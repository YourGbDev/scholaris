"""Create encrypted PostgreSQL dumps; credentials and keys come from the environment."""
import base64
import hashlib
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from urllib.parse import parse_qsl, unquote, urlsplit

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

MAGIC = b'SCB1'
CHUNK = 1024 * 1024


def encrypt_stream(source, target, key, prefix=b''):
    if len(key) != 32:
        raise ValueError('Expected a 32-byte encryption key')
    nonce = os.urandom(12)
    target.write(MAGIC + nonce)
    encryptor = Cipher(algorithms.AES(key), modes.GCM(nonce)).encryptor()
    encryptor.authenticate_additional_data(MAGIC)
    total = len(prefix)
    if prefix:
        target.write(encryptor.update(prefix))
    while data := source.read(CHUNK):
        total += len(data)
        target.write(encryptor.update(data))
    target.write(encryptor.finalize())
    target.write(encryptor.tag)
    return total


def decrypt_stream(source, target, key):
    if len(key) != 32:
        raise ValueError('Expected a 32-byte encryption key')
    source.seek(0, os.SEEK_END)
    size = source.tell()
    if size < len(MAGIC) + 12 + 16:
        raise ValueError('Incomplete encrypted backup')
    source.seek(0)
    if source.read(4) != MAGIC:
        raise ValueError('Unknown backup format')
    nonce = source.read(12)
    source.seek(-16, os.SEEK_END)
    tag = source.read(16)
    source.seek(16)
    remaining = size - 32
    decryptor = Cipher(algorithms.AES(key), modes.GCM(nonce, tag)).decryptor()
    decryptor.authenticate_additional_data(MAGIC)
    while remaining:
        data = source.read(min(CHUNK, remaining))
        if not data:
            raise ValueError('Incomplete encrypted backup')
        remaining -= len(data)
        target.write(decryptor.update(data))
    target.write(decryptor.finalize())


def decrypt_file(source_path, destination_path, key):
    destination = pathlib.Path(destination_path)
    if destination.exists():
        raise FileExistsError('Restore destination already exists')
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=destination.parent, prefix='.scholaris-restore-', delete=False) as output:
            temporary = pathlib.Path(output.name)
            with open(source_path, 'rb') as source:
                decrypt_stream(source, output, key)
        # Hard-link creation refuses to overwrite an existing destination.
        os.link(temporary, destination)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def create_backup(directory, executable, database_url, key):
    if not database_url.startswith(('postgresql://', 'postgres://')):
        raise ValueError('A PostgreSQL connection URL is required')
    connection = urlsplit(database_url)
    if not connection.hostname or connection.path in ('', '/'):
        raise ValueError('An explicit database host and database name are required')
    parameters = parse_qsl(connection.query, keep_blank_values=True)
    if any(name not in ('sslmode', 'sslrootcert') for name, _ in parameters):
        raise ValueError('Unsupported database connection option')
    if any((name == 'sslmode' and value != 'verify-full') or
           (name == 'sslrootcert' and value != 'system') for name, value in parameters):
        raise ValueError('Database connection must use verified TLS')
    directory = pathlib.Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    name = datetime.now(timezone.utc).strftime('scholaris-%Y%m%dT%H%M%S%fZ.scb')
    destination = directory / name
    partial = directory / (name + '.part')
    environment = os.environ.copy()
    # libpq does not expand a connection URI supplied through PGDATABASE.
    for name in ('PGHOSTADDR', 'PGSERVICE', 'PGUSER', 'PGPASSWORD'):
        environment.pop(name, None)
    environment['PGHOST'] = connection.hostname
    environment['PGPORT'] = str(connection.port or 5432)
    environment['PGDATABASE'] = unquote(connection.path[1:])
    if connection.username is not None:
        environment['PGUSER'] = unquote(connection.username)
    if connection.password is not None:
        environment['PGPASSWORD'] = unquote(connection.password)
    environment['PGSSLMODE'] = 'verify-full'
    environment['PGSSLROOTCERT'] = os.environ.get('SCHOLARIS_BACKUP_CA_FILE') or 'system'
    environment.pop('SCHOLARIS_DB_URL', None)
    environment.pop('SCHOLARIS_BACKUP_KEY', None)
    # Dump output is encrypted as it is read; no plaintext dump is written.
    with tempfile.TemporaryFile() as errors:
        process = subprocess.Popen([executable, '--format=custom', '--no-owner', '--no-privileges'],
                                   stdout=subprocess.PIPE, stderr=errors, env=environment)
        created = False
        try:
            header = process.stdout.read(5)
            if header != b'PGDMP':
                raise RuntimeError('Database output is not a PostgreSQL custom dump')
            with partial.open('xb') as output:
                created = True
                dumped_bytes = encrypt_stream(process.stdout, output, key, prefix=header)
            if process.wait() != 0:
                raise RuntimeError('Database dump failed; check connectivity and credentials')
            if dumped_bytes == 0:
                raise RuntimeError('Database dump was empty')
            os.link(partial, destination)
            partial.unlink()
        except BaseException:
            process.kill() if process.poll() is None else None
            process.wait()
            if created:
                partial.unlink(missing_ok=True)
            raise
    return destination


def copy_encrypted_backup(source_path, directory):
    source = pathlib.Path(source_path)
    directory = pathlib.Path(directory)
    with source.open('rb') as archive:
        if source.suffix != '.scb' or archive.read(4) != MAGIC or source.stat().st_size < 32:
            raise ValueError('Only encrypted Scholaris archives may be mirrored')
    if not directory.is_dir():
        raise FileNotFoundError('Cloud folder is unavailable; local backup is preserved')
    destination = directory / source.name
    if destination.exists():
        raise FileExistsError('Cloud backup already exists')
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=directory, prefix='.scholaris-copy-', suffix='.part', delete=False) as output:
            temporary = pathlib.Path(output.name)
            with source.open('rb') as archive:
                shutil.copyfileobj(archive, output, CHUNK)
        with source.open('rb') as original, temporary.open('rb') as copied:
            if hashlib.file_digest(original, 'sha256').digest() != hashlib.file_digest(copied, 'sha256').digest():
                raise RuntimeError('Cloud-folder copy checksum mismatch')
        # Windows rename refuses to overwrite an existing destination, including on Drive.
        os.rename(temporary, destination)
        return destination
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    try:
        key = base64.urlsafe_b64decode(os.environ['SCHOLARIS_BACKUP_KEY'])
        if len(sys.argv) == 4 and sys.argv[1] == 'decrypt':
            decrypt_file(sys.argv[2], sys.argv[3], key)
            print('Backup decrypted; restore only into an isolated authorized database.')
            return 0
        if len(sys.argv) != 1:
            raise ValueError('Usage: scholaris_backup.py [decrypt backup.scb output.dump]')
        path = create_backup(os.environ['SCHOLARIS_BACKUP_DIR'], os.environ['SCHOLARIS_PG_DUMP'],
                             os.environ['SCHOLARIS_DB_URL'], key)
        print(f'Encrypted backup created: {path}')
        if mirror := os.environ.get('SCHOLARIS_BACKUP_MIRROR_DIR'):
            try:
                copied = copy_encrypted_backup(path, mirror)
                print(f'Encrypted archive copied to sync folder: {copied}; cloud upload depends on Drive sync.')
            except Exception as error:
                print(f'Cloud copy failed: {type(error).__name__}; local encrypted backup is preserved.', file=sys.stderr)
                return 2
    except Exception as error:
        print(f'Backup failed: {type(error).__name__}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

import importlib.util
import io
import pathlib
import tempfile
import unittest
from unittest.mock import patch
from cryptography.exceptions import InvalidTag

spec = importlib.util.spec_from_file_location('scholaris_backup', pathlib.Path(__file__).parents[1] / 'tools' / 'scholaris_backup.py')
backup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backup)


class BackupEncryptionTest(unittest.TestCase):
    def test_mirror_copies_only_encrypted_archive_and_preserves_local_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            source = root / 'test.scb'
            target = root / 'cloud'
            target.mkdir()
            source.write_bytes(backup.MAGIC + b'encrypted bytes' * 8)
            copied = backup.copy_encrypted_backup(source, target)
            self.assertEqual(copied.read_bytes(), source.read_bytes())
            self.assertEqual(list(target.iterdir()), [copied])
            with self.assertRaises(FileExistsError):
                backup.copy_encrypted_backup(source, target)

    def test_mirror_rejects_plaintext_and_unavailable_cloud_folder(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            source = root / 'database.secret'
            source.write_bytes(b'private secret')
            with self.assertRaises(ValueError):
                backup.copy_encrypted_backup(source, root)
            source = root / 'fake.scb'
            source.write_bytes(b'PGDMPplaintext dump')
            with self.assertRaises(ValueError):
                backup.copy_encrypted_backup(source, root)
            source.write_bytes(backup.MAGIC + bytes(40))
            with self.assertRaises(FileNotFoundError):
                backup.copy_encrypted_backup(source, root / 'offline')

    def test_mirror_failure_keeps_local_backup_and_removes_partial_copy(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            source = root / 'test.scb'
            source.write_bytes(backup.MAGIC + bytes(40))
            target = root / 'cloud'
            target.mkdir()
            with patch.object(backup.shutil, 'copyfileobj', side_effect=OSError('offline')):
                with self.assertRaises(OSError):
                    backup.copy_encrypted_backup(source, target)
            self.assertTrue(source.exists())
            self.assertEqual(list(target.iterdir()), [])

    def test_configured_ca_file_keeps_full_tls_verification(self):
        class SuccessfulDump:
            stdout = io.BytesIO(b'PGDMPtest')
            def wait(self): return 0
            def poll(self): return 0
        with tempfile.TemporaryDirectory() as directory, patch.dict(backup.os.environ, {'SCHOLARIS_BACKUP_CA_FILE': 'C:/private/supabase-ca.crt'}), patch.object(backup.subprocess, 'Popen', return_value=SuccessfulDump()) as popen:
            backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db', bytes(32))
            self.assertEqual(popen.call_args.kwargs['env']['PGSSLROOTCERT'], 'C:/private/supabase-ca.crt')
            self.assertEqual(popen.call_args.kwargs['env']['PGSSLMODE'], 'verify-full')

    def test_connection_url_becomes_libpq_environment_without_secrets_in_arguments(self):
        class SuccessfulDump:
            stdout = io.BytesIO(b'PGDMPtest')
            def wait(self): return 0
            def poll(self): return 0
        with tempfile.TemporaryDirectory() as directory, patch.object(backup.subprocess, 'Popen', return_value=SuccessfulDump()) as popen:
            backup.create_backup(directory, 'pg_dump', 'postgresql://demo.user:p%40ss%3Aword@example.test:6543/demo%20db', bytes(32))
            environment = popen.call_args.kwargs['env']
            self.assertEqual(environment['PGDATABASE'], 'demo db')
            self.assertEqual(environment['PGHOST'], 'example.test')
            self.assertEqual(environment['PGPORT'], '6543')
            self.assertEqual(environment['PGUSER'], 'demo.user')
            self.assertEqual(environment['PGPASSWORD'], 'p@ss:word')
            self.assertNotIn('p@ss:word', str(popen.call_args.args))

    def test_connection_requires_explicit_remote_host_and_database(self):
        for url in ('postgresql:///db', 'postgresql://example.test/'):
            with self.subTest(url=url), tempfile.TemporaryDirectory() as directory:
                with self.assertRaises(ValueError):
                    backup.create_backup(directory, 'pg_dump', url, bytes(32))

    def test_unknown_connection_options_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db?host=other.test', bytes(32))

    def test_round_trip_and_tampering(self):
        key = bytes(range(32))
        original = b'private scholarship data' * 10000
        encrypted = io.BytesIO()
        backup.encrypt_stream(io.BytesIO(original), encrypted, key)
        ciphertext = encrypted.getvalue()
        self.assertNotIn(b'private scholarship data', ciphertext)
        restored = io.BytesIO()
        backup.decrypt_stream(io.BytesIO(ciphertext), restored, key)
        self.assertEqual(restored.getvalue(), original)
        altered = bytearray(ciphertext)
        altered[20] ^= 1
        with self.assertRaises(Exception):
            backup.decrypt_stream(io.BytesIO(altered), io.BytesIO(), key)

    def test_truncated_backup_is_rejected(self):
        with self.assertRaises(ValueError):
            backup.decrypt_stream(io.BytesIO(b'SCB1short'), io.BytesIO(), bytes(32))

    def test_failed_dump_does_not_leave_a_backup(self):
        class FailedDump:
            stdout = io.BytesIO(b'partial data')
            def wait(self): return 1
            def poll(self): return 1
        with tempfile.TemporaryDirectory() as directory, patch.object(backup.subprocess, 'Popen', return_value=FailedDump()):
            with self.assertRaises(RuntimeError):
                backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db', bytes(32))
            self.assertEqual(list(pathlib.Path(directory).iterdir()), [])

    def test_successful_dump_is_encrypted_and_credentials_stay_out_of_arguments(self):
        class SuccessfulDump:
            stdout = io.BytesIO(b'PGDMPpostgres dump contents')
            def wait(self): return 0
            def poll(self): return 0
        with tempfile.TemporaryDirectory() as directory, patch.object(backup.subprocess, 'Popen', return_value=SuccessfulDump()) as popen:
            path = backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db', bytes(32))
            self.assertTrue(path.exists())
            self.assertNotIn(b'postgres dump contents', path.read_bytes())
            self.assertNotIn('postgresql://example.test/db', str(popen.call_args.args))
            self.assertEqual(popen.call_args.kwargs['env']['PGSSLMODE'], 'verify-full')
            restored = io.BytesIO()
            with path.open('rb') as source:
                backup.decrypt_stream(source, restored, bytes(32))
            self.assertEqual(restored.getvalue(), b'PGDMPpostgres dump contents')

    def test_empty_dump_does_not_create_a_backup(self):
        class EmptyDump:
            stdout = io.BytesIO(b'')
            def wait(self): return 0
            def poll(self): return 0
        with tempfile.TemporaryDirectory() as directory, patch.object(backup.subprocess, 'Popen', return_value=EmptyDump()):
            with self.assertRaises(RuntimeError):
                backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db', bytes(32))
            self.assertEqual(list(pathlib.Path(directory).iterdir()), [])

    def test_non_postgres_output_is_rejected(self):
        class NotDump:
            stdout = io.BytesIO(b'not a dump')
            def wait(self): return 0
            def poll(self): return 0
        with tempfile.TemporaryDirectory() as directory, patch.object(backup.subprocess, 'Popen', return_value=NotDump()):
            with self.assertRaises(RuntimeError):
                backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db', bytes(32))
            self.assertEqual(list(pathlib.Path(directory).iterdir()), [])

    def test_connection_cannot_disable_tls(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                backup.create_backup(directory, 'pg_dump', 'postgresql://example.test/db?sslmode=disable', bytes(32))

    def test_failed_authentication_never_publishes_restore_file(self):
        key = bytes(range(32))
        encrypted = io.BytesIO()
        backup.encrypt_stream(io.BytesIO(b'sensitive data'), encrypted, key)
        corrupted = bytearray(encrypted.getvalue())
        corrupted[-1] ^= 1
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / 'backup.scb'
            destination = pathlib.Path(directory) / 'restored.dump'
            source.write_bytes(corrupted)
            with self.assertRaises(InvalidTag):
                backup.decrypt_file(source, destination, key)
            self.assertFalse(destination.exists())
            self.assertEqual(list(pathlib.Path(directory).iterdir()), [source])

    def test_restore_file_round_trip_and_no_overwrite(self):
        key = bytes(range(32))
        encrypted = io.BytesIO()
        backup.encrypt_stream(io.BytesIO(b'restore data'), encrypted, key)
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / 'backup.scb'
            destination = pathlib.Path(directory) / 'restored.dump'
            source.write_bytes(encrypted.getvalue())
            backup.decrypt_file(source, destination, key)
            self.assertEqual(destination.read_bytes(), b'restore data')
            with self.assertRaises(FileExistsError):
                backup.decrypt_file(source, destination, key)


if __name__ == '__main__':
    unittest.main()

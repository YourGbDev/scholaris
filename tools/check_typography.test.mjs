import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {typographyViolations} from './check_typography.mjs';

test('rejects independent fonts, weights, downloads and legacy helpers', () => {
  for (const code of ["TextStyle(fontFamily: 'Geist')", 'TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)', 'GoogleFonts.inter()', 'outfit(fontSize: 14)', "TextStyle(fontFamilyFallback: ['Roboto'])"]) {
    assert.ok(typographyViolations(code).length > 0, code);
  }
});

test('bundled Inter includes four genuine distinct weights and its license', () => {
  for (const [name, weight] of [['Regular', 400], ['Medium', 500], ['SemiBold', 600], ['Bold', 700]]) {
    const font = fs.readFileSync(`assets/fonts/inter/Inter-${name}.ttf`);
    const tables = new Map();
    for (let i = 0; i < font.readUInt16BE(4); i++) {
      const start = 12 + 16 * i;
      tables.set(font.toString('ascii', start, start + 4), font.readUInt32BE(start + 8));
    }
    assert.equal(font.readUInt16BE(tables.get('OS/2') + 4), weight, name);
    const names = tables.get('name');
    const strings = names + font.readUInt16BE(names + 4);
    let foundInter = false;
    for (let i = 0; i < font.readUInt16BE(names + 2); i++) {
      const record = names + 6 + 12 * i;
      if (![1, 16].includes(font.readUInt16BE(record + 6))) continue;
      const bytes = Buffer.from(font.subarray(strings + font.readUInt16BE(record + 10), strings + font.readUInt16BE(record + 10) + font.readUInt16BE(record + 8)));
      const unicode = [0, 3].includes(font.readUInt16BE(record));
      if (unicode) bytes.swap16();
      if (bytes.toString(unicode ? 'utf16le' : 'ascii').startsWith('Inter')) foundInter = true;
    }
    assert.ok(foundInter, `${name}: Inter family metadata missing`);
  }
  assert.match(fs.readFileSync('assets/fonts/inter/OFL.txt', 'utf8'), /SIL OPEN FONT LICENSE/);
  assert.match(fs.readFileSync('pubspec.yaml', 'utf8'), /- assets\/fonts\/inter\/OFL\.txt/, 'Inter license must ship in the asset bundle');
});
test('permits semantic roles, central resolution, geometry and comments', () => {
  for (const code of ['AppTypography.style(AppTextRole.body, fontSize: 14)', 'ThemeData(fontFamily: AppTypography.familyFor(14))', '// fontWeight: FontWeight.w800\nconst TextStyle(color: Colors.red)', '/* GoogleFonts.inter() */ TextStyle(height: 1.4)']) {
    assert.deepEqual(typographyViolations(code), [], code);
  }
});

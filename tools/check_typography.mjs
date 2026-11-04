import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

export function typographyViolations(source) {
  // Strip comments so documentation cannot hide real overrides or cause failures.
  const code = source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
  const checks = [
    [/\bFontWeight\s*\./g, 'independent font weight'],
    [/\bfontWeight\s*:/g, 'independent font weight argument'],
    [/\bfontFamily\s*:(?!\s*AppTypography\b)/g, 'independent font family'],
    [/\bfontFamilyFallback\s*:(?!\s*AppTypography\b)/g, 'independent fallback family'],
    [/\bGoogleFonts\s*\./g, 'runtime/font-specific GoogleFonts usage'],
    [/\b(?:geist|outfit|openSans|poppins|inter|orgHeadline|orgBody|orgLabel|orgDataMono|adminHeaderStyle|adminLabelStyle|adminBodyStyle|adminDataMono|seqDisplay|seqHeadlineLg|seqHeadlineMd|seqHeadlineSm|seqBodyLg|seqBodyMd|seqBodySm|seqLabelLg|seqLabelMd|seqLabelSm)\s*\(/g, 'legacy font helper'],
  ];
  return checks.flatMap(([pattern, reason]) => [...code.matchAll(pattern)].map(match => ({
    line: code.slice(0, match.index).split('\n').length, reason,
  })));
}

function scan(directory) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap(entry => {
    const filename = path.join(directory, entry.name);
    if (entry.isDirectory()) return scan(filename);
    if (!filename.endsWith('.dart') || filename.endsWith('app_typography.dart')) return [];
    return typographyViolations(fs.readFileSync(filename, 'utf8')).map(v => `${filename}:${v.line}: ${v.reason}`);
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const failures = scan('lib');
  if (failures.length) {
    console.error(failures.slice(0, 30).join('\n'));
    console.error(`${failures.length} typography violations`);
    process.exitCode = 1;
  } else console.log('Typography source guard passed: all app font families/weights are centralized.');
}

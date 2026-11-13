import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  auditProjectFiles,
  classifyCategory,
  classifyStage,
  extractResReferences,
  type ProjectFileEntry,
} from './godotAuditor';

function walkDir(dir: string, rootDir: string, out: ProjectFileEntry[]) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkDir(full, rootDir, out);
    } else {
      const rel = path.relative(rootDir, full).replace(/\\/g, '/');
      const isBinary = rel.endsWith('.wav');
      const resPath = rel.startsWith('godot_project/') ? `res://${rel.slice('godot_project/'.length)}` : null;
      const content = isBinary ? '' : fs.readFileSync(full, 'utf8');
      out.push({
        path: rel,
        resPath,
        size: fs.statSync(full).size,
        category: classifyCategory(rel),
        stage: classifyStage(rel),
        isBinary,
        content,
      });
    }
  }
}

test('extractResReferences extracts unique res:// paths', () => {
  const refs = extractResReferences('load("res://a/b.gd") and res://a/b.gd and res://c/d.tscn');
  assert.deepEqual(refs, ['res://a/b.gd', 'res://c/d.tscn']);
});

test('real godot_project on disk passes 100% of integrity and res:// path checks', () => {
  const root = process.cwd();
  const files: ProjectFileEntry[] = [];
  walkDir(path.join(root, 'godot_project'), root, files);
  const wfPath = path.join(root, '.github', 'workflows', 'android-build.yml');
  if (fs.existsSync(wfPath)) {
    files.push({
      path: '.github/workflows/android-build.yml',
      resPath: null,
      size: fs.statSync(wfPath).size,
      category: 'Config',
      stage: 10,
      isBinary: false,
      content: fs.readFileSync(wfPath, 'utf8'),
    });
  }

  const summary = auditProjectFiles(files);
  assert.equal(summary.missingResPaths.length, 0, `Missing res:// paths: ${summary.missingResPaths.join('; ')}`);
  for (const check of summary.checks) {
    assert.equal(check.passed, true, `Failed audit check: ${check.label} (${check.details})`);
  }
});

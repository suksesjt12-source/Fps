import express from 'express';
import fs from 'node:fs';
import path from 'node:path';
import { createServer as createViteServer } from 'vite';
import {
  auditProjectFiles,
  classifyCategory,
  classifyStage,
  type ProjectFileEntry,
} from './src/utils/godotAuditor.ts';

const PORT = 3000;
const ROOT_DIR = process.cwd();

function collectFiles(dir: string, out: ProjectFileEntry[]) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name));
  for (const entry of entries) {
    if (entry.name === 'build' || entry.name === '.godot' || entry.name === 'node_modules') continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectFiles(full, out);
    } else {
      const rel = path.relative(ROOT_DIR, full).replace(/\\/g, '/');
      const isBinary = rel.endsWith('.wav');
      const resPath = rel.startsWith('godot_project/') ? `res://${rel.slice('godot_project/'.length)}` : null;
      const buf = fs.readFileSync(full);
      out.push({
        path: rel,
        resPath,
        size: buf.byteLength,
        category: classifyCategory(rel),
        stage: classifyStage(rel),
        isBinary,
        content: isBinary ? buf.toString('base64') : buf.toString('utf8'),
      });
    }
  }
}

function parseTresFields(raw: string): Record<string, string> {
  const result: Record<string, string> = {};
  for (const line of raw.split(/\r?\n/)) {
    const m = line.match(/^([a-zA-Z0-9_]+)\s*=\s*(.+)$/);
    if (m) {
      let val = m[2].trim();
      if (val.startsWith('"') && val.endsWith('"')) {
        val = val.slice(1, -1);
      }
      result[m[1]] = val;
    }
  }
  return result;
}

async function startServer() {
  const app = express();
  app.use(express.json());

  app.get('/api/project-files', (_req, res) => {
    try {
      const files: ProjectFileEntry[] = [];
      collectFiles(path.join(ROOT_DIR, 'godot_project'), files);

      const extraPaths = [
        '.github/workflows/android-build.yml',
        'README.md',
      ];
      for (const rel of extraPaths) {
        const full = path.join(ROOT_DIR, rel);
        if (fs.existsSync(full)) {
          const content = fs.readFileSync(full, 'utf8');
          files.push({
            path: rel,
            resPath: null,
            size: Buffer.byteLength(content, 'utf8'),
            category: classifyCategory(rel),
            stage: classifyStage(rel),
            isBinary: false,
            content,
          });
        }
      }

      const audit = auditProjectFiles(files);
      const weapons = files
        .filter((f) => f.path.startsWith('godot_project/resources/weapons/') && f.path.endsWith('.tres'))
        .map((f) => ({ path: f.path, ...parseTresFields(f.content) }));
      const missions = files
        .filter((f) => f.path.startsWith('godot_project/resources/missions/') && f.path.endsWith('.tres'))
        .map((f) => ({ path: f.path, ...parseTresFields(f.content) }));

      res.json({ files, audit, weapons, missions });
    } catch (err) {
      res.status(500).json({ error: err instanceof Error ? err.message : 'Failed to load Godot project' });
    }
  });

  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distDir = path.join(ROOT_DIR, 'dist');
    app.use(express.static(distDir));
    app.get('*', (_req, res) => {
      res.sendFile(path.join(distDir, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Tactical Strike Studio running on http://0.0.0.0:${PORT}`);
  });
}

startServer();

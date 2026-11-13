import { useMemo, useState } from 'react';
import { Check, Copy, Search, Volume2 } from 'lucide-react';
import type { ProjectFileEntry } from '../utils/godotAuditor';

const STAGE_LABELS: Record<number, string> = {
  0: 'All Stages',
  1: 'Stage 1: Project Config',
  2: 'Stage 2: Core & Menus',
  3: 'Stage 3: Player & Touch',
  4: 'Stage 4: Weapons',
  5: 'Stage 5: Audio',
  6: 'Stage 6: Enemy AI',
  7: 'Stage 7: Maps & Missions',
  8: 'Stage 8: HUD, VFX & Save',
  9: 'Stage 9: Docs & Assets',
  10: 'Stage 10: APK & CI/CD',
};

const CATEGORIES = ['All', 'GDScript', 'Scene', 'Resource', 'Shader', 'Audio', 'Config', 'Docs & Assets'];

interface ExplorerViewProps {
  files: ProjectFileEntry[];
}

export function ExplorerView({ files }: ExplorerViewProps) {
  const [selectedStage, setSelectedStage] = useState<number>(0);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [query, setQuery] = useState<string>('');
  const [selectedPath, setSelectedPath] = useState<string>('godot_project/project.godot');
  const [copied, setCopied] = useState<boolean>(false);

  const filteredFiles = useMemo(() => {
    const q = query.trim().toLowerCase();
    return files.filter((f) => {
      if (selectedStage !== 0 && f.stage !== selectedStage) return false;
      if (selectedCategory !== 'All' && f.category !== selectedCategory) return false;
      if (q && !f.path.toLowerCase().includes(q) && !(f.resPath ?? '').toLowerCase().includes(q)) return false;
      return true;
    });
  }, [files, selectedStage, selectedCategory, query]);

  const activeFile = useMemo(() => {
    return files.find((f) => f.path === selectedPath) ?? filteredFiles[0] ?? null;
  }, [files, selectedPath, filteredFiles]);

  const handleCopy = async () => {
    if (!activeFile || activeFile.isBinary) return;
    await navigator.clipboard.writeText(activeFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  const formatBytes = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    return `${(bytes / 1024).toFixed(1)} KB`;
  };

  const wavDataUrl = useMemo(() => {
    if (!activeFile || !activeFile.isBinary) return null;
    return `data:audio/wav;base64,${activeFile.content}`;
  }, [activeFile]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-4 border-b border-slate-800 pb-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex flex-col gap-1">
            <label htmlFor="stage-filter" className="text-xs font-medium text-slate-400">
              Implementation Stage
            </label>
            <select
              id="stage-filter"
              value={selectedStage}
              onChange={(e) => setSelectedStage(Number(e.target.value))}
              className="bg-slate-900 border border-slate-800 rounded-md px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-amber-500"
            >
              {Object.entries(STAGE_LABELS).map(([k, label]) => (
                <option key={k} value={k}>
                  {label}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label htmlFor="category-filter" className="text-xs font-medium text-slate-400">
              File Type
            </label>
            <select
              id="category-filter"
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="bg-slate-900 border border-slate-800 rounded-md px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-amber-500"
            >
              {CATEGORIES.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex flex-col gap-1 w-full lg:w-80">
          <label htmlFor="file-search" className="text-xs font-medium text-slate-400">
            Search Path or Resource
          </label>
          <div className="relative">
            <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              id="file-search"
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="e.g. player_controller.gd"
              className="w-full bg-slate-900 border border-slate-800 rounded-md pl-9 pr-3 py-2 text-sm text-slate-100 placeholder:text-slate-500 focus:outline-none focus:border-amber-500"
            />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        <div className="lg:col-span-4 border border-slate-800 bg-[#111927] rounded-lg overflow-hidden">
          <div className="px-4 py-2.5 border-b border-slate-800 flex items-center justify-between text-xs text-slate-400">
            <span>Repository Files</span>
            <span className="font-mono tabular-nums">{filteredFiles.length} items</span>
          </div>
          <div className="max-h-[600px] overflow-y-auto divide-y divide-slate-800/70">
            {filteredFiles.length === 0 ? (
              <div className="p-6 text-sm text-slate-400 text-center">
                No files match the active stage or search filter.
              </div>
            ) : (
              filteredFiles.map((file) => {
                const isSelected = activeFile?.path === file.path;
                return (
                  <button
                    key={file.path}
                    type="button"
                    onClick={() => setSelectedPath(file.path)}
                    className={`w-full text-left px-4 py-2.5 transition-colors flex items-center justify-between gap-3 ${
                      isSelected
                        ? 'bg-amber-500/10 text-amber-300'
                        : 'hover:bg-slate-800/60 text-slate-200'
                    }`}
                  >
                    <div className="min-w-0">
                      <div className="text-xs font-mono truncate">{file.resPath ?? file.path}</div>
                      <div className="text-[11px] text-slate-400 mt-0.5">
                        {file.category} · Stage {file.stage}
                      </div>
                    </div>
                    <span className="text-[11px] font-mono text-slate-500 shrink-0 tabular-nums">
                      {formatBytes(file.size)}
                    </span>
                  </button>
                );
              })
            )}
          </div>
        </div>

        <div className="lg:col-span-8 border border-slate-800 bg-[#111927] rounded-lg overflow-hidden">
          {activeFile ? (
            <>
              <div className="px-4 py-3 border-b border-slate-800 flex flex-wrap items-center justify-between gap-3">
                <div className="min-w-0">
                  <h2 className="text-sm font-mono font-medium text-slate-100 truncate">
                    {activeFile.path}
                  </h2>
                  <p className="text-xs text-slate-400 mt-0.5">
                    {activeFile.resPath ?? 'Repository Root'} · {activeFile.category} · {formatBytes(activeFile.size)}
                  </p>
                </div>
                {!activeFile.isBinary && (
                  <button
                    type="button"
                    onClick={handleCopy}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md border border-slate-700 bg-slate-800/80 hover:bg-slate-700 text-xs font-medium text-slate-100 whitespace-nowrap shrink-0 transition-colors"
                  >
                    {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    <span>{copied ? 'Copied' : 'Copy Source'}</span>
                  </button>
                )}
              </div>

              {activeFile.isBinary && wavDataUrl ? (
                <div className="p-8 flex flex-col items-center justify-center gap-4 text-center">
                  <Volume2 className="w-8 h-8 text-amber-400" />
                  <div>
                    <div className="text-sm font-medium text-slate-100">PCM WAV Tactical Audio Asset</div>
                    <div className="text-xs text-slate-400 mt-1">
                      22.05 kHz Mono 16-bit PCM · Synthesized for Android Compatibility
                    </div>
                  </div>
                  <audio controls src={wavDataUrl} className="w-full max-w-md" />
                </div>
              ) : (
                <pre className="p-4 text-xs font-mono leading-relaxed text-slate-200 overflow-x-auto max-h-[600px] overflow-y-auto bg-[#0b111a]">
                  <code>{activeFile.content}</code>
                </pre>
              )}
            </>
          ) : (
            <div className="p-8 text-sm text-slate-400">Select a file from the tree to inspect its source.</div>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useEffect, useState } from 'react';
import JSZip from 'jszip';
import { Download } from 'lucide-react';
import { ExplorerView } from './components/ExplorerView';
import { SystemsView } from './components/SystemsView';
import { DEFAULT_HUD_CONFIG, TouchHudStudio } from './components/TouchHudStudio';
import { AuditBuildView } from './components/AuditBuildView';
import type { HudLayoutConfig, ProjectPayload } from './types/studio';

type StudioTab = 'explorer' | 'systems' | 'hud' | 'audit';

export default function App() {
  const [activeTab, setActiveTab] = useState<StudioTab>('explorer');
  const [data, setData] = useState<ProjectPayload | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState<boolean>(false);
  const [hudConfig, setHudConfig] = useState<HudLayoutConfig>(DEFAULT_HUD_CONFIG);

  const loadProject = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/project-files');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = (await res.json()) as ProjectPayload;
      setData(json);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to fetch Godot project files');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadProject();
  }, []);

  const handleDownloadZip = async () => {
    if (!data || exporting) return;
    setExporting(true);
    try {
      const zip = new JSZip();
      for (const file of data.files) {
        if (file.isBinary) {
          zip.file(file.path, file.content, { base64: true });
        } else {
          zip.file(file.path, file.content);
        }
      }
      zip.file(
        'godot_project/resources/settings/hud_layout_preset.json',
        JSON.stringify(
          {
            hud_joystick_size: hudConfig.joystickSize,
            hud_button_scale: hudConfig.buttonScale,
            hud_button_opacity: hudConfig.buttonOpacity,
            look_sensitivity_x: hudConfig.sensX,
            look_sensitivity_y: hudConfig.sensY,
            ads_sensitivity_multiplier: hudConfig.adsSens,
            hud_custom_positions: Object.fromEntries(
              hudConfig.buttons.map((b) => [b.id, { x: b.x, y: b.y }])
            ),
          },
          null,
          2
        )
      );

      const blob = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'tactical-strike-zero-hour-godot4.zip';
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0b111a] text-slate-100 flex flex-col">
      <header className="border-b border-slate-800 bg-[#0b111a]/95 sticky top-0 z-20">
        <div className="max-w-[1440px] mx-auto px-6 py-3.5 flex items-center justify-between gap-8">
          <a
            href="#top"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('explorer');
            }}
            className="text-lg font-display font-bold tracking-tight text-slate-100 whitespace-nowrap shrink-0"
          >
            Tactical Strike: Zero Hour
          </a>

          <nav aria-label="Primary studio sections" className="hidden md:flex items-center gap-6 text-sm font-medium">
            <button
              type="button"
              onClick={() => setActiveTab('explorer')}
              className={`py-1 border-b-2 transition-colors whitespace-nowrap shrink-0 ${
                activeTab === 'explorer'
                  ? 'border-amber-500 text-amber-400'
                  : 'border-transparent text-slate-400 hover:text-slate-100'
              }`}
            >
              Project Explorer
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('systems')}
              className={`py-1 border-b-2 transition-colors whitespace-nowrap shrink-0 ${
                activeTab === 'systems'
                  ? 'border-amber-500 text-amber-400'
                  : 'border-transparent text-slate-400 hover:text-slate-100'
              }`}
            >
              Systems &amp; Arsenal
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('hud')}
              className={`py-1 border-b-2 transition-colors whitespace-nowrap shrink-0 ${
                activeTab === 'hud'
                  ? 'border-amber-500 text-amber-400'
                  : 'border-transparent text-slate-400 hover:text-slate-100'
              }`}
            >
              Touch HUD Studio
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('audit')}
              className={`py-1 border-b-2 transition-colors whitespace-nowrap shrink-0 ${
                activeTab === 'audit'
                  ? 'border-amber-500 text-amber-400'
                  : 'border-transparent text-slate-400 hover:text-slate-100'
              }`}
            >
              APK Build &amp; Audit
            </button>
          </nav>

          <div className="shrink-0">
            <button
              type="button"
              disabled={!data || exporting}
              onClick={handleDownloadZip}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-md bg-amber-500 hover:bg-amber-400 disabled:opacity-50 text-xs font-semibold text-slate-950 transition-colors whitespace-nowrap shrink-0"
            >
              <Download className="w-3.5 h-3.5" />
              <span>{exporting ? 'Packaging ZIP...' : 'Download Project (.zip)'}</span>
            </button>
          </div>
        </div>

        <div className="md:hidden border-t border-slate-800 px-4 py-2 flex items-center gap-3 overflow-x-auto text-xs font-medium">
          <button
            type="button"
            onClick={() => setActiveTab('explorer')}
            className={`px-2.5 py-1.5 rounded whitespace-nowrap shrink-0 ${
              activeTab === 'explorer' ? 'bg-amber-500/15 text-amber-400' : 'text-slate-400'
            }`}
          >
            Explorer
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('systems')}
            className={`px-2.5 py-1.5 rounded whitespace-nowrap shrink-0 ${
              activeTab === 'systems' ? 'bg-amber-500/15 text-amber-400' : 'text-slate-400'
            }`}
          >
            Arsenal &amp; Maps
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('hud')}
            className={`px-2.5 py-1.5 rounded whitespace-nowrap shrink-0 ${
              activeTab === 'hud' ? 'bg-amber-500/15 text-amber-400' : 'text-slate-400'
            }`}
          >
            Touch HUD
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('audit')}
            className={`px-2.5 py-1.5 rounded whitespace-nowrap shrink-0 ${
              activeTab === 'audit' ? 'bg-amber-500/15 text-amber-400' : 'text-slate-400'
            }`}
          >
            APK Build
          </button>
        </div>
      </header>

      <main className="flex-1 max-w-[1440px] w-full mx-auto px-6 py-6">
        {loading ? (
          <div className="border border-slate-800 bg-[#111927] rounded-lg p-10 text-center text-sm text-slate-400">
            Loading Godot 4.3 project tree and auditing resource references...
          </div>
        ) : error ? (
          <div className="border border-red-900/60 bg-red-950/20 rounded-lg p-8 text-center space-y-3">
            <div className="text-sm font-medium text-red-300">Failed to load Godot project: {error}</div>
            <button
              type="button"
              onClick={loadProject}
              className="px-4 py-2 rounded-md bg-slate-800 hover:bg-slate-700 text-xs font-medium text-slate-100"
            >
              Retry
            </button>
          </div>
        ) : data ? (
          <>
            <div className="mb-6 flex flex-wrap items-baseline justify-between gap-4 border-b border-slate-800/80 pb-4">
              <div>
                <h1 className="text-2xl font-display font-semibold text-slate-100">
                  Godot 4.3 Android FPS Workspace
                </h1>
                <p className="text-sm text-slate-400 mt-1">
                  Godot Compatibility Renderer · ARM64 Export Preset · {data.audit.totalFiles} Project Files ·{' '}
                  {data.audit.missingResPaths.length === 0 ? 'All Resource Paths Verified' : 'Audit Warning'}
                </p>
              </div>
            </div>

            {activeTab === 'explorer' && <ExplorerView files={data.files} />}
            {activeTab === 'systems' && <SystemsView weapons={data.weapons} missions={data.missions} />}
            {activeTab === 'hud' && <TouchHudStudio config={hudConfig} onChange={setHudConfig} />}
            {activeTab === 'audit' && <AuditBuildView audit={data.audit} />}
          </>
        ) : null}
      </main>
    </div>
  );
}

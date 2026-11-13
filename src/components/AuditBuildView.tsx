import { CheckCircle2, AlertTriangle } from 'lucide-react';
import type { AuditSummary } from '../utils/godotAuditor';

interface AuditBuildViewProps {
  audit: AuditSummary;
}

const BUILD_STEPS = [
  {
    step: '01. Download Complete Repository ZIP',
    desc: 'Use the Download Project (.zip) button in the top bar to save the entire godot_project directory and .github/workflows/android-build.yml directly to your Android phone.',
  },
  {
    step: '02. Upload or Push to GitHub',
    desc: 'Create a new repository on GitHub from your mobile browser (or Termux/Git client), extract the ZIP, and upload/push all files preserving the .github/workflows/ folder.',
  },
  {
    step: '03. Automatic Headless Godot 4.3 Build',
    desc: 'GitHub Actions automatically provisions Java 17, Android SDK 34, Godot 4.3 headless Linux binary, exact 4.3.stable export templates, debug keystore, imports resources, checks script errors, and exports ARM64 APK.',
  },
  {
    step: '04. Install tactical_strike_zero_hour.apk',
    desc: 'Open the Actions run on your phone, download the tactical-strike-zero-hour-android-apk artifact ZIP, extract it, and install the APK on your Android device.',
  },
];

export function AuditBuildView({ audit }: AuditBuildViewProps) {
  return (
    <div className="space-y-8">
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
        <div className="border border-slate-800 bg-[#111927] rounded-lg p-4">
          <div className="text-xs text-slate-400">Total Files</div>
          <div className="text-2xl font-semibold font-mono tabular-nums text-slate-100 mt-1">{audit.totalFiles}</div>
        </div>
        <div className="border border-slate-800 bg-[#111927] rounded-lg p-4">
          <div className="text-xs text-slate-400">GDScript Modules</div>
          <div className="text-2xl font-semibold font-mono tabular-nums text-slate-100 mt-1">{audit.scriptCount}</div>
        </div>
        <div className="border border-slate-800 bg-[#111927] rounded-lg p-4">
          <div className="text-xs text-slate-400">Godot Scenes</div>
          <div className="text-2xl font-semibold font-mono tabular-nums text-slate-100 mt-1">{audit.sceneCount}</div>
        </div>
        <div className="border border-slate-800 bg-[#111927] rounded-lg p-4">
          <div className="text-xs text-slate-400">Resources (.tres)</div>
          <div className="text-2xl font-semibold font-mono tabular-nums text-slate-100 mt-1">{audit.resourceCount}</div>
        </div>
        <div className="border border-slate-800 bg-[#111927] rounded-lg p-4">
          <div className="text-xs text-slate-400">Audio Assets (.wav)</div>
          <div className="text-2xl font-semibold font-mono tabular-nums text-slate-100 mt-1">{audit.audioCount}</div>
        </div>
      </div>

      <section className="border border-slate-800 bg-[#111927] rounded-lg overflow-hidden">
        <div className="px-5 py-4 border-b border-slate-800">
          <h2 className="text-base font-semibold text-slate-100">Project Integrity & Readiness Audit</h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Live verification against all files in godot_project/ and .github/workflows/android-build.yml
          </p>
        </div>
        <div className="divide-y divide-slate-800/70">
          {audit.checks.map((chk) => (
            <div key={chk.id} className="px-5 py-3.5 flex items-start justify-between gap-4">
              <div className="flex items-start gap-3">
                {chk.passed ? (
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                ) : (
                  <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
                )}
                <div>
                  <div className="text-sm font-medium text-slate-100">{chk.label}</div>
                  <div className="text-xs text-slate-400 mt-0.5">{chk.details}</div>
                </div>
              </div>
              <span
                className={`text-xs font-mono font-semibold shrink-0 ${
                  chk.passed ? 'text-emerald-400' : 'text-amber-400'
                }`}
              >
                {chk.passed ? 'PASS' : 'WARN'}
              </span>
            </div>
          ))}
        </div>
      </section>

      <section className="border border-slate-800 bg-[#111927] rounded-lg p-5">
        <h2 className="text-base font-semibold text-slate-100 mb-1">
          Android Phone to APK Workflow (No Local PC Required)
        </h2>
        <p className="text-xs text-slate-400 mb-5">
          Configured for Godot 4.3-stable · ARM64-v8a · OpenGL ES 3 Compatibility Renderer
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {BUILD_STEPS.map((item) => (
            <div key={item.step} className="border border-slate-800/80 rounded-md p-4 bg-[#0b111a]">
              <div className="text-sm font-semibold text-amber-400">{item.step}</div>
              <p className="text-xs text-slate-300 mt-1.5 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

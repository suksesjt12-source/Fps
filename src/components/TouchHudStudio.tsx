import { useRef, useState } from 'react';
import { Check, Copy, RotateCcw } from 'lucide-react';
import type { HudLayoutConfig, TouchButtonPos } from '../types/studio';

export const DEFAULT_HUD_BUTTONS: TouchButtonPos[] = [
  { id: 'BtnFire', label: 'FIRE', x: 1090, y: 450, w: 110, h: 110 },
  { id: 'BtnADS', label: 'ADS', x: 980, y: 470, w: 84, h: 76 },
  { id: 'BtnReload', label: 'RLD', x: 1000, y: 380, w: 78, h: 68 },
  { id: 'BtnJump', label: 'JUMP', x: 1110, y: 360, w: 78, h: 70 },
  { id: 'BtnCrouch', label: 'CRCH', x: 1010, y: 560, w: 78, h: 62 },
  { id: 'BtnSprint', label: 'SPRINT', x: 910, y: 520, w: 72, h: 68 },
  { id: 'BtnSwitch', label: 'SWAP', x: 1110, y: 285, w: 92, h: 60 },
  { id: 'BtnInspect', label: 'INSP', x: 1010, y: 285, w: 86, h: 60 },
];

export const DEFAULT_HUD_CONFIG: HudLayoutConfig = {
  joystickSize: 1.0,
  buttonScale: 1.0,
  buttonOpacity: 0.82,
  sensX: 1.0,
  sensY: 1.0,
  adsSens: 0.6,
  buttons: DEFAULT_HUD_BUTTONS,
};

interface TouchHudStudioProps {
  config: HudLayoutConfig;
  onChange: (next: HudLayoutConfig) => void;
}

export function TouchHudStudio({ config, onChange }: TouchHudStudioProps) {
  const stageRef = useRef<HTMLDivElement | null>(null);
  const [draggingId, setDraggingId] = useState<string | null>(null);
  const [copiedJson, setCopiedJson] = useState<boolean>(false);

  const handlePointerDown = (id: string, e: React.PointerEvent<HTMLButtonElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    setDraggingId(id);
  };

  const handlePointerMove = (id: string, e: React.PointerEvent<HTMLButtonElement>) => {
    if (draggingId !== id || !stageRef.current) return;
    const rect = stageRef.current.getBoundingClientRect();
    const scaleX = 1280 / rect.width;
    const scaleY = 720 / rect.height;
    const dx = e.movementX * scaleX;
    const dy = e.movementY * scaleY;

    onChange({
      ...config,
      buttons: config.buttons.map((b) =>
        b.id === id
          ? {
              ...b,
              x: Math.round(Math.max(20, Math.min(1260 - b.w, b.x + dx))),
              y: Math.round(Math.max(40, Math.min(700 - b.h, b.y + dy))),
            }
          : b
      ),
    });
  };

  const handlePointerUp = () => {
    setDraggingId(null);
  };

  const saveJsonPayload = JSON.stringify(
    {
      hud_joystick_size: config.joystickSize,
      hud_button_scale: config.buttonScale,
      hud_button_opacity: config.buttonOpacity,
      look_sensitivity_x: config.sensX,
      look_sensitivity_y: config.sensY,
      ads_sensitivity_multiplier: config.adsSens,
      hud_custom_positions: Object.fromEntries(
        config.buttons.map((b) => [b.id, { x: b.x, y: b.y }])
      ),
    },
    null,
    2
  );

  const copyJson = async () => {
    await navigator.clipboard.writeText(saveJsonPayload);
    setCopiedJson(true);
    setTimeout(() => setCopiedJson(false), 1800);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4 border-b border-slate-800 pb-4">
        <div>
          <h2 className="text-lg font-semibold text-slate-100">Android Touchscreen HUD Studio</h2>
          <p className="text-sm text-slate-400">
            Drag buttons on the 1280x720 landscape viewport. Settings map directly to SaveManager and TouchControls.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => onChange(DEFAULT_HUD_CONFIG)}
            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-md border border-slate-700 bg-slate-900 hover:bg-slate-800 text-xs font-medium text-slate-200 whitespace-nowrap shrink-0"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Reset Defaults</span>
          </button>
          <button
            type="button"
            onClick={copyJson}
            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-md bg-amber-600 hover:bg-amber-500 text-xs font-semibold text-slate-950 whitespace-nowrap shrink-0"
          >
            {copiedJson ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
            <span>{copiedJson ? 'Copied JSON' : 'Copy Godot Config JSON'}</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div className="lg:col-span-8">
          <div
            ref={stageRef}
            className="relative w-full aspect-video rounded-lg border border-slate-700 bg-[#0d1522] overflow-hidden select-none"
          >
            <div className="absolute top-3 left-4 text-xs font-mono text-slate-400 pointer-events-none">
              HP 100 / 100 · OBJ: SECURE CENTRAL PLAZA
            </div>
            <div className="absolute top-3 right-4 px-2.5 py-1 rounded border border-slate-700 text-[11px] font-mono text-slate-300 pointer-events-none">
              PAUSE
            </div>

            <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-5 h-5 border border-slate-400/50 rounded-full pointer-events-none" />

            <div
              style={{
                left: '5.3%',
                bottom: '9%',
                width: `${13.1 * config.joystickSize}%`,
                height: `${23.3 * config.joystickSize}%`,
                opacity: config.buttonOpacity,
              }}
              className="absolute rounded-full border-2 border-slate-400/50 bg-slate-900/50 flex items-center justify-center pointer-events-none"
            >
              <div className="w-2/5 h-2/5 rounded-full bg-slate-200/30 border border-slate-300/60" />
            </div>

            {config.buttons.map((b) => (
              <button
                key={b.id}
                type="button"
                onPointerDown={(e) => handlePointerDown(b.id, e)}
                onPointerMove={(e) => handlePointerMove(b.id, e)}
                onPointerUp={handlePointerUp}
                style={{
                  left: `${(b.x / 1280) * 100}%`,
                  top: `${(b.y / 720) * 100}%`,
                  width: `${((b.w * config.buttonScale) / 1280) * 100}%`,
                  height: `${((b.h * config.buttonScale) / 720) * 100}%`,
                  opacity: config.buttonOpacity,
                }}
                className={`absolute rounded-full border-2 text-[11px] font-mono font-semibold flex items-center justify-center cursor-move transition-colors ${
                  b.id === 'BtnFire'
                    ? 'border-amber-400 bg-amber-500/20 text-amber-200'
                    : 'border-slate-300/60 bg-slate-900/70 text-slate-100'
                }`}
              >
                {b.label}
              </button>
            ))}
          </div>
        </div>

        <div className="lg:col-span-4 border border-slate-800 bg-[#111927] rounded-lg p-5 space-y-4">
          <h3 className="text-sm font-semibold text-slate-100">Tuning Parameters</h3>

          <div className="space-y-1.5">
            <div className="flex justify-between text-xs">
              <label htmlFor="hud-joy-size" className="text-slate-300">Joystick Size</label>
              <span className="font-mono text-amber-400 tabular-nums">{config.joystickSize.toFixed(2)}x</span>
            </div>
            <input
              id="hud-joy-size"
              type="range"
              min="0.7"
              max="1.4"
              step="0.05"
              value={config.joystickSize}
              onChange={(e) => onChange({ ...config, joystickSize: Number(e.target.value) })}
              className="w-full accent-amber-500"
            />
          </div>

          <div className="space-y-1.5">
            <div className="flex justify-between text-xs">
              <label htmlFor="hud-btn-scale" className="text-slate-300">Button Scale</label>
              <span className="font-mono text-amber-400 tabular-nums">{config.buttonScale.toFixed(2)}x</span>
            </div>
            <input
              id="hud-btn-scale"
              type="range"
              min="0.7"
              max="1.4"
              step="0.05"
              value={config.buttonScale}
              onChange={(e) => onChange({ ...config, buttonScale: Number(e.target.value) })}
              className="w-full accent-amber-500"
            />
          </div>

          <div className="space-y-1.5">
            <div className="flex justify-between text-xs">
              <label htmlFor="hud-opacity" className="text-slate-300">Control Opacity</label>
              <span className="font-mono text-amber-400 tabular-nums">{Math.round(config.buttonOpacity * 100)}%</span>
            </div>
            <input
              id="hud-opacity"
              type="range"
              min="0.3"
              max="1.0"
              step="0.05"
              value={config.buttonOpacity}
              onChange={(e) => onChange({ ...config, buttonOpacity: Number(e.target.value) })}
              className="w-full accent-amber-500"
            />
          </div>

          <div className="border-t border-slate-800 pt-3 space-y-3">
            <div className="space-y-1.5">
              <div className="flex justify-between text-xs">
                <label htmlFor="hud-sens-x" className="text-slate-300">Horizontal Sensitivity</label>
                <span className="font-mono text-slate-200 tabular-nums">{config.sensX.toFixed(2)}</span>
              </div>
              <input
                id="hud-sens-x"
                type="range"
                min="0.2"
                max="3.0"
                step="0.05"
                value={config.sensX}
                onChange={(e) => onChange({ ...config, sensX: Number(e.target.value) })}
                className="w-full accent-amber-500"
              />
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between text-xs">
                <label htmlFor="hud-sens-y" className="text-slate-300">Vertical Sensitivity</label>
                <span className="font-mono text-slate-200 tabular-nums">{config.sensY.toFixed(2)}</span>
              </div>
              <input
                id="hud-sens-y"
                type="range"
                min="0.2"
                max="3.0"
                step="0.05"
                value={config.sensY}
                onChange={(e) => onChange({ ...config, sensY: Number(e.target.value) })}
                className="w-full accent-amber-500"
              />
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between text-xs">
                <label htmlFor="hud-ads-sens" className="text-slate-300">ADS Sensitivity Mult</label>
                <span className="font-mono text-slate-200 tabular-nums">{config.adsSens.toFixed(2)}x</span>
              </div>
              <input
                id="hud-ads-sens"
                type="range"
                min="0.2"
                max="1.2"
                step="0.05"
                value={config.adsSens}
                onChange={(e) => onChange({ ...config, adsSens: Number(e.target.value) })}
                className="w-full accent-amber-500"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

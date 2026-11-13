import type { ParsedMission, ParsedWeapon } from '../types/studio';

interface SystemsViewProps {
  weapons: ParsedWeapon[];
  missions: ParsedMission[];
}

const FIRE_MODE_MAP: Record<string, string> = {
  '0': 'Single',
  '1': 'Burst (3-rd)',
  '2': 'Automatic',
};

const AI_STATES = [
  { name: 'IDLE', role: 'Stationary guard posture scanning LOS cone' },
  { name: 'PATROL', role: 'Follows NavigationAgent3D patrol waypoints' },
  { name: 'INVESTIGATE', role: 'Moves toward gunshot or sprint audio stimulus' },
  { name: 'SEARCH', role: 'Sweeps last known player coordinates on LOS loss' },
  { name: 'ALERT', role: 'Broadcasts squad alert to allies within 22m' },
  { name: 'CHASE', role: 'Pursues target via dynamic NavMesh steering' },
  { name: 'ATTACK', role: 'Fires burst volleys with difficulty reaction scaling' },
  { name: 'RETREAT', role: 'Repositions to nearest cover_points marker under 32% HP' },
  { name: 'STUNNED', role: 'Plays stagger hit animation on heavy impact' },
  { name: 'DEFEATED', role: 'Triggers score/objective completion & clean despawn' },
];

const GAME_MODES = [
  { title: 'Campaign', desc: '5 sequential tactical missions with checkpoints, briefings, and difficulty scaling.' },
  { title: 'Survival', desc: 'Escalating hostile waves across any map with wave ammo drops and high score tracking.' },
  { title: 'Training Range', desc: 'Dedicated range with moving targets, vault/crouch obstacles, and weapon racks.' },
  { title: 'Free Practice', desc: 'Open sector exploration with unlocked weapon testing and zero fail states.' },
];

export function SystemsView({ weapons, missions }: SystemsViewProps) {
  return (
    <div className="space-y-10">
      <section>
        <div className="mb-4">
          <h2 className="text-lg font-semibold text-slate-100">Modular Weapon Arsenal</h2>
          <p className="text-sm text-slate-400">
            Parsed directly from Godot WeaponData resources in res://resources/weapons/
          </p>
        </div>

        <div className="border border-slate-800 rounded-lg overflow-x-auto bg-[#111927]">
          <table className="w-full text-left border-collapse text-sm">
            <thead>
              <tr className="border-b border-slate-800 text-xs text-slate-400">
                <th className="py-3 px-4 font-medium">Weapon</th>
                <th className="py-3 px-4 font-medium">Category</th>
                <th className="py-3 px-4 font-medium">Fire Mode</th>
                <th className="py-3 px-4 font-medium text-right">Damage</th>
                <th className="py-3 px-4 font-medium text-right">Fire Rate</th>
                <th className="py-3 px-4 font-medium text-right">Mag / Reserve</th>
                <th className="py-3 px-4 font-medium text-right">Reload</th>
                <th className="py-3 px-4 font-medium text-right">ADS FOV</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/70">
              {weapons.map((w) => {
                const pellets = Number(w.pellets ?? '1');
                const dmgText = pellets > 1 ? `${w.damage} x ${pellets}` : w.damage;
                return (
                  <tr key={w.path} className="hover:bg-slate-800/40">
                    <td className="py-3 px-4 font-medium text-slate-100">
                      <span>{w.display_name}</span>
                      <span className="ml-2 text-xs font-mono text-slate-400">{w.icon_code}</span>
                    </td>
                    <td className="py-3 px-4 text-slate-300">{w.category_label}</td>
                    <td className="py-3 px-4 text-slate-300">{FIRE_MODE_MAP[w.fire_mode ?? '0'] ?? 'Single'}</td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums text-amber-400">{dmgText}</td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums text-slate-200">{w.fire_rate}/s</td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums text-slate-200">
                      {w.magazine_size} / {w.reserve_max}
                    </td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums text-slate-300">{w.reload_duration}s</td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums text-slate-300">{w.ads_fov} deg</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      <section>
        <div className="mb-4">
          <h2 className="text-lg font-semibold text-slate-100">Campaign Sectors & Missions</h2>
          <p className="text-sm text-slate-400">
            5 distinct 3D environments with NavigationRegion3D, lighting, weather particles, and multi-stage objectives
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {missions.map((m, idx) => (
            <div key={m.path} className="border border-slate-800 bg-[#111927] rounded-lg p-5 space-y-2.5">
              <div className="text-xs text-amber-400 font-medium">
                0{idx + 1}. {m.location_name} · {m.reward_credits} Credits
              </div>
              <h3 className="text-base font-semibold text-slate-100">{m.title}</h3>
              <p className="text-sm text-slate-400 leading-relaxed">{m.briefing}</p>
              <div className="pt-1 text-xs font-mono text-slate-500 truncate">{m.map_scene_path}</div>
            </div>
          ))}
        </div>
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <section className="border border-slate-800 bg-[#111927] rounded-lg p-5">
          <h2 className="text-base font-semibold text-slate-100 mb-1">Enemy AI 10-State Machine</h2>
          <p className="text-xs text-slate-400 mb-4">
            Driven by NavigationAgent3D, LOS RayCast3D, hearing radius, cover_points, and AnimationTree BlendSpace1D
          </p>
          <div className="divide-y divide-slate-800/70">
            {AI_STATES.map((st) => (
              <div key={st.name} className="py-2 flex items-baseline justify-between gap-4 text-xs">
                <span className="font-mono font-semibold text-amber-400 shrink-0">{st.name}</span>
                <span className="text-slate-300 text-right">{st.role}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="border border-slate-800 bg-[#111927] rounded-lg p-5">
          <h2 className="text-base font-semibold text-slate-100 mb-1">Playable Game Modes</h2>
          <p className="text-xs text-slate-400 mb-4">
            All 4 modes connected end-to-end via GameManager, LevelController, and SaveManager
          </p>
          <div className="divide-y divide-slate-800/70">
            {GAME_MODES.map((mode) => (
              <div key={mode.title} className="py-3 space-y-1">
                <div className="text-sm font-semibold text-slate-100">{mode.title}</div>
                <p className="text-xs text-slate-400 leading-relaxed">{mode.desc}</p>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

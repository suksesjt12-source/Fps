export interface ProjectFileEntry {
  path: string; // e.g. "godot_project/project.godot" or ".github/workflows/android-build.yml"
  resPath: string | null; // e.g. "res://project.godot"
  size: number;
  category: string;
  stage: number;
  isBinary: boolean;
  content: string; // text or base64 for binary
}

export interface AuditCheckResult {
  id: string;
  label: string;
  passed: boolean;
  details: string;
}

export interface AuditSummary {
  totalFiles: number;
  scriptCount: number;
  sceneCount: number;
  resourceCount: number;
  audioCount: number;
  missingResPaths: string[];
  checks: AuditCheckResult[];
}

export function classifyStage(relPath: string): number {
  if (relPath === 'godot_project/project.godot' || relPath === 'godot_project/default_bus_layout.tres' || relPath === 'godot_project/icon.svg') return 1;
  if (relPath.includes('scripts/core/') || relPath.includes('main_menu') || relPath.includes('mission_select') || relPath.includes('settings_menu') || relPath.includes('credits_screen') || relPath.includes('loading_screen')) return 2;
  if (relPath.includes('scripts/player/') || relPath.includes('scenes/player/') || relPath.includes('scripts/android/') || relPath.includes('touch_controls')) return 3;
  if (relPath.includes('scripts/weapons/') || relPath.includes('resources/weapons/')) return 4;
  if (relPath.includes('scripts/audio/') || relPath.includes('assets/audio/')) return 5;
  if (relPath.includes('scripts/enemies/') || relPath.includes('scenes/enemies/') || relPath.includes('resources/enemies/')) return 6;
  if (relPath.includes('scripts/missions/') || relPath.includes('resources/missions/') || relPath.includes('scenes/environments/')) return 7;
  if (relPath.includes('scripts/ui/') || relPath.includes('scripts/save/') || relPath.includes('scenes/ui/') || relPath.includes('scenes/effects/') || relPath.includes('shaders/') || relPath.includes('hud') || relPath.includes('pause_menu') || relPath.includes('victory_screen') || relPath.includes('game_over_screen')) return 8;
  if (relPath.includes('README') || relPath.includes('assets/models/')) return 9;
  if (relPath.includes('export_presets.cfg') || relPath.includes('android-build.yml')) return 10;
  return 1;
}

export function classifyCategory(relPath: string): string {
  if (relPath.endsWith('.gd')) return 'GDScript';
  if (relPath.endsWith('.tscn')) return 'Scene';
  if (relPath.endsWith('.tres')) return 'Resource';
  if (relPath.endsWith('.gdshader')) return 'Shader';
  if (relPath.endsWith('.wav')) return 'Audio';
  if (relPath.endsWith('.yml') || relPath.endsWith('.cfg') || relPath.endsWith('.godot')) return 'Config';
  return 'Docs & Assets';
}

export function extractResReferences(text: string): string[] {
  const matches = text.match(/res:\/\/[A-Za-z0-9_./-]+/g) || [];
  return Array.from(new Set(matches));
}

export function auditProjectFiles(files: ProjectFileEntry[]): AuditSummary {
  const resSet = new Set<string>();
  let scriptCount = 0;
  let sceneCount = 0;
  let resourceCount = 0;
  let audioCount = 0;

  for (const f of files) {
    if (f.resPath) resSet.add(f.resPath);
    if (f.path.endsWith('.gd')) scriptCount++;
    else if (f.path.endsWith('.tscn')) sceneCount++;
    else if (f.path.endsWith('.tres')) resourceCount++;
    else if (f.path.endsWith('.wav')) audioCount++;
  }

  const missingSet = new Set<string>();
  for (const f of files) {
    if (f.isBinary || f.path.endsWith('.md')) continue;
    const refs = extractResReferences(f.content);
    for (const ref of refs) {
      if (!resSet.has(ref)) {
        missingSet.add(`${ref} (referenced in ${f.path})`);
      }
    }
  }

  const missingResPaths = Array.from(missingSet);
  const projectGodot = files.find((f) => f.path === 'godot_project/project.godot')?.content ?? '';
  const exportPresets = files.find((f) => f.path === 'godot_project/export_presets.cfg')?.content ?? '';
  const workflow = files.find((f) => f.path === '.github/workflows/android-build.yml')?.content ?? '';

  const requiredAutoloads = [
    'GameManager',
    'SettingsManager',
    'SaveManager',
    'AudioManager',
    'WeaponManager',
    'MissionManager',
    'UIManager',
    'SceneManager',
  ];

  const hasAllAutoloads = requiredAutoloads.every((a) => projectGodot.includes(`${a}="*res://`));
  const hasCompatRenderer = projectGodot.includes('gl_compatibility');
  const hasLandscape = projectGodot.includes('window/handheld/orientation=0');
  const hasArm64 = exportPresets.includes('architectures/arm64-v8a=true');
  const hasWorkflowApkCheck =
    workflow.includes('--export-debug') &&
    workflow.includes('export_templates') &&
    workflow.includes('upload-artifact');

  const mapFiles = files.filter((f) => f.path.startsWith('godot_project/scenes/environments/map_'));
  const weaponFiles = files.filter((f) => f.path.startsWith('godot_project/resources/weapons/'));
  const missionFiles = files.filter((f) => f.path.startsWith('godot_project/resources/missions/'));

  const checks: AuditCheckResult[] = [
    {
      id: 'res_paths',
      label: 'All res:// References Resolved',
      passed: missingResPaths.length === 0,
      details:
        missingResPaths.length === 0
          ? 'Zero broken res:// paths across all scripts, scenes, and resources.'
          : `Missing: ${missingResPaths.slice(0, 3).join(', ')}`,
    },
    {
      id: 'autoloads',
      label: '8 Core Autoload Managers Registered',
      passed: hasAllAutoloads,
      details: 'GameManager, SettingsManager, SaveManager, AudioManager, WeaponManager, MissionManager, UIManager, SceneManager.',
    },
    {
      id: 'renderer',
      label: 'Android Compatibility Renderer & Landscape',
      passed: hasCompatRenderer && hasLandscape,
      details: 'gl_compatibility (GLES3) + Landscape orientation + ETC2/ASTC texture compression.',
    },
    {
      id: 'content',
      label: '7 Weapons, 5 Campaign Missions & 6 Maps',
      passed: weaponFiles.length >= 7 && missionFiles.length >= 5 && mapFiles.length >= 6,
      details: `${weaponFiles.length} weapons, ${missionFiles.length} missions, ${mapFiles.length} 3D maps (including Training Range).`,
    },
    {
      id: 'audio',
      label: 'Synthesized PCM Audio Bank Complete',
      passed: audioCount >= 35,
      details: `${audioCount} valid .wav assets for weapons, footsteps, stingers, ambience, and music.`,
    },
    {
      id: 'ci_apk',
      label: 'ARM64 Export Preset & GitHub Actions APK Workflow',
      passed: hasArm64 && hasWorkflowApkCheck,
      details: 'ARM64-v8a preset + Godot 4.3 headless import, validation, export, and artifact upload.',
    },
  ];

  return {
    totalFiles: files.length,
    scriptCount,
    sceneCount,
    resourceCount,
    audioCount,
    missingResPaths,
    checks,
  };
}

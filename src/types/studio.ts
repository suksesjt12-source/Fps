import type { AuditSummary, ProjectFileEntry } from '../utils/godotAuditor';

export interface ParsedWeapon {
  path: string;
  weapon_id?: string;
  display_name?: string;
  category_label?: string;
  fire_mode?: string;
  damage?: string;
  fire_rate?: string;
  magazine_size?: string;
  reserve_max?: string;
  reload_duration?: string;
  ads_fov?: string;
  pellets?: string;
  is_energy?: string;
  is_explosive?: string;
  icon_code?: string;
}

export interface ParsedMission {
  path: string;
  mission_id?: string;
  mission_index?: string;
  title?: string;
  location_name?: string;
  environment_theme?: string;
  map_scene_path?: string;
  briefing?: string;
  reward_credits?: string;
}

export interface ProjectPayload {
  files: ProjectFileEntry[];
  audit: AuditSummary;
  weapons: ParsedWeapon[];
  missions: ParsedMission[];
}

export interface TouchButtonPos {
  id: string;
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface HudLayoutConfig {
  joystickSize: number;
  buttonScale: number;
  buttonOpacity: number;
  sensX: number;
  sensY: number;
  adsSens: number;
  buttons: TouchButtonPos[];
}

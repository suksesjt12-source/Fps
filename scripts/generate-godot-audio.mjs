import fs from 'node:fs';
import path from 'node:path';

const SAMPLE_RATE = 22050;
const BASE_DIR = path.resolve(process.cwd(), 'godot_project', 'assets', 'audio');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeWav(relPath, samples) {
  const fullPath = path.join(BASE_DIR, relPath);
  ensureDir(path.dirname(fullPath));
  const numSamples = samples.length;
  const dataSize = numSamples * 2;
  const buf = Buffer.alloc(44 + dataSize);

  buf.write('RIFF', 0);
  buf.writeUInt32LE(36 + dataSize, 4);
  buf.write('WAVE', 8);
  buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16); // PCM
  buf.writeUInt16LE(1, 20);  // Mono
  buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(SAMPLE_RATE, 24);
  buf.writeUInt32LE(SAMPLE_RATE * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write('data', 36);
  buf.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < numSamples; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE(Math.round(s * 32767), 44 + i * 2);
  }
  fs.writeFileSync(fullPath, buf);
}

function synth(durationSec, fn) {
  const len = Math.floor(SAMPLE_RATE * durationSec);
  const out = new Float32Array(len);
  for (let i = 0; i < len; i++) {
    const t = i / SAMPLE_RATE;
    out[i] = fn(t, i, len);
  }
  return out;
}

function noise(seed) {
  const x = Math.sin(seed * 12.9898 + 78.233) * 43758.5453;
  return (x - Math.floor(x)) * 2 - 1;
}

// Gunfire synthesis
writeWav('sfx/fire_assault.wav', synth(0.18, (t) => {
  const env = Math.exp(-t * 28);
  const punch = Math.sin(2 * Math.PI * (180 * Math.exp(-t * 14)) * t);
  return (noise(t * 22050) * 0.65 + punch * 0.45) * env;
}));

writeWav('sfx/fire_compact.wav', synth(0.12, (t) => {
  const env = Math.exp(-t * 36);
  const punch = Math.sin(2 * Math.PI * (240 * Math.exp(-t * 18)) * t);
  return (noise(t * 22050) * 0.6 + punch * 0.4) * env;
}));

writeWav('sfx/fire_precision.wav', synth(0.32, (t) => {
  const env = Math.exp(-t * 14);
  const crack = Math.sin(2 * Math.PI * (140 * Math.exp(-t * 9)) * t);
  return (noise(t * 22050) * 0.72 + crack * 0.55) * env;
}));

writeWav('sfx/fire_energy.wav', synth(0.22, (t) => {
  const env = Math.exp(-t * 16);
  const freq = 960 * Math.exp(-t * 7.5) + 180;
  return (Math.sin(2 * Math.PI * freq * t) * 0.65 + Math.sin(2 * Math.PI * freq * 1.5 * t) * 0.25) * env;
}));

writeWav('sfx/fire_shotgun.wav', synth(0.36, (t) => {
  const env = Math.exp(-t * 11);
  const boom = Math.sin(2 * Math.PI * (110 * Math.exp(-t * 10)) * t);
  return (noise(t * 22050) * 0.8 + boom * 0.55) * env;
}));

writeWav('sfx/fire_sidearm.wav', synth(0.15, (t) => {
  const env = Math.exp(-t * 30);
  const snap = Math.sin(2 * Math.PI * (290 * Math.exp(-t * 20)) * t);
  return (noise(t * 22050) * 0.55 + snap * 0.45) * env;
}));

writeWav('sfx/fire_heavy_energy.wav', synth(0.45, (t) => {
  const env = Math.exp(-t * 8);
  const freq = 420 * Math.exp(-t * 4.5) + 65;
  return (Math.sin(2 * Math.PI * freq * t) * 0.7 + noise(t * 22050) * 0.35) * env;
}));

// Mechanical & player SFX
writeWav('sfx/weapon_reload.wav', synth(0.42, (t) => {
  const click1 = Math.exp(-Math.pow((t - 0.06) * 45, 2));
  const click2 = Math.exp(-Math.pow((t - 0.28) * 45, 2));
  return noise(t * 22050) * 0.45 * (click1 + click2);
}));

writeWav('sfx/weapon_equip.wav', synth(0.18, (t) => Math.sin(2 * Math.PI * 520 * t) * 0.15 * Math.exp(-t * 24) + noise(t * 22050) * 0.3 * Math.exp(-t * 28)));
writeWav('sfx/weapon_empty.wav', synth(0.08, (t) => Math.sin(2 * Math.PI * 1100 * t) * 0.35 * Math.exp(-t * 50)));
writeWav('sfx/weapon_pickup.wav', synth(0.22, (t) => Math.sin(2 * Math.PI * (t < 0.1 ? 520 : 780) * t) * 0.3 * Math.exp(-t * 14)));
writeWav('sfx/ui_click.wav', synth(0.06, (t) => Math.sin(2 * Math.PI * 880 * t) * 0.28 * Math.exp(-t * 60)));
writeWav('sfx/ui_hover.wav', synth(0.04, (t) => Math.sin(2 * Math.PI * 640 * t) * 0.16 * Math.exp(-t * 70)));
writeWav('sfx/hit_marker.wav', synth(0.07, (t) => Math.sin(2 * Math.PI * 1450 * t) * 0.38 * Math.exp(-t * 55)));
writeWav('sfx/player_hurt.wav', synth(0.22, (t) => (Math.sin(2 * Math.PI * 130 * t) * 0.5 + noise(t * 22050) * 0.35) * Math.exp(-t * 16)));
writeWav('sfx/footstep_concrete.wav', synth(0.1, (t) => (noise(t * 22050) * 0.4 + Math.sin(2 * Math.PI * 95 * t) * 0.3) * Math.exp(-t * 36)));
writeWav('sfx/footstep_sprint.wav', synth(0.11, (t) => (noise(t * 22050) * 0.5 + Math.sin(2 * Math.PI * 115 * t) * 0.35) * Math.exp(-t * 32)));
writeWav('sfx/player_jump.wav', synth(0.15, (t) => Math.sin(2 * Math.PI * (140 + t * 500) * t) * 0.25 * Math.exp(-t * 18)));
writeWav('sfx/player_land.wav', synth(0.16, (t) => (noise(t * 22050) * 0.45 + Math.sin(2 * Math.PI * 75 * t) * 0.45) * Math.exp(-t * 22)));
writeWav('sfx/player_crouch.wav', synth(0.12, (t) => noise(t * 22050) * 0.22 * Math.exp(-t * 24)));
writeWav('sfx/impact_metal.wav', synth(0.16, (t) => Math.sin(2 * Math.PI * 1760 * t) * 0.3 * Math.exp(-t * 25) + noise(t * 22050) * 0.2 * Math.exp(-t * 35)));
writeWav('sfx/impact_concrete.wav', synth(0.12, (t) => noise(t * 22050) * 0.35 * Math.exp(-t * 34)));
writeWav('sfx/explosion.wav', synth(0.65, (t) => (noise(t * 22050) * 0.65 + Math.sin(2 * Math.PI * (65 * Math.exp(-t * 3)) * t) * 0.6) * Math.exp(-t * 4.5)));
writeWav('sfx/enemy_alert.wav', synth(0.24, (t) => Math.sin(2 * Math.PI * (t < 0.12 ? 620 : 880) * t) * 0.32 * Math.exp(-t * 10)));
writeWav('sfx/enemy_defeated.wav', synth(0.28, (t) => Math.sin(2 * Math.PI * (240 * Math.exp(-t * 5)) * t) * 0.35 * Math.exp(-t * 9)));

// Gameplay stingers
writeWav('sfx/mission_start.wav', synth(0.55, (t) => (Math.sin(2 * Math.PI * 330 * t) + Math.sin(2 * Math.PI * 495 * t)) * 0.22 * Math.exp(-t * 3.5)));
writeWav('sfx/mission_complete.wav', synth(0.85, (t) => {
  const note = t < 0.25 ? 440 : (t < 0.5 ? 554.37 : 659.25);
  return Math.sin(2 * Math.PI * note * t) * 0.32 * Math.exp(-t * 2.1);
}));
writeWav('sfx/mission_failed.wav', synth(0.8, (t) => {
  const note = t < 0.35 ? 246.94 : 185.0;
  return Math.sin(2 * Math.PI * note * t) * 0.35 * Math.exp(-t * 2.4);
}));
writeWav('sfx/objective_updated.wav', synth(0.32, (t) => Math.sin(2 * Math.PI * (t < 0.14 ? 587.33 : 880.0) * t) * 0.28 * Math.exp(-t * 7)));
writeWav('sfx/checkpoint_activated.wav', synth(0.36, (t) => Math.sin(2 * Math.PI * (t < 0.16 ? 523.25 : 783.99) * t) * 0.28 * Math.exp(-t * 6)));
writeWav('sfx/warning_alert.wav', synth(0.38, (t) => Math.sin(2 * Math.PI * 740 * t) * 0.3 * (Math.sin(2 * Math.PI * 8 * t) > 0 ? 1 : 0.2)));

// Ambience loops (2.5s seamless)
writeWav('ambience/city_wind_ambience.wav', synth(2.5, (t) => (noise(t * 900) * 0.12 + Math.sin(2 * Math.PI * 55 * t) * 0.08)));
writeWav('ambience/desert_wind_ambience.wav', synth(2.5, (t) => (noise(t * 1400) * 0.16 * (0.7 + 0.3 * Math.sin(2 * Math.PI * 0.4 * t)))));
writeWav('ambience/arctic_storm_ambience.wav', synth(2.5, (t) => (noise(t * 2200) * 0.18 * (0.65 + 0.35 * Math.sin(2 * Math.PI * 0.8 * t)))));
writeWav('ambience/underground_machinery_ambience.wav', synth(2.5, (t) => (Math.sin(2 * Math.PI * 60 * t) * 0.14 + Math.sin(2 * Math.PI * 120 * t) * 0.08 + noise(t * 400) * 0.05)));
writeWav('ambience/harbor_rain_ambience.wav', synth(2.5, (t) => (noise(t * 8000) * 0.14 + Math.sin(2 * Math.PI * 72 * t) * 0.06)));

// Music loops/themes (4.0s tactical stems)
writeWav('music/main_menu_theme.wav', synth(4.0, (t) => {
  const arp = [110, 130.81, 164.81, 196][Math.floor(t * 2) % 4];
  return (Math.sin(2 * Math.PI * 55 * t) * 0.2 + Math.sin(2 * Math.PI * arp * t) * 0.12 * Math.exp(-(t % 0.5) * 4));
}));
writeWav('music/combat_tension_loop.wav', synth(4.0, (t) => {
  const beat = Math.exp(-(t % 0.5) * 10);
  const bass = Math.sin(2 * Math.PI * 65.41 * t) * 0.26 * beat;
  const pulse = Math.sin(2 * Math.PI * 130.81 * t) * 0.12 * Math.exp(-(t % 0.25) * 8);
  return bass + pulse;
}));
writeWav('music/victory_theme.wav', synth(2.4, (t) => {
  const chord = Math.sin(2 * Math.PI * 261.63 * t) + Math.sin(2 * Math.PI * 329.63 * t) + Math.sin(2 * Math.PI * 392.0 * t);
  return chord * 0.14 * Math.exp(-t * 1.1);
}));
writeWav('music/game_over_theme.wav', synth(2.4, (t) => {
  const chord = Math.sin(2 * Math.PI * 146.83 * t) + Math.sin(2 * Math.PI * 174.61 * t);
  return chord * 0.18 * Math.exp(-t * 1.2);
}));

console.log('Generated all 36 Godot PCM WAV audio assets under', BASE_DIR);

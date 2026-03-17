import { useCallback, useRef } from 'react';

const STORAGE_KEY_TSUMO = 'mahjong_sound_tsumo';
const STORAGE_KEY_RON = 'mahjong_sound_ron';
const STORAGE_KEY_ENABLED = 'mahjong_sound_enabled';

let audioCtx: AudioContext | null = null;
function getAudioCtx(): AudioContext {
  if (!audioCtx) audioCtx = new AudioContext();
  return audioCtx;
}

/** デフォルト: Web Audio APIでビープ音 */
function playDefaultTsumo() {
  const ctx = getAudioCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.frequency.value = 880;
  osc.type = 'sine';
  gain.gain.setValueAtTime(0.3, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
  osc.start(ctx.currentTime);
  osc.stop(ctx.currentTime + 0.5);
}

function playDefaultRon() {
  const ctx = getAudioCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.frequency.value = 660;
  osc.type = 'square';
  gain.gain.setValueAtTime(0.2, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.6);
  osc.start(ctx.currentTime);
  osc.stop(ctx.currentTime + 0.6);
}

function playCustomSound(base64: string) {
  const audio = new Audio(base64);
  audio.volume = 0.5;
  audio.play().catch(() => {});
}

export function isSoundEnabled(): boolean {
  return localStorage.getItem(STORAGE_KEY_ENABLED) !== 'false';
}

export function setSoundEnabled(enabled: boolean): void {
  localStorage.setItem(STORAGE_KEY_ENABLED, enabled ? 'true' : 'false');
}

export function getCustomSound(type: 'tsumo' | 'ron'): string | null {
  const key = type === 'tsumo' ? STORAGE_KEY_TSUMO : STORAGE_KEY_RON;
  return localStorage.getItem(key);
}

export function uploadCustomSound(type: 'tsumo' | 'ron', file: File): Promise<void> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const key = type === 'tsumo' ? STORAGE_KEY_TSUMO : STORAGE_KEY_RON;
      localStorage.setItem(key, reader.result as string);
      resolve();
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

export function resetCustomSound(type: 'tsumo' | 'ron'): void {
  const key = type === 'tsumo' ? STORAGE_KEY_TSUMO : STORAGE_KEY_RON;
  localStorage.removeItem(key);
}

export function useSound() {
  const playTsumo = useCallback(() => {
    if (!isSoundEnabled()) return;
    const custom = getCustomSound('tsumo');
    if (custom) playCustomSound(custom);
    else playDefaultTsumo();
  }, []);

  const playRon = useCallback(() => {
    if (!isSoundEnabled()) return;
    const custom = getCustomSound('ron');
    if (custom) playCustomSound(custom);
    else playDefaultRon();
  }, []);

  return { playTsumo, playRon };
}

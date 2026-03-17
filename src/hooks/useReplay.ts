import { useRef, useCallback } from 'react';

const STORAGE_KEY = 'mahjong_replays';

export interface ReplayAction {
  type: 'draw' | 'discard' | 'pon' | 'chi' | 'kan' | 'riichi' | 'tsumo_agari' | 'ron_agari' | 'round_start' | 'ryuukyoku';
  seat: number;
  tile?: { kind: string; suit: string; number: number; label: string };
  detail?: string;
  timestamp: number;
}

export interface ReplayData {
  id: string;
  date: string;
  actions: ReplayAction[];
}

export function useReplayRecorder() {
  const actions = useRef<ReplayAction[]>([]);

  const record = useCallback((action: Omit<ReplayAction, 'timestamp'>) => {
    actions.current.push({ ...action, timestamp: Date.now() });
  }, []);

  const getReplayData = useCallback((): ReplayData => ({
    id: Date.now().toString(),
    date: new Date().toLocaleString('ja-JP'),
    actions: [...actions.current],
  }), []);

  const reset = useCallback(() => { actions.current = []; }, []);

  return { record, getReplayData, reset };
}

export function saveReplay(data: ReplayData): void {
  const replays = listReplays();
  replays.unshift({ id: data.id, date: data.date });
  if (replays.length > 20) replays.length = 20;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(replays));
  localStorage.setItem(`${STORAGE_KEY}_${data.id}`, JSON.stringify(data));
}

export function getReplay(id: string): ReplayData | null {
  try {
    const data = localStorage.getItem(`${STORAGE_KEY}_${id}`);
    return data ? JSON.parse(data) : null;
  } catch { return null; }
}

export function listReplays(): { id: string; date: string }[] {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [];
  } catch { return []; }
}

export function deleteReplay(id: string): void {
  localStorage.removeItem(`${STORAGE_KEY}_${id}`);
  const replays = listReplays().filter(r => r.id !== id);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(replays));
}

const STORAGE_KEY = 'mahjong_match_history';

export interface MatchResult {
  id: string;
  date: string;
  mode: 'single' | 'multi';
  difficulty?: string;
  players: { name: string; score: number; jikaze: string }[];
  winner: string;
}

export function saveMatch(result: MatchResult): void {
  const history = getHistory();
  history.unshift(result);
  // 最大50件保持
  if (history.length > 50) history.length = 50;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(history));
}

export function getHistory(): MatchResult[] {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [];
  } catch { return []; }
}

export function clearHistory(): void {
  localStorage.removeItem(STORAGE_KEY);
}

export function getStats() {
  const history = getHistory();
  const total = history.length;
  const wins = history.filter(m => m.players[0]?.name === m.winner || m.winner.includes('あなた')).length;
  const scores = history.map(m => m.players[0]?.score ?? 0);
  const avg = total > 0 ? Math.round(scores.reduce((a, b) => a + b, 0) / total) : 0;
  const best = total > 0 ? Math.max(...scores) : 0;
  return { totalGames: total, wins, winRate: total > 0 ? Math.round(wins / total * 100) : 0, avgScore: avg, bestScore: best };
}

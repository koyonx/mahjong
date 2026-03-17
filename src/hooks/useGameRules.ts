const STORAGE_KEY = 'mahjong_game_rules';

export interface GameRules {
  redDora: boolean;
  openTanyao: boolean;
  startScore: number;
  gameMode: 'hanchan' | 'tonpuu';
}

const DEFAULT_RULES: GameRules = {
  redDora: true,
  openTanyao: true,
  startScore: 25000,
  gameMode: 'hanchan',
};

export function loadGameRules(): GameRules {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) return { ...DEFAULT_RULES, ...JSON.parse(saved) };
  } catch {}
  return { ...DEFAULT_RULES };
}

export function saveGameRules(rules: GameRules): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(rules));
}

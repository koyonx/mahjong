/**
 * OCaml麻雀ロジックへのTypeScriptブリッジ
 * Melange経由でコンパイルされたJSモジュールをラップする
 */

// === 型定義 ===

export interface Tile {
  kind: 'suhai' | 'jihai';
  suit: 'manzu' | 'pinzu' | 'souzu' | 'kaze' | 'sangen';
  number: number;
  label: string;
}

export interface Player {
  hand: Tile[] | null;
  hand_count: number;
  kawa: Tile[];
  score: number;
  is_riichi: boolean;
  is_menzen: boolean;
  jikaze: 'ton' | 'nan' | 'sha' | 'pei';
}

export type Phase = 'waiting_draw' | 'waiting_discard' | 'waiting_call' | 'round_end' | 'game_end';

export interface GameState {
  players: Player[];
  current_turn: number;
  phase: Phase;
  bakaze: 'ton' | 'nan' | 'sha' | 'pei';
  kyoku: number;
  honba: number;
  remaining_tiles: number;
  last_discard: Tile | null;
}

export interface Yaku {
  name: string;
  han: number;
}

export interface Payment {
  kind: 'ron' | 'tsumo_oya' | 'tsumo_ko';
  ron?: number;
  oya_pay?: number;
  ko_pay?: number;
}

export interface AgariResult {
  state: GameState;
  yakus: Yaku[];
  han: number;
  fu: number;
  total: number;
  payment: Payment;
}

// === Melange出力のインポート ===

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let mahjongJs: any = null;

export async function initMahjong(): Promise<void> {
  mahjongJs = await import('./generated/src/bindings/mahjong_js.js');
}

// === API関数 ===

function parse<T>(json: string): T | null {
  if (json === 'null') return null;
  try {
    return JSON.parse(json) as T;
  } catch {
    return null;
  }
}

export function startGame(): GameState {
  const json = mahjongJs.start_game();
  return JSON.parse(json) as GameState;
}

export function getState(): GameState | null {
  return parse<GameState>(mahjongJs.get_state());
}

export function drawTile(): GameState | null {
  return parse<GameState>(mahjongJs.draw_tile());
}

export function discardTile(tile: Tile): GameState | null {
  return parse<GameState>(mahjongJs.discard_tile(tile.kind, tile.suit, tile.number));
}

export function advanceTurn(): GameState | null {
  return parse<GameState>(mahjongJs.advance_turn());
}

export function checkTsumoAgari(): AgariResult | null {
  return parse<AgariResult>(mahjongJs.check_tsumo());
}

export function checkRon(winnerSeat: number): AgariResult | null {
  return parse<AgariResult>(mahjongJs.check_ron(winnerSeat));
}

export function declareRiichi(): GameState | null {
  return parse<GameState>(mahjongJs.declare_riichi());
}

export function getTenpaiTiles(): Tile[] {
  return JSON.parse(mahjongJs.get_tenpai()) as Tile[];
}

export function nextRound(oyaWon: boolean): GameState | null {
  return parse<GameState>(mahjongJs.next_round(oyaWon));
}

// === AI ===

export interface AiAction {
  action: 'tsumo' | 'discard' | 'riichi';
  tile?: Tile;
}

export function aiDecide(seat: number): AiAction | null {
  return parse<AiAction>(mahjongJs.ai_decide(seat));
}

// === ユーティリティ ===

/** 風の日本語名 */
export function kazeToJa(kaze: string): string {
  const map: Record<string, string> = { ton: '東', nan: '南', sha: '西', pei: '北' };
  return map[kaze] ?? kaze;
}

/** 牌の日本語表示名 */
export function tileToDisplay(tile: Tile): string {
  if (tile.kind === 'suhai') {
    const suitMap: Record<string, string> = { manzu: '萬', pinzu: '筒', souzu: '索' };
    return `${tile.number}${suitMap[tile.suit]}`;
  }
  const jihaiMap: Record<number, string> = {
    1: '東', 2: '南', 3: '西', 4: '北', 5: '白', 6: '發', 7: '中',
  };
  return jihaiMap[tile.number] ?? '';
}

/** フェーズの日本語表示 */
export function phaseToJa(phase: Phase): string {
  const map: Record<Phase, string> = {
    waiting_draw: 'ツモ待ち',
    waiting_discard: '打牌待ち',
    waiting_call: '鳴き判定',
    round_end: '局終了',
    game_end: 'ゲーム終了',
  };
  return map[phase];
}

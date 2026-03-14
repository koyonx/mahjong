/**
 * ゲーム進行管理 - Melange出力のサーバー版バインディングをラップ
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let mahjong: any = null;

export async function initGameEngine(): Promise<void> {
  mahjong = await import('../../src/generated/src/bindings/mahjong_server_js.js');
}

interface Tile {
  kind: string;
  suit: string;
  number: number;
  label: string;
}

interface AiAction {
  action: 'tsumo' | 'discard' | 'riichi';
  tile?: Tile;
}

function parse<T>(json: string): T | null {
  if (!json || json === 'null') return null;
  try {
    return JSON.parse(json) as T;
  } catch {
    return null;
  }
}

export function createRoom(roomId: string): boolean {
  const result = parse<{ ok: boolean }>(mahjong.create_room(roomId));
  return result?.ok ?? false;
}

export function destroyRoom(roomId: string): void {
  mahjong.destroy_room(roomId);
}

export function startGame(roomId: string): boolean {
  const result = parse<{ ok: boolean }>(mahjong.start_game(roomId));
  return result?.ok ?? false;
}

export function getState(roomId: string, viewerSeat: number): string {
  return mahjong.get_state(roomId, viewerSeat);
}

export function getCurrentTurn(roomId: string): number {
  return mahjong.get_current_turn(roomId);
}

export function getPhase(roomId: string): string {
  const raw = mahjong.get_phase(roomId);
  try {
    return JSON.parse(raw);
  } catch {
    return 'unknown';
  }
}

export function drawTile(roomId: string): boolean {
  const result = parse<{ ok: boolean }>(mahjong.draw_tile(roomId));
  return result?.ok ?? false;
}

export function discardTile(roomId: string, tile: Tile): boolean {
  const result = parse<{ ok: boolean }>(
    mahjong.discard_tile(roomId, tile.kind, tile.suit, tile.number)
  );
  return result?.ok ?? false;
}

export function advanceTurn(roomId: string): boolean {
  const result = parse<{ ok: boolean }>(mahjong.advance_turn(roomId));
  return result?.ok ?? false;
}

export interface AgariResultServer {
  state: unknown;
  yakus: { name: string; han: number }[];
  han: number;
  fu: number;
  total: number;
  payment: { kind: string; ron?: number; oya_pay?: number; ko_pay?: number };
  winner: number;
}

export function checkTsumo(roomId: string): AgariResultServer | null {
  return parse<AgariResultServer>(mahjong.check_tsumo(roomId));
}

export function checkRon(roomId: string, seat: number): AgariResultServer | null {
  return parse<AgariResultServer>(mahjong.check_ron(roomId, seat));
}

export function declareRiichi(roomId: string): boolean {
  const result = parse<{ ok: boolean }>(mahjong.declare_riichi(roomId));
  return result?.ok ?? false;
}

export function aiDecide(roomId: string, seat: number): AiAction | null {
  return parse<AiAction>(mahjong.ai_decide(roomId, seat));
}

export function getTenpai(roomId: string): Tile[] {
  try {
    return JSON.parse(mahjong.get_tenpai(roomId)) as Tile[];
  } catch {
    return [];
  }
}

export function nextRound(roomId: string, oyaWon: boolean): boolean {
  const result = parse<{ ok: boolean }>(mahjong.next_round(roomId, oyaWon));
  return result?.ok ?? false;
}

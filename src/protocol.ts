/**
 * クライアント・サーバー間のWebSocketプロトコル定義
 */

import type { Tile, GameState, AgariResult } from './mahjong-bridge';

// === Client -> Server ===

export type ClientMessage =
  | { type: 'create_room'; playerName: string }
  | { type: 'join_room'; roomId: string; playerName: string }
  | { type: 'start_game' }
  | { type: 'discard'; tile: Tile }
  | { type: 'tsumo' }
  | { type: 'riichi'; tile: Tile }
  | { type: 'ron' }
  | { type: 'skip_call' };

// === Server -> Client ===

export interface PlayerInfo {
  name: string;
  seat: number;
  isHuman: boolean;
}

export type ServerMessage =
  | { type: 'room_created'; roomId: string; seat: number }
  | { type: 'room_joined'; roomId: string; seat: number }
  | { type: 'room_left' }
  | { type: 'seat_assigned'; seat: number }
  | { type: 'player_list'; players: PlayerInfo[] }
  | { type: 'game_state'; state: GameState }
  | { type: 'your_turn'; canTsumo: boolean; canRiichi: boolean; tenpaiTiles: Tile[] }
  | { type: 'can_call'; canPon: boolean; chiOptions: Tile[][] }
  | { type: 'can_ron' }
  | { type: 'agari'; result: AgariResult; winnerSeat: number; winnerName: string }
  | { type: 'round_end'; reason: string }
  | { type: 'game_end'; finalScores: { name: string; score: number }[] }
  | { type: 'message'; text: string }
  | { type: 'error'; message: string };

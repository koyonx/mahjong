import { useState, useEffect, useCallback, useRef } from 'react';
import type { GameState, Tile, AgariResult } from '../mahjong-bridge';
import type { ServerMessage, PlayerInfo } from '../protocol';

interface MultiplayerState {
  connected: boolean;
  roomId: string | null;
  seat: number;
  players: PlayerInfo[];
  gameState: GameState | null;
  agariResult: { result: AgariResult; winnerSeat: number; winnerName: string } | null;
  turnInfo: { canTsumo: boolean; canRiichi: boolean; tenpaiTiles: Tile[] } | null;
  messages: string[];
  error: string | null;
  gameEnd: { name: string; score: number }[] | null;
}

export function useMultiplayer() {
  const wsRef = useRef<WebSocket | null>(null);
  const [state, setState] = useState<MultiplayerState>({
    connected: false,
    roomId: null,
    seat: -1,
    players: [],
    gameState: null,
    agariResult: null,
    turnInfo: null,
    messages: [],
    error: null,
    gameEnd: null,
  });

  const connect = useCallback(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws`;
    const ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      wsRef.current = ws;
      setState(s => ({ ...s, connected: true, error: null }));
    };

    ws.onclose = () => {
      wsRef.current = null;
      setState(s => ({ ...s, connected: false }));
      // 再接続
      setTimeout(connect, 3000);
    };

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data) as ServerMessage;
      handleMessage(msg);
    };

    ws.onerror = () => {
      setState(s => ({ ...s, error: 'サーバーに接続できません' }));
    };
  }, []);

  const handleMessage = useCallback((msg: ServerMessage) => {
    switch (msg.type) {
      case 'room_created':
        setState(s => ({ ...s, roomId: msg.roomId, seat: msg.seat }));
        break;
      case 'room_joined':
        setState(s => ({ ...s, roomId: msg.roomId, seat: msg.seat }));
        break;
      case 'player_list':
        setState(s => ({ ...s, players: msg.players }));
        break;
      case 'game_state':
        setState(s => ({ ...s, gameState: msg.state, turnInfo: null }));
        break;
      case 'your_turn':
        setState(s => ({
          ...s,
          turnInfo: {
            canTsumo: msg.canTsumo,
            canRiichi: msg.canRiichi,
            tenpaiTiles: msg.tenpaiTiles,
          },
        }));
        break;
      case 'agari':
        setState(s => ({
          ...s,
          agariResult: {
            result: msg.result as AgariResult,
            winnerSeat: msg.winnerSeat,
            winnerName: msg.winnerName,
          },
        }));
        break;
      case 'round_end':
        setState(s => ({
          ...s,
          messages: [...s.messages.slice(-9), msg.reason],
        }));
        break;
      case 'game_end':
        setState(s => ({ ...s, gameEnd: msg.finalScores }));
        break;
      case 'message':
        setState(s => ({
          ...s,
          messages: [...s.messages.slice(-9), msg.text],
        }));
        break;
      case 'error':
        setState(s => ({ ...s, error: msg.message }));
        break;
      case 'can_ron':
        // TODO: ロン選択UIの表示
        break;
    }
  }, []);

  useEffect(() => {
    connect();
    return () => {
      wsRef.current?.close();
    };
  }, [connect]);

  const send = useCallback((msg: unknown) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(msg));
    }
  }, []);

  const createRoom = useCallback((playerName: string) => {
    send({ type: 'create_room', playerName });
  }, [send]);

  const joinRoom = useCallback((roomId: string, playerName: string) => {
    send({ type: 'join_room', roomId, playerName });
  }, [send]);

  const startGame = useCallback(() => {
    send({ type: 'start_game' });
  }, [send]);

  const discard = useCallback((tile: Tile) => {
    send({ type: 'discard', tile });
  }, [send]);

  const tsumo = useCallback(() => {
    send({ type: 'tsumo' });
  }, [send]);

  const riichi = useCallback((tile: Tile) => {
    send({ type: 'riichi', tile });
  }, [send]);

  const clearAgari = useCallback(() => {
    setState(s => ({ ...s, agariResult: null }));
  }, []);

  return {
    ...state,
    createRoom,
    joinRoom,
    startGame,
    discard,
    tsumo,
    riichi,
    clearAgari,
  };
}

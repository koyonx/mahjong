import { createServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import {
  createRoom, joinRoom, getRoom, getRoomBySocket, getSeatBySocket,
  removePlayer, startGame as startRoomGame,
  broadcastToRoom, sendToSeat, cleanupRooms, type Room,
} from './room-manager.ts';
import {
  initGameEngine,
  createRoom as createGameRoom,
  startGame as startGameEngine,
  getState, getCurrentTurn, getPhase,
  drawTile, discardTile, advanceTurn,
  checkTsumo, checkRon, declareRiichi,
  aiDecide, getTenpai, nextRound,
  canPon, doPon, canChi, doChi,
} from './game-controller.ts';

const PORT = Number(process.env.PORT) || 8080;

async function main() {
  await initGameEngine();
  console.log('Mahjong game engine initialized');

  const server = createServer((req, res) => {
    if (req.url === '/health') {
      res.writeHead(200);
      res.end('ok');
    } else {
      res.writeHead(404);
      res.end();
    }
  });

  const wss = new WebSocketServer({ server });

  wss.on('connection', (ws) => {
    console.log('Client connected');

    ws.on('message', (data) => {
      try {
        const msg = JSON.parse(data.toString());
        handleMessage(ws, msg);
      } catch (e) {
        sendError(ws, 'メッセージの解析に失敗しました');
      }
    });

    ws.on('close', () => {
      const room = getRoomBySocket(ws);
      if (room) {
        removePlayer(ws);
        broadcastPlayerList(room);
      }
      console.log('Client disconnected');
    });
  });

  // 定期的にルームをクリーンアップ
  setInterval(cleanupRooms, 5 * 60 * 1000);

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Mahjong server listening on port ${PORT}`);
  });
}

function sendJson(ws: WebSocket, msg: unknown): void {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

function sendError(ws: WebSocket, message: string): void {
  sendJson(ws, { type: 'error', message });
}

function broadcastPlayerList(room: Room): void {
  const players = room.players.map(p => ({
    name: p.name,
    seat: p.seat,
    isHuman: p.isHuman,
  }));
  broadcastToRoom(room, () => JSON.stringify({ type: 'player_list', players }));
}

function broadcastGameState(room: Room): void {
  broadcastToRoom(room, (seat) => {
    const state = getState(room.id, seat);
    return JSON.stringify({ type: 'game_state', state: JSON.parse(state) });
  });
}

function handleMessage(ws: WebSocket, msg: { type: string; [key: string]: unknown }): void {
  switch (msg.type) {
    case 'create_room':
      handleCreateRoom(ws, msg.playerName as string, msg.gameMode as string | undefined);
      break;
    case 'join_room':
      handleJoinRoom(ws, msg.roomId as string, msg.playerName as string);
      break;
    case 'start_game':
      handleStartGame(ws);
      break;
    case 'discard':
      handleDiscard(ws, msg.tile as { kind: string; suit: string; number: number; label: string });
      break;
    case 'tsumo':
      handleTsumo(ws);
      break;
    case 'riichi':
      handleRiichi(ws, msg.tile as { kind: string; suit: string; number: number; label: string });
      break;
    case 'ron':
      handleRon(ws);
      break;
    case 'pon':
      handlePon(ws);
      break;
    case 'chi':
      handleChi(ws, msg.tiles as { kind: string; suit: string; number: number; label: string }[]);
      break;
    case 'skip_call':
      handleSkipCall(ws);
      break;
    case 'leave_room':
      handleLeaveRoom(ws);
      break;
    default:
      sendError(ws, `不明なメッセージタイプ: ${msg.type}`);
  }
}

function handleCreateRoom(ws: WebSocket, playerName: string, gameMode?: string): void {
  const mode = (gameMode === 'tonpuu' ? 'tonpuu' : 'hanchan') as 'tonpuu' | 'hanchan';
  const { roomId, seat } = createRoom(ws, playerName, mode);
  createGameRoom(roomId);
  sendJson(ws, { type: 'room_created', roomId, seat });

  const room = getRoom(roomId)!;
  broadcastPlayerList(room);
}

function handleJoinRoom(ws: WebSocket, roomId: string, playerName: string): void {
  const result = joinRoom(ws, roomId, playerName);
  if ('error' in result) {
    sendError(ws, result.error);
    return;
  }

  sendJson(ws, { type: 'room_joined', roomId, seat: result.seat });

  const room = getRoom(roomId)!;
  broadcastPlayerList(room);
  broadcastToRoom(room, () => JSON.stringify({
    type: 'message',
    text: `${playerName} が参加しました`,
  }));
}

function handleStartGame(ws: WebSocket): void {
  const room = getRoomBySocket(ws);
  if (!room) return sendError(ws, 'ルームに参加していません');
  if (room.hostWs !== ws) return sendError(ws, 'ホストのみゲームを開始できます');
  if (room.status !== 'waiting') return sendError(ws, 'ゲームは既に開始されています');

  startRoomGame(room.id);
  startGameEngine(room.id);

  // シャッフル後の座席を各プレイヤーに通知
  for (const player of room.players) {
    if (player.ws && player.ws.readyState === 1) {
      sendJson(player.ws, { type: 'seat_assigned', seat: player.seat });
    }
  }

  broadcastGameState(room);
  notifyCurrentTurn(room);
  broadcastToRoom(room, () => JSON.stringify({ type: 'message', text: 'ゲーム開始！' }));

  // 最初のターンがAIなら自動進行
  processAiTurns(room);
}

function handleDiscard(ws: WebSocket, tile: { kind: string; suit: string; number: number; label: string }): void {
  const room = getRoomBySocket(ws);
  if (!room) return;

  const seat = getSeatBySocket(ws);
  const currentTurn = getCurrentTurn(room.id);
  if (seat !== currentTurn) return sendError(ws, 'あなたのターンではありません');

  const phase = getPhase(room.id);
  if (phase !== 'waiting_discard') return sendError(ws, '打牌フェーズではありません');

  if (!discardTile(room.id, tile)) return sendError(ws, '打牌に失敗しました');

  broadcastGameState(room);

  // ロン判定
  processAfterDiscard(room);
}

function handleTsumo(ws: WebSocket): void {
  const room = getRoomBySocket(ws);
  if (!room) return;

  const seat = getSeatBySocket(ws);
  const currentTurn = getCurrentTurn(room.id);
  if (seat !== currentTurn) return;

  const result = checkTsumo(room.id);
  if (!result) return sendError(ws, 'ツモ和了できません');

  const winner = room.players.find(p => p.seat === result.winner);
  broadcastToRoom(room, () => JSON.stringify({
    type: 'agari',
    result: {
      yakus: result.yakus,
      han: result.han,
      fu: result.fu,
      total: result.total,
      payment: result.payment,
    },
    winnerSeat: result.winner,
    winnerName: winner?.name ?? '',
  }));

  broadcastGameState(room);

  // 次の局へ
  setTimeout(() => advanceToNextRound(room), 3000);
}

function handleRiichi(ws: WebSocket, tile: { kind: string; suit: string; number: number; label: string }): void {
  const room = getRoomBySocket(ws);
  if (!room) return;

  const seat = getSeatBySocket(ws);
  const currentTurn = getCurrentTurn(room.id);
  if (seat !== currentTurn) return;

  if (!declareRiichi(room.id)) return sendError(ws, 'リーチできません');

  broadcastToRoom(room, () => JSON.stringify({
    type: 'message',
    text: `${room.players[seat].name} がリーチ！`,
  }));

  // リーチ後の打牌
  if (!discardTile(room.id, tile)) return;
  broadcastGameState(room);
  processAfterDiscard(room);
}

function handleRon(ws: WebSocket): void {
  const room = getRoomBySocket(ws);
  if (!room) return;

  const seat = getSeatBySocket(ws);
  const result = checkRon(room.id, seat);
  if (!result) return sendError(ws, 'ロンできません');

  const winner = room.players.find(p => p.seat === result.winner);
  broadcastToRoom(room, () => JSON.stringify({
    type: 'agari',
    result: {
      yakus: result.yakus,
      han: result.han,
      fu: result.fu,
      total: result.total,
      payment: result.payment,
    },
    winnerSeat: result.winner,
    winnerName: winner?.name ?? '',
  }));

  broadcastGameState(room);

  setTimeout(() => advanceToNextRound(room), 3000);
}

function handleLeaveRoom(ws: WebSocket): void {
  const room = getRoomBySocket(ws);
  if (!room) return;

  const player = room.players.find(p => p.ws === ws);
  const name = player?.name ?? '';

  removePlayer(ws);
  sendJson(ws, { type: 'room_left' });

  if (room.players.length > 0) {
    broadcastPlayerList(room);
    broadcastToRoom(room, () => JSON.stringify({
      type: 'message',
      text: `${name} が退出しました`,
    }));
  }
}

function handlePon(ws: WebSocket): void {
  const room = getRoomBySocket(ws);
  if (!room) return;
  const seat = getSeatBySocket(ws);

  if (doPon(room.id, seat)) {
    broadcastToRoom(room, () => JSON.stringify({
      type: 'message',
      text: `${room.players.find(p => p.seat === seat)?.name} がポン！`,
    }));
    broadcastGameState(room);
    notifyCurrentTurn(room);
  } else {
    sendError(ws, 'ポンできません');
  }
}

function handleChi(ws: WebSocket, tiles: { kind: string; suit: string; number: number; label: string }[]): void {
  const room = getRoomBySocket(ws);
  if (!room) return;
  const seat = getSeatBySocket(ws);

  if (tiles.length === 2 && doChi(room.id, seat, tiles[0] as any, tiles[1] as any)) {
    broadcastToRoom(room, () => JSON.stringify({
      type: 'message',
      text: `${room.players.find(p => p.seat === seat)?.name} がチー！`,
    }));
    broadcastGameState(room);
    notifyCurrentTurn(room);
  } else {
    sendError(ws, 'チーできません');
  }
}

function handleSkipCall(ws: WebSocket): void {
  const room = getRoomBySocket(ws);
  if (!room) return;
  // スキップ: 鳴き判定待ちを解除して次の手番に進む
  continueAfterCalls(room);
}

function processAfterDiscard(room: Room): void {
  const currentTurn = getCurrentTurn(room.id);

  // ロン判定（AIは自動、人間はcan_ronで通知 → 簡略化: 全員自動）
  for (const player of room.players) {
    if (player.seat === currentTurn) continue;

    const ronResult = checkRon(room.id, player.seat);
    if (ronResult) {
      broadcastToRoom(room, () => JSON.stringify({
        type: 'agari',
        result: {
          yakus: ronResult.yakus, han: ronResult.han,
          fu: ronResult.fu, total: ronResult.total,
          payment: ronResult.payment,
        },
        winnerSeat: ronResult.winner,
        winnerName: player.name,
      }));
      broadcastGameState(room);
      setTimeout(() => advanceToNextRound(room), 3000);
      return;
    }
  }

  // ポン・チー判定
  let hasHumanCall = false;
  for (const player of room.players) {
    if (player.seat === currentTurn) continue;

    if (player.isHuman && player.ws) {
      const ponAvail = canPon(room.id, player.seat);
      const chiOptions = canChi(room.id, player.seat);
      if (ponAvail || chiOptions.length > 0) {
        sendJson(player.ws, {
          type: 'can_call',
          canPon: ponAvail,
          chiOptions,
        });
        hasHumanCall = true;
      }
    } else if (!player.isHuman) {
      // AIのポン判定（簡略化: AIはポンしない、チーもしない）
    }
  }

  if (hasHumanCall) {
    // 人間の鳴き判定を待つ（タイムアウト: 10秒で自動スキップ）
    setTimeout(() => {
      const phase = getPhase(room.id);
      if (phase === 'waiting_call') {
        continueAfterCalls(room);
      }
    }, 10000);
    return;
  }

  continueAfterCalls(room);
}

function continueAfterCalls(room: Room): void {
  advanceTurn(room.id);
  drawTile(room.id);
  broadcastGameState(room);

  const phase = getPhase(room.id);
  if (phase === 'round_end') {
    broadcastToRoom(room, () => JSON.stringify({ type: 'round_end', reason: '流局' }));
    setTimeout(() => advanceToNextRound(room, false), 2000);
    return;
  }

  notifyCurrentTurn(room);
  processAiTurns(room);
}

function notifyCurrentTurn(room: Room): void {
  const currentTurn = getCurrentTurn(room.id);
  const player = room.players.find(p => p.seat === currentTurn);

  if (player?.isHuman && player.ws) {
    const phase = getPhase(room.id);
    if (phase === 'waiting_discard') {
      const tenpaiTiles = getTenpai(room.id);

      // aiDecideでツモ和了可否を判定（副作用なし）
      const action = aiDecide(room.id, currentTurn);
      const canTsumo = action?.action === 'tsumo';

      sendJson(player.ws, {
        type: 'your_turn',
        canTsumo,
        canRiichi: false,
        tenpaiTiles,
      });
    }
  }
}

function processAiTurns(room: Room): void {
  const currentTurn = getCurrentTurn(room.id);
  const player = room.players.find(p => p.seat === currentTurn);

  if (!player || player.isHuman) return;

  const phase = getPhase(room.id);
  if (phase !== 'waiting_discard') return;

  setTimeout(() => {
    const action = aiDecide(room.id, currentTurn);
    if (!action) return;

    if (action.action === 'tsumo') {
      const result = checkTsumo(room.id);
      if (result) {
        broadcastToRoom(room, () => JSON.stringify({
          type: 'agari',
          result: {
            yakus: result.yakus,
            han: result.han,
            fu: result.fu,
            total: result.total,
            payment: result.payment,
          },
          winnerSeat: result.winner,
          winnerName: player.name,
        }));
        broadcastGameState(room);

        setTimeout(() => advanceToNextRound(room), 3000);
        return;
      }
    }

    if (action.action === 'riichi') {
      declareRiichi(room.id);
      broadcastToRoom(room, () => JSON.stringify({
        type: 'message',
        text: `${player.name} がリーチ！`,
      }));
    }

    if (action.tile) {
      discardTile(room.id, action.tile);
      broadcastGameState(room);
      setTimeout(() => processAfterDiscard(room), 500);
    }
  }, 800);
}

/** 次の局に進む、または東風戦終了チェック */
function advanceToNextRound(room: Room, wasAgari = true): void {
  nextRound(room.id, false, wasAgari);
  const newPhase = getPhase(room.id);

  // 東風戦: 南場に入ったら終了
  if (room.gameMode === 'tonpuu') {
    const stateJson = getState(room.id, 0);
    const st = JSON.parse(stateJson);
    if (st.bakaze === 'nan') {
      handleGameEnd(room);
      return;
    }
  }

  if (newPhase === 'game_end') {
    handleGameEnd(room);
  } else {
    drawTile(room.id);
    broadcastGameState(room);
    notifyCurrentTurn(room);
    processAiTurns(room);
  }
}

function handleGameEnd(room: Room): void {
  const finalScores = room.players.map(p => {
    const stateJson = getState(room.id, p.seat);
    const state = JSON.parse(stateJson);
    return {
      name: p.name,
      score: state.players[p.seat]?.score ?? 0,
    };
  });

  broadcastToRoom(room, () => JSON.stringify({
    type: 'game_end',
    finalScores: finalScores.sort((a, b) => b.score - a.score),
  }));

  room.status = 'finished';
}

main().catch(console.error);

import type { WebSocket } from 'ws';

export interface PlayerInfo {
  name: string;
  seat: number;
  isHuman: boolean;
  ws: WebSocket | null;
}

export type GameMode = 'tonpuu' | 'hanchan';

export interface Room {
  id: string;
  players: PlayerInfo[];
  hostWs: WebSocket;
  status: 'waiting' | 'playing' | 'finished';
  gameMode: GameMode;
  createdAt: number;
}

const rooms = new Map<string, Room>();
const socketToRoom = new Map<WebSocket, string>();

function generateRoomId(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let id = '';
  for (let i = 0; i < 6; i++) {
    id += chars[Math.floor(Math.random() * chars.length)];
  }
  return id;
}

export function createRoom(ws: WebSocket, playerName: string, gameMode: GameMode = 'hanchan'): { roomId: string; seat: number } {
  let roomId = generateRoomId();
  while (rooms.has(roomId)) {
    roomId = generateRoomId();
  }

  const room: Room = {
    id: roomId,
    players: [
      { name: playerName, seat: 0, isHuman: true, ws },
    ],
    hostWs: ws,
    status: 'waiting',
    gameMode,
    createdAt: Date.now(),
  };

  rooms.set(roomId, room);
  socketToRoom.set(ws, roomId);

  return { roomId, seat: 0 };
}

export function joinRoom(ws: WebSocket, roomId: string, playerName: string): { seat: number } | { error: string } {
  const room = rooms.get(roomId);
  if (!room) return { error: 'ルームが見つかりません' };
  if (room.status !== 'waiting') return { error: 'ゲームは既に開始されています' };

  const humanCount = room.players.filter(p => p.isHuman).length;
  if (humanCount >= 4) return { error: 'ルームが満員です' };

  const seat = humanCount;
  room.players.push({ name: playerName, seat, isHuman: true, ws });
  socketToRoom.set(ws, roomId);

  return { seat };
}

export function getRoom(roomId: string): Room | undefined {
  return rooms.get(roomId);
}

export function getRoomBySocket(ws: WebSocket): Room | undefined {
  const roomId = socketToRoom.get(ws);
  if (!roomId) return undefined;
  return rooms.get(roomId);
}

export function getSeatBySocket(ws: WebSocket): number {
  const room = getRoomBySocket(ws);
  if (!room) return -1;
  const player = room.players.find(p => p.ws === ws);
  return player?.seat ?? -1;
}

export function removePlayer(ws: WebSocket): void {
  const roomId = socketToRoom.get(ws);
  if (!roomId) return;

  const room = rooms.get(roomId);
  if (!room) return;

  socketToRoom.delete(ws);

  if (room.status === 'waiting') {
    room.players = room.players.filter(p => p.ws !== ws);
    if (room.players.length === 0) {
      rooms.delete(roomId);
    }
  } else {
    // ゲーム中: AIに置き換え
    const player = room.players.find(p => p.ws === ws);
    if (player) {
      player.ws = null;
      player.isHuman = false;
      player.name = `CPU(${player.name})`;
    }
  }
}

export function startGame(roomId: string): Room | undefined {
  const room = rooms.get(roomId);
  if (!room) return undefined;

  // 空席をAIで埋める
  while (room.players.length < 4) {
    room.players.push({
      name: `CPU ${room.players.length + 1}`,
      seat: room.players.length,
      isHuman: false,
      ws: null,
    });
  }

  // 座席をランダムにシャッフル
  const seats = [0, 1, 2, 3];
  for (let i = seats.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [seats[i], seats[j]] = [seats[j], seats[i]];
  }
  room.players.forEach((p, i) => { p.seat = seats[i]; });

  room.status = 'playing';
  return room;
}

export function getHumanSockets(room: Room): WebSocket[] {
  return room.players
    .filter(p => p.isHuman && p.ws !== null)
    .map(p => p.ws!);
}

export function broadcastToRoom(room: Room, messageFn: (seat: number) => string): void {
  for (const player of room.players) {
    if (player.ws && player.ws.readyState === 1) {
      player.ws.send(messageFn(player.seat));
    }
  }
}

export function sendToSeat(room: Room, seat: number, message: string): void {
  const player = room.players.find(p => p.seat === seat);
  if (player?.ws && player.ws.readyState === 1) {
    player.ws.send(message);
  }
}

// 30分以上放置されたルームを削除
export function cleanupRooms(): void {
  const now = Date.now();
  for (const [id, room] of rooms) {
    if (now - room.createdAt > 30 * 60 * 1000) {
      rooms.delete(id);
    }
  }
}

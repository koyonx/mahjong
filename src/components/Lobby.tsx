import { useState } from 'react';
import type { PlayerInfo } from '../protocol';
import { kazeToJa } from '../mahjong-bridge';

interface LobbyProps {
  connected: boolean;
  roomId: string | null;
  seat: number;
  players: PlayerInfo[];
  error: string | null;
  onCreateRoom: (name: string, gameMode: string) => void;
  onJoinRoom: (roomId: string, name: string) => void;
  onStartGame: () => void;
  onLeaveRoom: () => void;
  onSpectate?: (roomId: string, name: string) => void;
  isSpectator?: boolean;
}

export function Lobby({
  connected,
  roomId,
  seat,
  players,
  error,
  onCreateRoom,
  onJoinRoom,
  onStartGame,
  onLeaveRoom,
  onSpectate,
  isSpectator,
}: LobbyProps) {
  const [playerName, setPlayerName] = useState('');
  const [joinRoomId, setJoinRoomId] = useState('');
  const [mode, setMode] = useState<'menu' | 'create' | 'join' | 'spectate'>('menu');
  const [gameMode, setGameMode] = useState<'hanchan' | 'tonpuu'>('hanchan');

  if (!connected) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-green-300 text-xl animate-pulse">サーバーに接続中...</p>
      </div>
    );
  }

  // ルーム待機画面
  if (roomId) {
    const kazeNames = ['東', '南', '西', '北'];
    const isHost = seat === 0;

    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-6">
        <h1 className="text-4xl font-bold text-amber-300">ルーム待機中</h1>

        <div className="bg-green-800/50 rounded-xl p-6 w-full max-w-md">
          <div className="text-center mb-4">
            <p className="text-sm text-green-300">ルームID</p>
            <p className="text-3xl font-mono font-bold tracking-widest text-white">{roomId}</p>
            <p className="text-xs text-green-400 mt-1">このIDを他のプレイヤーに共有してください</p>
          </div>

          <div className="border-t border-green-700 pt-4">
            <p className="text-sm text-green-300 mb-2">プレイヤー</p>
            <div className="space-y-2">
              {[0, 1, 2, 3].map(i => {
                const player = players.find(p => p.seat === i);
                return (
                  <div key={i} className={`
                    flex items-center gap-3 px-3 py-2 rounded
                    ${player ? 'bg-green-700/50' : 'bg-green-900/30'}
                  `}>
                    <span className="text-amber-300 font-bold w-6">{kazeNames[i]}</span>
                    {player ? (
                      <>
                        <span className="flex-1">{player.name}</span>
                        {!player.isHuman && (
                          <span className="text-xs px-2 py-0.5 bg-gray-600 rounded">CPU</span>
                        )}
                        {player.seat === seat && (
                          <span className="text-xs px-2 py-0.5 bg-blue-600 rounded">あなた</span>
                        )}
                      </>
                    ) : (
                      <span className="flex-1 text-green-500 italic">空席（CPUが入ります）</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {isHost && (
          <button
            onClick={onStartGame}
            className="px-8 py-4 bg-yellow-500 hover:bg-yellow-400 text-green-950 text-xl font-bold rounded-xl transition shadow-lg"
          >
            ゲーム開始
          </button>
        )}

        {!isHost && (
          <p className="text-green-300">ホストがゲームを開始するのを待っています...</p>
        )}

        <button
          onClick={onLeaveRoom}
          className="text-green-400 hover:text-red-400 text-sm transition"
        >
          ルームを退出する
        </button>

        {error && <p className="text-red-400">{error}</p>}
      </div>
    );
  }

  // メニュー画面
  if (mode === 'menu') {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-8">
        <h1 className="text-5xl font-bold text-amber-300">麻雀</h1>
        <p className="text-green-300">オンライン対戦</p>

        <div className="flex flex-col gap-4 w-full max-w-xs">
          <button
            onClick={() => setMode('create')}
            className="px-8 py-4 bg-yellow-500 hover:bg-yellow-400 text-green-950 text-lg font-bold rounded-xl transition"
          >
            ルームを作成
          </button>
          <button
            onClick={() => setMode('join')}
            className="px-8 py-4 bg-green-700 hover:bg-green-600 text-white text-lg font-bold rounded-xl transition"
          >
            ルームに参加
          </button>
          {onSpectate && (
            <button
              onClick={() => setMode('spectate')}
              className="px-8 py-3 bg-gray-700 hover:bg-gray-600 text-white text-sm font-bold rounded-xl transition"
            >
              観戦する
            </button>
          )}
        </div>

        {error && <p className="text-red-400">{error}</p>}
      </div>
    );
  }

  // 作成/参加フォーム
  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-6">
      <h1 className="text-4xl font-bold text-amber-300">
        {mode === 'create' ? 'ルームを作成' : mode === 'spectate' ? '観戦する' : 'ルームに参加'}
      </h1>

      <div className="flex flex-col gap-4 w-full max-w-xs">
        <input
          type="text"
          placeholder="プレイヤー名"
          value={playerName}
          onChange={e => setPlayerName(e.target.value)}
          className="px-4 py-3 bg-green-800 border border-green-600 rounded-lg text-white placeholder-green-400 focus:outline-none focus:ring-2 focus:ring-yellow-400"
          maxLength={10}
        />

        {mode === 'create' && (
          <div className="flex gap-2">
            <button
              onClick={() => setGameMode('hanchan')}
              className={`flex-1 py-2 rounded-lg font-bold text-sm transition ${
                gameMode === 'hanchan'
                  ? 'bg-yellow-500 text-green-950'
                  : 'bg-green-800 text-green-300 border border-green-600'
              }`}
            >
              半荘戦
            </button>
            <button
              onClick={() => setGameMode('tonpuu')}
              className={`flex-1 py-2 rounded-lg font-bold text-sm transition ${
                gameMode === 'tonpuu'
                  ? 'bg-yellow-500 text-green-950'
                  : 'bg-green-800 text-green-300 border border-green-600'
              }`}
            >
              東風戦
            </button>
          </div>
        )}

        {(mode === 'join' || mode === 'spectate') && (
          <input
            type="text"
            placeholder="ルームID"
            value={joinRoomId}
            onChange={e => setJoinRoomId(e.target.value.toUpperCase())}
            className="px-4 py-3 bg-green-800 border border-green-600 rounded-lg text-white placeholder-green-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 font-mono tracking-widest text-center text-xl"
            maxLength={6}
          />
        )}

        <button
          onClick={() => {
            if (!playerName.trim()) return;
            if (mode === 'create') {
              onCreateRoom(playerName.trim(), gameMode);
            } else if (mode === 'spectate') {
              if (!joinRoomId.trim()) return;
              onSpectate?.(joinRoomId.trim(), playerName.trim());
            } else {
              if (!joinRoomId.trim()) return;
              onJoinRoom(joinRoomId.trim(), playerName.trim());
            }
          }}
          disabled={!playerName.trim() || ((mode === 'join' || mode === 'spectate') && !joinRoomId.trim())}
          className="px-8 py-4 bg-yellow-500 hover:bg-yellow-400 disabled:bg-gray-600 disabled:cursor-not-allowed text-green-950 text-lg font-bold rounded-xl transition"
        >
          {mode === 'create' ? '作成' : mode === 'spectate' ? '観戦開始' : '参加'}
        </button>

        <button
          onClick={() => setMode('menu')}
          className="text-green-400 hover:text-green-300 text-sm"
        >
          戻る
        </button>
      </div>

      {error && <p className="text-red-400">{error}</p>}
    </div>
  );
}

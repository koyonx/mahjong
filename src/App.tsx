import { useState, useEffect } from 'react';
import { initMahjong } from './mahjong-bridge';
import { GameBoard } from './components/GameBoard';
import { Lobby } from './components/Lobby';
import { MultiplayerGameBoard } from './components/MultiplayerGameBoard';
import { useMultiplayer } from './hooks/useMultiplayer';

type Mode = 'menu' | 'single' | 'multi';

function SinglePlayerApp() {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    initMahjong()
      .then(() => setReady(true))
      .catch((e) => setError(`麻雀ロジックの読み込みに失敗しました: ${e.message}`));
  }, []);

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-red-400 text-center">
          <p className="text-xl mb-2">エラー</p>
          <p className="text-sm">{error}</p>
        </div>
      </div>
    );
  }

  if (!ready) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-green-300 text-xl animate-pulse">読み込み中...</p>
      </div>
    );
  }

  return <GameBoard />;
}

function MultiplayerApp() {
  const mp = useMultiplayer();

  if (!mp.gameState) {
    return (
      <Lobby
        connected={mp.connected}
        roomId={mp.roomId}
        seat={mp.seat}
        players={mp.players}
        error={mp.error}
        onCreateRoom={mp.createRoom}
        onJoinRoom={mp.joinRoom}
        onStartGame={mp.startGame}
        onLeaveRoom={mp.leaveRoom}
      />
    );
  }

  return (
    <MultiplayerGameBoard
      state={mp.gameState}
      seat={mp.seat}
      turnInfo={mp.turnInfo}
      agariResult={mp.agariResult}
      messages={mp.messages}
      gameEnd={mp.gameEnd}
      onDiscard={mp.discard}
      onTsumo={mp.tsumo}
      onRiichi={mp.riichi}
      onAgariClose={mp.clearAgari}
    />
  );
}

function App() {
  const [mode, setMode] = useState<Mode>('menu');

  if (mode === 'single') return <SinglePlayerApp />;
  if (mode === 'multi') return <MultiplayerApp />;

  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-8">
      <h1 className="text-5xl font-bold text-amber-300">麻雀</h1>
      <p className="text-green-300">日本式リーチ麻雀</p>

      <div className="flex flex-col gap-4 w-full max-w-xs">
        <button
          onClick={() => setMode('single')}
          className="px-8 py-4 bg-yellow-500 hover:bg-yellow-400 text-green-950 text-lg font-bold rounded-xl transition shadow-lg"
        >
          一人プレイ（CPU対戦）
        </button>
        <button
          onClick={() => setMode('multi')}
          className="px-8 py-4 bg-green-700 hover:bg-green-600 text-white text-lg font-bold rounded-xl transition shadow-lg"
        >
          オンライン対戦
        </button>
      </div>
    </div>
  );
}

export default App;

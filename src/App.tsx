import { useState, useEffect } from 'react';
import { initMahjong } from './mahjong-bridge';
import { GameBoard } from './components/GameBoard';

function App() {
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

export default App;

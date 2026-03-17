import { useState, useEffect } from 'react';
import { initMahjong, setAiDifficulty, type AiDifficulty } from './mahjong-bridge';
import { GameBoard } from './components/GameBoard';
import { Lobby } from './components/Lobby';
import { MultiplayerGameBoard } from './components/MultiplayerGameBoard';
import { HelpPage } from './components/HelpPage';
import { MatchHistory } from './components/MatchHistory';
import { RuleSettings } from './components/RuleSettings';
import { ReplayList } from './components/ReplayList';
import { ReplayViewer } from './components/ReplayViewer';
import { getReplay, type ReplayData } from './hooks/useReplay';
import { useMultiplayer } from './hooks/useMultiplayer';

type Mode = 'menu' | 'single' | 'multi' | 'help' | 'history' | 'rules' | 'replay_list' | 'replay_view';

function SinglePlayerApp({ onBack }: { onBack: () => void }) {
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

  return <GameBoard onBack={onBack} />;
}

function MultiplayerApp({ onBack }: { onBack: () => void }) {
  const mp = useMultiplayer();

  const handleLeave = () => {
    mp.leaveRoom();
    onBack();
  };

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
        onLeaveRoom={mp.roomId ? mp.leaveRoom : onBack}
      />
    );
  }

  return (
    <MultiplayerGameBoard
      state={mp.gameState}
      seat={mp.seat}
      turnInfo={mp.turnInfo}
      callInfo={mp.callInfo}
      agariResult={mp.agariResult}
      messages={mp.messages}
      gameEnd={mp.gameEnd}
      onDiscard={mp.discard}
      onPon={mp.pon}
      onChi={mp.chi}
      onSkipCall={mp.skipCall}
      onTsumo={mp.tsumo}
      onRiichi={mp.riichi}
      onAgariClose={mp.clearAgari}
      onLeaveRoom={handleLeave}
    />
  );
}

function App() {
  const [mode, setMode] = useState<Mode>('menu');
  const [difficulty, setDifficulty] = useState<AiDifficulty>('normal');
  const [selectedReplay, setSelectedReplay] = useState<ReplayData | null>(null);

  const startSingle = (diff: AiDifficulty) => {
    setDifficulty(diff);
    setAiDifficulty(diff);
    setMode('single');
  };

  if (mode === 'single') return <SinglePlayerApp onBack={() => setMode('menu')} />;
  if (mode === 'multi') return <MultiplayerApp onBack={() => setMode('menu')} />;
  if (mode === 'help') return <HelpPage onBack={() => setMode('menu')} />;
  if (mode === 'history') return <MatchHistory onBack={() => setMode('menu')} />;
  if (mode === 'rules') return <RuleSettings onBack={() => setMode('menu')} />;
  if (mode === 'replay_list') return <ReplayList onSelect={(id) => { setSelectedReplay(getReplay(id)); setMode('replay_view'); }} onBack={() => setMode('menu')} />;
  if (mode === 'replay_view' && selectedReplay) return <ReplayViewer replay={selectedReplay} onBack={() => setMode('replay_list')} />;

  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-8">
      <h1 className="text-5xl font-bold text-amber-300">麻雀</h1>
      <p className="text-green-300">日本式リーチ麻雀</p>

      <div className="flex flex-col gap-4 w-full max-w-xs">
        {/* 難易度選択付きCPU対戦 */}
        <div style={{
          background: 'rgba(255,255,255,0.05)', borderRadius: 12, padding: 16,
          display: 'flex', flexDirection: 'column', gap: 8,
        }}>
          <p style={{ textAlign: 'center', color: '#e8c44a', fontWeight: 700, fontSize: 15 }}>一人プレイ（CPU対戦）</p>
          <div style={{ display: 'flex', gap: 6 }}>
            {([
              { key: 'easy' as AiDifficulty, label: '初級', color: '#4ade80', desc: 'ランダム寄り' },
              { key: 'normal' as AiDifficulty, label: '中級', color: '#e8c44a', desc: '牌効率重視' },
              { key: 'hard' as AiDifficulty, label: '上級', color: '#f87171', desc: '攻守バランス' },
            ]).map(d => (
              <button key={d.key} onClick={() => startSingle(d.key)} style={{
                flex: 1, padding: '10px 4px', border: 'none', borderRadius: 8, cursor: 'pointer',
                background: `${d.color}22`, color: d.color, fontWeight: 700, fontSize: 14,
                transition: 'background 0.2s',
              }}
              onMouseEnter={e => (e.currentTarget.style.background = `${d.color}44`)}
              onMouseLeave={e => (e.currentTarget.style.background = `${d.color}22`)}
              >
                <div>{d.label}</div>
                <div style={{ fontSize: 10, fontWeight: 400, opacity: 0.7, marginTop: 2 }}>{d.desc}</div>
              </button>
            ))}
          </div>
        </div>
        <button
          onClick={() => setMode('multi')}
          className="px-8 py-4 bg-green-700 hover:bg-green-600 text-white text-lg font-bold rounded-xl transition shadow-lg"
        >
          オンライン対戦
        </button>
        <button
          onClick={() => setMode('help')}
          className="px-8 py-4 bg-gray-700 hover:bg-gray-600 text-white text-lg font-bold rounded-xl transition shadow-lg"
        >
          ヘルプ（ルール・役一覧）
        </button>
        <button
          onClick={() => setMode('history')}
          className="px-8 py-4 bg-gray-700 hover:bg-gray-600 text-white text-lg font-bold rounded-xl transition shadow-lg"
        >
          対局履歴
        </button>
        <button
          onClick={() => setMode('rules')}
          className="px-8 py-3 bg-gray-800 hover:bg-gray-700 text-gray-300 text-sm font-bold rounded-xl transition"
        >
          ルール設定
        </button>
        <button
          onClick={() => setMode('replay_list')}
          className="px-8 py-3 bg-gray-800 hover:bg-gray-700 text-gray-300 text-sm font-bold rounded-xl transition"
        >
          リプレイ
        </button>
      </div>
    </div>
  );
}

export default App;

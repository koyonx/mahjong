import { useState, useEffect } from 'react';
import { initMahjong, setAiDifficulty, setAiLevel, type AiDifficulty } from './mahjong-bridge';
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
        onSpectate={mp.spectate}
        isSpectator={mp.isSpectator}
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
  const [aiLevel, setAiLevelState] = useState(5);
  const [selectedReplay, setSelectedReplay] = useState<ReplayData | null>(null);

  const startSingle = () => {
    setAiLevel(aiLevel);
    const diff: AiDifficulty = aiLevel <= 3 ? 'easy' : aiLevel <= 6 ? 'normal' : 'hard';
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
        {/* CPU対戦（レベル1-10） */}
        <div style={{
          background: 'rgba(255,255,255,0.05)', borderRadius: 12, padding: 16,
          display: 'flex', flexDirection: 'column', gap: 10,
        }}>
          <p style={{ textAlign: 'center', color: '#e8c44a', fontWeight: 700, fontSize: 15 }}>一人プレイ（CPU対戦）</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ color: '#4ade80', fontSize: 11, whiteSpace: 'nowrap' }}>弱</span>
            <input type="range" min="1" max="10" value={aiLevel}
              onChange={e => setAiLevelState(Number(e.target.value))}
              style={{ flex: 1, accentColor: aiLevel <= 3 ? '#4ade80' : aiLevel <= 6 ? '#e8c44a' : '#f87171' }}
            />
            <span style={{ color: '#f87171', fontSize: 11, whiteSpace: 'nowrap' }}>強</span>
          </div>
          <div style={{ textAlign: 'center' }}>
            <span style={{
              fontSize: 24, fontWeight: 700,
              color: aiLevel <= 3 ? '#4ade80' : aiLevel <= 6 ? '#e8c44a' : '#f87171',
            }}>Lv.{aiLevel}</span>
            <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>
              {aiLevel <= 2 ? 'ほぼランダム' :
               aiLevel <= 4 ? '基本牌効率' :
               aiLevel <= 6 ? '受入数+防御' :
               aiLevel <= 8 ? 'スジ読み+ダマテン' :
               '最強: 壁読み+完全防御'}
            </div>
          </div>
          <button onClick={startSingle} style={{
            padding: '12px', border: 'none', borderRadius: 8, cursor: 'pointer',
            background: aiLevel <= 3 ? '#4ade80' : aiLevel <= 6 ? '#e8c44a' : '#f87171',
            color: '#0a1a0a', fontWeight: 700, fontSize: 16,
          }}>ゲーム開始</button>
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

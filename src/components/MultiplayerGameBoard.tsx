import { useState } from 'react';
import type { Tile, GameState, AgariResult } from '../mahjong-bridge';
import { TileView } from './TileView';
import { PlayerHand } from './PlayerHand';
import { Kawa } from './Kawa';
import { CenterPanel } from './CenterPanel';
import { AgariDialog } from './AgariDialog';

interface MultiplayerGameBoardProps {
  state: GameState;
  seat: number;
  turnInfo: { canTsumo: boolean; canRiichi: boolean; tenpaiTiles: Tile[] } | null;
  agariResult: { result: AgariResult; winnerSeat: number; winnerName: string } | null;
  messages: string[];
  gameEnd: { name: string; score: number }[] | null;
  onDiscard: (tile: Tile) => void;
  onTsumo: () => void;
  onRiichi: (tile: Tile) => void;
  onAgariClose: () => void;
  onLeaveRoom: () => void;
}

export function MultiplayerGameBoard({
  state,
  seat,
  turnInfo,
  agariResult,
  messages,
  gameEnd,
  onDiscard,
  onTsumo,
  onAgariClose,
  onLeaveRoom,
}: MultiplayerGameBoardProps) {
  const [selectedTile, setSelectedTile] = useState<number | null>(null);
  const [showMenu, setShowMenu] = useState(false);

  if (gameEnd) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-6" style={{ background: '#0d1a0f' }}>
        <h1 className="text-4xl font-bold text-amber-300">ゲーム終了</h1>
        <div className="bg-green-800/50 rounded-xl p-6 w-full max-w-md">
          {gameEnd.map((p, i) => (
            <div key={i} className="flex justify-between px-4 py-3 border-b border-green-700 last:border-0">
              <span className="font-bold">{i === 0 ? '🏆 ' : ''}{p.name}</span>
              <span className="text-amber-300 font-mono">{p.score.toLocaleString()}点</span>
            </div>
          ))}
        </div>
        <button onClick={onLeaveRoom} className="px-6 py-3 bg-green-700 hover:bg-green-600 text-white font-bold rounded-lg transition">
          ロビーに戻る
        </button>
      </div>
    );
  }

  const isMyTurn = state.current_turn === seat && state.phase === 'waiting_discard';
  const rel = (offset: number) => (seat + offset) % 4;
  const topSeat = rel(2);
  const rightSeat = rel(1);
  const leftSeat = rel(3);
  const lastMessage = messages[messages.length - 1] ?? '';

  return (
    <div style={{
      width: '100vw', height: '100vh', overflow: 'hidden',
      background: 'linear-gradient(180deg, #3a2a1a 0%, #1a2a1a 30%, #0a1a0e 100%)',
      display: 'flex', flexDirection: 'column', position: 'relative',
    }}>
      {/* メニュー */}
      <button onClick={() => setShowMenu(!showMenu)} style={{
        position: 'absolute', top: 8, right: 8, zIndex: 30,
        width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: 'rgba(0,0,0,0.4)', border: '1px solid #555', borderRadius: 4,
        color: '#aaa', fontSize: 16, cursor: 'pointer',
      }}>☰</button>
      {showMenu && (
        <div style={{
          position: 'absolute', top: 44, right: 8, zIndex: 30,
          background: '#1a1a28', border: '1px solid #444', borderRadius: 6, padding: 4,
        }}>
          <button onClick={() => { onLeaveRoom(); setShowMenu(false); }} style={{
            display: 'block', width: '100%', padding: '8px 16px', textAlign: 'left',
            color: '#e05050', background: 'none', border: 'none', cursor: 'pointer', fontSize: 13,
          }}>退出する</button>
        </div>
      )}

      {lastMessage && (
        <div style={{ textAlign: 'center', padding: '4px 0', color: '#8a8', fontSize: 12, flexShrink: 0 }}>
          {lastMessage}
        </div>
      )}

      {/* 卓面 */}
      <div style={{ flex: 1, position: 'relative', minHeight: 0 }}>
        {/* 対面（上）: 裏面の牌 */}
        <div style={{
          position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
        }}>
          <PlayerHand player={state.players[topSeat]} isCurrentTurn={state.current_turn === topSeat} isHuman={false} compact />
          <Kawa tiles={state.players[topSeat].kawa} compact />
        </div>

        {/* 左プレイヤー */}
        <div style={{
          position: 'absolute', left: 8, top: '50%', transform: 'translateY(-50%)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
        }}>
          <PlayerHand player={state.players[leftSeat]} isCurrentTurn={state.current_turn === leftSeat} isHuman={false} compact />
          <Kawa tiles={state.players[leftSeat].kawa} compact />
        </div>

        {/* 右プレイヤー */}
        <div style={{
          position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
        }}>
          <PlayerHand player={state.players[rightSeat]} isCurrentTurn={state.current_turn === rightSeat} isHuman={false} compact />
          <Kawa tiles={state.players[rightSeat].kawa} compact />
        </div>

        {/* 中央パネル */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
        }}>
          <CenterPanel state={state} mySeat={seat} />
        </div>
      </div>

      {/* 自分の領域（下） */}
      <div style={{
        flexShrink: 0, padding: '8px 16px 12px',
        background: 'linear-gradient(0deg, rgba(0,0,0,0.4), transparent)',
      }}>
        <Kawa tiles={state.players[seat].kawa} />
        <div style={{ marginTop: 8 }}>
          <PlayerHand
            player={state.players[seat]}
            isCurrentTurn={isMyTurn}
            isHuman={true}
            onDiscard={(tile) => { onDiscard(tile); setSelectedTile(null); }}
            selectedTile={selectedTile}
            onSelectTile={setSelectedTile}
          />
        </div>

        {turnInfo && turnInfo.tenpaiTiles.length > 0 && (
          <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
            <span style={{ fontSize: 11, color: '#8a8' }}>待ち:</span>
            {turnInfo.tenpaiTiles.map((t, i) => (
              <TileView key={i} tile={t} small />
            ))}
          </div>
        )}

        {isMyTurn && turnInfo?.canTsumo && (
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
            <button onClick={onTsumo} style={{
              padding: '8px 24px', background: '#c41e3a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 15, cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(196,30,58,0.4)',
            }}>ツモ</button>
          </div>
        )}
      </div>

      {agariResult && (
        <AgariDialog result={agariResult.result} winnerName={agariResult.winnerName} onClose={onAgariClose} />
      )}
    </div>
  );
}

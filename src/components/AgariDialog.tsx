import type { AgariResult } from '../mahjong-bridge';
import { yakuName } from '../mahjong-bridge';
import { TileView } from './TileView';

interface AgariDialogProps {
  result: AgariResult;
  winnerName: string;
  onClose: () => void;
}

export function AgariDialog({ result, winnerName, onClose }: AgariDialogProps) {
  const paymentText = () => {
    const p = result.payment;
    switch (p.kind) {
      case 'ron':
        return `ロン ${p.ron?.toLocaleString()}点`;
      case 'tsumo_oya':
        return `ツモ ${p.ko_pay?.toLocaleString()}点オール`;
      case 'tsumo_ko':
        return `ツモ ${p.oya_pay?.toLocaleString()}/${p.ko_pay?.toLocaleString()}点`;
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-green-950 border-2 border-yellow-400 rounded-xl p-8 max-w-md w-full mx-4 shadow-2xl max-h-[90vh] overflow-y-auto">
        <h2 className="text-3xl font-bold text-yellow-400 text-center mb-4">
          和了
        </h2>
        <p className="text-center text-lg mb-4">{winnerName}</p>

        {/* 和了手牌 */}
        {result.winner_hand && result.winner_hand.length > 0 && (
          <div className="mb-4">
            <div className="flex gap-1 justify-center flex-wrap items-end">
              {result.winner_hand.map((t, i) => (
                <TileView key={i} tile={t} small />
              ))}
              {/* ロン牌は区切って表示 */}
              {result.agari_tile && (
                <>
                  <div style={{ width: 8 }} />
                  <div style={{ position: 'relative' }}>
                    <TileView tile={result.agari_tile} small />
                    <div style={{
                      position: 'absolute', bottom: -14, left: '50%', transform: 'translateX(-50%)',
                      fontSize: 9, color: '#e8c44a', whiteSpace: 'nowrap',
                    }}>
                      {result.is_tsumo ? 'ツモ' : 'ロン'}
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        )}

        {/* 役一覧 */}
        <div className="space-y-2 mb-4">
          {result.yakus.map((yaku, i) => (
            <div key={i} className="flex justify-between px-4 py-1 bg-green-900/50 rounded">
              <span>{yakuName(yaku.id)}</span>
              <span className="text-amber-300">{yaku.han}翻</span>
            </div>
          ))}
          {/* ドラ */}
          {(result.dora_count ?? 0) > 0 && (
            <div className="flex justify-between px-4 py-1 bg-green-900/50 rounded">
              <span>ドラ</span>
              <span className="text-amber-300">{result.dora_count}翻</span>
            </div>
          )}
          {/* 赤ドラ */}
          {(result.aka_count ?? 0) > 0 && (
            <div className="flex justify-between px-4 py-1 bg-green-900/50 rounded">
              <span>赤ドラ</span>
              <span className="text-amber-300">{result.aka_count}翻</span>
            </div>
          )}
          {/* 裏ドラ */}
          {(result.uradora_count ?? 0) > 0 && (
            <div className="flex justify-between px-4 py-1 bg-green-900/50 rounded">
              <span>裏ドラ</span>
              <span className="text-amber-300">{result.uradora_count}翻</span>
            </div>
          )}
        </div>

        {/* ドラ牌表示 */}
        {result.dora && result.dora.length > 0 && (
          <div className="flex items-center justify-center gap-4 mb-4">
            <div className="text-center">
              <div className="text-xs text-green-400 mb-1">ドラ</div>
              <div className="flex gap-1 justify-center">
                {result.dora.map((t, i) => <TileView key={i} tile={t} small />)}
              </div>
            </div>
            {result.uradora && result.uradora.length > 0 && (
              <div className="text-center">
                <div className="text-xs text-green-400 mb-1">裏ドラ</div>
                <div className="flex gap-1 justify-center">
                  {result.uradora.map((t, i) => <TileView key={i} tile={t} small />)}
                </div>
              </div>
            )}
          </div>
        )}

        <div className="text-center space-y-1 mb-6">
          <div className="text-sm text-green-300">
            {result.han}翻 {result.fu}符
          </div>
          <div className="text-2xl font-bold text-yellow-400">
            {result.total.toLocaleString()}点
          </div>
          <div className="text-sm text-green-300">
            {paymentText()}
          </div>
        </div>

        <button
          onClick={onClose}
          className="w-full py-3 bg-yellow-500 hover:bg-yellow-400 text-green-950 font-bold rounded-lg transition"
        >
          次の局へ
        </button>
      </div>
    </div>
  );
}

import { useState } from 'react';

type Tab = 'basics' | 'yaku' | 'scoring' | 'calls' | 'controls';

interface HelpPageProps {
  onBack: () => void;
}

const tabLabels: Record<Tab, string> = {
  basics: '基本ルール',
  yaku: '役一覧',
  scoring: '点数計算',
  calls: '鳴き',
  controls: '操作方法',
};

export function HelpPage({ onBack }: HelpPageProps) {
  const [tab, setTab] = useState<Tab>('basics');

  return (
    <div style={{
      minHeight: '100vh', background: '#0d1a0f', color: '#ddd',
      padding: '20px', overflowY: 'auto',
    }}>
      <div style={{ maxWidth: 700, margin: '0 auto' }}>
        {/* ヘッダー */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: '#e8c44a' }}>ヘルプ</h1>
          <button onClick={onBack} style={{
            padding: '6px 16px', background: '#333', border: 'none', borderRadius: 6,
            color: '#aaa', cursor: 'pointer', fontSize: 14,
          }}>戻る</button>
        </div>

        {/* タブ */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 20, flexWrap: 'wrap' }}>
          {(Object.keys(tabLabels) as Tab[]).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: '6px 14px', borderRadius: 6, border: 'none', cursor: 'pointer',
              fontSize: 13, fontWeight: 600,
              background: tab === t ? '#e8c44a' : '#2a3a2a',
              color: tab === t ? '#1a1a0a' : '#8a8',
            }}>{tabLabels[t]}</button>
          ))}
        </div>

        {/* コンテンツ */}
        <div style={{ lineHeight: 1.8, fontSize: 14 }}>
          {tab === 'basics' && <BasicsContent />}
          {tab === 'yaku' && <YakuContent />}
          {tab === 'scoring' && <ScoringContent />}
          {tab === 'calls' && <CallsContent />}
          {tab === 'controls' && <ControlsContent />}
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <h2 style={{ fontSize: 18, fontWeight: 700, color: '#e8c44a', marginBottom: 8, borderBottom: '1px solid #333', paddingBottom: 4 }}>{title}</h2>
      {children}
    </div>
  );
}

function BasicsContent() {
  return (
    <>
      <Section title="麻雀とは">
        <p>4人で行う牌を使ったゲームです。136枚の牌を使い、手牌を揃えて「和了（あがり）」を目指します。</p>
      </Section>
      <Section title="ゲームの流れ">
        <ol style={{ paddingLeft: 20 }}>
          <li>各プレイヤーに13枚の牌が配られます（配牌）</li>
          <li>自分の番が来たら牌山から1枚ツモ（引く）</li>
          <li>手牌14枚から1枚選んで捨てる</li>
          <li>他のプレイヤーの捨て牌を「鳴いて」利用できる場合がある</li>
          <li>手牌が特定の形（和了形）になったら上がれる</li>
        </ol>
      </Section>
      <Section title="和了形">
        <p><strong>基本形:</strong> 4面子（メンツ）+ 1雀頭（ジャントウ）</p>
        <ul style={{ paddingLeft: 20 }}>
          <li><strong>順子（シュンツ）:</strong> 同じ種類の連番3枚（例: 1萬2萬3萬）</li>
          <li><strong>刻子（コーツ）:</strong> 同じ牌3枚（例: 5筒5筒5筒）</li>
          <li><strong>雀頭:</strong> 同じ牌2枚（例: 東東）</li>
        </ul>
        <p style={{ marginTop: 8 }}><strong>特殊形:</strong></p>
        <ul style={{ paddingLeft: 20 }}>
          <li><strong>七対子:</strong> 7つの対子（ペア）</li>
          <li><strong>国士無双:</strong> 13種の么九牌 + 1枚</li>
        </ul>
      </Section>
      <Section title="牌の種類">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <tbody>
            {[
              ['萬子（マンズ）', '一萬〜九萬 × 各4枚'],
              ['筒子（ピンズ）', '一筒〜九筒 × 各4枚'],
              ['索子（ソーズ）', '一索〜九索 × 各4枚'],
              ['風牌', '東・南・西・北 × 各4枚'],
              ['三元牌', '白・發・中 × 各4枚'],
              ['赤ドラ', '5萬・5筒・5索 各1枚（+1翻）'],
            ].map(([name, desc], i) => (
              <tr key={i} style={{ borderBottom: '1px solid #2a3a2a' }}>
                <td style={{ padding: '4px 8px', color: '#e8c44a', fontWeight: 600 }}>{name}</td>
                <td style={{ padding: '4px 8px', color: '#aaa' }}>{desc}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Section>
      <Section title="和了方法">
        <ul style={{ paddingLeft: 20 }}>
          <li><strong>ツモ:</strong> 自分で牌山から引いた牌で和了</li>
          <li><strong>ロン:</strong> 他のプレイヤーが捨てた牌で和了</li>
        </ul>
      </Section>
      <Section title="リーチ">
        <p>門前（鳴きなし）でテンパイ（あと1枚で和了）の時、1000点を供託して宣言。</p>
        <ul style={{ paddingLeft: 20 }}>
          <li>リーチ後は手牌を変更できない（自動ツモ切り）</li>
          <li>和了時に裏ドラが追加される</li>
          <li>一発（リーチ後1巡以内の和了）で+1翻</li>
        </ul>
      </Section>
      <Section title="流局">
        <ul style={{ paddingLeft: 20 }}>
          <li>牌山がなくなると流局（ノーゲーム）</li>
          <li>テンパイの人はノーテンの人から3000点を受け取る</li>
          <li>九種九牌: 配牌で9種以上の么九牌がある場合、流局を選択可能</li>
        </ul>
      </Section>
    </>
  );
}

function YakuContent() {
  const yakuList = [
    { name: 'リーチ', han: '1翻', desc: '門前テンパイで宣言。1000点供託', cat: '状況' },
    { name: '一発', han: '1翻', desc: 'リーチ後1巡以内に和了', cat: '状況' },
    { name: '門前清自摸和', han: '1翻', desc: '門前でツモ和了', cat: '状況' },
    { name: 'ダブルリーチ', han: '2翻', desc: '最初の打牌でリーチ（鳴きなし）', cat: '状況' },
    { name: '海底摸月', han: '1翻', desc: '最後のツモで和了', cat: '状況' },
    { name: '河底撈魚', han: '1翻', desc: '最後の捨て牌で和了', cat: '状況' },
    { name: '断么九', han: '1翻', desc: '么九牌（1,9,字牌）を含まない', cat: '1翻' },
    { name: '平和', han: '1翻', desc: '全て順子・雀頭が役牌でない（門前限定）', cat: '1翻' },
    { name: '一盃口', han: '1翻', desc: '同じ順子が2組（門前限定）', cat: '1翻' },
    { name: '役牌', han: '1翻', desc: '三元牌/場風/自風の刻子', cat: '1翻' },
    { name: '混全帯么九', han: '2翻', desc: '全ての面子と雀頭に么九牌を含む（字牌あり）', cat: '2翻' },
    { name: '一気通貫', han: '2翻', desc: '同じ種類で123・456・789', cat: '2翻' },
    { name: '三色同順', han: '2翻', desc: '3種の数牌で同じ数字の順子', cat: '2翻' },
    { name: '三色同刻', han: '2翻', desc: '3種の数牌で同じ数字の刻子', cat: '2翻' },
    { name: '対々和', han: '2翻', desc: '全て刻子', cat: '2翻' },
    { name: '三暗刻', han: '2翻', desc: '暗刻（手牌内の刻子）が3つ', cat: '2翻' },
    { name: '混老頭', han: '2翻', desc: '全て么九牌', cat: '2翻' },
    { name: '小三元', han: '2翻', desc: '三元牌の刻子2つ + 三元牌の雀頭', cat: '2翻' },
    { name: '七対子', han: '2翻', desc: '7つの対子（門前限定）', cat: '2翻' },
    { name: '混一色', han: '3翻', desc: '1種の数牌 + 字牌のみ', cat: '3翻' },
    { name: '純全帯么九', han: '3翻', desc: '全ての面子と雀頭に老頭牌（1,9のみ）', cat: '3翻' },
    { name: '二盃口', han: '3翻', desc: '同じ順子が2組×2（門前限定）', cat: '3翻' },
    { name: '清一色', han: '6翻', desc: '1種の数牌のみ', cat: '6翻' },
    { name: '国士無双', han: '役満', desc: '13種の么九牌 + 1枚', cat: '役満' },
    { name: '四暗刻', han: '役満', desc: '暗刻が4つ（ツモ or 単騎ロン）', cat: '役満' },
    { name: '大三元', han: '役満', desc: '白・發・中の刻子3つ', cat: '役満' },
    { name: '小四喜', han: '役満', desc: '風牌の刻子3つ + 風牌の雀頭', cat: '役満' },
    { name: '大四喜', han: '役満', desc: '風牌の刻子4つ', cat: '役満' },
    { name: '字一色', han: '役満', desc: '全て字牌', cat: '役満' },
    { name: '緑一色', han: '役満', desc: '2s,3s,4s,6s,8s,發のみ', cat: '役満' },
    { name: '清老頭', han: '役満', desc: '全て1と9の数牌のみ', cat: '役満' },
    { name: '九蓮宝燈', han: '役満', desc: '同一スートで1112345678999+1枚', cat: '役満' },
    { name: '天和', han: '役満', desc: '親の配牌で即和了', cat: '役満' },
    { name: '地和', han: '役満', desc: '子の最初のツモで和了（鳴きなし）', cat: '役満' },
  ];

  const categories = ['状況', '1翻', '2翻', '3翻', '6翻', '役満'];

  return (
    <>
      {categories.map(cat => (
        <Section key={cat} title={cat === '状況' ? '状況役' : cat}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <tbody>
              {yakuList.filter(y => y.cat === cat).map((y, i) => (
                <tr key={i} style={{ borderBottom: '1px solid #2a3a2a' }}>
                  <td style={{ padding: '4px 8px', fontWeight: 600, color: cat === '役満' ? '#ff6b6b' : '#eee', whiteSpace: 'nowrap', width: 120 }}>{y.name}</td>
                  <td style={{ padding: '4px 8px', color: '#e8c44a', whiteSpace: 'nowrap', width: 50 }}>{y.han}</td>
                  <td style={{ padding: '4px 8px', color: '#999', fontSize: 13 }}>{y.desc}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>
      ))}
      <Section title="食い下がり">
        <p style={{ color: '#999' }}>以下の役は鳴くと1翻下がります:</p>
        <p>混全帯么九、一気通貫、三色同順、混一色、純全帯么九、清一色</p>
      </Section>
    </>
  );
}

function ScoringContent() {
  return (
    <>
      <Section title="点数の仕組み">
        <p>点数 = <strong>翻数</strong>（役の合計）× <strong>符</strong>（手の形）で決まります。</p>
      </Section>
      <Section title="翻数と点数の対応（子の場合）">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #444' }}>
              <th style={{ padding: '4px 8px', textAlign: 'left', color: '#e8c44a' }}>翻数</th>
              <th style={{ padding: '4px 8px', textAlign: 'left', color: '#e8c44a' }}>名称</th>
              <th style={{ padding: '4px 8px', textAlign: 'right', color: '#e8c44a' }}>ロン</th>
            </tr>
          </thead>
          <tbody>
            {[
              ['1翻30符', '', '1,000'],
              ['2翻30符', '', '2,000'],
              ['3翻30符', '', '3,900'],
              ['4翻30符', '', '7,700'],
              ['5翻', '満貫', '8,000'],
              ['6-7翻', '跳満', '12,000'],
              ['8-10翻', '倍満', '16,000'],
              ['11-12翻', '三倍満', '24,000'],
              ['13翻+', '役満', '32,000'],
            ].map(([han, name, ron], i) => (
              <tr key={i} style={{ borderBottom: '1px solid #2a3a2a' }}>
                <td style={{ padding: '4px 8px' }}>{han}</td>
                <td style={{ padding: '4px 8px', color: '#e8c44a' }}>{name}</td>
                <td style={{ padding: '4px 8px', textAlign: 'right', fontFamily: 'monospace' }}>{ron}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p style={{ marginTop: 8, color: '#888', fontSize: 12 }}>※ 親は上記の1.5倍</p>
      </Section>
      <Section title="ドラ">
        <ul style={{ paddingLeft: 20 }}>
          <li><strong>表ドラ:</strong> ドラ表示牌の次の牌（各+1翻）</li>
          <li><strong>裏ドラ:</strong> リーチ和了時のみ（各+1翻）</li>
          <li><strong>赤ドラ:</strong> 赤い5萬/5筒/5索（各+1翻）</li>
          <li><strong>カンドラ:</strong> カンごとにドラ表示牌が増える</li>
        </ul>
      </Section>
    </>
  );
}

function CallsContent() {
  return (
    <>
      <Section title="鳴き（副露）">
        <p>他のプレイヤーの捨て牌を利用して面子を作ること。鳴くと門前ではなくなります。</p>
      </Section>
      <Section title="チー">
        <p>上家（左のプレイヤー）の捨て牌で順子を作る。</p>
        <p style={{ color: '#888' }}>例: 手牌に3萬4萬 → 上家が2萬を捨てる → チーで2萬3萬4萬</p>
      </Section>
      <Section title="ポン">
        <p>誰の捨て牌でも刻子を作れる。</p>
        <p style={{ color: '#888' }}>例: 手牌に東東 → 誰かが東を捨てる → ポンで東東東</p>
      </Section>
      <Section title="カン">
        <ul style={{ paddingLeft: 20 }}>
          <li><strong>明槓:</strong> 手牌に3枚 + 他家の捨て牌で4枚</li>
          <li><strong>暗槓:</strong> 手牌に4枚揃った時（自分のターン中）</li>
          <li><strong>加槓:</strong> ポン済みの牌の4枚目をツモった時</li>
        </ul>
        <p style={{ marginTop: 8, color: '#888' }}>カン後はドラ表示牌が1枚増え、嶺上牌をツモります。</p>
      </Section>
      <Section title="優先順位">
        <p>ロン {'>'} ポン/カン {'>'} チー</p>
      </Section>
    </>
  );
}

function ControlsContent() {
  return (
    <>
      <Section title="牌の操作">
        <ul style={{ paddingLeft: 20 }}>
          <li><strong>牌をクリック:</strong> 選択（ハイライト）</li>
          <li><strong>選択中の牌を再クリック:</strong> その牌を捨てる</li>
          <li><strong>ツモ牌:</strong> 手牌の右端に分離表示</li>
        </ul>
      </Section>
      <Section title="アクションボタン">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <tbody>
            {[
              ['ツモ', '#c41e3a', 'ツモ和了を宣言（スキップ可）'],
              ['リーチ', '#d4a030', 'リーチを宣言（テンパイ時）'],
              ['ロン', '#c41e3a', '他家の捨て牌で和了（スキップ可）'],
              ['ポン', '#2a6aaa', '刻子を作る'],
              ['チー', '#2a8a4a', '順子を作る（上家からのみ）'],
              ['カン', '#8a5a2a', '槓子を作る'],
              ['九種九牌', '#8a6a2a', '配牌で9種以上の么九牌がある時に流局'],
              ['スキップ', '#555', '鳴き/ロンを見送る'],
            ].map(([name, color, desc], i) => (
              <tr key={i} style={{ borderBottom: '1px solid #2a3a2a' }}>
                <td style={{ padding: '4px 8px' }}>
                  <span style={{ padding: '2px 10px', background: color, color: '#fff', borderRadius: 4, fontSize: 12, fontWeight: 700 }}>{name}</span>
                </td>
                <td style={{ padding: '4px 8px', color: '#999', fontSize: 13 }}>{desc}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Section>
      <Section title="リーチ時の表示">
        <ul style={{ paddingLeft: 20 }}>
          <li>捨てられる牌（テンパイ維持）のみ明るく表示</li>
          <li>各候補に対する待ち牌が表示される</li>
          <li>リーチ後は自動ツモ切り</li>
        </ul>
      </Section>
    </>
  );
}

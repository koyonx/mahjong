# 麻雀 - 日本式リーチ麻雀

日本式リーチ麻雀のWebアプリケーション。麻雀のコアロジック（牌・面子・役判定・点数計算）をOCamlで実装し、MelangeでJavaScriptにコンパイルしてReactフロントエンドから利用しています。

## 必要な環境

- Docker
- Node.js (v18+)
- npm

## セットアップ

```bash
# 初回セットアップ（Dockerイメージビルド + npm install + Melange出力コピー）
make setup
```

## 起動方法

```bash
# 開発サーバーを起動（http://localhost:5173）
make dev
```

OCamlのソースを変更した場合は、Melange出力の再コピーが必要です：

```bash
make melange-copy
```

## コマンド一覧

```bash
make help              # コマンド一覧を表示
make setup             # 初回セットアップ
make dev               # 開発サーバー起動
make build             # プロダクションビルド
make test              # テスト実行
make ocaml-build       # OCamlビルド
make ocaml-test        # OCamlテスト
make ocaml-watch       # OCamlウォッチビルド
make ocaml-shell       # OCamlコンテナにシェルで入る
make melange-copy      # Melange JS出力をコピー
make clean             # ビルド成果物を削除
```

## プロジェクト構成

```
src/
  core/              # OCaml - 麻雀ロジック
    tile.ml           # 牌の型定義
    mentsu.ml         # 面子判定・和了パターン探索
    hand.ml           # 手牌管理・テンパイ判定
    yaku.ml           # 役判定
    scoring.ml        # 符計算・点数計算
    wall.ml           # 牌山・ドラ
    player.ml         # プレイヤー状態・副露
    game.ml           # 局進行管理
    ai.ml             # CPU思考ロジック
  bindings/          # Melange - OCaml→JSバインディング
    mahjong_js.ml     # JS向けAPI
  components/        # React - UIコンポーネント
    TileView.tsx      # 牌の表示
    PlayerHand.tsx    # 手牌
    Kawa.tsx          # 河（捨て牌）
    GameInfo.tsx      # 局情報
    GameBoard.tsx     # ゲームボード
    AgariDialog.tsx   # 和了結果表示
  mahjong-bridge.ts  # TypeScript型定義・APIラッパー
test/
  test_mahjong.ml    # OUnit2テスト
scripts/
  copy-melange-output.sh  # Melange出力コピー
```

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| 麻雀ロジック | OCaml (Melange) |
| フロントエンド | React + TypeScript |
| スタイリング | Tailwind CSS |
| ビルド | Dune (OCaml) + Vite (フロント) |
| テスト | OUnit2 |
| OCaml環境 | Docker |

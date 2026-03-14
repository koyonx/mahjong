# CLAUDE.md - 麻雀プロジェクト

## プロジェクト概要
日本式麻雀（リーチ麻雀）のWebアプリケーション。

## 技術スタック
- **麻雀ロジック**: OCaml（Melange経由でJSにコンパイル）
- **フロントエンド**: React + TypeScript
- **スタイリング**: Tailwind CSS
- **ビルドツール**: Dune (OCaml) + Vite (フロント)
- **テスト**: OUnit2 (OCamlロジック) / Vitest (UI)
- **パッケージ管理**: opam (OCaml) + npm (JS)
- **OCaml環境**: Docker（開発環境をコンテナで管理）

## ブランチ戦略
- 機能単位で細かくブランチを切り分け、PRを作成する
- **新しいブランチは常に現在の作業ブランチから切る**（mainからではない）
  - 例: `feature/tile-types` → `feature/hand-evaluation` → `feature/scoring` のように連鎖的に派生させる
- ブランチ名は `feature/<機能名>` の形式にする
- PRのマージ先は直前の親ブランチとする
- 各PRは小さく、レビューしやすい単位に保つ

## コーディング規約
- 麻雀のコアロジック（牌の定義、手牌補完、役判定、点数計算）はすべてOCamlで実装する
- OCaml側では代数的データ型とパターンマッチを活用し、牌・面子・役を型安全に表現する
- UIはReact + TypeScriptで実装し、Melange経由でOCamlロジックを呼び出す
- 麻雀用語は英語表記を使用する（例: `hai`, `mentsu`, `agari`, `tsumo`）

## ディレクトリ構成（予定）
```
src/
  core/              # OCaml - 麻雀ロジック（UI非依存）
    tile.ml           # 牌の型定義
    hand.ml           # 手牌管理・補完
    mentsu.ml         # 面子判定
    yaku.ml           # 役判定
    scoring.ml        # 点数計算
    game.ml           # ゲーム進行管理
    ai.ml             # CPU思考ロジック
  frontend/          # React + TypeScript - UI
    components/       # UIコンポーネント
    hooks/            # カスタムフック
    assets/           # 牌画像・音声等
    App.tsx
    main.tsx
```

## Docker環境
- OCamlのビルド・テストはDocker内で実行する
- `docker compose` でOCaml環境とフロント開発環境を管理

## コマンド
```bash
docker compose up -d          # OCaml開発コンテナ起動
docker compose exec ocaml dune build   # OCamlビルド
docker compose exec ocaml dune test    # OCamlテスト実行
npm install                  # JS依存関係インストール
npm dev                      # 開発サーバー起動
npm build                    # プロダクションビルド
npm test                     # UIテスト実行
```

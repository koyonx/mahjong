#!/bin/bash
# MelangeのJS出力をフロントエンドから参照できる位置にコピーする
set -e

CONTAINER_OUTPUT="/home/opam/app/_build/default/src/bindings/output"
LOCAL_OUTPUT="./src/generated"

mkdir -p "$LOCAL_OUTPUT"

docker compose run --rm ocaml bash -c "
  dune build && \
  tar cf - -C $CONTAINER_OUTPUT .
" | tar xf - -C "$LOCAL_OUTPUT"

# Vite dev serverとの互換性のため、Melange出力の変数名衝突を修正
# string.js 内の spellcheck 関数で min が forループ内の min と衝突する
if [ -f "$LOCAL_OUTPUT/node_modules/melange/string.js" ]; then
  sed -i.bak 's/const min = {/const min_ref = {/g; s/min\.contents/min_ref.contents/g' \
    "$LOCAL_OUTPUT/node_modules/melange/string.js"
  rm -f "$LOCAL_OUTPUT/node_modules/melange/string.js.bak"
fi

# サーバーからMelange stdlibを解決できるようシンボリックリンクを作成
if [ -d "$LOCAL_OUTPUT/node_modules/melange" ]; then
  MELANGE_MODULES="$LOCAL_OUTPUT/node_modules"

  # ルートのnode_modulesにもリンク
  for dir in "$MELANGE_MODULES"/melange*; do
    name=$(basename "$dir")
    target=$(cd "$dir" && pwd)
    rm -rf "node_modules/$name"
    ln -sf "$target" "node_modules/$name"
  done

  # serverのnode_modulesにもリンク
  if [ -d "server/node_modules" ]; then
    for dir in "$MELANGE_MODULES"/melange*; do
      name=$(basename "$dir")
      target=$(cd "$dir" && pwd)
      rm -rf "server/node_modules/$name"
      ln -sf "$target" "server/node_modules/$name"
    done
  fi
fi

echo "Melange output copied to $LOCAL_OUTPUT"

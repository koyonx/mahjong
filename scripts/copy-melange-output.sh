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

# サーバーからMelange stdlibを解決できるようシンボリックリンクを作成
if [ -d "$LOCAL_OUTPUT/node_modules/melange" ]; then
  MELANGE_MODULES="$LOCAL_OUTPUT/node_modules"
  SERVER_MODULES="./server/node_modules"
  mkdir -p "$SERVER_MODULES"

  # melange, melange.js のシンボリックリンク
  for dir in "$MELANGE_MODULES"/melange*; do
    name=$(basename "$dir")
    target=$(cd "$dir" && pwd)
    rm -rf "$SERVER_MODULES/$name"
    ln -sf "$target" "$SERVER_MODULES/$name"
  done
fi

echo "Melange output copied to $LOCAL_OUTPUT"

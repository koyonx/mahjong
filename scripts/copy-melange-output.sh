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

echo "Melange output copied to $LOCAL_OUTPUT"

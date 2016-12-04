#!/bin/sh

ROOT_DIR=$(cd $(dirname $0); pwd)
RESULT_NAME="$ROOT_DIR/bin/luacc.lua"

rm $ROOT_DIR/bin/*

cd src
./luacc.lua \
    -o $RESULT_NAME \
    -i argparse/src -i templates/lib/resty \
    luacc helpers argparse template
cd ..

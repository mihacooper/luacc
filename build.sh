#!/bin/sh

cd src
./luacc.lua \
    -o ../bin/luacc \
    luacc filesys stringex argparse.src.argparse

#luac -o bin/luacc bin/luacc
#!/bin/sh

SOURCES_DIR=${ROOT_DIR}/src

log "Combine LuaCC sources using LuaCC binary"
lua $LUACC_BIN \
    -o ${WORK_DIR}/luacc \
    -i ${SOURCES_DIR} -i ${SOURCES_DIR}/argparse/src -i ${SOURCES_DIR}/templates/lib/resty \
    luacc helpers argparse template

log "Check result file workability"
OUTPUT=$(lua ${WORK_DIR}/luacc 2>&1 | grep "^Usage: luacc.*")
( (( $? == 0 )) && { test_succeed; } ) || { test_failed "unexpected output:" "$OUTPUT"; }
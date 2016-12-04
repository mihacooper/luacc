#!/bin/bash


#--------------------------------------------------
#---------- TEST FRAMEWORK ------------------------
#--------------------------------------------------

log(){
    echo -e "[ $(date +"%8T.%2N") ]" $@
}

test_start(){
    echo "[   STARTED   ]" $1
}

test_finish(){
    echo "[   FINISHED  ]" $1
}

test_succeed(){
    echo "[   SUCCEED   ]"
    exit 0
}

test_failed(){
    echo "[   FAILED    ]" $1
    log $2
    exit 1
}

#--------------------------------------------------

ROOT_DIR=$(cd $(dirname $0); pwd)
LUACC_BIN=$ROOT_DIR/bin/luacc.lua
WORK_DIR=$ROOT_DIR/work_dir

$ROOT_DIR/build.sh
if ! (( $? == 0)); then
    test_failed "Unable to compile LuaCC"
fi

[ -f $LUACC_BIN ] || { echo "Compilation failed!"; exit 1; }
[ -d $WORK_DIR ] || { mkdir $WORK_DIR; }

SUCCESSFUL_NUM=0
FAILED_NUM=0

cd $ROOT_DIR/test
TESTS=$(ls $ROOT_DIR/test/*.sh)
for TEST_CASE in $TESTS; do
    test_start $TEST_CASE
    source $TEST_CASE
    if (( $? == 0 )); then
        SUCCESSFUL_NUM=$(( $SUCCESSFUL_NUM + 1 ))
    else
        FAILED_NUM=$(( $FAILED_NUM + 1 ))
    fi
    rm -f $WORK_DIR/*
    test_finish $TEST_CASE
done
cd $ROOT_DIR

rm -r $WORK_DIR

log ""
log "Tests results:"
log "\t$SUCCESSFUL_NUM tests succeeded"
log "\t$FAILED_NUM tests failed"

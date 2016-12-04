#!/bin/sh

log "Create source files"

write_source_file(){
    log "Write source file $1"
    echo $2 > $1
}

write_source_file ${WORK_DIR}/source_file_main.lua \
'
file1 = require "source_file_1"
file2 = require "source_file_2"

local name = "source_file_main.lua"

print(name .. ": " .. file1.name())
print(name .. ": " .. file2.name())

print(name)
'

write_source_file ${WORK_DIR}/source_file_1.lua \
'
local name = "source_file_1.lua"
print(name)
return { name = function() return name end }
'

write_source_file ${WORK_DIR}/source_file_2.lua \
'
local name = "source_file_2.lua"
print(name)
return { name = function() return name end }
'

log "Combine source files"

lua $LUACC_BIN \
    -o ${WORK_DIR}/result.test_smoke.lua \
    -i ${WORK_DIR} \
    source_file_main source_file_1 source_file_2

log "Execute result file ${WORK_DIR}/result.test_smoke.lua"
ACTUAL_OUTPUT=$(lua ${WORK_DIR}/result.test_smoke.lua)
EXPECT_OUTPUT="source_file_1.lua
source_file_2.lua
source_file_main.lua: source_file_1.lua
source_file_main.lua: source_file_2.lua
source_file_main.lua"

( [ "$ACTUAL_OUTPUT" = "$EXPECT_OUTPUT" ] && { test_succeed; } ) || { test_failed "unexpected output:" "$ACTUAL_OUTPUT"; }
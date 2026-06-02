#!/usr/bin/env bash

set -euo pipefail

SCRIPT="$(dirname "$0")/lab6.sh"
PASS=0
FAIL=0

setup() {
    TMPDIR_TEST=$(mktemp -d)
}

teardown() {
    rm -rf "$TMPDIR_TEST"
}

ok() {
    local name="$1" path="$2"
    if [[ -e "$path" ]]; then
        echo "  ok: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name (нет файла $path)"
        FAIL=$((FAIL + 1))
    fi
}

no() {
    local name="$1" path="$2"
    if [[ ! -e "$path" ]]; then
        echo "  ok: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name (файл не должен существовать: $path)"
        FAIL=$((FAIL + 1))
    fi
}

echo "[1] простое переименование"
setup
printf 'hello' > "$TMPDIR_TEST/hello.txt"
bash "$SCRIPT" "$TMPDIR_TEST" 100 >/dev/null
no  "hello.txt пропал"  "$TMPDIR_TEST/hello.txt"
ok  "hello.h появился"  "$TMPDIR_TEST/hello.h"
teardown

echo "[2] большой файл не трогается"
setup
python3 -c "print('x'*200)" > "$TMPDIR_TEST/big.txt"
bash "$SCRIPT" "$TMPDIR_TEST" 100 >/dev/null
ok  "big.txt на месте"  "$TMPDIR_TEST/big.txt"
teardown

echo "[3] имя с подчёркиванием"
setup
printf 'hi' > "$TMPDIR_TEST/my_file.c"
bash "$SCRIPT" "$TMPDIR_TEST" 100 >/dev/null
no  "my_file.c пропал"   "$TMPDIR_TEST/my_file.c"
ok  "my_file.mf появился" "$TMPDIR_TEST/my_file.mf"
teardown

echo "[4] dry run ничего не меняет"
setup
printf 'test' > "$TMPDIR_TEST/doc.md"
bash "$SCRIPT" -n "$TMPDIR_TEST" 100 >/dev/null
ok  "doc.md на месте"  "$TMPDIR_TEST/doc.md"
no  "doc.d не создан"  "$TMPDIR_TEST/doc.d"
teardown

echo "[5] рекурсия"
setup
mkdir -p "$TMPDIR_TEST/sub"
printf 'nested' > "$TMPDIR_TEST/sub/note.txt"
bash "$SCRIPT" -r "$TMPDIR_TEST" 100 >/dev/null
no  "sub/note.txt пропал"  "$TMPDIR_TEST/sub/note.txt"
ok  "sub/note.n появился"  "$TMPDIR_TEST/sub/note.n"
teardown

echo "[6] файл без расширения"
setup
printf 'x' > "$TMPDIR_TEST/readme"
bash "$SCRIPT" "$TMPDIR_TEST" 100 >/dev/null
no  "readme пропал"    "$TMPDIR_TEST/readme"
ok  "readme.r появился" "$TMPDIR_TEST/readme.r"
teardown

echo "[7] скрытый файл не трогается"
setup
printf 'hidden' > "$TMPDIR_TEST/.hidden"
bash "$SCRIPT" "$TMPDIR_TEST" 100 >/dev/null
ok  ".hidden на месте"  "$TMPDIR_TEST/.hidden"
teardown

echo "[8] имя с дефисом"
setup
printf 'hi' > "$TMPDIR_TEST/test-case.sh"
bash "$SCRIPT" "$TMPDIR_TEST" 100 >/dev/null
no  "test-case.sh пропал"  "$TMPDIR_TEST/test-case.sh"
ok  "test-case.tc появился" "$TMPDIR_TEST/test-case.tc"
teardown

echo ""
echo "pass: $PASS, fail: $FAIL"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1

#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 [-r] [-n] [-v] <dir> <size>"
    echo "  <dir>   директория"
    echo "  <size>  порог в байтах"
    echo "  -r      рекурсивно"
    echo "  -n      dry run"
    echo "  -v      подробный вывод"
    exit 1
}

RECURSIVE=0
DRY_RUN=0
VERBOSE=0

while getopts "rnv" opt; do
    case "$opt" in
        r) RECURSIVE=1 ;;
        n) DRY_RUN=1 ;;
        v) VERBOSE=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -lt 2 ]] && usage

DIR="$1"
SIZE_THRESHOLD="$2"

[[ ! -d "$DIR" ]] && { echo "ошибка: '$DIR' не директория" >&2; exit 1; }
[[ ! "$SIZE_THRESHOLD" =~ ^[0-9]+$ ]] && { echo "ошибка: размер должен быть числом" >&2; exit 1; }

get_initials() {
    local base="$1"
    local initials=""
    local old_ifs="$IFS"
    IFS='_-'
    read -ra parts <<< "$base"
    IFS="$old_ifs"
    for part in "${parts[@]}"; do
        [[ -n "$part" ]] && initials+="${part:0:1}"
    done
    printf '%s' "$initials"
}

get_file_size() {
    if stat -f%z "$1" &>/dev/null; then
        stat -f%z "$1"
    else
        stat -c%s "$1"
    fi
}

RENAMED=0
SKIPPED=0

process_file() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")
    local filedir
    filedir=$(dirname "$filepath")

    [[ "$filename" == .* ]] && return 0

    local fsize
    fsize=$(get_file_size "$filepath")
    [[ "$fsize" -ge "$SIZE_THRESHOLD" ]] && return 0

    local base
    if [[ "$filename" == *.* ]]; then
        base="${filename%.*}"
    else
        base="$filename"
    fi

    local initials
    initials=$(get_initials "$base")
    [[ -z "$initials" ]] && { SKIPPED=$((SKIPPED + 1)); return 0; }

    local new_name="${base}.${initials}"
    [[ "$new_name" == "$filename" ]] && return 0

    local new_path="${filedir}/${new_name}"

    [[ "$VERBOSE" -eq 1 || "$DRY_RUN" -eq 1 ]] && echo "$filepath -> $new_path"

    if [[ "$DRY_RUN" -eq 0 ]]; then
        if [[ -e "$new_path" ]]; then
            echo "пропускаю '$filepath': '$new_path' уже существует" >&2
            SKIPPED=$((SKIPPED + 1))
            return 0
        fi
        mv -- "$filepath" "$new_path"
    fi

    RENAMED=$((RENAMED + 1))
}

if [[ "$RECURSIVE" -eq 1 ]]; then
    FIND_CMD=(find "$DIR" -type f -print0)
else
    FIND_CMD=(find "$DIR" -maxdepth 1 -type f -print0)
fi

while IFS= read -r -d '' filepath; do
    process_file "$filepath"
done < <("${FIND_CMD[@]}")

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry run: $RENAMED переименовано, $SKIPPED пропущено"
else
    echo "переименовано: $RENAMED, пропущено: $SKIPPED"
fi

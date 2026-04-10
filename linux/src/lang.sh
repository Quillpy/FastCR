#!/usr/bin/env bash

LANG_ID=""
BINARY=""
COMPILE_CMD=""
RUN_CMD=""

detect_lang() {
    local file="$1"
    local ext="${file##*.}"
    local base="${file%.*}"
    local dir
    dir="$(dirname "$file")"
    local basename_file
    basename_file="${base##*/}"
    BINARY="$dir/.fastcr_${basename_file}"

    case "$ext" in
        c)
            LANG_ID="c"
            if [[ -n "$OPT_DEBUG" ]]; then
                COMPILE_CMD="gcc -g -O0 -Wall -Wextra -fsanitize=address,undefined -o $BINARY $file"
            else
                COMPILE_CMD="gcc -O2 -o $BINARY $file"
            fi
            RUN_CMD="$BINARY"
            ;;
        cpp|cc|cxx)
            LANG_ID="cpp"
            if [[ -n "$OPT_DEBUG" ]]; then
                COMPILE_CMD="g++ -g -O0 -Wall -Wextra -std=c++17 -fsanitize=address,undefined -o $BINARY $file"
            else
                COMPILE_CMD="g++ -O2 -std=c++17 -o $BINARY $file"
            fi
            RUN_CMD="$BINARY"
            ;;
        java)
            LANG_ID="java"
            local classname
            classname="$(grep -m1 'public class' "$file" | sed 's/.*public class \([A-Za-z0-9_]*\).*/\1/')"
            [[ -z "$classname" ]] && classname="${basename_file}"
            local java_out="$dir/.fastcr_${basename_file}_java"
            mkdir -p "$java_out"
            COMPILE_CMD="javac -d $java_out $file"
            RUN_CMD="java -cp $java_out $classname"
            BINARY="$java_out"
            ;;
        py)
            LANG_ID="python"
            COMPILE_CMD=""
            if command -v pypy3 &>/dev/null; then
                RUN_CMD="pypy3 $file"
            else
                RUN_CMD="python3 $file"
            fi
            BINARY=""
            ;;
        rs)
            LANG_ID="rust"
            if [[ -n "$OPT_DEBUG" ]]; then
                COMPILE_CMD="rustc -g -o $BINARY $file"
            else
                COMPILE_CMD="rustc -C opt-level=2 -o $BINARY $file"
            fi
            RUN_CMD="$BINARY"
            ;;
        go)
            LANG_ID="go"
            COMPILE_CMD="go build -o $BINARY $file"
            RUN_CMD="$BINARY"
            ;;
        kt)
            LANG_ID="kotlin"
            local jarfile="$dir/.fastcr_${basename_file}.jar"
            COMPILE_CMD="kotlinc $file -include-runtime -d $jarfile"
            RUN_CMD="java -jar $jarfile"
            BINARY="$jarfile"
            ;;
        js)
            LANG_ID="js"
            COMPILE_CMD=""
            RUN_CMD="node $file"
            BINARY=""
            ;;
        rb)
            LANG_ID="ruby"
            COMPILE_CMD=""
            RUN_CMD="ruby $file"
            BINARY=""
            ;;
        hs)
            LANG_ID="haskell"
            local hs_tmp="$dir/.fastcr_${basename_file}_hs"
            mkdir -p "$hs_tmp"
            COMPILE_CMD="ghc -O2 -o $BINARY $file -outputdir $hs_tmp"
            RUN_CMD="$BINARY"
            ;;
        ts)
            LANG_ID="typescript"
            COMPILE_CMD=""
            RUN_CMD="ts-node $file"
            BINARY=""
            ;;
        sh)
            LANG_ID="shell"
            COMPILE_CMD=""
            RUN_CMD="bash $file"
            BINARY=""
            ;;
        php)
            LANG_ID="php"
            COMPILE_CMD=""
            RUN_CMD="php $file"
            BINARY=""
            ;;
        *)
            echo "error: unsupported extension: .$ext"
            exit 1
            ;;
    esac
}

check_compiler() {
    local cmd
    case "$LANG_ID" in
        c)      cmd="gcc" ;;
        cpp)    cmd="g++" ;;
        java)   cmd="javac" ;;
        python) cmd="python3"; command -v pypy3 &>/dev/null && cmd="pypy3" ;;
        rust)   cmd="rustc" ;;
        go)     cmd="go" ;;
        kotlin) cmd="kotlinc" ;;
        js)     cmd="node" ;;
        rb)     cmd="ruby" ;;
        hs)     cmd="ghc" ;;
        ts)     cmd="ts-node" ;;
        shell)  cmd="bash" ;;
        php)    cmd="php" ;;
        *)      return 0 ;;
    esac
    if ! command -v "$cmd" &>/dev/null; then
        echo "error: $cmd is not installed"
        return 1
    fi
    return 0
}

compile_file() {
    [[ -z "$COMPILE_CMD" ]] && return 0

    [[ -n "$OPT_VERBOSE" ]] && echo "compile: $COMPILE_CMD"

    local err
    err=$(eval "$COMPILE_CMD" 2>&1)
    local status=$?

    if [[ $status -ne 0 ]]; then
        echo "compile error:"
        echo "$err"
        return 1
    fi

    [[ -n "$OPT_VERBOSE" && -n "$err" ]] && echo "$err"
    return 0
}

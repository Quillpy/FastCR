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
    BINARY="$dir/.fastcr_${base##*/}"

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
            BINARY="$dir"
            local classname
            classname="$(grep -m1 'public class' "$file" | sed 's/.*public class \([A-Za-z0-9_]*\).*/\1/')"
            [[ -z "$classname" ]] && classname="${base##*/}"
            COMPILE_CMD="javac -d $BINARY $file"
            RUN_CMD="java -cp $BINARY $classname"
            BINARY="$dir/${classname}.class"
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
                COMPILE_CMD="rustc -o $BINARY $file"
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
            local jarfile="${BINARY}.jar"
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
            COMPILE_CMD="ghc -O2 -o $BINARY $file -outputdir /tmp/fastcr_hs"
            RUN_CMD="$BINARY"
            ;;
        *)
            echo "error: unsupported extension: .$ext"
            exit 1
            ;;
    esac
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

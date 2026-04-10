# FastCR — Full Documentation

> **`cr`** — Compile & Run any source file in one command.

---

## Table of Contents

1. [Overview](#1-overview)
2. [How It Works](#2-how-it-works)
3. [Installation](#3-installation)
4. [Commands & Usage](#4-commands--usage)
5. [Supported Languages](#5-supported-languages)
6. [Batch Testing](#6-batch-testing)
7. [Error Reference](#7-error-reference)
8. [Examples](#8-examples)

---

## 1. Overview

FastCR is a single Bash script that wraps the compile-and-run workflow for 13 programming languages into one unified command: `cr`.

Instead of:
```bash
g++ -O2 -std=c++17 -o app app.cpp && ./app
```

You write:
```bash
cr app.cpp
```

FastCR figures out the language from the file extension, invokes the correct compiler or interpreter with sensible default flags, times execution in milliseconds, reports memory usage, and outputs clear verdicts (AC, WA, TLE, RTE, MLE).

---

## 2. How It Works

When you run `cr <file>`, the script performs the following steps:

```
1. Parse arguments  →  detect flags (--help, --del, --t, --i, --e, --d, --tl, --ml, --v, --tm, --n, --w, --cp, --b)
2. Validate file    →  confirm the file exists
3. Detect language  →  read the file extension
4. Check compiler   →  verify the required toolchain is installed
5. Compile phase    →  (compiled languages only)
                        invoke compiler with flags
6. Run phase        →  execute the binary or interpreter
                        forward any extra arguments to the program
                        measure execution time and memory
7. Report verdict   →  AC / WA / TLE / RTE / MLE with timing stats
```

For **interpreted languages** (Python, Node, Ruby, etc.), step 5 is skipped — the file is passed directly to the runtime.

---

## 3. Installation

### Linux (Automatic)

```bash
git clone https://github.com/Quillpy/fastcr
cd fastcr/linux
chmod +x install.sh
./install.sh
```

The installer:
- Copies `cr` to `/usr/local/bin/cr` if writable, otherwise `~/.local/bin/cr`
- Sets executable permissions automatically

If installed to `~/.local/bin`, add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Manual

```bash
cd linux
chmod +x cr
sudo cp cr /usr/local/bin/cr
```

### Uninstall

```bash
rm /usr/local/bin/cr 2>/dev/null || rm ~/.local/bin/cr 2>/dev/null
```

---

## 4. Commands & Usage

### Basic Usage

```
cr [flags] <file>
```

### Flags

| Flag | Description |
|------|-------------|
| `--t` | Feed `input.txt` as stdin |
| `--i <file>` | Feed a custom file as stdin |
| `--o <file>` | Write output to a file |
| `--e <file>` | Compare output against expected, show diff |
| `--b` | Batch test all `test*.txt` files |
| `--d` | Debug build with sanitizers and warnings |
| `--tl <ms>` | Time limit in milliseconds (default: 2000) |
| `--ml <MB>` | Memory limit in MB (default: 256) |
| `--v` | Verbose — print compile command and warnings |
| `--tm` | Show cached stats from last run |
| `--n <file>` | Create a new file with boilerplate |
| `--w` | Watch mode — rerun on every file save |
| `--cp` | Copy source file to clipboard |
| `--del <file>` | Delete compiled binary for a file |
| `--del *` | Delete all compiled binaries in current directory |
| `-h, --help` | Show help message |

### Argument Forwarding

Any arguments after the filename are forwarded directly to your program.

```bash
cr main.c input.txt --verbose
cr app.py --port 8080
```

---

## 5. Supported Languages

| Extension | Language | Compiler/Runner |
|-----------|----------|-----------------|
| `.c` | C | `gcc -O2` |
| `.cpp` `.cc` `.cxx` | C++ | `g++ -O2 -std=c++17` |
| `.java` | Java | `javac` / `java` |
| `.py` | Python 3 | `python3` (or `pypy3` if available) |
| `.rs` | Rust | `rustc -C opt-level=2` |
| `.go` | Go | `go build` |
| `.kt` | Kotlin | `kotlinc` |
| `.js` | JavaScript | `node` |
| `.rb` | Ruby | `ruby` |
| `.hs` | Haskell | `ghc -O2` |
| `.ts` | TypeScript | `ts-node` |
| `.sh` | Shell | `bash` |
| `.php` | PHP | `php` |

---

## 6. Batch Testing

Place test files in the current directory:

```
test1.txt     input
test1.out     expected output (optional)
test2.txt
test2.out
```

Run:
```bash
cr --b solution.cpp
```

Output:
```
Batch Tests
--------------------------------------------------
  test1.txt               AC      34 ms  1.2 MB
  test2.txt               WA      28 ms  1.1 MB
  test3.txt               TLE   2000+ ms  -- MB
--------------------------------------------------
  Passed: 1   Failed: 2
```

Verdicts: `AC` accepted, `WA` wrong answer, `TLE` time limit exceeded, `RTE` runtime error, `RAN` ran (no expected file).

---

## 7. Error Reference

| Error message | Cause | Fix |
|---------------|-------|-----|
| `usage: cr [flags] <file>` | No file provided | Pass a source file |
| `error: file not found: ...` | Path doesn't exist | Check spelling and working directory |
| `error: unsupported extension: .xyz` | Extension not supported | Use a supported language |
| `error: gcc is not installed` | Compiler/interpreter missing | Install the required toolchain |
| `compile error:` | Compilation failed | Read compiler output above |
| `unknown flag: ...` | Unrecognized flag | Check `cr --help` |

---

## 8. Examples

```bash
cr solution.cpp
cr --t solution.cpp
cr --i in.txt --e expected.txt solution.cpp
cr --b --tl 1000 solution.cpp
cr --d solution.cpp
cr --n problem_b.cpp
cr --w --t solution.py
cr --del solution.cpp
cr --del *
cr --cp solution.cpp
cr --help
```

### Watch Mode

Requires `inotify-tools`:
```bash
sudo apt install inotify-tools
```

### Creating New Files

```bash
cr --n main.cpp
cr --n subdir/solution.py
```

Creates parent directories automatically if they don't exist.

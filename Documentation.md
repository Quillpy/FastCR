# FastCR — Full Documentation

Warning: this doc contains mild sarcasm to keep you awake during installs.

> **`cr`** — Compile & Run any source file in one command.
> Full guide: https://github.com/Quillpy/Fastcc

---

## Table of Contents

1. [Overview](#1-overview)
2. [How It Works](#2-how-it-works)
3. [Installation](#3-installation)
   - [Linux/macOS (Automatic)](#31-linuxmacos-automatic)
   - [Windows (PowerShell)](#32-windows-powershell)
   - [Manual](#33-manual)
   - [Uninstall](#34-uninstall)
4. [Commands & Usage](#4-commands--usage)
   - [Basic Usage](#41-basic-usage)
   - [Passing Arguments to Your Program](#42-passing-arguments-to-your-program)
   - [--keep Flag](#43---keep-flag)
   - [--del Command](#44---del-command)
   - [--help Command](#45---help-command)
5. [Supported Languages](#5-supported-languages)
   - [C](#51-c)
   - [C++](#52-c-1)
   - [Java](#53-java)
   - [Rust](#54-rust)
   - [Go](#55-go)
   - [Python](#56-python)
   - [JavaScript](#57-javascript)
   - [TypeScript](#58-typescript)
   - [Shell](#59-shell)
   - [Ruby](#510-ruby)
   - [PHP](#511-php)
6. [Output Reference](#6-output-reference)
   - [Compiled Languages](#61-compiled-languages)
   - [Interpreted Languages](#62-interpreted-languages)
   - [Exit Code Reporting](#63-exit-code-reporting)
7. [Binary Management](#7-binary-management)
8. [Performance](#8-performance)
9. [Requirements](#9-requirements)
10. [Error Reference](#10-error-reference)
11. [Examples](#11-examples)

---

## 1. Overview

FastCR is a single Bash script that wraps the compile-and-run workflow for 11 programming languages into one unified command: `cr`.

Instead of:
```bash
g++ -Wall -Wextra -O2 -std=c++17 -o app app.cpp && ./app
```

You write:
```bash
cr app.cpp
```

FastCR figures out the language from the file extension, invokes the correct compiler or interpreter with sensible default flags, times both phases in milliseconds, prints a clear success/failure report with the exit code, and offers to clean up the compiled binary when done.

---

## 2. How It Works

When you run `cr <file>`, the script performs the following steps:

```
1. Parse arguments  →  detect flags (--keep, --del, --help)
2. Validate file    →  confirm the file exists
3. Detect language  →  read the file extension
4. Compile phase    →  (compiled languages only)
                        invoke compiler with flags
                        measure time in milliseconds
                        print "Compile successful │ Xms"
                        abort with error if compilation fails
5. Run phase        →  execute the binary or interpreter
                        forward any extra arguments
                        measure execution time
                        print "Run successful │ exit code 0 │ Xms ✓"
                           or "Run finished with errors │ exit code N │ Xms"
6. Binary cleanup   →  (compiled languages only, unless --keep)
                        prompt: "Delete compiled binary? [Y/n]"
7. Exit             →  forward the program's own exit code
```

For **interpreted languages** (Python, Node, Ruby, etc.), steps 4 and 6 are skipped entirely — the file is passed directly to the runtime.

---

## 3. Installation

### 3.1 Linux/macOS (Automatic)

```bash
git clone https://github.com/Quillpy/Fastcc.git
cd Fastcc/linux
chmod +x install.sh
./install.sh
```

The installer:
- Copies `cr` to `/usr/local/bin/cr` if writable, otherwise `~/.local/bin/cr`
- Sets executable permissions automatically
- Prints a confirmation with example commands
- Scans for language runtimes and gives you the friendliest possible nudge

If installed to `~/.local/bin`, make sure that directory is on your `PATH`. Add this to your `~/.bashrc` or `~/.zshrc` if needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:
```bash
source ~/.bashrc   # or source ~/.zshrc
```

### 3.2 Windows (PowerShell)

Open PowerShell and run:
```powershell
git clone https://github.com/Quillpy/Fastcc.git
cd Fastcc\windows
powershell -ExecutionPolicy Bypass -File .\install.ps1
```
This installs cr.ps1 and a cr.cmd shim into a PATH directory.

Verify:
```powershell
cr --help
```

### 3.3 Manual

Linux/macOS manual install:
```bash
cd linux
chmod +x cr
sudo cp cr /usr/local/bin/cr
```

Windows manual usage without installer:
```powershell
# Run directly from the repo folder
powershell -ExecutionPolicy Bypass -File windows\cr.ps1 <file>
```

### 3.4 Uninstall

Linux/macOS:
```bash
sudo rm /usr/local/bin/cr || true
rm ~/.local/bin/cr 2>/dev/null || true
```

Windows:
- Delete cr.ps1 (and cr.cmd) from the folder the installer used (WindowsApps or %USERPROFILE%\.local\bin)
- Close and reopen terminals to refresh PATH

---

## 4. Commands & Usage

### 4.1 Basic Usage

```
cr <file> [args...]
```

Compile (if applicable) and run the given source file.

```bash
cr main.c
cr app.cpp
cr Main.java
cr script.py
cr server.rs
cr index.js
```

### 4.2 Passing Arguments to Your Program

Any arguments after the filename are forwarded directly to your program.

```bash
cr main.c input.txt --verbose
cr app.py --port 8080
cr Main.java Alice 42
```

Inside your program these arrive as the usual `argv` / command-line arguments.

### 4.3 `--keep` Flag

```
cr --keep <file> [args...]
```

Run the file normally but **skip the binary-delete prompt** at the end. The compiled binary is kept in the same directory as the source file.

```bash
cr --keep server.rs
cr --keep main.c
```

Useful when you want to run the binary again later without recompiling.

### 4.4 `--del` Command

```
cr --del
```

Scans the **current working directory** for compiled binaries (executable files with no extension) and offers to delete them all at once.

Example session:
```
❯ Scanning /home/user/projects for compiled binaries…

  Found 3 binary/binaries:
    – main    (24K)
    – server  (88K)
    – test    (16K)

  Delete all 3 file(s)? [y/N]  y

✔ Deleted 3 binary/binaries.
```

Answering `n` or pressing Enter without typing `y` cancels the operation — nothing is deleted.

### 4.5 `--help` Command

```
cr --help
cr -h
```

Prints the full usage reference to the terminal and **opens `https://github.com/Quillpy/Fastcc`** in your default browser (best-effort, using `xdg-open` on Linux or `open` on macOS).

---

## 5. Supported Languages

### 5.1 C

| Property    | Value |
|-------------|-------|
| Extension   | `.c` |
| Compiler    | `gcc` |
| Flags       | `-Wall -Wextra -O2` |
| Output      | binary named after the source file (no extension) |

```bash
cr main.c
cr utils.c myarg
```

### 5.2 C++

| Property    | Value |
|-------------|-------|
| Extensions  | `.cpp`, `.cc`, `.cxx` |
| Compiler    | `g++` |
| Flags       | `-Wall -Wextra -O2 -std=c++17` |
| Output      | binary named after the source file |

```bash
cr app.cpp
cr engine.cc
```

### 5.3 Java

| Property    | Value |
|-------------|-------|
| Extension   | `.java` |
| Compiler    | `javac` |
| Runner      | `java` |
| Class path  | same directory as source file |
| Artifact    | `<ClassName>.class` (prompted for deletion) |

The class name must match the filename (standard Java convention).

```bash
cr Main.java
cr Calculator.java 10 20
```

### 5.4 Rust

| Property    | Value |
|-------------|-------|
| Extension   | `.rs` |
| Compiler    | `rustc` |
| Output      | binary named after the source file |

```bash
cr hello.rs
cr game.rs level1
```

### 5.5 Go

| Property    | Value |
|-------------|-------|
| Extension   | `.go` |
| Runner      | `go run` |
| Type        | Interpreted (no binary created) |

```bash
cr main.go
cr server.go --port 9000
```

### 5.6 Python

| Property    | Value |
|-------------|-------|
| Extension   | `.py` |
| Runner      | `python3` |
| Type        | Interpreted |

```bash
cr script.py
cr app.py --debug
```

### 5.7 JavaScript

| Property    | Value |
|-------------|-------|
| Extension   | `.js` |
| Runner      | `node` |
| Type        | Interpreted |

```bash
cr index.js
cr server.js 3000
```

### 5.8 TypeScript

| Property    | Value |
|-------------|-------|
| Extension   | `.ts` |
| Runner      | `ts-node` |
| Type        | Interpreted |

```bash
cr app.ts
cr api.ts --env production
```

Requires `ts-node` to be installed (`npm install -g ts-node`).

### 5.9 Shell

| Property    | Value |
|-------------|-------|
| Extension   | `.sh` |
| Runner      | `bash` |
| Type        | Interpreted |

```bash
cr deploy.sh
cr setup.sh --dry-run
```

### 5.10 Ruby

| Property    | Value |
|-------------|-------|
| Extension   | `.rb` |
| Runner      | `ruby` |
| Type        | Interpreted |

```bash
cr app.rb
cr task.rb input.csv
```

### 5.11 PHP

| Property    | Value |
|-------------|-------|
| Extension   | `.php` |
| Runner      | `php` |
| Type        | Interpreted |

```bash
cr index.php
cr cli.php --migrate
```

---

## 6. Output Reference

### 6.1 Compiled Languages

```
  FastCR  ──────────────────────────────
  File  :  main.c
  Lang  :  .c
  ─────────────────────────────────

› Compiling with gcc…
✔ Compile successful  │  287ms

› Running main…
  ─────────────────────────────────
Hello, world!
  ─────────────────────────────────
✔ Run successful  │  exit code 0  │  3ms  ✓

  Delete compiled binary 'main'? [Y/n]
```

### 6.2 Interpreted Languages

```
  FastCR  ──────────────────────────────
  File  :  script.py
  Lang  :  .py
  ─────────────────────────────────

› Running with python3…
  ─────────────────────────────────
Hello from Python!
  ─────────────────────────────────
✔ Run successful  │  exit code 0  │  41ms  ✓
```

### 6.3 Exit Code Reporting

| Outcome | Output |
|---------|--------|
| Success (exit 0) | `✔ Run successful  │  exit code 0  │  Xms  ✓` |
| Failure (exit N) | `⚠ Run finished with errors  │  exit code N  │  Xms` |
| Compile failure  | `✘ ERROR: Compilation failed. Fix the errors above and retry.` |

FastCR always exits with the **same exit code as your program**, so it works correctly in scripts and CI pipelines.

---

## 7. Binary Management

For compiled languages, FastCR places the output binary in the **same directory as the source file**, named after the source file without its extension:

```
src/main.c  →  src/main
app/App.java →  app/App.class
```

After a successful run, FastCR prompts:

```
  Delete compiled binary 'main'? [Y/n]
```

- Press **Enter** or type `y` → binary is deleted
- Type `n` → binary is kept

Use `--keep` to skip this prompt entirely and always keep the binary.

Use `cr --del` to bulk-delete all binaries in a directory at any time.

---

## 8. Performance

FastCR is optimised to add as little overhead as possible:

- `LC_ALL=C` and `LANG=C` are exported at startup to disable locale processing, which is one of the most common sources of shell script slowdown.
- Timing uses `date +%s%3N` (millisecond precision) with minimal subshell overhead.
- No external dependencies beyond Bash 4+ and the language toolchain you're already using.

---

## 9. Requirements

Bash 4+ on Linux/macOS, or PowerShell 5.1+/pwsh 7+ on Windows. Your language toolchains must be installed separately.

| Requirement | Notes |
|-------------|-------|
| **Bash 4.0+** | Required. Pre-installed on most Linux distros and macOS with Homebrew. |
| `gcc`        | For `.c` files |
| `g++`        | For `.cpp` / `.cc` / `.cxx` files |
| `javac` + `java` | JDK required for `.java` files |
| `rustc`      | For `.rs` files. Install via [rustup](https://rustup.rs) |
| `go`         | For `.go` files |
| `python3`    | For `.py` files |
| `node`       | For `.js` files |
| `ts-node`    | For `.ts` files. Install: `npm install -g ts-node` |
| `bash`       | For `.sh` files (already required for FastCR itself) |
| `ruby`       | For `.rb` files |
| `php`        | For `.php` files |

You only need to install the tools for the languages you actually use. If a required tool is missing, FastCR prints a clear error and exits without doing anything harmful.

---

## 10. Error Reference

| Error message | Cause | Fix |
|---------------|-------|-----|
| `File not found: 'foo.c'` | The path given doesn't exist | Check spelling and working directory |
| `'gcc' is not installed` | Compiler missing | Install the required tool |
| `Compilation failed.` | Compiler reported errors | Read the compiler output above the error line |
| `Unsupported extension '.xyz'` | Extension not in the dispatch table | Use a supported language or extend the script |

---

## 11. Examples

Pro tip: everything after the filename goes to your program unchanged. Be creative, not destructive.

**Compile and run a C program:**
```bash
cr main.c
```

**Run a Python script with arguments:**
```bash
cr process.py data.csv --output result.txt
```

**Compile a Rust file and keep the binary:**
```bash
cr --keep engine.rs
```

**Run a Java program with arguments:**
```bash
cr Calculator.java 100 200
```

**Delete all compiled binaries in the project folder:**
```bash
cd ~/myproject
cr --del
```

**Check available commands:**
```bash
cr --help
```

---

## 12. Testing and Development Guide

- Run unit-ish tests on Linux/macOS:
  - bash tests/run_tests.sh
- Add more cases in tests/run_tests.sh to cover new languages or flags.
- On Windows, open PowerShell and sanity check:
  - cr --help
  - cr --del
  - cr .\examples\hello.py

Coding tips:
- Keep linux/cr POSIX-ish Bash 4+, no bashisms that break on older distros.
- Mirror features in windows/cr.ps1 for parity.
- Keep output tidy, colorful, and helpful. The goal is to inform, not shout.

Changelog policy:
- Update README and Documentation when behavior changes.
- Mention new languages in all the places: installers, dispatch tables, docs, tests.

License: MIT. See LICENSE.

*FastCR — https://github.com/Quillpy/Fastcc*

<div align="center">

# ⚡ FastCR

Warning: This README has jokes. Your compiler will not laugh, but you might.

**Compile & run any source file with a single command.**

```bash
cr main.c
```

[![Shell](https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue?style=flat-square)](https://github.com/Quillpy/Fastcc)
[![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)](LICENSE)
[![Languages](https://img.shields.io/badge/languages-11-purple?style=flat-square)](https://github.com/Quillpy/Fastcc)

</div>

---

## What is FastCR?

FastCR is a lightweight Bash command `cr` that eliminates the repetitive compile-then-run workflow. Instead of typing:

```bash
gcc -Wall -Wextra -O2 -o main main.c && ./main
```

You type:

```bash
cr main.c
```

FastCR detects the language from the file extension, runs the right compiler or interpreter, times both phases, and asks if you want to clean up the binary — all in one step.

---

## Features

- **11 languages** supported out of the box
- **Millisecond timing** for both compile and run phases
- **Detailed exit code reporting** — always know if your program succeeded
- **Binary cleanup prompt** — stay in control of compiled artifacts
- **`--keep` flag** — skip the delete prompt and keep the binary
- **`cr --del`** — bulk-delete all compiled binaries in the current directory
- **`cr --help`** — full usage reference + opens the online guide in your browser
- **Fast startup** — locale processing disabled for snappier invocation

---

## Installation

Pick your operating system. We won’t judge. Much.

### Linux/macOS

```bash
git clone https://github.com/Quillpy/Fastcc.git
cd Fastcc/linux
chmod +x install.sh
./install.sh
```

The installer places `cr` in `/usr/local/bin` (or `~/.local/bin` if you don't have root). It also scans your toolchain and roasts your missing compilers politely.

Verify:
```bash
cr --help
```

Manual install (you like danger):
```bash
chmod +x cr
sudo cp cr /usr/local/bin/cr
```

### Windows (PowerShell)

Open PowerShell and run:
```powershell
git clone https://github.com/Quillpy/Fastcc.git
cd Fastcc\windows
powershell -ExecutionPolicy Bypass -File .\install.ps1
```
This installs cr.ps1 and a handy cr.cmd shim so you can just type cr like a boss.

Verify:
```powershell
cr --help
```

---

## Quick Start

Your keyboard is about to get some PTO.

```bash
# C
cr main.c

# C++
cr app.cpp

# Java
cr Main.java

# Rust
cr game.rs

# Python
cr script.py

# Pass arguments to your program
cr main.c --verbose input.txt

# Keep the compiled binary (skip delete prompt)
cr --keep server.rs

# Delete all binaries in the current directory
cr --del
```

---

## Supported Languages

If it compiles, we compile it. If it interprets, we interpret it. If it makes coffee, please open a PR.

| Extension       | Compiler / Runtime | Type         |
|-----------------|-------------------|--------------|
| `.c`            | `gcc`             | Compiled     |
| `.cpp` `.cc` `.cxx` | `g++` (C++17) | Compiled  |
| `.java`         | `javac` + `java`  | Compiled     |
| `.rs`           | `rustc`           | Compiled     |
| `.go`           | `go run`          | Interpreted  |
| `.py`           | `python3`         | Interpreted  |
| `.js`           | `node`            | Interpreted  |
| `.ts`           | `ts-node`         | Interpreted  |
| `.sh`           | `bash`            | Interpreted  |
| `.rb`           | `ruby`            | Interpreted  |
| `.php`          | `php`             | Interpreted  |

---

## Example Output

It’s like a tiny, encouraging CI pipeline in your terminal.

```
  FastCR  ──────────────────────────────
  File  :  main.c
  Lang  :  .c
  ─────────────────────────────────

› Compiling with gcc…
✔ Compile successful  │  312ms

› Running main…
  ─────────────────────────────────
Hello, world!
  ─────────────────────────────────
✔ Run successful  │  exit code 0  │  4ms  ✓

  Delete compiled binary 'main'? [Y/n]
```

---

## Requirements

FastCR needs Bash 4+ on Linux/macOS or PowerShell 5.1+ (or pwsh 7+) on Windows. The language toolchains are on you.

FastCR itself only needs **Bash 4+**. The compilers and runtimes for the languages you want to use must be installed separately.

| Language | Required tool |
|----------|--------------|
| C        | `gcc`        |
| C++      | `g++`        |
| Java     | `javac`, `java` (JDK) |
| Rust     | `rustc`      |
| Go       | `go`         |
| Python   | `python3`    |
| JavaScript | `node`     |
| TypeScript | `ts-node`  |
| Shell    | `bash`       |
| Ruby     | `ruby`       |
| PHP      | `php`        |

If a required tool is missing, FastCR will tell you exactly which one and exit cleanly.

---

## Testing

- Linux/macOS:
  - Run: bash tests/run_tests.sh
  - This checks cr --help and cr --del behavior in a temp directory. Add more tests as your ambition grows.
- Windows:
  - Manually run a few commands in PowerShell: cr --help, cr --del, cr script.py, etc.

## Contributing

- Fork, branch, code, and open a PR.
- Keep the tone developer-friendly and the output helpful.
- If you add a new language, update both linux/cr and windows/cr.ps1, docs, and tests.

## Todo

- [ ] Clean codebase
- [ ] Remove unwanted lines
- [ ] Update documentation and README (meta!)
- [ ] Find and remove bugs
- [ ] Improve design consistency
- [ ] macOS-specific notes
- [ ] Expand tests

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">
  <sub>Made for developers who just want to run their code.</sub>
</div>

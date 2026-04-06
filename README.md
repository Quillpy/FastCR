# FastCR

A fast, minimal competitive programming tool for Linux.

```
cr solution.cpp
```

Detects your language, compiles, runs, and shows time + memory. No configuration needed.

---

## Install

```bash
git clone https://github.com/Quillpy/fastcr
cd fastcr
chmod +x install.sh
./install.sh
```

If `/usr/local/bin` is not writable, the installer uses `~/.local/bin` automatically.

---

## Usage

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

---

## Supported Languages

| Extension | Language | Compiler |
|-----------|----------|----------|
| `.c` | C | `gcc -O2` |
| `.cpp` `.cc` `.cxx` | C++ | `g++ -O2 -std=c++17` |
| `.java` | Java | `javac` |
| `.py` | Python 3 | `python3` (or `pypy3` if available) |
| `.rs` | Rust | `rustc -C opt-level=2` |
| `.go` | Go | `go build` |
| `.kt` | Kotlin | `kotlinc` |
| `.js` | JavaScript | `node` |
| `.rb` | Ruby | `ruby` |
| `.hs` | Haskell | `ghc -O2` |

---

## Batch Testing

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

## Examples

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
```

---

## Watch Mode

Requires `inotify-tools`:
```bash
sudo apt install inotify-tools
```

---

## Uninstall

```bash
rm ~/.local/bin/cr
# or
sudo rm /usr/local/bin/cr
```

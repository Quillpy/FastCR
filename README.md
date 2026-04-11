# FastCR ⚡ (BETA)

*A fast, minimal, no-nonsense (okay maybe a little nonsense) **Linux-only** competitive programming tool.*

```bash
cr solution.cpp
```

Because typing `g++ solution.cpp -O2 -std=c++17 && ./a.out` repeatedly builds character... but wastes time.

---

## Why FastCR?

FastCR exists so you can:

- Compile faster 🚀
- Test faster 🧪
- Debug faster 🐛
- And still lose to someone who wrote the solution in Python in 6 lines 😄

But at least **you'll lose efficiently**.

---

## Features

- Auto-detects language (10+ supported)
- Compiles & runs with time/memory limits
- Batch testing with `test*.txt` / `test*.out`
- Watch mode (because saving files manually is too mainstream)
- New file boilerplate generator
- Clipboard copy support
- Zero config required

Install → run → solve → AC → celebrate.

(Or debug for 40 minutes. Also normal.)

---

## Quick Install (Local Repo)

```bash
cd /path/to/FastCR/linux
chmod +x install.sh
./install.sh
```

Installer places `cr` in:

- `/usr/local/bin` (requires sudo)

OR

- `~/.local/bin` + updates PATH automatically

FastCR believes in freedom of choice.

Unlike your WA verdict.

---

## Build From Source (No Install)

```bash
cd linux
gcc -O2 -o meminfo src/meminfo.c
cp cr.sh meminfo ./
```

Run locally:

```bash
./cr solution.cpp
```

Minimal effort. Maximum productivity. Slightly increased ego.

---

## Usage

```bash
cr [flags] <file>
```

---

## Flags

| Flag | Description |
|------|-------------|
| `--t` | Use `input.txt` as stdin |
| `--i <file>` | Custom input file |
| `--o <file>` | Output to file |
| `--e <file>` | Compare vs expected output |
| `--b` | Batch test all `test*.txt` |
| `--d` | Debug build (sanitizers enabled) |
| `--tl <ms>` | Time limit (default 2000ms) |
| `--ml <MB>` | Memory limit (default 256MB) |
| `--v` | Verbose compile output |
| `--tm` | Show last run stats |
| `--n <file>` | Generate boilerplate file |
| `--w` | Watch mode |
| `--cp` | Copy source to clipboard |
| `--del <file>` / `--del *` | Cleanup binaries |

Basically everything you need during contests except extra time.

---

## Supported Languages

| Extension | Language | Compiler / Runner |
|-----------|----------|------------------|
| `.c` | C | `gcc -O2` |
| `.cpp` / `.cc` / `.cxx` | C++17 | `g++ -O2` |
| `.py` | Python3 / PyPy | `python3` |
| `.java` | Java | `javac + java` |
| `.rs` | Rust | `rustc -O` |
| `.go` | Go | `go build` |
| `.kt` | Kotlin | `kotlinc` |
| `.js` | Node.js | `node` |
| `.rb` | Ruby | `ruby` |
| `.hs` | Haskell | `ghc -O2` |

More languages coming soon™ (after the next contest maybe).

---

## Batch Testing

Example structure:

```
test1.txt
test1.out

test2.txt
```

Run:

```bash
cr --b solution.cpp --tl 1000
```

Sample output:

```
Batch Tests
--------------------------------------------------
  test1.txt     AC    34 ms   1.2 MB
  test2.txt     WA    28 ms   1.1 MB
  test3.txt     TLE 2000+ ms   -- MB
--------------------------------------------------
  Passed: 1   Failed: 2
```

Verdicts supported:

- AC
- WA
- TLE
- RTE
- RAN (ran successfully but no expected output)

Yes, FastCR judges your code faster than your contest platform does.

---

## Examples

```bash
cr solution.cpp
cr --t solution.cpp
cr --i in.txt --e out.txt sol.cpp
cr --b sol.cpp
cr --d sol.cpp
cr --n prob.cpp
cr --w --t sol.py
cr --del *
```

Pro tip:

`--b` before submission saves lives.

---

## Watch Mode

Install dependency:

```bash
sudo apt install inotify-tools
```

Run:

```bash
cr --w solution.cpp
```

Now FastCR watches your file like a strict contest judge watching for hacks.

---

## Uninstall

Check install location:

```bash
which cr
```

If installed globally:

```bash
sudo rm /usr/local/bin/{cr,meminfo}
```

If installed locally:

```bash
rm ~/.local/bin/{cr,meminfo}
```

FastCR will leave silently.

Unlike runtime errors.

---

## Troubleshooting

| Issue | Fix |
|------|-----|
| `cr: command not found` | Run `source ~/.bashrc` |
| Watch mode fails | Install `inotify-tools` |
| Permission denied | Use `~/.local/bin` |
| Java/Kotlin leftovers | `cr --del *` |

Dependencies:

- gcc
- g++
- language runtimes

Optional:

- inotify-tools
- xclip or xsel

---

## Contributors 👨‍💻

Big thanks to the legends who helped make FastCR faster:

- [**Shubham**](https://github.com/Quillpy) — Creator and maintainer
- [**Tacoblude**](https://github.com/Tacoblude) — Contributor and bug hunter  
- [**Cloude Code**](https://github.com/anthropics/claude-code) — Contributor, automation enhancer and script writer

Want your name here too?
Break something. Fix something. Improve something.
Open a PR.

---

## License

MIT License © 2024 Shubham

Use it.
Fork it.
Win contests with it.
(Or at least compile faster with it.)

---

## Development / Contributing

Project structure:

```
linux/
 ├── cr.sh
 ├── meminfo.c
 └── install.sh

test/
```

Ways to contribute:

- Add integration tests
- Extend language support
- Improve memory limit handling
- Improve signal handling
- Optimize compilation flow
- Add more speed (always welcome)

No GitHub repo yet.

Yes, this is your sign to create one 😄

---

## Final Motivation

Fast compile.
Fast test.
Fast debug.

Slowly reach AC.
One verdict at a time.

⚡ Happy coding.


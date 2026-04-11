# FastCR ⚡ (BETA)

*A fast, minimal, no-nonsense (okay maybe a little nonsense) **Linux-only** competitive programming tool.*

```bash
cr solution.cpp
```

Because typing `g++ solution.cpp -O2 -std=c++17 && ./a.out` repeatedly builds character... but wastes time.

---

## Why FastCR?

![logo](./logo.png)

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
- Template-based file creation
- Clipboard copy support
- Config file support for customization
- Zero config required (works out of the box)

Install → run → solve → AC → celebrate.

(Or debug for 40 minutes. Also normal.)

---

## Quick Install

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
chmod +x cr.sh
```

Run locally:

```bash
./cr.sh solution.cpp
```

Or create an alias:

```bash
alias cr="/path/to/FastCR/linux/cr.sh"
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
| `--config <action>` | Config file: create, edit, show |
| `--uninstall` | Uninstall FastCR |
| `--template <file>` | Create file from template |
| `--help` / `-h` | Show help message |
| `--version` | Show version info |

Basically everything you need during contests except extra time.

---

## Config File

FastCR supports a config file to set default values for flags.

**Location:** `~/.config/fastcr/config.conf`

### Create config file:
```bash
cr --config create
```

### Edit config file:
```bash
cr --config edit
```

### Show config file:
```bash
cr --config show
```

### Config options:
```bash
# Time limit in milliseconds (default: 2000)
TL=2000

# Memory limit in MB (default: 256)
ML=256

# Verbose compile output (0 or 1)
VERBOSE=0

# Show timing stats (0 or 1)
TM=0

# Debug mode with sanitizers (0 or 1)
DEBUG=0

# Default input file
INPUT_FILE=

# Default expected output file
EXPECTED_FILE=

# Default output file
OUTPUT_FILE=

# Batch test mode (0 or 1)
BATCH=0

# Watch mode (0 or 1)
WATCH=0
```

Command-line flags override config file values.

---

## Templates

FastCR can create new files from templates located in `linux/Templates/`.

### Add templates:
Place template files with naming convention `main.<ext>`:
- `main.cpp` - C++ template
- `main.py` - Python template
- `main.c` - C template
- etc.

### Use template:
```bash
cr --template newfile.cpp
```

This creates `newfile.cpp` using the `main.cpp` template.

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
cr --config edit
cr --template newfile.cpp
cr --uninstall
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

### Recommended (using built-in flag):
```bash
cr --uninstall
```

This will detect your installation location and guide you through uninstallation.

### Manual uninstall:

Check install location:
```bash
which cr
```

If installed globally:
```bash
sudo rm /usr/local/bin/{cr,meminfo,Templates}
```

If installed locally:
```bash
rm -rf ~/.local/bin/{cr,meminfo,Templates} ~/.config/fastcr
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
| Config not loading | Check `~/.config/fastcr/config.conf` exists |

### Dependencies:

- gcc
- g++
- language runtimes

### Optional:

- inotify-tools (for watch mode)
- xclip or xsel (for clipboard)
- nano/vim/vscode (for config editing)

---

## Project Structure

```
FastCR/
├── README.md
├── linux/
│   ├── cr.sh           # Main script
│   ├── install.sh       # Installer
│   ├── Templates/       # File templates
│   │   └── main.cpp     # C++ template
│   └── src/
│       └── meminfo.c    # Memory info utility
```

---

## License

MIT License © 2024 Shubham

Use it.
Fork it.
Win contests with it.
(Or at least compile faster with it.)

---

## Final Motivation

Fast compile.
Fast test.
Fast debug.

Slowly reach AC.
One verdict at a time.

⚡ Happy coding.
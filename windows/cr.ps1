# ══════════════════════════════════════════════════════════════
#  FastCR  –  Compile & Run in one command  (Windows / PowerShell)
#  Usage : cr <file> [args...]
#          cr --del
#          cr --help
#  Docs  : https://github.com/Quillpy/Fastcc
# ══════════════════════════════════════════════════════════════

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Input = "",

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$ExtraArgs = @(),

    [switch]$Keep,
    [switch]$Del,
    [switch]$Help,
    [switch]$Bench
)

# ══════════════════════════════════════════════════════════════
#  Colour helpers  (works on Windows Terminal, VS Code, pwsh 7+)
# ══════════════════════════════════════════════════════════════
function Write-Cr {
    param(
        [string]$Text,
        [string]$Prefix   = "",
        [ConsoleColor]$PrefixColor = "White",
        [ConsoleColor]$TextColor   = "White",
        [switch]$NoNewline
    )
    if ($Prefix) {
        Write-Host "  " -NoNewline
        Write-Host $Prefix -ForegroundColor $PrefixColor -NoNewline
        Write-Host "  " -NoNewline
    } else {
        Write-Host "  " -NoNewline
    }
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $TextColor -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $TextColor
    }
}

function Write-Info    ([string]$msg) { Write-Cr $msg -Prefix ">" -PrefixColor Cyan  -TextColor White }
function Write-Success ([string]$msg) { Write-Cr $msg -Prefix "v" -PrefixColor Green -TextColor Green }
function Write-Warn    ([string]$msg) { Write-Cr $msg -Prefix "!" -PrefixColor Yellow -TextColor Yellow }
function Write-Step    ([string]$msg) { Write-Cr $msg -Prefix ">" -PrefixColor Blue  -TextColor White }
function Write-Dim     ([string]$msg) { Write-Cr $msg -Prefix ""  -TextColor DarkGray }
function Write-Div                    { Write-Host "  " -NoNewline; Write-Host ("─" * 49) -ForegroundColor DarkGray }

function Write-CrError ([string]$msg) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "x  ERROR:  " -ForegroundColor Red -NoNewline
    Write-Host $msg -ForegroundColor White
    Write-Host ""
    exit 1
}

# ══════════════════════════════════════════════════════════════
#  Millisecond timer
# ══════════════════════════════════════════════════════════════
$script:_T0 = [System.Diagnostics.Stopwatch]::new()

function Start-CrTimer { $script:_T0.Restart() }
function Get-CrElapsed { return [math]::Round($script:_T0.Elapsed.TotalMilliseconds) }

# ══════════════════════════════════════════════════════════════
#  Check if a command exists
# ══════════════════════════════════════════════════════════════
function Assert-Tool ([string]$tool) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-CrError "'$tool' is not installed or not on PATH. Please install it and retry."
    }
}

# ══════════════════════════════════════════════════════════════
#  Print run result
# ══════════════════════════════════════════════════════════════
function Write-RunResult ([int]$code, [long]$ms) {
    Write-Div
    if ($code -eq 0) {
        Write-Host "  " -NoNewline
        Write-Host "v" -ForegroundColor Green -NoNewline
        Write-Host "  Run successful  " -ForegroundColor Green -NoNewline
        Write-Host "|  exit code 0  |  ${ms}ms  " -ForegroundColor DarkGray -NoNewline
        Write-Host "v" -ForegroundColor Green
    } else {
        Write-Host "  " -NoNewline
        Write-Host "!" -ForegroundColor Yellow -NoNewline
        Write-Host "  Run finished with errors  " -ForegroundColor Yellow -NoNewline
        Write-Host "|  exit code $code  |  ${ms}ms" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════
#  Ask to delete binary
# ══════════════════════════════════════════════════════════════
function Invoke-MaybeDelete ([string]$binPath) {
    if (-not (Test-Path $binPath)) { return }

    if ($Keep) {
        Write-Info "Binary kept (--keep flag):  $binPath"
        Write-Host ""
        return
    }

    $name = Split-Path $binPath -Leaf
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "  Delete compiled binary '$name'? [Y/n]  " -ForegroundColor Yellow -NoNewline
    $ans = Read-Host
    Write-Host ""

    if ($ans -match '^[Nn]') {
        Write-Info "Binary kept:  $binPath"
    } else {
        Remove-Item -Force $binPath -ErrorAction SilentlyContinue
        Write-Success "Binary deleted."
    }
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════
#  --help
# ══════════════════════════════════════════════════════════════
function Show-Usage {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "FastCR" -ForegroundColor Cyan -NoNewline
    Write-Host "  -  Compile & Run in one command" -ForegroundColor White
    Write-Dim   "  Full guide -> https://github.com/Quillpy/Fastcc"
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Usage" -ForegroundColor White
    Write-Dim   "    cr <file> [args...]   compile (if needed) and run"
    Write-Dim   "    cr --del              delete all .exe binaries in current dir"
    Write-Dim   "    cr --keep <file>      run but keep the binary afterwards"
    Write-Dim   "    cr --bench <file>     benchmark compile/run time and memory (C/C++/Rust)"
    Write-Dim   "    cr --help             show this help"
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Supported languages" -ForegroundColor White
    $langs = @(
        @(".c",         "gcc            (compiled)"),
        @(".cpp / .cc", "g++ C++17      (compiled)"),
        @(".java",      "javac + java   (compiled)"),
        @(".rs",        "rustc          (compiled)"),
        @(".go",        "go run         (interpreted)"),
        @(".py",        "python         (interpreted)"),
        @(".js",        "node           (interpreted)"),
        @(".ts",        "ts-node        (interpreted)"),
        @(".ps1",       "powershell     (interpreted)"),
        @(".rb",        "ruby           (interpreted)"),
        @(".php",       "php            (interpreted)")
    )
    foreach ($l in $langs) {
        Write-Host "    " -NoNewline
        Write-Host ("{0,-16}" -f $l[0]) -ForegroundColor Cyan -NoNewline
        Write-Host $l[1] -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Flags" -ForegroundColor White
    Write-Host "    " -NoNewline; Write-Host "--keep" -ForegroundColor Green -NoNewline
    Write-Host "   keep the compiled binary after running"
    Write-Host "    " -NoNewline; Write-Host "--del " -ForegroundColor Green -NoNewline
    Write-Host "   delete all .exe files in the current directory"
    Write-Host "    " -NoNewline; Write-Host "--bench" -ForegroundColor Green -NoNewline
    Write-Host "   benchmark compile/run time and memory (C/C++/Rust)"
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Examples" -ForegroundColor White
    Write-Dim   "    cr main.c"
    Write-Dim   "    cr app.py --verbose"
    Write-Dim   "    cr Main.java arg1 arg2"
    Write-Dim   "    cr --keep server.rs"
    Write-Dim   "    cr --del"
    Write-Host ""

    # Best-effort open browser
    try { Start-Process "https://github.com/Quillpy/Fastcc" } catch {}
    exit 0
}

# ══════════════════════════════════════════════════════════════
#  --del : remove .exe binaries in current directory
# ══════════════════════════════════════════════════════════════
function Invoke-DelBinaries {
    Write-Host ""
    Write-Info "Scanning  $(Get-Location)  for compiled binaries..."
    Write-Host ""

    # On Windows, compiled outputs are .exe files
    $found = @(Get-ChildItem -Path "." -MaxDepth 1 -Filter "*.exe" -File -ErrorAction SilentlyContinue)

    if ($found.Count -eq 0) {
        Write-Warn "No compiled .exe binaries found in current directory."
        Write-Host ""
        exit 0
    }

    Write-Host "  " -NoNewline
    Write-Host "Found $($found.Count) binary/binaries:" -ForegroundColor White
    foreach ($f in $found) {
        $size = "{0:N0} KB" -f ($f.Length / 1KB)
        Write-Host "    " -NoNewline
        Write-Host "-" -ForegroundColor Red -NoNewline
        Write-Host "  $($f.Name)" -NoNewline
        Write-Host "  ($size)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "  Delete all $($found.Count) file(s)? [y/N]  " -ForegroundColor Yellow -NoNewline
    $ans = Read-Host
    Write-Host ""

    if ($ans -match '^[Yy]') {
        foreach ($f in $found) { Remove-Item -Force $f.FullName -ErrorAction SilentlyContinue }
        Write-Success "Deleted $($found.Count) binary/binaries."
    } else {
        Write-Info "Aborted. Nothing deleted."
    }
    Write-Host ""
    exit 0
}

# ══════════════════════════════════════════════════════════════
#  Compiled language runner
# ══════════════════════════════════════════════════════════════
function Invoke-Compiled {
    param(
        [string]   $Compiler,
        [string[]] $Flags,
        [string]   $SourceFile,
        [string]   $OutBin,
        [string[]] $RunArgs
    )

    Assert-Tool $Compiler

    Write-Step "Compiling with $Compiler..."
    Start-CrTimer

    $compileArgs = $Flags + @("-o", $OutBin, $SourceFile)
    & $Compiler @compileArgs 2>&1
    $compileExit = $LASTEXITCODE

    $ms = Get-CrElapsed

    if ($compileExit -ne 0) {
        Write-Host ""
        Write-CrError "Compilation failed. Fix the errors above and retry."
    }

    Write-Host "  " -NoNewline
    Write-Host "v" -ForegroundColor Green -NoNewline
    Write-Host "  Compile successful  " -ForegroundColor Green -NoNewline
    Write-Host "|  ${ms}ms" -ForegroundColor DarkGray
    Write-Host ""

    $binName = Split-Path $OutBin -Leaf
    Write-Step "Running $binName..."
    Write-Div
    Start-CrTimer

    & $OutBin @RunArgs
    $runExit = $LASTEXITCODE
    $ms = Get-CrElapsed

    Write-RunResult $runExit $ms
    Invoke-MaybeDelete $OutBin
    exit $runExit
}

# Benchmark for compiled languages (C/C++/Rust)
function Invoke-CompiledBench {
    param(
        [string]   $Compiler,
        [string[]] $Flags,
        [string]   $SourceFile,
        [string]   $OutBin,
        [string[]] $RunArgs
    )

    Assert-Tool $Compiler

    # Compile timing
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $compileArgs = $Flags + @("-o", $OutBin, $SourceFile)
    & $Compiler @compileArgs 2>&1
    $compileExit = $LASTEXITCODE
    $sw.Stop()
    $compileMs = [math]::Round($sw.Elapsed.TotalMilliseconds)
    if ($compileExit -ne 0) {
        Write-CrError "Compilation failed. Fix the errors above and retry."
    }

    # Run timing + memory
    $outTmp = [System.IO.Path]::GetTempFileName()
    $errTmp = [System.IO.Path]::GetTempFileName()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $p = Start-Process -FilePath $OutBin -ArgumentList $RunArgs -PassThru -Wait -RedirectStandardOutput $outTmp -RedirectStandardError $errTmp
    $sw.Stop()
    $runMs = [math]::Round($sw.Elapsed.TotalMilliseconds)
    $runExit = $p.ExitCode
    $peak = $p.PeakWorkingSet64  # bytes
    Remove-Item -Force $outTmp,$errTmp -ErrorAction SilentlyContinue

    if (-not $keepBin) { Remove-Item -Force $OutBin -ErrorAction SilentlyContinue }

    # Print results
    $cSec = [string]::Format("{0:N2}", ($compileMs/1000.0))
    $rSec = [string]::Format("{0:N2}", ($runMs/1000.0))
    Write-Host "Compile time: ${cSec}s" 
    Write-Host "Runtime: ${rSec}s"
    if ($peak -gt 0) {
        $memMB = [int][math]::Round($peak / 1MB)
        if ($memMB -lt 1) {
            $memKB = [int][math]::Round($peak / 1KB)
            Write-Host "Memory usage: ${memKB}KB"
        } else {
            Write-Host "Memory usage: ${memMB}MB"
        }
    }

    exit $runExit
}

# ══════════════════════════════════════════════════════════════
#  Interpreted language runner
# ══════════════════════════════════════════════════════════════
function Invoke-Interpreted {
    param(
        [string]   $Runtime,
        [string[]] $RuntimeFlags = @(),
        [string]   $SourceFile,
        [string[]] $RunArgs
    )

    Assert-Tool $Runtime

    Write-Step "Running with $Runtime..."
    Write-Div
    Start-CrTimer

    & $Runtime @RuntimeFlags $SourceFile @RunArgs
    $runExit = $LASTEXITCODE
    $ms = Get-CrElapsed

    Write-RunResult $runExit $ms
    exit $runExit
}

# ══════════════════════════════════════════════════════════════
#  Argument routing
# ══════════════════════════════════════════════════════════════
if ($Help -or ($Input -eq "--help") -or ($Input -eq "-h") -or ($Input -eq "")) {
    Show-Usage
}

if ($Del -or $Input -eq "--del") {
    Invoke-DelBinaries
}

# --keep flag can come as first positional on Windows too
$keepBin = $Keep
$sourceFile = $Input

if ($sourceFile -eq "--keep") {
    $keepBin = $true
    if ($ExtraArgs.Count -eq 0) { Show-Usage }
    $sourceFile   = $ExtraArgs[0]
    $ExtraArgs    = $ExtraArgs[1..($ExtraArgs.Count - 1)]
}

# Support --bench as first positional too
$doBench = $Bench
if ($sourceFile -eq "--bench") {
    $doBench = $true
    if ($ExtraArgs.Count -eq 0) { Show-Usage }
    $sourceFile   = $ExtraArgs[0]
    $ExtraArgs    = $ExtraArgs[1..($ExtraArgs.Count - 1)]
}

if (-not (Test-Path $sourceFile)) {
    Write-CrError "File not found: '$sourceFile'"
}

# ── Extract parts ─────────────────────────────────────────────
$baseName  = Split-Path $sourceFile -Leaf
$ext       = ($baseName -split '\.')[-1].ToLower()
$name      = [System.IO.Path]::GetFileNameWithoutExtension($baseName)
$dir       = (Resolve-Path (Split-Path $sourceFile -Parent)).Path
$outBin    = Join-Path $dir "$name.exe"

# ── Print header ──────────────────────────────────────────────
Write-Host ""
Write-Host "  " -NoNewline
Write-Host "FastCR" -ForegroundColor Cyan -NoNewline
Write-Host "  " -NoNewline
Write-Host ("─" * 32) -ForegroundColor DarkGray
Write-Host "  " -NoNewline
Write-Host "File  :  " -ForegroundColor DarkGray -NoNewline
Write-Host $sourceFile -ForegroundColor White
Write-Host "  " -NoNewline
Write-Host "Lang  :  " -ForegroundColor DarkGray -NoNewline
Write-Host ".$ext" -ForegroundColor White
Write-Div
Write-Host ""

# ══════════════════════════════════════════════════════════════
#  Language dispatch
# ══════════════════════════════════════════════════════════════
switch ($ext) {

    "c" {
        if ($doBench) {
            Invoke-CompiledBench -Compiler "gcc" `
                                 -Flags @("-Wall", "-Wextra", "-O2") `
                                 -SourceFile $sourceFile `
                                 -OutBin $outBin `
                                 -RunArgs $ExtraArgs
        } else {
            Invoke-Compiled -Compiler "gcc" `
                            -Flags @("-Wall", "-Wextra", "-O2") `
                            -SourceFile $sourceFile `
                            -OutBin $outBin `
                            -RunArgs $ExtraArgs
        }
    }

    { $_ -in "cpp","cc","cxx" } {
        if ($doBench) {
            Invoke-CompiledBench -Compiler "g++" `
                                 -Flags @("-Wall", "-Wextra", "-O2", "-std=c++17") `
                                 -SourceFile $sourceFile `
                                 -OutBin $outBin `
                                 -RunArgs $ExtraArgs
        } else {
            Invoke-Compiled -Compiler "g++" `
                            -Flags @("-Wall", "-Wextra", "-O2", "-std=c++17") `
                            -SourceFile $sourceFile `
                            -OutBin $outBin `
                            -RunArgs $ExtraArgs
        }
    }

    "java" {
        Assert-Tool "javac"
        Assert-Tool "java"

        Write-Step "Compiling with javac..."
        Start-CrTimer
        & javac -d $dir $sourceFile 2>&1
        $compileExit = $LASTEXITCODE
        $ms = Get-CrElapsed

        if ($compileExit -ne 0) {
            Write-Host ""
            Write-CrError "Compilation failed. Fix the errors above and retry."
        }

        Write-Host "  " -NoNewline
        Write-Host "v" -ForegroundColor Green -NoNewline
        Write-Host "  Compile successful  " -ForegroundColor Green -NoNewline
        Write-Host "|  ${ms}ms" -ForegroundColor DarkGray
        Write-Host ""

        Write-Step "Running $name with java..."
        Write-Div
        Start-CrTimer
        & java -cp $dir $name @ExtraArgs
        $runExit = $LASTEXITCODE
        $ms = Get-CrElapsed
        Write-RunResult $runExit $ms

        $classFile = Join-Path $dir "$name.class"
        if (Test-Path $classFile) {
            if ($keepBin) {
                Write-Info "Class file kept (--keep):  $classFile"
                Write-Host ""
            } else {
                Write-Host "  " -NoNewline
                Write-Host "  Delete compiled '$name.class'? [Y/n]  " -ForegroundColor Yellow -NoNewline
                $ans = Read-Host
                Write-Host ""
                if ($ans -match '^[Nn]') {
                    Write-Info "Class file kept:  $classFile"
                } else {
                    Remove-Item -Force $classFile -ErrorAction SilentlyContinue
                    Write-Success "Class file deleted."
                }
                Write-Host ""
            }
        }
        exit $runExit
    }

    "rs" {
        if ($doBench) {
            Invoke-CompiledBench -Compiler "rustc" `
                                 -Flags @() `
                                 -SourceFile $sourceFile `
                                 -OutBin $outBin `
                                 -RunArgs $ExtraArgs
        } else {
            Invoke-Compiled -Compiler "rustc" `
                            -Flags @() `
                            -SourceFile $sourceFile `
                            -OutBin $outBin `
                            -RunArgs $ExtraArgs
        }
    }

    "go" {
        Invoke-Interpreted -Runtime "go" `
                           -RuntimeFlags @("run") `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    "py" {
        # Try python first, then python3 (both exist on Windows)
        $pyCmd = if (Get-Command "python"  -ErrorAction SilentlyContinue) { "python"  } `
            elseif (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" } `
            else { Write-CrError "'python' / 'python3' is not installed or not on PATH." }

        Invoke-Interpreted -Runtime $pyCmd `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    "js" {
        Invoke-Interpreted -Runtime "node" `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    "ts" {
        Invoke-Interpreted -Runtime "ts-node" `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    "ps1" {
        Invoke-Interpreted -Runtime "powershell" `
                           -RuntimeFlags @("-ExecutionPolicy", "Bypass", "-File") `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    "rb" {
        Invoke-Interpreted -Runtime "ruby" `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    "php" {
        Invoke-Interpreted -Runtime "php" `
                           -SourceFile $sourceFile `
                           -RunArgs $ExtraArgs
    }

    default {
        Write-CrError "Unsupported extension '.$ext'`nRun  cr --help  to see all supported languages."
    }
}

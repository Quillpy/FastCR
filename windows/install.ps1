# ══════════════════════════════════════════════════════════════
#  FastCR Windows Installer
#  Sets up the `cr` command globally via PowerShell
#  https://github.com/Quillpy/Fastcc
# ══════════════════════════════════════════════════════════════

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Force   # skip all prompts, use defaults
)

# ── Colour helpers ────────────────────────────────────────────
function p  ([string]$t, [string]$c="White", [switch]$nn) {
    Write-Host "  $t" -ForegroundColor $c -NoNewline:$nn
}
function nl { Write-Host "" }
function Write-Info    ([string]$m) { Write-Host "  " -NoNewline; Write-Host ">" -ForegroundColor Cyan   -NoNewline; Write-Host "  $m" }
function Write-Success ([string]$m) { Write-Host "  " -NoNewline; Write-Host "v" -ForegroundColor Green  -NoNewline; Write-Host "  $m" -ForegroundColor Green }
function Write-Warn    ([string]$m) { Write-Host "  " -NoNewline; Write-Host "!" -ForegroundColor Yellow -NoNewline; Write-Host "  $m" -ForegroundColor Yellow }
function Write-Step    ([string]$m) { nl; Write-Host "  " -NoNewline; Write-Host ">" -ForegroundColor Blue   -NoNewline; Write-Host "  " -NoNewline; Write-Host $m -ForegroundColor White }
function Write-Dim     ([string]$m) { Write-Host "  $m" -ForegroundColor DarkGray }
function Write-Div     { Write-Host "  " -NoNewline; Write-Host ("─" * 50) -ForegroundColor DarkGray }
function Write-BigDiv  { Write-Host "  " -NoNewline; Write-Host ("═" * 50) -ForegroundColor Blue }

function Write-Err ([string]$m) {
    nl
    Write-Host "  " -NoNewline
    Write-Host "x  ERROR:  " -ForegroundColor Red -NoNewline
    Write-Host $m -ForegroundColor White
    nl
    exit 1
}

# ── Progress bar ─────────────────────────────────────────────
function Show-Progress ([string]$label, [int]$steps = 20) {
    Write-Host "  " -NoNewline
    Write-Host ("> " + ("{0,-32}" -f $label) + "  [") -NoNewline
    for ($i = 0; $i -lt $steps; $i++) {
        Write-Host "-" -ForegroundColor Green -NoNewline
        Start-Sleep -Milliseconds 25
    }
    Write-Host "]  " -NoNewline
    Write-Host "done" -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────
#  BANNER
# ─────────────────────────────────────────────────────────────
Clear-Host
nl
Write-Host "  " -NoNewline; Write-Host "███████╗ █████╗ ███████╗████████╗ ██████╗██████╗ " -ForegroundColor Blue
Write-Host "  " -NoNewline; Write-Host "██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗" -ForegroundColor Blue
Write-Host "  " -NoNewline; Write-Host "█████╗  ███████║███████╗   ██║   ██║     ██████╔╝" -ForegroundColor Blue
Write-Host "  " -NoNewline; Write-Host "██╔══╝  ██╔══██║╚════██║   ██║   ██║     ██╔══██╗" -ForegroundColor Blue
Write-Host "  " -NoNewline; Write-Host "██║     ██║  ██║███████║   ██║   ╚██████╗██║  ██║" -ForegroundColor Blue
Write-Host "  " -NoNewline; Write-Host "╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝" -ForegroundColor Blue
nl
Write-Host "  " -NoNewline; Write-Host "Compile & Run in one command.  (Windows Edition)" -ForegroundColor Cyan
Write-Dim   "  Turning your PowerShell into a one-stop code execution shop."
Write-Dim   "  Yes, this works on Windows. No, we're not as surprised as you are."
nl
Write-BigDiv
nl

Start-Sleep -Milliseconds 400

# ─────────────────────────────────────────────────────────────
#  FIND cr.ps1 NEXT TO THIS INSTALLER
# ─────────────────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CrSrc     = Join-Path $ScriptDir "cr.ps1"

if (-not (Test-Path $CrSrc)) {
    Write-Err "Cannot find 'cr.ps1' next to this installer.`n  Expected:  $CrSrc`n  Keep install.ps1 and cr.ps1 in the same folder."
}

# ─────────────────────────────────────────────────────────────
#  STEP 1 — CHOOSE INSTALL LOCATION
# ─────────────────────────────────────────────────────────────
Write-Step "Step 1 / 4  -  Choosing install location"
nl

# Options (in priority order):
#   A) C:\Windows\System32  (system-wide, needs admin)  -- too invasive, skip
#   B) C:\Users\<user>\AppData\Local\Microsoft\WindowsApps  (user PATH, no admin)
#   C) C:\Users\<user>\.local\bin  (manual, needs PATH patch)

$WinAppsDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
$LocalBin   = "$env:USERPROFILE\.local\bin"

$Dest         = ""
$NeedsPathFix = $false

if (Test-Path $WinAppsDir) {
    $Dest = $WinAppsDir
    Write-Info "Found WindowsApps folder - no admin needed. Living dangerously, I see."
} else {
    $Dest = $LocalBin
    if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Force -Path $Dest | Out-Null }
    $NeedsPathFix = $true
    Write-Info "Using $Dest  (humble but effective)"
}

$CrDest     = Join-Path $Dest "cr.ps1"
# We also drop a tiny .cmd shim so you can type  cr  without .ps1
$ShimDest   = Join-Path $Dest "cr.cmd"

Write-Success "Destination:  $Dest"
nl

# ─────────────────────────────────────────────────────────────
#  STEP 2 — COPY FILES
# ─────────────────────────────────────────────────────────────
Write-Step "Step 2 / 4  -  Installing cr.ps1 + cr.cmd shim"
nl

Write-Info "Copying cr.ps1..."
try {
    Copy-Item -Force $CrSrc $CrDest
} catch {
    Write-Err "Failed to copy cr.ps1 to $CrDest`n$($_.Exception.Message)"
}

# Create a .cmd shim so the user can just type  cr  in any terminal
$ShimContent = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0cr.ps1" %*
"@

try {
    Set-Content -Path $ShimDest -Value $ShimContent -Encoding ASCII
} catch {
    Write-Warn "Could not write cr.cmd shim: $($_.Exception.Message)"
    Write-Warn "You can still run cr with:  powershell -File cr.ps1 <file>"
}

Show-Progress "Installing files" 20
Write-Success "Installed to  $Dest"
nl

# ─────────────────────────────────────────────────────────────
#  STEP 3 — EXECUTION POLICY CHECK
# ─────────────────────────────────────────────────────────────
Write-Step "Step 3 / 4  -  Checking PowerShell execution policy"
nl

$policy = Get-ExecutionPolicy -Scope CurrentUser
Write-Info "Current user policy:  $policy"

if ($policy -in @("Restricted", "AllSigned")) {
    Write-Warn "Execution policy '$policy' will block cr.ps1 from running."
    Write-Info "Setting policy to RemoteSigned for current user..."
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Success "Policy set to RemoteSigned.  Scripts you write will run fine."
    } catch {
        Write-Warn "Couldn't set policy automatically."
        Write-Warn "Run this manually in PowerShell (as admin if needed):"
        nl
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned" -ForegroundColor White
        nl
    }
} else {
    Write-Success "Execution policy is '$policy' - cr.ps1 will run without drama."
}
nl

# ─────────────────────────────────────────────────────────────
#  STEP 4 — PATH SETUP + VERIFY
# ─────────────────────────────────────────────────────────────
Write-Step "Step 4 / 4  -  Verifying PATH and installation"
nl

# Check if Dest is already on the user PATH
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$pathDirs  = $userPath -split ";" | ForEach-Object { $_.Trim() }

if ($Dest -notin $pathDirs) {
    Write-Warn "$Dest is not on your PATH."
    Write-Info "Adding it now (user scope, no admin needed)..."
    $newPath = ($userPath.TrimEnd(";") + ";" + $Dest)
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    # Also patch current session
    $env:PATH = $env:PATH + ";" + $Dest
    Write-Success "PATH updated.  Open a new terminal to pick up the change."
} else {
    Write-Success "PATH already includes $Dest  - you're golden."
}

nl
Show-Progress "Running sanity check" 15

if (Test-Path $CrDest) {
    Write-Success "cr.ps1 is in place.  v"
} else {
    Write-Err "Something went wrong - cr.ps1 not found at $CrDest  Very mysterious."
}

if (Test-Path $ShimDest) {
    Write-Success "cr.cmd shim is in place.  Just type  cr  in any terminal."
} else {
    Write-Warn "cr.cmd shim missing - you'll need to type  cr.ps1  explicitly."
}
nl

# ─────────────────────────────────────────────────────────────
#  RUNTIME SCANNER
# ─────────────────────────────────────────────────────────────
Write-BigDiv
nl
Write-Host "  " -NoNewline; Write-Host "Scanning for language runtimes on your system..." -ForegroundColor Magenta
Write-Dim   "  (Let's see what you've actually installed)"
nl

$tools = @(
    @{ cmd="gcc";      lang="C" },
    @{ cmd="g++";      lang="C++" },
    @{ cmd="javac";    lang="Java (compiler)" },
    @{ cmd="java";     lang="Java (runtime)" },
    @{ cmd="rustc";    lang="Rust" },
    @{ cmd="go";       lang="Go" },
    @{ cmd="python";   lang="Python" },
    @{ cmd="node";     lang="JavaScript" },
    @{ cmd="ts-node";  lang="TypeScript" },
    @{ cmd="ruby";     lang="Ruby" },
    @{ cmd="php";      lang="PHP" }
)

$found   = 0
$missing = 0

foreach ($t in $tools) {
    $cmd  = $t.cmd
    $lang = $t.lang
    $exe  = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($exe) {
        $ver = ""
        try { $ver = (& $cmd --version 2>&1 | Select-Object -First 1) -replace ".*?(\d+\.\d+[\.\d]*).*", '$1' } catch {}
        Write-Host "  " -NoNewline
        Write-Host "v" -ForegroundColor Green -NoNewline
        Write-Host ("  {0,-12}  " -f $cmd) -NoNewline
        Write-Host ("{0,-24}" -f "($lang)") -ForegroundColor DarkGray -NoNewline
        Write-Host "v$ver" -ForegroundColor DarkGray
        $found++
    } else {
        Write-Host "  " -NoNewline
        Write-Host "-" -ForegroundColor Yellow -NoNewline
        Write-Host ("  {0,-12}  " -f $cmd) -NoNewline
        Write-Host ("{0,-24}" -f "($lang)") -ForegroundColor DarkGray -NoNewline
        Write-Host "not installed" -ForegroundColor DarkGray
        $missing++
    }
    Start-Sleep -Milliseconds 40
}

nl
if ($missing -eq 0) {
    Write-Success "All $($tools.Count) tools installed. You're basically a compiler museum. Impressive."
} elseif ($found -ge 7) {
    Write-Success "Found $found/$($tools.Count) tools. Solid setup. The gaps won't bite unless you need them."
} elseif ($found -ge 3) {
    Write-Info    "Found $found/$($tools.Count) tools. Reasonable. Install more when the moment strikes."
} else {
    Write-Warn    "Found $found/$($tools.Count) tools. A bold minimalist choice. We respect it."
}
nl

# ─────────────────────────────────────────────────────────────
#  SUCCESS
# ─────────────────────────────────────────────────────────────
Write-BigDiv
nl
Write-Host "  " -NoNewline
Write-Host "FastCR is installed!  Open a new terminal and try:" -ForegroundColor Green
nl
Write-Dim  "    cr main.c"
Write-Dim  "    cr script.py --debug"
Write-Dim  "    cr Main.java arg1"
Write-Dim  "    cr --keep server.rs"
Write-Dim  "    cr --del"
Write-Dim  "    cr --help"
nl
Write-Dim  "  Full docs:  https://github.com/Quillpy/Fastcc"
nl
Write-BigDiv
nl

# ─────────────────────────────────────────────────────────────
#  OPTIONAL: DELETE CLONED REPO
# ─────────────────────────────────────────────────────────────
$hasGit = Test-Path (Join-Path $ScriptDir ".git")
$safeToOffer = $hasGit `
    -and ($ScriptDir -ne $env:USERPROFILE) `
    -and ($ScriptDir -notlike "$env:SystemRoot*") `
    -and ($ScriptDir -notlike "$env:ProgramFiles*")

if ($safeToOffer) {
    Write-Host "  " -NoNewline
    Write-Host "One last thing..." -ForegroundColor Yellow
    nl
    Write-Dim  "  The cloned repo is still sitting at:"
    Write-Host "    $ScriptDir" -ForegroundColor White
    nl
    Write-Dim  "  FastCR is installed - you don't need this folder anymore."
    Write-Dim  "  It's the digital equivalent of leaving a moving box in the hallway for 3 months."
    nl

    if ($Force) {
        $cleanup = "y"
    } else {
        Write-Host "  " -NoNewline
        Write-Host "  Throw it in the Recycle Bin? [y/N]  " -ForegroundColor Yellow -NoNewline
        $cleanup = Read-Host
    }
    nl

    if ($cleanup -match '^[Yy]') {
        if (Test-Path $CrDest) {
            try {
                Remove-Item -Recurse -Force $ScriptDir
                Write-Success "Repo deleted.  $ScriptDir  is history. Tidy desk, tidy mind."
            } catch {
                Write-Warn "Couldn't delete the folder: $($_.Exception.Message)"
                Write-Warn "Delete it manually when you're ready."
            }
        } else {
            Write-Warn "Can't confirm install succeeded - NOT deleting the repo just to be safe."
            Write-Warn "Check that  $CrDest  exists, then delete manually."
        }
    } else {
        Write-Info "Fair enough. The folder stays. We won't judge you."
    }
    nl
}

Write-BigDiv
nl
Write-Dim "  FastCR  -  https://github.com/Quillpy/Fastcc"
nl

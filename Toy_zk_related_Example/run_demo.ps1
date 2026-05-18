# run_demo.ps1
# ZK Commitment Demo - PowerShell Automation Script
#
# What this script does:
#   1. Clears (overwrites) logs.txt completely
#   2. Runs: scarb execute --executable-name demo
#   3. Captures all output and saves it to logs.txt
#   4. Also prints output to console for live viewing
#
# Usage: .\run_demo.ps1
# ============================================================

param()

# path to logs.txt (same folder as this script)
$LogFile = Join-Path $PSScriptRoot "logs.txt"
$RunTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host ""
Write-Host "=== ZK Commitment Demo Runner ===" -ForegroundColor Cyan
Write-Host "Run Time : $RunTime"
Write-Host "Log File : $LogFile"
Write-Host ""

# ---- Step 1: Clear logs.txt and write fresh header (atomic) ----
"=== ZK Commitment Demo Log ===" | Out-File -FilePath $LogFile -Encoding utf8 -Force
"Run Time : $RunTime" | Out-File -FilePath $LogFile -Append -Encoding utf8
"================================" | Out-File -FilePath $LogFile -Append -Encoding utf8
"" | Out-File -FilePath $LogFile -Append -Encoding utf8
Write-Host "[1/3] Logs cleared. Fresh run starting..." -ForegroundColor Yellow

# ---- Helper: find scarb in PATH or project ----
function Find-Scarb {
	# 1) try Get-Command
	$cmd = Get-Command scarb -ErrorAction SilentlyContinue
	if ($cmd) {
		if ($cmd.Path) { return $cmd.Path }
		if ($cmd.Definition) { return $cmd.Definition }
		return $cmd
	}
	# 2) check common project-local locations (coerce root to string first)
	$root = [string]$PSScriptRoot
	$candidates = @(
		"$root\scarb.exe",
		"$root\tools\scarb\bin\scarb.exe",
		"$root\tools\scarb.exe",
		"$root\bin\scarb.exe"
	)
	foreach ($c in $candidates) {
		if (Test-Path $c) { return (Get-Item $c).FullName }
	}

	# 3) search recursively in tools/ for scarb.exe (handles extracted folders)
	$toolsDir = Join-Path $root 'tools'
	if (Test-Path $toolsDir) {
		try {
			$found = Get-ChildItem -Path $toolsDir -Recurse -Filter 'scarb.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
			if ($found) { return $found.FullName }
		} catch { }
	}

	# 4) finally try `where.exe`
	try {
		$where = & where.exe scarb 2>$null
		if ($where) { return ($where -split "`r?`n")[0] }
	} catch { }

	return $null
}

# ---- Step 2: Ensure scarb is available (no automatic download) ----
$scarbPath = Find-Scarb
if (-not $scarbPath) {
	$msg = @()
	$msg += "scarb not found in PATH or project."
	$msg += "Please install Scarb manually and add it to your PATH, or copy 'scarb.exe' into one of these project locations:"
	$msg += "  $PSScriptRoot\scarb.exe"
	$msg += "  $PSScriptRoot\tools\scarb\bin\scarb.exe"
	$msg += "  $PSScriptRoot\tools\scarb.exe"
	$msg += "  $PSScriptRoot\bin\scarb.exe"
	$full = $msg -join " `n"
	Write-Host $full -ForegroundColor Yellow
	$full | Out-File -FilePath $LogFile -Append -Encoding utf8
	exit 1
}

Write-Host "[2/3] Running: $scarbPath execute --executable-name demo" -ForegroundColor Yellow
Write-Host ""

# ---- Run scarb and capture output safely ----
try {
	# call scarb by full path (works whether in PATH or local copy)
	$raw = & "$scarbPath" execute --executable-name demo 2>&1
	if ($raw -is [System.Array]) { $output = $raw -join "`n" } else { $output = "$raw" }
} catch {
	$output = "Failed to run scarb: $_"
}

# ---- Helper: safe append with retries to avoid transient locks ----
function Safe-Append {
	param(
		[string]$Path,
		[string]$Text,
		[int]$Attempts = 6,
		[int]$DelayMs = 250
	)
	for ($i = 0; $i -lt $Attempts; $i++) {
		try {
			$Text | Out-File -FilePath $Path -Append -Encoding utf8 -Force
			return $true
		} catch [System.IO.IOException] {
			Start-Sleep -Milliseconds $DelayMs
		} catch {
			throw
		}
	}
	return $false
}

# ---- Step 3: Display output to console ----
Write-Host "--- Demo Output ---" -ForegroundColor Green
Write-Host $output
Write-Host "-------------------"
Write-Host ""

# ---- Step 4: Write output to logs.txt (with retries) ----
"--- Demo Output ---" | Out-File -FilePath $LogFile -Append -Encoding utf8 -Force
if (-not (Safe-Append -Path $LogFile -Text $output)) {
	Write-Host "Warning: Failed to write demo output to log after multiple retries." -ForegroundColor Yellow
}

"" | Out-File -FilePath $LogFile -Append -Encoding utf8 -Force
"=== End of Log ===" | Out-File -FilePath $LogFile -Append -Encoding utf8 -Force

Write-Host "[3/3] Log saved to: $LogFile" -ForegroundColor Green
Write-Host "==================================="
Write-Host ""

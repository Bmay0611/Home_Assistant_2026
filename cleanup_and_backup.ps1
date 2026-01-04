<#
.SYNOPSIS
  Securely back up secret files from your repo, remove them from the current tip, and purge them from history using git-filter-repo (with safe prompts).

.NOTES
  - Run this from your local repository root (e.g. C:\Users\bmayb\Documents\GitHub\Homeassistant2026).
  - This script will:
      1) Detect secret-like files tracked in the current tree (*.pem, *.key, *.crt, *.p12, secret*.txt)
      2) Back them up to an encrypted archive (you provide a passphrase)
      3) Remove them from the current branch tip (git rm --cached) and push that cleanup
      4) Create a mirror backup of the repo
      5) Install git-filter-repo (via pip) if necessary
      6) Run git-filter-repo in a separate mirror to purge the files from history and push selected branches individually
  - Rewriting history is destructive: collaborators must re-clone. Rotate/revoke any compromised keys immediately.
  - You will be prompted to confirm actions. Read prompts carefully.

USAGE
  powershell -ExecutionPolicy Bypass -File .\cleanup_and_backup.ps1

#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Prompt-YesNo([string]$msg, [bool]$defaultNo=$true) {
    $yn = Read-Host "$msg `nType 'y' to continue, anything else to cancel"
    return ($yn -eq 'y' -or $yn -eq 'Y')
}

function Derive-KeyIV([string]$passphrase, [byte[]]$salt, [int]$iter=100000) {
    $r = New-Object Security.Cryptography.Rfc2898DeriveBytes($passphrase, $salt, $iter)
    return @{
        Key = $r.GetBytes(32)    # AES-256
        IV  = $r.GetBytes(16)
    }
}

function Encrypt-File([string]$inPath, [string]$outPath, [string]$passphrase) {
    $salt = New-Object byte[] 16
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($salt)
    $kiv = Derive-KeyIV $passphrase $salt 100000

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $kiv.Key
    $aes.IV  = $kiv.IV
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $encryptor = $aes.CreateEncryptor()
    $inBytes = [System.IO.File]::ReadAllBytes($inPath)

    $ms = New-Object System.IO.MemoryStream
    $cs = New-Object System.Security.Cryptography.CryptoStream($ms, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $cs.Write($inBytes, 0, $inBytes.Length)
    $cs.FlushFinalBlock()
    $cs.Close()

    $cipher = $ms.ToArray()
    # File format: salt (16) + iter (4) + cipher
    $iterBytes = [BitConverter]::GetBytes([int]100000)
    $out = New-Object System.IO.MemoryStream
    $out.Write($salt, 0, $salt.Length)
    $out.Write($iterBytes, 0, $iterBytes.Length)
    $out.Write($cipher, 0, $cipher.Length)
    [System.IO.File]::WriteAllBytes($outPath, $out.ToArray())
}

# --- Start script ---
Write-Host "RUNNING SECRET CLEANUP + HISTORY PURGE SCRIPT"
Write-Host "Make sure you're in your repository root. Current directory:"
Write-Host (Get-Location).Path
if (-not (Test-Path ".git")) {
    Write-Error "This directory does not look like a git repo root (no .git folder). cd to the repo root and rerun."
    exit 1
}

# Detect git remote origin
$originUrl = (git remote get-url origin 2>$null) -join ''
if (-not $originUrl) {
    Write-Error "No git remote 'origin' found. Add or check remote and rerun."
    exit 1
}
Write-Host "Remote origin: $originUrl"

# Detect current branch
$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Current branch: $currentBranch"

# Patterns and detection
$patterns = @('*.pem','*.key','*.crt','*.p12','secret*.txt')
Write-Host "Looking for tracked files that match: $($patterns -join ', ')"

# Get tracked files and find matches
$tracked = git ls-files
$secretFiles = @()
foreach ($p in $patterns) {
    # convert glob to regex: simple approach
    $regex = [Regex]::Escape($p).Replace('\*','.*') + '$'
    $secretFiles += ($tracked | Where-Object { $_ -match $regex })
}
$secretFiles = $secretFiles | Select-Object -Unique

if (-not $secretFiles -or $secretFiles.Count -eq 0) {
    Write-Host "No tracked secret-like files found in the current tree."
} else {
    Write-Host "FOUND tracked secret files:"
    $secretFiles | ForEach-Object { Write-Host "  $_" }

    if (-not (Prompt-YesNo "Proceed to back up these files and remove them from the current tip? (you will be prompted for a passphrase to encrypt the backup)") ) {
        Write-Host "Aborted by user."
        exit 0
    }

    # Prepare backup folder
    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $backupDir = Join-Path $env:USERPROFILE "Secrets_Backup\Home_Assistant_2026_$timestamp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

    # Copy secret files to backup and create a zip
    Write-Host "Copying secret files to backup folder: $backupDir"
    foreach ($f in $secretFiles) {
        $src = Join-Path (Get-Location).Path $f
        if (Test-Path $src) {
            $dest = Join-Path $backupDir (Split-Path $f -Leaf)
            Copy-Item -Path $src -Destination $dest -Force
        } else {
            Write-Warning "File not found on disk (skipping): $src"
        }
    }

    $tempZip = Join-Path $env:TEMP "repo_secrets_$timestamp.zip"
    Write-Host "Creating temporary zip: $tempZip"
    Compress-Archive -Path (Join-Path $backupDir '*') -DestinationPath $tempZip -Force

    # Ask passphrase
    $pass1 = Read-Host "Enter passphrase to encrypt backup (will not be displayed)" -AsSecureString
    $pass2 = Read-Host "Confirm passphrase" -AsSecureString
    $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass1))
    $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass2))
    if ($plain1 -ne $plain2) {
        Write-Error "Passphrases did not match. Aborting."
        Remove-Item $tempZip -ErrorAction SilentlyContinue
        exit 1
    }

    $encPath = Join-Path $backupDir "secrets_encrypted.enc"
    Write-Host "Encrypting zip to: $encPath"
    Encrypt-File -inPath $tempZip -outPath $encPath -passphrase $plain1

    # Cleanup temporary zip and unencrypted copies (user choice)
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    $keepPlain = Prompt-YesNo "Remove unencrypted backup copies from disk and keep only the encrypted archive? (recommended)" 
    if ($keepPlain) {
        Get-ChildItem -Path $backupDir -Exclude "secrets_encrypted.enc" | Remove-Item -Recurse -Force
        Write-Host "Unencrypted copies removed. Encrypted archive located at: $encPath"
    } else {
        Write-Host "Unencrypted copies retained in: $backupDir (encrypted archive also present)"
    }

    # Remove secret files from current index (keep local copies in working directory? we used --cached)
    Write-Host "Removing secret files from git index (git rm --cached ...) and adding .gitignore"
    git rm --cached --quiet @($secretFiles) 2>$null
    # ensure .gitignore has entry
    foreach ($p in $patterns) {
        if (-not (Select-String -Path .gitignore -Pattern ([Regex]::Escape($p)) -SimpleMatch -Quiet -ErrorAction SilentlyContinue)) {
            Add-Content -Path .gitignore -Value $p
        }
    }
    git add .gitignore
    git commit -m "Remove secret certificate/key files from current tree and ignore *.pem/*.key/etc." || Write-Host "Nothing to commit (maybe commit already exists)."
    # Push current branch to origin
    Write-Host "Pushing cleanup commit to origin/$currentBranch"
    git push origin $currentBranch
}

# Create a mirror backup before rewriting history
$mirrorBackup = Join-Path $env:TEMP ("Home_Assistant_2026-backup-{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Write-Host "Creating a mirror backup of the repository at: $mirrorBackup"
git clone --mirror $originUrl $mirrorBackup
Write-Host "Mirror backup created."

# Ask which branches to rewrite (default: main and current branch if present)
$allBranches = git for-each-ref --format='%(refname:short)' refs/heads | Sort-Object
Write-Host "Branches found in your local repo:"
$allBranches | ForEach-Object { Write-Host "  $_" }

$defaultTargets = @()
if ($allBranches -contains "main") { $defaultTargets += "main" }
if ($allBranches -contains $currentBranch -and $currentBranch -ne "main") { $defaultTargets += $currentBranch }
if ($defaultTargets.Count -eq 0) { $defaultTargets = $allBranches[0..([math]::Min(1,$allBranches.Count-1))] }

Write-Host "By default the script will attempt to rewrite: $($defaultTargets -join ', ')"
$resp = Read-Host "Enter comma-separated branches to purge (or press ENTER to use defaults above)"
if ([string]::IsNullOrWhiteSpace($resp)) {
    $branchesToPush = $defaultTargets
} else {
    $branchesToPush = $resp.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
}

Write-Host "Branches that will be force-replaced on origin after purge: $($branchesToPush -join ', ')"

if (-not (Prompt-YesNo "Proceed to rewrite history and purge secret file types from all commits? This will rewrite commit history for the selected branches.") ) {
    Write-Host "User cancelled history purge. Exiting."
    exit 0
}

# Ensure git-filter-repo is installed
function Ensure-GitFilterRepo {
    try {
        git filter-repo --help > $null 2>&1
        return $true
    } catch {
        Write-Host "git-filter-repo not found. Attempting to install via pip..."
        try {
            python -m pip install --upgrade git-filter-repo
            git filter-repo --help > $null 2>&1
            return $true
        } catch {
            Write-Warning "Automatic installation of git-filter-repo failed. You can install it manually (python -m pip install git-filter-repo) or use BFG (requires Java)."
            return $false
        }
    }
}

$haveFilterRepo = Ensure-GitFilterRepo
if (-not $haveFilterRepo) {
    Write-Error "git-filter-repo is required to proceed with the automatic purge. Install it and rerun the script, or contact me for a BFG alternative."
    exit 1
}

# Prepare a mirror clone for filter-repo operation
$filterMirror = Join-Path $env:TEMP ("Home_Assistant_2026-filter-{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Write-Host "Cloning a fresh mirror for filter-repo at: $filterMirror"
git clone --mirror $originUrl $filterMirror
Set-Location $filterMirror

# Build path-glob args
$pathGlobs = @("*.pem","*.key","*.crt","*.p12","secret*.txt")
$globArgs = $pathGlobs | ForEach-Object { "--path-glob `"$($_)`"" } | Out-String
$globArgs = $globArgs -replace "`r`n"," "

Write-Host "Running git-filter-repo to remove the following globs from history: $($pathGlobs -join ', ')"
# Run filter-repo
$cmd = "git filter-repo --invert-paths $globArgs"
Write-Host "Executing: $cmd"
Invoke-Expression $cmd

# Cleanup local mirror repo
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push selected branches one-by-one to avoid accidental deletion of remote branches
Write-Host "Force pushing rewritten branches back to origin (one-by-one). Branch protection may block pushes to protected branches."
foreach ($b in $branchesToPush) {
    if ($b -ne '') {
        Write-Host "Pushing cleaned branch: $b"
        try {
            git push --force origin "refs/heads/$b:refs/heads/$b"
            Write-Host "Pushed $b"
        } catch {
            Write-Warning "Failed to force-push branch $b. You may need to disable branch protection or push manually. Error: $_"
        }
    }
}

# Optionally push tags
if (Prompt-YesNo "Push tags to origin (force)? (Recommended for completeness; decide 'y' to do this)") {
    try {
        git push --force origin --tags
        Write-Host "Tags pushed."
    } catch {
        Write-Warning "Failed to push tags: $_"
    }
}

# Final verification steps (local)
Set-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
Write-Host ""
Write-Host "=== DONE ==="
Write-Host "IMPORTANT NEXT STEPS:"
Write-Host "  1) Immediately rotate/revoke any keys/certificates that were exposed (they remain valid until rotated)."
Write-Host "  2) Tell collaborators to re-clone the repo (history was rewritten). Example message: 'Please reclone repository; history rewritten to remove secrets.'"
Write-Host "  3) Create a non-sensitive commit (README.md) to help GitHub re-index the repo and wait 24-72 hours for indexing to refresh."
Write-Host ""
Write-Host "Encrypted secret backup is in: $backupDir (file: secrets_encrypted.enc) - keep your passphrase safe."
Write-Host ""
Write-Host "If any force-pushes failed due to branch protection, visit https://github.com/$($originUrl -replace '^.*github.com[:/]+','','')/settings/branches to adjust protection temporarily or push manually."
Write-Host ""
Write-Host "Script finished."

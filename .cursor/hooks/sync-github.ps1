# After a Cursor agent session in this project, commit non-secret changes
# and push them to the current branch. Never changes git config, never
# force-pushes, and never amends a failed commit.
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$env:GIT_TERMINAL_PROMPT = "0"
$env:GCM_INTERACTIVE = "Never"

$script:Done = $false
$script:GitExe = $null

function Redact([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    $text = [regex]::Replace($text, "https://[^@\s/]+@", "https://***@")
    $text = [regex]::Replace($text, "\b(ghp_|gho_|github_pat_|glpat-)[A-Za-z0-9_]+", '$1***')
    if ($text.Length -gt 2000) { $text = $text.Substring(0, 2000) }
    return $text
}

function Finish([string]$message) {
    if ($script:Done) { return }
    $script:Done = $true
    $safe = Redact $message
    try {
        $dir = Join-Path (Get-Location) ".cursor\hooks"
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
        $log = Join-Path $dir "last-sync-result.txt"
        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Set-Content -LiteralPath $log -Value "$stamp $safe" -Encoding UTF8
    } catch {
        [Console]::Error.WriteLine("Could not write the sync result file.")
    }
    [Console]::Error.WriteLine($safe)
    [Console]::Out.WriteLine("{}")
}

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$GitArgs
    )
    if (-not $script:GitExe) {
        return @{ Code = 127; Text = "git was not found" }
    }
    $output = & $script:GitExe @GitArgs 2>&1
    $code = $LASTEXITCODE
    if ($null -eq $output) {
        $text = ""
    } else {
        $text = (@($output | ForEach-Object { "$_" }) -join "`n").Trim()
    }
    return @{ Code = $code; Text = $text }
}

function Unquote-GitPath([string]$value) {
    $value = $value.Trim()
    if ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) {
        $inner = $value.Substring(1, $value.Length - 2)
        return $inner.Replace('\"', '"').Replace('\\', '\')
    }
    return $value
}

function Test-SecretPath([string]$relativePath) {
    $relativePath = ($relativePath -replace "\\", "/").Trim()
    if ($relativePath -eq ".cursor/hooks/last-sync-result.txt") { return $true }
    $name = Split-Path $relativePath -Leaf
    if ($name -match '(?i)^\.(env)($|\.)') { return $true }
    if ($name -match '(?i)credential') { return $true }
    if ($name -match '(?i)secret') { return $true }
    if ($name -match '(?i)token') { return $true }
    if ($name -match '(?i)\.(pem|key|pfx|p12|kdbx)$') { return $true }
    if ($name -match '(?i)^(id_rsa|id_dsa|id_ecdsa|id_ed25519)($|\.)') { return $true }
    if ($relativePath -match '(?i)(^|/)secrets?(/|$)') { return $true }
    return $false
}

function Test-SecretContent([string]$fullPath) {
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { return $false }
    $item = Get-Item -LiteralPath $fullPath
    if ($item.Length -gt 1048576) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    foreach ($byte in $bytes) {
        if ($byte -eq 0) { return $false }
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text -match "-----BEGIN [A-Z ]*PRIVATE KEY-----") { return $true }
    if ($text -match "(?i)\b(ghp_|gho_|github_pat_|glpat-|xox[baprs]-|AKIA[0-9A-Z]{16})") { return $true }
    return $false
}

function Get-RepoChanges {
    $status = Invoke-Git -c core.quotepath=false status --porcelain=v1 -uall
    $items = @()
    if ($status.Code -ne 0) {
        return @{ Ok = $false; Error = $status.Text; Items = $items }
    }
    foreach ($rawLine in ($status.Text -split "`n")) {
        $line = $rawLine.TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
        $code = $line.Substring(0, 2)
        $rest = $line.Substring(3)
        $path = $rest
        if ($code.Contains("R") -or $code.Contains("C")) {
            $arrow = $rest.LastIndexOf(" -> ")
            if ($arrow -ge 0) { $path = $rest.Substring($arrow + 4) }
        }
        $items += [pscustomobject]@{
            Code = $code
            Path = (Unquote-GitPath $path)
        }
    }
    return @{ Ok = $true; Error = ""; Items = $items }
}

try {
    $rawInput = ""
    if ($null -ne [Console]::In -and [Console]::In.Peek() -ge 0) {
        $rawInput = [Console]::In.ReadToEnd()
    }
    $statusName = "completed"
    if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
        try {
            $hookInput = $rawInput | ConvertFrom-Json
        } catch {
            Finish "Skipped: hook input was not valid JSON, so nothing was committed."
            exit 0
        }
        if ($hookInput.status) { $statusName = [string]$hookInput.status }
        if ($null -ne $hookInput.loop_count -and [int]$hookInput.loop_count -gt 0) {
            Finish "Skipped: this session already continued from the stop hook, so nothing was committed."
            exit 0
        }
    }

    if ($statusName -eq "aborted") {
        Finish "Skipped: the agent session was aborted, so nothing was committed."
        exit 0
    }

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $script:GitExe = $gitCmd.Source
    } elseif (Test-Path -LiteralPath "C:\Program Files\Git\cmd\git.exe") {
        $script:GitExe = "C:\Program Files\Git\cmd\git.exe"
    }
    if (-not $script:GitExe) {
        Finish "Skipped: git was not found, so nothing was committed."
        exit 0
    }

    $top = Invoke-Git rev-parse --show-toplevel
    if ($top.Code -ne 0 -or [string]::IsNullOrWhiteSpace($top.Text)) {
        Finish "Skipped: this folder is not a git repository."
        exit 0
    }
    Set-Location -LiteralPath $top.Text.Trim()

    $projectFile = Join-Path (Get-Location) "project.godot"
    if (-not (Test-Path -LiteralPath $projectFile)) {
        Finish "Skipped: this is not the U r fired Godot project."
        exit 0
    }
    $projectText = Get-Content -LiteralPath $projectFile -Raw
    if ($projectText -notmatch 'config/name="U r fired"') {
        Finish "Skipped: this is not the U r fired Godot project."
        exit 0
    }

    foreach ($marker in @(".git\MERGE_HEAD", ".git\rebase-merge", ".git\rebase-apply", ".git\CHERRY_PICK_HEAD")) {
        if (Test-Path -LiteralPath (Join-Path (Get-Location) $marker)) {
            Finish "Skipped: a merge, rebase, or cherry-pick is in progress, so nothing was committed."
            exit 0
        }
    }

    $changes = Get-RepoChanges
    if (-not $changes.Ok) {
        Finish ("Skipped: git status failed, so nothing was committed. " + $changes.Error)
        exit 0
    }

    $commitPaths = New-Object System.Collections.Generic.List[string]
    $secretPaths = New-Object System.Collections.Generic.List[string]
    foreach ($change in $changes.Items) {
        $relative = $change.Path
        $isDeletion = $change.Code.Contains("D") -and -not (Test-Path -LiteralPath (Join-Path (Get-Location) $relative))
        if (-not $isDeletion -and (Test-SecretPath $relative)) {
            [void]$secretPaths.Add($relative)
            continue
        }
        $full = Join-Path (Get-Location) $relative
        if (-not $isDeletion -and (Test-SecretContent $full)) {
            [void]$secretPaths.Add($relative)
            continue
        }
        [void]$commitPaths.Add($relative)
    }

    $secretNote = ""
    if ($secretPaths.Count -gt 0) {
        $secretNote = " Left uncommitted because they look like secrets: " + ($secretPaths -join ", ") + "."
    }

    if ($commitPaths.Count -eq 0) {
        Finish ("Skipped: nothing to commit." + $secretNote)
        exit 0
    }

    $remote = Invoke-Git remote get-url origin
    if ($remote.Code -ne 0 -or $remote.Text -notmatch "github\.com[:/]") {
        Finish ("Skipped: GitHub origin is missing, so nothing was committed." + $secretNote)
        exit 0
    }

    $probe = Invoke-Git ls-remote origin
    if ($probe.Code -ne 0) {
        Finish ("Skipped: GitHub authentication or network access failed, so nothing was committed. " + $probe.Text + $secretNote)
        exit 0
    }

    $branch = Invoke-Git rev-parse --abbrev-ref HEAD
    if ($branch.Code -ne 0 -or [string]::IsNullOrWhiteSpace($branch.Text) -or $branch.Text.Trim() -eq "HEAD") {
        Finish ("Skipped: the checkout is detached, so nothing was committed." + $secretNote)
        exit 0
    }
    $branchName = $branch.Text.Trim()

    if ($DryRun) {
        Finish ("Dry run: would commit " + $commitPaths.Count + " path(s) and push branch " + $branchName + " without force. Paths: " + ($commitPaths -join ", ") + "." + $secretNote)
        exit 0
    }

    foreach ($relative in $commitPaths) {
        $added = Invoke-Git --literal-pathspecs add -- $relative
        if ($added.Code -ne 0) {
            Finish ("Commit was not created because git add failed for " + $relative + ". " + $added.Text + $secretNote)
            exit 0
        }
    }

    foreach ($relative in $secretPaths) {
        $full = Join-Path (Get-Location) $relative
        if (Test-Path -LiteralPath $full) {
            Invoke-Git restore --staged -- $relative | Out-Null
        }
    }

    $staged = Invoke-Git diff --cached --name-only
    if ($staged.Code -ne 0) {
        Finish ("Commit was not created because the staged file list could not be read. " + $staged.Text)
        exit 0
    }
    if ([string]::IsNullOrWhiteSpace($staged.Text)) {
        Finish ("Skipped: nothing to commit." + $secretNote)
        exit 0
    }

    $committed = Invoke-Git commit -m "Update the game after agent edits." -m "Save the latest project changes from the Cursor agent onto the current branch."
    if ($committed.Code -ne 0) {
        Finish ("Commit failed and was not amended. " + $committed.Text + $secretNote)
        exit 0
    }

    $upstream = Invoke-Git rev-parse --abbrev-ref --symbolic-full-name "@{u}"
    if ($upstream.Code -ne 0) {
        $pushed = Invoke-Git push -u origin HEAD
    } else {
        $pushed = Invoke-Git push
    }
    if ($pushed.Code -ne 0) {
        Finish ("The local commit succeeded, but the push failed and was not forced. " + $pushed.Text + $secretNote)
        exit 0
    }

    Finish ("Pushed branch " + $branchName + " to GitHub." + $secretNote)
    exit 0
} catch {
    Finish ("Sync failed and was not retried. " + $_.Exception.Message)
    exit 0
}

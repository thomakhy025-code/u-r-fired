$candidates = @(
    (Join-Path $env:LOCALAPPDATA "Godot\Godot_v4.7.2-stable_win64_console.exe"),
    (Join-Path $env:LOCALAPPDATA "Godot\Godot_v4.7.2-stable_win64.exe"),
    (Join-Path $env:USERPROFILE "Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"),
    (Join-Path $env:USERPROFILE "Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe")
)

foreach ($path in $candidates) {
    if (Test-Path -LiteralPath $path) {
        Write-Output $path
        exit 0
    }
}

[Console]::Error.WriteLine("Godot 4.7.2 was not found.")
exit 1

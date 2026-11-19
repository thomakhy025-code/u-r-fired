# U r fired

Godot 4.7 project for a small 3D office.

Name the company, then run the room. The phone rings with a customer who wants chairs or mobile phones. Pick an employee to take the call. Buy wood, plastic, and glass from the supply shelf, and craft the order on the bench. Hand the goods over before love falls to 0. The company is paid, and that employee receives a commission. R&D spends cash to raise company skill and shorten the next craft.

Open `project.godot` in Godot 4.7.2 (the standard editor, not the .NET build). The scene is `scenes/main.tscn`.

On this computer the editor is not on `PATH`. The console binary is:

`%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64_console.exe`

`tools/godot-editor.ps1` prints the binary it finds.

The private GitHub repository is https://github.com/thomakhy025-code/u-r-fired. When a Cursor agent session in this project finishes, `.cursor/hooks/sync-github.ps1` commits non-secret files and pushes the current branch. It does not force-push. An aborted session is left uncommitted. Edits made outside an agent session stay local until the next finished agent session, or until you commit them yourself.

GitHub Actions imports the project, checks the scripts, and runs the simulation checks. It does not export a playable build.

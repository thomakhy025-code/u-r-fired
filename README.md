# U r fired

Godot 4.7 project for a small real-time office.

Name the company, then run the room. Tap a desk to start a product, wait out the seconds, and tap the finished job onto the outbox. The phone rings with a caller who wants one product. Hand that product over before the patience bar runs out and they pay cash. Restock the shelf, wipe up papers and cups, hire a person, and buy a faster desk, another outbox slot, a second phone line, or a bigger shelf.

Open `project.godot` in Godot 4.7.2 (the standard editor, not the .NET build). The scene is `scenes/main.tscn`.

On this computer the editor is not on `PATH`. The console binary is:

`%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64_console.exe`

`tools/godot-editor.ps1` prints the binary it finds.

The private GitHub repository is https://github.com/thomakhy025-code/u-r-fired. When a Cursor agent session in this project finishes, `.cursor/hooks/sync-github.ps1` commits non-secret files and pushes the current branch. It does not force-push. An aborted session is left uncommitted. Edits made outside an agent session stay local until the next finished agent session, or until you commit them yourself.

GitHub Actions imports the project, checks the scripts, and runs the simulation checks. It does not export a playable build.

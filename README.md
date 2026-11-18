# U r fired

Godot 4.7 project for a company-director simulation.

You direct a company by pressing buttons. There is no character to walk. The director sits in one room. Empty desks outside fill when someone is hired.

The signs on the right are mail, the newspaper, customer orders, suppliers, recruiting, and the bank. The bank sign shows the interest rate. A deal with a customer or a supplier moves only after you assign one employee, or a few. They report at proposal, doing, and almost finish. Each report lists every heart on that deal.

Love changes how much work is finished, how fast it moves, and the terms. Strengths and bad habits are separate. A paid training period takes someone off the job and rolls three independent chances: a milder temper, a larger workload, and a faster pace.

Open `project.godot` in Godot 4.7.2 (the standard editor, not the .NET build). The scene is `scenes/main.tscn`.

On this computer the editor is not on `PATH`. The console binary is:

`%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64_console.exe`

`tools/godot-editor.ps1` prints the binary it finds.

The private GitHub repository is https://github.com/thomakhy025-code/u-r-fired. When a Cursor agent session in this project finishes, `.cursor/hooks/sync-github.ps1` commits non-secret files and pushes the current branch. It does not force-push. An aborted session is left uncommitted. Edits made outside an agent session stay local until the next finished agent session, or until you commit them yourself.

GitHub Actions imports the project, checks the scripts, and runs the simulation checks. It does not export a playable build.

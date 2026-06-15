# Workflowy Internal Link Tool

One-hotkey creation of internal links in [Workflowy](https://workflowy.com).

Put your cursor in any Workflowy node, press **Ctrl+Alt+L**, and your
clipboard now contains a hyperlinked label like
**[WorkflowyItem#BuyMilkAtThe]** that points to that node. Paste it
(Ctrl+V) anywhere in Workflowy to create the reference. The original node
is left unchanged.

This replaces a manual workflow that previously required PhraseExpress,
ClipboardFusion, and several copy/select/paste steps per link.

## How it works

The script drives Workflowy purely through keystrokes and the clipboard —
no screen coordinates, no DOM inspection — so it works in any browser and
in the Workflowy desktop app, and is unaffected by Workflowy UI redesigns:

1. **Capture** — `Ctrl+A` (Workflowy's "select current item") + `Ctrl+C`
   grabs the node text.
2. **Label** — the first 4 words are converted to PascalCase and wrapped
   into `[WorkflowyItem#LikeThis]`.
3. **Link** — `Alt+Shift+L` (Workflowy's native "copy internal link")
   puts the node's URL in the clipboard.
4. **Hyperlink** — the label is pasted at the end of the node, selected,
   and the URL is pasted over it. Workflowy converts text that has a URL
   pasted over it into a hyperlink.
5. **Cut** — the hyperlinked label is cut, restoring the node and leaving
   the finished link in your clipboard, ready to paste.

If anything fails mid-way, the script restores your original clipboard and
shows an error notification. `Ctrl+Z` in Workflowy undoes any partial edit.

## Installation

1. Install [AutoHotkey v2](https://www.autohotkey.com/) (the script
   requires v2, not v1).
2. Download `WorkflowyInternalLink.ahk` and double-click it. A tray icon
   appears while it's running.
3. (Optional) To run it at startup, put a shortcut to the script in
   `shell:startup` (Win+R, type `shell:startup`, Enter).

## Usage

1. Click into the Workflowy node you want to link to (cursor in the text).
2. Press **Ctrl+Alt+L**.
3. Wait for the "Copied" notification (~1–2 seconds of automated typing —
   don't touch the keyboard or mouse during it).
4. Navigate to where you want the reference and press **Ctrl+V**.

## Configuration

Edit the configuration block at the top of the script:

| Setting           | Default            | Meaning                                            |
| ----------------- | ------------------ | -------------------------------------------------- |
| `TRIGGER_KEY`     | `^!l` (Ctrl+Alt+L) | The trigger hotkey ([syntax](https://www.autohotkey.com/docs/v2/Hotkeys.htm)) |
| `LABEL_PREFIX`    | `WorkflowyItem#`   | Text before the generated label                    |
| `MAX_WORDS`       | `4`                | How many words of the node go into the label       |
| `MAX_LABEL_CHARS` | `40`               | Hard cap on the label length                       |
| `STEP_DELAY`      | `120` ms           | Pause between keystrokes                           |
| `PASTE_DELAY`     | `250` ms           | Pause after each paste                             |
| `TARGET_EXES`     | major browsers     | Apps where the hotkey is active                    |

After editing, right-click the tray icon and choose **Reload Script**.

## Troubleshooting

- **The label ends up mangled or half-linked** — Workflowy didn't keep up
  with the keystrokes. Increase `STEP_DELAY` and `PASTE_DELAY` (try 250 /
  500). Slow machines, busy tabs, and large Workflowy documents need
  larger delays.
- **"Alt+Shift+L didn't copy a link"** — your cursor wasn't inside a
  Workflowy node, or another extension/app intercepts Alt+Shift+L.
- **Hotkey does nothing** — the active window's process isn't in
  `TARGET_EXES`. Add your browser's `.exe` name to the list.
- **Whole page got selected instead of one node** — Workflowy's Ctrl+A
  selects the current item only when the cursor is in a node's text;
  click into the node first.

## Antivirus false positives

Some antivirus products (e.g. Norton, with a detection like `IDP.Generic`
flagged by "Behavioral Protection") may flag this script — or
`AutoHotkey64.exe` itself — as a threat. **This is a false positive.**

It happens because the script's core job is to **simulate keystrokes and
read/write the clipboard** — the same behaviors that keyloggers and
clipboard-stealers exhibit. A behavioral/heuristic scanner can't tell
benign automation apart from malicious automation, so AutoHotkey scripts
are among the most commonly false-flagged legitimate tools. When the
antivirus blames `AutoHotkey64.exe`, that's the interpreter running the
script, not a compromised AutoHotkey install.

For the record, this script:

- Makes **no network connections** (there is no download/HTTP/socket code)
- Writes **no files**, touches **no registry keys**, spawns **no processes**
- Only sends keystrokes, uses the clipboard, and shows tray notifications

Nothing leaves your machine. The script is plain, readable text — open it
and check every line yourself.

**To verify independently:**

1. Upload `WorkflowyInternalLink.ahk` to [VirusTotal](https://www.virustotal.com);
   a plain-text AHK script comes back clean from essentially all engines.
2. Read the source — it's commented top to bottom.
3. Confirm the only process involved is the official `AutoHotkey64.exe`
   from `C:\Program Files\AutoHotkey\v2\`.

**To resolve:** add the script to your antivirus's exclusions/allow list.

## Limitations

- The label is generated from the node's first words. If you want a
  hand-crafted semantic label instead, edit the link text after pasting,
  or temporarily put the desired words at the start of the node.
- Don't type or click while the script is running (it's ~1–2 seconds).

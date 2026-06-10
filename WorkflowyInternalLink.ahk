; ============================================================================
; Workflowy Internal Link Tool
; ----------------------------------------------------------------------------
; Press the hotkey (default Ctrl+Alt+L) while your cursor is inside a
; Workflowy node. The script will:
;
;   1. Capture the node's text (Ctrl+A selects the current item in Workflowy)
;   2. Generate a PascalCase label from the first few words,
;      e.g. "buy milk at the store" -> [WorkflowyItem#BuyMilkAtThe]
;   3. Copy the node's internal link with Workflowy's native Alt+Shift+L
;   4. Paste the label at the end of the node, select it, and paste the
;      link over it (Workflowy turns pasted-over text into a hyperlink)
;   5. Cut the hyperlinked label - it's now in your clipboard, and the
;      node is back to its original text
;
; Then just Ctrl+V the link wherever you want to reference the node.
; ============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================ Configuration =================================
HOTKEY          := "^!l"            ; Ctrl+Alt+L. See AHK docs for syntax:
                                    ; ^ = Ctrl, ! = Alt, + = Shift, # = Win
LABEL_PREFIX    := "WorkflowyItem#" ; text before the generated label
MAX_WORDS       := 4                ; how many words of the node to use
MAX_LABEL_CHARS := 40               ; hard cap on generated label length
STEP_DELAY      := 120              ; ms between keystrokes; raise if flaky
PASTE_DELAY     := 250              ; ms after each paste; raise if flaky

; Windows where the hotkey is active (browsers + Workflowy desktop app)
TARGET_EXES := [
    "chrome.exe", "msedge.exe", "firefox.exe", "brave.exe",
    "opera.exe", "vivaldi.exe", "arc.exe", "WorkFlowy.exe"
]
; ============================================================================

A_IconTip := "Workflowy Internal Link Tool (" HotkeyToText(HOTKEY) ")"

for exe in TARGET_EXES
    GroupAdd "WorkflowyHosts", "ahk_exe " exe

HotIfWinActive "ahk_group WorkflowyHosts"
Hotkey HOTKEY, CreateInternalLink
HotIfWinActive

TrayTip "Ready. Press " HotkeyToText(HOTKEY) " inside a Workflowy node.",
    "Workflowy Internal Link Tool"

CreateInternalLink(*)
{
    savedClip := ClipboardAll()

    ; --- 1. Capture the current node's text -------------------------------
    ; In Workflowy, the first Ctrl+A selects only the current item's text.
    A_Clipboard := ""
    Send "^a"
    Sleep STEP_DELAY
    Send "^c"
    if !ClipWait(1) {
        Fail savedClip, "Couldn't read the node text. Is your cursor inside a Workflowy node?"
        return
    }
    nodeText := Trim(A_Clipboard)

    label := MakePascalLabel(nodeText)
    if (label = "") {
        Fail savedClip, "The node appears to be empty - nothing to build a label from."
        return
    }
    fullLabel := "[" LABEL_PREFIX label "]"
    labelLen  := StrLen(fullLabel)

    ; Collapse the selection so the cursor sits at the end of the node text.
    Send "{Right}"
    Sleep STEP_DELAY

    ; --- 2. Copy the node's internal link (Workflowy native shortcut) -----
    A_Clipboard := ""
    Send "!+l"
    if !ClipWait(2) {
        Fail savedClip, "Alt+Shift+L didn't copy a link. Are you in Workflowy?"
        return
    }
    url := A_Clipboard
    if !RegExMatch(url, "i)^https?://") {
        Fail savedClip, "Expected a link from Alt+Shift+L but got:`n" SubStr(url, 1, 100)
        return
    }

    ; --- 3. Paste the label at the end of the node ------------------------
    A_Clipboard := fullLabel
    ClipWait 1
    Send "^v"
    Sleep PASTE_DELAY

    ; --- 4. Select the label and paste the URL over it to hyperlink it ----
    Send "+{Left " labelLen "}"
    Sleep STEP_DELAY
    A_Clipboard := url
    ClipWait 1
    Send "^v"
    Sleep PASTE_DELAY

    ; --- 5. Select the hyperlinked label and cut it -----------------------
    ; The visible text length is unchanged, so the same selection works.
    Send "+{Left " labelLen "}"
    Sleep STEP_DELAY
    A_Clipboard := ""
    Send "^x"
    if !ClipWait(2, 1) {
        Fail savedClip, "Cutting the hyperlinked label failed. The node may need manual cleanup (Ctrl+Z)."
        return
    }

    TrayTip "Copied " fullLabel "`nPaste it (Ctrl+V) wherever you want the reference.",
        "Workflowy Internal Link Tool"
}

; Build a PascalCase label from the first MAX_WORDS words of the node text.
MakePascalLabel(text)
{
    text := RegExReplace(text, "i)https?://\S+", " ")   ; drop URLs
    text := RegExReplace(text, "[^\w]+", " ")           ; keep letters/digits/_
    out := ""
    count := 0
    for word in StrSplit(text, " ") {
        if (word = "")
            continue
        out .= StrUpper(SubStr(word, 1, 1)) SubStr(word, 2)
        if (++count >= MAX_WORDS)
            break
    }
    if (StrLen(out) > MAX_LABEL_CHARS)
        out := SubStr(out, 1, MAX_LABEL_CHARS)
    return out
}

; Restore the user's clipboard and show an error notification.
Fail(savedClip, msg)
{
    A_Clipboard := savedClip
    TrayTip msg, "Workflowy Internal Link Tool", "Iconx"
    SoundBeep 300, 150
}

; Human-readable hotkey name for notifications, e.g. "^!l" -> "Ctrl+Alt+L".
HotkeyToText(hk)
{
    out := ""
    Loop Parse hk {
        switch A_LoopField {
            case "^": out .= "Ctrl+"
            case "!": out .= "Alt+"
            case "+": out .= "Shift+"
            case "#": out .= "Win+"
            default:  out .= StrUpper(A_LoopField)
        }
    }
    return out
}

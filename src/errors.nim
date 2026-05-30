from std/os import existsEnv
from std/strutils import replace, repeat
from std/terminal import ansiForegroundColorCode, ansiResetCode, ansiStyleCode, fgRed, styleBright, isatty

# Errors
type StarchError* = ref object of CatchableError
    line*, col*, length*: int
    context*, file*: string
type StarchSyntaxError* = ref object of StarchError
type StarchTypeError* = ref object of StarchError

# Formatting
proc red*(text: string): string {.inline.} =
    if not stdout.isatty(): return text
    if existsEnv("NO_COLOR"): return text
    ansiForegroundColorCode(fgRed) & text & ansiResetCode

proc bold*(text: string): string {.inline.} =
    if not stdout.isatty(): return text
    if existsEnv("NO_COLOR"): return text
    ansiStyleCode(styleBright) & text & ansiResetCode

proc newStarchError*(kind: typedesc[StarchError], msg: string, context: string = "", line: int = 0, col: int = 0, length: int = 1, file: string = "<starch-input>"): StarchError =
    ## Constructs an error message with formatting and position information.
    var text: string = "File " & red("\"" & file & "\"") & ", line " & red($line)
    if context != "":
        let cleanContext = context.replace("\t", "    ")
        text.add("\n    " & cleanContext)
        if col > 0:
            let spaces: string = " ".repeat(cleanContext[0 ..< col - 1].len)
            text.add("\n    " & spaces & red("^".repeat(length)))

    # Strip "Starch" from error name
    let typeName = ($kind).replace("Starch", "").replace("ref ", "")
    text.add("\n" & bold(red(typeName)) & ": " & red(msg))

    result = kind(msg: text, context: context, line: line, col: col, length: length, file: file)

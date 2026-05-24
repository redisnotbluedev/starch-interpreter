import std/strformat
import std/strutils
import std/terminal

# Errors
type StarchError* = ref object of CatchableError
    line*: int
    context*: string
    col*: int
    file*: string
type StarchSyntaxError* = ref object of StarchError
type StarchTypeError* = ref object of StarchError

# Formatting
template red*(text: string): string =
    ansiForegroundColorCode(fgRed) & text & ansiResetCode

template bold*(text: string): string =
    ansiStyleCode(styleBright) & text & ansiResetCode

proc newStarchError*(kind: typedesc[StarchError], msg: string, line: int = 0, context: string = "", col: int = 0, file: string = "<starch-input>"): StarchError =
    # Fancy error message
    var text = "File " & red("\"" & file & "\"") & ", line " & red($line)
    if context != "":
        let cleanContext = context.replace("\t", "    ")
        text.add("\n    " & cleanContext)
        if col > 0:
            let spaces = " ".repeat(cleanContext[0 ..< col - 1].len)
            text.add("\n    " & spaces & red("^"))

    # Strip "Starch" from error name
    let typeName = ($kind).replace("Starch", "").replace("ref ", "")
    text.add(&"\n{bold(red(typeName))}: {red(msg)}")

    result = kind(msg: text, line: line, context: context, col: col, file: file)

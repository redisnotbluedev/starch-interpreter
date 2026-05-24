from errors import StarchError, newStarchError
from std/os import paramStr, paramCount

proc main(): void =
    if paramCount() < 1:
        echo "Usage: starch <filename>"
        quit(1)

    let content = paramStr(1).readFile()

when isMainModule:
    try:
        main()
    except StarchError as e:
        stderr.writeLine(e.msg)
        quit(1)

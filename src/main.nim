from errors import StarchError, newStarchError
from lexer import newLexer, lex, `$`
from std/os import paramStr, paramCount
from std/monotimes import getMonoTime, `-`
from std/times import inNanoseconds
from std/strformat import `&`

proc main(): void =
    if paramCount() < 1:
        echo "Usage: starch <filename>"
        quit(1)

    # Lex the file
    let content = paramStr(1).readFile()
    let tokens = newLexer(content, paramStr(1)).lex()
    for t in tokens:
        echo $t

when isMainModule:
    try:
        let start = getMonoTime()
        main()
        let elapsed = (getMonoTime() - start).inNanoseconds
        echo()
        echo(&"Took {elapsed.float / 1_000_000.0}ms")
    except StarchError as e:
        # Return the error and quit gracefully
        stderr.writeLine(e.msg)
        quit(1)

import errors
import lexer
import tokens
import std/os
import std/monotimes
import std/times
import std/strformat

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

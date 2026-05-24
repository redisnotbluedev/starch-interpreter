import errors

proc main(): void =
     echo "STARCH is not actually implemented in Nim yet..."
     raise newStarchError(StarchSyntaxError, "Unexpected token", line=10, context="print(@@@)", col=7)

when isMainModule:
    try:
        main()
    except StarchError as e:
        stderr.writeLine(e.msg)
        quit(1)

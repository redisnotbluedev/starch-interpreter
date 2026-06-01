"""Used to generate src/unicode_tables.nim.
Extracts XID_Start and XID_Continue from Unicode's DerivedCoreProperties.txt and transforms into Nim code.
Should be re-generated every Unicode release."""

import urllib.request, pathlib

PROPERTIES = "https://www.unicode.org/Public/latest/ucd/DerivedCoreProperties.txt"

# Read latest Unicode properties
data = urllib.request.urlopen(PROPERTIES).read().decode("utf-8")
xid_start = []
xid_continue = []
text = "import std/unicode\nimport std/algorithm\n\n"

# Syntax:
# codepoint..codepoint ; core property # general category [total codepoints] CHARACTER NAME
# Or with only one codepoint:
# codepoint ; core property # general category CHARACTER NAME
for line in data.split("\n"):
	# XID_Start block — characters that variables can start with
	if "; XID_Start" in line:
		range_part = line.split(";")[0].strip()
		if ".." in range_part:
			start, end = range_part.split("..")
			xid_start.append((int(start, 16), int(end, 16)))
		else:
			val = int(range_part, 16)
			xid_start.append((val, val))
	# XID_Continue block — a superset of XID_Start
	elif "; XID_Continue" in line:
		range_part = line.split(";")[0].strip()
		if ".." in range_part:
			start, end = range_part.split("..")
			xid_continue.append((int(start, 16), int(end, 16)))
		else:
			val = int(range_part, 16)
			xid_continue.append((val, val))

# Generate Nim code
text += "const XID_Start_Ranges = ["
for start, end in xid_start:
	text += f"\n    (0x{start:04X}, 0x{end:04X}),"
text += "\n]"

text += "\nconst XID_Continue_Ranges = ["
for start, end in xid_continue:
	text += f"\n    (0x{start:04X}, 0x{end:04X}),"
text += "\n]"

text += """

proc cmpRange(rangeTuple: (int, int), key: int): int =
    ## Returns > 0 if key is below the range, < 0 if above, and 0 if inside.
    if key < rangeTuple[0]:
        # The target key is smaller than the lowest value in this range.
        return 1
    elif key > rangeTuple[1]:
        # The target key is larger than the highest value in this range.
        return -1
    else:
        # The key matches/falls within this range block.
        return 0

# std/algorithm.binarySearch returns the index if found, or -1 if not found.
# Uses binary search to check if it's there as fast as possible.
proc isXIDStart*(r: Rune): bool =
    let idx = XID_Start_Ranges.binarySearch(r.int, cmpRange)
    return idx >= 0

proc isXIDContinue*(r: Rune): bool =
    let idx = XID_Continue_Ranges.binarySearch(r.int, cmpRange)
    return idx >= 0
"""

# Assumes unicode_gen.py is in a tools/ directory (or similar) relative to the project root.
with open(pathlib.Path(__file__).parent.parent / "src" / "unicode_tables.nim", "w") as f:
	f.write(text)

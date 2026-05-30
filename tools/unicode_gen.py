"""Used to generate unicode_tables.nim.
Extracts XID_Start and XID_Continue from Unicode's DerivedCoreProperties.txt and transforms into Nim code.
Should be re-generated every Unicode release."""

import urllib.request, pathlib

PROPERTIES = "https://www.unicode.org/Public/latest/ucd/DerivedCoreProperties.txt"

# Read latest Unicode properties
data = urllib.request.urlopen(PROPERTIES).read().decode("utf-8")
xid_start = []
xid_continue = []
text = "import std/unicode\n\n"

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

proc binarySearch(ranges: openArray[(int, int)], target: int): bool =
    var left = 0
    var right = ranges.len - 1
    while left <= right:
        let mid = (left + right) div 2
        if target < ranges[mid][0]:
            right = mid - 1
        elif target > ranges[mid][1]:
            left = mid + 1
        else:
            return true
    false

proc isXIDStart*(r: Rune): bool =
    binarySearch(XID_Start_Ranges, r.int)

proc isXIDContinue*(r: Rune): bool =
    binarySearch(XID_Continue_Ranges, r.int)"""

# Assumes unicode_gen.py is in a tools/ directory (or similar) relative to the project root.
with open(pathlib.Path(__file__).parent.parent / "src" / "unicode_tables.nim", "w") as f:
	f.write(text)

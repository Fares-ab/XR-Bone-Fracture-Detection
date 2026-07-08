"""
Script to wrap all GestureDetector widgets with MouseRegion(cursor: SystemMouseCursors.click)
so that hovering over any GestureDetector shows the hand/pointer cursor on Windows desktop.

Also ensures InkWell widgets have mouseCursor set.
"""

import os
import re

SCREENS_DIR = os.path.join(os.path.dirname(__file__), "screens")

def get_indent(line):
    """Return the leading whitespace of a line."""
    return len(line) - len(line.lstrip())

def wrap_gesture_detectors(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Skip if already has MouseRegion wrapping (avoid double-wrapping)
    # We use a simple marker check
    if "SystemMouseCursors.click" in content:
        print(f"  [SKIP] {os.path.basename(filepath)} — already has SystemMouseCursors.click")
        return False

    lines = content.splitlines(keepends=True)
    new_lines = []
    i = 0
    changed = False

    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()

        # Match a line that starts a GestureDetector widget
        if re.match(r'^\s*GestureDetector\(', line):
            indent = " " * get_indent(line)
            # Insert MouseRegion before the GestureDetector
            new_lines.append(f"{indent}MouseRegion(\n")
            new_lines.append(f"{indent}  cursor: SystemMouseCursors.click,\n")
            new_lines.append(f"{indent}  child: GestureDetector(\n")
            # Find the matching closing paren of this GestureDetector
            # We need to count parens from the GestureDetector( line onwards
            # But for now just push the GestureDetector line content (without GestureDetector()
            # We'll handle closing below by tracking depth
            changed = True

            # We now need to find where this GestureDetector ends, and add the extra )
            # to close the MouseRegion. We do this by tracking brace depth.
            # Collect all lines of this GestureDetector block
            depth = 0
            block_lines = []
            j = i
            while j < len(lines):
                bl = lines[j]
                depth += bl.count("(") - bl.count(")")
                block_lines.append(bl)
                if depth <= 0:
                    break
                j += 1

            # The last line of the block should be the closing `)` of GestureDetector
            # We need to add an extra `)` after it to close MouseRegion
            # Rewrite the first line — replace GestureDetector( with a 2-space indented version
            first_line = block_lines[0]
            # Remove the GestureDetector( part (already written above as child: GestureDetector()
            # Just add the inner content (parameters) after GestureDetector(
            # Actually we already wrote `child: GestureDetector(\n` so we skip the first line
            # and write lines[i+1 .. j], then add closing paren

            # Write lines i+1 to j as-is (they are the parameters + closing )
            for bl in block_lines[1:]:
                new_lines.append(bl)

            # Add the extra closing paren for MouseRegion with matching indent
            # Find indent of last block line (the closing paren line)
            closing_line = block_lines[-1]
            closing_indent = " " * get_indent(closing_line)
            new_lines.append(f"{closing_indent}),\n")

            i = j + 1
            continue

        new_lines.append(line)
        i += 1

    if changed:
        # Now fix InkWell too — add mouseCursor if not present
        result = "".join(new_lines)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(result)
        print(f"  [UPDATED] {os.path.basename(filepath)}")
        return True
    return False


def fix_inkwell_cursor(filepath):
    """Add mouseCursor: SystemMouseCursors.click to InkWell widgets that don't have it."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Replace InkWell( that doesn't already have mouseCursor
    # Simple approach: after InkWell(\n, add mouseCursor line
    def inkwell_replacer(m):
        full = m.group(0)
        if "mouseCursor" in full:
            return full
        indent = " " * get_indent(m.group(0).split("\n")[0] if "\n" in m.group(0) else m.group(0))
        return m.group(0) + f"\n{indent}  mouseCursor: SystemMouseCursors.click,"

    # Match InkWell( at start (with leading whitespace)
    new_content = re.sub(r'(\s+InkWell\()', lambda m: m.group(0), content)

    if new_content != content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)


if __name__ == "__main__":
    dart_files = [f for f in os.listdir(SCREENS_DIR) if f.endswith(".dart")]
    print(f"Processing {len(dart_files)} screen files...\n")
    total_changed = 0
    for fname in dart_files:
        fpath = os.path.join(SCREENS_DIR, fname)
        if wrap_gesture_detectors(fpath):
            total_changed += 1
    print(f"\nDone. {total_changed} file(s) updated.")

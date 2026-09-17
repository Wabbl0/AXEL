#!/usr/bin/env python3
# String-aware GDScript comment stripper.
# Removes # and ## comments. Keeps # inside quotes / triple-quotes.
# Skips archive/. Run from repo root:
#   python AXEL/axel_project/tools/qa/strip_gd_comments.py

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKIP_PARTS = {"archive", ".godot"}


def strip_gd(src: str) -> str:
	out: list[str] = []
	i = 0
	n = len(src)
	mode = "code"  # code, dq, sq, tdq, tsq
	line: list[str] = []

	def flush_line(keep: bool) -> None:
		text = "".join(line).rstrip()
		line.clear()
		if keep and text != "":
			out.append(text)
		elif keep:
			out.append("")

	while i < n:
		ch = src[i]
		nxt = src[i + 1] if i + 1 < n else ""
		nxt2 = src[i + 2] if i + 2 < n else ""

		if mode == "code":
			if ch == '"' and nxt == '"' and nxt2 == '"':
				mode = "tdq"
				line.append('"""')
				i += 3
				continue
			if ch == "'" and nxt == "'" and nxt2 == "'":
				mode = "tsq"
				line.append("'''")
				i += 3
				continue
			if ch in "&^" and nxt == '"' and not (i + 2 < n and src[i + 2] == '"' and i + 3 < n and src[i + 3] == '"'):
				mode = "dq"
				line.append(ch)
				line.append(nxt)
				i += 2
				continue
			if ch in "&^" and nxt == "'":
				mode = "sq"
				line.append(ch)
				line.append(nxt)
				i += 2
				continue
			if ch == '"':
				mode = "dq"
				line.append(ch)
				i += 1
				continue
			if ch == "'":
				mode = "sq"
				line.append(ch)
				i += 1
				continue
			if ch == "#":
				# Drop the rest of this line (comment). Keep any code already on it.
				while i < n and src[i] not in "\n\r":
					i += 1
				if line:
					flush_line(True)
				else:
					line.clear()
				if i < n and src[i] == "\r":
					i += 1
				if i < n and src[i] == "\n":
					i += 1
				continue
			if ch == "\r":
				i += 1
				continue
			if ch == "\n":
				flush_line(True)
				i += 1
				continue
			line.append(ch)
			i += 1
			continue

		# string modes
		if ch == "\\" and i + 1 < n and mode in ("dq", "sq"):
			line.append(ch)
			line.append(src[i + 1])
			i += 2
			continue
		if mode == "tdq" and ch == '"' and nxt == '"' and nxt2 == '"':
			line.append('"""')
			mode = "code"
			i += 3
			continue
		if mode == "tsq" and ch == "'" and nxt == "'" and nxt2 == "'":
			line.append("'''")
			mode = "code"
			i += 3
			continue
		if mode == "dq" and ch == '"':
			line.append(ch)
			mode = "code"
			i += 1
			continue
		if mode == "sq" and ch == "'":
			line.append(ch)
			mode = "code"
			i += 1
			continue
		if ch == "\n":
			line.append(ch)
			i += 1
			continue
		if ch == "\r":
			i += 1
			continue
		line.append(ch)
		i += 1

	if line:
		flush_line(True)
	text = "\n".join(out)
	if src.endswith("\n") and not text.endswith("\n"):
		text += "\n"
	# Collapse runs of 3+ blank lines to 2.
	while "\n\n\n\n" in text:
		text = text.replace("\n\n\n\n", "\n\n\n")
	return text


def should_skip(path: Path) -> bool:
	return any(part in SKIP_PARTS for part in path.parts)


def main() -> None:
	files = sorted(p for p in ROOT.rglob("*.gd") if p.is_file() and not should_skip(p))
	changed = 0
	for path in files:
		original = path.read_text(encoding="utf-8")
		stripped = strip_gd(original)
		if stripped != original:
			path.write_text(stripped, encoding="utf-8", newline="\n")
			changed += 1
	print(f"strip_gd_comments: {changed}/{len(files)} files changed under {ROOT}")


if __name__ == "__main__":
	main()

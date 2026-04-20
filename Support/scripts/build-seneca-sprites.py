#!/usr/bin/env python3
"""Regenerate Seneca mascot sprite strips — round owl, big eyes, gray/cream palette.

Emits 40x44 per frame, 2 frames per state, written to
Sources/Perch/Resources/Mascots/Seneca/{idle,watching,alert,working}.png.

Tone legend:
    .   transparent
    H   head / outline (dark gray)   #3F424A
    F   face (cream)                 #C8C4BA
    C   cheek (mid gray)             #6E7078
    P   pupil (black)                #000000
    W   white accent (runtime-tinted to theme.primary)
    X   magenta accent (runtime-tinted to theme.secondary)

Idle: eyes closed + Zz on top. Alert: eyes wide open. Watching: pupil shift.
Working: half-lid. Body is round (ellipse) so the sprite reads as a round owl,
not a rectangle.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image

HEAD = (0x3F, 0x42, 0x4A, 0xFF)
FACE = (0xC8, 0xC4, 0xBA, 0xFF)
CHEEK = (0x6E, 0x70, 0x78, 0xFF)
PUPIL = (0x00, 0x00, 0x00, 0xFF)
WHITE = (0xFF, 0xFF, 0xFF, 0xFF)
MAGENTA = (0xFF, 0x00, 0xFF, 0xFF)
CLEAR = (0x00, 0x00, 0x00, 0x00)

TONE = {
    ".": CLEAR,
    "H": HEAD,
    "F": FACE,
    "C": CHEEK,
    "P": PUPIL,
    "W": WHITE,
    "X": MAGENTA,
}

FRAME_W = 20
FRAME_H = 22
SCALE = 2

ZZ_A = [
    "..............WWW...",
    "................W...",
]
ZZ_B = [
    "...............WWW..",
    ".................W..",
]
EMPTY_TOP = [
    "....................",
    "....................",
]
# Check mark (magenta accent — runtime-tinted to theme.secondary).
CHECK_A = [
    "..............X.....",
    ".............XX.X...",
]
CHECK_B = [
    "..............X.....",
    "............XXXXX...",
]

# Eye panels (3 cols × 3 rows) inserted at cols 4-6 (left) and 13-15 (right).
EYE_ALERT = ["WWW", "WPW", "WWW"]
EYE_WATCH_L = ["WWW", "WWP", "WWW"]
EYE_WATCH_R = ["WWW", "PWW", "WWW"]
EYE_WORK = ["HHH", "WPW", "WWW"]
EYE_CLOSED_A = ["FFF", "PPP", "FFF"]
EYE_CLOSED_B = ["FFF", "HHH", "FFF"]
EYE_WINK_OPEN = ["WWW", "WPW", "WWW"]
EYE_WINK_SHUT = ["FFF", "HHH", "FFF"]

BODY_TOP = [
    "........HHHH........",  # row 2
    "......HHFFFFHH......",  # row 3
    ".....HHFFFFFFFFHH...",  # row 4  (kept 20 cols)
    "....HHFFFFFFFFFFHH..",  # row 5
    "...HHFFFFFFFFFFFFHH.",  # row 6
    "..HHFFFFFFFFFFFFFFHH",  # row 7
    ".HHFFFFFFFFFFFFFFFFH",  # row 8
]

# row 4-8 must each be exactly 20 chars. Recompute.
BODY_TOP = [
    "........HHHH........",
    "......HHFFFFHH......",
    ".....HFFFFFFFFH.....",
    "....HFFFFFFFFFFH....",
    "...HFFFFFFFFFFFFH...",
    "..HFFFFFFFFFFFFFFH..",
    ".HFFFFFFFFFFFFFFFFH.",
]

# Eye rows (3 rows) — composed per frame.
def eye_row(left: str, right: str) -> str:
    assert len(left) == 3 and len(right) == 3
    row = ".HFF" + left + "FFFFFF" + right + "FFH."
    assert len(row) == 20, row
    return row

BEAK = [
    ".HFFFFFFFXXFFFFFFFH.",
    ".HFFFFFFFXXFFFFFFFH.",
]

BODY_BOTTOM = [
    ".HFFFFFFFFFFFFFFFFH.",
    ".HFFFFFFFFFFFFFFFFH.",
    "..HFFFFFFFFFFFFFFH..",
    "...HFFFFFFFFFFFFH...",
    "....HFFFFFFFFFFH....",
    ".....HHFFFFFFHH.....",
    "......HHHHHHHH......",
]

FEET = [
    "........HH..HH......",
    "........HH..HH......",
]


def build_frame(top: list[str], eyes: list[str]) -> list[str]:
    assert len(top) == 2
    assert len(eyes) == 3
    rows: list[str] = []
    rows.extend(top)                           # 2 rows (0-1)
    rows.extend(BODY_TOP)                      # 7 rows (2-8)
    rows.append(eye_row(eyes[0], eyes[0]))     # row 9
    rows.append(eye_row(eyes[1], eyes[1]))     # row 10
    rows.append(eye_row(eyes[2], eyes[2]))     # row 11
    rows.extend(BEAK)                          # rows 12-13
    rows.extend(BODY_BOTTOM)                   # 7 rows (14-20)
    rows.extend(FEET[:1])                      # row 21
    if len(rows) != FRAME_H:
        raise AssertionError(f"frame has {len(rows)} rows, want {FRAME_H}")
    return rows


def build_watching_frame(top: list[str], left: list[str], right: list[str]) -> list[str]:
    rows: list[str] = []
    rows.extend(top)
    rows.extend(BODY_TOP)
    rows.append(eye_row(left[0], right[0]))
    rows.append(eye_row(left[1], right[1]))
    rows.append(eye_row(left[2], right[2]))
    rows.extend(BEAK)
    rows.extend(BODY_BOTTOM)
    rows.extend(FEET[:1])
    if len(rows) != FRAME_H:
        raise AssertionError(f"frame has {len(rows)} rows, want {FRAME_H}")
    return rows


IDLE_A = build_frame(ZZ_A, EYE_CLOSED_A)
IDLE_B = build_frame(ZZ_B, EYE_CLOSED_B)
ALERT_A = build_frame(EMPTY_TOP, EYE_ALERT)
ALERT_B = build_frame(EMPTY_TOP, ["WWW", "WPW", "HHH"])  # subtle squint
WATCHING_A = build_watching_frame(EMPTY_TOP, EYE_WATCH_R, EYE_WATCH_R)
WATCHING_B = build_watching_frame(EMPTY_TOP, EYE_WATCH_L, EYE_WATCH_L)
WORKING_A = build_frame(EMPTY_TOP, EYE_WORK)
WORKING_B = build_frame(EMPTY_TOP, ["WWW", "WPW", "HHH"])
FINISHED_A = build_watching_frame(CHECK_A, EYE_WINK_SHUT, EYE_WINK_OPEN)
FINISHED_B = build_watching_frame(CHECK_B, EYE_WINK_OPEN, EYE_WINK_SHUT)

STATES = {
    "idle": (IDLE_A, IDLE_B),
    "watching": (WATCHING_A, WATCHING_B),
    "alert": (ALERT_A, ALERT_B),
    "working": (WORKING_A, WORKING_B),
    "finished": (FINISHED_A, FINISHED_B),
}


def render_frame(grid: list[str]) -> Image.Image:
    if len(grid) != FRAME_H:
        raise ValueError(f"frame must be {FRAME_H} rows, got {len(grid)}")
    img = Image.new("RGBA", (FRAME_W, FRAME_H), CLEAR)
    pixels = img.load()
    for y, row in enumerate(grid):
        if len(row) != FRAME_W:
            raise ValueError(f"row {y} must be {FRAME_W} cols, got {len(row)}: {row!r}")
        for x, ch in enumerate(row):
            pixels[x, y] = TONE[ch]
    return img


def render_strip(frames: tuple[list[str], list[str]]) -> Image.Image:
    a = render_frame(frames[0])
    b = render_frame(frames[1])
    strip = Image.new("RGBA", (FRAME_W * 2, FRAME_H), CLEAR)
    strip.paste(a, (0, 0))
    strip.paste(b, (FRAME_W, 0))
    return strip.resize((FRAME_W * 2 * SCALE, FRAME_H * SCALE), Image.NEAREST)


def main() -> None:
    here = Path(__file__).resolve().parent
    out_dir = here.parent.parent / "Sources" / "Perch" / "Resources" / "Mascots" / "Seneca"
    out_dir.mkdir(parents=True, exist_ok=True)

    for state, frames in STATES.items():
        strip = render_strip(frames)
        path = out_dir / f"{state}.png"
        strip.save(path, format="PNG")
        print(f"wrote {path} ({strip.width}x{strip.height})")


if __name__ == "__main__":
    main()

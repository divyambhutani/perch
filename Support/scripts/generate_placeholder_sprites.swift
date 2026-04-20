#!/usr/bin/env swift

// Generates Seneca sprites at 16x18 per frame, 2 frames per state, as 32x18 PNG strips.
//
// Body palette (fixed — never theme-shifted):
//   head   charcoal      #3F424A
//   face   light grey    #C8C4BA
//   cheek  mid grey      #6E7078
//   pupil  black         #000000
// Accent palette (runtime LUT in SpriteAccentRenderer):
//   primary marker       #FFFFFF  → theme.primary   (eye rings, feet)
//   secondary marker     #FF00FF  → theme.secondary (beak)
// Clear pixels are fully transparent.

import AppKit
import UniformTypeIdentifiers

let frameW = 16
let frameH = 18

struct RGBA {
    let r: UInt8; let g: UInt8; let b: UInt8; let a: UInt8
    static let clear   = RGBA(r: 0x00, g: 0x00, b: 0x00, a: 0x00)
    static let head    = RGBA(r: 0x3F, g: 0x42, b: 0x4A, a: 0xFF)
    static let face    = RGBA(r: 0xC8, g: 0xC4, b: 0xBA, a: 0xFF)
    static let cheek   = RGBA(r: 0x6E, g: 0x70, b: 0x78, a: 0xFF)
    static let pupil   = RGBA(r: 0x00, g: 0x00, b: 0x00, a: 0xFF)
    static let primary = RGBA(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF)
    static let second  = RGBA(r: 0xFF, g: 0x00, b: 0xFF, a: 0xFF)
}

// Pixel chars: '.' clear  '#' head  'L' face  'C' cheek  'B' pupil  'P' primary  'S' secondary
func pixels(from rows: [String]) -> [RGBA] {
    precondition(rows.count == frameH, "need \(frameH) rows, got \(rows.count)")
    var out: [RGBA] = []
    out.reserveCapacity(frameW * frameH)
    for row in rows {
        let chars = Array(row)
        precondition(chars.count == frameW, "need \(frameW) cols, got \(chars.count): \(row)")
        for c in chars {
            switch c {
            case "#": out.append(.head)
            case "L": out.append(.face)
            case "C": out.append(.cheek)
            case "B": out.append(.pupil)
            case "P": out.append(.primary)
            case "S": out.append(.second)
            default:  out.append(.clear)
            }
        }
    }
    return out
}

// Reference frame mirrors the screenshot: ear-tufted owl, light face mask,
// round eye rings around black pupils, gold beak, light belly, cheek dots, feet.
let referenceFrame: [String] = [
    "................",  // 0
    "...##......##...",  // 1  ear tufts
    "..####....####..",  // 2
    "..############..",  // 3  head cap
    ".##############.",  // 4  head widest
    ".##LLLLLLLLLL##.",  // 5  face mask top
    ".##LPPLLLLPPL##.",  // 6  eye rings upper
    ".##LPBPLLPBPL##.",  // 7  pupils
    ".##LPPLSSLPPL##.",  // 8  eye rings lower + beak top
    ".##LLLLSSLLLL##.",  // 9  beak lower
    ".##LLLLLLLLLL##.",  // 10 belly upper
    ".##CLLLLLLLLC##.",  // 11 cheeks
    ".##LLLLLLLLLL##.",  // 12 belly lower
    "..############..",  // 13 jawline
    "...##########...",  // 14 neck narrow
    "....LLLLLLLL....",  // 15 belly patch
    "....PP....PP....",  // 16 feet
    "................"   // 17
]

// --- Per-state frame variants ---
// Mutate specific rows/cols off the reference to animate without redrawing whole frames.

func withRowEdit(_ rows: [String], row: Int, edit: (inout [Character]) -> Void) -> [String] {
    var out = rows
    var chars = Array(out[row])
    edit(&chars)
    out[row] = String(chars)
    return out
}

// idle: gentle blink. Frame 2 closes eyes — pupils row becomes primary line across rings.
let idleOpen = referenceFrame
let idleClosed = withRowEdit(referenceFrame, row: 7) { chars in
    // ".##LPBPLLPBPL##." → replace B with P (eyelid closes over pupil)
    chars[5]  = "P"
    chars[10] = "P"
}

// watching: slow eye scan. Shift pupils left 1 col then right 1 col.
let watchingLeft = withRowEdit(referenceFrame, row: 7) { chars in
    // default pupils at 5 and 10; shift to 4 and 9
    chars[4]  = "B"; chars[5]  = "P"
    chars[9]  = "B"; chars[10] = "P"
}
let watchingRight = withRowEdit(referenceFrame, row: 7) { chars in
    // shift to 6 and 11
    chars[5]  = "P"; chars[6]  = "B"
    chars[10] = "P"; chars[11] = "B"
}

// alert: eyes wide. Rings expand outward one column each side on row 6 + row 8.
func widenRings(_ rows: [String]) -> [String] {
    var out = rows
    out = withRowEdit(out, row: 6) { chars in
        // ".##LPPLLLLPPL##." → ".##PPPLLLLPPPL##. wait that breaks length.
        // Keep widths: just bake inner face pixel adjacent to ring into primary.
        chars[6]  = "P"
        chars[9]  = "P"
    }
    out = withRowEdit(out, row: 8) { chars in
        chars[6]  = "P"
        chars[9]  = "P"
    }
    return out
}
let alertA = referenceFrame
let alertB = widenRings(referenceFrame)

// working: looks down. Pupils drop one row; row 7 becomes face, row 8 gets pupils.
func lookDown(_ rows: [String]) -> [String] {
    var out = rows
    out = withRowEdit(out, row: 7) { chars in
        // restore pupils to face
        chars[5]  = "P"
        chars[10] = "P"
    }
    out = withRowEdit(out, row: 8) { chars in
        // ".##LPPLSSLPPL##." — replace left-ring's bottom-right P and right-ring's bottom-left P with pupils.
        // Pupils drop into row 8's ring bottom: positions 5 and 10 currently 'P' — flip to 'B'.
        chars[5]  = "B"
        chars[10] = "B"
    }
    return out
}
let workingA = lookDown(referenceFrame)
let workingB: [String] = {
    // second beat of look-down: pupils drift further inward.
    var rows = lookDown(referenceFrame)
    rows = withRowEdit(rows, row: 8) { chars in
        // move pupils from 5,10 to 6,9
        chars[5] = "P"; chars[6] = "B"
        chars[9] = "B"; chars[10] = "P"
    }
    return rows
}()

let frames: [(String, [[String]])] = [
    ("idle",     [idleOpen, idleClosed]),
    ("watching", [watchingLeft, watchingRight]),
    ("alert",    [alertA, alertB]),
    ("working",  [workingA, workingB])
]

// --- PNG writer ----------------------------------------------------------

func writePNG(frames twoFrames: [[RGBA]], to url: URL) throws {
    let stripW = frameW * 2
    let stripH = frameH
    var flat = [UInt8](repeating: 0, count: stripW * stripH * 4)

    for (idx, frame) in twoFrames.enumerated() {
        for y in 0..<frameH {
            for x in 0..<frameW {
                let src = frame[y * frameW + x]
                let dstX = idx * frameW + x
                let offset = (y * stripW + dstX) * 4
                flat[offset + 0] = src.r
                flat[offset + 1] = src.g
                flat[offset + 2] = src.b
                flat[offset + 3] = src.a
            }
        }
    }

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: stripW,
        pixelsHigh: stripH,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [.alphaNonpremultiplied],
        bytesPerRow: stripW * 4,
        bitsPerPixel: 32
    ) else {
        throw NSError(domain: "SenecaSprites", code: 1, userInfo: [NSLocalizedDescriptionKey: "NSBitmapImageRep alloc failed"])
    }

    guard let planes = rep.bitmapData else {
        throw NSError(domain: "SenecaSprites", code: 2, userInfo: [NSLocalizedDescriptionKey: "bitmapData nil"])
    }
    flat.withUnsafeBufferPointer { buf in
        planes.update(from: buf.baseAddress!, count: buf.count)
    }

    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "SenecaSprites", code: 3, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
    }
    try png.write(to: url)
}

// --- Driver --------------------------------------------------------------

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: generate_placeholder_sprites.swift <output-dir>\n".utf8))
    exit(2)
}
let outDir = URL(fileURLWithPath: args[1])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for (state, frameRows) in frames {
    let twoFrames = frameRows.map { pixels(from: $0) }
    let url = outDir.appendingPathComponent("\(state).png")
    try writePNG(frames: twoFrames, to: url)
    print("wrote \(url.path)")
}

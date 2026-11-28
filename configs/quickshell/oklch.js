.pragma library

// sRGB ↔ OKLCH for the color picker, the same matrices as tools/oklab.py
// (Björn Ottosson's). The picker moves lightness, chroma and hue, because in
// OKLab equal steps look like equal changes; it stores plain #RRGGBB.

function toLinear(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
function fromLinear(c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055 }

// "#RRGGBB" → { L: 0…1, C: 0…~0.37, h: 0…360 }
function fromHex(hex) {
    const n = hex.replace("#", "")
    const r = toLinear(parseInt(n.slice(0, 2), 16) / 255)
    const g = toLinear(parseInt(n.slice(2, 4), 16) / 255)
    const b = toLinear(parseInt(n.slice(4, 6), 16) / 255)
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    const L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720420 * s
    const A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    const B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    const h = Math.atan2(B, A) * 180 / Math.PI
    return { L: L, C: Math.hypot(A, B), h: h < 0 ? h + 360 : h }
}

// { L, C, h } → { hex: "#RRGGBB", inGamut: bool }. Outside sRGB, each channel
// is clipped (as oklab.py does), and inGamut says so.
function toHex(L, C, h) {
    const a = C * Math.cos(h * Math.PI / 180), b = C * Math.sin(h * Math.PI / 180)
    const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3)
    const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3)
    const s = Math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3)
    const rgb = [
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    ]
    const eps = 1e-4
    const inGamut = rgb.every(c => c >= -eps && c <= 1 + eps)
    const hex = "#" + rgb.map(c => {
        const v = Math.round(Math.max(0, Math.min(1, fromLinear(Math.max(0, c)))) * 255)
        return (v < 16 ? "0" : "") + v.toString(16).toUpperCase()
    }).join("")
    return { hex: hex, inGamut: inGamut }
}

function isHex(s) { return /^#[0-9A-Fa-f]{6}$/.test(s) }

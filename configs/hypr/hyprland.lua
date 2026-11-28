-- ── Warm Terminal / Cozy Archive — Hyprland (Lua config, Hyprland ≥ 0.57) ────
-- Paper on a desk: windows are parchment cards on a wooden desk (Quickshell
-- draws the wallpaper), each with cut corners, a bevelled edge lit from the
-- top left, and a hard shadow falling down-right. Every gap on screen is the
-- same 8px (2 × the 4px unit); the bar and menus follow the same rules.

-- ── Settings ────────────────────────────────────────────────────────────────
-- Written by apply.py from ~/.config/cozy-archive/settings.json; change them
-- from the settings menu (SUPER+comma). Defaults if it hasn't run yet.
-- dofile, not require: require caches, and these change while Hyprland runs.
local confdir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local ok, settings = pcall(dofile, confdir .. "/hypr/settings.lua")
if not ok or type(settings) ~= "table" then settings = {} end
local mode = settings.mode == "dark" and "dark" or "light"

-- Palette (both modes) — generated from tokens.toml.
local c = require("./colors.lua")[mode]

-- ── Keyboard ────────────────────────────────────────────────────────────────
-- Sets the typing layout and the focus keys, which sit where vim's h/j/k/l
-- physically are (qwerty H J K L, dvorak D H T N):
--   "qwerty"         a plain keyboard, typing QWERTY
--   "dvorak"         a plain keyboard; Hyprland remaps it to Dvorak
--   "dvorak-native"  the keyboard itself sends Dvorak (QMK/ZMK firmware), so
--                    Hyprland must NOT remap it again; Dvorak focus keys only
-- `lock` is SUPER+L, except on QWERTY, where L is already "focus right".
local keyboard = settings.keyboard or "dvorak-native"

local layouts = {
    ["qwerty"]        = { variant = "",       left = "H", down = "J", up = "K", right = "L", lock = "SHIFT + L" },
    ["dvorak"]        = { variant = "dvorak", left = "D", down = "H", up = "T", right = "N", lock = "L" },
    ["dvorak-native"] = { variant = "",       left = "D", down = "H", up = "T", right = "N", lock = "L" },
}
local kb = assert(layouts[keyboard],
    "keyboard must be \"qwerty\", \"dvorak\" or \"dvorak-native\"")

-- ── Monitors ────────────────────────────────────────────────────────────────
-- `preferred` auto-detects; for a real machine add one per output, e.g.
--   hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- ── Autostart ───────────────────────────────────────────────────────────────
-- apply.py --startup links the right day/night files and makes sure the
-- wallpaper for this screen size exists; Quickshell draws it, plus the bar,
-- the launcher and the settings menu.
local share = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")) .. "/cozy-archive"
hl.on("hyprland.start", function()
    hl.exec_cmd("python3 " .. share .. "/apply.py --startup; quickshell")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")       -- locks on idle and before sleep (hypridle.conf)
end)

-- A border that's flat-shaded, not smoothly blended: five stops of the lit
-- color then five of the shaded one (10 is Hyprland's maximum), so the 45°
-- gradient is solid on each side and only blends in a thin band across the
-- diagonal — a bevel with two faces, like low-poly geometry.
local function faceted(lit, shade)
    return { colors = { lit, lit, lit, lit, lit, shade, shade, shade, shade, shade }, angle = 45 }
end

-- ── Look & feel ─────────────────────────────────────────────────────────────
hl.config({
    general = {
        gaps_in          = 4,      -- per side, so 8 between two windows
        gaps_out         = 8,      -- screen edge and bar → window
        border_size      = 2,
        -- Light from the top left (the shadows fall down-right): the top and
        -- left faces of each border are lit, the bottom and right in shade.
        col = {
            active_border   = faceted(c.rgb.focusBorder, c.rgb.focusBorderShade),
            inactive_border = faceted(c.rgb.highlight,   c.rgb.shadow),
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        -- Cut corners: rounding_power = 1 makes the corner "curve" a straight
        -- 45° line, so an 8px rounding is an 8px chamfer — the low-poly corner.
        -- The border and the shadow follow the same shape.
        rounding       = 8,
        rounding_power = 1,
        -- No blur: paper, not glass. The shadow is sharp and offset, like a
        -- card resting on a desk, not a glow.
        blur   = { enabled = false },
        shadow = {
            enabled = true,
            sharp   = true,
            range   = 0,          -- no spread: exactly the window's shape…
            offset  = { 4, 4 },   -- …moved one unit down-right
            color   = c.shadow,
        },
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = c.desk,   -- under the wallpaper, if it's missing
    },

    input = {
        kb_layout    = "us",
        kb_variant   = kb.variant,
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad     = { natural_scroll = true },
    },
})

-- Snappy, mechanical — nothing bouncy. (speed is in deciseconds)
hl.curve("crisp", { type = "bezier", points = { {0.2, 0.0}, {0.2, 1.0} } })
hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "crisp" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "crisp" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "crisp", style = "slide" })
hl.animation({ leaf = "border",     enabled = true, speed = 4, bezier = "crisp" })

-- ── Keybinds ────────────────────────────────────────────────────────────────
local mod  = "SUPER"
local term = "kitty"
local function key(k) return mod .. " + " .. k end

hl.bind(key("Return"), hl.dsp.exec_cmd(term))
hl.bind(key("Q"),      hl.dsp.window.close())
hl.bind(key("M"),      hl.dsp.exit())
hl.bind(key("E"),      hl.dsp.exec_cmd(term .. " --class yazi -e yazi"))   -- files: yazi, themed from tokens
hl.bind(key("V"),      hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("F"),      hl.dsp.window.fullscreen())
hl.bind(key("Space"),  hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(key("comma"),  hl.dsp.exec_cmd("quickshell ipc call settings toggle"))
-- Lock: Quickshell's login card (Lock.qml). Through logind, so hypridle and
-- anything else that locks the session all land in the same place.
-- (Not SUPER+Escape: VM viewers keep that one for themselves.)
hl.bind(key(kb.lock), hl.dsp.exec_cmd("pgrep -x hypridle >/dev/null && loginctl lock-session || quickshell ipc call lock lock"))

-- Focus (vim positions for the chosen keyboard, + arrows)
for _, pair in ipairs({
    { kb.left, "left" }, { kb.down, "down" }, { kb.up, "up" }, { kb.right, "right" },
    { "left", "left" }, { "right", "right" }, { "up", "up" }, { "down", "down" },
}) do
    hl.bind(key(pair[1]), hl.dsp.focus({ direction = pair[2] }))
end

-- Workspaces 1–5 (match the bar's numbered squares)
for i = 1, 5 do
    hl.bind(key(i),              hl.dsp.focus({ workspace = i }))
    hl.bind(key("SHIFT + " .. i), hl.dsp.window.move({ workspace = i }))
end

-- Mouse drag move/resize
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- ── Window rules ────────────────────────────────────────────────────────────
-- Apps don't get to maximize themselves; the tiling layout decides sizes.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- ── Warm Terminal / Cozy Archive — Hyprland (Lua config, Hyprland ≥ 0.57) ────
-- Paper on a desk: windows are parchment cards on a darker desk, each with a
-- hard offset shadow. Every gap on screen is the same 8px (2 × the 4px unit);
-- the bar (Quickshell) follows the same rules.

-- Palette (lit/shaded edges, desk, shadow) — generated from tokens.toml.
local c = require("./colors.lua")

-- ── Keyboard: the one switch ─────────────────────────────────────────────────
-- Sets the typing layout and the focus keys, which sit where vim's h/j/k/l
-- physically are (qwerty H J K L, dvorak D H T N):
--   "qwerty"         a plain keyboard, typing QWERTY
--   "dvorak"         a plain keyboard; Hyprland remaps it to Dvorak
--   "dvorak-native"  the keyboard itself sends Dvorak (QMK/ZMK firmware), so
--                    Hyprland must NOT remap it again; Dvorak focus keys only
local keyboard = "dvorak-native"

local layouts = {
    ["qwerty"]        = { variant = "",       left = "H", down = "J", up = "K", right = "L" },
    ["dvorak"]        = { variant = "dvorak", left = "D", down = "H", up = "T", right = "N" },
    ["dvorak-native"] = { variant = "",       left = "D", down = "H", up = "T", right = "N" },
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
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("mako")
end)

-- ── Look & feel ─────────────────────────────────────────────────────────────
hl.config({
    general = {
        gaps_in          = 4,      -- per side, so 8 between two windows
        gaps_out         = 8,      -- screen edge and bar → window
        border_size      = 2,
        -- Light from the top left (the shadows fall down-right): each border
        -- runs from its lit color at the top-left corner to its shaded color
        -- at the bottom-right (45° = that diagonal in Hyprland's gradients).
        col = {
            active_border   = { colors = { c.rgb.focusBorder, c.rgb.focusBorderShade }, angle = 45 },
            inactive_border = { colors = { c.rgb.border,      c.rgb.borderShade      }, angle = 45 },
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 0,           -- square corners everywhere
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
        background_color         = c.desk,
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
hl.bind(key("E"),      hl.dsp.exec_cmd("nautilus"))
hl.bind(key("V"),      hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("F"),      hl.dsp.window.fullscreen())
hl.bind(key("Space"),  hl.dsp.exec_cmd("wofi --show drun"))

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

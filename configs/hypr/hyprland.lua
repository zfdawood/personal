-- ── Warm Terminal / Cozy Archive — Hyprland (Lua config, Hyprland ≥ 0.57) ────
-- Square, thick-bordered, no rounding. Rust-amber active edge on deep-parchment.

-- Palette: accent, borderStrong, bgPrimary — generated from tokens.toml.
local c = require("./colors.lua")

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
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col = {
            active_border   = c.accent,
            inactive_border = c.borderStrong,
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 0,           -- square corners everywhere
        -- Restraint: no blur, no shadow — physical equipment, not glass.
        blur   = { enabled = false },
        shadow = { enabled = false },
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
        background_color         = c.bgPrimary,
    },

    input = {
        kb_layout    = "us",
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

-- Focus (vim + arrows)
for _, pair in ipairs({
    { "H", "left" }, { "L", "right" }, { "K", "up" }, { "J", "down" },
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

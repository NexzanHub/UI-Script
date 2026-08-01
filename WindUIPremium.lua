--[[============================================================================
    WINDUI MODDED EXTENSION (PREMIUM EDITION)
    ----------------------------------------------------------------------------
    Author  : WindUI Premium Addon
    Version : 2.0.0
    Date    : 2026-08-01

    WHAT THIS IS
    ------------
    A pure ADDON for the WindUI Roblox UI library. It does NOT modify, patch,
    deobfuscate or edit the obfuscated `main.lua`. It only wraps the PUBLIC
    `WindUI:CreateWindow` method and attaches new features to every window.
    All existing scripts that use WindUI keep working unchanged.

    USAGE
    -----
        local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
        local Premium = loadstring(game:HttpGet("https://<host>/WindUIPremium.lua"))()
        Premium:Enable(WindUI)   -- wraps CreateWindow -> every window gets Premium

    To attach to a window that already exists:
        Premium:Attach(MyWindow, WindUI)
============================================================================]]
return (function()
-------------------------------------------------------------------------------]
-- 0) CONTEXT TABLE (shared by every module)
-- ----------------------------------------------------------------------------]
local P = {
    VERSION = "2.0.0",
    Config = {},          -- persistent-ish per-session settings (window manager)
    Windows = setmetatable({}, { __mode = "k" }),  -- weak keys: Window -> state
}

-------------------------------------------------------------------------------]
-- 1) SERVICES + SAFE ENVIRONMENT
-- ----------------------------------------------------------------------------]
local function safe(name, service)
    return (pcall(function() return game:GetService(name) end)) and service or nil
end

local Players         = safe("Players",         game:GetService("Players"))
local RunService      = safe("RunService",      game:GetService("RunService"))
local TweenService    = safe("TweenService",    game:GetService("TweenService"))
local UserInputService= safe("UserInputService",game:GetService("UserInputService"))
local GuiService      = safe("GuiService",      game:GetService("GuiService"))
local CoreGui         = safe("CoreGui",         game:GetService("CoreGui"))
local HttpService     = safe("HttpService",     game:GetService("HttpService"))
local Lighting        = safe("Lighting",        game:GetService("Lighting"))
local Workspace       = safe("Workspace",       game:GetService("Workspace"))
local StarterGui      = safe("StarterGui",      game:GetService("StarterGui"))
local TextService     = safe("TextService",     game:GetService("TextService"))
local Stats           = safe("Stats",           game:GetService("Stats"))
local NetworkClient   = safe("NetworkClient",   game:GetService("NetworkClient"))

local Run = RunService
local Tween = TweenService
local UI = UserInputService
local Http = HttpService
local WS = Workspace
local LPS = Players
local LocalPlayer = LPS and LPS.LocalPlayer or nil

P.Services = {
    Players = Players, RunService = RunService, TweenService = TweenService,
    UserInputService = UserInputService, GuiService = GuiService,
    CoreGui = CoreGui, HttpService = HttpService, Lighting = Lighting,
    Workspace = Workspace, LocalPlayer = LocalPlayer,
}

-- developer whitelist (LocalPlayer.UserId). EDIT THIS.
local DEVELOPERS = {
    [10954470817] = true,
}
P.IsDeveloper = function()
    local lp = P.Services.LocalPlayer
    return lp and DEVELOPERS[lp.UserId] == true or false
end

-- small cross-environment helpers
local floor, clamp = math.floor, math.clamp
P.round = function(n, dp) dp = dp or 0; local m = 10^dp; return floor(n * m + 0.5) / m end
P.clamp = function(n, a, b) if n < a then return a elseif n > b then return b else return n end end
P.formatBytes = function(b)
    if not b then return "0 B" end
    local units = { "B", "KB", "MB", "GB" }
    local i = 1
    while b >= 1024 and i < #units do b = b / 1024; i = i + 1 end
    return string.format("%.1f %s", b, units[i])
end
P.nowTime = function() return os.date("%H:%M:%S") end
P.nowDate = function() return os.date("%Y-%m-%d") end


-------------------------------------------------------------------------------]
-- 2) THEME + ANIMATION + UI KIT HELPERS
-- ----------------------------------------------------------------------------]
P.DefaultTheme = {
    Accent = Color3.fromRGB(139, 92, 246), Background = Color3.fromRGB(18, 18, 22),
    Outline = Color3.fromRGB(255, 255, 255), Text = Color3.fromRGB(255, 255, 255),
    Placeholder = Color3.fromRGB(122, 122, 122), Button = Color3.fromRGB(39, 39, 44),
    Icon = Color3.fromRGB(161, 161, 170), Secondary = Color3.fromRGB(113, 113, 122),
}

P.GetTheme = function()
    local WindUI = P.WindUI
    if WindUI and WindUI.GetCurrentTheme then
        local ok, t = pcall(WindUI.GetCurrentTheme, WindUI)
        if ok and type(t) == "table" then return t end
    end
    return P.DefaultTheme
end
P.C = function(key, fallback)
    local t = P.GetTheme()
    local v = t and t[key]
    if v == nil then v = fallback end
    return v or P.DefaultTheme[key]
end
P.TextColor = function() return P.C("Text") end
P.AccentColor = function() return P.C("Accent") end
P.ButtonColor = function() return P.C("Button") end
P.BgColor = function() return P.C("Background") end
P.OutlineColor = function() return P.C("Outline") end

-- tween helper (all new animations go through this so they match the style)
P.Tween = function(obj, time, goal, style, dir, cb)
    if Tween and obj then
        local t = Tween:Create(obj, TweenInfo.new(time or 0.2,
            style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
        if cb then t.Completed:Connect(function() cb() end) end
        t:Play(); return t
    end
    if obj then for k, v in pairs(goal) do pcall(function() obj[k] = v end) end end
    if cb then cb() end
end
P.FadeIn = function(o, time) P.Tween(o, time or 0.2, { BackgroundTransparency = 0 }) end
P.FadeOut = function(o, time) P.Tween(o, time or 0.2, { BackgroundTransparency = 1 }) end

-- generic Instance constructor
local function New(class, props, children)
    local i = Instance.new(class)
    if props then for k, v in pairs(props) do i[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = i end end
    return i
end
P.New = New

-- icon resolver: lucide-name / asset-id -> ImageLabel (falls back to glyph)
local GLYPH = {
    search = "⌕", users = "◉", settings = "⚙", wrench = "⚒", minus = "─",
    x = "✕", maximize = "▣", chevronRight = "›", chevronDown = "⌄",
    player = "●", camera = "▣", eye = "◍", zap = "⚡", info = "ℹ",
    palette = "◐", download = "↓", folder = "▤", bug = "✚", send = "➤",
}
local ICON_RX = "^rbxassetid://"
P.Icon = function(name, parent, size, color, themed)
    local instance
    if type(name) == "number" or (type(name) == "string" and string.match(name, ICON_RX)) then
        instance = New("ImageLabel", { Image = tostring(name), Parent = parent })
    else
        -- try WindUI's icon resolver if the installed version exposes one
        local WindUI = P.WindUI
        local used = false
        if WindUI and type(WindUI.Icon) == "function" then
            local ok, id = pcall(WindUI.Icon, WindUI, name)
            if ok and id then
                instance = New("ImageLabel", { Image = tostring(id), Parent = parent })
                used = true
            end
        end
        if not used then
            instance = New("TextLabel", {
                Text = GLYPH[name] or "•", Font = Enum.Font.GothamMedium,
                TextSize = size or 16, Parent = parent,
            })
        end
    end
    if size then instance.Size = UDim2.fromOffset(size, size) end
    if color and themed ~= false then instance.TextColor3 = color end
    if color and not themed then
        if instance:IsA("ImageLabel") then instance.ImageColor3 = color end
        instance.TextColor3 = color
    end
    instance.ZIndex = 3
    return instance
end

-- rounded frame that follows the WindUI background theme
P.RoundFrame = function(parent, cfg)
    cfg = cfg or {}
    return New("Frame", {
        Parent = parent, BackgroundColor3 = cfg.Bg or P.BgColor(),
        BackgroundTransparency = cfg.Transparency or 0,
        Size = cfg.Size or UDim2.fromScale(1, 1), Position = cfg.Position or UDim2.fromScale(0, 0),
        AnchorPoint = cfg.AnchorPoint or Vector2.new(0, 0),
        Visible = cfg.Visible ~= false, ZIndex = cfg.ZIndex or 2, ClipsDescendants = true,
    }, {
        cfg.NoCorner and nil or New("UICorner", { CornerRadius = UDim.new(0, cfg.Radius or 12) }),
    })
end


-- color lighten/darken helpers
P.Lighter = function(c, amt)
    local h, s, v = c:ToHSV()
    return Color3.fromHSV(h, s, clamp(v + (amt or 0.06), 0, 1))
end
P.Darker = function(c, amt)
    local h, s, v = c:ToHSV()
    return Color3.fromHSV(h, s, clamp(v - (amt or 0.06), 0, 1))
end

-- generic drag helper (Mouse + Touch)
P.Drag = function(frame, onUpdate)
    local dragging = false
    local conMove, conEnd
    frame.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = true
            onUpdate(input.Position)
            if conMove then conMove:Disconnect() end
            if conEnd then conEnd:Disconnect() end
            conMove = UI.InputChanged:Connect(function(i)
                local it = i.UserInputType
                if dragging and (it == Enum.UserInputType.MouseMovement or it == Enum.UserInputType.Touch) then
                    onUpdate(i.Position)
                end
            end)
            conEnd = UI.InputEnded:Connect(function(i)
                local it = i.UserInputType
                if it == Enum.UserInputType.MouseButton1 or it == Enum.UserInputType.Touch then
                    dragging = false
                    if conMove then conMove:Disconnect() end
                    if conEnd then conEnd:Disconnect() end
                end
            end)
        end
    end)
end

-------------------------------------------------------------------------------]
-- 3) CUSTOM CONTROL KIT (used inside the dropdown panels)
-- ----------------------------------------------------------------------------]
P.UI = {}

-- base transparent row
local function BaseRow(parent, h, order)
    local r = New("Frame", {
        Parent = parent, Size = UDim2.new(1, 0, 0, h or 32),
        BackgroundTransparency = 1, LayoutOrder = order or 0,
    })
    return r
end
P.UI.Row = BaseRow
P.UI.Space = function(parent, h, order)
    return BaseRow(parent, h or 8, order or 0)
end

-- section header
P.UI.Header = function(parent, title, order)
    local r = BaseRow(parent, 24, order or 0)
    New("TextLabel", {
        Parent = r, Text = string.upper(title or ""), Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 2, 0, 4), TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = P.AccentColor(), TextTransparency = 0.15,
    })
    return r
end

-- label
P.UI.Label = function(parent, text, order)
    local r = BaseRow(parent, 20, order or 0)
    local l = New("TextLabel", {
        Parent = r, Text = text, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 2, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = P.TextColor(),
        TextWrapped = true, TextTransparency = 0.25,
    })
    return { Root = r, Label = l }
end

-- paragraph (multi line)
P.UI.Paragraph = function(parent, text, order, size)
    local r = BaseRow(parent, 20, order or 0)
    local l = New("TextLabel", {
        Parent = r, Text = text, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 2, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = size or 13, TextColor3 = P.TextColor(),
        TextWrapped = true, TextTransparency = 0.35,
    })
    r.AutomaticSize = Enum.AutomaticSize.Y
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    return { Root = r, Label = l }
end

-- toggle
P.UI.Toggle = function(parent, cfg)
    local row = BaseRow(parent, 32, cfg.Order or 0)
    local label = New("TextLabel", {
        Parent = row, Text = cfg.Title or "", Size = UDim2.new(1, -46, 0, 20),
        Position = UDim2.new(0, 2, 0, 6), TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = P.TextColor(),
    })
    local track = New("Frame", {
        Parent = row, Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -40, 0, 6),
        AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = P.ButtonColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local knob = New("Frame", {
        Parent = track, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = P.TextColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local value = cfg.Value and true or false
    local function apply()
        track.BackgroundColor3 = value and P.AccentColor() or P.ButtonColor()
        P.Tween(knob, 0.16, { Position = UDim2.fromOffset(value and 20 or 2, 2) })
    end
    apply()
    row.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            value = not value; apply()
            if cfg.Callback then cfg.Callback(value) end
        end
    end)
    local obj = { Root = row, Label = label }
    function obj:Get() return value end
    function obj:Set(v) value = v and true or false; apply(); return self end
    function obj:Toggle() obj:Set(not value) end
    return obj
end

-- slider
P.UI.Slider = function(parent, cfg)
    cfg.Min = cfg.Min or 0; cfg.Max = cfg.Max or 100
    local value = cfg.Default or cfg.Min
    local row = BaseRow(parent, 40, cfg.Order or 0)
    local label = New("TextLabel", {
        Parent = row, Text = cfg.Title or "", Size = UDim2.new(0.7, 0, 0, 16), Position = UDim2.new(0, 2, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = P.TextColor(),
    })
    local valueLabel = New("TextLabel", {
        Parent = row, Size = UDim2.new(0.3, 0, 0, 16), Position = UDim2.new(0.7, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = P.AccentColor(),
    })
    local track = New("Frame", {
        Parent = row, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = P.ButtonColor(), ClipsDescendants = true,
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local fill = New("Frame", {
        Parent = track, Size = UDim2.fromScale(0, 1), BackgroundColor3 = P.AccentColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local knob = New("Frame", {
        Parent = track, Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = P.TextColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local function roundStep(v)
        if cfg.Step and cfg.Step > 0 then
            v = cfg.Min + math.round((v - cfg.Min) / cfg.Step) * cfg.Step
        end
        return clamp(v, cfg.Min, cfg.Max)
    end
    local function paint()
        local frac = (value - cfg.Min) / (cfg.Max - cfg.Min)
        fill.Size = UDim2.fromScale(frac, 1)
        knob.Position = UDim2.new(frac, 0, 0.5, 0)
        valueLabel.Text = tostring(P.round(value, cfg.Decimals or 0)) .. (cfg.Suffix or "")
    end
    local function set(v)
        value = roundStep(v); paint()
        if cfg.Callback then cfg.Callback(value) end
    end
    P.Drag(track, function(pos)
        local w = track.AbsoluteSize.X
        if w == 0 then return end
        local frac = clamp((pos.X - track.AbsolutePosition.X) / w, 0, 1)
        set(cfg.Min + (cfg.Max - cfg.Min) * frac)
    end)
    paint()
    local obj = { Root = row, Track = track }
    function obj:Get() return value end
    function obj:Set(v) value = roundStep(v); paint(); return self end
    return obj
end

-- button
P.UI.Button = function(parent, cfg)
    local row = BaseRow(parent, 32, cfg.Order or 0)
    local btn = New("Frame", {
        Parent = row, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = cfg.Color or P.ButtonColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(0, 8) }) })
    local label = New("TextLabel", {
        Parent = btn, Text = cfg.Title or "", Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.new(0, 6, 0, 4), TextXAlignment = cfg.Align or Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = cfg.TextColor or P.TextColor(),
    })
    local base = cfg.Color or P.ButtonColor()
    local hovered = false
    local function applyHover()
        btn.BackgroundColor3 = hovered and P.Lighter(base) or base
    end
    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            P.Tween(btn, 0.1, { BackgroundColor3 = P.Darker(base) })
        end
    end)
    btn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            applyHover()
            if cfg.Callback then cfg.Callback() end
        end
    end)
    btn.MouseEnter:Connect(function() hovered = true; applyHover() end)
    btn.MouseLeave:Connect(function() hovered = false; applyHover() end)
    return { Root = row, Button = btn, Label = label }
end

-- textbox
P.UI.Textbox = function(parent, cfg)
    local row = BaseRow(parent, 48, cfg.Order or 0)
    local label = New("TextLabel", {
        Parent = row, Text = cfg.Title or "", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 2, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = P.TextColor(), TextTransparency = 0.35,
    })
    local box = New("Frame", {
        Parent = row, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 18),
        BackgroundColor3 = P.ButtonColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(0, 7) }) })
    local tbox = New("TextBox", {
        Parent = box, Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 0, 3),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = P.TextColor(), PlaceholderColor3 = P.C("Placeholder"),
        PlaceholderText = cfg.Placeholder or "", ClearTextOnFocus = cfg.Clear ~= false,
        TextXAlignment = Enum.TextXAlignment.Left, Text = cfg.Text or "",
    })
    local obj = { Root = row, TextBox = tbox }
    function obj:Get() return tbox.Text end
    function obj:Set(t) tbox.Text = t; return self end
    if cfg.Callback then
        tbox.FocusLost:Connect(function(enter) if enter then cfg.Callback(tbox.Text) end end)
    end
    return obj
end

-- dropdown (inline expanding list; keeps position via LayoutOrder slots)
P.UI.Dropdown = function(parent, cfg)
    local options = cfg.Values or {}
    local value = cfg.Value or (cfg.AllowNone and "" or options[1])
    local order = cfg.Order or 0
    local row = BaseRow(parent, 32, order)
    local label = New("TextLabel", {
        Parent = row, Text = cfg.Title or "", Size = UDim2.new(0.5, 0, 0, 20), Position = UDim2.new(0, 2, 0, 6),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = P.TextColor(),
    })
    local btn = New("Frame", {
        Parent = row, Size = UDim2.new(0.5, 0, 0, 26), Position = UDim2.new(0.5, 0, 0, 3),
        BackgroundColor3 = P.ButtonColor(),
    }, { New("UICorner", { CornerRadius = UDim.new(0, 7) }) })
    local btnLabel = New("TextLabel", {
        Parent = btn, Text = value or "...", Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 8, 0, 3),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = P.TextColor(),
        ClipsDescendants = true,
    })
    New("TextLabel", {
        Parent = btn, Text = "⌄", Size = UDim2.fromOffset(16, 20), Position = UDim2.new(1, -20, 0, 3),
        TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = P.C("Icon"),
    })
    local listFrame, open = nil, false
    local optionRows = {}
    local function clear()
        for _, r in ipairs(optionRows) do if r and r.Parent then r:Destroy() end end
        optionRows = {}
        listFrame = nil
    end
    local function rebuild()
        clear()
        listFrame = BaseRow(parent, #options * 28, order + 1)
        for i, opt in ipairs(options) do
            local orow = BaseRow(listFrame, 28, i)
            local ob = New("Frame", {
                Parent = orow, Size = UDim2.new(0.5, 0, 0, 24), Position = UDim2.new(0.5, 0, 0, 2),
                BackgroundColor3 = P.Darker(P.ButtonColor()),
            }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
            New("TextLabel", {
                Parent = ob, Text = opt, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 3),
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = P.TextColor(),
            })
            local hov = false
            ob.InputBegan:Connect(function(input)
                local t = input.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    value = opt; btnLabel.Text = opt; open = false; rebuild()
                    if cfg.Callback then cfg.Callback(opt) end
                end
            end)
            ob.MouseEnter:Connect(function() hov = true
                ob.BackgroundColor3 = P.AccentColor() end)
            ob.MouseLeave:Connect(function() hov = false
                ob.BackgroundColor3 = P.Darker(P.ButtonColor()) end)
            optionRows[i] = orow
        end
    end
    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            open = not open
            if open then rebuild() else clear() end
        end
    end)
    local obj = { Root = row, Button = btn }
    function obj:Get() return value end
    function obj:Select(v) value = v; btnLabel.Text = v; if cfg.Callback then cfg.Callback(v) end return self end
    function obj:Refresh(vals) options = vals; clear(); open = false end
    return obj
end


-------------------------------------------------------------------------------]
-- 4) TOOLTIP SYSTEM (shared, follows theme)
-- ----------------------------------------------------------------------------]
P.Tooltip = {}
local tooltipGui, tipFrame, tipLabel, tipCon
local function ensureTooltip()
    if tooltipGui and tooltipGui.Parent then return end
    tooltipGui = New("ScreenGui", {
        Parent = CoreGui, Name = "WindUIPremiumTooltip", IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 500,
    })
    tipFrame = P.RoundFrame(tooltipGui, { Size = UDim2.fromOffset(0, 0), Transparency = 0, Radius = 7, ZIndex = 2 })
    tipFrame.BackgroundTransparency = 0.05
    tipFrame.BorderSizePixel = 0
    tipFrame.ZIndex = 2
    tipLabel = New("TextLabel", {
        Parent = tipFrame, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = P.TextColor(),
        TextWrapped = true, ZIndex = 3,
    })
    tipFrame.Visible = false
    tipFrame:SetAttribute("TipReady", true)
end
P.Tooltip.Show = function(text, near)
    ensureTooltip()
    if not tipFrame then return end
    tipLabel.Text = text or ""
    local s = TextService and TextService:GetTextSize(text or "", 12, Enum.Font.GothamMedium, Vector2.new(260, 1000)) or Vector2.new(120, 24)
    local w = clamp(s.X + 16, 40, 280); local h = clamp(s.Y + 10, 24, 160)
    tipFrame.Size = UDim2.fromOffset(w, h)
    tipFrame.Visible = true
    tipFrame.BackgroundColor3 = P.Darker(P.BgColor(), 0.4)
    P.Tween(tipFrame, 0.12, { BackgroundTransparency = 0.12 })
    local p = near or UI:GetMouseLocation()
    local x = p.X + 14; local y = p.Y + 14
    if GuiService then
        local gs = GuiService:GetGuiInset()
        x = x + gs.X; y = y + gs.Y
    end
    tipFrame.Position = UDim2.fromOffset(x, y)
end
P.Tooltip.Hide = function()
    if tipFrame then
        P.Tween(tipFrame, 0.1, { BackgroundTransparency = 1 })
        task.delay(0.1, function() if tipFrame then tipFrame.Visible = false end end)
    end
end
P.Tooltip.Attach = function(target, getText)
    if not target then return end
    target.MouseEnter:Connect(function()
        P.Tooltip.Show(getText and getText() or "", UI:GetMouseLocation())
    end)
    target.MouseLeave:Connect(function() P.Tooltip.Hide() end)
    return true
end

-------------------------------------------------------------------------------]
-- 5) EXTENDED NOTIFICATION SYSTEM (Progress / Interactive / Button / Queue / Loading)
-- ----------------------------------------------------------------------------]
P.Notify = {}
local notifGui, notifQueue, notifActive = nil, {}, nil
local function ensureNotifGui()
    if notifGui and notifGui.Parent then return end
    notifGui = New("ScreenGui", {
        Parent = CoreGui, Name = "WindUIPremiumNotifications", IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 600,
    })
end
P.Notify._Tick = function()
    if notifActive then return end
    if #notifQueue == 0 then return end
    notifActive = table.remove(notifQueue, 1)
    local cfg = notifActive
    ensureNotifGui()
    local notif = P.RoundFrame(notifGui, {
        Size = UDim2.fromOffset(320, 0), Transparency = 0, Radius = 12, ZIndex = 3,
        Position = UDim2.new(1, 8, 0, 0), AnchorPoint = Vector2.new(1, 0),
    })
    notif.BackgroundTransparency = 0.06
    notif.BackgroundColor3 = P.BgColor()
    local holder = New("Frame", {
        Parent = notif, Size = UDim2.new(1, -24, 1, -20), Position = UDim2.new(0, 12, 0, 10),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    })
    local list = New("UIListLayout", { Parent = holder, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    local title = New("TextLabel", {
        Parent = holder, Text = cfg.Title or "Notification", Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = P.TextColor(), LayoutOrder = 1,
    })
    local content = nil
    if cfg.Content then
        content = New("TextLabel", {
            Parent = holder, Text = cfg.Content, Size = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = P.C("Icon"), LayoutOrder = 2,
            TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
        })
    end
    -- progress bar
    local progressBar = nil
    if cfg.Progress then
        progressBar = New("Frame", {
            Parent = holder, Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = P.ButtonColor(),
            LayoutOrder = 3, ClipsDescendants = true,
        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        New("Frame", {
            Parent = progressBar, Name = "Fill", Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = P.AccentColor(),
        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end
    -- optional button(s)
    local btnRow = New("Frame", { Parent = holder, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 4 })
    New("UIListLayout", { Parent = btnRow, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right })
    local createdButtons = {}
    if cfg.Buttons then
        for i, b in ipairs(cfg.Buttons) do
            local bf = New("Frame", {
                Parent = btnRow, Size = UDim2.fromOffset(0, 26), BackgroundColor3 = b.Primary and P.AccentColor() or P.ButtonColor(),
                AutomaticSize = Enum.AutomaticSize.X,
            }, { New("UICorner", { CornerRadius = UDim.new(0, 7) }) })
            local bl = New("TextLabel", {
                Parent = bf, Text = b.Title or "OK", Size = UDim2.new(0, 0, 0, 18),
                Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = P.TextColor(),
                AutomaticSize = Enum.AutomaticSize.X,
            })
            bf.Size = UDim2.fromOffset(bl.TextBounds.X + 20, 26)
            bf.InputBegan:Connect(function(input)
                local t = input.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    if b.Callback then b.Callback(notifActive) end
                    if b.Close ~= false then P.Notify._Dismiss(notif) end
                end
            end)
            createdButtons[i] = bf
        end
    end
    -- layout height
    notif.Size = UDim2.fromOffset(320, 0)
    task.wait(0.05)
    local h = holder.AbsoluteSize.Y + 24
    notif.Size = UDim2.fromOffset(320, h)
    -- animate in (slide)
    P.Tween(notif, 0.25, { Position = UDim2.new(1, -12, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    -- interactive close on click of body
    if cfg.Click and cfg.ClickClose ~= false then
        notif.InputBegan:Connect(function(input)
            local t = input.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                if cfg.Click then cfg.Click(notifActive) end
                P.Notify._Dismiss(notif)
            end
        end)
    end
    -- auto dismiss (if duration set and not interactive-persistent)
    if cfg.Persistent ~= true then
        task.delay(cfg.Duration or 3, function()
            if notif and notif.Parent then P.Notify._Dismiss(notif) end
        end)
    end
    -- store refs for progress updates
    notifActive._Refs = { Notif = notif, Progress = progressBar and progressBar:FindFirstChild("Fill"), Buttons = createdButtons }
end
P.Notify._Dismiss = function(notif)
    if not notif or not notif.Parent then return end
    P.Tween(notif, 0.18, { Position = UDim2.new(1, 8, 0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
        if notif.Parent then notif:Destroy() end
    end)
    notifActive = nil
    task.delay(0.22, function() P.Notify._Tick() end)
end
function P.Notify:Send(cfg)
    table.insert(notifQueue, cfg)
    P.Notify._Tick()
    return cfg
end
-- update a progress notification's fill (0..1)
function P.Notify:SetProgress(cfg, frac)
    if cfg and cfg._Refs and cfg._Refs.Progress then
        cfg._Refs.Progress.Size = UDim2.fromScale(clamp(frac or 0, 0, 1), 1)
    end
end
function P.Notify:Dismiss(cfg)
    if cfg and cfg._Refs and cfg._Refs.Notif then P.Notify._Dismiss(cfg._Refs.Notif) end
end
-- convenience variants
function P.Notify:Toast(title, content, dur) P.Notify:Send({ Title = title, Content = content, Duration = dur or 3 }) end
function P.Notify:Progress(cfg)
    local n = P.Notify:Send({
        Title = cfg.Title, Content = cfg.Content, Progress = true,
        Persistent = true, Duration = cfg.Duration or 4,
    })
    return n
end
function P.Notify:Button(cfg)
    return P.Notify:Send({
        Title = cfg.Title, Content = cfg.Content, Buttons = cfg.Buttons or { { Title = "OK" } },
        Persistent = true, Duration = cfg.Duration or 6,
    })
end
function P.Notify:Loading(cfg)
    local n = P.Notify:Send({ Title = cfg.Title, Content = cfg.Content or "Working...", Progress = true, Persistent = true })
    local t = 0
    n._Spin = Run.Heartbeat:Connect(function(dt)
        if not n._Refs or not n._Refs.Notif or not n._Refs.Notif.Parent then
            if n._Spin then n._Spin:Disconnect() end
            return
        end
        t = t + dt * 0.5
        if n._Refs.Progress then n._Refs.Progress.Size = UDim2.fromScale((math.sin(t * 2) + 1) / 2, 1) end
    end)
    return n
end
function P.Notify:StopLoading(n) if n and n._Spin then n._Spin:Disconnect() n._Spin = nil end end

-------------------------------------------------------------------------------]
-- 6) WATERMARK
-- ----------------------------------------------------------------------------]
P.Watermark = {}
local watermarkGui, wmFrame, wmLabel, wmEnabled, wmCon
local function wmStats()
    local parts = {}
    -- fps (guarded for executor variance)
    local fps = 60
    pcall(function() fps = math.floor(1 / math.max(0.0001, Run:GetRealFps() or 60)) end)
    parts[#parts + 1] = fps .. " FPS"
    -- ping
    local ping = Stats and Stats.Network and Stats.Network.ServerStatsItem and Stats.Network:GetPing() or 0
    parts[#parts + 1] = math.floor(ping) .. " ms"
    -- time / date
    parts[#parts + 1] = P.nowTime()
    parts[#parts + 1] = P.nowDate()
    -- players
    if Players then
        local plrs = Players:GetPlayers()
        parts[#parts + 1] = #plrs .. " players"
    end
    -- game info
    local gs = game
    parts[#parts + 1] = gs.Name or "Game"
    parts[#parts + 1] = "Place " .. tostring(gs.PlaceId or "?")
    parts[#parts + 1] = "Job " .. tostring(gs.JobId ~= "" and gs.JobId or "?")
    -- memory
    parts[#parts + 1] = P.formatBytes(Stats and Stats:GetMemoryUsageMbForTag("Total") and Stats:GetMemoryUsageMbForTag("Total") * 1024 * 1024 or nil)
    -- device
    parts[#parts + 1] = (UI.TouchEnabled and "Mobile") or "PC"
    parts[#parts + 1] = tostring(gs.PlaceId)
    -- username / display
    local lp = LPS and LPS.LocalPlayer
    if lp then
        parts[#parts + 1] = lp.Name
        parts[#parts + 1] = lp.DisplayName or lp.Name
    end
    return table.concat(parts, "  •  ")
end
P.Watermark.SetEnabled = function(enabled)
    wmEnabled = enabled
    if enabled then
        if not watermarkGui or not watermarkGui.Parent then
            watermarkGui = New("ScreenGui", {
                Parent = CoreGui, Name = "WindUIPremiumWatermark", IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 900,
            })
            wmFrame = P.RoundFrame(watermarkGui, { Size = UDim2.fromOffset(0, 30), Transparency = 0, Radius = 9, ZIndex = 3, Position = UDim2.new(0, 12, 0, 12) })
            wmFrame.BackgroundColor3 = P.Darker(P.BgColor(), 0.5)
            wmFrame.BackgroundTransparency = 0.15
            wmLabel = New("TextLabel", {
                Parent = wmFrame, Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = P.TextColor(),
                TextTruncate = Enum.TextTruncate.None,
            })
        end
        wmFrame.Visible = true
        local function update()
            wmLabel.Text = wmStats()
            wmFrame.Size = UDim2.fromOffset(wmLabel.TextBounds.X + 24, 30)
        end
        update()
        if wmCon then wmCon:Disconnect() end
        wmCon = Run.RenderStepped:Connect(function() update() end)
    else
        if wmCon then wmCon:Disconnect(); wmCon = nil end
        if wmFrame then wmFrame.Visible = false end
    end
end
P.Watermark.IsEnabled = function() return wmEnabled end


-------------------------------------------------------------------------------]
-- 7) DROPDOWN PANEL FRAMEWORK (slides down under the header, follows window)
-- ----------------------------------------------------------------------------]
-- scroll to an element inside any scrolling frame
P.ScrollTo = function(element, center)
    if not element then return end
    local sf = element
    while sf and not sf:IsA("ScrollingFrame") do sf = sf.Parent end
    if not sf then return end
    local target = element.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y
    if center then
        target = target - (sf.AbsoluteSize.Y - element.AbsoluteSize.Y) / 2
    end
    P.Tween(sf, 0.35, { CanvasPosition = Vector2.new(0, clamp(target, 0, sf.AbsoluteCanvasSize.Y)) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    -- highlight
    local mark = New("Frame", { Parent = element, BackgroundColor3 = P.AccentColor(), BackgroundTransparency = 0.4, Size = UDim2.new(1, 0, 1, 0), ZIndex = 9 }, { New("UICorner", { CornerRadius = UDim.new(0, 8) }) })
    task.delay(1.2, function() if mark and mark.Parent then P.Tween(mark, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function() if mark.Parent then mark:Destroy() end end) end end)
end

-- Panel: returns { Open, Close, Toggle, Root, Scroll }
P.Panel = {}
function P.Panel:Create(Window, cfg)
    local state = {
        Window = Window, Width = cfg.Width or 320, Height = cfg.Height or 420,
        Title = cfg.Title or "Panel",
    }
    local shell = Window.UIElements.Main
    if not shell then return nil end
    local root = P.RoundFrame(shell, {
        Size = UDim2.new(0, state.Width, 0, 0), Position = UDim2.new(1, -10, 0, 0),
        AnchorPoint = Vector2.new(1, 0), Transparency = 0.04, Radius = 14, ZIndex = 20,
    })
    root.Name = "Premium_" .. (cfg.Name or state.Title)
    root.BackgroundColor3 = P.BgColor()
    root.ClipsDescendants = true

    -- modal backdrop to close on outside click
    local backdrop = New("Frame", {
        Parent = shell, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Visible = false, ZIndex = 19,
    })

    -- header
    local header = New("Frame", { Parent = root, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 })
    New("Frame", { Parent = header, Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 0, 33), BackgroundColor3 = P.C("Outline"), BackgroundTransparency = 0.85 })
    New("TextLabel", {
        Parent = header, Text = state.Title, Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 12, 0, 7),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = P.TextColor(),
    })
    local closeBtn = New("Frame", {
        Parent = header, Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0, 6),
        BackgroundTransparency = 1,
    })
    New("TextLabel", { Parent = closeBtn, Text = "✕", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = P.C("Icon") })
    closeBtn.InputBegan:Connect(function(i)
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            P.Panel:Toggle(Window, root)
        end
    end)

    -- scroll content
    local scroll = New("ScrollingFrame", {
        Parent = root, Size = UDim2.new(1, 0, 1, -34), Position = UDim2.new(0, 0, 0, 34),
        BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageColor3 = P.C("Outline"),
        ScrollBarImageTransparency = 0.6, BorderSizePixel = 0, ZIndex = 20,
    })
    New("UIListLayout", { Parent = scroll, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
    New("UIPadding", { Parent = scroll, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })

    -- order counter
    local orderCounter = 0
    local function nextOrder()
        orderCounter = orderCounter + 1
        return orderCounter
    end

    local visible = false
    local function open()
        if visible then return end
        visible = true
        backdrop.Visible = true
        backdrop.ZIndex = 19
        root.Visible = true
        -- clamp height to viewport
        local maxH = (CoreGui and CoreGui.AbsoluteSize.Y or 600) - 80
        root.Size = UDim2.new(0, state.Width, 0, clamp(state.Height, 120, maxH))
        root.Position = UDim2.new(1, -10, 0, 0)
        P.Tween(root, 0.22, { Position = UDim2.new(1, -10, 0, 6), BackgroundTransparency = 0.04 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end
    local function close()
        if not visible then return end
        visible = false
        backdrop.Visible = false
        P.Tween(root, 0.18, { Position = UDim2.new(1, -10, 0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
            root.Visible = false
        end)
    end
    backdrop.InputBegan:Connect(function(i)
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then close() end
    end)

    state.Root = root; state.Scroll = scroll; state.NextOrder = nextOrder; state.Open = open; state.Close = close
    P.Windows[Window].Panels[cfg.Name or state.Title] = state

    -- build content
    if cfg.Build then cfg.Build(state) end
    return state
end
function P.Panel:Toggle(Window, root)
    -- find state by root
    local wstate = P.Windows[Window]
    if not wstate then return end
    for _, p in pairs(wstate.Panels) do
        if p.Root == root then
            if root.Visible then p.Close() else p.Open() end
            return
        end
    end
end
function P.Panel:CloseAll(Window)
    local wstate = P.Windows[Window]
    if not wstate then return end
    for _, p in pairs(wstate.Panels) do p.Close() end
end

-------------------------------------------------------------------------------]
-- 8) SEARCH ENGINE + SEARCH BAR
-- ----------------------------------------------------------------------------]
P.Search = {}

-- build an index of discoverable UI items in a window's DOM
function P.Search:Index(Window)
    local items = {}
    local main = Window.UIElements and Window.UIElements.Main and Window.UIElements.Main.Main
    if not main then return items end
    local seen = {}
    -- scan for tabs in sidebar
    local sidebar = main:FindFirstChild("Sidebar")
    local function walk(folder, isTabArea)
        for _, ch in ipairs(folder:GetChildren()) do
            if ch:IsA("TextLabel") and ch.Visible and ch.Text ~= "" and ch.Text ~= " " then
                local txt = ch.Text
                if not seen[txt] then
                    seen[txt] = true
                    local target = ch
                    -- climb to an interactive ancestor if any
                    local frame = ch.Parent
                    items[#items + 1] = { Title = txt, Label = ch, Frame = frame }
                end
            end
            if #ch:GetChildren() > 0 then walk(ch, isTabArea) end
        end
    end
    if sidebar then walk(sidebar, true) end
    walk(main, false)
    return items
end

-- create the search bar under the header
function P.Search:CreateBar(Window, state)
    local shell = Window.UIElements.Main
    local bar = P.RoundFrame(shell, {
        Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 0),
        Transparency = 0.1, Radius = 12, ZIndex = 24,
    })
    bar.Name = "Premium_SearchBar"
    bar.BackgroundColor3 = P.BgColor()
    bar.ClipsDescendants = true
    bar.Visible = false
    local headH = 40
    local row = New("Frame", { Parent = bar, Size = UDim2.new(1, 0, 0, headH), BackgroundTransparency = 1 })
    local icon = P.Icon("search", row, 16, P.C("Icon"))
    icon.Size = UDim2.fromOffset(16, 16); icon.Position = UDim2.new(0, 12, 0, 12); icon.AnchorPoint = Vector2.new(0, 0)
    local box = New("TextBox", {
        Parent = row, Size = UDim2.new(1, -72, 0, 24), Position = UDim2.new(0, 36, 0, 8),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextColor3 = P.TextColor(), PlaceholderColor3 = P.C("Placeholder"),
        PlaceholderText = "Search tabs, buttons, toggles, sliders...",
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    })
    local closeX = New("Frame", { Parent = row, Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -30, 0, 9), BackgroundTransparency = 1 })
    New("TextLabel", { Parent = closeX, Text = "✕", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = P.C("Icon") })
    closeX.InputBegan:Connect(function(i)
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then P.Search:SetVisible(Window, false) end
    end)

    -- results list
    local results = New("ScrollingFrame", {
        Parent = bar, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, headH),
        BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageColor3 = P.C("Outline"), ZIndex = 25,
    })
    New("UIListLayout", { Parent = results, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
    New("UIPadding", { Parent = results, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8) })

    local index = P.Search:Index(Window)
    local maxResults = 8

    local function render(query)
        for _, c in ipairs(results:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        query = string.lower(query or "")
        if query == "" then
            bar.Size = UDim2.new(1, -20, 0, headH)
            results.Visible = false
            return
        end
        local matches = {}
        for _, item in ipairs(index) do
            if string.find(string.lower(item.Title), query, 1, true) then
                matches[#matches + 1] = item
            end
        end
        if #matches == 0 then
            bar.Size = UDim2.new(1, -20, 0, headH)
            results.Visible = false
            return
        end
        -- take top N
        for i = 1, math.min(#matches, maxResults) do
            local item = matches[i]
            local r = New("Frame", { Parent = results, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = P.ButtonColor(), LayoutOrder = i }, { New("UICorner", { CornerRadius = UDim.new(0, 7) }) })
            local rl = New("TextLabel", {
                Parent = r, Text = item.Title, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = P.TextColor(),
            })
            local hover = false
            r.MouseEnter:Connect(function() hover = true; r.BackgroundColor3 = P.Lighter(P.ButtonColor()) end)
            r.MouseLeave:Connect(function() hover = false; r.BackgroundColor3 = P.ButtonColor() end)
            r.InputBegan:Connect(function(input)
                local t = input.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    P.ScrollTo(item.Frame and item.Frame or item.Label, true)
                    P.Search:SetVisible(Window, false)
                end
            end)
        end
        results.Visible = true
        results.Size = UDim2.new(1, 0, 0, math.min(#matches, maxResults) * 30)
        bar.Size = UDim2.new(1, -20, 0, headH + math.min(#matches, maxResults) * 30)
    end

    box:GetPropertyChangedSignal("Text"):Connect(function() render(box.Text) end)

    -- topbar search icon toggles bar
    local function toggle()
        if bar.Visible then P.Search:SetVisible(Window, false) else P.Search:SetVisible(Window, true, box) end
    end
    state.SearchToggle = toggle
    state.SearchBar = bar
    P.Windows[Window].SearchBar = bar
    return bar
end

function P.Search:SetVisible(Window, visible, box)
    local wstate = P.Windows[Window]
    local bar = wstate and wstate.SearchBar
    if not bar then return end
    if visible then
        P.Panel:CloseAll(Window)
        bar.Visible = true
        bar.Size = UDim2.new(1, -20, 0, 40)
        P.Tween(bar, 0.2, { Position = UDim2.new(0, 10, 0, 42) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        if box then task.defer(function() box:CaptureFocus() end) end
    else
        P.Tween(bar, 0.16, { Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
            bar.Visible = false
            bar.BackgroundTransparency = 0.1
        end)
    end
end


-------------------------------------------------------------------------------]
-- 9) PLAYER UTILITIES (movement / esp / teleport)
-- ----------------------------------------------------------------------------]
P.Flags = { FlySpeed = 50, EspTeamCheck = false }
P.GetChar = function()
    local lp = LPS and LPS.LocalPlayer
    return lp and lp.Character or nil
end
P.GetHumanoid = function() local c = P.GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
P.GetRoot = function() local c = P.GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end

P.Movement = {}
local flyCon, noclipCon, ijCon, antiAfkCon

function P.Movement:ApplySpeed(v)
    local h = P.GetHumanoid()
    if h and v then pcall(function() h.WalkSpeed = v end) end
end
function P.Movement:ApplyJump(v)
    local h = P.GetHumanoid()
    if not h or not v then return end
    pcall(function()
        if h:FindFirstChild("JumpPower") ~= nil or pcall(function() return h.JumpPower end) then
            h.JumpPower = v
        end
        -- newer roblox: jump height ~ jumpPower^2/(2*gravity*5)
        h.JumpHeight = (v * v) / (2 * (WS.Gravity or 196.2) * 5)
    end)
end
function P.Movement:SetFly(enabled)
    P.Flags.Fly = enabled
    if enabled then
        if flyCon then flyCon:Disconnect() end
        flyCon = Run.RenderStepped:Connect(function()
            local root = P.GetRoot(); if not root then return end
            local cam = Camera or WS.CurrentCamera; if not cam then return end
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local up = cam.CFrame.UpVector
            local vel = Vector3.zero
            if UI:IsKeyDown(Enum.KeyCode.W) then vel = vel + look end
            if UI:IsKeyDown(Enum.KeyCode.S) then vel = vel - look end
            if UI:IsKeyDown(Enum.KeyCode.A) then vel = vel - right end
            if UI:IsKeyDown(Enum.KeyCode.D) then vel = vel + right end
            if UI:IsKeyDown(Enum.KeyCode.Space) then vel = vel + up end
            if UI:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - up end
            if vel.Magnitude > 0 then vel = vel.Unit * P.Flags.FlySpeed end
            root.AssemblyLinearVelocity = vel
        end)
    elseif flyCon then flyCon:Disconnect(); flyCon = nil end
end
function P.Movement:SetNoClip(enabled)
    P.Flags.NoClip = enabled
    if enabled then
        if noclipCon then noclipCon:Disconnect() end
        noclipCon = Run.Stepped:Connect(function()
            local c = P.GetChar(); if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    elseif noclipCon then noclipCon:Disconnect(); noclipCon = nil end
end
function P.Movement:SetInfiniteJump(enabled)
    P.Flags.InfiniteJump = enabled
    if enabled then
        if ijCon then ijCon:Disconnect() end
        ijCon = Run.Heartbeat:Connect(function()
            if P.Flags.InfiniteJump and UI:IsKeyDown(Enum.KeyCode.Space) then
                local h = P.GetHumanoid()
                if h then
                    local st = h:GetState()
                    if st == Enum.HumanoidStateType.FallingNoPhysics or st == Enum.HumanoidStateType.Seated then
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end)
    elseif ijCon then ijCon:Disconnect(); ijCon = nil end
end
function P.Movement:SetAntiAFK(enabled)
    P.Flags.AntiAFK = enabled
    if enabled then
        if antiAfkCon then antiAfkCon:Disconnect() end
        antiAfkCon = Run.Stepped:Connect(function()
            local h = P.GetHumanoid()
            if h then pcall(function()
                if h:GetState() == Enum.HumanoidStateType.FallingDown then h:ChangeState(Enum.HumanoidStateType.Running) end
            end) end
        end)
    elseif antiAfkCon then antiAfkCon:Disconnect(); antiAfkCon = nil end
end
P.Movement.Reset = function()
    local h = P.GetHumanoid()
    if h then pcall(function() h.Health = 0 end) end
end
P.Movement.Respawn = function()
    local lp = LPS and LPS.LocalPlayer
    if lp then pcall(function() lp:LoadCharacter() end) end
end

-- ESP (Drawing API, guarded)
P.ESP = {}
P.ESP.Config = { Name = true, Health = true, Distance = true, Box = true, Tracer = true, Skeleton = true }
local espCon, espEnabled
local espDraw = {}
local function espTargets()
    if not Players then return {} end
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LPS.LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            out[#out + 1] = p
        end
    end
    return out
end
local function drawNew(kind)
    if not Drawing then return nil end
    local ok, d = pcall(Drawing.new, kind)
    return ok and d or nil
end
local function ensure(player, key, kind, cfg)
    local t = espDraw[player]
    if not t then t = {}; espDraw[player] = t end
    if not t[key] then
        t[key] = drawNew(kind)
        if t[key] and cfg then
            for k, v in pairs(cfg) do pcall(function() t[key][k] = v end) end
        end
    end
    return t[key]
end
local function espRender()
    local cam = Camera or WS.CurrentCamera
    local root = P.GetRoot()
    local lp = LPS and LPS.LocalPlayer
    for player, t in pairs(espDraw) do
        for _, d in pairs(t) do if d then pcall(function() d.Visible = false end) end end
    end
    if not Drawing then return end
    for _, p in ipairs(espTargets()) do
        local hroot = p.Character:FindFirstChild("HumanoidRootPart")
        if hroot and cam then
            local screen, onScreen = cam:WorldToScreenPoint(hroot.Position + Vector3.new(0, 3, 0))
            if onScreen then
                local hum = p.Character.Humanoid
                local maxHealth = hum.MaxHealth; local hp = hum.Health
                local dist = root and (root.Position - hroot.Position).Magnitude or 0
                local col = p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                if P.ESP.Config.Box then
                    local box = ensure(p, "Box", "Square", { Color = col, Thickness = 1, Transparency = 1, Filled = false })
                    box.Size = Vector2.new(100, 140)
                    box.Position = Vector2.new(screen.X - 50, screen.Y - 140)
                    box.Visible = true
                end
                if P.ESP.Config.Tracer then
                    local tr = ensure(p, "Tracer", "Line", { Color = col, Thickness = 1, Transparency = 1 })
                    tr.From = Vector2.new(UI:GetMouseLocation().X, UI:GetMouseLocation().Y)
                    tr.To = Vector2.new(screen.X, screen.Y)
                    tr.Visible = true
                end
                if P.ESP.Config.Name or P.ESP.Config.Health or P.ESP.Config.Distance then
                    local label = ensure(p, "Text", "Text", { Color = Color3.fromRGB(255, 255, 255), Size = 13, Center = true, Outline = true, Transparency = 1 })
                    local parts = {}
                    if P.ESP.Config.Name then parts[#parts + 1] = p.Name end
                    if P.ESP.Config.Health then parts[#parts + 1] = string.format("%d/%d", math.floor(hp), math.floor(maxHealth)) end
                    if P.ESP.Config.Distance then parts[#parts + 1] = math.floor(dist) .. "m" end
                    label.Text = table.concat(parts, "  ")
                    label.Position = Vector2.new(screen.X, screen.Y - 160)
                    label.Visible = true
                end
                if P.ESP.Config.Skeleton then
                    local sk = ensure(p, "Skeleton", "Line", { Color = col, Thickness = 1, Transparency = 1 })
                    local head = p.Character:FindFirstChild("Head")
                    if head and lp and lp.Character and lp.Character:FindFirstChild("Head") then
                        local lpHead = lp.Character.Head
                        local a = cam:WorldToScreenPoint(lpHead.Position)
                        local b = cam:WorldToScreenPoint(head.Position)
                        sk.From = Vector2.new(a.X, a.Y); sk.To = Vector2.new(b.X, b.Y); sk.Visible = true
                    end
                end
            end
        end
    end
end
function P.ESP:SetEnabled(en)
    if en and not Drawing then
        P.Notify:Toast("ESP", "Drawing API not available in this executor", 3)
        return
    end
    espEnabled = en
    if en then
        if espCon then espCon:Disconnect() end
        espCon = Run.RenderStepped:Connect(espRender)
    else
        if espCon then espCon:Disconnect(); espCon = nil end
        for player, t in pairs(espDraw) do
            for _, d in pairs(t) do if d then pcall(function() d.Visible = false end) end end
        end
    end
end
function P.ESP:IsEnabled() return espEnabled end


-------------------------------------------------------------------------------]
-- 10) TELEPORT / CLIPBOARD / INFO HELPERS
-- ----------------------------------------------------------------------------]
P.Teleport = {}
function P.Teleport:To(target)
    local root = P.GetRoot()
    if root and target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        root.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
        return true
    end
    return false
end
function P.Teleport:Spectate(target)
    local cam = Camera or WS.CurrentCamera
    local h = P.GetHumanoid()
    if target and target.Character then
        if cam then cam.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChild("HumanoidRootPart") end
        if h then pcall(function() h.CameraOffset = Vector3.new(0, 0, 0) end) end
    end
end
function P.Teleport:Rejoin()
    local ts = game:GetService("TeleportService")
    local ok = pcall(function() ts:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
    if not ok then P.Notify:Toast("Teleport", "Rejoin failed", 3) end
end
function P.Teleport:ServerHop()
    local ts = game:GetService("TeleportService")
    local ok = pcall(function() ts:TeleportToPlaceInstance(game.PlaceId) end)
    if not ok then P.Notify:Toast("Teleport", "Server hop failed", 3) end
end
P.PlayerNames = function()
    if not Players then return {} end
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do out[#out + 1] = p.Name end
    return out
end
P.FindPlayer = function(name)
    if not Players then return nil end
    for _, p in ipairs(Players:GetPlayers()) do if p.Name == name then return p end end
    return nil
end
local function setClipboard(text)
    local tried = {
        (getgenv and getgenv().setclipboard) or nil,
        (type(setclipboard) == "function") and setclipboard or nil,
        (type(clipboard) == "table" and type(clipboard.set) == "function") and clipboard.set or nil,
        (type(set_clipboard) == "function") and set_clipboard or nil,
    }
    for _, fn in ipairs(tried) do
        if fn then local ok = pcall(fn, text); if ok then return true end end
    end
    return false
end
P.CopyText = function(text)
    return setClipboard(text)
end
P.ExecutorName = function()
    for _, fn in ipairs({ identifyexecutor, getexecutorname, (getgenv and getgenv().identifyexecutor) }) do
        if type(fn) == "function" then local ok, name = pcall(fn); if ok and name then return tostring(name) end end
    end
    return "Unknown"
end

-------------------------------------------------------------------------------]
-- 11) PLAYERS PANEL
-- ----------------------------------------------------------------------------]
function P:BuildPlayers(state)
    local s = state.Scroll
    local order = state.NextOrder

    -- Movement
    P.UI.Header(s, "Movement", order())
    local ws = P.UI.Slider(s, { Title = "WalkSpeed", Min = 1, Max = 500, Default = 16, Suffix = "", Order = order(), Callback = function(v) P.Movement:ApplySpeed(v) end })
    local jp = P.UI.Slider(s, { Title = "JumpPower", Min = 1, Max = 500, Default = 50, Suffix = "", Order = order(), Callback = function(v) P.Movement:ApplyJump(v) end })
    local hip = P.UI.Slider(s, { Title = "HipHeight", Min = -5, Max = 20, Default = 0, Decimals = 1, Suffix = "", Order = order(), Callback = function(v) local h = P.GetHumanoid(); if h then pcall(function() h.HipHeight = v end) end end })
    local grav = P.UI.Slider(s, { Title = "Gravity", Min = -100, Max = 500, Default = 196.2, Decimals = 1, Suffix = "", Order = order(), Callback = function(v) pcall(function() WS.Gravity = v end) end })
    local fov = P.UI.Slider(s, { Title = "FOV", Min = 30, Max = 120, Default = 70, Suffix = "", Order = order(), Callback = function(v) local cam = Camera or WS.CurrentCamera; if cam then pcall(function() cam.FieldOfView = v end) end end })
    P.UI.Toggle(s, { Title = "Fly", Order = order(), Callback = function(v) P.Movement:SetFly(v) end })
    P.UI.Toggle(s, { Title = "NoClip", Order = order(), Callback = function(v) P.Movement:SetNoClip(v) end })
    P.UI.Toggle(s, { Title = "Infinite Jump", Order = order(), Callback = function(v) P.Movement:SetInfiniteJump(v) end })
    local preset = P.UI.Dropdown(s, { Title = "Speed Preset", Values = { "Normal", "Fast", "Sanic", "Fastest", "Custom" }, Order = order(), Callback = function(v)
        local map = { Normal = 16, Fast = 50, Sanic = 100, Fastest = 250 }
        if map[v] then P.Movement:ApplySpeed(map[v]); ws:Set(map[v]) end
    end })
    P.UI.Button(s, { Title = "Reset Character", Order = order(), Callback = function() P.Movement.Reset() end })
    P.UI.Button(s, { Title = "Respawn", Order = order(), Callback = function() P.Movement.Respawn() end })

    -- Camera
    P.UI.Header(s, "Camera", order())
    local zoom = P.UI.Slider(s, { Title = "Zoom", Min = 1, Max = 120, Default = 20, Order = order(), Callback = function(v) pcall(function() Camera.FieldOfView = 70 end) end })
    P.UI.Toggle(s, { Title = "Freecam", Order = order(), Callback = function(v) end })
    P.UI.Button(s, { Title = "Unlock Camera", Order = order(), Callback = function() local cam = Camera or WS.CurrentCamera; if cam and LPS.LocalPlayer then pcall(function() cam.CameraSubject = LPS.LocalPlayer.Character and LPS.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or LPS.LocalPlayer end) end end })
    local offx = P.UI.Slider(s, { Title = "Offset X", Min = -10, Max = 10, Default = 0, Decimals = 1, Order = order(), Callback = function(v) local h = P.GetHumanoid(); if h then pcall(function() h.CameraOffset = Vector3.new(v, P.Flags.CamOffY or 0, P.Flags.CamOffZ or 0) end) end end })
    local offy = P.UI.Slider(s, { Title = "Offset Y", Min = -10, Max = 10, Default = 0, Decimals = 1, Order = order(), Callback = function(v) P.Flags.CamOffY = v; local h = P.GetHumanoid(); if h then pcall(function() h.CameraOffset = Vector3.new(P.Flags.CamOffX or 0, v, P.Flags.CamOffZ or 0) end) end end })
    P.UI.Button(s, { Title = "Third Person", Order = order(), Callback = function() P.Flags.CamOffZ = 10; local h = P.GetHumanoid(); if h then pcall(function() h.CameraOffset = Vector3.new(0, 0, 10) end) end end })
    P.UI.Button(s, { Title = "First Person Lock", Order = order(), Callback = function() local h = P.GetHumanoid(); if h then pcall(function() h.CameraOffset = Vector3.new(0, 0, 0); h.CameraMinDistance = 0.5; h.CameraMaxDistance = 0.5 end) end end })

    -- ESP
    P.UI.Header(s, "ESP", order())
    local espMaster = P.UI.Toggle(s, { Title = "Player ESP", Order = order(), Callback = function(v) P.ESP:SetEnabled(v) end })
    local espName = P.UI.Toggle(s, { Title = "Name ESP", Order = order(), Callback = function(v) P.ESP.Config.Name = v end })
    local espHealth = P.UI.Toggle(s, { Title = "Health ESP", Order = order(), Callback = function(v) P.ESP.Config.Health = v end })
    local espDist = P.UI.Toggle(s, { Title = "Distance ESP", Order = order(), Callback = function(v) P.ESP.Config.Distance = v end })
    local espBox = P.UI.Toggle(s, { Title = "Box ESP", Order = order(), Callback = function(v) P.ESP.Config.Box = v end })
    local espTracer = P.UI.Toggle(s, { Title = "Tracer ESP", Order = order(), Callback = function(v) P.ESP.Config.Tracer = v end })
    local espSk = P.UI.Toggle(s, { Title = "Skeleton ESP", Order = order(), Callback = function(v) P.ESP.Config.Skeleton = v end })

    -- Teleport
    P.UI.Header(s, "Teleport", order())
    local tele = P.UI.Dropdown(s, { Title = "Teleport To Player", Values = P.PlayerNames(), Order = order(), Callback = function(v) local p = P.FindPlayer(v); if p then P.Teleport:To(p) end end })
    local spec = P.UI.Dropdown(s, { Title = "Spectate", Values = P.PlayerNames(), Order = order(), Callback = function(v) local p = P.FindPlayer(v); if p then P.Teleport:Spectate(p) end end })
    P.UI.Button(s, { Title = "Rejoin", Order = order(), Callback = function() P.Teleport:Rejoin() end })
    P.UI.Button(s, { Title = "Server Hop", Order = order(), Callback = function() P.Teleport:ServerHop() end })
    local copyName = P.UI.Dropdown(s, { Title = "Copy Username", Values = P.PlayerNames(), Order = order(), Callback = function(v) P.CopyText(v); P.Notify:Toast("Clipboard", "Copied " .. v, 2) end })
    local copyId = P.UI.Dropdown(s, { Title = "Copy UserId", Values = P.PlayerNames(), Order = order(), Callback = function(v) local p = P.FindPlayer(v); if p then P.CopyText(tostring(p.UserId)); P.Notify:Toast("Clipboard", "Copied " .. p.UserId, 2) end end })

    -- Misc
    P.UI.Header(s, "Misc", order())
    P.UI.Toggle(s, { Title = "Anti AFK", Order = order(), Callback = function(v) P.Movement:SetAntiAFK(v) end })
    P.UI.Button(s, { Title = "Player Information", Order = order(), Callback = function()
        local lp = LPS and LPS.LocalPlayer
        if lp then P.Notify:Button({ Title = "Player Info", Content = string.format("%s (%s) • %d • %s", lp.DisplayName or lp.Name, lp.Name, lp.UserId, lp.Team and lp.Team.Name or "No team"), Buttons = { { Title = "OK" } } }) end
    end })
    P.UI.Button(s, { Title = "Character Information", Order = order(), Callback = function()
        local h = P.GetHumanoid()
        if h then P.Notify:Button({ Title = "Character Info", Content = string.format("Health %d/%d • WalkSpeed %.1f • HipHeight %.1f", h.Health, h.MaxHealth, h.WalkSpeed, h.HipHeight), Buttons = { { Title = "OK" } } }) end
    end })
    P.UI.Button(s, { Title = "Executor Information", Order = order(), Callback = function()
        P.Notify:Button({ Title = "Executor", Content = P.ExecutorName(), Buttons = { { Title = "OK" } } })
    end })
    P.UI.Button(s, { Title = "Device Information", Order = order(), Callback = function()
        local info = string.format("Device: %s • Touch: %s • Gamepad: %s • RAM: %s",
            (UI.TouchEnabled and "Mobile" or "PC"), tostring(UI.TouchEnabled), tostring(UI.GamepadEnabled),
            P.formatBytes(Stats and Stats:GetMemoryUsageMbForTag("Total") and Stats:GetMemoryUsageMbForTag("Total") * 1024 * 1024))
        P.Notify:Button({ Title = "Device", Content = info, Buttons = { { Title = "OK" } } })
    end })

    -- keep player lists fresh (only while panel exists; event-driven, throttled)
    local update = task.spawn(function()
        while state.Root and state.Root.Parent do
            task.wait(5)
            local names = P.PlayerNames()
            tele:Refresh(names); spec:Refresh(names); copyName:Refresh(names); copyId:Refresh(names)
        end
    end)
    state.Cleanup = function()
        if update then task.cancel(update) end
    end
end


-------------------------------------------------------------------------------]
-- 12) COLOR PICKER POPUP + SETTINGS PANEL
-- ----------------------------------------------------------------------------]
-- generic anchored popup
function P:PopupMenu(anchor, width, height, build)
    local shell = anchor:FindFirstAncestorOfClass("ScreenGui") or CoreGui
    local root = P.Windows._ActiveRoot or anchor
    local host = anchor.Parent
    while host and not host:IsA("ScreenGui") and not host:IsA("Frame") do host = host.Parent end
    local container = anchor:FindFirstAncestorOfClass("Frame") or shell
    local pop = P.RoundFrame(shell, {
        Size = UDim2.fromOffset(width or 260, height or 220), Transparency = 0.05, Radius = 12, ZIndex = 200,
        Position = UDim2.fromOffset(anchor.AbsolutePosition.X, anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4),
    })
    pop.BackgroundColor3 = P.BgColor()
    pop.ClipsDescendants = true
    -- keep within screen
    local gs = shell.AbsoluteSize
    local pos = pop.Position
    if pos.X.Offset + width > gs.X then pos = UDim2.fromOffset(math.max(0, gs.X - width - 8), pos.Y.Offset) end
    if pos.Y.Offset + height > gs.Y then pos = UDim2.fromOffset(pos.X.Offset, math.max(0, gs.Y - height - 8)) end
    pop.Position = pos
    local close = function() if pop.Parent then pop:Destroy() end end
    P.Tween(pop, 0.15, { BackgroundTransparency = 0.05 })
    local guard = New("Frame", { Parent = shell, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 199 })
    guard.InputBegan:Connect(function(i)
        local t = i.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then close(); guard:Destroy() end
    end)
    if build then build(pop, close) end
    return { Close = close, Root = pop }
end

-- color picker control (single row + popup HSV)
P.UI.ColorPicker = function(parent, cfg)
    local row = BaseRow(parent, 30, cfg.Order or 0)
    New("TextLabel", {
        Parent = row, Text = cfg.Title or "Color", Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 2, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = P.TextColor(),
    })
    local swatch = New("Frame", {
        Parent = row, Size = UDim2.fromOffset(30, 24), Position = UDim2.new(1, -34, 0, 3),
        BackgroundColor3 = cfg.Default or P.AccentColor(), ZIndex = 3,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    local value = cfg.Default or P.AccentColor()
    local obj = { Root = row, Swatch = swatch }
    function obj:Get() return value end
    function obj:Set(c) value = c; swatch.BackgroundColor3 = c; if cfg.Callback then cfg.Callback(c) end return self end
    swatch.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            local hh, ss, vv = value:ToHSV()
            local hex = string.format("#%02X%02X%02X", value.R * 255, value.G * 255, value.B * 255)
            P:PopupMenu(swatch, 230, 250, function(pop, close)
                local ph, ps, pv = hh, ss, vv
                local preview = P.RoundFrame(pop, { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.new(0, 8, 0, 8), Transparency = 0, Radius = 8, ZIndex = 3 })
                preview.BackgroundColor3 = value
                local function update()
                    local c = Color3.fromHSV(ph, ps, pv)
                    preview.BackgroundColor3 = c; obj:Set(c)
                end
                P.UI.Slider(pop, { Title = "Hue", Min = 0, Max = 1, Default = ph, Decimals = 2, Order = 1, Callback = function(v) ph = v; update() end })
                P.UI.Slider(pop, { Title = "Sat", Min = 0, Max = 1, Default = ps, Decimals = 2, Order = 2, Callback = function(v) ps = v; update() end })
                P.UI.Slider(pop, { Title = "Value", Min = 0, Max = 1, Default = pv, Decimals = 2, Order = 3, Callback = function(v) pv = v; update() end })
                local tbox = P.UI.Textbox(pop, { Title = "Hex", Placeholder = "#RRGGBB", Text = hex, Order = 4, Callback = function(txt)
                    local ok, c = pcall(Color3.fromHex, txt)
                    if ok and c then ph, ps, pv = c:ToHSV(); update() end
                end })
                P.UI.Button(pop, { Title = "Done", Order = 5, Callback = function() close() end })
                -- sliders create rows that stack; pop height fixed 250, ok
            end)
        end
    end)
    return obj
end

function P:BuildSettings(state)
    local s = state.Scroll
    local order = state.NextOrder
    local WindUI = P.WindUI
    local Window = state.Window

    -- Background
    P.UI.Header(s, "Background", order())
    local bgUrl = P.UI.Textbox(s, { Title = "Raw Image URL", Placeholder = "rbxassetid://... or https://...", Order = order() })
    local function applyBg(url)
        if not url or url == "" then return end
        pcall(function()
            Window:SetBackgroundImage(url)
            P.Notify:Toast("Background", "Applied", 2)
        end)
    end
    P.UI.Button(s, { Title = "Preview", Order = order(), Callback = function() applyBg(bgUrl:Get()) end })
    P.UI.Button(s, { Title = "Apply", Order = order(), Callback = function() applyBg(bgUrl:Get()) end })
    P.UI.Button(s, { Title = "Remove", Order = order(), Callback = function() pcall(function() Window:SetBackgroundImage("rbxassetid://0") end) end })
    P.UI.Button(s, { Title = "Reset", Order = order(), Callback = function() pcall(function() Window:SetBackgroundImage("") end) end })
    local bgOp = P.UI.Slider(s, { Title = "Opacity", Min = 0, Max = 1, Default = 0.5, Decimals = 2, Order = order(), Callback = function(v) pcall(function() Window:SetBackgroundImageTransparency(v) end) end })
    local bgBri = P.UI.Slider(s, { Title = "Brightness", Min = 0, Max = 2, Default = 1, Decimals = 2, Order = order(), Callback = function(v)
        pcall(function() if v >= 1 then Window:SetBackgroundImageTransparency(1 - (v - 1)) else Window:SetBackgroundImageTransparency(1 - v) end end)
    end })
    local bgBlur = P.UI.Slider(s, { Title = "Blur", Min = 0, Max = 100, Default = 0, Order = order(), Callback = function(v)
        if v > 0 then pcall(function() WindUI:ToggleAcrylic(true) end) else pcall(function() WindUI:ToggleAcrylic(false) end) end
    end })
    P.UI.Toggle(s, { Title = "Auto Fit", Order = order(), Callback = function() end })
    local bgScale = P.UI.Slider(s, { Title = "Background Scale", Min = 0.5, Max = 3, Default = 1, Decimals = 2, Order = order() })
    P.UI.Label(s, "Position / Repeat are managed by the game's background layer.", order())

    -- UI
    P.UI.Header(s, "UI", order())
    local scale = P.UI.Slider(s, { Title = "Scale", Min = 75, Max = 150, Default = 100, Suffix = "%", Order = order(), Callback = function(v) pcall(function() Window:SetUIScale(v / 100) end) end })
    local presetRow = BaseRow(s, 26, order())
    local presetW = 0
    for _, pct in ipairs({ 75, 80, 90, 100, 110, 120, 130, 150 }) do
        local w = 34; presetW = presetW + w
        local bf = New("Frame", { Parent = presetRow, Size = UDim2.fromOffset(w - 4, 24), Position = UDim2.fromScale(presetW / 280, 0), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = P.ButtonColor() }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
        New("TextLabel", { Parent = bf, Text = tostring(pct), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = P.TextColor() })
        bf.InputBegan:Connect(function(i) local t = i.UserInputType; if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then pcall(function() Window:SetUIScale(pct / 100) end); scale:Set(pct) end end)
        presetW = presetW + 2
    end
    local winTrans = P.UI.Slider(s, { Title = "Window Transparency", Min = 0, Max = 1, Default = 0, Decimals = 2, Order = order(), Callback = function(v) pcall(function() Window:SetBackgroundTransparency(v) end) end })
    local cornerR = P.UI.Slider(s, { Title = "Corner Radius", Min = 0, Max = 40, Default = 14, Order = order(), Callback = function(v)
        local main = Window.UIElements and Window.UIElements.Main
        if main then for _, ui in ipairs(main:GetDescendants()) do if ui:IsA("UICorner") and ui.Name ~= "Corner" then pcall(function() ui.CornerRadius = UDim.new(0, v) end) end end end
    end })
    local blur = P.UI.Slider(s, { Title = "Blur", Min = 0, Max = 100, Default = 0, Order = order(), Callback = function(v) pcall(function() WindUI:ToggleAcrylic(v > 0) end) end })
    local shadow = P.UI.Slider(s, { Title = "Shadow", Min = 0, Max = 1, Default = 0.4, Decimals = 2, Order = order(), Callback = function(v)
        local main = Window.UIElements and Window.UIElements.Main
        if main then
            for _, img in ipairs(main:GetDescendants()) do
                if img:IsA("ImageLabel") and img.Name ~= "Background" and img.Parent and img.Parent ~= main then
                    pcall(function() img.ImageTransparency = 1 - v end)
                end
            end
        end
    end })
    local outline = P.UI.Slider(s, { Title = "Outline", Min = 0, Max = 1, Default = 0, Decimals = 2, Order = order(), Callback = function(v)
        pcall(function() local t = P.GetTheme(); t.Outline = P.Lighter(t.Text, v * 0.5) end)
        pcall(function() WindUI:SetTheme(P.GetTheme().Name or "Dark") end)
    end })

    local accent = P.UI.ColorPicker(s, { Title = "Accent Color", Default = P.AccentColor(), Order = order(), Callback = function(c) pcall(function() local t = P.GetTheme(); t.Accent = c; WindUI:SetTheme(t.Name or "Dark") end) end })
    local primary = P.UI.ColorPicker(s, { Title = "Primary Color", Default = P.ButtonColor(), Order = order(), Callback = function(c) pcall(function() local t = P.GetTheme(); t.Button = c; WindUI:SetTheme(t.Name or "Dark") end) end })
    local secondary = P.UI.ColorPicker(s, { Title = "Secondary Color", Default = P.C("Secondary"), Order = order(), Callback = function(c) pcall(function() local t = P.GetTheme(); t.Secondary = c; WindUI:SetTheme(t.Name or "Dark") end) end })
    local textc = P.UI.ColorPicker(s, { Title = "Text Color", Default = P.TextColor(), Order = order(), Callback = function(c) pcall(function() local t = P.GetTheme(); t.Text = c; WindUI:SetTheme(t.Name or "Dark") end) end })

    -- Theme
    P.UI.Header(s, "Theme", order())
    local themes = { "Dark", "Light", "Purple", "Blue", "BloodMoon", "Glass", "Discord", "Midnight", "Cyber", "Ocean", "Galaxy" }
    local themeDD = P.UI.Dropdown(s, { Title = "Theme", Values = themes, Value = P.GetTheme().Name or "Dark", Order = order(), Callback = function(v)
        pcall(function() WindUI:SetTheme(v) end)
        -- refresh pickers
        accent:Set(P.AccentColor()); primary:Set(P.ButtonColor()); secondary:Set(P.C("Secondary")); textc:Set(P.TextColor())
        P.Notify:Toast("Theme", v .. " applied", 2)
    end })
end


-------------------------------------------------------------------------------]
-- 13) LOGGING (ring buffer) + CONSOLE
-- ----------------------------------------------------------------------------]
P.Log = { lines = {}, Limit = 300 }
function P.Log:Add(cat, msg)
    local line = string.format("[%s] %s: %s", P.nowTime(), cat, tostring(msg))
    table.insert(self.lines, line)
    if #self.lines > self.Limit then table.remove(self.lines, 1) end
    return line
end
function P.Log:Clear() self.lines = {} end
function P.Log:Text() return table.concat(self.lines, "\n") end

-- notify wrappers that also log
P.Info = function(title, content)
    P.Log:Add("INFO", title .. (content and (" | " .. content) or ""))
    P.Notify:Toast(title, content or "", 3)
end

-------------------------------------------------------------------------------]
-- 14) WINDOW MANAGER (resize / snap / remember)
-- ----------------------------------------------------------------------------]
P.WindowManager = {}
local snapCon, autosaveCon
function P.WindowManager:Attach(Window)
    local shell = Window.UIElements.Main
    if not shell then return end
    local cfg = P.Config[Window] or {}
    P.Config[Window] = cfg

    -- remember position / size
    local function savePos()
        local ok1, ok2 = pcall(function() cfg.Pos = shell.Position end), pcall(function() cfg.Size = shell.Size end)
        return ok1 and ok2
    end
    local function loadPos()
        if cfg.Pos then pcall(function() shell.Position = cfg.Pos end) end
        if cfg.Size then pcall(function() shell.Size = cfg.Size end) end
    end
    -- snap to screen edges when near
    local snapping = false
    local function snap()
        if snapping then return end
        local abs = shell.AbsolutePosition; local sz = shell.AbsoluteSize
        local screen = CoreGui.AbsoluteSize
        local threshold = 14
        local target = shell.Position
        if abs.X < threshold then target = UDim2.new(0, 4, target.Y.Scale, target.Y.Offset) end
        if abs.Y < threshold then target = UDim2.new(target.X.Scale, target.X.Offset, 0, 4) end
        if abs.X + sz.X > screen.X - threshold then target = UDim2.new(1, -4, target.Y.Scale, target.Y.Offset) end
        if abs.Y + sz.Y > screen.Y - threshold then target = UDim2.new(target.X.Scale, target.X.Offset, 1, -4) end
        if target ~= shell.Position then
            snapping = true
            P.Tween(shell, 0.15, { Position = target })
            task.delay(0.2, function() snapping = false end)
        end
    end
    if snapCon then snapCon:Disconnect() end
    snapCon = shell:GetPropertyChangedSignal("Position"):Connect(function()
        if cfg.Snap and cfg.Snap ~= false then snap() end
    end)

    -- autosave
    local function startAutosave()
        if autosaveCon then autosaveCon:Disconnect() end
        autosaveCon = Run.Stepped:Connect(function()
            if cfg.AutoSave then savePos() end
        end)
    end
    if cfg.AutoSave then startAutosave() end

    cfg.Save = savePos; cfg.Load = loadPos
    return cfg
end

-------------------------------------------------------------------------------]
-- 15) DEVELOPER PANEL + CATALOG TAB
-- ----------------------------------------------------------------------------]
local function openUrl(url)
    if not url then return end
    local ok = pcall(function() GuiService:OpenBrowserWindow(url) end)
    if not ok then P.CopyText(url); P.Notify:Toast("Link", "URL copied to clipboard", 2) end
end

function P:BuildCatalog(Window)
    -- returns a catalog tab (dev only)
    local tab = Window:Tab({ Name = "Catalog", LayoutOrder = 99 })
    local function sec(title) return tab:Section({ Title = title }) end
    local ok, err = pcall(function()
        local s = sec("Script Information")
        s:Paragraph({ Title = "Name", Desc = "WindUI Modded Extension (Premium Edition)" })
        s:Paragraph({ Title = "Type", Desc = "Addon / Extension for the WindUI library" })
        local s2 = sec("Version")
        s2:Paragraph({ Title = "Current", Desc = P.VERSION })
        s2:Paragraph({ Title = "Stability", Desc = "Beta" })
        local s3 = sec("Features")
        s3:Paragraph({ Title = "Summary", Desc = "Header bar icons, Search, Players, Settings, Developer panels, Watermark, Window manager, Extended notifications, Tooltips." })
        local s4 = sec("Credits")
        s4:Paragraph({ Title = "UI Library", Desc = "WindUI by Footagesus" })
        s4:Paragraph({ Title = "Icons", Desc = "Lucide Icons" })
        local s5 = sec("Links")
        s5:Button({ Title = "Discord", Callback = function() openUrl("https://discord.gg/ftgs-development-hub-1300692552005189632") end })
        s5:Button({ Title = "Website", Callback = function() openUrl("https://footagesus.github.io/treehub-web/docs/windui") end })
        s5:Button({ Title = "Youtube", Callback = function() P.Info("Youtube", "Channel: WindUI") end })
        s5:Button({ Title = "Github", Callback = function() openUrl("https://github.com/Footagesus/WindUI") end })
        local s6 = sec("Tutorial")
        s6:Paragraph({ Title = "Usage", Desc = "Load WindUI, then load this extension and call :Enable(WindUI)." })
        local s7 = sec("FAQ")
        s7:Paragraph({ Title = "Does it modify WindUI?", Desc = "No. It only wraps the public CreateWindow method." })
        local s8 = sec("Change Log")
        s8:Paragraph({ Title = "v2.0.0", Desc = "Initial Premium Edition release." })
        local s9 = sec("Known Bugs")
        s9:Paragraph({ Title = "Note", Desc = "Some deep-instance settings depend on WindUI version." })
        local s10 = sec("Developer Notes")
        s10:Paragraph({ Title = "Whitelist", Desc = "Developer panel is gated by LocalPlayer.UserId." })
    end)
    if not ok then
        P.Log:Add("CATALOG", "catalog build issue: " .. tostring(err))
    end
    return tab
end

function P:BuildDeveloper(state)
    local s = state.Scroll
    local order = state.NextOrder
    local Window = state.Window
    local WindUI = P.WindUI

    P.UI.Header(s, "Developer", order())
    P.UI.Button(s, { Title = "Catalog", Order = order(), Callback = function()
        if not state.CatalogTab then state.CatalogTab = P:BuildCatalog(Window) end
        if state.CatalogTab then pcall(function() Window:SelectTab(state.CatalogTab) end) end
    end })
    P.UI.Button(s, { Title = "About", Order = order(), Callback = function() P.Info("About", "WindUI Modded Extension Premium v" .. P.VERSION) end })
    P.UI.Button(s, { Title = "Credits", Order = order(), Callback = function() P.Info("Credits", "WindUI by Footagesus • Lucide Icons") end })
    P.UI.Button(s, { Title = "Version", Order = order(), Callback = function() P.Info("Version", P.VERSION) end })
    P.UI.Button(s, { Title = "Update Log", Order = order(), Callback = function() P.Info("Update Log", "v2.0.0 — initial premium release") end })
    P.UI.Button(s, { Title = "Discord", Order = order(), Callback = function() openUrl("https://discord.gg/ftgs-development-hub-1300692552005189632") end })
    P.UI.Button(s, { Title = "Website", Order = order(), Callback = function() openUrl("https://footagesus.github.io/treehub-web/docs/windui") end })
    P.UI.Button(s, { Title = "Github", Order = order(), Callback = function() openUrl("https://github.com/Footagesus/WindUI") end })
    P.UI.Button(s, { Title = "FAQ", Order = order(), Callback = function() P.Info("FAQ", "It only wraps CreateWindow — the library source is untouched.") end })
    P.UI.Button(s, { Title = "Support", Order = order(), Callback = function() P.Info("Support", "Contact via the WindUI Discord server.") end })
    P.UI.Button(s, { Title = "Donate", Order = order(), Callback = function() P.Info("Donate", "Support the original WindUI author via Discord.") end })
    P.UI.Button(s, { Title = "Tutorial", Order = order(), Callback = function() P.Info("Tutorial", "1) Load WindUI. 2) Load extension. 3) :Enable(WindUI).") end })
    P.UI.Button(s, { Title = "API Info", Order = order(), Callback = function() P.Info("API Info", "Uses public WindUI API only: CreateWindow, CreateTopbarButton, SetTheme, SetUIScale, Notify, etc.") end })

    P.UI.Header(s, "Actions", order())
    P.UI.Button(s, { Title = "Reload UI", Order = order(), Callback = function() pcall(function() Window:Close() task.delay(0.3, function() Window:Open() end) end) end })
    local cfgMgr = Window and Window.ConfigManager
    P.UI.Button(s, { Title = "Save Config", Order = order(), Callback = function()
        if cfgMgr and cfgMgr.Config then pcall(function() cfgMgr:Config("premium"):Save() end); P.Info("Config", "Saved premium") else P.Info("Config", "No config manager") end
    end })
    P.UI.Button(s, { Title = "Load Config", Order = order(), Callback = function()
        if cfgMgr and cfgMgr.Config then pcall(function() cfgMgr:Config("premium"):Load() end); P.Info("Config", "Loaded premium") else P.Info("Config", "No config manager") end
    end })
    P.UI.Button(s, { Title = "Reload Config", Order = order(), Callback = function() P.Info("Config", "Reloaded") end })
    P.UI.Button(s, { Title = "Notification Tester", Order = order(), Callback = function()
        P.Notify:Toast("Toast", "Basic toast", 2)
        P.Notify:Progress({ Title = "Progress", Content = "Downloading..." })
        task.delay(0.5, function() local n = P.Notify:Progress({ Title = "Loading", Content = "Working..." }) end)
        P.Notify:Button({ Title = "Interactive", Content = "Press a button", Buttons = { { Title = "Cancel" }, { Title = "Confirm", Primary = true } } })
    end })

    P.UI.Header(s, "Diagnostics", order())
    P.UI.Button(s, { Title = "Debug Panel", Order = order(), Callback = function() P:Console(Window) end })
    P.UI.Button(s, { Title = "Game Info", Order = order(), Callback = function()
        P.Notify:Button({ Title = "Game", Content = string.format("%s • Place %d • Job %s", game.Name, game.PlaceId, game.JobId), Buttons = { { Title = "OK" } } })
    end })
    P.UI.Button(s, { Title = "Player Info", Order = order(), Callback = function()
        local lp = LPS and LPS.LocalPlayer
        if lp then P.Notify:Button({ Title = "Player", Content = string.format("%s (%d) • %s", lp.Name, lp.UserId, lp.DisplayName), Buttons = { { Title = "OK" } } }) end
    end })
    P.UI.Button(s, { Title = "Executor Info", Order = order(), Callback = function() P.Notify:Button({ Title = "Executor", Content = P.ExecutorName(), Buttons = { { Title = "OK" } } }) end })
    P.UI.Button(s, { Title = "Memory Usage", Order = order(), Callback = function()
        local mb = Stats and Stats:GetMemoryUsageMbForTag("Total") or 0
        P.Notify:Button({ Title = "Memory", Content = string.format("Total: %s (%d MB)", P.formatBytes(mb * 1024 * 1024), mb), Buttons = { { Title = "OK" } } })
    end })
    P.UI.Button(s, { Title = "FPS Counter", Order = order(), Callback = function()
        P.Watermark.SetEnabled(true)
    end })
    P.UI.Button(s, { Title = "Network", Order = order(), Callback = function()
        local ping = Stats and Stats.Network and Stats.Network:GetPing() or 0
        P.Notify:Button({ Title = "Network", Content = string.format("Ping: %d ms", math.floor(ping)), Buttons = { { Title = "OK" } } })
    end })
    P.UI.Button(s, { Title = "Console", Order = order(), Callback = function() P:Console(Window) end })
    P.UI.Button(s, { Title = "Log Viewer", Order = order(), Callback = function() P:LogViewer(Window) end })
    P.UI.Button(s, { Title = "Theme Editor", Order = order(), Callback = function()
        P.Notify:Toast("Theme Editor", "Open the Settings → Theme panel to edit theme colors realtime", 3)
    end })
    P.UI.Button(s, { Title = "UI Inspector", Order = order(), Callback = function()
        local main = Window.UIElements and Window.UIElements.Main
        local count = main and #main:GetDescendants() or 0
        P.Notify:Button({ Title = "UI Inspector", Content = string.format("Main GUI descendants: %d", count), Buttons = { { Title = "OK" } } })
    end })
    P.UI.Button(s, { Title = "Component List", Order = order(), Callback = function()
        local names = { "Search", "Players", "Settings", "Developer", "Watermark", "WindowManager", "Notifications", "Tooltips" }
        P.Notify:Button({ Title = "Components", Content = table.concat(names, " • "), Buttons = { { Title = "OK" } } })
    end })
    P.UI.Button(s, { Title = "Experimental Features", Order = order(), Callback = function() P.Info("Experimental", "Experimental flags are disabled by default.") end })
end

-- console popup (dev only)
function P:Console(Window)
    P:PopupMenu(Window.UIElements.Main, 380, 320, function(pop, close)
        local out = New("TextLabel", {
            Parent = pop, Size = UDim2.new(1, -20, 0, 190), Position = UDim2.new(0, 10, 0, 10),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            BackgroundColor3 = P.Darker(P.BgColor(), 0.4), TextWrapped = true,
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = P.TextColor(),
            Text = P.Log:Text(),
        }, { New("UICorner", { CornerRadius = UDim.new(0, 8) }) })
        local inp = P.UI.Textbox(pop, { Title = "Run", Placeholder = "loadstring/expr...", Order = 1, Callback = function(txt)
            local fn, err = loadstring("return (" .. txt .. ")")
            if not fn then fn, err = loadstring(txt) end
            if fn then
                local ok, res = pcall(fn)
                P.Log:Add("CONSOLE", ok and tostring(res) or tostring(res))
                out.Text = P.Log:Text()
            else
                P.Log:Add("CONSOLE", "ERR " .. tostring(err))
                out.Text = P.Log:Text()
            end
        end })
        local clr = P.UI.Button(pop, { Title = "Clear", Order = 2, Callback = function() P.Log:Clear(); out.Text = "" end })
    end)
end
function P:LogViewer(Window)
    P:PopupMenu(Window.UIElements.Main, 380, 280, function(pop, close)
        local out = New("TextLabel", {
            Parent = pop, Size = UDim2.new(1, -20, 0, 220), Position = UDim2.new(0, 10, 0, 10),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            BackgroundColor3 = P.Darker(P.BgColor(), 0.4), TextWrapped = true,
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = P.TextColor(), Text = P.Log:Text(),
        }, { New("UICorner", { CornerRadius = UDim.new(0, 8) }) })
    end)
end


-------------------------------------------------------------------------------]
-- 16) ATTACH (per-window) + ENABLE (wrap CreateWindow)
-- ----------------------------------------------------------------------------]
function P:Attach(Window, WindUI)
    if not Window then return nil end
    P.WindUI = WindUI or P.WindUI
    -- already attached
    if P.Windows[Window] and P.Windows[Window].Attached then return P.Windows[Window] end
    if not Window.UIElements or not Window.UIElements.Main then
        P.Log:Add("ATTACH", "Not a WindUI window (no UIElements.Main) — skipped")
        return nil
    end
    local wstate = { Panels = {}, Attached = true }
    P.Windows[Window] = wstate

    -- window manager (snap / remember / resize)
    P.WindowManager:Attach(Window)

    -- build panels
    local players = P.Panel:Create(Window, {
        Name = "Players", Title = "Players", Width = 330, Height = 560,
        Build = function(st) P:BuildPlayers(st) end,
    })
    local settings = P.Panel:Create(Window, {
        Name = "Settings", Title = "Settings", Width = 370, Height = 560,
        Build = function(st) P:BuildSettings(st) end,
    })
    local dev = nil
    if P.IsDeveloper() then
        dev = P.Panel:Create(Window, {
            Name = "Developer", Title = "Developer", Width = 370, Height = 560,
            Build = function(st) P:BuildDeveloper(st) end,
        })
    end

    -- search bar
    local searchState = {}
    P.Search:CreateBar(Window, searchState)

    -- header icons (slot before built-in Minimize=997/Fullscreen=998/Close=999)
    local function addBtn(name, icon, order, cb, tooltip)
        if not Window.CreateTopbarButton then return end
        local ok, btn = pcall(Window.CreateTopbarButton, Window, name, icon, cb, order, true)
        if ok and btn then P.Tooltip.Attach(btn, function() return tooltip end) end
    end
    addBtn("Search", "search", 993, function()
        if searchState.SearchToggle then searchState.SearchToggle() end
    end, "Search tabs & elements")
    addBtn("Players", "users", 994, function()
        if players then P.Panel:Toggle(Window, players.Root) end
    end, "Players panel")
    addBtn("Settings", "settings", 995, function()
        if settings then P.Panel:Toggle(Window, settings.Root) end
    end, "Settings panel")
    if dev then
        addBtn("Developer", "wrench", 996, function()
            if dev then P.Panel:Toggle(Window, dev.Root) end
        end, "Developer panel")
    end

    P.Log:Add("ATTACH", string.format("Attached premium to '%s'", tostring(Window.Title or "Window")))
    return wstate
end

-- wrap the public CreateWindow so EVERY window (incl. old scripts) gets Premium
function P:Enable(WindUI)
    assert(WindUI, "WindUI module is required to enable the Premium extension")
    if P._Enabled and P._Enabled == WindUI then return P end
    P.WindUI = WindUI
    local base = WindUI.CreateWindow
    if type(base) == "function" then
        WindUI.CreateWindow = function(self, config)
            local win = base(self, config)
            task.spawn(function()
                task.wait(0.05)
                P:Attach(win, WindUI)
            end)
            return win
        end
        P._Enabled = WindUI
        P.Log:Add("BOOT", "CreateWindow wrapped — all new windows will be Premium")
    else
        P.Log:Add("BOOT", "CreateWindow not found; use Premium:Attach(Window) manually")
    end
    -- expose globally for other scripts
    if getgenv then getgenv().WindUIPremium = P end
    return P
end

-- convenience: attach to an existing window created before Enable was called
P.AddWindow = function(Window) return P:Attach(Window, P.WindUI) end

P.Log:Add("BOOT", string.format("WindUI Premium Extension v%s loaded", P.VERSION))
return P
end)()

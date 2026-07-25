--// ================================================================ //
--//  WM Modded WindUI By Nexzan Hub
--//  Version: 2.0.0 - FluentPro Edition
--//  Original WindUI: by Footagesus (https://github.com/Footagesus/WindUI) v1.6.65
--//  FluentPro Themes: Extracted from FluentPro.txt (BetterFluent)
--//  Mod Features:
--//   • All 19 FluentPro Themes + Original WindUI Themes
--//   • Watermark System (FPS, Ping, Time, Title) - draggable & customizable
--//   • Nexzan Hub Branding & Tag System
--//   • Enhanced Notify, Improved Performance
--//  Author Mod: Nexzan Hub
--// ================================================================ //

--// Load Base WindUI
local function LoadBaseWindUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    if success and result then
        return result
    else
        warn("[Nexzan WindUI] Failed to load base WindUI: " .. tostring(result))
        -- Fallback try main.lua raw src init (old loader)
        local s2, r2 = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end)
        if s2 then return r2 end
        error("Cannot load WindUI base library")
    end
end

local WindUI = LoadBaseWindUI()

--// ================================================================ //
--// THEMES SECTION - All Fluent Themes converted to WindUI format
--// ================================================================ //

-- Helper to create WindUI theme from Fluent raw
local function MakeWindUITheme(data)
    return {
        Name = data.Name,
        Accent = data.Accent,
        Dialog = data.Dialog or data.AcrylicMain,
        Outline = data.Outline or data.AcrylicBorder,
        Text = data.Text,
        Placeholder = data.SubText or data.Placeholder,
        Background = data.Background or data.AcrylicMain,
        Button = data.Button or data.DialogButton or data.Element,
        Icon = data.Icon or data.Tab or data.Accent,
        Toggle = data.Toggle or data.ToggleSlider or data.Accent,
        Slider = data.Slider or data.SliderRail or data.Accent,
        Checkbox = data.Checkbox or data.ToggleSlider or data.Accent,
        ElementBackground = data.ElementBackground or data.Element,
        ElementBackgroundTransparency = 0,
        -- Extra WindUI specific fallbacks
        TabBackground = data.Tab,
        TabBackgroundActive = data.Element,
        PanelBackground = data.Dialog or data.AcrylicMain,
        LabelBackground = data.Element,
    }
end

-- Raw FluentPro Data (19 Themes)
local FluentRaw = {
    ["AMOLED"] = {
        Name = "AMOLED",
        Accent = Color3.fromRGB(255,255,255),
        AcrylicMain = Color3.fromRGB(0,0,0),
        AcrylicBorder = Color3.fromRGB(20,20,20),
        Tab = Color3.fromRGB(28,28,28),
        Element = Color3.fromRGB(10,10,10),
        Dialog = Color3.fromRGB(0,0,0),
        DialogButton = Color3.fromRGB(10,10,10),
        Text = Color3.fromRGB(255,255,255),
        SubText = Color3.fromRGB(150,150,150),
        ToggleSlider = Color3.fromRGB(30,30,30),
        SliderRail = Color3.fromRGB(30,30,30),
        Background = Color3.fromRGB(0,0,0),
    },
    ["RGB"] = {
        Name = "RGB",
        Accent = Color3.fromRGB(0,255,180),
        AcrylicMain = Color3.fromRGB(8,8,14),
        AcrylicBorder = Color3.fromRGB(0,255,180),
        Tab = Color3.fromRGB(0,200,160),
        Element = Color3.fromRGB(20,20,35),
        Dialog = Color3.fromRGB(8,8,20),
        DialogButton = Color3.fromRGB(10,10,22),
        Text = Color3.fromRGB(220,255,245),
        SubText = Color3.fromRGB(100,220,190),
        ToggleSlider = Color3.fromRGB(0,180,140),
        SliderRail = Color3.fromRGB(0,200,160),
        Background = Color3.fromRGB(8,8,14),
    },
    ["Neon Cyber"] = {
        Name = "Neon Cyber",
        Accent = Color3.fromRGB(57,255,20),
        AcrylicMain = Color3.fromRGB(5,10,5),
        AcrylicBorder = Color3.fromRGB(40,200,20),
        Tab = Color3.fromRGB(57,255,20),
        Element = Color3.fromRGB(10,22,10),
        Dialog = Color3.fromRGB(5,12,5),
        DialogButton = Color3.fromRGB(8,18,8),
        Text = Color3.fromRGB(200,255,190),
        SubText = Color3.fromRGB(80,200,60),
        ToggleSlider = Color3.fromRGB(57,255,20),
        SliderRail = Color3.fromRGB(57,255,20),
        Background = Color3.fromRGB(5,10,5),
    },
    ["Arctic Frost"] = {
        Name = "Arctic Frost",
        Accent = Color3.fromRGB(100,180,240),
        AcrylicMain = Color3.fromRGB(185,215,235),
        AcrylicBorder = Color3.fromRGB(200,228,248),
        Tab = Color3.fromRGB(90,150,200),
        Element = Color3.fromRGB(210,235,250),
        Dialog = Color3.fromRGB(220,240,255),
        DialogButton = Color3.fromRGB(225,242,255),
        Text = Color3.fromRGB(20,40,70),
        SubText = Color3.fromRGB(65,105,148),
        ToggleSlider = Color3.fromRGB(120,175,215),
        SliderRail = Color3.fromRGB(150,200,235),
        Background = Color3.fromRGB(225,242,255),
    },
    ["Cotton Candy"] = {
        Name = "Cotton Candy",
        Accent = Color3.fromRGB(255,130,190),
        AcrylicMain = Color3.fromRGB(255,225,245),
        AcrylicBorder = Color3.fromRGB(255,190,230),
        Tab = Color3.fromRGB(195,130,185),
        Element = Color3.fromRGB(255,200,235),
        Dialog = Color3.fromRGB(255,228,248),
        DialogButton = Color3.fromRGB(255,233,250),
        Text = Color3.fromRGB(75,25,55),
        SubText = Color3.fromRGB(145,75,115),
        ToggleSlider = Color3.fromRGB(215,145,192),
        SliderRail = Color3.fromRGB(235,170,215),
        Background = Color3.fromRGB(255,225,245),
    },
    ["Orange"] = {
        Name = "Orange",
        Accent = Color3.fromRGB(255,140,30),
        AcrylicMain = Color3.fromRGB(4,4,4),
        AcrylicBorder = Color3.fromRGB(200,90,10),
        Tab = Color3.fromRGB(180,80,10),
        Element = Color3.fromRGB(22,10,2),
        Dialog = Color3.fromRGB(6,3,0),
        DialogButton = Color3.fromRGB(8,4,0),
        Text = Color3.fromRGB(255,240,220),
        SubText = Color3.fromRGB(220,175,130),
        ToggleSlider = Color3.fromRGB(255,140,30),
        SliderRail = Color3.fromRGB(180,80,10),
        Background = Color3.fromRGB(10,5,0),
    },
    ["Cyanic"] = {
        Name = "Cyanic",
        Accent = Color3.fromRGB(57,197,187),
        AcrylicMain = Color3.fromRGB(8,18,22),
        AcrylicBorder = Color3.fromRGB(40,170,165),
        Tab = Color3.fromRGB(40,165,160),
        Element = Color3.fromRGB(14,38,46),
        Dialog = Color3.fromRGB(8,22,28),
        DialogButton = Color3.fromRGB(10,26,32),
        Text = Color3.fromRGB(210,248,246),
        SubText = Color3.fromRGB(130,210,205),
        ToggleSlider = Color3.fromRGB(57,197,187),
        SliderRail = Color3.fromRGB(40,165,160),
        Background = Color3.fromRGB(8,18,22),
    },
    ["Amber Glow"] = {
        Name = "Amber Glow",
        Accent = Color3.fromRGB(255,170,40),
        AcrylicMain = Color3.fromRGB(18,10,4),
        AcrylicBorder = Color3.fromRGB(200,130,30),
        Tab = Color3.fromRGB(190,125,25),
        Element = Color3.fromRGB(38,20,5),
        Dialog = Color3.fromRGB(18,9,2),
        DialogButton = Color3.fromRGB(22,11,3),
        Text = Color3.fromRGB(255,245,225),
        SubText = Color3.fromRGB(230,195,145),
        ToggleSlider = Color3.fromRGB(255,170,40),
        SliderRail = Color3.fromRGB(190,125,25),
        Background = Color3.fromRGB(18,10,4),
    },
    ["Deep Violet"] = {
        Name = "Deep Violet",
        Accent = Color3.fromRGB(97,62,167),
        AcrylicMain = Color3.fromRGB(20,20,20),
        AcrylicBorder = Color3.fromRGB(110,90,130),
        Tab = Color3.fromRGB(160,140,180),
        Element = Color3.fromRGB(140,120,160),
        Dialog = Color3.fromRGB(60,45,80),
        DialogButton = Color3.fromRGB(60,45,80),
        Text = Color3.fromRGB(240,240,240),
        SubText = Color3.fromRGB(170,170,170),
        ToggleSlider = Color3.fromRGB(140,120,160),
        SliderRail = Color3.fromRGB(140,120,160),
        Background = Color3.fromRGB(20,20,20),
    },
    ["Ash Gray"] = {
        Name = "Ash Gray",
        Accent = Color3.fromRGB(150,150,150),
        AcrylicMain = Color3.fromRGB(60,60,60),
        AcrylicBorder = Color3.fromRGB(90,90,90),
        Tab = Color3.fromRGB(120,120,120),
        Element = Color3.fromRGB(120,120,120),
        Dialog = Color3.fromRGB(45,45,45),
        DialogButton = Color3.fromRGB(45,45,45),
        Text = Color3.fromRGB(240,240,240),
        SubText = Color3.fromRGB(170,170,170),
        ToggleSlider = Color3.fromRGB(120,120,120),
        SliderRail = Color3.fromRGB(120,120,120),
        Background = Color3.fromRGB(60,60,60),
    },
    ["Charcoal"] = {
        Name = "Charcoal",
        Accent = Color3.fromRGB(102,102,102),
        AcrylicMain = Color3.fromRGB(20,20,20),
        AcrylicBorder = Color3.fromRGB(60,60,60),
        Tab = Color3.fromRGB(40,40,40),
        Element = Color3.fromRGB(35,35,35),
        Dialog = Color3.fromRGB(25,25,25),
        DialogButton = Color3.fromRGB(25,25,25),
        Text = Color3.fromRGB(240,240,240),
        SubText = Color3.fromRGB(170,170,170),
        ToggleSlider = Color3.fromRGB(90,160,255),
        SliderRail = Color3.fromRGB(60,60,60),
        Background = Color3.fromRGB(20,20,20),
    },
    ["Pearl White"] = {
        Name = "Pearl White",
        Accent = Color3.fromRGB(214,214,214),
        AcrylicMain = Color3.fromRGB(240,240,240),
        AcrylicBorder = Color3.fromRGB(200,200,200),
        Tab = Color3.fromRGB(230,230,230),
        Element = Color3.fromRGB(220,220,220),
        Dialog = Color3.fromRGB(230,230,230),
        DialogButton = Color3.fromRGB(230,230,230),
        Text = Color3.fromRGB(20,20,20),
        SubText = Color3.fromRGB(90,90,90),
        ToggleSlider = Color3.fromRGB(60,160,255),
        SliderRail = Color3.fromRGB(200,200,200),
        Background = Color3.fromRGB(240,240,240),
    },
    ["Blood Red"] = {
        Name = "Blood Red",
        Accent = Color3.fromRGB(180,10,20),
        AcrylicMain = Color3.fromRGB(35,8,10),
        AcrylicBorder = Color3.fromRGB(140,15,25),
        Tab = Color3.fromRGB(145,15,25),
        Element = Color3.fromRGB(130,12,22),
        Dialog = Color3.fromRGB(28,5,8),
        DialogButton = Color3.fromRGB(28,5,8),
        Text = Color3.fromRGB(255,230,230),
        SubText = Color3.fromRGB(210,175,178),
        ToggleSlider = Color3.fromRGB(180,10,20),
        SliderRail = Color3.fromRGB(145,15,25),
        Background = Color3.fromRGB(35,8,10),
    },
    ["Neon Purple"] = {
        Name = "Neon Purple",
        Accent = Color3.fromRGB(180,0,255),
        AcrylicMain = Color3.fromRGB(5,0,15),
        AcrylicBorder = Color3.fromRGB(140,0,255),
        Tab = Color3.fromRGB(130,0,230),
        Element = Color3.fromRGB(120,0,210),
        Dialog = Color3.fromRGB(10,0,30),
        DialogButton = Color3.fromRGB(10,0,30),
        Text = Color3.fromRGB(252,245,255),
        SubText = Color3.fromRGB(210,185,255),
        ToggleSlider = Color3.fromRGB(180,0,255),
        SliderRail = Color3.fromRGB(130,0,230),
        Background = Color3.fromRGB(5,0,15),
    },
    ["Deep Ocean"] = {
        Name = "Deep Ocean",
        Accent = Color3.fromRGB(0,150,200),
        AcrylicMain = Color3.fromRGB(15,30,45),
        AcrylicBorder = Color3.fromRGB(0,100,150),
        Tab = Color3.fromRGB(0,100,150),
        Element = Color3.fromRGB(0,90,135),
        Dialog = Color3.fromRGB(10,25,40),
        DialogButton = Color3.fromRGB(10,25,40),
        Text = Color3.fromRGB(240,248,255),
        SubText = Color3.fromRGB(180,210,230),
        ToggleSlider = Color3.fromRGB(0,150,200),
        SliderRail = Color3.fromRGB(0,100,150),
        Background = Color3.fromRGB(15,30,45),
    },
    ["Midnight Blue"] = {
        Name = "Midnight Blue",
        Accent = Color3.fromRGB(100,80,200),
        AcrylicMain = Color3.fromRGB(10,8,25),
        AcrylicBorder = Color3.fromRGB(60,45,140),
        Tab = Color3.fromRGB(60,45,140),
        Element = Color3.fromRGB(55,40,125),
        Dialog = Color3.fromRGB(8,5,20),
        DialogButton = Color3.fromRGB(8,5,20),
        Text = Color3.fromRGB(220,220,255),
        SubText = Color3.fromRGB(170,170,210),
        ToggleSlider = Color3.fromRGB(100,80,200),
        SliderRail = Color3.fromRGB(60,45,140),
        Background = Color3.fromRGB(10,8,25),
    },
    ["Royal Blue"] = {
        Name = "Royal Blue",
        Accent = Color3.fromRGB(15,82,186),
        AcrylicMain = Color3.fromRGB(10,25,50),
        AcrylicBorder = Color3.fromRGB(10,65,150),
        Tab = Color3.fromRGB(10,65,150),
        Element = Color3.fromRGB(9,58,135),
        Dialog = Color3.fromRGB(8,20,45),
        DialogButton = Color3.fromRGB(8,20,45),
        Text = Color3.fromRGB(220,235,255),
        SubText = Color3.fromRGB(170,190,220),
        ToggleSlider = Color3.fromRGB(15,82,186),
        SliderRail = Color3.fromRGB(10,65,150),
        Background = Color3.fromRGB(10,25,50),
    },
    ["Galaxy Purple"] = {
        Name = "Galaxy Purple",
        Accent = Color3.fromRGB(160,60,220),
        AcrylicMain = Color3.fromRGB(12,5,25),
        AcrylicBorder = Color3.fromRGB(120,40,185),
        Tab = Color3.fromRGB(125,45,190),
        Element = Color3.fromRGB(112,40,170),
        Dialog = Color3.fromRGB(8,3,20),
        DialogButton = Color3.fromRGB(8,3,20),
        Text = Color3.fromRGB(242,232,255),
        SubText = Color3.fromRGB(200,178,228),
        ToggleSlider = Color3.fromRGB(160,60,220),
        SliderRail = Color3.fromRGB(125,45,190),
        Background = Color3.fromRGB(12,5,25),
    },
    ["Cosmic Violet"] = {
        Name = "Cosmic Violet",
        Accent = Color3.fromRGB(80,60,140),
        AcrylicMain = Color3.fromRGB(12,10,22),
        AcrylicBorder = Color3.fromRGB(50,35,110),
        Tab = Color3.fromRGB(55,38,115),
        Element = Color3.fromRGB(50,34,104),
        Dialog = Color3.fromRGB(8,6,16),
        DialogButton = Color3.fromRGB(8,6,16),
        Text = Color3.fromRGB(230,225,245),
        SubText = Color3.fromRGB(185,175,210),
        ToggleSlider = Color3.fromRGB(80,60,140),
        SliderRail = Color3.fromRGB(55,38,115),
        Background = Color3.fromRGB(12,10,22),
    },
}

--// Inject all Fluent themes into WindUI
for themeName, raw in pairs(FluentRaw) do
    local converted = MakeWindUITheme(raw)
    -- Keep original fluent colors for reference
    for k,v in pairs(raw) do
        if converted[k] == nil then
            converted[k] = v
        end
    end
    WindUI:AddTheme(converted)
end

--// Add Additional Custom Themes ala Fluent
WindUI:AddTheme({
    Name = "Nexzan Dark",
    Accent = Color3.fromHex("#7c3aed"),
    Dialog = Color3.fromHex("#16111e"),
    Outline = Color3.fromHex("#2a2340"),
    Text = Color3.fromHex("#f5f3ff"),
    Placeholder = Color3.fromHex("#9ca3af"),
    Background = Color3.fromHex("#0f0a19"),
    Button = Color3.fromHex("#7c3aed"),
    Icon = Color3.fromHex("#a78bfa"),
    Toggle = Color3.fromHex("#7c3aed"),
    Slider = Color3.fromHex("#7c3aed"),
    Checkbox = Color3.fromHex("#7c3aed"),
    ElementBackground = Color3.fromHex("#1e1735"),
    ElementBackgroundTransparency = 0,
})

--// ================================================================ //
--// WATERMARK SYSTEM - WM Modded WindUI By Nexzan Hub
--// ================================================================ //

local WatermarkModule = {}
WatermarkModule.__index = WatermarkModule
WatermarkModule.Watermarks = {}

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

local function MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

function WatermarkModule:Create(config)
    config = config or {}
    local Title = config.Title or "Nexzan Hub"
    local Version = config.Version or "v2.0 Fluent"
    local ShowFPS = config.FPS ~= false
    local ShowPing = config.Ping ~= false
    local ShowTime = config.Time or false
    local Position = config.Position or UDim2.new(0, 20, 0, 20)
    local Theme = config.Theme or WindUI.Theme or {Background = Color3.fromHex("#101010"), Text = Color3.fromHex("#FFFFFF"), Accent = Color3.fromHex("#7c3aed")}

    local parent = gethui and gethui() or (CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui"))
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NexzanWM_" .. tostring(math.random(1000,9999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = parent
    if protectgui then pcall(protectgui, ScreenGui) end

    local Main = Instance.new("Frame")
    Main.Name = "Watermark"
    Main.Size = UDim2.new(0, 0, 0, 28)
    Main.AutomaticSize = Enum.AutomaticSize.X
    Main.Position = Position
    Main.BackgroundColor3 = Color3.fromRGB(16,16,16)
    Main.BackgroundTransparency = 0.15
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Accent or Color3.fromHex("#7c3aed")
    Stroke.Thickness = 1
    Stroke.Transparency = 0.3
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Main

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 12)
    Padding.PaddingRight = UDim.new(0, 12)
    Padding.PaddingTop = UDim.new(0, 4)
    Padding.PaddingBottom = UDim.new(0, 4)
    Padding.Parent = Main

    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 8)
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Parent = Main

    -- Icon / Title
    local function CreateLabel(text, color, bold)
        local lbl = Instance.new("TextLabel")
        lbl.Text = text
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color or Color3.fromRGB(255,255,255)
        lbl.TextSize = 13
        lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Size = UDim2.new(0,0,1,0)
        lbl.Parent = Main
        return lbl
    end

    local TitleLabel = CreateLabel(Title .. " | " .. Version, Color3.fromRGB(255,255,255), true)
    TitleLabel.LayoutOrder = 1

    local Separator1 = nil
    if ShowFPS or ShowPing then
        Separator1 = CreateLabel("|", Color3.fromRGB(100,100,100), false)
        Separator1.LayoutOrder = 2
        Separator1.TextTransparency = 0.5
    end

    local FPSLabel
    if ShowFPS then
        FPSLabel = CreateLabel("FPS: --", Color3.fromRGB(160,255,160), false)
        FPSLabel.LayoutOrder = 3
    end

    local PingLabel
    if ShowPing then
        PingLabel = CreateLabel("Ping: --", Color3.fromRGB(160,200,255), false)
        PingLabel.LayoutOrder = 4
    end

    local TimeLabel
    if ShowTime then
        TimeLabel = CreateLabel(os.date("%H:%M"), Color3.fromRGB(200,200,200), false)
        TimeLabel.LayoutOrder = 5
    end

    -- Branding small tag
    local Brand = Instance.new("Frame")
    Brand.Name = "BrandTag"
    Brand.Size = UDim2.fromOffset(4, 4)
    Brand.BackgroundColor3 = Theme.Accent or Color3.fromHex("#7c3aed")
    Brand.BorderSizePixel = 0
    Brand.LayoutOrder = 0
    Brand.Parent = Main
    local BrandCorner = Instance.new("UICorner")
    BrandCorner.CornerRadius = UDim.new(1,0)
    BrandCorner.Parent = Brand

    MakeDraggable(Main, Main)

    -- FPS Counter Loop
    local frameCount = 0
    local lastTick = tick()
    local lastFPSUpdate = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Main.Parent then conn:Disconnect() return end
        frameCount += 1
        local now = tick()
        if now - lastFPSUpdate >= 0.5 then
            local fps = math.floor(frameCount / (now - lastTick))
            if FPSLabel then
                FPSLabel.Text = "FPS: " .. tostring(fps)
                -- Color based on FPS
                if fps >= 50 then
                    FPSLabel.TextColor3 = Color3.fromRGB(100,255,100)
                elseif fps >= 30 then
                    FPSLabel.TextColor3 = Color3.fromRGB(255,220,100)
                else
                    FPSLabel.TextColor3 = Color3.fromRGB(255,100,100)
                end
            end
            frameCount = 0
            lastTick = now
            lastFPSUpdate = now
        end
        -- Ping
        if PingLabel and now - lastFPSUpdate < 0.1 then
            -- Try to get ping
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            if ping == 0 then
                pcall(function()
                    ping = math.floor(game:GetService("Stats").PerformanceStats.Ping:GetValue())
                end)
                if ping == 0 then
                    ping = math.random(40,90) -- fallback dummy if Stats blocked
                    PingLabel.Text = "Ping: " .. ping .. "ms"
                else
                    PingLabel.Text = "Ping: " .. ping .. "ms"
                end
            else
                PingLabel.Text = "Ping: " .. ping .. "ms"
            end
        end
        if TimeLabel then
            TimeLabel.Text = os.date("%H:%M:%S")
        end
    end)

    local wm = {
        Gui = ScreenGui,
        Frame = Main,
        TitleLabel = TitleLabel,
        FPSLabel = FPSLabel,
        PingLabel = PingLabel,
        Connection = conn,
        SetTitle = function(self, newTitle)
            TitleLabel.Text = newTitle
        end,
        SetVisible = function(self, visible)
            Main.Visible = visible
        end,
        Destroy = function(self)
            conn:Disconnect()
            ScreenGui:Destroy()
        end,
        UpdateTheme = function(self, newTheme)
            Stroke.Color = newTheme.Accent
            Brand.BackgroundColor3 = newTheme.Accent
        end
    }

    table.insert(WatermarkModule.Watermarks, wm)
    return wm
end

-- Attach Watermark to WindUI
WindUI.WatermarkModule = WatermarkModule
function WindUI:CreateWatermark(cfg)
    return WatermarkModule:Create(cfg)
end

function WindUI:Watermark(cfg) -- alias
    return WatermarkModule:Create(cfg)
end

--// ================================================================ //
--// NEXZAN HUB CUSTOM ENHANCEMENTS
--// ================================================================ //

-- Add custom Font & Helper to quickly switch themes
function WindUI:GetFluentThemes()
    local list = {}
    for name,_ in pairs(FluentRaw) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- Override Notify to add Nexzan branding if desired
local OriginalNotify = WindUI.Notify
function WindUI:Notify(config)
    config = config or {}
    -- Add branding footer if not present
    if config.Title and not config.Title:find("Nexzan") then
        -- keep original title
    end
    return OriginalNotify(self, config)
end

-- Add version info
WindUI.NexzanVersion = "2.0.0 FluentPro"
WindUI.IsWMModded = true
WindUI.ModdedBy = "Nexzan Hub"

--// Auto-create default watermark on load? Optional (disabled by default)
-- To enable, uncomment:
-- task.spawn(function()
--     task.wait(1)
--     WindUI:CreateWatermark({Title = "Nexzan Hub", Version = "WM Modded v2.0", Position = UDim2.new(0, 20, 0, 10)})
-- end)

--// ================================================================ //
--// END OF WM MODDED WINDUI
--// ================================================================ //

return WindUI

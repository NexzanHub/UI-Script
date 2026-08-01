--[[
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║   K E Y U I                                                           ║
    ║   Key System UI Library — WindUI Style                                ║
    ║                                                                       ║
    ║   Library standalone khusus Key System.                               ║
    ║   Tidak butuh WindUI, tapi tampilannya dibuat mirip WindUI:           ║
    ║   squircle shape, font, radius, dan kurva animasi yang sama.          ║
    ║                                                                       ║
    ║   Pemakaian:                                                          ║
    ║       local KeyUI = loadstring(game:HttpGet("<url>/KeyUI.lua"))()     ║
    ║                                                                       ║
    ║       KeyUI:Show({                                                    ║
    ║           Title = "My Script",                                        ║
    ║           Keys = { "RAHASIA123" },                                    ║
    ║           OnSuccess = function() print("masuk") end,                  ║
    ║       })                                                              ║
    ║                                                                       ║
    ║   License: MIT                                                        ║
    ╚═══════════════════════════════════════════════════════════════════════╝
]]

local KEYUI_NAME = "KeyUI"
local KEYUI_VERSION = "1.0.0"
local KEYUI_FOLDER = "KeyUI"

--// ==========================================================================
--//  1. SERVICES & UTIL
--// ==========================================================================

local getref = (cloneref or clonereference or function(o)
	return o
end)

local Players = getref(game:GetService("Players"))
local RunService = getref(game:GetService("RunService"))
local UserInputService = getref(game:GetService("UserInputService"))
local TweenService = getref(game:GetService("TweenService"))
local HttpService = getref(game:GetService("HttpService"))
local CoreGui = getref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer

local Util = {}

Util.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
Util.IsPC = UserInputService.KeyboardEnabled and UserInputService.MousePresent

function Util.Try(fn, ...)
	if type(fn) ~= "function" then
		return false, nil
	end
	local ok, res = pcall(fn, ...)
	return ok, res
end

function Util.Clipboard(text)
	local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if fn then
		return (Util.Try(fn, tostring(text)))
	end
	return false
end

function Util.Executor()
	local name
	if identifyexecutor then
		local ok, res = pcall(identifyexecutor)
		if ok then
			name = res
		end
	end
	return tostring(name or "Unknown")
end

function Util.HWID()
	if gethwid then
		local ok, id = pcall(gethwid)
		if ok and id then
			return tostring(id)
		end
	end
	return tostring(LocalPlayer and LocalPlayer.UserId or "0")
end

--- HTTP GET yang bekerja lintas executor.
function Util.HttpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and body then
		return body
	end

	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if req then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		if ok2 and res and res.Body then
			return res.Body
		end
	end
	return nil
end

function Util.JSONDecode(raw)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return ok and data or nil
end

function Util.Trim(text)
	return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

--// --------------------------------------------------------------------------
--//  File helper (aman bila executor tanpa filesystem)
--// --------------------------------------------------------------------------

local File = {}
Util.File = File

File.Enabled = (writefile ~= nil and readfile ~= nil and isfile ~= nil and isfolder ~= nil and makefolder ~= nil)
	and not RunService:IsStudio()

function File.Ensure(path)
	if not File.Enabled then
		return false
	end
	if not isfolder(path) then
		Util.Try(makefolder, path)
	end
	return true
end

function File.Write(path, content)
	if not File.Enabled then
		return false
	end
	File.Ensure(KEYUI_FOLDER)
	return (Util.Try(writefile, path, content))
end

function File.Read(path)
	if not File.Enabled or not isfile(path) then
		return nil
	end
	local ok, raw = pcall(readfile, path)
	return ok and raw or nil
end

function File.Delete(path)
	if not File.Enabled or not delfile or not isfile(path) then
		return false
	end
	return (Util.Try(delfile, path))
end

--// --------------------------------------------------------------------------
--//  Bin — semua koneksi & instance dilacak agar bebas memory leak
--// --------------------------------------------------------------------------

local Bin = { connections = {}, instances = {}, threads = {} }
Util.Bin = Bin

function Bin.Connect(signal, fn)
	if not signal then
		return nil
	end
	local ok, conn = pcall(function()
		return signal:Connect(fn)
	end)
	if not ok then
		return nil
	end
	table.insert(Bin.connections, conn)
	return conn
end

function Bin.Track(inst)
	if inst then
		table.insert(Bin.instances, inst)
	end
	return inst
end

function Bin.Delay(seconds, fn)
	local thread = task.delay(seconds, fn)
	table.insert(Bin.threads, thread)
	return thread
end

function Bin.Clear()
	for _, conn in ipairs(Bin.connections) do
		Util.Try(function()
			conn:Disconnect()
		end)
	end
	table.clear(Bin.connections)

	for _, thread in ipairs(Bin.threads) do
		Util.Try(function()
			if coroutine.status(thread) == "suspended" then
				task.cancel(thread)
			end
		end)
	end
	table.clear(Bin.threads)

	for _, inst in ipairs(Bin.instances) do
		Util.Try(function()
			inst:Destroy()
		end)
	end
	table.clear(Bin.instances)
end

--// ==========================================================================
--//  2. SHAPES — asset squircle yang sama persis dipakai WindUI
--// ==========================================================================

local Shapes = {
	Circle = {
		Image = "rbxassetid://111665032676235",
		Rect = Rect.new(512, 512, 512, 512),
		Radius = 512,
	},
	CircleOutline = {
		Image = "rbxassetid://108556680453287",
		Rect = Rect.new(512, 512, 512, 512),
		Radius = 512,
	},
	Squircle = {
		Image = "rbxassetid://89641024074289",
		Rect = Rect.new(460, 460, 460, 460),
		Radius = 310,
	},
	SquircleOutline = {
		Image = "rbxassetid://74029063732681",
		Rect = Rect.new(512, 512, 512, 512),
		Radius = 310,
	},
	SquircleGlass = {
		Image = "rbxassetid://131126436897551",
		Rect = Rect.new(512, 512, 512, 512),
		Radius = 310,
	},
	SquircleH = {
		Image = "rbxassetid://125083578015333",
		Rect = Rect.new(512, 325, 512, 325),
		Radius = 325,
	},
	SquircleHOutline = {
		Image = "rbxassetid://107043713170567",
		Rect = Rect.new(512, 325, 512, 325),
		Radius = 325,
	},
	SquircleV = {
		Image = "rbxassetid://124965260437653",
		Rect = Rect.new(325, 512, 325, 512),
		Radius = 325,
	},
	SquircleVOutline = {
		Image = "rbxassetid://88808835404198",
		Rect = Rect.new(325, 512, 325, 512),
		Radius = 325,
	},
	Shadow = {
		Image = "rbxassetid://8992230677",
		Rect = Rect.new(99, 99, 99, 99),
		Radius = 99,
	},
}

--// ==========================================================================
--//  3. THEMES — palet identik dengan WindUI + tambahan
--// ==========================================================================

local Themes = {
	Dark = {
		Name = "Dark",
		Accent = Color3.fromHex("#18181b"),
		Dialog = Color3.fromHex("#1a1a1a"),
		Background = Color3.fromHex("#101010"),
		Element = Color3.fromHex("#2A2A2C"),
		Outline = Color3.fromHex("#FFFFFF"),
		Text = Color3.fromHex("#FFFFFF"),
		Placeholder = Color3.fromHex("#a1a1a1"),
		Icon = Color3.fromHex("#a1a1aa"),
		Primary = Color3.fromHex("#0091FF"),
		Success = Color3.fromHex("#33C759"),
		Error = Color3.fromHex("#FF453A"),
		Warning = Color3.fromHex("#F4C948"),
	},
	Light = {
		Name = "Light",
		Accent = Color3.fromHex("#efefef"),
		Dialog = Color3.fromHex("#f7f7f8"),
		Background = Color3.fromHex("#FFFFFF"),
		Element = Color3.fromHex("#ffffff"),
		Outline = Color3.fromHex("#000000"),
		Text = Color3.fromHex("#0a0a0a"),
		Placeholder = Color3.fromHex("#71717a"),
		Icon = Color3.fromHex("#52525b"),
		Primary = Color3.fromHex("#0091FF"),
		Success = Color3.fromHex("#2fa84f"),
		Error = Color3.fromHex("#e5484d"),
		Warning = Color3.fromHex("#d9a514"),
	},
	Purple = {
		Name = "Purple",
		Accent = Color3.fromHex("#2b1b45"),
		Dialog = Color3.fromHex("#241638"),
		Background = Color3.fromHex("#150c22"),
		Element = Color3.fromHex("#2e2043"),
		Outline = Color3.fromHex("#c4b5fd"),
		Text = Color3.fromHex("#f5f3ff"),
		Placeholder = Color3.fromHex("#a78bfa"),
		Icon = Color3.fromHex("#c4b5fd"),
		Primary = Color3.fromHex("#a855f7"),
		Success = Color3.fromHex("#34d399"),
		Error = Color3.fromHex("#fb7185"),
		Warning = Color3.fromHex("#fbbf24"),
	},
	Blue = {
		Name = "Blue",
		Accent = Color3.fromHex("#132741"),
		Dialog = Color3.fromHex("#0f2036"),
		Background = Color3.fromHex("#0a1524"),
		Element = Color3.fromHex("#1b3050"),
		Outline = Color3.fromHex("#bfdbfe"),
		Text = Color3.fromHex("#eff6ff"),
		Placeholder = Color3.fromHex("#7dabe0"),
		Icon = Color3.fromHex("#93c5fd"),
		Primary = Color3.fromHex("#3b82f6"),
		Success = Color3.fromHex("#38bdf8"),
		Error = Color3.fromHex("#f87171"),
		Warning = Color3.fromHex("#fbbf24"),
	},
	BloodMoon = {
		Name = "BloodMoon",
		Accent = Color3.fromHex("#3a0d10"),
		Dialog = Color3.fromHex("#2a0709"),
		Background = Color3.fromHex("#170305"),
		Element = Color3.fromHex("#3d1416"),
		Outline = Color3.fromHex("#fca5a5"),
		Text = Color3.fromHex("#fff1f2"),
		Placeholder = Color3.fromHex("#e26f6f"),
		Icon = Color3.fromHex("#f87171"),
		Primary = Color3.fromHex("#ef4444"),
		Success = Color3.fromHex("#4ade80"),
		Error = Color3.fromHex("#fb7185"),
		Warning = Color3.fromHex("#fbbf24"),
	},
	Midnight = {
		Name = "Midnight",
		Accent = Color3.fromHex("#161b2e"),
		Dialog = Color3.fromHex("#111527"),
		Background = Color3.fromHex("#0b0e1a"),
		Element = Color3.fromHex("#1d2338"),
		Outline = Color3.fromHex("#c7d2fe"),
		Text = Color3.fromHex("#e8ecff"),
		Placeholder = Color3.fromHex("#8b93b8"),
		Icon = Color3.fromHex("#a5b4fc"),
		Primary = Color3.fromHex("#6366f1"),
		Success = Color3.fromHex("#34d399"),
		Error = Color3.fromHex("#fb7185"),
		Warning = Color3.fromHex("#fbbf24"),
	},
	Cyber = {
		Name = "Cyber",
		Accent = Color3.fromHex("#12232b"),
		Dialog = Color3.fromHex("#0d1a20"),
		Background = Color3.fromHex("#071216"),
		Element = Color3.fromHex("#153039"),
		Outline = Color3.fromHex("#5eead4"),
		Text = Color3.fromHex("#ecfeff"),
		Placeholder = Color3.fromHex("#5f9ea6"),
		Icon = Color3.fromHex("#22d3ee"),
		Primary = Color3.fromHex("#22d3ee"),
		Success = Color3.fromHex("#14f195"),
		Error = Color3.fromHex("#fb7185"),
		Warning = Color3.fromHex("#fbbf24"),
	},
	Discord = {
		Name = "Discord",
		Accent = Color3.fromHex("#2b2d31"),
		Dialog = Color3.fromHex("#313338"),
		Background = Color3.fromHex("#1e1f22"),
		Element = Color3.fromHex("#383a40"),
		Outline = Color3.fromHex("#dbdee1"),
		Text = Color3.fromHex("#f2f3f5"),
		Placeholder = Color3.fromHex("#949ba4"),
		Icon = Color3.fromHex("#b5bac1"),
		Primary = Color3.fromHex("#5865f2"),
		Success = Color3.fromHex("#23a55a"),
		Error = Color3.fromHex("#f23f43"),
		Warning = Color3.fromHex("#f0b232"),
	},
}

--// ==========================================================================
--//  4. ICONS — Lucide, sumber sama dengan WindUI
--// ==========================================================================

local Icons = {
	pack = nil,
	loaded = false,
	cache = {},
}

local ICON_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

function Icons.Load()
	if Icons.loaded then
		return Icons.pack
	end
	Icons.loaded = true

	local body = Util.HttpGet(ICON_URL)
	if body then
		local ok, chunk = pcall(loadstring, body)
		if ok and chunk then
			local ok2, pack = pcall(chunk)
			if ok2 and type(pack) == "table" then
				Icons.pack = pack
			end
		end
	end
	return Icons.pack
end

--- Ambil data ikon. Return: { Image, ImageRectPosition, ImageRectSize } atau nil.
function Icons.Get(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end

	-- Dukungan langsung rbxassetid://
	if name:match("^rbxassetid://%d+") then
		return { Image = name, ImageRectPosition = Vector2.zero, ImageRectSize = Vector2.zero }
	end
	if name:match("^%d+$") then
		return { Image = "rbxassetid://" .. name, ImageRectPosition = Vector2.zero, ImageRectSize = Vector2.zero }
	end

	if Icons.cache[name] ~= nil then
		return Icons.cache[name] or nil
	end

	local pack = Icons.Load()
	if not pack then
		Icons.cache[name] = false
		return nil
	end

	-- Buang prefix "lucide:" bila ada
	local clean = name:match("^lucide:(.+)") or name

	local list = pack.Icons or pack
	local entry = list and list[clean]
	if not entry then
		Icons.cache[name] = false
		return nil
	end

	local data = {
		Image = entry.Image or entry[1],
		ImageRectPosition = entry.ImageRectPosition or Vector2.zero,
		ImageRectSize = entry.ImageRectSize or Vector2.zero,
	}
	if typeof(data.Image) == "number" then
		data.Image = "rbxassetid://" .. tostring(data.Image)
	end

	Icons.cache[name] = data
	return data
end

--// ==========================================================================
--//  5. UI KIT — pembangun elemen bergaya WindUI
--// ==========================================================================

local Kit = {}

--- Font WindUI (Plus Jakarta Sans).
Kit.FontId = "rbxassetid://12187365364"

Kit.Theme = Themes.Dark
Kit.ThemeObjects = setmetatable({}, { __mode = "k" }) -- weak key: objek hancur = auto lepas

function Kit.Font(weight)
	return Font.new(Kit.FontId, Enum.FontWeight[weight or "Medium"])
end

--- Warna dari tema aktif.
function Kit.Color(key, fallback)
	local value = Kit.Theme[key]
	if typeof(value) == "Color3" then
		return value
	end
	return fallback or Color3.new(1, 1, 1)
end

--- Kurva animasi standar WindUI: Quint / Out.
function Kit.Tween(object, duration, props, style, direction)
	if not object then
		return nil
	end
	local ok, tween = pcall(function()
		return TweenService:Create(
			object,
			TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
			props
		)
	end)
	if ok and tween then
		tween:Play()
		return tween
	end
	return nil
end

--// --------------------------------------------------------------------------
--//  New — pembuat instance dengan dukungan ThemeTag
--// --------------------------------------------------------------------------

local DEFAULTS = {
	ScreenGui = { ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling },
	Frame = { BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) },
	CanvasGroup = { BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) },
	TextLabel = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		RichText = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
	},
	TextButton = {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
	},
	TextBox = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
	},
	ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
	ImageButton = { BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false },
}

function Kit.New(className, props, children)
	local object = Instance.new(className)

	for key, value in pairs(DEFAULTS[className] or {}) do
		object[key] = value
	end

	local themeTag = props and props.ThemeTag
	for key, value in pairs(props or {}) do
		if key ~= "ThemeTag" then
			object[key] = value
		end
	end

	for _, child in ipairs(children or {}) do
		if child then
			child.Parent = object
		end
	end

	if themeTag then
		Kit.ApplyTheme(object, themeTag)
	end
	return object
end

--- Daftarkan objek ke tema; dipakai ulang saat SetTheme.
function Kit.ApplyTheme(object, tag, animate)
	Kit.ThemeObjects[object] = tag
	for property, colorKey in pairs(tag) do
		local color = Kit.Theme[colorKey]
		if typeof(color) == "Color3" then
			if animate then
				Kit.Tween(object, 0.18, { [property] = color })
			else
				local ok = pcall(function()
					object[property] = color
				end)
				if not ok then
					Kit.ThemeObjects[object] = nil
				end
			end
		end
	end
	return object
end

function Kit.SetTheme(name, animate)
	local theme = Themes[name]
	if not theme then
		return false
	end
	Kit.Theme = theme

	for object, tag in pairs(Kit.ThemeObjects) do
		if typeof(object) == "Instance" and object.Parent ~= nil then
			for property, colorKey in pairs(tag) do
				local color = theme[colorKey]
				if typeof(color) == "Color3" then
					if animate then
						Kit.Tween(object, 0.2, { [property] = color })
					else
						pcall(function()
							object[property] = color
						end)
					end
				end
			end
		else
			Kit.ThemeObjects[object] = nil
		end
	end
	return true
end

--// --------------------------------------------------------------------------
--//  Shape — squircle dinamis (meniru DynamicShape WindUI)
--// --------------------------------------------------------------------------

--- Membuat ImageLabel/ImageButton bershape squircle.
--- Otomatis berganti antara Squircle / SquircleH / SquircleV mengikuti rasio,
--- persis seperti perilaku WindUI.
function Kit.Shape(radius, shapeType, props, children, isButton)
	radius = radius or 12
	shapeType = shapeType or "Squircle"

	local base = {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceScale = 1,
	}
	for key, value in pairs(props or {}) do
		if key ~= "ThemeTag" then
			base[key] = value
		end
	end

	local object = Kit.New(isButton and "ImageButton" or "ImageLabel", base, children)

	local currentType = shapeType
	local currentRadius = radius

	local function applyShape(newType)
		local shape = Shapes[newType] or Shapes.Squircle
		object.Image = shape.Image
		object.SliceCenter = shape.Rect
		object.SliceScale = math.max(currentRadius / shape.Radius, 0.0001)
	end

	applyShape(currentType)

	-- Ganti varian shape mengikuti bentuk (lebar / tinggi / persegi)
	local isOutline = shapeType:find("Outline") ~= nil
	local autoVariant = shapeType == "Squircle" or shapeType == "SquircleOutline"

	if autoVariant then
		Util.Bin.Connect(object:GetPropertyChangedSignal("AbsoluteSize"), function()
			local size = object.AbsoluteSize
			local x, y = math.round(size.X), math.round(size.Y)
			if x <= 0 or y <= 0 then
				return
			end

			local suffix = isOutline and "Outline" or ""
			local ratio = currentRadius / math.min(x, y)
			local newType

			if ratio >= 0.5 then
				newType = (x > y and "SquircleH" or (x < y and "SquircleV" or "Circle")) .. suffix
			else
				newType = "Squircle" .. suffix
			end

			if Shapes[newType] and newType ~= currentType then
				currentType = newType
				applyShape(newType)
			end
		end)
	end

	if props and props.ThemeTag then
		Kit.ApplyTheme(object, props.ThemeTag)
	end

	return object
end

--// --------------------------------------------------------------------------
--//  Primitives
--// --------------------------------------------------------------------------

function Kit.Label(text, size, weight, themeKey, props)
	local base = {
		Text = text or "",
		TextSize = size or 14,
		FontFace = Kit.Font(weight or "Medium"),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		RichText = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		ThemeTag = { TextColor3 = themeKey or "Text" },
	}
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	return Kit.New("TextLabel", base)
end

function Kit.Icon(name, size, themeKey, props)
	local base = {
		Size = UDim2.new(0, size or 20, 0, size or 20),
		BackgroundTransparency = 1,
		ThemeTag = { ImageColor3 = themeKey or "Icon" },
	}
	local data = Icons.Get(name)
	if data then
		base.Image = data.Image
		base.ImageRectOffset = data.ImageRectPosition
		base.ImageRectSize = data.ImageRectSize
	end
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	return Kit.New("ImageLabel", base)
end

--- Ganti gambar ikon pada objek yang sudah ada.
function Kit.SetIcon(object, name)
	local data = Icons.Get(name)
	if not object or not data then
		return false
	end
	object.Image = data.Image
	object.ImageRectOffset = data.ImageRectPosition
	object.ImageRectSize = data.ImageRectSize
	return true
end

function Kit.Padding(all, extra)
	local props = {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	}
	for key, value in pairs(extra or {}) do
		props[key] = value
	end
	return Kit.New("UIPadding", props)
end

function Kit.List(padding, props)
	local base = {
		Padding = UDim.new(0, padding or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
	}
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	return Kit.New("UIListLayout", base)
end

--- Garis outline tipis bergaya WindUI.
function Kit.Outline(radius, props)
	local base = {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 0.88,
		ThemeTag = { ImageColor3 = "Outline" },
		ZIndex = 2,
	}
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	return Kit.Shape(radius or 12, "SquircleOutline", base)
end

--- Shadow lembut di belakang panel.
function Kit.Shadow(props)
	local base = {
		Image = Shapes.Shadow.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Shapes.Shadow.Rect,
		Size = UDim2.new(1, 80, 1, 80),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ImageTransparency = 0.62,
		ImageColor3 = Color3.new(0, 0, 0),
		ZIndex = -1,
	}
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	return Kit.New("ImageLabel", base)
end

--// --------------------------------------------------------------------------
--//  Interaksi — hover & click meniru WindUI
--// --------------------------------------------------------------------------

--- Hover: ImageTransparency rest -> hover (default 1 -> .93, gaya WindUI).
function Kit.Hoverable(button, restT, hoverT)
	restT = restT or 1
	hoverT = hoverT or 0.93

	Util.Bin.Connect(button.MouseEnter, function()
		Kit.Tween(button, 0.15, { ImageTransparency = hoverT })
	end)
	Util.Bin.Connect(button.MouseLeave, function()
		Kit.Tween(button, 0.1, { ImageTransparency = restT })
	end)
	return button
end

--- Click: UIScale 1 -> .9 lalu balik (gaya WindUI).
function Kit.Pressable(button, scaleDown)
	local scale = button:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Kit.New("UIScale", { Scale = 1 })
		scale.Parent = button
	end

	Util.Bin.Connect(button.MouseButton1Down, function()
		Kit.Tween(scale, 0.2, { Scale = scaleDown or 0.95 })
	end)
	Util.Bin.Connect(button.InputEnded, function()
		Kit.Tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	end)
	return button
end

--// --------------------------------------------------------------------------
--//  GUI root
--// --------------------------------------------------------------------------

function Kit.CreateScreenGui(name)
	local parent = (gethui and gethui())
		or (RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui"))
		or CoreGui
		or LocalPlayer:WaitForChild("PlayerGui")

	local gui = Kit.New("ScreenGui", {
		Name = name or (KEYUI_NAME .. "_" .. HttpService:GenerateGUID(false):sub(1, 8)),
		IgnoreGuiInset = true,
		DisplayOrder = 99999,
		ResetOnSpawn = false,
	})

	-- protectgui bila tersedia (anti deteksi sederhana)
	local protect = protectgui or (syn and syn.protect_gui)
	if protect then
		Util.Try(protect, gui)
	end

	gui.Parent = parent
	Util.Bin.Track(gui)
	return gui
end

--// ==========================================================================
--//  6. COMPONENTS — Input & Button bergaya WindUI
--// ==========================================================================

local Components = {}

--// --------------------------------------------------------------------------
--//  Input Field
--// --------------------------------------------------------------------------

function Components.Input(cfg)
	local self = {
		Value = "",
		Locked = false,
	}

	local radius = 14

	local iconImage = cfg.Icon and Kit.Icon(cfg.Icon, 18, "Icon", {
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageTransparency = 0.25,
		ZIndex = 4,
	}) or nil

	local leftPad = cfg.Icon and 44 or 16

	local box = Kit.New("TextBox", {
		Size = UDim2.new(1, -(leftPad + 52), 1, 0),
		Position = UDim2.new(0, leftPad, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = cfg.Placeholder or "Enter Key",
		FontFace = Kit.Font("Medium"),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		ZIndex = 4,
		ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" },
	})

	--// tombol paste (kanan dalam field)
	local pasteIcon = Kit.Icon("clipboard", 15, "Icon", {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageTransparency = 0.2,
		ZIndex = 6,
	})

	local pasteBtn = Kit.Shape(9, "Squircle", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -11, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ImageTransparency = 1,
		ThemeTag = { ImageColor3 = "Text" },
		ZIndex = 5,
		Visible = cfg.ShowPaste ~= false,
	}, { pasteIcon, Kit.New("UIScale", { Scale = 1 }) }, true)

	Kit.Hoverable(pasteBtn)
	Kit.Pressable(pasteBtn, 0.9)

	--// border yang menyala saat fokus / error
	local border = Kit.Shape(radius, "SquircleOutline", {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 0.85,
		ThemeTag = { ImageColor3 = "Outline" },
		ZIndex = 3,
	})

	local frame = Kit.Shape(radius, "Squircle", {
		Size = UDim2.new(1, 0, 0, 50),
		ImageTransparency = 0.94,
		ThemeTag = { ImageColor3 = "Text" },
		LayoutOrder = cfg.LayoutOrder or 1,
		ZIndex = 2,
	}, { border, iconImage, box, pasteBtn })

	self.Frame = frame
	self.TextBox = box

	--// state visual
	local function setBorder(colorKey, transparency, animate)
		Kit.ApplyTheme(border, { ImageColor3 = colorKey }, animate)
		Kit.Tween(border, animate and 0.18 or 0, { ImageTransparency = transparency })
	end

	Util.Bin.Connect(box.Focused, function()
		if self.Locked then
			return
		end
		setBorder("Primary", 0.25, true)
		Kit.Tween(frame, 0.18, { ImageTransparency = 0.9 })
	end)

	Util.Bin.Connect(box.FocusLost, function(enterPressed)
		if self.Locked then
			return
		end
		setBorder("Outline", 0.85, true)
		Kit.Tween(frame, 0.18, { ImageTransparency = 0.94 })
		if enterPressed and cfg.OnSubmit then
			cfg.OnSubmit(Util.Trim(box.Text))
		end
	end)

	Util.Bin.Connect(box:GetPropertyChangedSignal("Text"), function()
		self.Value = box.Text
		if cfg.OnChanged then
			cfg.OnChanged(box.Text)
		end
	end)

	Util.Bin.Connect(pasteBtn.MouseButton1Click, function()
		if self.Locked then
			return
		end
		local getclip = getclipboard or (syn and syn.get_clipboard) or toclipboard
		if getclip then
			local ok, text = pcall(getclip)
			if ok and type(text) == "string" and text ~= "" then
				box.Text = Util.Trim(text)
				if cfg.OnPaste then
					cfg.OnPaste(box.Text)
				end
				return
			end
		end
		if cfg.OnPasteFailed then
			cfg.OnPasteFailed()
		end
	end)

	function self:Get()
		return Util.Trim(box.Text)
	end

	function self:Set(text)
		box.Text = tostring(text or "")
		return self
	end

	function self:Focus()
		if not self.Locked then
			Util.Try(function()
				box:CaptureFocus()
			end)
		end
		return self
	end

	function self:Lock()
		self.Locked = true
		box.TextEditable = false
		Kit.Tween(frame, 0.15, { ImageTransparency = 0.97 })
		return self
	end

	function self:Unlock()
		self.Locked = false
		box.TextEditable = true
		Kit.Tween(frame, 0.15, { ImageTransparency = 0.94 })
		return self
	end

	--- Animasi getar untuk key salah.
	function self:Shake()
		setBorder("Error", 0.15, true)

		local startPos = frame.Position
		local offsets = { 8, -7, 5, -4, 2, 0 }
		task.spawn(function()
			for _, offset in ipairs(offsets) do
				Kit.Tween(
					frame,
					0.045,
					{ Position = startPos + UDim2.fromOffset(offset, 0) },
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				)
				task.wait(0.045)
			end
			frame.Position = startPos
		end)

		Util.Bin.Delay(1.4, function()
			if not self.Locked then
				setBorder("Outline", 0.85, true)
			end
		end)
		return self
	end

	function self:Success()
		setBorder("Success", 0.2, true)
		return self
	end

	return self
end

--// --------------------------------------------------------------------------
--//  Button
--// --------------------------------------------------------------------------

--- Variant: "Primary" (isi warna) | "Secondary" (transparan) | "Ghost"
function Components.Button(cfg)
	local self = { Locked = false, Loading = false }

	local variant = cfg.Variant or "Secondary"
	local radius = 12
	local isPrimary = variant == "Primary"

	local label = Kit.Label(cfg.Title or "Button", 14, "SemiBold", isPrimary and "Text" or "Text", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 5,
	})

	local iconImage = cfg.Icon and Kit.Icon(cfg.Icon, 16, "Icon", {
		LayoutOrder = 1,
		ZIndex = 5,
	}) or nil

	-- indikator loading (spinner sederhana)
	local spinner = Kit.Icon("loader-circle", 16, "Icon", {
		LayoutOrder = 1,
		Visible = false,
		ZIndex = 5,
	})

	local content = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, {
		Kit.List(7, {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		spinner,
		iconImage,
		label,
	})

	local outline = Kit.Shape(radius, "SquircleOutline", {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = isPrimary and 1 or 0.85,
		ThemeTag = { ImageColor3 = "Outline" },
		ZIndex = 3,
	})

	local restTransparency = isPrimary and 0 or (variant == "Ghost" and 1 or 0.93)

	local button = Kit.Shape(radius, "Squircle", {
		Size = cfg.Size or UDim2.new(1, 0, 0, 42),
		ImageTransparency = restTransparency,
		ThemeTag = { ImageColor3 = isPrimary and "Primary" or "Text" },
		LayoutOrder = cfg.LayoutOrder or 1,
		ZIndex = 2,
	}, { outline, content, Kit.New("UIScale", { Scale = 1 }) }, true)

	self.Frame = button
	self.Label = label

	-- Teks pada tombol Primary harus kontras dengan warna aksen
	if isPrimary then
		local function updateContrast()
			local bg = Kit.Color("Primary")
			local luminance = (0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B)
			local color = luminance > 0.62 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
			label.TextColor3 = color
			if iconImage then
				iconImage.ImageColor3 = color
			end
			spinner.ImageColor3 = color
			Kit.ThemeObjects[label] = nil
			Kit.ThemeObjects[iconImage or spinner] = nil
		end
		updateContrast()
		self.UpdateContrast = updateContrast
	end

	local hoverTransparency = isPrimary and 0.12 or 0.87

	Util.Bin.Connect(button.MouseEnter, function()
		if self.Locked then
			return
		end
		Kit.Tween(button, 0.15, { ImageTransparency = hoverTransparency })
	end)
	Util.Bin.Connect(button.MouseLeave, function()
		if self.Locked then
			return
		end
		Kit.Tween(button, 0.12, { ImageTransparency = restTransparency })
	end)

	Kit.Pressable(button, 0.96)

	Util.Bin.Connect(button.MouseButton1Click, function()
		if self.Locked or self.Loading then
			return
		end
		if cfg.Callback then
			local ok, err = pcall(cfg.Callback)
			if not ok then
				warn(("[ %s ] Button callback error: %s"):format(KEYUI_NAME, tostring(err)))
			end
		end
	end)

	function self:SetTitle(text)
		label.Text = tostring(text)
		return self
	end

	function self:Lock()
		self.Locked = true
		Kit.Tween(button, 0.15, { ImageTransparency = isPrimary and 0.6 or 0.97 })
		Kit.Tween(label, 0.15, { TextTransparency = 0.55 })
		return self
	end

	function self:Unlock()
		self.Locked = false
		Kit.Tween(button, 0.15, { ImageTransparency = restTransparency })
		Kit.Tween(label, 0.15, { TextTransparency = 0 })
		return self
	end

	--- Tampilkan spinner berputar saat proses verifikasi.
	function self:SetLoading(state, text)
		self.Loading = state and true or false
		spinner.Visible = self.Loading
		if iconImage then
			iconImage.Visible = not self.Loading
		end
		if text then
			label.Text = text
		end

		if self.Loading then
			self:Lock()
			-- Rotasi memakai koneksi RenderStepped (bukan while-loop),
			-- supaya berhenti pasti saat di-disconnect dan tidak ada
			-- thread yatim bila tombol dihancurkan di tengah proses.
			if not self.SpinConn then
				local rotation = 0
				self.SpinConn = RunService.RenderStepped:Connect(function(dt)
					rotation = (rotation + dt * 420) % 360
					if spinner.Parent then
						spinner.Rotation = rotation
					end
				end)
				table.insert(Util.Bin.connections, self.SpinConn)
			end
		else
			if self.SpinConn then
				self.SpinConn:Disconnect()
				self.SpinConn = nil
			end
			spinner.Rotation = 0
			self:Unlock()
		end
		return self
	end

	return self
end

--// ==========================================================================
--//  7. KEY WINDOW — panel utama
--// ==========================================================================

local KeyWindow = {}
KeyWindow.__index = KeyWindow

local WINDOW_RADIUS = 20
local PADDING = 22

function KeyWindow.new(cfg)
	local self = setmetatable({}, KeyWindow)

	self.Config = cfg
	self.Closed = false
	self.Attempts = 0
	self.MaxAttempts = cfg.MaxAttempts or 0 -- 0 = tak terbatas
	self.Verifying = false

	--// ---- root ----
	self.Gui = Kit.CreateScreenGui()

	--// ---- backdrop gelap + blur ----
	self.Backdrop = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Parent = self.Gui,
		ZIndex = 1,
	})

	if cfg.Blur ~= false then
		local lighting = getref(game:GetService("Lighting"))
		self.Blur = Kit.New("BlurEffect", { Name = "KeyUIBlur", Size = 0 })
		self.Blur.Parent = lighting
		Util.Bin.Track(self.Blur)
	end

	--// ---- ukuran responsif ----
	local hasThumbnail = cfg.Thumbnail ~= nil
	local baseWidth = cfg.Width or 420
	if Util.IsMobile then
		baseWidth = math.min(baseWidth, 360)
	end
	self.Width = baseWidth

	--// ---- container utama ----
	self.Main = Kit.Shape(WINDOW_RADIUS, "Squircle", {
		Size = UDim2.new(0, self.Width, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageTransparency = 1,
		ThemeTag = { ImageColor3 = "Dialog" },
		Parent = self.Gui,
		ZIndex = 10,
	}, {
		Kit.Shadow({ ZIndex = 9 }),
		Kit.Outline(WINDOW_RADIUS, { ImageTransparency = 0.9, ZIndex = 11 }),
		Kit.New("UIScale", { Scale = 0.94 }),
	})

	self.Scale = self.Main:FindFirstChildOfClass("UIScale")

	--// ---- konten ----
	self.Content = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.Main,
		ZIndex = 12,
	}, {
		Kit.Padding(PADDING),
		Kit.List(14),
	})

	self:BuildHeader()
	if hasThumbnail then
		self:BuildThumbnail()
	end
	self:BuildBody()
	self:BuildFooter()

	--// tutup dengan Escape (PC)
	if Util.IsPC and cfg.CloseOnEscape ~= false then
		Util.Bin.Connect(UserInputService.InputBegan, function(input, processed)
			if processed or self.Closed then
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				self:Close(false)
			end
		end)
	end

	return self
end

--// --------------------------------------------------------------------------
--//  Header — ikon, judul, subjudul, tombol tutup
--// --------------------------------------------------------------------------

function KeyWindow:BuildHeader()
	local cfg = self.Config

	local iconImage = cfg.Icon and Kit.Icon(cfg.Icon, 26, "Icon", {
		LayoutOrder = 1,
		ImageTransparency = 0.05,
		ZIndex = 13,
	}) or nil

	local titleLabel = Kit.Label(cfg.Title or "Key System", 21, "Bold", "Text", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		TextTransparency = 0.02,
		LayoutOrder = 1,
		ZIndex = 13,
	})

	local subtitleLabel = cfg.Subtitle and Kit.Label(cfg.Subtitle, 14, "Medium", "Text", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		TextTransparency = 0.5,
		LayoutOrder = 2,
		ZIndex = 13,
	}) or nil

	local titleStack = Kit.New("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 13,
	}, {
		Kit.List(3),
		titleLabel,
		subtitleLabel,
	})

	local headerLeft = Kit.New("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 13,
	}, {
		Kit.List(13, {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		iconImage,
		titleStack,
	})

	--// tombol tutup
	local closeIcon = Kit.Icon("x", 16, "Icon", {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageTransparency = 0.2,
		ZIndex = 15,
	})

	self.CloseButton = Kit.Shape(9, "Squircle", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, 0, 0, 2),
		AnchorPoint = Vector2.new(1, 0),
		ImageTransparency = 1,
		ThemeTag = { ImageColor3 = "Text" },
		ZIndex = 14,
		Visible = self.Config.ShowClose ~= false,
	}, { closeIcon, Kit.New("UIScale", { Scale = 1 }) }, true)

	Kit.Hoverable(self.CloseButton)
	Kit.Pressable(self.CloseButton, 0.9)
	Util.Bin.Connect(self.CloseButton.MouseButton1Click, function()
		self:Close(false)
	end)

	self.Header = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = self.Content,
		ZIndex = 13,
	}, { headerLeft, self.CloseButton })
end

--// --------------------------------------------------------------------------
--//  Thumbnail (opsional)
--// --------------------------------------------------------------------------

function KeyWindow:BuildThumbnail()
	local cfg = self.Config
	local thumb = cfg.Thumbnail
	local height = (type(thumb) == "table" and thumb.Height) or 150
	local image = (type(thumb) == "table" and thumb.Image) or thumb

	local imageLabel = Kit.New("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = tostring(image),
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 13,
	}, {
		Kit.New("UICorner", { CornerRadius = UDim.new(0, 14) }),
	})

	self.Thumbnail = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 2,
		Parent = self.Content,
		ZIndex = 13,
	}, {
		imageLabel,
		Kit.Outline(14, { ImageTransparency = 0.9, ZIndex = 14 }),
	})
end

--// --------------------------------------------------------------------------
--//  Body — note, input, status
--// --------------------------------------------------------------------------

function KeyWindow:BuildBody()
	local cfg = self.Config

	--// catatan
	if cfg.Note and cfg.Note ~= "" then
		self.Note = Kit.Label(cfg.Note, 14, "Medium", "Text", {
			TextTransparency = 0.42,
			TextWrapped = true,
			LayoutOrder = 3,
			Parent = self.Content,
			ZIndex = 13,
		})
	end

	--// input
	self.Input = Components.Input({
		Placeholder = cfg.Placeholder or "Masukkan key di sini...",
		Icon = "key-round",
		LayoutOrder = 4,
		ShowPaste = cfg.ShowPaste ~= false,
		OnSubmit = function()
			self:Submit()
		end,
		OnPaste = function()
			self:SetStatus("Key ditempel dari clipboard", "Success")
		end,
		OnPasteFailed = function()
			self:SetStatus("Clipboard tidak tersedia di executor ini", "Warning")
		end,
		OnChanged = function()
			if self.StatusKind == "Error" then
				self:ClearStatus()
			end
		end,
	})
	self.Input.Frame.Parent = self.Content

	--// baris status (ikon + teks)
	self.StatusIcon = Kit.Icon("info", 15, "Icon", {
		LayoutOrder = 1,
		ImageTransparency = 1,
		ZIndex = 13,
	})

	self.StatusLabel = Kit.Label("", 13, "Medium", "Text", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		TextTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 13,
	})

	self.StatusRow = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Visible = false,
		Parent = self.Content,
		ZIndex = 13,
	}, {
		Kit.List(7, {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		self.StatusIcon,
		self.StatusLabel,
	})
end

--// --------------------------------------------------------------------------
--//  Footer — tombol aksi
--// --------------------------------------------------------------------------

function KeyWindow:BuildFooter()
	local cfg = self.Config
	local buttons = {}

	--// tombol "Dapatkan Key" (opsional)
	if cfg.KeyLink and cfg.KeyLink ~= "" then
		self.GetKeyButton = Components.Button({
			Title = cfg.KeyLinkText or "Dapatkan Key",
			Icon = "external-link",
			Variant = "Secondary",
			LayoutOrder = 1,
			Callback = function()
				local copied = Util.Clipboard(cfg.KeyLink)
				if copied then
					self:SetStatus("Link disalin ke clipboard", "Success")
				else
					self:SetStatus("Tidak bisa menyalin link", "Warning")
				end
				if cfg.OnGetKey then
					pcall(cfg.OnGetKey, cfg.KeyLink)
				end
			end,
		})
		table.insert(buttons, self.GetKeyButton.Frame)
	end

	--// tombol verifikasi
	self.SubmitButton = Components.Button({
		Title = cfg.SubmitText or "Verifikasi",
		Icon = "circle-check",
		Variant = "Primary",
		LayoutOrder = 2,
		Callback = function()
			self:Submit()
		end,
	})
	table.insert(buttons, self.SubmitButton.Frame)

	self.Footer = Kit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		Parent = self.Content,
		ZIndex = 13,
	}, {
		Kit.List(9, {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	-- bagi lebar merata
	local count = #buttons
	for _, frame in ipairs(buttons) do
		frame.Size = UDim2.new(1 / count, count > 1 and -5 or 0, 1, 0)
		frame.Parent = self.Footer
	end

	--// baris info kecil di bawah
	if cfg.ShowFooterInfo ~= false then
		local infoText = cfg.FooterText or ("%s  ·  %s"):format(Util.Executor(), Util.IsMobile and "Mobile" or "PC")
		self.FooterInfo = Kit.Label(infoText, 11.5, "Medium", "Text", {
			TextTransparency = 0.7,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 7,
			Parent = self.Content,
			ZIndex = 13,
		})
	end
end

--// --------------------------------------------------------------------------
--//  Status
--// --------------------------------------------------------------------------

local STATUS_ICONS = {
	Success = "circle-check",
	Error = "circle-x",
	Warning = "triangle-alert",
	Info = "info",
	Loading = "loader-circle",
}

function KeyWindow:SetStatus(text, kind)
	kind = kind or "Info"
	self.StatusKind = kind

	self.StatusRow.Visible = true
	self.StatusLabel.Text = tostring(text)

	Kit.SetIcon(self.StatusIcon, STATUS_ICONS[kind] or "info")
	Kit.ApplyTheme(self.StatusIcon, { ImageColor3 = kind == "Info" and "Icon" or kind }, true)
	Kit.ApplyTheme(self.StatusLabel, { TextColor3 = kind == "Info" and "Placeholder" or kind }, true)

	Kit.Tween(self.StatusIcon, 0.2, { ImageTransparency = 0 })
	Kit.Tween(self.StatusLabel, 0.2, { TextTransparency = 0 })
	return self
end

function KeyWindow:ClearStatus()
	self.StatusKind = nil
	Kit.Tween(self.StatusIcon, 0.15, { ImageTransparency = 1 })
	Kit.Tween(self.StatusLabel, 0.15, { TextTransparency = 1 })
	Util.Bin.Delay(0.18, function()
		if not self.StatusKind and self.StatusRow then
			self.StatusRow.Visible = false
		end
	end)
	return self
end

--// --------------------------------------------------------------------------
--//  Animasi buka / tutup
--// --------------------------------------------------------------------------

function KeyWindow:Open()
	self.Main.Visible = true

	Kit.Tween(self.Backdrop, 0.25, { BackgroundTransparency = self.Config.BackdropTransparency or 0.45 })
	Kit.Tween(self.Main, 0.28, { ImageTransparency = 0 })
	Kit.Tween(self.Scale, 0.34, { Scale = 1 })

	if self.Blur then
		Kit.Tween(self.Blur, 0.3, { Size = self.Config.BlurSize or 14 })
	end

	-- fokus otomatis di PC
	if Util.IsPC and self.Config.AutoFocus ~= false then
		Util.Bin.Delay(0.35, function()
			if not self.Closed then
				self.Input:Focus()
			end
		end)
	end
	return self
end

function KeyWindow:Close(success)
	if self.Closed then
		return
	end
	self.Closed = true

	Kit.Tween(self.Backdrop, 0.22, { BackgroundTransparency = 1 })
	Kit.Tween(self.Main, 0.22, { ImageTransparency = 1 })
	Kit.Tween(self.Scale, 0.22, { Scale = success and 1.04 or 0.94 })

	if self.Blur then
		Kit.Tween(self.Blur, 0.25, { Size = 0 })
	end

	Util.Bin.Delay(0.3, function()
		if self.Gui then
			self.Gui:Destroy()
		end
		if self.Blur then
			self.Blur:Destroy()
		end
	end)

	if not success and self.Config.OnClose then
		pcall(self.Config.OnClose)
	end
	return self
end

--// ==========================================================================
--//  8. VERIFIKASI
--// ==========================================================================

--- Cek key terhadap semua sumber yang dikonfigurasi.
--- Return: success (boolean), message (string)
local function verifyKey(cfg, key)
	--// 1) Validator kustom — prioritas tertinggi
	if type(cfg.Validator) == "function" then
		local ok, result, message = pcall(cfg.Validator, key)
		if not ok then
			return false, "Validator error: " .. tostring(result)
		end
		if type(result) == "string" then
			return false, result
		end
		return result == true, message or (result and "Key valid" or "Key salah")
	end

	--// 2) Daftar key statis
	if cfg.Keys then
		local list = type(cfg.Keys) == "table" and cfg.Keys or { cfg.Keys }
		for _, valid in ipairs(list) do
			if tostring(valid) == key then
				return true, "Key valid"
			end
		end
		-- kalau tidak ada sumber lain, langsung gagal
		if not cfg.KeyUrl then
			return false, "Key salah"
		end
	end

	--// 3) Key dari URL (satu key per baris, atau JSON array)
	if cfg.KeyUrl then
		local body = Util.HttpGet(cfg.KeyUrl)
		if not body then
			return false, "Gagal menghubungi server key"
		end

		-- coba JSON dulu
		local data = Util.JSONDecode(body)
		if type(data) == "table" then
			local list = data.keys or data.Keys or data
			if type(list) == "table" then
				for _, valid in ipairs(list) do
					if tostring(valid) == key then
						return true, "Key valid"
					end
				end
				return false, "Key salah"
			end
		end

		-- fallback: teks biasa, satu key per baris
		for line in tostring(body):gmatch("[^\r\n]+") do
			if Util.Trim(line) == key then
				return true, "Key valid"
			end
		end
		return false, "Key salah"
	end

	return false, "Tidak ada sumber key yang dikonfigurasi"
end

--// --------------------------------------------------------------------------
--//  Simpan / muat key
--// --------------------------------------------------------------------------

local function savedKeyPath(cfg)
	local folder = cfg.SaveFolder or KEYUI_FOLDER
	return folder .. "/" .. Util.HWID() .. ".key"
end

local function loadSavedKey(cfg)
	if not cfg.SaveKey or not Util.File.Enabled then
		return nil
	end
	local raw = Util.File.Read(savedKeyPath(cfg))
	return raw and Util.Trim(raw) or nil
end

local function saveKey(cfg, key)
	if not cfg.SaveKey or not Util.File.Enabled then
		return false
	end
	Util.File.Ensure(cfg.SaveFolder or KEYUI_FOLDER)
	return Util.File.Write(savedKeyPath(cfg), key)
end

local function deleteSavedKey(cfg)
	if not Util.File.Enabled then
		return false
	end
	return Util.File.Delete(savedKeyPath(cfg))
end

--// --------------------------------------------------------------------------
--//  Submit — dipanggil dari tombol atau Enter
--// --------------------------------------------------------------------------

function KeyWindow:Submit()
	if self.Verifying or self.Closed then
		return
	end

	local cfg = self.Config
	local key = self.Input:Get()

	if key == "" then
		self:SetStatus("Key tidak boleh kosong", "Error")
		self.Input:Shake()
		return
	end

	self.Verifying = true
	self.SubmitButton:SetLoading(true, cfg.VerifyingText or "Memverifikasi...")
	self.Input:Lock()
	self:SetStatus(cfg.VerifyingText or "Memverifikasi...", "Loading")

	task.spawn(function()
		-- jeda kecil supaya animasi loading terlihat
		task.wait(cfg.VerifyDelay or 0.45)

		local success, message = verifyKey(cfg, key)

		if self.Closed then
			return
		end

		self.Verifying = false
		self.SubmitButton:SetLoading(false, cfg.SubmitText or "Verifikasi")

		if success then
			self.Input:Success()
			self.Input:Lock()
			self:SetStatus(cfg.SuccessText or "Key valid, memuat script...", "Success")
			self.SubmitButton:SetTitle(cfg.SuccessButtonText or "Berhasil")
			self.SubmitButton:Lock()

			if cfg.SaveKey then
				saveKey(cfg, key)
			end

			Util.Bin.Delay(cfg.SuccessDelay or 0.8, function()
				self:Close(true)
				if cfg.OnSuccess then
					local ok, err = pcall(cfg.OnSuccess, key)
					if not ok then
						warn(("[ %s ] OnSuccess error: %s"):format(KEYUI_NAME, tostring(err)))
					end
				end
			end)
		else
			self.Attempts += 1
			self.Input:Unlock()
			self.Input:Shake()

			local remaining
			if self.MaxAttempts > 0 then
				remaining = self.MaxAttempts - self.Attempts
			end

			if remaining and remaining <= 0 then
				self:SetStatus(cfg.LockoutText or "Percobaan habis", "Error")
				self.Input:Lock()
				self.SubmitButton:Lock()

				if cfg.OnLockout then
					pcall(cfg.OnLockout)
				end

				Util.Bin.Delay(1.5, function()
					self:Close(false)
					if cfg.KickOnLockout then
						Util.Try(function()
							LocalPlayer:Kick(cfg.KickMessage or "Percobaan key habis.")
						end)
					end
				end)
			else
				local text = message or "Key salah"
				if remaining ~= nil then
					text = ("%s · sisa %d percobaan"):format(text, tonumber(remaining) or 0)
				end
				self:SetStatus(text, "Error")

				if cfg.OnFail then
					pcall(cfg.OnFail, key, self.Attempts)
				end
			end
		end
	end)
end

--// ==========================================================================
--//  9. API PUBLIK
--// ==========================================================================

local KeyUI = {
	Name = KEYUI_NAME,
	Version = KEYUI_VERSION,

	Util = Util,
	Kit = Kit,
	Themes = Themes,
	Shapes = Shapes,
	Icons = Icons,
	Components = Components,

	Current = nil,
}

--- Ganti tema aktif.
--- KeyUI:SetTheme("Purple")
function KeyUI:SetTheme(name, animate)
	return Kit.SetTheme(name, animate)
end

--- Tambah tema kustom.
function KeyUI:AddTheme(theme)
	if type(theme) == "table" and theme.Name then
		Themes[theme.Name] = theme
		return theme
	end
	return nil
end

function KeyUI:GetThemes()
	local names = {}
	for name in pairs(Themes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--- Tampilkan jendela key system.
---
--- KeyUI:Show({
---     Title      = "My Script",
---     Subtitle   = "Key System",
---     Note       = "Dapatkan key di Discord.",
---     Icon       = "shield-check",
---     Theme      = "Dark",
---     Keys       = { "KEY123" },        -- atau KeyUrl / Validator
---     SaveKey    = true,
---     KeyLink    = "https://discord.gg/xxx",
---     OnSuccess  = function(key) end,
---     OnClose    = function() end,
--- })
function KeyUI:Show(cfg)
	cfg = cfg or {}

	if self.Current and not self.Current.Closed then
		return self.Current
	end

	if cfg.Theme then
		Kit.SetTheme(cfg.Theme)
	end

	--// key tersimpan: verifikasi diam-diam
	if cfg.SaveKey then
		local saved = loadSavedKey(cfg)
		if saved and saved ~= "" then
			local ok = verifyKey(cfg, saved)
			if ok then
				if cfg.OnSuccess then
					task.spawn(function()
						local success, err = pcall(cfg.OnSuccess, saved)
						if not success then
							warn(("[ %s ] OnSuccess error: %s"):format(KEYUI_NAME, tostring(err)))
						end
					end)
				end
				return nil -- tidak perlu tampilkan UI
			end
			deleteSavedKey(cfg) -- key lama sudah tidak valid
		end
	end

	local window = KeyWindow.new(cfg)
	self.Current = window
	window:Open()
	return window
end

--- Versi blocking: menahan eksekusi sampai key benar.
--- Return true bila berhasil, false bila jendela ditutup.
---
--- if not KeyUI:Prompt({ Keys = {"ABC"} }) then return end
function KeyUI:Prompt(cfg)
	cfg = cfg or {}

	local finished = false
	local result = false

	local userSuccess = cfg.OnSuccess
	local userClose = cfg.OnClose

	cfg.OnSuccess = function(key)
		result = true
		finished = true
		if userSuccess then
			pcall(userSuccess, key)
		end
	end
	cfg.OnClose = function()
		result = false
		finished = true
		if userClose then
			pcall(userClose)
		end
	end

	local window = self:Show(cfg)

	-- key tersimpan valid: Show mengembalikan nil dan OnSuccess sudah dipanggil
	if window == nil then
		return true
	end

	local timeout = cfg.Timeout or 600
	local startTime = os.clock()
	while not finished do
		if os.clock() - startTime > timeout then
			window:Close(false)
			return false
		end
		task.wait(0.05)
	end

	return result
end

--- Hapus key yang tersimpan.
function KeyUI:ClearSavedKey(cfg)
	return deleteSavedKey(cfg or {})
end

--- Tutup jendela yang sedang aktif.
function KeyUI:Close()
	if self.Current and not self.Current.Closed then
		self.Current:Close(false)
	end
	return self
end

--- Bersihkan seluruh resource (koneksi, instance, thread).
function KeyUI:Destroy()
	self:Close()
	Util.Bin.Clear()
	self.Current = nil
	return self
end

return KeyUI

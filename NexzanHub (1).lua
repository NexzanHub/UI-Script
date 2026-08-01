--[[
    ███╗   ██╗███████╗██╗  ██╗███████╗ █████╗ ███╗   ██╗    ██╗  ██╗██╗   ██╗██████╗
    ████╗  ██║██╔════╝╚██╗██╔╝╚══███╔╝██╔══██╗████╗  ██║    ██║  ██║██║   ██║██╔══██╗
    ██╔██╗ ██║█████╗   ╚███╔╝   ███╔╝ ███████║██╔██╗ ██║    ███████║██║   ██║██████╔╝
    ██║╚██╗██║██╔══╝   ██╔██╗  ███╔╝  ██╔══██║██║╚██╗██║    ██╔══██║██║   ██║██╔══██╗
    ██║ ╚████║███████╗██╔╝ ██╗███████╗██║  ██║██║ ╚████║    ██║  ██║╚██████╔╝██████╔╝
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    Nexzan Hub — WindUI Modded Extension (Premium Edition)

    Sebuah EXTENSION / ADDON untuk WindUI.
      • Tidak membuat UI Library baru
      • Tidak mengedit / deobfuscate source main.lua
      • Tidak mengubah API, Class, Window, Tab, Theme, Config, animasi, atau fitur bawaan
      • Hanya MENAMBAHKAN fitur di atas WindUI yang sudah dimuat

    Pemakaian:
        local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
        loadstring(game:HttpGet("<url>/NexzanHub.lua"))()(WindUI)

        -- setelah itu semua script lama tetap jalan tanpa perubahan:
        local Window = WindUI:CreateWindow({ Title = "My Script", ... })

    Author  : Nexzan Hub
    License : MIT
]]

--// ==========================================================================
--//  0. CONSTANTS / OPTIONS
--// ==========================================================================

local NEXZAN_NAME = "Nexzan Hub"
local NEXZAN_VERSION = "1.0.0"
local NEXZAN_CHANNEL = "Premium Edition"
local NEXZAN_FOLDER = "WindUI/NexzanHub"

-- Whitelist Developer (UserId). Ikon 🛠️ Developer HANYA muncul untuk UserId ini.
local Developers = {
	10954470817,
}

-- Default option, bisa dioverride lewat Nexzan:Attach(WindUI, { ... })
local DefaultOptions = {
	Search = true, -- ikon Search
	Players = true, -- ikon Players
	Settings = true, -- ikon Settings
	Developer = true, -- ikon Developer (tetap butuh whitelist)
	Watermark = false, -- watermark aktif saat start
	Themes = true, -- daftarkan theme tambahan (Purple, Blue, BloodMoon, dst)
	RememberWindow = true, -- ingat posisi & ukuran window
	SnapPosition = true, -- snap window ke tepi layar
	Shortcuts = true, -- keyboard shortcut (PC)
	Tooltips = true, -- tooltip pada ikon header
	Developers = nil, -- tabel UserId tambahan
	CatalogAutoOpen = false,
}

--// ==========================================================================
--//  1. SERVICES & UTIL
--// ==========================================================================

-- Forward declaration: tabel publik extension (diisi di bagian akhir file).
local Nexzan

local getref = (cloneref or clonereference or function(o)
	return o
end)

local Players = getref(game:GetService("Players"))
local RunService = getref(game:GetService("RunService"))
local UserInputService = getref(game:GetService("UserInputService"))
local HttpService = getref(game:GetService("HttpService"))
local Lighting = getref(game:GetService("Lighting"))
local Stats = getref(game:GetService("Stats"))
local TeleportService = getref(game:GetService("TeleportService"))
local TextService = getref(game:GetService("TextService"))
local LogService = getref(game:GetService("LogService"))
local VirtualUser = getref(game:GetService("VirtualUser"))
local LocalPlayer = Players.LocalPlayer

local Util = {}

Util.IsPC = UserInputService.KeyboardEnabled and UserInputService.MousePresent
Util.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--- Panggil fungsi tanpa pernah melempar error keluar (extension tidak boleh merusak host).
function Util.Try(fn, ...)
	if type(fn) ~= "function" then
		return false, nil
	end
	local ok, res = pcall(fn, ...)
	if not ok then
		return false, res
	end
	return true, res
end

--- Ambil nilai bersarang secara aman: Util.Get(Window, "UIElements", "Main", "Main")
function Util.Get(root, ...)
	local cur = root
	for _, key in ipairs({ ... }) do
		if typeof(cur) ~= "table" and typeof(cur) ~= "Instance" then
			return nil
		end
		local ok, nxt = pcall(function()
			if typeof(cur) == "Instance" then
				return cur:FindFirstChild(key)
			end
			return cur[key]
		end)
		if not ok or nxt == nil then
			return nil
		end
		cur = nxt
	end
	return cur
end

function Util.Round(n, step)
	step = step or 1
	return math.floor((tonumber(n) or 0) / step + 0.5) * step
end

function Util.Clamp(v, min, max)
	return math.clamp(tonumber(v) or min, min, max)
end

function Util.Comma(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	out = out:gsub("^,", "")
	return out
end

function Util.Short(n)
	n = tonumber(n) or 0
	local units = { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			return string.format("%.1f%s", n / u[1], u[2])
		end
	end
	return tostring(Util.Round(n))
end

function Util.Truncate(text, max)
	text = tostring(text or "")
	if #text <= max then
		return text
	end
	return text:sub(1, math.max(1, max - 3)) .. "..."
end

function Util.Clipboard(text)
	local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if fn then
		Util.Try(fn, tostring(text))
		return true
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
	if not name and getexecutorname then
		local ok, res = pcall(getexecutorname)
		if ok then
			name = res
		end
	end
	return tostring(name or "Unknown")
end

function Util.Device()
	if Util.IsMobile then
		return "Mobile"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "Console"
	end
	return "PC"
end

function Util.Ping()
	local ok, ping = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
	end)
	if ok and ping then
		return tostring(ping):gsub("%s+%(.*%)", "")
	end
	return "N/A"
end

function Util.PingMs()
	local ok, ms = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return ok and math.floor(ms) or 0
end

function Util.Memory()
	local ok, mb = pcall(function()
		return Stats:GetTotalMemoryUsageMb()
	end)
	return ok and math.floor(mb) or 0
end

function Util.NetworkKbps()
	local ok, kbps = pcall(function()
		local inKb = Stats.DataReceiveKbps
		local outKb = Stats.DataSendKbps
		return inKb + outKb
	end)
	return ok and math.floor(kbps) or 0
end

function Util.Region()
	-- Region hanya bisa didekati lewat HttpGet ke ip-api; dijalankan async & di-cache.
	return Util._region or "Detecting..."
end

function Util.DetectRegion()
	if Util._regionRequested then
		return
	end
	Util._regionRequested = true
	task.spawn(function()
		local req = (syn and syn.request) or (http and http.request) or http_request or request
		local body
		if req then
			local ok, res = pcall(req, { Url = "http://ip-api.com/json/?fields=country,city", Method = "GET" })
			if ok and res and res.Body then
				body = res.Body
			end
		end
		if not body then
			local ok, res = pcall(function()
				return game:HttpGet("http://ip-api.com/json/?fields=country,city")
			end)
			if ok then
				body = res
			end
		end
		if body then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(body)
			end)
			if ok and type(data) == "table" and data.country then
				Util._region = (data.city and (data.city .. ", ") or "") .. data.country
				return
			end
		end
		Util._region = "Unknown"
	end)
end

function Util.TimeString()
	return os.date("%H:%M:%S")
end

function Util.DateString()
	return os.date("%d/%m/%Y")
end

function Util.PlayTime(startClock)
	local sec = math.floor(os.clock() - (startClock or os.clock()))
	return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60)
end

--// --------------------------------------------------------------------------
--//  File helper (aman jika executor tidak punya filesystem)
--// --------------------------------------------------------------------------

local File = {}
Util.File = File

File.Enabled = (writefile ~= nil and readfile ~= nil and isfile ~= nil and isfolder ~= nil and makefolder ~= nil)
	and not RunService:IsStudio()

function File.Ensure(path)
	if not File.Enabled then
		return false
	end
	local parts = string.split(path, "/")
	local cur = ""
	for _, p in ipairs(parts) do
		if p ~= "" then
			cur = (cur == "" and p) or (cur .. "/" .. p)
			if not isfolder(cur) then
				Util.Try(makefolder, cur)
			end
		end
	end
	return true
end

function File.WriteJSON(path, data)
	if not File.Enabled then
		return false
	end
	File.Ensure(NEXZAN_FOLDER)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		return false
	end
	return (Util.Try(writefile, path, encoded))
end

function File.ReadJSON(path)
	if not File.Enabled then
		return nil
	end
	if not isfile(path) then
		return nil
	end
	local ok, raw = pcall(readfile, path)
	if not ok then
		return nil
	end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return ok2 and data or nil
end

--// --------------------------------------------------------------------------
--//  Connection registry (anti memory leak)
--// --------------------------------------------------------------------------

local Bin = {
	connections = {},
	instances = {},
	threads = {},
}
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

function Bin.Track(instance)
	if instance then
		table.insert(Bin.instances, instance)
	end
	return instance
end

function Bin.Spawn(fn)
	local thread = task.spawn(fn)
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

--// --------------------------------------------------------------------------
--//  Scheduler — SATU RenderStepped untuk semua fitur (hemat FPS, tanpa loop liar)
--// --------------------------------------------------------------------------

local Scheduler = {
	tasks = {},
	count = 0,
	connection = nil,
}
Util.Scheduler = Scheduler

local function schedulerStep(dt)
	local now = os.clock()
	for name, t in pairs(Scheduler.tasks) do
		if now - t.last >= t.interval then
			t.last = now
			local ok, err = pcall(t.fn, dt, now)
			if not ok then
				t.errors = (t.errors or 0) + 1
				-- Task yang selalu error otomatis dilepas agar tidak membebani frame.
				if t.errors > 5 then
					Scheduler.tasks[name] = nil
					Scheduler.count = math.max(0, Scheduler.count - 1)
					warn(("[ %s ] Task '%s' dihentikan: %s"):format(NEXZAN_NAME, name, tostring(err)))
				end
			end
		end
	end
	if Scheduler.count <= 0 and Scheduler.connection then
		Scheduler.connection:Disconnect()
		Scheduler.connection = nil
	end
end

--- interval = detik antar eksekusi (0 = tiap frame)
function Scheduler.Add(name, interval, fn)
	if Scheduler.tasks[name] == nil then
		Scheduler.count += 1
	end
	Scheduler.tasks[name] = { interval = interval or 0, fn = fn, last = 0, errors = 0 }
	if not Scheduler.connection then
		Scheduler.connection = RunService.RenderStepped:Connect(schedulerStep)
		table.insert(Bin.connections, Scheduler.connection)
	end
end

function Scheduler.Remove(name)
	if Scheduler.tasks[name] then
		Scheduler.tasks[name] = nil
		Scheduler.count = math.max(0, Scheduler.count - 1)
	end
end

function Scheduler.Has(name)
	return Scheduler.tasks[name] ~= nil
end

--// --------------------------------------------------------------------------
--//  FPS meter (dipakai watermark, debug panel, dsb — hanya satu perhitungan)
--// --------------------------------------------------------------------------

local FPS = { value = 60, frames = 0, last = os.clock(), min = 999, max = 0 }
Util.FPS = FPS

Bin.Connect(RunService.RenderStepped, function()
	FPS.frames += 1
	local now = os.clock()
	local delta = now - FPS.last
	if delta >= 0.5 then
		FPS.value = math.floor(FPS.frames / delta + 0.5)
		FPS.min = math.min(FPS.min, FPS.value)
		FPS.max = math.max(FPS.max, FPS.value)
		FPS.frames = 0
		FPS.last = now
	end
end)

--// --------------------------------------------------------------------------
--//  Character helper
--// --------------------------------------------------------------------------

local Char = {}
Util.Char = Char

function Char.Get(player)
	player = player or LocalPlayer
	return player and player.Character
end

function Char.Humanoid(player)
	local c = Char.Get(player)
	return c and c:FindFirstChildOfClass("Humanoid")
end

function Char.Root(player)
	local c = Char.Get(player)
	return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end

function Char.Alive(player)
	local h = Char.Humanoid(player)
	return h ~= nil and h.Health > 0
end

function Char.Distance(player)
	local root = Char.Root(player)
	local myRoot = Char.Root(LocalPlayer)
	if root and myRoot then
		return (root.Position - myRoot.Position).Magnitude
	end
	return 0
end

--// ==========================================================================
--//  2. UI KIT — dibangun MEMAKAI Creator milik WindUI
--//     (shape, radius, font, theme tag, tween: semuanya milik WindUI)
--// ==========================================================================

local Kit = {}

local WindUI, Creator, New, Tween, Icon, NewRoundFrame

--- Diinisialisasi sekali setelah WindUI diterima.
function Kit.Init(windui)
	WindUI = windui
	Creator = WindUI.Creator

	New = Creator.New
	Tween = Creator.Tween
	Icon = Creator.Icon
	NewRoundFrame = Creator.NewRoundFrame

	Kit.WindUI = WindUI
	Kit.Creator = Creator
	Kit.New = New
	Kit.Tween = Tween
	Kit.Icon = Icon
	Kit.NewRoundFrame = NewRoundFrame

	return Kit
end

--- Kurva animasi standar WindUI (Quint / Out).
function Kit.Ease(dur)
	return dur or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out
end

function Kit.Anim(object, dur, props)
	if not object then
		return nil
	end
	local ok, tween = pcall(function()
		return Tween(object, dur, props, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end)
	if ok and tween then
		tween:Play()
		return tween
	end
	return nil
end

function Kit.Font(weight)
	return Font.new(Creator.Font, Enum.FontWeight[weight or "Medium"])
end

function Kit.Theme(prop, fallback)
	local ok, value = pcall(Creator.GetThemeProperty, prop, Creator.Theme)
	if ok and value ~= nil then
		return value
	end
	return fallback
end

--// --------------------------------------------------------------------------
--//  Primitives
--// --------------------------------------------------------------------------

function Kit.Label(text, size, weight, themeTag, props)
	local base = {
		Text = text or "",
		TextSize = size or 14,
		FontFace = Kit.Font(weight or "Medium"),
		BackgroundTransparency = 1,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		RichText = true,
		AutomaticSize = "Y",
		Size = UDim2.new(1, 0, 0, 0),
		ThemeTag = { TextColor3 = themeTag or "Text" },
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	return New("TextLabel", base)
end

function Kit.IconImage(iconName, size, themeTag, props)
	local data = Icon(iconName)
	local base = {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, size or 18, 0, size or 18),
		ThemeTag = { ImageColor3 = themeTag or "Icon" },
	}
	if data and data[1] then
		base.Image = data[1]
		base.ImageRectOffset = data[2] and data[2].ImageRectPosition or Vector2.zero
		base.ImageRectSize = data[2] and data[2].ImageRectSize or Vector2.zero
	end
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	return New("ImageLabel", base)
end

--- Container membulat memakai shape "Squircle" bawaan WindUI.
function Kit.Card(radius, props, children, isButton)
	local base = {
		BackgroundTransparency = 1,
		ThemeTag = { ImageColor3 = "Element" },
		ImageTransparency = 0,
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	-- NewRoundFrame mengembalikan (ImageLabel, Wrapper); ambil objeknya saja
	-- supaya aman dipakai langsung di dalam daftar Children.
	local object = NewRoundFrame(radius or 12, "Squircle", base, children or {}, isButton == true)
	return object
end

function Kit.Outline(radius, props, children)
	local base = {
		Size = UDim2.new(1, 0, 1, 0),
		ThemeTag = { ImageColor3 = "Outline" },
		ImageTransparency = 0.85,
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local object = NewRoundFrame(radius or 12, "SquircleOutline", base, children or {})
	return object
end

function Kit.Padding(all, extra)
	local p = {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	}
	for k, v in pairs(extra or {}) do
		p[k] = v
	end
	return New("UIPadding", p)
end

function Kit.List(padding, props)
	local base = {
		Padding = UDim.new(0, padding or 6),
		SortOrder = "LayoutOrder",
		FillDirection = "Vertical",
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	return New("UIListLayout", base)
end

function Kit.Scroll(props, children)
	local base = {
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollingDirection = "Y",
		AutomaticCanvasSize = "Y",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ElasticBehavior = "Never",
		ClipsDescendants = true,
		Active = true,
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	return New("ScrollingFrame", base, children or {})
end

--// --------------------------------------------------------------------------
--//  Hover / Click behaviour — meniru persis gaya WindUI
--//  (hover: ImageTransparency 1 -> .93 ; click: UIScale 1 -> .9)
--// --------------------------------------------------------------------------

function Kit.Hoverable(button, hoverTransparency, restTransparency)
	hoverTransparency = hoverTransparency or 0.93
	restTransparency = restTransparency or 1

	Util.Bin.Connect(button.MouseEnter, function()
		Kit.Anim(button, 0.15, { ImageTransparency = hoverTransparency })
	end)
	Util.Bin.Connect(button.MouseLeave, function()
		Kit.Anim(button, 0.1, { ImageTransparency = restTransparency })
	end)
	return button
end

function Kit.Pressable(button, scaleObject)
	local scale = scaleObject or button:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = New("UIScale", { Scale = 1 })
		scale.Parent = button
	end
	Util.Bin.Connect(button.MouseButton1Down, function()
		Kit.Anim(scale, 0.2, { Scale = 0.9 })
	end)
	Util.Bin.Connect(button.InputEnded, function()
		Kit.Anim(scale, 0.2, { Scale = 1 })
	end)
	return button
end

--// --------------------------------------------------------------------------
--//  Tooltip — memakai TooltipGui milik WindUI
--// --------------------------------------------------------------------------

local TooltipHolder

function Kit.Tooltip(target, text)
	if not text or text == "" then
		return
	end

	if not TooltipHolder then
		TooltipHolder = WindUI.TooltipGui or WindUI.ScreenGui
	end

	local frame, label
	local visible = false
	local hoverThread

	local function build()
		label = Kit.Label(text, 13, "Medium", "Text", {
			AutomaticSize = "XY",
			Size = UDim2.new(0, 0, 0, 0),
			TextTransparency = 0.05,
		})
		frame = Util.Bin.Track(Kit.Card(10, {
			AutomaticSize = "XY",
			Size = UDim2.new(0, 0, 0, 0),
			ThemeTag = { ImageColor3 = "Dialog" },
			ImageTransparency = 0.05,
			ZIndex = 500000,
			Parent = TooltipHolder,
			AnchorPoint = Vector2.new(0.5, 1),
		}, {
			Kit.Outline(10, { ImageTransparency = 0.9 }),
			label,
			Kit.Padding(8, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
			New("UIScale", { Scale = 0.9 }),
		}))
	end

	local function show()
		if visible then
			return
		end
		visible = true
		if not frame then
			build()
		end
		local abs = target.AbsolutePosition
		local size = target.AbsoluteSize
		frame.Position = UDim2.fromOffset(abs.X + size.X / 2, abs.Y - 6)
		frame.Visible = true
		frame.ImageTransparency = 1
		label.TextTransparency = 1
		Kit.Anim(frame, 0.14, { ImageTransparency = 0.05 })
		Kit.Anim(label, 0.14, { TextTransparency = 0.05 })
		Kit.Anim(frame.UIScale, 0.16, { Scale = 1 })
	end

	local function hide()
		if hoverThread then
			task.cancel(hoverThread)
			hoverThread = nil
		end
		if not visible or not frame then
			return
		end
		visible = false
		Kit.Anim(frame, 0.1, { ImageTransparency = 1 })
		Kit.Anim(label, 0.1, { TextTransparency = 1 })
		Kit.Anim(frame.UIScale, 0.1, { Scale = 0.9 })
		task.delay(0.12, function()
			if not visible and frame then
				frame.Visible = false
			end
		end)
	end

	-- Tooltip hanya untuk PC (mouse hover); mobile tidak butuh.
	if Util.IsPC then
		Util.Bin.Connect(target.MouseEnter, function()
			hoverThread = task.delay(0.35, show)
		end)
		Util.Bin.Connect(target.MouseLeave, hide)
		Util.Bin.Connect(target.MouseButton1Down, hide)
	end

end

--// --------------------------------------------------------------------------
--//  Kontrol ringan untuk panel (Row, Toggle, Slider, Dropdown, Input, Section)
--//  Semua memakai warna/shape/font WindUI — terlihat seperti elemen resmi.
--// --------------------------------------------------------------------------

local Controls = {}
Kit.Controls = Controls

local ROW_RADIUS = 12

-- Semua LayoutOrder dikali 10 agar elemen sisipan (mis. list dropdown)
-- punya slot di antara dua baris tanpa bentrok urutan.
local ORDER_STEP = 10

local function rowBase(parent, height, layoutOrder)
	local row = Kit.Card(ROW_RADIUS, {
		Size = UDim2.new(1, 0, 0, height or 40),
		LayoutOrder = (layoutOrder or 1) * ORDER_STEP,
		ThemeTag = { ImageColor3 = "Text" },
		ImageTransparency = 0.94,
		Parent = parent,
	})
	return row
end

function Controls.Section(parent, title, layoutOrder)
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = (layoutOrder or 1) * ORDER_STEP,
		Parent = parent,
	}, {
		Kit.Label(string.upper(title), 11, "Bold", "Text", {
			TextTransparency = 0.45,
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = "None",
			TextYAlignment = "Bottom",
		}),
	})
	return holder
end

function Controls.Button(parent, cfg)
	local row = rowBase(parent, cfg.Height or 38, cfg.LayoutOrder)
	row.Active = true

	local click = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
		ZIndex = 5,
	})

	local iconImg = cfg.Icon and Kit.IconImage(cfg.Icon, 16, "Icon", { LayoutOrder = 1 }) or nil
	local label = Kit.Label(cfg.Title, 14, "Medium", "Text", {
		LayoutOrder = 2,
		AutomaticSize = "X",
		Size = UDim2.new(0, 0, 1, 0),
		TextTransparency = 0.08,
	})

	New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = row,
	}, {
		Kit.List(8, { FillDirection = "Horizontal", VerticalAlignment = "Center" }),
		Kit.Padding(0, { PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11) }),
		iconImg,
		label,
	})

	local scale = New("UIScale", { Scale = 1 })
	scale.Parent = row

	Util.Bin.Connect(click.MouseEnter, function()
		Kit.Anim(row, 0.15, { ImageTransparency = 0.88 })
	end)
	Util.Bin.Connect(click.MouseLeave, function()
		Kit.Anim(row, 0.15, { ImageTransparency = 0.94 })
	end)
	Util.Bin.Connect(click.MouseButton1Down, function()
		Kit.Anim(scale, 0.2, { Scale = 0.97 })
	end)
	Util.Bin.Connect(click.InputEnded, function()
		Kit.Anim(scale, 0.2, { Scale = 1 })
	end)
	Util.Bin.Connect(click.MouseButton1Click, function()
		Creator.SafeCallback(cfg.Callback)
	end)

	if cfg.Tooltip then
		Kit.Tooltip(click, cfg.Tooltip)
	end

	local api = { Frame = row, Label = label, __type = "Button", Title = cfg.Title }
	function api:SetTitle(t)
		api.Title = t
		label.Text = t
	end
	return api
end

function Controls.Toggle(parent, cfg)
	local row = rowBase(parent, 38, cfg.LayoutOrder)
	local value = cfg.Value == true

	local label = Kit.Label(cfg.Title, 14, "Medium", "Text", {
		Size = UDim2.new(1, -54, 1, 0),
		AutomaticSize = "None",
		Position = UDim2.new(0, 11, 0, 0),
		TextTransparency = 0.08,
		TextTruncate = "AtEnd",
	})
	label.Parent = row

	local knob = Kit.Card(999, {
		Size = UDim2.new(0, 15, 0, 15),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageColor3 = Color3.new(1, 1, 1),
		ImageTransparency = 0,
	})

	local track = Kit.Card(999, {
		Size = UDim2.new(0, 38, 0, 21),
		Position = UDim2.new(1, -11, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ThemeTag = { ImageColor3 = value and "Toggle" or "Text" },
		ImageTransparency = value and 0 or 0.88,
		Parent = row,
	}, { knob })

	local click = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
		ZIndex = 5,
	})

	local api = { Frame = row, __type = "Toggle", Title = cfg.Title, Value = value }

	local function render(animated)
		local dur = animated and 0.18 or 0
		Creator.SetThemeTag(track, {
			ImageColor3 = api.Value and "Toggle" or "Text",
			ImageTransparency = api.Value and 0 or 0.88,
		}, dur)
		Kit.Anim(knob, dur, {
			Position = api.Value and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = api.Value and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
		})
	end

	function api:Set(v, silent)
		api.Value = v == true
		render(true)
		if not silent then
			Creator.SafeCallback(cfg.Callback, api.Value)
		end
		return api
	end

	Util.Bin.Connect(click.MouseButton1Click, function()
		api:Set(not api.Value)
	end)
	Util.Bin.Connect(click.MouseEnter, function()
		Kit.Anim(row, 0.15, { ImageTransparency = 0.88 })
	end)
	Util.Bin.Connect(click.MouseLeave, function()
		Kit.Anim(row, 0.15, { ImageTransparency = 0.94 })
	end)

	if cfg.Tooltip then
		Kit.Tooltip(click, cfg.Tooltip)
	end

	render(false)
	if value and cfg.FireOnInit then
		task.defer(function()
			Creator.SafeCallback(cfg.Callback, true)
		end)
	end
	return api
end

function Controls.Slider(parent, cfg)
	local min, max = cfg.Min or 0, cfg.Max or 100
	local step = cfg.Step or 1
	local value = Util.Clamp(cfg.Value or min, min, max)

	local row = rowBase(parent, 52, cfg.LayoutOrder)

	local label = Kit.Label(cfg.Title, 13, "Medium", "Text", {
		Size = UDim2.new(1, -70, 0, 16),
		AutomaticSize = "None",
		Position = UDim2.new(0, 11, 0, 8),
		TextTransparency = 0.15,
		TextTruncate = "AtEnd",
	})
	label.Parent = row

	local valueLabel = Kit.Label(tostring(value), 13, "SemiBold", "Text", {
		Size = UDim2.new(0, 56, 0, 16),
		AutomaticSize = "None",
		Position = UDim2.new(1, -11, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = "Right",
		TextTransparency = 0.1,
	})
	valueLabel.Parent = row

	local fill = Kit.Card(999, {
		Size = UDim2.new((value - min) / math.max(1e-6, max - min), 0, 1, 0),
		ThemeTag = { ImageColor3 = "Slider" },
		ImageTransparency = 0,
	})

	local bar = Kit.Card(999, {
		Size = UDim2.new(1, -22, 0, 6),
		Position = UDim2.new(0, 11, 1, -14),
		ThemeTag = { ImageColor3 = "Text" },
		ImageTransparency = 0.85,
		Parent = row,
		ClipsDescendants = true,
	}, { fill })

	local hit = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 1, -26),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
		ZIndex = 6,
		AutoButtonColor = false,
	})

	local api = { Frame = row, __type = "Slider", Title = cfg.Title, Value = value }

	local function apply(v, silent, animated)
		v = Util.Clamp(Util.Round(v, step), min, max)
		if step < 1 then
			v = tonumber(string.format("%.2f", v))
		end
		api.Value = v
		valueLabel.Text = (cfg.Suffix and (tostring(v) .. cfg.Suffix)) or tostring(v)
		local alpha = (v - min) / math.max(1e-6, max - min)
		if animated then
			Kit.Anim(fill, 0.12, { Size = UDim2.new(alpha, 0, 1, 0) })
		else
			fill.Size = UDim2.new(alpha, 0, 1, 0)
		end
		if not silent then
			Creator.SafeCallback(cfg.Callback, v)
		end
	end

	function api:Set(v, silent)
		apply(v, silent, true)
		return api
	end

	local dragging = false
	local function fromInput(input)
		local relative = (input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)
		apply(min + math.clamp(relative, 0, 1) * (max - min), false, false)
	end

	Util.Bin.Connect(hit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromInput(input)
			Kit.Anim(bar, 0.12, { Size = UDim2.new(1, -22, 0, 8) })
		end
	end)
	Util.Bin.Connect(UserInputService.InputChanged, function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			fromInput(input)
		end
	end)
	Util.Bin.Connect(UserInputService.InputEnded, function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging = false
			Kit.Anim(bar, 0.12, { Size = UDim2.new(1, -22, 0, 6) })
		end
	end)

	apply(value, true, false)
	if cfg.Tooltip then
		Kit.Tooltip(hit, cfg.Tooltip)
	end
	return api
end

function Controls.Dropdown(parent, cfg)
	local row = rowBase(parent, 38, cfg.LayoutOrder)
	local options = cfg.Values or {}
	local value = cfg.Value or options[1]

	local label = Kit.Label(cfg.Title, 13, "Medium", "Text", {
		Size = UDim2.new(0.5, -11, 1, 0),
		AutomaticSize = "None",
		Position = UDim2.new(0, 11, 0, 0),
		TextTransparency = 0.15,
		TextTruncate = "AtEnd",
	})
	label.Parent = row

	local chevron = Kit.IconImage("chevron-down", 14, "Icon", {
		Position = UDim2.new(1, -11, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ImageTransparency = 0.25,
	})
	chevron.Parent = row

	local current = Kit.Label(tostring(value or "-"), 13, "SemiBold", "Text", {
		Size = UDim2.new(0.5, -34, 1, 0),
		AutomaticSize = "None",
		Position = UDim2.new(1, -30, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = "Right",
		TextTransparency = 0.15,
		TextTruncate = "AtEnd",
	})
	current.Parent = row

	local listHolder = Kit.Card(ROW_RADIUS, {
		Size = UDim2.new(1, 0, 0, 0),
		ThemeTag = { ImageColor3 = "Text" },
		ImageTransparency = 0.96,
		Parent = parent,
		LayoutOrder = ((cfg.LayoutOrder or 1) * ORDER_STEP) + 1,
		Visible = false,
		ClipsDescendants = true,
	})
	local listInner = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = listHolder,
	}, {
		Kit.List(2),
		Kit.Padding(5),
	})

	local api = { Frame = row, __type = "Dropdown", Title = cfg.Title, Value = value }
	local open = false
	local optionButtons = {}

	local function refresh()
		current.Text = tostring(api.Value or "-")
		for optValue, btn in pairs(optionButtons) do
			Kit.Anim(btn, 0.12, { ImageTransparency = (optValue == api.Value) and 0.9 or 1 })
		end
	end

	function api:Select(v, silent)
		api.Value = v
		refresh()
		if not silent then
			Creator.SafeCallback(cfg.Callback, v)
		end
		return api
	end

	local function buildOptions()
		for _, child in ipairs(listInner:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(optionButtons)
		for i, opt in ipairs(options) do
			local btn = Kit.Card(9, {
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = i,
				ThemeTag = { ImageColor3 = "Text" },
				ImageTransparency = (opt == api.Value) and 0.9 or 1,
				Parent = listInner,
			}, {
				Kit.Label(tostring(opt), 13, "Medium", "Text", {
					Size = UDim2.new(1, -18, 1, 0),
					AutomaticSize = "None",
					Position = UDim2.new(0, 9, 0, 0),
					TextTransparency = 0.15,
				}),
			}, true)
			optionButtons[opt] = btn
			Util.Bin.Connect(btn.MouseEnter, function()
				Kit.Anim(btn, 0.12, { ImageTransparency = 0.88 })
			end)
			Util.Bin.Connect(btn.MouseLeave, function()
				Kit.Anim(btn, 0.12, { ImageTransparency = (opt == api.Value) and 0.9 or 1 })
			end)
			Util.Bin.Connect(btn.MouseButton1Click, function()
				api:Select(opt)
				api:Close()
			end)
		end
	end

	function api:Open()
		if open then
			return
		end
		open = true
		buildOptions()
		listHolder.Visible = true
		local height = math.min(#options * 32 + 10, 190)
		Kit.Anim(listHolder, 0.2, { Size = UDim2.new(1, 0, 0, height) })
		Kit.Anim(chevron, 0.2, { Rotation = 180 })
	end

	function api:Close()
		if not open then
			return
		end
		open = false
		Kit.Anim(listHolder, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
		Kit.Anim(chevron, 0.18, { Rotation = 0 })
		task.delay(0.2, function()
			if not open then
				listHolder.Visible = false
			end
		end)
	end

	function api:SetValues(newValues)
		options = newValues or {}
		if open then
			buildOptions()
			Kit.Anim(listHolder, 0.15, { Size = UDim2.new(1, 0, 0, math.min(#options * 32 + 10, 190)) })
		end
		return api
	end

	local click = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
		ZIndex = 5,
	})
	Util.Bin.Connect(click.MouseButton1Click, function()
		if open then
			api:Close()
		else
			api:Open()
		end
	end)
	Util.Bin.Connect(click.MouseEnter, function()
		Kit.Anim(row, 0.15, { ImageTransparency = 0.88 })
	end)
	Util.Bin.Connect(click.MouseLeave, function()
		Kit.Anim(row, 0.15, { ImageTransparency = 0.94 })
	end)

	refresh()
	return api
end

function Controls.Input(parent, cfg)
	local row = rowBase(parent, 38, cfg.LayoutOrder)

	local label = Kit.Label(cfg.Title, 13, "Medium", "Text", {
		Size = UDim2.new(0, 90, 1, 0),
		AutomaticSize = "None",
		Position = UDim2.new(0, 11, 0, 0),
		TextTransparency = 0.15,
		TextTruncate = "AtEnd",
		Visible = cfg.Title ~= nil,
	})
	label.Parent = row

	local box = New("TextBox", {
		Size = UDim2.new(1, cfg.Title and -112 or -22, 1, -10),
		Position = UDim2.new(1, -11, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Text = cfg.Value or "",
		PlaceholderText = cfg.Placeholder or "",
		FontFace = Kit.Font("Medium"),
		TextSize = 13,
		TextXAlignment = cfg.Title and "Right" or "Left",
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" },
		Parent = row,
	})

	local api = { Frame = row, __type = "Input", Title = cfg.Title, Value = box.Text, TextBox = box }

	function api:Set(v, silent)
		box.Text = tostring(v or "")
		api.Value = box.Text
		if not silent then
			Creator.SafeCallback(cfg.Callback, api.Value)
		end
		return api
	end

	Util.Bin.Connect(box.FocusLost, function(enter)
		api.Value = box.Text
		Creator.SafeCallback(cfg.Callback, box.Text, enter)
	end)
	if cfg.OnChanged then
		Util.Bin.Connect(box:GetPropertyChangedSignal("Text"), function()
			api.Value = box.Text
			Creator.SafeCallback(cfg.OnChanged, box.Text)
		end)
	end

	return api
end

function Controls.Info(parent, cfg)
	local row = rowBase(parent, 38, cfg.LayoutOrder)
	row.ImageTransparency = 0.96

	local label = Kit.Label(cfg.Title, 13, "Medium", "Text", {
		Size = UDim2.new(0.45, -11, 1, 0),
		AutomaticSize = "None",
		Position = UDim2.new(0, 11, 0, 0),
		TextTransparency = 0.35,
		TextTruncate = "AtEnd",
	})
	label.Parent = row

	local value = Kit.Label(tostring(cfg.Value or "-"), 13, "SemiBold", "Text", {
		Size = UDim2.new(0.55, -11, 1, 0),
		AutomaticSize = "None",
		Position = UDim2.new(1, -11, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = "Right",
		TextTransparency = 0.1,
		TextTruncate = "AtEnd",
	})
	value.Parent = row

	local api = { Frame = row, __type = "Info", Title = cfg.Title }
	function api:Set(v)
		value.Text = tostring(v)
		return api
	end
	if cfg.Copyable then
		local click = New("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			Parent = row,
			ZIndex = 5,
		})
		Util.Bin.Connect(click.MouseButton1Click, function()
			Util.Clipboard(value.Text)
			Nexzan.Notify("Copied", tostring(cfg.Title) .. " disalin ke clipboard", "clipboard-check")
		end)
		Kit.Tooltip(click, "Click to copy")
	end
	return api
end

--// ==========================================================================
--//  3. PANEL SYSTEM — dropdown panel yang menempel di bawah Header WindUI
--// ==========================================================================

local Panel = {}
Panel.__index = Panel

local ActivePanel = nil
local PanelRegistry = {}

local PANEL_RADIUS = 16

--- Membuat panel baru. Parent = Window.UIElements.Main (di dalam window, mengikuti UIScale).
function Panel.new(ctx, cfg)
	local self = setmetatable({}, Panel)

	self.Window = ctx.Window
	self.Id = cfg.Id
	self.Title = cfg.Title
	self.Icon = cfg.Icon
	self.Width = cfg.Width or 300
	self.MaxHeight = cfg.MaxHeight or 360
	self.Opened = false
	self.Built = false
	self.Builder = cfg.Build
	self.Tabs = cfg.Tabs
	self.OnOpen = cfg.OnOpen
	self.OnClose = cfg.OnClose
	self.ActiveTab = nil
	self.TabButtons = {}
	self.TabPages = {}

	local Window = self.Window
	local topbarHeight = (Window.Topbar and Window.Topbar.Height) or 52

	self.Root = Kit.Card(PANEL_RADIUS, {
		Size = UDim2.new(0, self.Width, 0, 0),
		Position = UDim2.new(1, -10, 0, topbarHeight - 6),
		AnchorPoint = Vector2.new(1, 0),
		ThemeTag = { ImageColor3 = "Dialog" },
		ImageTransparency = 0.02,
		ZIndex = 1200,
		Visible = false,
		ClipsDescendants = true,
		Parent = Window.UIElements.Main,
	}, {
		Kit.Outline(PANEL_RADIUS, { ImageTransparency = 0.88, ZIndex = 1201 }),
		New("UIScale", { Scale = 0.96 }),
	})

	-- Shadow lembut, gaya WindUI
	self.Shadow = New("ImageLabel", {
		Image = "rbxassetid://8992230677",
		ThemeTag = { ImageColor3 = "WindowShadow" },
		ImageTransparency = 0.75,
		Size = UDim2.new(1, 60, 1, 60),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ScaleType = "Slice",
		SliceCenter = Rect.new(99, 99, 99, 99),
		BackgroundTransparency = 1,
		ZIndex = 1199,
		Parent = self.Root,
	})

	self.Header = New("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		ZIndex = 1210,
		Parent = self.Root,
	}, {
		Kit.Padding(0, { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10) }),
		Kit.List(8, { FillDirection = "Horizontal", VerticalAlignment = "Center" }),
		Kit.IconImage(self.Icon, 16, "Icon", { LayoutOrder = 1, ImageTransparency = 0.1 }),
		Kit.Label(self.Title, 15, "SemiBold", "Text", {
			LayoutOrder = 2,
			AutomaticSize = "X",
			Size = UDim2.new(0, 0, 1, 0),
			TextTransparency = 0.05,
		}),
	})

	local closeIcon = Kit.IconImage("x", 15, "Icon", {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageTransparency = 0.15,
	})
	self.CloseButton = Kit.Card(9, {
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(1, -10, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		ThemeTag = { ImageColor3 = "Text" },
		ImageTransparency = 1,
		ZIndex = 1215,
		Parent = self.Root,
	}, { closeIcon, New("UIScale", { Scale = 1 }) }, true)
	Kit.Hoverable(self.CloseButton)
	Kit.Pressable(self.CloseButton)
	Util.Bin.Connect(self.CloseButton.MouseButton1Click, function()
		self:Close()
	end)

	self.Divider = New("Frame", {
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.new(0, 10, 0, 42),
		BackgroundTransparency = 0.9,
		ThemeTag = { BackgroundColor3 = "Text" },
		BorderSizePixel = 0,
		ZIndex = 1210,
		Parent = self.Root,
	})

	-- Baris tab kategori (opsional)
	self.TabBarHeight = 0
	if self.Tabs then
		self.TabBarHeight = 38
		self.TabBar = Kit.Scroll({
			Size = UDim2.new(1, -16, 0, 32),
			Position = UDim2.new(0, 8, 0, 48),
			ScrollingDirection = "X",
			AutomaticCanvasSize = "X",
			ZIndex = 1210,
			Parent = self.Root,
		}, {
			Kit.List(5, { FillDirection = "Horizontal", VerticalAlignment = "Center" }),
		})
	end

	self.Body = Kit.Scroll({
		Size = UDim2.new(1, 0, 1, -(46 + self.TabBarHeight)),
		Position = UDim2.new(0, 0, 0, 46 + self.TabBarHeight),
		ZIndex = 1210,
		Parent = self.Root,
	}, {
		Kit.Padding(10, { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12) }),
		Kit.List(6),
	})

	-- Tinggi panel mengikuti isi secara otomatis (mis. saat dropdown dibuka).
	local layout = self.Body:FindFirstChildOfClass("UIListLayout")
	if layout then
		Util.Bin.Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			if self.Opened then
				self:Refresh()
			end
		end)
	end

	PanelRegistry[self.Id] = self
	return self
end

function Panel:Content()
	return self.Body
end

--- Membuat halaman kategori di dalam panel (dipakai Players / Settings / Developer).
function Panel:Page(name, icon)
	local page = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = "Y",
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 1210,
		Parent = self.Body,
	}, {
		Kit.List(6),
	})

	local btnLabel = Kit.Label(name, 13, "Medium", "Text", {
		AutomaticSize = "X",
		Size = UDim2.new(0, 0, 1, 0),
		TextTransparency = 0.45,
		Position = UDim2.new(0, 10, 0, 0),
	})
	local btn = Kit.Card(9, {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = "X",
		ThemeTag = { ImageColor3 = "Text" },
		ImageTransparency = 1,
		ZIndex = 1211,
		Parent = self.TabBar,
	}, {
		btnLabel,
		Kit.Padding(0, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		New("UIScale", { Scale = 1 }),
	}, true)

	local entry = { Name = name, Page = page, Button = btn, Label = btnLabel }
	table.insert(self.TabPages, entry)

	Util.Bin.Connect(btn.MouseButton1Click, function()
		self:SelectPage(name)
	end)
	Util.Bin.Connect(btn.MouseEnter, function()
		if self.ActiveTab ~= name then
			Kit.Anim(btn, 0.12, { ImageTransparency = 0.93 })
		end
	end)
	Util.Bin.Connect(btn.MouseLeave, function()
		if self.ActiveTab ~= name then
			Kit.Anim(btn, 0.12, { ImageTransparency = 1 })
		end
	end)

	if not self.ActiveTab then
		self:SelectPage(name)
	end
	return page
end

function Panel:SelectPage(name)
	self.ActiveTab = name
	for _, entry in ipairs(self.TabPages) do
		local active = entry.Name == name
		entry.Page.Visible = active
		Kit.Anim(entry.Button, 0.15, { ImageTransparency = active and 0.9 or 1 })
		Kit.Anim(entry.Label, 0.15, { TextTransparency = active and 0.05 or 0.45 })
	end
	self.Body.CanvasPosition = Vector2.zero
end

function Panel:Build()
	if self.Built then
		return
	end
	self.Built = true
	if self.Builder then
		local ok, err = pcall(self.Builder, self)
		if not ok then
			warn(("[ %s ] Gagal membangun panel '%s': %s"):format(NEXZAN_NAME, tostring(self.Id), tostring(err)))
		end
	end
end

function Panel:TargetHeight()
	local content = self.Body.UIListLayout and self.Body.UIListLayout.AbsoluteContentSize.Y or 0
	local scale = (WindUI and WindUI.UIScale) or 1
	content = content / math.max(scale, 0.01)
	local total = 46 + self.TabBarHeight + content + 18
	local windowHeight = self.Window.UIElements.Main.AbsoluteSize.Y / math.max(scale, 0.01)
	local maxAllowed = math.min(self.MaxHeight, windowHeight - ((self.Window.Topbar.Height or 52) + 24))
	return math.clamp(total, 120, math.max(140, maxAllowed))
end

function Panel:Open()
	if self.Opened then
		return
	end
	if ActivePanel and ActivePanel ~= self then
		ActivePanel:Close()
	end

	self:Build()
	self.Opened = true
	ActivePanel = self

	self.Root.Visible = true
	self.Root.Size = UDim2.new(0, self.Width, 0, 0)
	self.Root.ImageTransparency = 1
	self.Root.UIScale.Scale = 0.96

	Kit.Anim(self.Root, 0.24, {
		Size = UDim2.new(0, self.Width, 0, self:TargetHeight()),
		ImageTransparency = 0.02,
	})
	Kit.Anim(self.Root.UIScale, 0.24, { Scale = 1 })

	if self.OnOpen then
		Creator.SafeCallback(self.OnOpen, self)
	end
end

function Panel:Close()
	if not self.Opened then
		return
	end
	self.Opened = false
	if ActivePanel == self then
		ActivePanel = nil
	end

	Kit.Anim(self.Root, 0.18, { Size = UDim2.new(0, self.Width, 0, 0), ImageTransparency = 1 })
	Kit.Anim(self.Root.UIScale, 0.18, { Scale = 0.96 })
	task.delay(0.2, function()
		if not self.Opened then
			self.Root.Visible = false
		end
	end)

	if self.OnClose then
		Creator.SafeCallback(self.OnClose, self)
	end
end

function Panel:Toggle()
	if self.Opened then
		self:Close()
	else
		self:Open()
	end
end

function Panel:Refresh()
	if self.Opened then
		Kit.Anim(self.Root, 0.18, { Size = UDim2.new(0, self.Width, 0, self:TargetHeight()) })
	end
end

function Panel.CloseAll()
	for _, panel in pairs(PanelRegistry) do
		panel:Close()
	end
end

function Panel.Get(id)
	return PanelRegistry[id]
end

--// ==========================================================================
--//  4. HEADER BAR — ikon tambahan di kanan Topbar
--//     Memakai Window:CreateTopbarButton (API resmi WindUI) sehingga
--//     hover, click, warna theme, dan ukuran identik dengan bawaan.
--// ==========================================================================

local Header = {}

-- LayoutOrder bawaan WindUI: Minimize 997, Fullscreen 998, Close 999.
-- Ikon tambahan memakai order < 997 agar tampil di kiri tombol jendela.
local ORDER = {
	Search = 990,
	Players = 991,
	Settings = 992,
	Developer = 993,
}

local ICONS = {
	Search = "search",
	Players = "users-round",
	Settings = "settings",
	Developer = "wrench",
}

function Header.Init(ctx)
	local Window = ctx.Window
	local created = {}

	local function add(key, tooltip, callback)
		local ok, button = pcall(function()
			return Window:CreateTopbarButton(key, ICONS[key], callback, ORDER[key], nil, nil, nil)
		end)
		if not ok or not button then
			warn(("[ %s ] Tidak dapat menambah ikon '%s'"):format(NEXZAN_NAME, key))
			return nil
		end
		if ctx.Options.Tooltips and tooltip then
			Kit.Tooltip(button, tooltip)
		end
		created[key] = button
		return button
	end

	ctx.HeaderButtons = created
	Header.Add = add
	return Header
end

--// ==========================================================================
--//  5. SEARCH — slide down search bar + realtime search engine
--// ==========================================================================

local Search = {}

local SEARCH_TYPES = {
	Tab = "layout-grid",
	Section = "rows-3",
	Button = "mouse-pointer-click",
	Toggle = "toggle-right",
	Slider = "sliders-horizontal",
	Dropdown = "chevron-down",
	Input = "type",
	Textbox = "type",
	Label = "text",
	Paragraph = "text",
	Keybind = "keyboard",
	Colorpicker = "palette",
	Category = "folder",
}

function Search.Init(ctx)
	local Window = ctx.Window
	local self = { Opened = false, Built = false, Results = {}, Query = "" }

	local topbarHeight = (Window.Topbar and Window.Topbar.Height) or 52

	--// Index cache — dibangun ulang hanya bila jumlah tab/elemen berubah.
	local cache = { items = {}, signature = "" }

	local function signature()
		local tabModule = Window.TabModule
		if not tabModule then
			return "0"
		end
		local n, e = 0, 0
		for _, tab in pairs(tabModule.Tabs or {}) do
			n += 1
			for _ in pairs(tab.Elements or {}) do
				e += 1
			end
		end
		return n .. ":" .. e
	end

	local function buildIndex()
		local sig = signature()
		if sig == cache.signature and #cache.items > 0 then
			return cache.items
		end
		cache.signature = sig

		local items = {}
		local tabModule = Window.TabModule
		if tabModule then
			for _, tab in pairs(tabModule.Tabs or {}) do
				table.insert(items, {
					Kind = "Tab",
					Title = tostring(tab.Title or "Tab"),
					Desc = tab.Desc,
					Tab = tab,
					Icon = tab.Icon or SEARCH_TYPES.Tab,
				})
				for index, element in pairs(tab.Elements or {}) do
					local kind = element.__type or "Element"
					local title = element.Title
					if title == nil and element.__type == "Section" then
						title = element.Title or "Section"
					end
					if title ~= nil then
						table.insert(items, {
							Kind = kind,
							Title = tostring(title),
							Desc = element.Desc,
							Tab = tab,
							Index = index,
							Element = element,
							Icon = SEARCH_TYPES[kind] or "circle-dot",
						})
					end
				end
			end
		end
		cache.items = items
		return items
	end

	--// ---------------------------------------------------------------------
	--// UI
	--// ---------------------------------------------------------------------

	local barHeight = 44
	local root, box, resultList, countLabel, clearButton

	local function buildUI()
		if self.Built then
			return
		end
		self.Built = true

		local icon = Kit.IconImage("search", 17, "Icon", {
			Position = UDim2.new(0, 14, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageTransparency = 0.15,
			ZIndex = 1310,
		})

		box = New("TextBox", {
			Size = UDim2.new(1, -84, 1, 0),
			Position = UDim2.new(0, 40, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search tab, toggle, slider, dropdown...",
			FontFace = Kit.Font("Medium"),
			TextSize = 15,
			TextXAlignment = "Left",
			ClearTextOnFocus = false,
			ClipsDescendants = true,
			ZIndex = 1310,
			ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" },
		})

		local clearIcon = Kit.IconImage("x", 15, "Icon", {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 0.15,
			ZIndex = 1312,
		})
		clearButton = Kit.Card(9, {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(1, -10, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			ThemeTag = { ImageColor3 = "Text" },
			ImageTransparency = 1,
			ZIndex = 1311,
		}, { clearIcon, New("UIScale", { Scale = 1 }) }, true)
		Kit.Hoverable(clearButton)
		Kit.Pressable(clearButton)

		local bar = Kit.Card(14, {
			Size = UDim2.new(1, 0, 0, barHeight),
			ThemeTag = { ImageColor3 = "Text" },
			ImageTransparency = 0.94,
			ZIndex = 1305,
		}, { icon, box, clearButton })

		countLabel = Kit.Label("", 12, "Medium", "Text", {
			Size = UDim2.new(1, -8, 0, 16),
			Position = UDim2.new(0, 4, 0, barHeight + 6),
			AutomaticSize = "None",
			TextTransparency = 0.5,
			ZIndex = 1306,
		})

		resultList = Kit.Scroll({
			Size = UDim2.new(1, 0, 1, -(barHeight + 26)),
			Position = UDim2.new(0, 0, 0, barHeight + 24),
			ZIndex = 1306,
		}, {
			Kit.List(4),
			Kit.Padding(0, { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 2) }),
		})

		root = Kit.Card(16, {
			Size = UDim2.new(1, -20, 0, 0),
			Position = UDim2.new(0.5, 0, 0, topbarHeight - 8),
			AnchorPoint = Vector2.new(0.5, 0),
			ThemeTag = { ImageColor3 = "Dialog" },
			ImageTransparency = 0.02,
			ZIndex = 1300,
			Visible = false,
			ClipsDescendants = true,
			Parent = Window.UIElements.Main,
		}, {
			Kit.Outline(16, { ImageTransparency = 0.88, ZIndex = 1301 }),
			Kit.Padding(10),
			bar,
			countLabel,
			resultList,
			New("UIScale", { Scale = 1 }),
		})

		Util.Bin.Connect(clearButton.MouseButton1Click, function()
			if box.Text ~= "" then
				box.Text = ""
			else
				self:Close()
			end
		end)

		Util.Bin.Connect(box:GetPropertyChangedSignal("Text"), function()
			self:Update(box.Text)
		end)

		Util.Bin.Connect(box.FocusLost, function(enter)
			if enter then
				local first = self.Results[1]
				if first then
					self:Goto(first)
				end
			end
		end)
	end

	--// ---------------------------------------------------------------------
	--// Result rendering
	--// ---------------------------------------------------------------------

	local rowPool = {}

	local function releaseRows()
		for _, row in ipairs(rowPool) do
			row.Frame.Visible = false
		end
	end

	local function highlightText(text, query)
		if query == "" then
			return text
		end
		local lower = string.lower(text)
		local q = string.lower(query)
		local s, e = string.find(lower, q, 1, true)
		if not s then
			return text
		end
		-- RichText highlight (font WindUI mendukung RichText)
		return string.format(
			'%s<font color="#ffd166"><b>%s</b></font>%s',
			text:sub(1, s - 1),
			text:sub(s, e),
			text:sub(e + 1)
		)
	end

	local function acquireRow(i)
		local row = rowPool[i]
		if row then
			row.Frame.Visible = true
			return row
		end

		local iconImg = Kit.IconImage("circle-dot", 15, "Icon", {
			Position = UDim2.new(0, 11, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageTransparency = 0.25,
			ZIndex = 1308,
		})
		local title = Kit.Label("", 13, "Medium", "Text", {
			Position = UDim2.new(0, 36, 0, 6),
			Size = UDim2.new(1, -110, 0, 17),
			AutomaticSize = "None",
			TextTransparency = 0.08,
			TextTruncate = "AtEnd",
			ZIndex = 1308,
		})
		local sub = Kit.Label("", 11, "Regular", "Text", {
			Position = UDim2.new(0, 36, 0, 22),
			Size = UDim2.new(1, -110, 0, 14),
			AutomaticSize = "None",
			TextTransparency = 0.55,
			TextTruncate = "AtEnd",
			ZIndex = 1308,
		})
		local badge = Kit.Label("", 11, "SemiBold", "Text", {
			Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.new(0, 80, 0, 16),
			AutomaticSize = "None",
			TextXAlignment = "Right",
			TextTransparency = 0.5,
			ZIndex = 1308,
		})

		local frame = Kit.Card(11, {
			Size = UDim2.new(1, 0, 0, 44),
			ThemeTag = { ImageColor3 = "Text" },
			ImageTransparency = 0.95,
			ZIndex = 1307,
			LayoutOrder = i,
			Parent = resultList,
		}, { iconImg, title, sub, badge, New("UIScale", { Scale = 1 }) }, true)

		row = { Frame = frame, Icon = iconImg, Title = title, Sub = sub, Badge = badge }
		rowPool[i] = row

		Util.Bin.Connect(frame.MouseEnter, function()
			Kit.Anim(frame, 0.12, { ImageTransparency = 0.88 })
		end)
		Util.Bin.Connect(frame.MouseLeave, function()
			Kit.Anim(frame, 0.12, { ImageTransparency = 0.95 })
		end)
		Util.Bin.Connect(frame.MouseButton1Down, function()
			Kit.Anim(frame.UIScale, 0.18, { Scale = 0.98 })
		end)
		Util.Bin.Connect(frame.InputEnded, function()
			Kit.Anim(frame.UIScale, 0.18, { Scale = 1 })
		end)
		Util.Bin.Connect(frame.MouseButton1Click, function()
			if row.Item then
				self:Goto(row.Item)
			end
		end)
		return row
	end

	local function score(item, query)
		local title = string.lower(item.Title)
		if query == "" then
			return 1
		end
		if title == query then
			return 1000
		end
		local s = string.find(title, query, 1, true)
		if s then
			return 500 - s
		end
		if item.Desc and string.find(string.lower(tostring(item.Desc)), query, 1, true) then
			return 100
		end
		if string.find(string.lower(item.Kind), query, 1, true) then
			return 50
		end
		return nil
	end

	function self:Update(query)
		query = string.lower(string.gsub(tostring(query or ""), "^%s+", ""))
		self.Query = query

		local items = buildIndex()
		local matched = {}
		for _, item in ipairs(items) do
			local s = score(item, query)
			if s then
				item.Score = s
				table.insert(matched, item)
			end
		end
		table.sort(matched, function(a, b)
			if a.Score == b.Score then
				return a.Title < b.Title
			end
			return a.Score > b.Score
		end)

		self.Results = matched
		releaseRows()

		local shown = math.min(#matched, 60)
		for i = 1, shown do
			local item = matched[i]
			local row = acquireRow(i)
			row.Item = item
			row.Title.Text = highlightText(item.Title, query)
			row.Sub.Text = item.Tab and ("in " .. tostring(item.Tab.Title)) or ""
			row.Badge.Text = item.Kind
			local iconData = Creator.Icon(item.Icon)
			if iconData and iconData[1] then
				row.Icon.Image = iconData[1]
				row.Icon.ImageRectOffset = iconData[2] and iconData[2].ImageRectPosition or Vector2.zero
				row.Icon.ImageRectSize = iconData[2] and iconData[2].ImageRectSize or Vector2.zero
			end
			row.Frame.LayoutOrder = i
		end

		if query == "" then
			countLabel.Text = string.format("%d items", #matched)
		elseif #matched == 0 then
			countLabel.Text = "No results for \"" .. Util.Truncate(query, 24) .. "\""
		else
			countLabel.Text = string.format("%d result%s", #matched, #matched == 1 and "" or "s")
		end

		resultList.CanvasPosition = Vector2.zero
	end

	function self:Goto(item)
		if not item then
			return
		end
		local tabModule = Window.TabModule
		if item.Tab and tabModule then
			Util.Try(function()
				tabModule:SelectTab(item.Tab.Index)
			end)
		end
		if item.Index and item.Tab and item.Tab.ScrollToTheElement then
			task.delay(0.12, function()
				Util.Try(function()
					item.Tab:ScrollToTheElement(item.Index)
				end)
			end)
		end
		self:Close()
	end

	--// ---------------------------------------------------------------------
	--// Open / Close (Slide Down)
	--// ---------------------------------------------------------------------

	function self:TargetHeight()
		local scale = (WindUI and WindUI.UIScale) or 1
		local windowHeight = Window.UIElements.Main.AbsoluteSize.Y / math.max(scale, 0.01)
		return math.clamp(windowHeight - topbarHeight - 24, 140, 380)
	end

	function self:Open()
		if self.Opened then
			return
		end
		buildUI()
		Panel.CloseAll()
		self.Opened = true

		root.Visible = true
		root.Size = UDim2.new(1, -20, 0, 0)
		root.Position = UDim2.new(0.5, 0, 0, topbarHeight - 22)
		root.ImageTransparency = 1

		Kit.Anim(root, 0.26, {
			Size = UDim2.new(1, -20, 0, self:TargetHeight()),
			Position = UDim2.new(0.5, 0, 0, topbarHeight - 8),
			ImageTransparency = 0.02,
		})

		self:Update("")
		task.defer(function()
			if self.Opened and Util.IsPC then
				Util.Try(function()
					box:CaptureFocus()
				end)
			end
		end)
	end

	function self:Close()
		if not self.Opened then
			return
		end
		self.Opened = false
		Util.Try(function()
			box:ReleaseFocus()
		end)
		Kit.Anim(root, 0.2, {
			Size = UDim2.new(1, -20, 0, 0),
			Position = UDim2.new(0.5, 0, 0, topbarHeight - 22),
			ImageTransparency = 1,
		})
		task.delay(0.22, function()
			if not self.Opened and root then
				root.Visible = false
				box.Text = ""
			end
		end)
	end

	function self:Toggle()
		if self.Opened then
			self:Close()
		else
			self:Open()
		end
	end

	ctx.Search = self
	return self
end

--// ==========================================================================
--//  6. PLAYER FEATURES — Movement, Camera, ESP, Teleport, Misc
--//     Semua memakai Scheduler bersama (tanpa loop liar) & auto-cleanup.
--// ==========================================================================

local Features = {}

local Camera = workspace.CurrentCamera
Util.Bin.Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	Camera = workspace.CurrentCamera
end)

--// --------------------------------------------------------------------------
--//  State + default (untuk Reset)
--// --------------------------------------------------------------------------

local State = {
	WalkSpeed = 16,
	JumpPower = 50,
	HipHeight = 0,
	Gravity = workspace.Gravity,
	FOV = 70,
	Zoom = 128,
	CameraOffset = 0,
	Fly = false,
	FlySpeed = 60,
	NoClip = false,
	InfiniteJump = false,
	AntiAFK = false,
	Freecam = false,
	UnlockCamera = false,
	FirstPersonLock = false,
	ESP = {
		Player = false,
		Name = false,
		Health = false,
		Distance = false,
		Box = false,
		Tracer = false,
		Skeleton = false,
		TeamCheck = false,
		MaxDistance = 2000,
	},
	Spectating = nil,
}
Features.State = State

local Defaults = {
	WalkSpeed = 16,
	JumpPower = 50,
	JumpHeight = 7.2,
	HipHeight = 0,
	Gravity = workspace.Gravity,
	FOV = 70,
	MinZoom = 0.5,
	MaxZoom = 128,
	CameraMode = Enum.CameraMode.Classic,
}
Features.Defaults = Defaults

local function captureDefaults()
	local hum = Util.Char.Humanoid()
	if hum then
		Defaults.WalkSpeed = hum.WalkSpeed
		Defaults.JumpPower = hum.UseJumpPower and hum.JumpPower or 50
		Defaults.JumpHeight = hum.JumpHeight
		Defaults.HipHeight = hum.HipHeight
		State.WalkSpeed = hum.WalkSpeed
		State.JumpPower = Defaults.JumpPower
		State.HipHeight = hum.HipHeight
	end
	if Camera then
		Defaults.FOV = Camera.FieldOfView
		State.FOV = Camera.FieldOfView
	end
	if LocalPlayer then
		Defaults.MinZoom = LocalPlayer.CameraMinZoomDistance
		Defaults.MaxZoom = LocalPlayer.CameraMaxZoomDistance
		Defaults.CameraMode = LocalPlayer.CameraMode
		State.Zoom = LocalPlayer.CameraMaxZoomDistance
	end
end

--// --------------------------------------------------------------------------
--//  Movement
--// --------------------------------------------------------------------------

function Features.SetWalkSpeed(value)
	State.WalkSpeed = value
	local hum = Util.Char.Humanoid()
	if hum then
		hum.WalkSpeed = value
	end
end

function Features.SetJumpPower(value)
	State.JumpPower = value
	local hum = Util.Char.Humanoid()
	if hum then
		if hum.UseJumpPower then
			hum.JumpPower = value
		else
			hum.JumpHeight = value / 7
		end
	end
end

function Features.SetHipHeight(value)
	State.HipHeight = value
	local hum = Util.Char.Humanoid()
	if hum then
		hum.HipHeight = value
	end
end

function Features.SetGravity(value)
	State.Gravity = value
	workspace.Gravity = value
end

function Features.SetFOV(value)
	State.FOV = value
	if Camera then
		Camera.FieldOfView = value
	end
end

function Features.SetZoom(value)
	State.Zoom = value
	if LocalPlayer then
		LocalPlayer.CameraMaxZoomDistance = value
	end
end

function Features.SetCameraOffset(value)
	State.CameraOffset = value
	local hum = Util.Char.Humanoid()
	if hum then
		hum.CameraOffset = Vector3.new(0, value, 0)
	end
end

function Features.ApplyPersistentState()
	local hum = Util.Char.Humanoid()
	if not hum then
		return
	end
	Features.SetWalkSpeed(State.WalkSpeed)
	Features.SetJumpPower(State.JumpPower)
	Features.SetHipHeight(State.HipHeight)
	Features.SetCameraOffset(State.CameraOffset)
	if State.NoClip then
		Features.SetNoClip(true)
	end
	if State.Fly then
		Features.SetFly(true)
	end
end

--// Fly (BodyVelocity/BodyGyro klasik — kompatibel luas)
local flyParts = {}

local function destroyFly()
	for _, part in pairs(flyParts) do
		Util.Try(function()
			part:Destroy()
		end)
	end
	table.clear(flyParts)
	Util.Scheduler.Remove("nexzan_fly")
end

function Features.SetFly(enabled)
	State.Fly = enabled and true or false
	destroyFly()

	if not State.Fly then
		local hum = Util.Char.Humanoid()
		if hum then
			hum.PlatformStand = false
		end
		return
	end

	local root = Util.Char.Root()
	local hum = Util.Char.Humanoid()
	if not root or not hum then
		State.Fly = false
		return
	end

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	velocity.Velocity = Vector3.zero
	velocity.Parent = root

	local gyro = Instance.new("BodyGyro")
	gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	gyro.P = 9e4
	gyro.CFrame = root.CFrame
	gyro.Parent = root

	flyParts.velocity = velocity
	flyParts.gyro = gyro

	Util.Scheduler.Add("nexzan_fly", 0, function()
		if not State.Fly or not velocity.Parent then
			destroyFly()
			return
		end
		local cam = Camera
		if not cam then
			return
		end

		local direction = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			direction += cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			direction -= cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			direction -= cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			direction += cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.yAxis
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			direction -= Vector3.yAxis
		end

		-- Mobile: arahkan lewat MoveVector joystick
		if Util.IsMobile then
			local move = hum.MoveDirection
			if move.Magnitude > 0 then
				direction += move
			end
			if hum.Jump then
				direction += Vector3.yAxis
			end
		end

		gyro.CFrame = cam.CFrame
		if direction.Magnitude > 0 then
			velocity.Velocity = direction.Unit * State.FlySpeed
		else
			velocity.Velocity = Vector3.zero
		end
	end)
end

--// NoClip
function Features.SetNoClip(enabled)
	State.NoClip = enabled and true or false
	if not State.NoClip then
		Util.Scheduler.Remove("nexzan_noclip")
		local char = Util.Char.Get()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide == false and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end
		return
	end

	Util.Scheduler.Add("nexzan_noclip", 0.1, function()
		local char = Util.Char.Get()
		if not char then
			return
		end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end)
end

--// Infinite Jump
local infiniteJumpConn
function Features.SetInfiniteJump(enabled)
	State.InfiniteJump = enabled and true or false
	if infiniteJumpConn then
		infiniteJumpConn:Disconnect()
		infiniteJumpConn = nil
	end
	if State.InfiniteJump then
		infiniteJumpConn = Util.Bin.Connect(UserInputService.JumpRequest, function()
			local hum = Util.Char.Humanoid()
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end

--// Anti AFK
local antiAfkConn
function Features.SetAntiAFK(enabled)
	State.AntiAFK = enabled and true or false
	if antiAfkConn then
		antiAfkConn:Disconnect()
		antiAfkConn = nil
	end
	if State.AntiAFK then
		antiAfkConn = Util.Bin.Connect(LocalPlayer.Idled, function()
			Util.Try(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end
end

function Features.ResetCharacter()
	local hum = Util.Char.Humanoid()
	if hum then
		hum.Health = 0
	end
end

function Features.Respawn()
	local char = Util.Char.Get()
	if char then
		Util.Try(function()
			LocalPlayer:LoadCharacter()
		end)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum.Health = 0
		end
	end
end

--// --------------------------------------------------------------------------
--//  Camera
--// --------------------------------------------------------------------------

function Features.SetUnlockCamera(enabled)
	State.UnlockCamera = enabled and true or false
	if State.UnlockCamera then
		LocalPlayer.CameraMinZoomDistance = 0.5
		LocalPlayer.CameraMaxZoomDistance = math.max(State.Zoom, 400)
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
	else
		LocalPlayer.CameraMinZoomDistance = Defaults.MinZoom
		LocalPlayer.CameraMaxZoomDistance = State.Zoom
	end
end

function Features.SetFirstPersonLock(enabled)
	State.FirstPersonLock = enabled and true or false
	if State.FirstPersonLock then
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		LocalPlayer.CameraMode = Defaults.CameraMode
	end
end

function Features.ThirdPerson()
	LocalPlayer.CameraMode = Enum.CameraMode.Classic
	LocalPlayer.CameraMinZoomDistance = 0.5
	LocalPlayer.CameraMaxZoomDistance = math.max(State.Zoom, 12)
	State.FirstPersonLock = false
end

function Features.FirstPerson()
	LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
end

--// Freecam
local freecam = { cf = nil, speed = 60 }
function Features.SetFreecam(enabled)
	State.Freecam = enabled and true or false
	if not State.Freecam then
		Util.Scheduler.Remove("nexzan_freecam")
		if Camera then
			Camera.CameraType = Enum.CameraType.Custom
			local char = Util.Char.Get()
			if char then
				Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid") or Camera.CameraSubject
			end
		end
		return
	end
	if not Camera then
		State.Freecam = false
		return
	end

	freecam.cf = Camera.CFrame
	Camera.CameraType = Enum.CameraType.Scriptable

	Util.Scheduler.Add("nexzan_freecam", 0, function(dt)
		if not State.Freecam or not Camera then
			return
		end
		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			move += Vector3.new(0, 0, -1)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			move += Vector3.new(0, 0, 1)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			move += Vector3.new(-1, 0, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			move += Vector3.new(1, 0, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			move += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			move += Vector3.new(0, -1, 0)
		end

		local delta = UserInputService:GetMouseDelta()
		local rot = CFrame.Angles(0, -delta.X * 0.003, 0) * CFrame.Angles(-delta.Y * 0.003, 0, 0)
		freecam.cf = (freecam.cf or Camera.CFrame)
		freecam.cf = CFrame.new(freecam.cf.Position) * CFrame.Angles(0, select(2, freecam.cf:ToEulerAnglesYXZ()), 0)
			* rot
		if move.Magnitude > 0 then
			freecam.cf = freecam.cf + (freecam.cf:VectorToWorldSpace(move.Unit) * freecam.speed * (dt or 0.016))
		end
		Camera.CFrame = freecam.cf
	end)
end

--// --------------------------------------------------------------------------
--//  ESP — Highlight + Billboard + Drawing-less box/tracer via Frames
--//  Menggunakan satu ScreenGui terpisah, dibersihkan otomatis.
--// --------------------------------------------------------------------------

local ESP = { objects = {}, gui = nil }
Features.ESP = ESP

local SKELETON_PAIRS = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
	-- R6 fallback
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

local function espGui()
	if ESP.gui and ESP.gui.Parent then
		return ESP.gui
	end
	local parent = (gethui and gethui()) or (WindUI and WindUI.ScreenGui and WindUI.ScreenGui.Parent) or LocalPlayer:WaitForChild("PlayerGui")
	ESP.gui = Creator.New("ScreenGui", {
		Name = "NexzanESP",
		Parent = parent,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = -99998,
	})
	Util.Bin.Track(ESP.gui)
	return ESP.gui
end

local function createESPObject(player)
	if ESP.objects[player] then
		return ESP.objects[player]
	end
	local gui = espGui()

	local highlight = Instance.new("Highlight")
	highlight.Name = "NexzanHighlight"
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	highlight.Parent = gui

	local nameLabel = Creator.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 15),
		FontFace = Kit.Font("SemiBold"),
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		Text = player.DisplayName,
		LayoutOrder = 1,
	})
	local infoLabel = Creator.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 13),
		FontFace = Kit.Font("Medium"),
		TextSize = 11,
		TextColor3 = Color3.fromRGB(210, 210, 215),
		TextStrokeTransparency = 0.6,
		Text = "",
		LayoutOrder = 2,
	})
	local healthBg = Creator.New("Frame", {
		Size = UDim2.new(0, 60, 0, 4),
		BackgroundColor3 = Color3.fromRGB(30, 30, 35),
		BorderSizePixel = 0,
		LayoutOrder = 3,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Creator.New("Frame", {
			Name = "Fill",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(80, 220, 120),
			BorderSizePixel = 0,
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
	})

	local billboard = Creator.New("BillboardGui", {
		Name = "NexzanTag",
		Size = UDim2.new(0, 190, 0, 46),
		AlwaysOnTop = true,
		StudsOffset = Vector3.new(0, 2.6, 0),
		Enabled = false,
		Parent = gui,
	}, {
		Creator.New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Kit.List(1, { HorizontalAlignment = "Center", VerticalAlignment = "Bottom" }),
			nameLabel,
			infoLabel,
			healthBg,
		}),
	})

	local box = Creator.New("Frame", {
		Name = "NexzanBox",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	}, {
		Creator.New("UIStroke", { Color = Color3.fromRGB(120, 200, 255), Thickness = 1.4, Transparency = 0.1 }),
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
	})

	local tracer = Creator.New("Frame", {
		Name = "NexzanTracer",
		BackgroundColor3 = Color3.fromRGB(120, 200, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0, 1, 0, 0),
		Visible = false,
		Parent = gui,
	})

	local bones = {}
	for i = 1, #SKELETON_PAIRS do
		bones[i] = Creator.New("Frame", {
			Name = "Bone" .. i,
			BackgroundColor3 = Color3.fromRGB(200, 240, 255),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 1, 0, 0),
			Visible = false,
			Parent = gui,
		})
	end

	local obj = {
		Player = player,
		Highlight = highlight,
		Billboard = billboard,
		Name = nameLabel,
		Info = infoLabel,
		HealthBg = healthBg,
		HealthFill = healthBg.Fill,
		Box = box,
		Tracer = tracer,
		Bones = bones,
	}
	ESP.objects[player] = obj
	return obj
end

local function destroyESPObject(player)
	local obj = ESP.objects[player]
	if not obj then
		return
	end
	Util.Try(function()
		obj.Highlight:Destroy()
	end)
	Util.Try(function()
		obj.Billboard:Destroy()
	end)
	Util.Try(function()
		obj.Box:Destroy()
	end)
	Util.Try(function()
		obj.Tracer:Destroy()
	end)
	for _, bone in ipairs(obj.Bones) do
		Util.Try(function()
			bone:Destroy()
		end)
	end
	ESP.objects[player] = nil
end

local function anyESPEnabled()
	local e = State.ESP
	return e.Player or e.Name or e.Health or e.Distance or e.Box or e.Tracer or e.Skeleton
end

local function teamColor(player)
	if player.Team and player.TeamColor then
		return player.TeamColor.Color
	end
	return Color3.fromRGB(120, 200, 255)
end

local function updateESP()
	local e = State.ESP
	if not anyESPEnabled() then
		for player in pairs(ESP.objects) do
			destroyESPObject(player)
		end
		Util.Scheduler.Remove("nexzan_esp")
		return
	end

	local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local bottomCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local obj = ESP.objects[player]

			local sameTeam = e.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team

			if not char or not root or not hum or hum.Health <= 0 or sameTeam then
				if obj then
					obj.Highlight.Enabled = false
					obj.Billboard.Enabled = false
					obj.Box.Visible = false
					obj.Tracer.Visible = false
					for _, bone in ipairs(obj.Bones) do
						bone.Visible = false
					end
				end
			else
				obj = obj or createESPObject(player)
				local color = teamColor(player)
				local distance = Util.Char.Distance(player)

				if distance > e.MaxDistance then
					obj.Highlight.Enabled = false
					obj.Billboard.Enabled = false
					obj.Box.Visible = false
					obj.Tracer.Visible = false
					for _, bone in ipairs(obj.Bones) do
						bone.Visible = false
					end
					continue
				end

				-- Highlight
				obj.Highlight.Enabled = e.Player
				if e.Player then
					obj.Highlight.Adornee = char
					obj.Highlight.FillColor = color
					obj.Highlight.OutlineColor = color
				end

				-- Billboard (Name / Health / Distance)
				local wantTag = e.Name or e.Health or e.Distance
				obj.Billboard.Enabled = wantTag
				if wantTag then
					obj.Billboard.Adornee = char:FindFirstChild("Head") or root
					obj.Name.Visible = e.Name
					obj.Name.Text = player.DisplayName
					obj.Name.TextColor3 = color
					obj.HealthBg.Visible = e.Health
					if e.Health then
						local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
						obj.HealthFill.Size = UDim2.new(ratio, 0, 1, 0)
						obj.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(80, 220, 120), ratio)
					end
					obj.Info.Visible = e.Distance
					if e.Distance then
						obj.Info.Text = string.format("%d studs", math.floor(distance))
					end
				end

				-- Box & Tracer (screen-space)
				local needScreen = e.Box or e.Tracer or e.Skeleton
				if needScreen and Camera then
					local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
					if onScreen then
						local scaleFactor = 1 / (pos.Z * 0.5)
						local height = math.clamp(1600 * scaleFactor, 12, 900)
						local width = height * 0.55

						if e.Box then
							obj.Box.Visible = true
							obj.Box.Size = UDim2.fromOffset(width, height)
							obj.Box.Position = UDim2.fromOffset(pos.X - width / 2, pos.Y - height / 2)
							obj.Box.UIStroke.Color = color
						else
							obj.Box.Visible = false
						end

						if e.Tracer then
							local delta = Vector2.new(pos.X, pos.Y) - bottomCenter
							obj.Tracer.Visible = true
							obj.Tracer.BackgroundColor3 = color
							obj.Tracer.Position = UDim2.fromOffset(bottomCenter.X, bottomCenter.Y)
							obj.Tracer.Size = UDim2.fromOffset(1.6, delta.Magnitude)
							obj.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
							obj.Tracer.AnchorPoint = Vector2.new(0.5, 0)
						else
							obj.Tracer.Visible = false
						end

						if e.Skeleton then
							for i, pair in ipairs(SKELETON_PAIRS) do
								local a = char:FindFirstChild(pair[1])
								local b = char:FindFirstChild(pair[2])
								local bone = obj.Bones[i]
								if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
									local pa, va = Camera:WorldToViewportPoint(a.Position)
									local pb, vb = Camera:WorldToViewportPoint(b.Position)
									if va and vb then
										local v2a = Vector2.new(pa.X, pa.Y)
										local v2b = Vector2.new(pb.X, pb.Y)
										local diff = v2b - v2a
										bone.Visible = true
										bone.BackgroundColor3 = color
										bone.Position = UDim2.fromOffset((v2a.X + v2b.X) / 2, (v2a.Y + v2b.Y) / 2)
										bone.Size = UDim2.fromOffset(1.4, diff.Magnitude)
										bone.Rotation = math.deg(math.atan2(diff.Y, diff.X)) - 90
									else
										bone.Visible = false
									end
								else
									bone.Visible = false
								end
							end
						else
							for _, bone in ipairs(obj.Bones) do
								bone.Visible = false
							end
						end
					else
						obj.Box.Visible = false
						obj.Tracer.Visible = false
						for _, bone in ipairs(obj.Bones) do
							bone.Visible = false
						end
					end
				else
					obj.Box.Visible = false
					obj.Tracer.Visible = false
					for _, bone in ipairs(obj.Bones) do
						bone.Visible = false
					end
				end
			end
		end
	end
end

function Features.SetESP(key, enabled)
	State.ESP[key] = enabled and true or false
	if anyESPEnabled() then
		if not Util.Scheduler.Has("nexzan_esp") then
			-- 30 Hz: cukup halus, jauh lebih hemat daripada tiap frame.
			Util.Scheduler.Add("nexzan_esp", 1 / 30, updateESP)
		end
	else
		Util.Scheduler.Remove("nexzan_esp")
		for player in pairs(ESP.objects) do
			destroyESPObject(player)
		end
	end
end

Util.Bin.Connect(Players.PlayerRemoving, function(player)
	destroyESPObject(player)
	if State.Spectating == player then
		Features.Spectate(nil)
	end
end)

--// --------------------------------------------------------------------------
--//  Teleport / Server
--// --------------------------------------------------------------------------

function Features.TeleportTo(player)
	local target = Util.Char.Root(player)
	local myRoot = Util.Char.Root()
	if target and myRoot then
		myRoot.CFrame = target.CFrame * CFrame.new(0, 0, 3)
		return true
	end
	return false
end

function Features.Spectate(player)
	if not Camera then
		return
	end
	if not player then
		State.Spectating = nil
		local char = Util.Char.Get()
		Camera.CameraSubject = char and char:FindFirstChildOfClass("Humanoid") or Camera.CameraSubject
		return
	end
	local hum = Util.Char.Humanoid(player)
	if hum then
		State.Spectating = player
		Camera.CameraSubject = hum
	end
end

function Features.Rejoin()
	Util.Try(function()
		if #Players:GetPlayers() <= 1 then
			LocalPlayer:Kick("[Nexzan Hub] Rejoining...")
			task.wait(0.5)
		end
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end

function Features.ServerHop(onStatus)
	task.spawn(function()
		local function say(msg)
			if onStatus then
				Creator.SafeCallback(onStatus, msg)
			end
		end
		say("Mencari server...")
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if not ok then
			say("Gagal mengambil daftar server")
			return
		end
		local ok2, data = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if not ok2 or type(data) ~= "table" or not data.data then
			say("Data server tidak valid")
			return
		end
		local candidates = {}
		for _, server in ipairs(data.data) do
			if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
				table.insert(candidates, server.id)
			end
		end
		if #candidates == 0 then
			say("Tidak ada server lain yang tersedia")
			return
		end
		local pick = candidates[math.random(1, #candidates)]
		say("Teleport ke server baru...")
		Util.Try(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LocalPlayer)
		end)
	end)
end

--// --------------------------------------------------------------------------
--//  Character respawn hook — state persist (WalkSpeed dsb tetap setelah mati)
--// --------------------------------------------------------------------------

local function hookCharacter(char)
	task.defer(function()
		char:WaitForChild("Humanoid", 10)
		task.wait(0.15)
		Features.ApplyPersistentState()
	end)
end

if LocalPlayer.Character then
	captureDefaults()
end
Util.Bin.Connect(LocalPlayer.CharacterAdded, hookCharacter)
task.defer(captureDefaults)

function Features.ResetAll()
	Features.SetFly(false)
	Features.SetNoClip(false)
	Features.SetInfiniteJump(false)
	Features.SetFreecam(false)
	Features.SetFirstPersonLock(false)
	Features.Spectate(nil)
	for key in pairs(State.ESP) do
		if type(State.ESP[key]) == "boolean" then
			Features.SetESP(key, false)
		end
	end
	Features.SetWalkSpeed(Defaults.WalkSpeed)
	Features.SetJumpPower(Defaults.JumpPower)
	Features.SetHipHeight(Defaults.HipHeight)
	Features.SetGravity(Defaults.Gravity)
	Features.SetFOV(Defaults.FOV)
	Features.SetCameraOffset(0)
	LocalPlayer.CameraMinZoomDistance = Defaults.MinZoom
	LocalPlayer.CameraMaxZoomDistance = Defaults.MaxZoom
	LocalPlayer.CameraMode = Defaults.CameraMode
end

--// ==========================================================================
--//  7. PLAYERS PANEL
--// ==========================================================================

local PlayersPanel = {}

local function playerNames(excludeSelf)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if not (excludeSelf and p == LocalPlayer) then
			table.insert(list, p.Name)
		end
	end
	table.sort(list)
	return list
end

function PlayersPanel.Init(ctx)
	local C = Kit.Controls
	local liveInfo = {}
	local targetDropdown
	local targetName

	local panel = Panel.new(ctx, {
		Id = "Players",
		Title = "Players",
		Icon = "users-round",
		Width = 320,
		MaxHeight = 400,
		Tabs = true,

		Build = function(self)
			--// ---------------- Movement ----------------
			local movement = self:Page("Movement", "footprints")

			C.Section(movement, "Speed & Jump", 1)
			local speedSlider = C.Slider(movement, {
				Title = "WalkSpeed",
				Min = 8,
				Max = 500,
				Value = Features.State.WalkSpeed,
				LayoutOrder = 2,
				Callback = Features.SetWalkSpeed,
			})
			C.Slider(movement, {
				Title = "JumpPower",
				Min = 0,
				Max = 500,
				Value = Features.State.JumpPower,
				LayoutOrder = 3,
				Callback = Features.SetJumpPower,
			})
			C.Slider(movement, {
				Title = "HipHeight",
				Min = 0,
				Max = 30,
				Value = Features.State.HipHeight,
				LayoutOrder = 4,
				Callback = Features.SetHipHeight,
			})
			C.Slider(movement, {
				Title = "Gravity",
				Min = 0,
				Max = 300,
				Value = Features.State.Gravity,
				LayoutOrder = 5,
				Callback = Features.SetGravity,
			})
			C.Slider(movement, {
				Title = "FOV",
				Min = 30,
				Max = 120,
				Value = Features.State.FOV,
				LayoutOrder = 6,
				Callback = Features.SetFOV,
			})

			C.Section(movement, "Abilities", 10)
			C.Toggle(movement, {
				Title = "Fly",
				LayoutOrder = 11,
				Tooltip = "WASD + Space/Shift (PC) atau joystick (Mobile)",
				Callback = Features.SetFly,
			})
			C.Slider(movement, {
				Title = "Fly Speed",
				Min = 10,
				Max = 400,
				Value = Features.State.FlySpeed,
				LayoutOrder = 12,
				Callback = function(v)
					Features.State.FlySpeed = v
				end,
			})
			C.Toggle(movement, { Title = "NoClip", LayoutOrder = 13, Callback = Features.SetNoClip })
			C.Toggle(movement, { Title = "Infinite Jump", LayoutOrder = 14, Callback = Features.SetInfiniteJump })

			C.Section(movement, "Preset", 20)
			C.Dropdown(movement, {
				Title = "Speed Preset",
				Values = { "Normal (16)", "Fast (32)", "Sonic (64)", "Hyper (120)", "Insane (250)" },
				Value = "Normal (16)",
				LayoutOrder = 21,
				Callback = function(v)
					local map = {
						["Normal (16)"] = 16,
						["Fast (32)"] = 32,
						["Sonic (64)"] = 64,
						["Hyper (120)"] = 120,
						["Insane (250)"] = 250,
					}
					local value = map[v] or 16
					Features.SetWalkSpeed(value)
					speedSlider:Set(value, true)
				end,
			})

			C.Section(movement, "Character", 30)
			C.Button(movement, {
				Title = "Reset Character",
				Icon = "skull",
				LayoutOrder = 31,
				Callback = Features.ResetCharacter,
			})
			C.Button(movement, {
				Title = "Respawn",
				Icon = "rotate-ccw",
				LayoutOrder = 32,
				Callback = Features.Respawn,
			})

			--// ---------------- Camera ----------------
			local camera = self:Page("Camera", "camera")

			C.Section(camera, "View", 1)
			C.Slider(camera, {
				Title = "Zoom Distance",
				Min = 10,
				Max = 1000,
				Value = Features.State.Zoom,
				LayoutOrder = 2,
				Callback = Features.SetZoom,
			})
			C.Slider(camera, {
				Title = "Camera Offset (Y)",
				Min = -10,
				Max = 20,
				Value = 0,
				LayoutOrder = 3,
				Callback = Features.SetCameraOffset,
			})

			C.Section(camera, "Mode", 10)
			C.Toggle(camera, { Title = "Freecam", LayoutOrder = 11, Callback = Features.SetFreecam })
			C.Toggle(camera, { Title = "Unlock Camera", LayoutOrder = 12, Callback = Features.SetUnlockCamera })
			C.Toggle(camera, { Title = "First Person Lock", LayoutOrder = 13, Callback = Features.SetFirstPersonLock })
			C.Button(camera, {
				Title = "Third Person",
				Icon = "user",
				LayoutOrder = 14,
				Callback = Features.ThirdPerson,
			})
			C.Button(camera, { Title = "First Person", Icon = "eye", LayoutOrder = 15, Callback = Features.FirstPerson })

			--// ---------------- ESP ----------------
			local esp = self:Page("ESP", "scan-eye")

			C.Section(esp, "Visuals", 1)
			C.Toggle(esp, {
				Title = "Player ESP",
				LayoutOrder = 2,
				Callback = function(v)
					Features.SetESP("Player", v)
				end,
			})
			C.Toggle(esp, {
				Title = "Name ESP",
				LayoutOrder = 3,
				Callback = function(v)
					Features.SetESP("Name", v)
				end,
			})
			C.Toggle(esp, {
				Title = "Health ESP",
				LayoutOrder = 4,
				Callback = function(v)
					Features.SetESP("Health", v)
				end,
			})
			C.Toggle(esp, {
				Title = "Distance ESP",
				LayoutOrder = 5,
				Callback = function(v)
					Features.SetESP("Distance", v)
				end,
			})
			C.Toggle(esp, {
				Title = "Box ESP",
				LayoutOrder = 6,
				Callback = function(v)
					Features.SetESP("Box", v)
				end,
			})
			C.Toggle(esp, {
				Title = "Tracer ESP",
				LayoutOrder = 7,
				Callback = function(v)
					Features.SetESP("Tracer", v)
				end,
			})
			C.Toggle(esp, {
				Title = "Skeleton ESP",
				LayoutOrder = 8,
				Callback = function(v)
					Features.SetESP("Skeleton", v)
				end,
			})

			C.Section(esp, "Filter", 20)
			C.Toggle(esp, {
				Title = "Team Check",
				LayoutOrder = 21,
				Callback = function(v)
					Features.State.ESP.TeamCheck = v
				end,
			})
			C.Slider(esp, {
				Title = "Max Distance",
				Min = 100,
				Max = 5000,
				Step = 50,
				Value = Features.State.ESP.MaxDistance,
				LayoutOrder = 22,
				Callback = function(v)
					Features.State.ESP.MaxDistance = v
				end,
			})

			--// ---------------- Teleport ----------------
			local teleport = self:Page("Teleport", "move-3d")

			C.Section(teleport, "Target", 1)
			targetDropdown = C.Dropdown(teleport, {
				Title = "Player",
				Values = playerNames(true),
				LayoutOrder = 2,
				Callback = function(v)
					targetName = v
				end,
			})
			C.Button(teleport, {
				Title = "Refresh Player List",
				Icon = "refresh-cw",
				LayoutOrder = 3,
				Callback = function()
					targetDropdown:SetValues(playerNames(true))
					Nexzan.Notify("Players", "Daftar pemain diperbarui", "refresh-cw")
				end,
			})

			C.Section(teleport, "Action", 10)
			C.Button(teleport, {
				Title = "Teleport To Player",
				Icon = "map-pin",
				LayoutOrder = 11,
				Callback = function()
					local target = targetName and Players:FindFirstChild(targetName)
					if target and Features.TeleportTo(target) then
						Nexzan.Notify("Teleport", "Berpindah ke " .. target.DisplayName, "map-pin")
					else
						Nexzan.Notify("Teleport", "Target tidak tersedia", "triangle-alert")
					end
				end,
			})
			C.Button(teleport, {
				Title = "Spectate",
				Icon = "eye",
				LayoutOrder = 12,
				Callback = function()
					local target = targetName and Players:FindFirstChild(targetName)
					if Features.State.Spectating then
						Features.Spectate(nil)
						Nexzan.Notify("Spectate", "Berhenti menonton", "eye-off")
					elseif target then
						Features.Spectate(target)
						Nexzan.Notify("Spectate", "Menonton " .. target.DisplayName, "eye")
					end
				end,
			})
			C.Button(teleport, {
				Title = "Copy Username",
				Icon = "copy",
				LayoutOrder = 13,
				Callback = function()
					local name = targetName or LocalPlayer.Name
					Util.Clipboard(name)
					Nexzan.Notify("Copied", name, "clipboard-check")
				end,
			})
			C.Button(teleport, {
				Title = "Copy UserId",
				Icon = "hash",
				LayoutOrder = 14,
				Callback = function()
					local target = targetName and Players:FindFirstChild(targetName) or LocalPlayer
					Util.Clipboard(tostring(target.UserId))
					Nexzan.Notify("Copied", tostring(target.UserId), "clipboard-check")
				end,
			})

			C.Section(teleport, "Server", 20)
			C.Button(teleport, {
				Title = "Rejoin",
				Icon = "rotate-cw",
				LayoutOrder = 21,
				Callback = function()
					Nexzan.Notify("Server", "Rejoining...", "rotate-cw")
					Features.Rejoin()
				end,
			})
			C.Button(teleport, {
				Title = "Server Hop",
				Icon = "server",
				LayoutOrder = 22,
				Callback = function()
					local loading = Nexzan.Notifications.Loading("Server Hop", "Mencari server...")
					Features.ServerHop(function(status)
						loading:Update(status)
						if status:find("Tidak ada") or status:find("Gagal") or status:find("tidak valid") then
							loading:Finish(false, status)
						end
					end)
				end,
			})

			--// ---------------- Misc ----------------
			local misc = self:Page("Misc", "info")

			C.Section(misc, "Utility", 1)
			C.Toggle(misc, { Title = "Anti AFK", LayoutOrder = 2, Callback = Features.SetAntiAFK })
			C.Button(misc, {
				Title = "Reset All Modifications",
				Icon = "eraser",
				LayoutOrder = 3,
				Callback = function()
					Features.ResetAll()
					Nexzan.Notify("Reset", "Semua modifikasi dikembalikan ke default", "eraser")
				end,
			})

			C.Section(misc, "Player Information", 10)
			liveInfo.username = C.Info(misc, { Title = "Username", Value = LocalPlayer.Name, LayoutOrder = 11, Copyable = true })
			liveInfo.display = C.Info(misc, { Title = "DisplayName", Value = LocalPlayer.DisplayName, LayoutOrder = 12 })
			liveInfo.userid = C.Info(misc, { Title = "UserId", Value = LocalPlayer.UserId, LayoutOrder = 13, Copyable = true })
			liveInfo.age = C.Info(misc, { Title = "Account Age", Value = LocalPlayer.AccountAge .. " days", LayoutOrder = 14 })
			liveInfo.team = C.Info(misc, { Title = "Team", Value = LocalPlayer.Team and LocalPlayer.Team.Name or "None", LayoutOrder = 15 })

			C.Section(misc, "Character Information", 20)
			liveInfo.health = C.Info(misc, { Title = "Health", Value = "-", LayoutOrder = 21 })
			liveInfo.speed = C.Info(misc, { Title = "WalkSpeed", Value = "-", LayoutOrder = 22 })
			liveInfo.jump = C.Info(misc, { Title = "JumpPower", Value = "-", LayoutOrder = 23 })
			liveInfo.position = C.Info(misc, { Title = "Position", Value = "-", LayoutOrder = 24 })

			C.Section(misc, "Executor & Device", 30)
			C.Info(misc, { Title = "Executor", Value = Util.Executor(), LayoutOrder = 31, Copyable = true })
			C.Info(misc, { Title = "Device", Value = Util.Device(), LayoutOrder = 32 })
			C.Info(misc, { Title = "Platform", Value = Util.IsMobile and "Touch" or "Keyboard + Mouse", LayoutOrder = 33 })
			liveInfo.region = C.Info(misc, { Title = "Server Region", Value = Util.Region(), LayoutOrder = 34 })

			self:SelectPage("Movement")
		end,

		OnOpen = function(self)
			Util.DetectRegion()
			if targetDropdown then
				targetDropdown:SetValues(playerNames(true))
			end
			-- Info live hanya berjalan saat panel terbuka (hemat resource).
			Util.Scheduler.Add("nexzan_players_info", 0.5, function()
				local hum = Util.Char.Humanoid()
				local root = Util.Char.Root()
				if liveInfo.health then
					liveInfo.health:Set(hum and string.format("%d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "-")
				end
				if liveInfo.speed then
					liveInfo.speed:Set(hum and tostring(math.floor(hum.WalkSpeed)) or "-")
				end
				if liveInfo.jump then
					liveInfo.jump:Set(hum and tostring(math.floor(hum.UseJumpPower and hum.JumpPower or hum.JumpHeight)) or "-")
				end
				if liveInfo.position and root then
					local p = root.Position
					liveInfo.position:Set(string.format("%d, %d, %d", p.X, p.Y, p.Z))
				end
				if liveInfo.team then
					liveInfo.team:Set(LocalPlayer.Team and LocalPlayer.Team.Name or "None")
				end
				if liveInfo.region then
					liveInfo.region:Set(Util.Region())
				end
			end)
		end,

		OnClose = function()
			Util.Scheduler.Remove("nexzan_players_info")
		end,
	})

	ctx.Panels.Players = panel
	return panel
end

--// ==========================================================================
--//  8. THEMES TAMBAHAN — didaftarkan lewat WindUI:AddTheme (API resmi)
--//     Tidak mengubah struktur theme; hanya menambah entri baru.
--// ==========================================================================

local Themes = {}

Themes.List = {
	{
		Name = "Purple",
		Accent = Color3.fromHex("#2b1b45"),
		Dialog = Color3.fromHex("#241638"),
		Outline = Color3.fromHex("#c4b5fd"),
		Text = Color3.fromHex("#f5f3ff"),
		Placeholder = Color3.fromHex("#a78bfa"),
		Background = Color3.fromHex("#150c22"),
		Button = Color3.fromHex("#8b5cf6"),
		Icon = Color3.fromHex("#c4b5fd"),
		Toggle = Color3.fromHex("#a855f7"),
		Slider = Color3.fromHex("#8b5cf6"),
		Primary = Color3.fromHex("#a855f7"),
		ElementBackground = Color3.fromHex("#2e2043"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "Blue",
		Accent = Color3.fromHex("#132741"),
		Dialog = Color3.fromHex("#0f2036"),
		Outline = Color3.fromHex("#bfdbfe"),
		Text = Color3.fromHex("#eff6ff"),
		Placeholder = Color3.fromHex("#7dabe0"),
		Background = Color3.fromHex("#0a1524"),
		Button = Color3.fromHex("#3b82f6"),
		Icon = Color3.fromHex("#93c5fd"),
		Toggle = Color3.fromHex("#38bdf8"),
		Slider = Color3.fromHex("#3b82f6"),
		Primary = Color3.fromHex("#3b82f6"),
		ElementBackground = Color3.fromHex("#1b3050"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "BloodMoon",
		Accent = Color3.fromHex("#3a0d10"),
		Dialog = Color3.fromHex("#2a0709"),
		Outline = Color3.fromHex("#fca5a5"),
		Text = Color3.fromHex("#fff1f2"),
		Placeholder = Color3.fromHex("#e26f6f"),
		Background = Color3.fromHex("#170305"),
		Button = Color3.fromHex("#dc2626"),
		Icon = Color3.fromHex("#f87171"),
		Toggle = Color3.fromHex("#ef4444"),
		Slider = Color3.fromHex("#b91c1c"),
		Primary = Color3.fromHex("#ef4444"),
		ElementBackground = Color3.fromHex("#3d1416"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "Glass",
		Accent = Color3.fromHex("#20232a"),
		Dialog = Color3.fromHex("#1b1e24"),
		Outline = Color3.fromHex("#ffffff"),
		Text = Color3.fromHex("#f8fafc"),
		Placeholder = Color3.fromHex("#b9c0cc"),
		Background = Color3.fromHex("#14171c"),
		Button = Color3.fromHex("#94a3b8"),
		Icon = Color3.fromHex("#cbd5e1"),
		Toggle = Color3.fromHex("#22d3ee"),
		Slider = Color3.fromHex("#60a5fa"),
		Primary = Color3.fromHex("#38bdf8"),
		PanelBackground = Color3.fromHex("#ffffff"),
		PanelBackgroundTransparency = 0.9,
		ElementBackground = Color3.fromHex("#ffffff"),
		ElementBackgroundTransparency = 0.9,
	},
	{
		Name = "Discord",
		Accent = Color3.fromHex("#2b2d31"),
		Dialog = Color3.fromHex("#313338"),
		Outline = Color3.fromHex("#dbdee1"),
		Text = Color3.fromHex("#f2f3f5"),
		Placeholder = Color3.fromHex("#949ba4"),
		Background = Color3.fromHex("#1e1f22"),
		Button = Color3.fromHex("#5865f2"),
		Icon = Color3.fromHex("#b5bac1"),
		Toggle = Color3.fromHex("#23a55a"),
		Slider = Color3.fromHex("#5865f2"),
		Primary = Color3.fromHex("#5865f2"),
		ElementBackground = Color3.fromHex("#383a40"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "Midnight",
		Accent = Color3.fromHex("#161b2e"),
		Dialog = Color3.fromHex("#111527"),
		Outline = Color3.fromHex("#c7d2fe"),
		Text = Color3.fromHex("#e8ecff"),
		Placeholder = Color3.fromHex("#8b93b8"),
		Background = Color3.fromHex("#0b0e1a"),
		Button = Color3.fromHex("#4f46e5"),
		Icon = Color3.fromHex("#a5b4fc"),
		Toggle = Color3.fromHex("#6366f1"),
		Slider = Color3.fromHex("#4f46e5"),
		Primary = Color3.fromHex("#6366f1"),
		ElementBackground = Color3.fromHex("#1d2338"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "Cyber",
		Accent = Color3.fromHex("#12232b"),
		Dialog = Color3.fromHex("#0d1a20"),
		Outline = Color3.fromHex("#5eead4"),
		Text = Color3.fromHex("#ecfeff"),
		Placeholder = Color3.fromHex("#5f9ea6"),
		Background = Color3.fromHex("#071216"),
		Button = Color3.fromHex("#06b6d4"),
		Icon = Color3.fromHex("#22d3ee"),
		Toggle = Color3.fromHex("#14f195"),
		Slider = Color3.fromHex("#06b6d4"),
		Primary = Color3.fromHex("#22d3ee"),
		ElementBackground = Color3.fromHex("#153039"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "Ocean",
		Accent = Color3.fromHex("#0e3746"),
		Dialog = Color3.fromHex("#0a2b37"),
		Outline = Color3.fromHex("#a5f3fc"),
		Text = Color3.fromHex("#f0fdff"),
		Placeholder = Color3.fromHex("#6aa8b8"),
		Background = Color3.fromHex("#061c25"),
		Button = Color3.fromHex("#0ea5e9"),
		Icon = Color3.fromHex("#67e8f9"),
		Toggle = Color3.fromHex("#2dd4bf"),
		Slider = Color3.fromHex("#0ea5e9"),
		Primary = Color3.fromHex("#0ea5e9"),
		ElementBackground = Color3.fromHex("#12414f"),
		ElementBackgroundTransparency = 0,
	},
	{
		Name = "Galaxy",
		Accent = Color3.fromHex("#251a3d"),
		Dialog = Color3.fromHex("#1c1330"),
		Outline = Color3.fromHex("#e9d5ff"),
		Text = Color3.fromHex("#faf5ff"),
		Placeholder = Color3.fromHex("#a394c7"),
		Background = Color3.fromHex("#0f0a1c"),
		Button = Color3.fromHex("#7c3aed"),
		Icon = Color3.fromHex("#d8b4fe"),
		Toggle = Color3.fromHex("#e879f9"),
		Slider = Color3.fromHex("#c026d3"),
		Primary = Color3.fromHex("#a855f7"),
		ElementBackground = Color3.fromHex("#2b2047"),
		ElementBackgroundTransparency = 0,
	},
}

function Themes.Register(windui)
	local added = {}
	for _, theme in ipairs(Themes.List) do
		if not windui.Themes[theme.Name] then
			Util.Try(function()
				windui:AddTheme(theme)
			end)
		end
		table.insert(added, theme.Name)
	end
	return added
end

function Themes.AllNames(windui)
	local names = {}
	for name in pairs(windui:GetThemes() or {}) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--// ==========================================================================
--//  9. SETTINGS PANEL — Background, UI, Theme
--// ==========================================================================

local SettingsPanel = {}

local SETTINGS_FILE = NEXZAN_FOLDER .. "/settings.json"

local Settings = {
	data = {
		BackgroundUrl = "",
		BackgroundOpacity = 0,
		Brightness = 0,
		Blur = 0,
		Scale = 100,
		WindowTransparency = 0,
		Theme = nil,
		Watermark = false,
		AutoFit = true,
		BackgroundScale = "Crop",
		BackgroundPosition = "Center",
		BackgroundRepeat = false,
		Shadow = 0.6,
		Outline = true,
	},
}
SettingsPanel.Store = Settings

function Settings.Save()
	Util.File.WriteJSON(SETTINGS_FILE, Settings.data)
end

function Settings.Load()
	local data = Util.File.ReadJSON(SETTINGS_FILE)
	if type(data) == "table" then
		for k, v in pairs(data) do
			Settings.data[k] = v
		end
	end
	return Settings.data
end

function SettingsPanel.Init(ctx)
	local C = Kit.Controls
	local Window = ctx.Window
	local previewImage

	--// ---- helper: layer background milik Nexzan (tidak mengubah milik WindUI) ----
	local function ensureBackgroundImage()
		if previewImage and previewImage.Parent then
			return previewImage
		end
		local bg = Util.Get(Window, "UIElements", "Main", "Background")
		if not bg then
			return nil
		end
		previewImage = Creator.New("ImageLabel", {
			Name = "NexzanBackground",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ScaleType = "Crop",
			ZIndex = 0,
			Parent = bg,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, Window.UICorner or 16) }),
		})
		Util.Bin.Track(previewImage)
		return previewImage
	end

	local function applyBackground(url, notify)
		local image = ensureBackgroundImage()
		if not image then
			return false
		end
		if not url or url == "" then
			image.Image = ""
			image.ImageTransparency = 1
			return false
		end

		local assetUrl = url
		if url:match("^%d+$") then
			assetUrl = "rbxassetid://" .. url
		elseif url:match("^https?://") and Util.File.Enabled and getcustomasset then
			-- download → getcustomasset (mendukung Raw Image URL apa pun)
			local ext = url:match("%.jpe?g") and ".jpg" or ".png"
			local safe = Creator.SanitizeFilename and Creator.SanitizeFilename(url) or tostring(#url)
			local path = NEXZAN_FOLDER .. "/bg_" .. safe .. ext
			Util.File.Ensure(NEXZAN_FOLDER)
			if not isfile(path) then
				local ok, body = pcall(function()
					return game:HttpGet(url)
				end)
				if ok and body then
					Util.Try(writefile, path, body)
				end
			end
			if isfile(path) then
				local ok, asset = pcall(getcustomasset, path)
				if ok then
					assetUrl = asset
				end
			end
		end

		image.Image = assetUrl
		image.ImageTransparency = 1 - (Settings.data.BackgroundOpacity / 100)
		Settings.data.BackgroundUrl = url
		Settings.Save()
		if notify then
			Nexzan.Notify("Background", "Background diterapkan", "image")
		end
		return true
	end

	local function applyOpacity(v)
		Settings.data.BackgroundOpacity = v
		local image = ensureBackgroundImage()
		if image then
			image.ImageTransparency = 1 - (v / 100)
		end
	end

	local function applyBrightness(v)
		Settings.data.Brightness = v
		local main = Util.Get(Window, "UIElements", "Main")
		if not main then
			return
		end
		local overlay = main:FindFirstChild("NexzanBrightness")
		if not overlay then
			overlay = Kit.Card(Window.UICorner or 16, {
				Name = "NexzanBrightness",
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ImageColor3 = Color3.new(1, 1, 1),
				ImageTransparency = 1,
				ZIndex = 96,
				Parent = main,
			})
			Util.Bin.Track(overlay)
		end
		if v >= 0 then
			overlay.ImageColor3 = Color3.new(1, 1, 1)
			overlay.ImageTransparency = 1 - (v / 100) * 0.5
		else
			overlay.ImageColor3 = Color3.new(0, 0, 0)
			overlay.ImageTransparency = 1 - (math.abs(v) / 100) * 0.6
		end
	end

	local function applyBlur(v)
		Settings.data.Blur = v
		-- Blur belakang window (Lighting), aman & reversible.
		local blur = Lighting:FindFirstChild("NexzanBlur")
		if v <= 0 then
			if blur then
				blur:Destroy()
			end
			return
		end
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "NexzanBlur"
			blur.Parent = Lighting
			Util.Bin.Track(blur)
		end
		blur.Size = v
	end

	local function applyScale(percent)
		Settings.data.Scale = percent
		Util.Try(function()
			Window:SetUIScale(percent / 100)
		end)
	end

	local function applyWindowTransparency(v)
		Settings.data.WindowTransparency = v
		Util.Try(function()
			Window:SetBackgroundTransparency(v / 100)
		end)
	end

	local function applyShadow(v)
		Settings.data.Shadow = v
		local blur = Util.Get(Window, "UIElements", "Main", "Blur")
		if blur then
			Kit.Anim(blur, 0.15, { ImageTransparency = 1 - (v / 100) })
		end
	end

	local function applyOutline(enabled)
		Settings.data.Outline = enabled
		local main = Util.Get(Window, "UIElements", "Main", "Main")
		if not main then
			return
		end
		for _, child in ipairs(main:GetDescendants()) do
			if child.Name == "Outline" and child:IsA("ImageLabel") then
				Kit.Anim(child, 0.15, { ImageTransparency = enabled and 0.75 or 1 })
			end
		end
	end

	local urlInput

	local panel = Panel.new(ctx, {
		Id = "Settings",
		Title = "Settings",
		Icon = "settings",
		Width = 330,
		MaxHeight = 400,
		Tabs = true,

		Build = function(self)
			--// ---------------- Background ----------------
			local bg = self:Page("Background", "image")

			C.Section(bg, "Source", 1)
			urlInput = C.Input(bg, {
				Placeholder = "Raw Image URL / rbxassetid",
				Value = Settings.data.BackgroundUrl,
				LayoutOrder = 2,
			})
			C.Button(bg, {
				Title = "Preview",
				Icon = "eye",
				LayoutOrder = 3,
				Callback = function()
					applyBackground(urlInput.Value, false)
					Nexzan.Notify("Background", "Preview ditampilkan", "eye")
				end,
			})
			C.Button(bg, {
				Title = "Apply",
				Icon = "check",
				LayoutOrder = 4,
				Callback = function()
					applyBackground(urlInput.Value, true)
				end,
			})
			C.Button(bg, {
				Title = "Remove",
				Icon = "trash-2",
				LayoutOrder = 5,
				Callback = function()
					applyBackground("", false)
					urlInput:Set("", true)
					Settings.data.BackgroundUrl = ""
					Settings.Save()
					Nexzan.Notify("Background", "Background dihapus", "trash-2")
				end,
			})
			C.Button(bg, {
				Title = "Reset",
				Icon = "rotate-ccw",
				LayoutOrder = 6,
				Callback = function()
					applyBackground("", false)
					applyOpacity(0)
					applyBrightness(0)
					applyBlur(0)
					urlInput:Set("", true)
					Settings.data.BackgroundUrl = ""
					Settings.Save()
					Nexzan.Notify("Background", "Pengaturan background direset", "rotate-ccw")
				end,
			})

			C.Section(bg, "Adjustment", 10)
			C.Slider(bg, {
				Title = "Opacity",
				Min = 0,
				Max = 100,
				Suffix = "%",
				Value = Settings.data.BackgroundOpacity,
				LayoutOrder = 11,
				Callback = function(v)
					applyOpacity(v)
					Settings.Save()
				end,
			})
			C.Slider(bg, {
				Title = "Brightness",
				Min = -100,
				Max = 100,
				Value = Settings.data.Brightness,
				LayoutOrder = 12,
				Callback = function(v)
					applyBrightness(v)
					Settings.Save()
				end,
			})
			C.Slider(bg, {
				Title = "Blur",
				Min = 0,
				Max = 40,
				Value = Settings.data.Blur,
				LayoutOrder = 13,
				Callback = function(v)
					applyBlur(v)
					Settings.Save()
				end,
			})

			C.Section(bg, "Layout", 20)
			C.Toggle(bg, {
				Title = "Auto Fit",
				Value = Settings.data.AutoFit,
				LayoutOrder = 21,
				Callback = function(v)
					Settings.data.AutoFit = v
					local image = ensureBackgroundImage()
					if image then
						image.ScaleType = v and Enum.ScaleType.Crop or Enum.ScaleType.Stretch
					end
					Settings.Save()
				end,
			})
			C.Dropdown(bg, {
				Title = "Background Scale",
				Values = { "Crop", "Stretch", "Fit", "Tile" },
				Value = Settings.data.BackgroundScale,
				LayoutOrder = 22,
				Callback = function(v)
					Settings.data.BackgroundScale = v
					local image = ensureBackgroundImage()
					if image then
						local map = {
							Crop = Enum.ScaleType.Crop,
							Stretch = Enum.ScaleType.Stretch,
							Fit = Enum.ScaleType.Fit,
							Tile = Enum.ScaleType.Tile,
						}
						image.ScaleType = map[v] or Enum.ScaleType.Crop
						if v == "Tile" then
							image.TileSize = UDim2.new(0.5, 0, 0.5, 0)
						end
					end
					Settings.Save()
				end,
			})
			C.Dropdown(bg, {
				Title = "Background Position",
				Values = { "Center", "Top", "Bottom", "Left", "Right" },
				Value = Settings.data.BackgroundPosition,
				LayoutOrder = 23,
				Callback = function(v)
					Settings.data.BackgroundPosition = v
					local image = ensureBackgroundImage()
					if image then
						local map = {
							Center = { Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0) },
							Top = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 0) },
							Bottom = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, 0) },
							Left = { Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0) },
							Right = { Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0) },
						}
						local entry = map[v] or map.Center
						image.AnchorPoint = entry[1]
						image.Position = entry[2]
					end
					Settings.Save()
				end,
			})
			C.Toggle(bg, {
				Title = "Background Repeat",
				Value = Settings.data.BackgroundRepeat,
				LayoutOrder = 24,
				Callback = function(v)
					Settings.data.BackgroundRepeat = v
					local image = ensureBackgroundImage()
					if image then
						image.ScaleType = v and Enum.ScaleType.Tile or Enum.ScaleType.Crop
						image.TileSize = UDim2.new(0.5, 0, 0.5, 0)
					end
					Settings.Save()
				end,
			})

			--// ---------------- UI ----------------
			local ui = self:Page("UI", "layout-dashboard")

			C.Section(ui, "Scale", 1)
			local scaleSlider = C.Slider(ui, {
				Title = "UI Scale",
				Min = 60,
				Max = 160,
				Suffix = "%",
				Value = Settings.data.Scale,
				LayoutOrder = 2,
				Callback = function(v)
					applyScale(v)
					Settings.Save()
				end,
			})
			C.Dropdown(ui, {
				Title = "Preset",
				Values = { "75%", "80%", "90%", "100%", "110%", "120%", "130%", "150%" },
				Value = tostring(math.floor(Settings.data.Scale)) .. "%",
				LayoutOrder = 3,
				Callback = function(v)
					local percent = tonumber((v:gsub("%%", ""))) or 100
					applyScale(percent)
					scaleSlider:Set(percent, true)
					Settings.Save()
				end,
			})

			C.Section(ui, "Appearance", 10)
			C.Slider(ui, {
				Title = "Window Transparency",
				Min = 0,
				Max = 90,
				Suffix = "%",
				Value = Settings.data.WindowTransparency,
				LayoutOrder = 11,
				Callback = function(v)
					applyWindowTransparency(v)
					Settings.Save()
				end,
			})
			C.Slider(ui, {
				Title = "Corner Radius",
				Min = 0,
				Max = 28,
				Value = Window.UICorner or 16,
				LayoutOrder = 12,
				Callback = function(v)
					local main = Util.Get(Window, "UIElements", "Main")
					if main then
						for _, child in ipairs(main:GetDescendants()) do
							if child:IsA("UICorner") then
								child.CornerRadius = UDim.new(0, v)
							end
						end
					end
				end,
			})
			C.Slider(ui, {
				Title = "Shadow",
				Min = 0,
				Max = 100,
				Suffix = "%",
				Value = math.floor((1 - (Window.ShadowTransparency or 0.6)) * 100),
				LayoutOrder = 13,
				Callback = function(v)
					applyShadow(v)
					Settings.Save()
				end,
			})
			C.Toggle(ui, {
				Title = "Outline",
				Value = Settings.data.Outline,
				LayoutOrder = 14,
				Callback = function(v)
					applyOutline(v)
					Settings.Save()
				end,
			})
			C.Slider(ui, {
				Title = "Blur (Background)",
				Min = 0,
				Max = 40,
				Value = Settings.data.Blur,
				LayoutOrder = 15,
				Callback = function(v)
					applyBlur(v)
					Settings.Save()
				end,
			})

			C.Section(ui, "Colors (Live Theme)", 20)
			local function colorRow(title, key, order)
				C.Input(ui, {
					Title = title,
					Placeholder = "#RRGGBB",
					LayoutOrder = order,
					Callback = function(text)
						local hex = tostring(text):gsub("%s", "")
						if not hex:match("^#?%x%x%x%x%x%x$") then
							if hex ~= "" then
								Nexzan.Notify("Theme", "Format warna tidak valid (#RRGGBB)", "triangle-alert")
							end
							return
						end
						if hex:sub(1, 1) ~= "#" then
							hex = "#" .. hex
						end
						local theme = Creator.Theme
						if theme then
							theme[key] = Color3.fromHex(hex)
							Util.Try(function()
								Creator.SetTheme(theme)
							end)
							Nexzan.Notify("Theme", title .. " diperbarui", "palette")
						end
					end,
				})
			end
			colorRow("Accent Color", "Accent", 21)
			colorRow("Primary Color", "Primary", 22)
			colorRow("Secondary Color", "Button", 23)
			colorRow("Text Color", "Text", 24)

			C.Section(ui, "Watermark", 30)
			C.Toggle(ui, {
				Title = "Show Watermark",
				Value = Settings.data.Watermark,
				LayoutOrder = 31,
				Callback = function(v)
					Settings.data.Watermark = v
					Settings.Save()
					Nexzan.Watermark.Set(v)
				end,
			})

			--// ---------------- Theme ----------------
			local themePage = self:Page("Theme", "palette")

			C.Section(themePage, "Nexzan Themes", 1)
			local order = 2
			local themeButtons = {}
			local function themeRow(name)
				local btn = C.Button(themePage, {
					Title = name,
					Icon = "swatch-book",
					LayoutOrder = order,
					Callback = function()
						local ok = Util.Try(function()
							ctx.WindUI:SetTheme(name)
						end)
						if ok then
							Settings.data.Theme = name
							Settings.Save()
							Nexzan.Notify("Theme", "Theme diganti ke " .. name, "palette")
							for otherName, other in pairs(themeButtons) do
								other:SetTitle(otherName == name and (name .. "  •") or otherName)
							end
						end
					end,
				})
				themeButtons[name] = btn
				order += 1
			end

			for _, name in ipairs({
				"Dark",
				"Light",
				"Purple",
				"Blue",
				"BloodMoon",
				"Glass",
				"Discord",
				"Midnight",
				"Cyber",
				"Ocean",
				"Galaxy",
			}) do
				if ctx.WindUI.Themes[name] then
					themeRow(name)
				end
			end

			C.Section(themePage, "Built-in WindUI Themes", 100)
			order = 101
			for _, name in ipairs(Themes.AllNames(ctx.WindUI)) do
				if not themeButtons[name] then
					themeRow(name)
				end
			end

			self:SelectPage("Background")
		end,
	})

	--// Restore setelah panel dibuat (tanpa membuka panel).
	task.defer(function()
		Settings.Load()
		if Settings.data.Scale and Settings.data.Scale ~= 100 then
			applyScale(Settings.data.Scale)
		end
		if Settings.data.BackgroundUrl ~= "" then
			applyBackground(Settings.data.BackgroundUrl, false)
			applyOpacity(Settings.data.BackgroundOpacity)
		end
		if (Settings.data.Brightness or 0) ~= 0 then
			applyBrightness(Settings.data.Brightness)
		end
		if (Settings.data.Blur or 0) > 0 then
			applyBlur(Settings.data.Blur)
		end
		if Settings.data.Theme and ctx.WindUI.Themes[Settings.data.Theme] then
			Util.Try(function()
				ctx.WindUI:SetTheme(Settings.data.Theme)
			end)
		end
	end)

	ctx.Panels.Settings = panel
	ctx.Settings = Settings
	return panel
end

--// ==========================================================================
--//  10. WATERMARK — modern, dapat di-drag, ON/OFF, konten lengkap
--// ==========================================================================

local Watermark = {
	Enabled = false,
	Fields = {
		FPS = true,
		Ping = true,
		Time = true,
		Date = false,
		PlayerCount = true,
		GameName = false,
		PlaceId = false,
		JobId = false,
		Executor = true,
		Device = false,
		Region = false,
		Memory = true,
		Network = false,
		Username = true,
		DisplayName = false,
	},
}

local wmGui, wmFrame, wmLabel, wmIcon

local function buildWatermark(ctx)
	if wmFrame and wmFrame.Parent then
		return
	end

	local parent = (gethui and gethui())
		or (WindUI.ScreenGui and WindUI.ScreenGui.Parent)
		or LocalPlayer:WaitForChild("PlayerGui")

	wmGui = Creator.New("ScreenGui", {
		Name = "NexzanWatermark",
		Parent = parent,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = -99997,
	})
	Util.Bin.Track(wmGui)

	wmIcon = Kit.IconImage("zap", 14, "Icon", {
		Position = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageTransparency = 0.05,
		ZIndex = 3,
	})

	wmLabel = Kit.Label("", 13, "Medium", "Text", {
		Position = UDim2.new(0, 32, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -44, 1, 0),
		AutomaticSize = "None",
		TextTransparency = 0.05,
		ZIndex = 3,
	})

	wmFrame = Kit.Card(12, {
		Size = UDim2.new(0, 320, 0, 34),
		Position = UDim2.new(0, 14, 0, 14),
		ThemeTag = { ImageColor3 = "Dialog" },
		ImageTransparency = 0.05,
		Visible = false,
		Parent = wmGui,
		ZIndex = 2,
	}, {
		Kit.Outline(12, { ImageTransparency = 0.86, ZIndex = 2 }),
		wmIcon,
		wmLabel,
		Creator.New("UIScale", { Scale = 1 }),
	})

end

local function watermarkText(ctx)
	local f = Watermark.Fields
	local parts = { string.format("<b>%s</b>", NEXZAN_NAME) }

	if f.FPS then
		table.insert(parts, string.format("%d FPS", Util.FPS.value))
	end
	if f.Ping then
		table.insert(parts, string.format("%d ms", Util.PingMs()))
	end
	if f.Memory then
		table.insert(parts, string.format("%d MB", Util.Memory()))
	end
	if f.Network then
		table.insert(parts, string.format("%d kb/s", Util.NetworkKbps()))
	end
	if f.PlayerCount then
		table.insert(parts, string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers))
	end
	if f.Username then
		table.insert(parts, LocalPlayer.Name)
	end
	if f.DisplayName then
		table.insert(parts, LocalPlayer.DisplayName)
	end
	if f.Executor then
		table.insert(parts, Util.Executor())
	end
	if f.Device then
		table.insert(parts, Util.Device())
	end
	if f.GameName then
		table.insert(parts, Util.Truncate(ctx.GameName or "Game", 22))
	end
	if f.PlaceId then
		table.insert(parts, "P:" .. tostring(game.PlaceId))
	end
	if f.JobId then
		table.insert(parts, "J:" .. tostring(game.JobId):sub(1, 8))
	end
	if f.Region then
		table.insert(parts, Util.Region())
	end
	if f.Time then
		table.insert(parts, Util.TimeString())
	end
	if f.Date then
		table.insert(parts, Util.DateString())
	end

	return table.concat(parts, "  │  ")
end

function Watermark.Init(ctx)
	Watermark.ctx = ctx

	function Watermark.Set(enabled)
		Watermark.Enabled = enabled and true or false
		if Watermark.Enabled then
			buildWatermark(ctx)
			wmFrame.Visible = true
			wmFrame.ImageTransparency = 1
			Kit.Anim(wmFrame, 0.22, { ImageTransparency = 0.05 })
			Util.Scheduler.Add("nexzan_watermark", 0.5, function()
				if not wmLabel then
					return
				end
				local text = watermarkText(ctx)
				wmLabel.Text = text
				-- Auto width mengikuti isi (tanpa AutomaticSize agar drag tetap stabil)
				local bounds = TextService:GetTextSize(
					text:gsub("<[^>]->", ""),
					wmLabel.TextSize,
					Enum.Font.Gotham,
					Vector2.new(9999, 100)
				)
				wmFrame.Size = UDim2.new(0, math.clamp(bounds.X + 52, 180, 720), 0, 34)
			end)
		else
			Util.Scheduler.Remove("nexzan_watermark")
			if wmFrame then
				Kit.Anim(wmFrame, 0.18, { ImageTransparency = 1 })
				task.delay(0.2, function()
					if not Watermark.Enabled and wmFrame then
						wmFrame.Visible = false
					end
				end)
			end
		end
		return Watermark.Enabled
	end

	function Watermark.Toggle()
		return Watermark.Set(not Watermark.Enabled)
	end

	function Watermark.SetField(name, value)
		if Watermark.Fields[name] ~= nil then
			Watermark.Fields[name] = value and true or false
		end
		return Watermark.Fields[name]
	end

	return Watermark
end

--// ==========================================================================
--//  11. NOTIFICATION EXTRAS — Progress, Interactive, Button, Queue, Loading
--//      Semua dibangun di atas WindUI:Notify (API resmi, tampilan asli).
--// ==========================================================================

local Notifications = { queue = {}, processing = false }

function Notifications.Init(ctx)
	local windui = ctx.WindUI

	--- Notifikasi biasa (helper singkat).
	function Notifications.Send(title, content, icon, duration)
		return windui:Notify({
			Title = title or NEXZAN_NAME,
			Content = content,
			Icon = icon or "sparkles",
			Duration = duration or 4,
		})
	end

	--- Cari holder notifikasi WindUI untuk menyisipkan progress bar.
	local function notificationHolder()
		local gui = windui.NotificationGui
		if not gui then
			return nil
		end
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("Frame") then
				return child
			end
		end
		return nil
	end

	--- Cari label konten di dalam frame notifikasi (untuk :Update).
	local function findContentLabel(container)
		local labels = {}
		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				table.insert(labels, descendant)
			end
		end
		-- Label pertama = Title, kedua = Content (struktur WindUI).
		return labels[2] or labels[1]
	end

	--- Progress Notification — bar progres di dalam notifikasi WindUI asli.
	function Notifications.Progress(title, content, icon)
		local holder = notificationHolder()
		local captured

		local conn
		if holder then
			conn = holder.ChildAdded:Connect(function(child)
				captured = captured or child
			end)
		end

		local notification = windui:Notify({
			Title = title or "Progress",
			Content = content or "",
			Icon = icon or "loader",
			Duration = nil, -- ditutup manual
		})

		if conn then
			task.defer(function()
				conn:Disconnect()
			end)
		end

		local api = { Notification = notification, Value = 0, Closed = false }
		local fill, contentLabel

		task.defer(function()
			if not captured then
				return
			end
			contentLabel = findContentLabel(captured)

			local frame = captured:FindFirstChildWhichIsA("ImageLabel")
				or captured:FindFirstChildWhichIsA("Frame")
				or captured
			fill = Kit.Card(999, {
				Size = UDim2.new(0, 0, 1, 0),
				ThemeTag = { ImageColor3 = "Slider" },
				ImageTransparency = 0,
				ZIndex = 61,
			})
			Kit.Card(999, {
				Size = UDim2.new(1, -28, 0, 4),
				Position = UDim2.new(0, 14, 1, -10),
				AnchorPoint = Vector2.new(0, 1),
				ThemeTag = { ImageColor3 = "Text" },
				ImageTransparency = 0.85,
				ZIndex = 60,
				ClipsDescendants = true,
				Parent = frame,
			}, { fill })
		end)

		function api:Set(alpha, text)
			api.Value = math.clamp(alpha, 0, 1)
			if fill then
				Kit.Anim(fill, 0.2, { Size = UDim2.new(api.Value, 0, 1, 0) })
			end
			if text then
				api:Update(text)
			end
			return api
		end

		function api:Update(text)
			if contentLabel then
				contentLabel.Text = tostring(text)
			end
			return api
		end

		function api:Close()
			if api.Closed then
				return
			end
			api.Closed = true
			task.spawn(function()
				Util.Try(function()
					notification:Close()
				end)
			end)
		end

		return api
	end

	--- Loading Notification — spinner + auto finish.
	function Notifications.Loading(title, content)
		local api = Notifications.Progress(title, content, "loader-circle")
		local alpha = 0
		local key = "nexzan_loading_" .. tostring(math.random(1, 1e6))

		Util.Scheduler.Add(key, 0.1, function()
			if api.Closed then
				Util.Scheduler.Remove(key)
				return
			end
			alpha = math.min(alpha + 0.02, 0.92)
			api:Set(alpha)
		end)

		function api:Finish(success, text)
			Util.Scheduler.Remove(key)
			api:Set(1, text)
			task.delay(0.8, function()
				api:Close()
				Notifications.Send(
					success ~= false and "Selesai" or "Gagal",
					text or (success ~= false and "Operasi berhasil" or "Operasi gagal"),
					success ~= false and "circle-check" or "circle-x",
					3
				)
			end)
		end

		return api
	end

	--- Interactive / Button Notification — memakai Buttons bawaan WindUI.
	function Notifications.Interactive(cfg)
		return windui:Notify({
			Title = cfg.Title or NEXZAN_NAME,
			Content = cfg.Content,
			Icon = cfg.Icon or "message-square",
			Duration = cfg.Duration or 8,
			Buttons = cfg.Buttons or {},
		})
	end

	function Notifications.Button(title, content, buttonTitle, callback)
		return Notifications.Interactive({
			Title = title,
			Content = content,
			Buttons = {
				{
					Title = buttonTitle or "OK",
					Variant = "Primary",
					Callback = callback,
				},
			},
		})
	end

	function Notifications.Confirm(title, content, onAccept, onDecline)
		return Notifications.Interactive({
			Title = title,
			Content = content,
			Icon = "circle-help",
			Duration = 15,
			Buttons = {
				{ Title = "Batal", Variant = "Secondary", Callback = onDecline },
				{ Title = "Lanjut", Variant = "Primary", Callback = onAccept },
			},
		})
	end

	--- Queue Notification — antre satu per satu, tidak menumpuk layar.
	local function processQueue()
		if Notifications.processing then
			return
		end
		Notifications.processing = true
		task.spawn(function()
			while #Notifications.queue > 0 do
				local item = table.remove(Notifications.queue, 1)
				Notifications.Send(item.Title, item.Content, item.Icon, item.Duration)
				task.wait((item.Duration or 3) * 0.55)
			end
			Notifications.processing = false
		end)
	end

	function Notifications.Queue(title, content, icon, duration)
		table.insert(Notifications.queue, {
			Title = title,
			Content = content,
			Icon = icon,
			Duration = duration or 3,
		})
		processQueue()
	end

	function Notifications.ClearQueue()
		table.clear(Notifications.queue)
	end

	return Notifications
end

--// ==========================================================================
--//  12. WINDOW ENHANCEMENTS
--//      Resize (PC), Smooth Drag, Snap, Remember Position/Size, Auto Save
--//      Semua bekerja di atas Window.UIElements.Main tanpa mengubah API.
--// ==========================================================================

local WindowExtra = {}

local LAYOUT_FILE = NEXZAN_FOLDER .. "/layout.json"

function WindowExtra.Init(ctx)
	local Window = ctx.Window
	local main = Window.UIElements and Window.UIElements.Main
	if not main then
		return WindowExtra
	end

	local layout = Util.File.ReadJSON(LAYOUT_FILE) or {}
	local saveDebounce = false

	local function saveLayout()
		if saveDebounce or not ctx.Options.RememberWindow then
			return
		end
		saveDebounce = true
		task.delay(0.75, function()
			saveDebounce = false
			Util.File.WriteJSON(LAYOUT_FILE, {
				PosX = main.Position.X.Offset,
				PosY = main.Position.Y.Offset,
				PosXS = main.Position.X.Scale,
				PosYS = main.Position.Y.Scale,
				SizeX = main.Size.X.Offset,
				SizeY = main.Size.Y.Offset,
			})
		end)
	end
	WindowExtra.Save = saveLayout

	--// ---- Remember Position & Size ----
	if ctx.Options.RememberWindow and layout.SizeX then
		task.delay(0.9, function()
			Util.Try(function()
				local minSize = Window.MinSize or Vector2.new(560, 350)
				local maxSize = Window.MaxSize or Vector2.new(850, 560)
				main.Size = UDim2.new(
					0,
					math.clamp(layout.SizeX, minSize.X, maxSize.X),
					0,
					math.clamp(layout.SizeY, minSize.Y, maxSize.Y)
				)
				main.Position =
					UDim2.new(layout.PosXS or 0.5, layout.PosX or 0, layout.PosYS or 0.5, layout.PosY or 0)
			end)
		end)
	end

	--// ---- Auto save saat posisi/ukuran berubah ----
	Util.Bin.Connect(main:GetPropertyChangedSignal("Position"), saveLayout)
	Util.Bin.Connect(main:GetPropertyChangedSignal("Size"), saveLayout)

	--// ---- Snap Position ----
	local snapGuide
	local function ensureGuide()
		if snapGuide and snapGuide.Parent then
			return snapGuide
		end
		snapGuide = Kit.Card(Window.UICorner or 16, {
			Size = UDim2.new(1, 8, 1, 8),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ThemeTag = { ImageColor3 = "Primary" },
			ImageTransparency = 1,
			ZIndex = 90,
			Parent = main,
		})
		Util.Bin.Track(snapGuide)
		return snapGuide
	end

	local SNAP_THRESHOLD = 26

	local function applySnap()
		if not ctx.Options.SnapPosition then
			return
		end
		local screen = WindUI.ScreenGui
		if not screen then
			return
		end
		local viewport = screen.AbsoluteSize
		local scale = WindUI.UIScale or 1
		local size = main.AbsoluteSize
		local pos = main.AbsolutePosition

		local left = pos.X
		local top = pos.Y
		local right = viewport.X - (pos.X + size.X)
		local bottom = viewport.Y - (pos.Y + size.Y)

		local newX, newY = nil, nil
		if left < SNAP_THRESHOLD then
			newX = (size.X / 2 + 10) / scale
		elseif right < SNAP_THRESHOLD then
			newX = (viewport.X - size.X / 2 - 10) / scale
		end
		if top < SNAP_THRESHOLD then
			newY = (size.Y / 2 + 10) / scale
		elseif bottom < SNAP_THRESHOLD then
			newY = (viewport.Y - size.Y / 2 - 10) / scale
		end

		if newX or newY then
			local target = UDim2.new(
				0,
				newX or (pos.X + size.X / 2) / scale,
				0,
				newY or (pos.Y + size.Y / 2) / scale
			)
			Kit.Anim(main, 0.22, { Position = target })
			local guide = ensureGuide()
			Kit.Anim(guide, 0.1, { ImageTransparency = 0.88 })
			task.delay(0.18, function()
				Kit.Anim(guide, 0.25, { ImageTransparency = 1 })
			end)
			saveLayout()
		end
	end

	Util.Bin.Connect(UserInputService.InputEnded, function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if Window.Dragging then
				task.defer(applySnap)
			end
		end
	end)

	--// ---- Smooth Drag: memperhalus gerak window saat di-drag ----
	-- Tidak mengganti drag bawaan; hanya menambahkan interpolasi visual halus
	-- pada UIScale (efek "lift") agar terasa premium.
	local dragWatch = false
	Util.Bin.Connect(main:GetPropertyChangedSignal("Position"), function()
		if Window.Dragging and not dragWatch then
			dragWatch = true
			local blur = main:FindFirstChild("Blur")
			if blur then
				Kit.Anim(blur, 0.2, { ImageTransparency = 0.45 })
			end
		elseif not Window.Dragging and dragWatch then
			dragWatch = false
			local blur = main:FindFirstChild("Blur")
			if blur then
				Kit.Anim(blur, 0.3, { ImageTransparency = 1 - ((ctx.Settings and ctx.Settings.data.Shadow or 60) / 100) })
			end
		end
	end)

	--// ---- Resize handle tambahan (PC) di sudut kanan-bawah ----
	-- WindUI sudah punya resize; handle ini hanya memberi area grip visual
	-- dan tetap menghormati Window.MinSize / Window.MaxSize.
	if Util.IsPC and Window.Resizable ~= false then
		local grip = Kit.Card(8, {
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(1, -6, 1, -6),
			AnchorPoint = Vector2.new(1, 1),
			ThemeTag = { ImageColor3 = "Text" },
			ImageTransparency = 1,
			ZIndex = 300,
			Parent = main,
		}, {
			Kit.IconImage("grip", 12, "Icon", {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ImageTransparency = 0.5,
				ZIndex = 301,
			}),
		}, true)
		Util.Bin.Track(grip)

		local resizing, startPos, startSize
		Util.Bin.Connect(grip.MouseEnter, function()
			Kit.Anim(grip, 0.12, { ImageTransparency = 0.9 })
		end)
		Util.Bin.Connect(grip.MouseLeave, function()
			if not resizing then
				Kit.Anim(grip, 0.12, { ImageTransparency = 1 })
			end
		end)
		Util.Bin.Connect(grip.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and Window.CanResize ~= false then
				resizing = true
				startPos = input.Position
				startSize = main.AbsoluteSize
			end
		end)
		Util.Bin.Connect(UserInputService.InputChanged, function(input)
			if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
				local scale = WindUI.UIScale or 1
				local delta = input.Position - startPos
				local minSize = Window.MinSize or Vector2.new(560, 350)
				local maxSize = Window.MaxSize or Vector2.new(850, 560)
				main.Size = UDim2.new(
					0,
					math.clamp((startSize.X + delta.X * 2) / scale, minSize.X, maxSize.X),
					0,
					math.clamp((startSize.Y + delta.Y * 2) / scale, minSize.Y, maxSize.Y)
				)
			end
		end)
		Util.Bin.Connect(UserInputService.InputEnded, function(input)
			if resizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = false
				Kit.Anim(grip, 0.15, { ImageTransparency = 1 })
				saveLayout()
			end
		end)
	end

	--// ---- Keyboard shortcut (PC) ----
	if Util.IsPC and ctx.Options.Shortcuts then
		Util.Bin.Connect(UserInputService.InputBegan, function(input, processed)
			if processed then
				return
			end
			local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

			if input.KeyCode == Enum.KeyCode.Escape then
				if ctx.Search and ctx.Search.Opened then
					ctx.Search:Close()
				else
					Panel.CloseAll()
				end
			elseif ctrl and input.KeyCode == Enum.KeyCode.F then
				if ctx.Search then
					ctx.Search:Toggle()
				end
			elseif ctrl and input.KeyCode == Enum.KeyCode.P then
				if ctx.Panels.Players then
					ctx.Panels.Players:Toggle()
				end
			elseif ctrl and input.KeyCode == Enum.KeyCode.Comma then
				if ctx.Panels.Settings then
					ctx.Panels.Settings:Toggle()
				end
			elseif ctrl and input.KeyCode == Enum.KeyCode.M then
				Nexzan.Watermark.Toggle()
			end
		end)
	end

	--// ---- Klik di luar panel = tutup panel (mobile friendly) ----
	Util.Bin.Connect(UserInputService.InputBegan, function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		task.defer(function()
			local pos = input.Position
			local function inside(frame)
				if not frame or not frame.Visible then
					return false
				end
				local p, s = frame.AbsolutePosition, frame.AbsoluteSize
				return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
			end

			-- Jangan tutup jika klik di area topbar (tempat ikon berada).
			local topbar = Util.Get(Window, "UIElements", "Main", "Main", "Topbar")
			if inside(topbar) then
				return
			end

			for _, panel in pairs(ctx.Panels) do
				if panel.Opened and not inside(panel.Root) then
					panel:Close()
				end
			end
		end)
	end)

	return WindowExtra
end

--// ==========================================================================
--//  13. DEVELOPER PANEL — hanya untuk UserId yang ada di whitelist
--//      Jika tidak whitelist: ikon tidak dibuat sama sekali (tidak ada
--//      ruang kosong, tidak ada menu, tidak ada cara mengaksesnya).
--// ==========================================================================

local Developer = {}

local Meta = {
	Version = NEXZAN_VERSION,
	Channel = NEXZAN_CHANNEL,
	Author = "Nexzan",
	Discord = "https://discord.gg/nexzan",
	Website = "https://nexzan.dev",
	Github = "https://github.com/nexzan/nexzan-hub",
	Youtube = "https://youtube.com/@nexzan",
	Donate = "https://saweria.co/nexzan",
	Support = "https://discord.gg/nexzan",
	Tutorial = "https://nexzan.dev/docs",
}
Developer.Meta = Meta

function Developer.IsDeveloper(list)
	local id = LocalPlayer and LocalPlayer.UserId
	if not id then
		return false
	end
	for _, dev in ipairs(list or {}) do
		if tonumber(dev) == id then
			return true
		end
	end
	return false
end

function Developer.Init(ctx)
	local C = Kit.Controls
	local Window = ctx.Window
	local live = {}
	local logLines = {}
	local logLabel

	--// Log viewer menangkap output tanpa mengubah perilaku game.
	local function pushLog(kind, text)
		table.insert(logLines, string.format("[%s] %s", kind, tostring(text)))
		if #logLines > 120 then
			table.remove(logLines, 1)
		end
		if logLabel then
			logLabel.Text = table.concat(logLines, "\n")
		end
	end

	Util.Bin.Connect(LogService.MessageOut, function(message, messageType)
		local kind = (messageType == Enum.MessageType.MessageError and "ERROR")
			or (messageType == Enum.MessageType.MessageWarning and "WARN")
			or "INFO"
		pushLog(kind, message)
	end)

	local panel = Panel.new(ctx, {
		Id = "Developer",
		Title = "Developer",
		Icon = "wrench",
		Width = 340,
		MaxHeight = 400,
		Tabs = true,

		Build = function(self)
			--// ---------------- About ----------------
			local about = self:Page("About", "info")

			C.Section(about, "Script", 1)
			C.Info(about, { Title = "Name", Value = NEXZAN_NAME, LayoutOrder = 2 })
			C.Info(about, { Title = "Version", Value = Meta.Version, LayoutOrder = 3 })
			C.Info(about, { Title = "Channel", Value = Meta.Channel, LayoutOrder = 4 })
			C.Info(about, { Title = "WindUI", Value = tostring(ctx.WindUI.Version or "?"), LayoutOrder = 5 })
			C.Info(about, { Title = "Author", Value = Meta.Author, LayoutOrder = 6 })

			C.Section(about, "Credits", 10)
			C.Info(about, { Title = "UI Library", Value = "WindUI by Footagesus", LayoutOrder = 11 })
			C.Info(about, { Title = "Icons", Value = "Lucide Icons", LayoutOrder = 12 })
			C.Info(about, { Title = "Extension", Value = NEXZAN_NAME, LayoutOrder = 13 })

			C.Section(about, "Links", 20)
			local function linkRow(title, icon, url, order)
				C.Button(about, {
					Title = title,
					Icon = icon,
					LayoutOrder = order,
					Tooltip = url,
					Callback = function()
						Util.Clipboard(url)
						Nexzan.Notify(title, "Link disalin ke clipboard", "clipboard-check")
					end,
				})
			end
			linkRow("Discord", "message-circle", Meta.Discord, 21)
			linkRow("Website", "globe", Meta.Website, 22)
			linkRow("Github", "github", Meta.Github, 23)
			linkRow("Youtube", "youtube", Meta.Youtube, 24)
			linkRow("Support", "life-buoy", Meta.Support, 25)
			linkRow("Donate", "heart", Meta.Donate, 26)
			linkRow("Tutorial", "graduation-cap", Meta.Tutorial, 27)

			C.Section(about, "Update Log", 30)
			C.Info(about, { Title = "v1.0.0", Value = "Initial premium release", LayoutOrder = 31 })
			C.Info(about, { Title = "Search", Value = "Realtime search engine", LayoutOrder = 32 })
			C.Info(about, { Title = "Players", Value = "Movement, ESP, Teleport", LayoutOrder = 33 })
			C.Info(about, { Title = "Settings", Value = "Background, UI, 11 Themes", LayoutOrder = 34 })

			C.Section(about, "FAQ", 40)
			C.Button(about, {
				Title = "Apakah script lama tetap jalan?",
				Icon = "circle-help",
				LayoutOrder = 41,
				Callback = function()
					Nexzan.Notifications.Button(
						"FAQ",
						"Ya. Extension ini hanya menambah fitur di atas WindUI. Semua API lama tidak berubah.",
						"Mengerti"
					)
				end,
			})
			C.Button(about, {
				Title = "Apakah source WindUI diubah?",
				Icon = "circle-help",
				LayoutOrder = 42,
				Callback = function()
					Nexzan.Notifications.Button(
						"FAQ",
						"Tidak. main.lua dimuat apa adanya lewat loadstring, tanpa edit & tanpa deobfuscate.",
						"Mengerti"
					)
				end,
			})

			--// ---------------- Config ----------------
			local config = self:Page("Config", "save")

			C.Section(config, "UI", 1)
			C.Button(config, {
				Title = "Reload UI",
				Icon = "refresh-cw",
				LayoutOrder = 2,
				Callback = function()
					Panel.CloseAll()
					if ctx.Search then
						ctx.Search:Close()
					end
					Util.Try(function()
						Window:SetToTheCenter()
					end)
					Util.Try(function()
						Creator.SetTheme(Creator.Theme)
					end)
					Nexzan.Notify("Developer", "UI di-reload", "refresh-cw")
				end,
			})
			C.Button(config, {
				Title = "Reset Window Layout",
				Icon = "layout-dashboard",
				LayoutOrder = 3,
				Callback = function()
					Util.Try(function()
						Window:SetToTheCenter()
						Window:SetSize(Window.Size)
					end)
					Nexzan.Notify("Developer", "Layout window direset", "layout-dashboard")
				end,
			})

			C.Section(config, "Config Manager", 10)
			C.Button(config, {
				Title = "Save Config",
				Icon = "save",
				LayoutOrder = 11,
				Callback = function()
					local cfg = Window.CurrentConfig
					if cfg and cfg.Save then
						local ok = Util.Try(function()
							cfg:Save()
						end)
						Nexzan.Notify(
							"Config",
							ok and "Config tersimpan" or "Gagal menyimpan config",
							ok and "save" or "triangle-alert"
						)
					else
						Nexzan.Notify("Config", "Window ini tidak memakai ConfigManager", "triangle-alert")
					end
				end,
			})
			C.Button(config, {
				Title = "Load Config",
				Icon = "folder-open",
				LayoutOrder = 12,
				Callback = function()
					local cfg = Window.CurrentConfig
					if cfg and cfg.Load then
						local ok = Util.Try(function()
							cfg:Load()
						end)
						Nexzan.Notify(
							"Config",
							ok and "Config dimuat" or "Gagal memuat config",
							ok and "folder-open" or "triangle-alert"
						)
					else
						Nexzan.Notify("Config", "Window ini tidak memakai ConfigManager", "triangle-alert")
					end
				end,
			})
			C.Button(config, {
				Title = "Reload Config",
				Icon = "rotate-cw",
				LayoutOrder = 13,
				Callback = function()
					local cfg = Window.CurrentConfig
					if cfg and cfg.Load and cfg.Save then
						Util.Try(function()
							cfg:Save()
							cfg:Load()
						end)
						Nexzan.Notify("Config", "Config di-reload", "rotate-cw")
					end
				end,
			})
			C.Button(config, {
				Title = "Save Nexzan Settings",
				Icon = "hard-drive",
				LayoutOrder = 14,
				Callback = function()
					if ctx.Settings then
						ctx.Settings.Save()
					end
					if ctx.WindowExtra and ctx.WindowExtra.Save then
						ctx.WindowExtra.Save()
					end
					Nexzan.Notify("Settings", "Pengaturan Nexzan tersimpan", "hard-drive")
				end,
			})

			--// ---------------- Debug ----------------
			local debugPage = self:Page("Debug", "bug")

			C.Section(debugPage, "Performance", 1)
			live.fps = C.Info(debugPage, { Title = "FPS", Value = "-", LayoutOrder = 2 })
			live.fpsRange = C.Info(debugPage, { Title = "FPS Min / Max", Value = "-", LayoutOrder = 3 })
			live.ping = C.Info(debugPage, { Title = "Ping", Value = "-", LayoutOrder = 4 })
			live.memory = C.Info(debugPage, { Title = "Memory Usage", Value = "-", LayoutOrder = 5 })
			live.network = C.Info(debugPage, { Title = "Network", Value = "-", LayoutOrder = 6 })
			live.tasks = C.Info(debugPage, { Title = "Active Tasks", Value = "-", LayoutOrder = 7 })
			live.instances = C.Info(debugPage, { Title = "Instances", Value = "-", LayoutOrder = 8 })

			C.Section(debugPage, "Game Info", 20)
			C.Info(debugPage, { Title = "Game", Value = ctx.GameName or "?", LayoutOrder = 21 })
			C.Info(debugPage, { Title = "PlaceId", Value = tostring(game.PlaceId), LayoutOrder = 22, Copyable = true })
			C.Info(debugPage, { Title = "JobId", Value = tostring(game.JobId), LayoutOrder = 23, Copyable = true })
			live.players = C.Info(debugPage, { Title = "Players", Value = "-", LayoutOrder = 24 })
			live.uptime = C.Info(debugPage, { Title = "Session Time", Value = "-", LayoutOrder = 25 })

			C.Section(debugPage, "Executor Info", 30)
			C.Info(debugPage, { Title = "Executor", Value = Util.Executor(), LayoutOrder = 31, Copyable = true })
			C.Info(debugPage, {
				Title = "Filesystem",
				Value = Util.File.Enabled and "Available" or "Unavailable",
				LayoutOrder = 32,
			})
			C.Info(debugPage, {
				Title = "getcustomasset",
				Value = getcustomasset and "Yes" or "No",
				LayoutOrder = 33,
			})
			C.Info(debugPage, { Title = "gethui", Value = gethui and "Yes" or "No", LayoutOrder = 34 })

			C.Section(debugPage, "Player Info", 40)
			C.Info(debugPage, { Title = "Username", Value = LocalPlayer.Name, LayoutOrder = 41, Copyable = true })
			C.Info(debugPage, { Title = "UserId", Value = LocalPlayer.UserId, LayoutOrder = 42, Copyable = true })
			C.Info(debugPage, { Title = "Device", Value = Util.Device(), LayoutOrder = 43 })

			--// ---------------- Tools ----------------
			local tools = self:Page("Tools", "hammer")

			C.Section(tools, "Console / Log", 1)
			logLabel = Kit.Label("", 11, "Regular", "Text", {
				TextTransparency = 0.25,
				TextXAlignment = "Left",
				TextYAlignment = "Top",
				AutomaticSize = "Y",
				Size = UDim2.new(1, -16, 0, 0),
				Position = UDim2.new(0, 8, 0, 8),
				TextWrapped = true,
				RichText = false,
			})
			Kit.Card(12, {
				Size = UDim2.new(1, 0, 0, 150),
				ThemeTag = { ImageColor3 = "Text" },
				ImageTransparency = 0.96,
				LayoutOrder = 2,
				ClipsDescendants = true,
				Parent = tools,
			}, {
				Kit.Scroll({
					Size = UDim2.new(1, 0, 1, 0),
				}, { logLabel }),
			})
			C.Button(tools, {
				Title = "Clear Log",
				Icon = "eraser",
				LayoutOrder = 3,
				Callback = function()
					table.clear(logLines)
					logLabel.Text = ""
				end,
			})
			C.Button(tools, {
				Title = "Copy Log",
				Icon = "clipboard-copy",
				LayoutOrder = 4,
				Callback = function()
					Util.Clipboard(table.concat(logLines, "\n"))
					Nexzan.Notify("Log", "Log disalin", "clipboard-check")
				end,
			})

			C.Section(tools, "Notification Tester", 10)
			C.Button(tools, {
				Title = "Test Simple",
				Icon = "bell",
				LayoutOrder = 11,
				Callback = function()
					Nexzan.Notify("Test", "Ini notifikasi biasa", "bell")
				end,
			})
			C.Button(tools, {
				Title = "Test Progress",
				Icon = "loader",
				LayoutOrder = 12,
				Callback = function()
					local p = Nexzan.Notifications.Progress("Progress", "Memproses...", "loader")
					task.spawn(function()
						for i = 1, 10 do
							task.wait(0.25)
							p:Set(i / 10, ("Memproses... %d%%"):format(i * 10))
						end
						p:Close()
					end)
				end,
			})
			C.Button(tools, {
				Title = "Test Interactive",
				Icon = "message-square",
				LayoutOrder = 13,
				Callback = function()
					Nexzan.Notifications.Confirm("Konfirmasi", "Lanjutkan aksi ini?", function()
						Nexzan.Notify("Konfirmasi", "Aksi dijalankan", "circle-check")
					end, function()
						Nexzan.Notify("Konfirmasi", "Dibatalkan", "circle-x")
					end)
				end,
			})
			C.Button(tools, {
				Title = "Test Queue (x4)",
				Icon = "list",
				LayoutOrder = 14,
				Callback = function()
					for i = 1, 4 do
						Nexzan.Notifications.Queue("Queue #" .. i, "Notifikasi antrean ke-" .. i, "list", 2.5)
					end
				end,
			})
			C.Button(tools, {
				Title = "Test Loading",
				Icon = "loader-circle",
				LayoutOrder = 15,
				Callback = function()
					local l = Nexzan.Notifications.Loading("Loading", "Memuat data...")
					task.delay(2.5, function()
						l:Finish(true, "Data dimuat")
					end)
				end,
			})

			C.Section(tools, "Inspector", 20)
			live.inspector = C.Info(tools, { Title = "Hovered Element", Value = "-", LayoutOrder = 21 })
			C.Toggle(tools, {
				Title = "UI Inspector",
				LayoutOrder = 22,
				Tooltip = "Tampilkan nama & class elemen di bawah kursor",
				Callback = function(enabled)
					if enabled then
						Util.Scheduler.Add("nexzan_inspector", 0.15, function()
							local gui = WindUI.ScreenGui
							if not gui then
								return
							end
							local found = gui:GetGuiObjectsAtPosition(
								UserInputService:GetMouseLocation().X,
								UserInputService:GetMouseLocation().Y
							)
							local top = found and found[1]
							live.inspector:Set(top and (top.ClassName .. " · " .. top.Name) or "-")
						end)
					else
						Util.Scheduler.Remove("nexzan_inspector")
						live.inspector:Set("-")
					end
				end,
			})
			C.Button(tools, {
				Title = "Component List",
				Icon = "list-tree",
				LayoutOrder = 23,
				Callback = function()
					local counts = {}
					for _, tab in pairs((Window.TabModule and Window.TabModule.Tabs) or {}) do
						for _, element in pairs(tab.Elements or {}) do
							local kind = element.__type or "Unknown"
							counts[kind] = (counts[kind] or 0) + 1
						end
					end
					local lines = {}
					for kind, count in pairs(counts) do
						table.insert(lines, ("%s x%d"):format(kind, count))
					end
					table.sort(lines)
					Nexzan.Notifications.Button(
						"Component List",
						#lines > 0 and table.concat(lines, ", ") or "Tidak ada elemen",
						"Tutup"
					)
				end,
			})

			C.Section(tools, "Theme Editor", 30)
			C.Button(tools, {
				Title = "Dump Current Theme",
				Icon = "palette",
				LayoutOrder = 31,
				Callback = function()
					local theme = Creator.Theme or {}
					local lines = {}
					for key, value in pairs(theme) do
						if typeof(value) == "Color3" then
							table.insert(lines, ("%s = \"#%s\""):format(key, value:ToHex()))
						end
					end
					table.sort(lines)
					Util.Clipboard(table.concat(lines, "\n"))
					Nexzan.Notify("Theme Editor", "Theme disalin ke clipboard", "clipboard-check")
				end,
			})
			C.Button(tools, {
				Title = "API Info",
				Icon = "code",
				LayoutOrder = 32,
				Callback = function()
					local api = {}
					for key, value in pairs(ctx.WindUI) do
						if type(value) == "function" then
							table.insert(api, key)
						end
					end
					table.sort(api)
					Util.Clipboard("WindUI API: " .. table.concat(api, ", "))
					Nexzan.Notify("API Info", #api .. " fungsi disalin", "code")
				end,
			})

			C.Section(tools, "Experimental", 40)
			C.Toggle(tools, {
				Title = "FPS Counter (Watermark)",
				Value = Nexzan.Watermark.Enabled,
				LayoutOrder = 41,
				Callback = function(v)
					Nexzan.Watermark.Set(v)
				end,
			})
			C.Toggle(tools, {
				Title = "Verbose Errors",
				LayoutOrder = 42,
				Callback = function(v)
					Window.Debug = v
				end,
			})
			C.Button(tools, {
				Title = "Force Garbage Collect",
				Icon = "trash",
				LayoutOrder = 43,
				Callback = function()
					local before = Util.Memory()
					Util.Try(function()
						collectgarbage("collect")
					end)
					task.wait(0.2)
					Nexzan.Notify("Memory", ("%d MB → %d MB"):format(before, Util.Memory()), "trash")
				end,
			})

			--// ---------------- Catalog ----------------
			local catalog = self:Page("Catalog", "book-open")

			C.Section(catalog, "Catalog Tab", 1)
			C.Button(catalog, {
				Title = "Create Catalog Tab",
				Icon = "plus",
				LayoutOrder = 2,
				Tooltip = "Membuat tab Catalog berisi info script",
				Callback = function()
					local tab = Nexzan.CreateCatalogTab()
					if tab then
						Nexzan.Notify("Catalog", "Tab Catalog dibuat", "book-open")
						self:Close()
						Util.Try(function()
							tab:Select()
						end)
					else
						Nexzan.Notify("Catalog", "Tab Catalog sudah ada", "info")
					end
				end,
			})
			C.Info(catalog, {
				Title = "Status",
				Value = "Ready",
				LayoutOrder = 3,
			})

			self:SelectPage("About")
		end,

		OnOpen = function()
			Util.Scheduler.Add("nexzan_dev_live", 0.5, function()
				if live.fps then
					live.fps:Set(Util.FPS.value)
				end
				if live.fpsRange then
					live.fpsRange:Set(("%d / %d"):format(Util.FPS.min == 999 and 0 or Util.FPS.min, Util.FPS.max))
				end
				if live.ping then
					live.ping:Set(Util.PingMs() .. " ms")
				end
				if live.memory then
					live.memory:Set(Util.Memory() .. " MB")
				end
				if live.network then
					live.network:Set(Util.NetworkKbps() .. " kb/s")
				end
				if live.tasks then
					live.tasks:Set(Util.Scheduler.count)
				end
				if live.instances then
					live.instances:Set(#Util.Bin.instances .. " tracked")
				end
				if live.players then
					live.players:Set(("%d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers))
				end
				if live.uptime then
					live.uptime:Set(Util.PlayTime(ctx.StartClock))
				end
			end)
		end,

		OnClose = function()
			Util.Scheduler.Remove("nexzan_dev_live")
		end,
	})

	ctx.Panels.Developer = panel
	return panel
end

--// ==========================================================================
--//  14. CATALOG TAB — dibuat lewat Window:Tab (API resmi WindUI)
--// ==========================================================================

function Developer.CreateCatalogTab(ctx)
	if ctx.CatalogTab then
		return nil
	end

	local Window = ctx.Window
	local ok, tab = pcall(function()
		return Window:Tab({
			Title = "Catalog",
			Icon = "book-open",
			Desc = NEXZAN_NAME .. " — Script Information",
		})
	end)
	if not ok or not tab then
		return nil
	end

	ctx.CatalogTab = tab

	Util.Try(function()
		tab:Section({ Title = "Script Information" })
		tab:Paragraph({
			Title = NEXZAN_NAME,
			Desc = ("%s · versi %s\nExtension premium untuk WindUI — menambah Search, Players, Settings, Developer, Watermark, dan Notification tanpa mengubah API WindUI."):format(
				Meta.Channel,
				Meta.Version
			),
			Image = "sparkles",
		})

		tab:Section({ Title = "Version" })
		tab:Paragraph({
			Title = "Version " .. Meta.Version,
			Desc = ("Channel: %s\nWindUI: %s\nExecutor: %s"):format(
				Meta.Channel,
				tostring(ctx.WindUI.Version or "?"),
				Util.Executor()
			),
		})

		tab:Section({ Title = "Features" })
		tab:Paragraph({
			Title = "Fitur Utama",
			Desc = table.concat({
				"• Search Engine realtime (Tab, Button, Toggle, Slider, Dropdown, Textbox)",
				"• Players Panel (Movement, Camera, ESP, Teleport, Misc)",
				"• Settings Panel (Background, UI Scale, 11 Theme)",
				"• Developer Panel (whitelist UserId)",
				"• Watermark modern (FPS, Ping, Memory, dll)",
				"• Notification: Progress, Interactive, Button, Queue, Loading",
				"• Window: Resize, Smooth Drag, Snap, Remember Position & Size",
			}, "\n"),
		})

		tab:Section({ Title = "Credits" })
		tab:Paragraph({
			Title = "Credits",
			Desc = "WindUI oleh Footagesus\nLucide Icons\nNexzan Hub Extension",
		})

		tab:Section({ Title = "Links" })
		local function linkButton(title, icon, url)
			tab:Button({
				Title = title,
				Desc = url,
				Icon = icon,
				Callback = function()
					Util.Clipboard(url)
					Nexzan.Notify(title, "Link disalin ke clipboard", "clipboard-check")
				end,
			})
		end
		linkButton("Discord", "message-circle", Meta.Discord)
		linkButton("Website", "globe", Meta.Website)
		linkButton("Youtube", "youtube", Meta.Youtube)
		linkButton("Tutorial", "graduation-cap", Meta.Tutorial)

		tab:Section({ Title = "FAQ" })
		tab:Paragraph({
			Title = "Apakah script lama tetap kompatibel?",
			Desc = "Ya. Extension hanya menambah fitur. Semua fungsi, class, struktur Window/Tab/Theme/Config WindUI tidak diubah sama sekali.",
		})
		tab:Paragraph({
			Title = "Apakah source WindUI diedit?",
			Desc = "Tidak. main.lua dimuat lewat loadstring apa adanya, tanpa deobfuscate dan tanpa modifikasi.",
		})

		tab:Section({ Title = "Change Log" })
		tab:Paragraph({
			Title = "v1.0.0",
			Desc = "Rilis pertama Premium Edition: header bar, search, players, settings, developer, watermark, notification extras, window enhancements.",
		})

		tab:Section({ Title = "Known Bugs" })
		tab:Paragraph({
			Title = "Catatan",
			Desc = "• Freecam butuh mouse lock (PC).\n• Beberapa executor tanpa filesystem tidak dapat menyimpan pengaturan.\n• Background dari URL memerlukan getcustomasset.",
		})

		tab:Section({ Title = "Developer Notes" })
		tab:Paragraph({
			Title = "Notes",
			Desc = "Panel Developer hanya tampil untuk UserId di whitelist. Tambahkan UserId lewat Nexzan:AddDeveloper(id) sebelum Attach.",
		})
	end)

	return tab
end

--// ==========================================================================
--//  15. MAIN — perakitan extension
--// ==========================================================================

Nexzan = {
	Name = NEXZAN_NAME,
	Version = NEXZAN_VERSION,
	Channel = NEXZAN_CHANNEL,

	Attached = false,
	Window = nil,
	WindUI = nil,

	Options = table.clone(DefaultOptions),
	Developers = table.clone(Developers),

	Util = Util,
	Features = Features,
	Themes = Themes,
	Panel = Panel,
	Kit = Kit,
	Watermark = nil,
	Notifications = nil,
	Panels = {},
}

--// Notify helper global (dipakai semua modul di atas).
function Nexzan.Notify(title, content, icon, duration)
	if Nexzan.Notifications and Nexzan.Notifications.Send then
		return Nexzan.Notifications.Send(title, content, icon, duration)
	end
	if Nexzan.WindUI then
		return Nexzan.WindUI:Notify({
			Title = title or NEXZAN_NAME,
			Content = content,
			Icon = icon or "sparkles",
			Duration = duration or 4,
		})
	end
	return nil
end

--- Tambah UserId developer (harus dipanggil sebelum Attach agar ikon muncul).
function Nexzan:AddDeveloper(userId)
	userId = tonumber(userId)
	if userId and not table.find(Nexzan.Developers, userId) then
		table.insert(Nexzan.Developers, userId)
	end
	return Nexzan
end

function Nexzan:IsDeveloper()
	return Developer.IsDeveloper(Nexzan.Developers)
end

function Nexzan.CreateCatalogTab()
	if not Nexzan.ctx then
		return nil
	end
	return Developer.CreateCatalogTab(Nexzan.ctx)
end

--// --------------------------------------------------------------------------
--//  Pemasangan ke Window
--// --------------------------------------------------------------------------

local function attachToWindow(ctx)
	local Window = ctx.Window

	-- Beri jarak visual antara ikon Nexzan dan tombol jendela bawaan.
	Util.Try(function()
		local right = Util.Get(Window, "UIElements", "Main", "Main", "Topbar", "Right")
		if right then
			local spacer = Creator.New("Frame", {
				Name = "NexzanSpacer",
				Size = UDim2.new(0, 4, 0, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 994,
				Parent = right,
			})
			Util.Bin.Track(spacer)
		end
	end)

	--// 1) Search
	if ctx.Options.Search then
		local search = Search.Init(ctx)
		Header.Add("Search", "Search  (Ctrl+F)", function()
			search:Toggle()
		end)
	end

	--// 2) Players
	if ctx.Options.Players then
		local panel = PlayersPanel.Init(ctx)
		Header.Add("Players", "Players  (Ctrl+P)", function()
			if ctx.Search then
				ctx.Search:Close()
			end
			panel:Toggle()
		end)
	end

	--// 3) Settings
	if ctx.Options.Settings then
		local panel = SettingsPanel.Init(ctx)
		Header.Add("Settings", "Settings  (Ctrl+,)", function()
			if ctx.Search then
				ctx.Search:Close()
			end
			panel:Toggle()
		end)
	end

	--// 4) Developer — HANYA jika UserId ada di whitelist.
	--    Jika tidak: tidak ada ikon, tidak ada panel, tidak ada ruang kosong.
	if ctx.Options.Developer and Developer.IsDeveloper(ctx.Developers) then
		local panel = Developer.Init(ctx)
		Header.Add("Developer", "Developer Tools", function()
			if ctx.Search then
				ctx.Search:Close()
			end
			panel:Toggle()
		end)
		ctx.IsDeveloper = true
	else
		ctx.IsDeveloper = false
	end

	--// 5) Window enhancements
	ctx.WindowExtra = WindowExtra.Init(ctx)

	--// 6) Watermark
	if ctx.Options.Watermark or (ctx.Settings and ctx.Settings.data.Watermark) then
		task.delay(0.4, function()
			Nexzan.Watermark.Set(true)
		end)
	end

	--// Tutup panel bila window ditutup/di-minimize.
	Util.Try(function()
		local originalOnClose = Window.OnCloseCallback
		Window:OnClose(function()
			Panel.CloseAll()
			if ctx.Search then
				ctx.Search:Close()
			end
			if originalOnClose then
				Creator.SafeCallback(originalOnClose)
			end
		end)
	end)

	--// Bersihkan semua resource saat window dihancurkan (tanpa memory leak).
	Util.Try(function()
		local originalOnDestroy = Window.OnDestroyCallback
		Window:OnDestroy(function()
			Nexzan:Unload()
			if originalOnDestroy then
				Creator.SafeCallback(originalOnDestroy)
			end
		end)
	end)
end

--// --------------------------------------------------------------------------
--//  Attach — hook ke WindUI:CreateWindow tanpa mengubah API
--// --------------------------------------------------------------------------

function Nexzan:Attach(windui, options)
	if type(windui) ~= "table" or type(windui.CreateWindow) ~= "function" then
		warn(("[ %s ] Objek WindUI tidak valid."):format(NEXZAN_NAME))
		return Nexzan
	end
	if Nexzan.Attached then
		return Nexzan
	end
	Nexzan.Attached = true
	Nexzan.WindUI = windui

	for key, value in pairs(options or {}) do
		Nexzan.Options[key] = value
	end
	if type(Nexzan.Options.Developers) == "table" then
		for _, id in ipairs(Nexzan.Options.Developers) do
			Nexzan:AddDeveloper(id)
		end
	end

	Kit.Init(windui)
	WindUI = windui
	Creator = windui.Creator

	--// Theme tambahan (Purple, Blue, BloodMoon, Glass, Discord, Midnight, Cyber, Ocean, Galaxy)
	if Nexzan.Options.Themes then
		Themes.Register(windui)
	end

	local ctx = {
		WindUI = windui,
		Options = Nexzan.Options,
		Developers = Nexzan.Developers,
		Panels = Nexzan.Panels,
		StartClock = os.clock(),
		GameName = "Game",
	}
	Nexzan.ctx = ctx

	task.spawn(function()
		local ok, info = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		end)
		if ok and info and info.Name then
			ctx.GameName = info.Name
		end
	end)

	Nexzan.Notifications = Notifications.Init(ctx)
	Nexzan.Watermark = Watermark.Init(ctx)
	Util.DetectRegion()

	--// --- Hook CreateWindow: window lama & baru tetap identik ---
	local originalCreateWindow = windui.CreateWindow

	windui.CreateWindow = function(selfOrConfig, maybeConfig)
		-- Mendukung pemanggilan WindUI:CreateWindow(cfg) maupun WindUI.CreateWindow(cfg)
		local window
		if maybeConfig ~= nil then
			window = originalCreateWindow(selfOrConfig, maybeConfig)
		else
			window = originalCreateWindow(windui, selfOrConfig)
		end

		if window and not Nexzan.Window then
			Nexzan.Window = window
			ctx.Window = window
			-- Ditunda satu frame agar Topbar & UIElements sudah lengkap.
			task.defer(function()
				local ok, err = pcall(function()
					Header.Init(ctx)
					attachToWindow(ctx)
				end)
				if ok then
					if ctx.Options.CatalogAutoOpen then
						Developer.CreateCatalogTab(ctx)
					end
				else
					warn(("[ %s ] Gagal memasang extension: %s"):format(NEXZAN_NAME, tostring(err)))
				end
			end)
		end

		return window
	end

	--// Jika window sudah dibuat sebelum extension dimuat, pasang langsung.
	if windui.Window then
		Nexzan.Window = windui.Window
		ctx.Window = windui.Window
		task.defer(function()
			local ok, err = pcall(function()
				Header.Init(ctx)
				attachToWindow(ctx)
			end)
			if not ok then
				warn(("[ %s ] Gagal memasang extension: %s"):format(NEXZAN_NAME, tostring(err)))
			end
		end)
	end

	return Nexzan
end

--// --------------------------------------------------------------------------
--//  Unload — lepas semua koneksi, task, dan instance (bebas memory leak)
--// --------------------------------------------------------------------------

function Nexzan:Unload()
	if not Nexzan.Attached then
		return
	end
	Nexzan.Attached = false

	Util.Try(function()
		Features.ResetAll()
	end)
	Util.Try(function()
		if Nexzan.Watermark then
			Nexzan.Watermark.Set(false)
		end
	end)

	for name in pairs(Util.Scheduler.tasks) do
		Util.Scheduler.Remove(name)
	end

	Panel.CloseAll()
	Util.Bin.Clear()

	Nexzan.Panels = {}
	Nexzan.Window = nil
	Nexzan.ctx = nil
end

--// --------------------------------------------------------------------------
--//  API publik tambahan (opsional untuk script pengguna)
--// --------------------------------------------------------------------------

function Nexzan:SetWatermark(enabled)
	if Nexzan.Watermark then
		Nexzan.Watermark.Set(enabled)
	end
	return Nexzan
end

function Nexzan:ToggleWatermark()
	if Nexzan.Watermark then
		return Nexzan.Watermark.Toggle()
	end
	return false
end

function Nexzan:WatermarkField(name, value)
	if Nexzan.Watermark then
		return Nexzan.Watermark.SetField(name, value)
	end
	return nil
end

function Nexzan:OpenPanel(id)
	local panel = Nexzan.Panels[id]
	if panel then
		panel:Open()
	end
	return Nexzan
end

function Nexzan:ClosePanels()
	Panel.CloseAll()
	return Nexzan
end

function Nexzan:Search(query)
	if Nexzan.ctx and Nexzan.ctx.Search then
		Nexzan.ctx.Search:Open()
		if query then
			Nexzan.ctx.Search:Update(query)
		end
	end
	return Nexzan
end

function Nexzan:GetFeatures()
	return Features
end

--// --------------------------------------------------------------------------
--//  Auto-attach: jika WindUI sudah ada di environment, langsung pasang.
--// --------------------------------------------------------------------------

local function autoDetect()
	local candidates = {}

	local ok, env = pcall(function()
		return getgenv and getgenv() or _G
	end)
	if ok and type(env) == "table" then
		table.insert(candidates, rawget(env, "WindUI"))
	end
	table.insert(candidates, rawget(_G, "WindUI"))
	if type(shared) == "table" then
		table.insert(candidates, rawget(shared, "WindUI"))
	end

	for _, candidate in ipairs(candidates) do
		if type(candidate) == "table" and type(candidate.CreateWindow) == "function" then
			return candidate
		end
	end
	return nil
end

local detected = autoDetect()
if detected then
	Nexzan:Attach(detected)
end

-- Ekspos secara global agar script lain bisa memakai (dilindungi pcall
-- karena sebagian environment mengunci _G / shared).
Util.Try(function()
	local env = (getgenv and getgenv()) or _G
	env.NexzanHub = Nexzan
end)
Util.Try(function()
	if type(shared) == "table" then
		shared.NexzanHub = Nexzan
	end
end)

--// Mengembalikan callable: hasil loadstring bisa langsung dipanggil dengan WindUI.
return setmetatable(Nexzan, {
	__call = function(_, windui, options)
		return Nexzan:Attach(windui, options)
	end,
})

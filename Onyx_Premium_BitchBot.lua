task.spawn(function() -- wrap entire script async so it never freezes the game
local menu
local MenuName = isfile("bitchbot/menuname.txt") and readfile("bitchbot/menuname.txt") or nil
local loadstart = tick()

local function map(X, A, B, C, D)
	return (X - A) / (B - A) * (D - C) + C
end

do
	local notes = {}
	local function DrawingObject(t, col)
		local d = Drawing.new(t)

		d.Visible = true
		d.Transparency = 1
		d.Color = col

		return d
	end

	local function Rectangle(sizex, sizey, fill, col)
		local s = DrawingObject("Square", col)

		s.Filled = fill
		s.Thickness = 1
		s.Position = Vector2.new()
		s.Size = Vector2.new(sizex, sizey)

		return s
	end

	local function Text(text)
		local s = DrawingObject("Text", Color3.new(1, 1, 1))

		s.Text = text
		s.Size = 13
		s.Center = false
		s.Outline = true
		s.Position = Vector2.new()
		s.Font = 2

		return s
	end

	function CreateNotification(t, customcolor) -- TODO i want some kind of prioritized message to the notification list, like a warning or something. warnings have icons too maybe? idk??
		local gap = 25
		local width = 18

		local alpha = 255
		local time = 0
		local estep = 0
		local eestep = 0.02

		local insety = 0

		local Note = {

			enabled = true,

			targetPos = Vector2.new(50, 33),

			size = Vector2.new(200, width),

			drawings = {
				outline = Rectangle(202, width + 2, false, Color3.new(0, 0, 0)),
				fade = Rectangle(202, width + 2, false, Color3.new(0, 0, 0)),
			},

			Remove = function(self, d)
				if d.Position.x < d.Size.x then
					for k, drawing in pairs(self.drawings) do
						drawing:Remove()
						drawing = false
					end
					self.enabled = false
				end
			end,

			Update = function(self, num, listLength, dt)
				local pos = self.targetPos

				local indexOffset = (listLength - num) * gap
				if insety < indexOffset then
					insety -= (insety - indexOffset) * 0.2
				else
					insety = indexOffset
				end
				local size = self.size

				local tpos = Vector2.new(pos.x - size.x / time - map(alpha, 0, 255, size.x, 0), pos.y + insety)
				self.pos = tpos

				local locRect = {
					x = math.ceil(tpos.x),
					y = math.ceil(tpos.y),
					w = math.floor(size.x - map(255 - alpha, 0, 255, 0, 70)),
					h = size.y,
				}
				--pos.set(-size.x / fc - map(alpha, 0, 255, size.x, 0), pos.y)

				local fade = math.min(time * 12, alpha)
				fade = fade > 255 and 255 or fade < 0 and 0 or fade

				if self.enabled then
					local linenum = 1
					for i, drawing in pairs(self.drawings) do
						drawing.Transparency = fade / 255

						if type(i) == "number" then
							drawing.Position = Vector2.new(locRect.x + 1, locRect.y + i)
							drawing.Size = Vector2.new(locRect.w - 2, 1)
						elseif i == "text" then
							drawing.Position = tpos + Vector2.new(6, 2)
						elseif i == "outline" then
							drawing.Position = Vector2.new(locRect.x, locRect.y)
							drawing.Size = Vector2.new(locRect.w, locRect.h)
						elseif i == "fade" then
							drawing.Position = Vector2.new(locRect.x - 1, locRect.y - 1)
							drawing.Size = Vector2.new(locRect.w + 2, locRect.h + 2)
							local t = (200 - fade) / 255 / 3
							drawing.Transparency = t < 0.4 and 0.4 or t
						elseif i:find("line") then
							drawing.Position = Vector2.new(locRect.x + linenum, locRect.y + 1)
							if menu then
								local mencol = customcolor or (
										Color3.fromRGB(127, 72, 163)
									)
								local color = linenum == 1 and mencol or Color3.fromRGB(mencol.R * 255 - 40, mencol.G * 255 - 40, mencol.B * 255 - 40) -- super shit
								if drawing.Color ~= color then
									drawing.Color = color
								end
							end
							linenum += 1
						end
					end

					time += estep * dt * 128 -- TODO need to do the duration
					estep += eestep * dt * 64
				end
			end,

			Fade = function(self, num, len, dt)
				if self.pos.x > self.targetPos.x - 0.2 * len or self.fading then
					if not self.fading then
						estep = 0
					end
					self.fading = true
					alpha -= estep / 4 * len * dt * 50
					eestep += 0.01 * dt * 100
				end
				if alpha <= 0 then
					self:Remove(self.drawings[1])
				end
			end,
		}

		for i = 1, Note.size.y - 2 do
			local c = 0.28 - i / 80
			Note.drawings[i] = Rectangle(200, 1, true, Color3.new(c, c, c))
		end
		local color =  Color3.fromRGB(127, 72, 163)

		Note.drawings.text = Text(t)
		if Note.drawings.text.TextBounds.x + 7 > Note.size.x then -- expand the note size to fit if it's less than the default size
			Note.size = Vector2.new(Note.drawings.text.TextBounds.x + 7, Note.size.y)
		end
		Note.drawings.line = Rectangle(1, Note.size.y - 2, true, color)
		Note.drawings.line1 = Rectangle(1, Note.size.y - 2, true, color)

		notes[#notes + 1] = Note
	end

	renderStepped = game.RunService.RenderStepped:Connect(function(dt)
		Camera = workspace.CurrentCamera
		local smallest = math.huge
		for k = 1, #notes do
			local v = notes[k]
			if v and v.enabled then
				smallest = k < smallest and k or smallest
			else
				table.remove(notes, k)
			end
		end
		local length = #notes
		for k = 1, #notes do
			local note = notes[k]
			note:Update(k, length, dt)
			if k <= math.ceil(length / 10) or note.fading then
				note:Fade(k, length, dt)
			end
		end
	end)
	--ANCHOR how to create notification
	--CreateNotification("Loading...")
end

--!SECTION

local menuWidth, menuHeight = 500, 600
menu = { -- this is for menu stuffs n shi
	w = menuWidth,
	h = menuHeight,
	x = 0,
	y = 0,
	columns = {
		width = (menuWidth - 40) / 2,
		left = 17,
		right = (menuWidth - 20) / 2 + 13,
	},
	activetab = 1,
	open = true,
	fadestart = 0,
	fading = false,
	mousedown = false,
	postable = {},
	options = {},
	clrs = {
		norm = {},
		dark = {},
		togz = {},
	},
	mc = { 127, 72, 163 },
	watermark = {},
	connections = {},
	list = {},
	unloaded = false,
	copied_clr = nil,
	game = "uni",
	tabnames = {}, -- its used to change the tab num to the string (did it like this so its dynamic if u add or remove tabs or whatever :D)
	friends = {},
	priority = {},
	muted = {},
	spectating = false,
	stat_menu = false,
	load_time = 0,
	log_multi = nil,
	mgrouptabz = {},
	backspaceheld = false,
	backspacetime = -1,
	backspaceflags = 0,
	selectall = false,
	modkeys = {
		alt = {
			direction = nil,
		},
		shift = {
			direction = nil,
		},
	},
	modkeydown = function(self, key, direction)
		local keydata = self.modkeys[key]
		return keydata.direction and keydata.direction == direction or false
	end,
	keybinds = {},
	values = {}
}

local function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function average(t)
	local sum = 0
	for _, v in pairs(t) do -- Get the sum of all numbers in t
		sum = sum + v
	end
	return sum / #t
end

local function clamp(a, lowerNum, higher) -- DONT REMOVE this clamp is better then roblox's because it doesnt error when its not lower or heigher
	if a > higher then
		return higher
	elseif a < lowerNum then
		return lowerNum
	else
		return a
	end
end

local function CreateThread(func, ...) -- improved... yay.
	local thread = coroutine.create(func)
	coroutine.resume(thread, ...)
	return thread
end

local function MultiThreadList(obj, ...)
	local n = #obj
	if n > 0 then
		for i = 1, n do
			local t = obj[i]
			if type(t) == "table" then
				local d = #t
				assert(d ~= 0, "table inserted was not an array or was empty")
				assert(d < 3, ("invalid number of arguments (%d)"):format(d))
				local thetype = type(t[1])
				assert(
					thetype == "function",
					("invalid argument #1: expected 'function', got '%s'"):format(tostring(thetype))
				)

				CreateThread(t[1], unpack(t[2]))
			else
				CreateThread(t, ...)
			end
		end
	else
		for i, v in pairs(obj) do
			CreateThread(v, ...)
		end
	end
end

local DeepRestoreTableFunctions, DeepCleanupTable

DeepRestoreTableFunctions = function(tbl)
	for k, v in next, tbl do
		if type(v) == "function" and is_synapse_function(v) then
			for k1, v1 in next, getupvalues(v) do
				if type(v1) == "function" and islclosure(v1) and not is_synapse_function(v1) then
					tbl[k] = v1
				end
			end
		end

		if type(v) == "table" then
			DeepRestoreTableFunctions(v)
		end
	end
end

DeepCleanupTable = function(tbl)
	local numTable = #tbl
	local isTableArray = numTable > 0
	if isTableArray then
		for i = 1, numTable do
			local entry = tbl[i]
			local entryType = type(entry)

			if entryType == "table" then
				DeepCleanupTable(tbl)
			end

			tbl[i] = nil
			entry = nil
			entryType = nil
		end
	else
		for k, v in next, tbl do
			if type(v) == "table" then
				DeepCleanupTable(tbl)
			end
		end

		tbl[k] = nil
	end

	numTable = nil
	isTableArray = nil
end

local event = {}

local allevent = {}

function event.new(eventname, eventtable, requirename) -- fyi you can put in a table of choice to make the table you want an "event" pretty cool its like doing & in c lol!
	if eventname then
		assert(
			allevent[eventname] == nil,
			("the event '%s' already exists in the event table"):format(eventname)
		)
	end
	local newevent = eventtable or {}
	local funcs = {}
	local disconnectlist = {}
	function newevent:fire(...)
		allevent[eventname].fire(...)
	end
	function newevent:connect(func)
		funcs[#funcs + 1] = func
		local disconnected = false
		local function disconnect()
			if not disconnected then
				disconnected = true
				disconnectlist[func] = true
			end
		end
		return disconnect
	end

	local function fire(...)
		local n = #funcs
		local j = 0
		for i = 1, n do
			local func = funcs[i]
			if disconnectlist[func] then
				disconnectlist[func] = nil
			else
				j = j + 1
				funcs[j] = func
			end
		end
		for i = j + 1, n do
			funcs[i] = nil
		end
		for i = 1, j do
			CreateThread(function(...)
				pcall(funcs[i], ...)
			end, ...)
		end
	end

	if eventname then
		allevent[eventname] = {
			event = newevent,
			fire = fire,
		}
	end

	return newevent, fire
end

local function FireEvent(eventname, ...)
	if allevent[eventname] then
		return allevent[eventname].fire(...)
	else
		--warn(("Event %s does not exist!"):format(eventname))
	end
end

local function GetEvent(eventname)
	return allevent[eventname]
end

local BBOT_IMAGES = {}
local BBOT_IMAGE_URLS = {
	"https://i.imgur.com/9NMuFcQ.png",
	"https://i.imgur.com/jG3NjxN.png",
	"https://i.imgur.com/2Ty4u2O.png",
	"https://i.imgur.com/kNGuTlj.png",
	"https://i.imgur.com/OZUR3EY.png",
	"https://i.imgur.com/3HGuyVa.png",
}
MultiThreadList((function()
	local fns = {}
	for i, url in ipairs(BBOT_IMAGE_URLS) do
		local idx = i
		fns[i] = function()
			local ok, data = pcall(function() return game:HttpGet(url) end)
			BBOT_IMAGES[idx] = (ok and type(data) == "string" and #data > 0) and data or ""
		end
	end
	return fns
end)())

-- Wait for all images with a 10-second timeout so we never hang forever
local loaded = {}
do
	local deadline = tick() + 5
	local function Loopy_Image_Checky()
		if tick() > deadline then return false end  -- 5s timeout: proceed regardless
		for i = 1, 6 do
			local v = BBOT_IMAGES[i]
			if v == nil then
				return true
			elseif not loaded[i] then
				loaded[i] = true
			end
		end
		return false
	end
	while Loopy_Image_Checky() do
		task.wait()
	end
	-- Fill any still-nil slots with empty string so nothing errors later
	for i = 1, 6 do
		if BBOT_IMAGES[i] == nil then BBOT_IMAGES[i] = "" end
	end
end

loadstart = tick()

-- nate i miss u D:
-- im back
local NETWORK = game:service("NetworkClient")
local NETWORK_SETTINGS = settings().Network
NETWORK:SetOutgoingKBPSLimit(0)

setfpscap(maxfps or 144)

if not isfolder("bitchbot") then
	makefolder("bitchbot")
	if not isfile("bitchbot/relations.bb") then
		writefile("bitchbot/relations.bb", "bb:{{friends:}{priority:}")
	end
else
	if not isfile("bitchbot/relations.bb") then
		writefile("bitchbot/relations.bb", "bb:{{friends:}{priority:}")
	end
	writefile("bitchbot/debuglog.bb", "")
end

if not isfolder("bitchbot/" .. menu.game) then
	makefolder("bitchbot/" .. menu.game)
end

local configs = {}

local function GetConfigs()
	local result = {}
	local directory = "bitchbot\\" .. menu.game
	for k, v in pairs(listfiles(directory)) do
		local clipped = v:sub(#directory + 2)
		if clipped:sub(#clipped - 2) == ".bb" then
			clipped = clipped:sub(0, #clipped - 3)
			result[k] = clipped
			configs[k] = v
		end
	end
	if #result <= 0 then
		writefile("bitchbot/" .. menu.game .. "/Default.bb", "")
	end
	return result
end

local Players = game:GetService("Players")
local stats = game:GetService("Stats")

local function UnpackRelations()
	local str = isfile("bitchbot/relations.bb") and readfile("bitchbot/relations.bb") or nil
	local final = {
		friends = {},
		priority = {},
	}
	if str then
		if str:find("bb:{{") then
			writefile("bitchbot/relations.bb", "friends:\npriority:")
			return
		end

		local friends, frend = str:find("friends:")
		local priority, priend = str:find("\npriority:")
		local friendslist = str:sub(frend + 1, priority - 1)
		local prioritylist = str:sub(priend + 1)
		for i in friendslist:gmatch("[^,]+") do
			if not table.find(final.friends, i) then
				table.insert(final.friends, i)
			end
		end
		for i in prioritylist:gmatch("[^,]+") do
			if not table.find(final.priority, i) then
				table.insert(final.priority, i)
			end
		end
	end
	if not menu then
		repeat
			game.RunService.Heartbeat:Wait()
		until menu
	end
	menu.friends = final.friends
	if not table.find(menu.friends, Players.LocalPlayer.Name) then
		table.insert(menu.friends, Players.LocalPlayer.Name)
	end
	menu.priority = final.priority
end

local function WriteRelations()
	local str = "friends:"

	for k, v in next, menu.friends do
		local playerobj
		local userid
		local pass, ret = pcall(function()
			playerobj = Players[v]
		end)

		if not pass then
			local newpass, newret = pcall(function()
				userid = v
			end)
		end

		if userid then
			str ..= tostring(userid) .. ","
		else
			str ..= tostring(playerobj.Name) .. ","
		end
	end

	str ..= "\npriority:"

	for k, v in next, menu.priority do
		local playerobj
		local userid
		local pass, ret = pcall(function()
			playerobj = Players[v]
		end)

		if not pass then
			local newpass, newret = pcall(function()
				userid = v
			end)
		end

		if userid then
			str ..= tostring(userid) .. ","
		else
			str ..= tostring(playerobj.Name) .. ","
		end
	end

	writefile("bitchbot/relations.bb", str)
end
CreateThread(function()
	if (not menu or not menu.GetVal) then
		repeat
			game.RunService.Heartbeat:Wait()
		until (menu and menu.GetVal)
	end
	wait(2)
	UnpackRelations()
	WriteRelations()
end)

local LOCAL_PLAYER = Players.LocalPlayer
local LOCAL_MOUSE = LOCAL_PLAYER:GetMouse()
local TEAMS = game:GetService("Teams")
local INPUT_SERVICE = game:GetService("UserInputService")
local GAME_SETTINGS = UserSettings():GetService("UserGameSettings")
local CACHED_VEC3 = Vector3.new()
local Camera = workspace.CurrentCamera
local SCREEN_SIZE = Camera.ViewportSize
local ButtonPressed = event.new("bb_buttonpressed")
local TogglePressed = event.new("bb_togglepressed")
local MouseMoved = event.new("bb_mousemoved")

menu.x = math.floor((SCREEN_SIZE.x / 2) - (menu.w / 2))
menu.y = math.floor((SCREEN_SIZE.y / 2) - (menu.h / 2))

local Lerp = function(delta, from, to) -- wtf why were these globals thats so exploitable!
	if (delta > 1) then
		return to
	end
	if (delta < 0) then
		return from
	end
	return from + (to - from) * delta
end

local ColorRange = function(value, ranges) -- ty tony for dis function u a homie
	if value <= ranges[1].start then
		return ranges[1].color
	end
	if value >= ranges[#ranges].start then
		return ranges[#ranges].color
	end

	local selected = #ranges
	for i = 1, #ranges - 1 do
		if value < ranges[i + 1].start then
			selected = i
			break
		end
	end
	local minColor = ranges[selected]
	local maxColor = ranges[selected + 1]
	local lerpValue = (value - minColor.start) / (maxColor.start - minColor.start)
	return Color3.new(
		Lerp(lerpValue, minColor.color.r, maxColor.color.r),
		Lerp(lerpValue, minColor.color.g, maxColor.color.g),
		Lerp(lerpValue, minColor.color.b, maxColor.color.b)
	)
end

local bVector2 = {}
do -- vector functions
	function bVector2:getRotate(Vec, Rads)
		local vec = Vec.Unit
		--x2 = cos β x1 − sin β y1
		--y2 = sin β x1 + cos β y1
		local sin = math.sin(Rads)
		local cos = math.cos(Rads)
		local x = (cos * vec.x) - (sin * vec.y)
		local y = (sin * vec.x) + (cos * vec.y)

		return Vector2.new(x, y).Unit * Vec.Magnitude
	end
end
local bColor = {}
do -- color functions
	function bColor:Mult(col, mult)
		return Color3.new(col.R * mult, col.G * mult, col.B * mult)
	end
	function bColor:Add(col, num)
		return Color3.new(col.R + num, col.G + num, col.B + num)
	end
end
local function string_cut(s1, num)
	return num == 0 and s1 or string.sub(s1, 1, num)
end

local textBoxLetters = {
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
}

local keyNames = {
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Zero = "0",
	LeftBracket = "[",
	RightBracket = "]",
	Semicolon = ";",
	BackSlash = "\\",
	Slash = "/",
	Minus = "-",
	Equals = "=",
	Return = "Enter",
	Backquote = "`",
	CapsLock = "Caps",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	Backspace = "Back",
	Plus = "+",
	Multiply = "x",
	PageUp = "PgUp",
	PageDown = "PgDown",
	Delete = "Del",
	Insert = "Ins",
	NumLock = "NumL",
	Comma = ",",
	Period = ".",
}
local colemak = {
	E = "F",
	R = "P",
	T = "G",
	Y = "J",
	U = "L",
	I = "U",
	O = "Y",
	P = ";",
	S = "R",
	D = "S",
	F = "T",
	G = "D",
	J = "N",
	K = "E",
	L = "I",
	[";"] = "O",
	N = "K",
}

local keymodifiernames = {
	["`"] = "~",
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["\\"] = "|",
	[";"] = ":",
	["'"] = '"',
	[","] = "<",
	["."] = ".",
	["/"] = "?",
}

local function KeyEnumToName(key) -- did this all in a function cuz why not
	if key == nil then
		return "None"
	end
	local _key = tostring(key) .. "."
	local _key = _key:gsub("%.", ",")
	local keyname = nil
	local looptime = 0
	for w in _key:gmatch("(.-),") do
		looptime = looptime + 1
		if looptime == 3 then
			keyname = w
		end
	end
	if string.match(keyname, "Keypad") then
		keyname = string.gsub(keyname, "Keypad", "")
	end

	if keyname == "Unknown" or key.Value == 27 then
		return "None"
	end

	if keyNames[keyname] then
		keyname = keyNames[keyname]
	end
	if Nate then
		return colemak[keyname] or keyname
	else
		return keyname
	end
end

local invalidfilekeys = {
	["\\"] = true,
	["/"] = true,
	[":"] = true,
	["*"] = true,
	["?"] = true,
	['"'] = true,
	["<"] = true,
	[">"] = true,
	["|"] = true,
}

local function KeyModifierToName(key, filename)
	if keymodifiernames[key] ~= nil then
		if filename then
			if invalidfilekeys[keymodifiernames[key]] then
				return ""
			else
				return keymodifiernames[key]
			end
		else
			return keymodifiernames[key]
		end
	else
		return ""
	end
end

local allrender = {}

local RGB = Color3.fromRGB
local Draw = {}

do
	function Draw:UnRender()
		for k, v in pairs(allrender) do
			for k1, v1 in pairs(v) do
				--warn(k1, v1)
				-- ANCHOR WHAT THE FUCK IS GOING ON WITH THIS WHY IS THIS ERRORING BECAUSE OF NUMBER
				if v1 and type(v1) ~= "number" and v1.__OBJECT_EXISTS then
					v1:Remove()
				else
					--rconsolewarn(tostring(k),tostring(v),tostring(k1),tostring(v1)) -- idfk why but this shit doesn't print anything out. might as well have it commented out though -nata april 1 21
				end
			end
		end
	end

	function Draw:OutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
		local temptable = Drawing.new("Square")
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = Vector2.new(width, height)
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Filled = false
		temptable.Thickness = 0
		temptable.Transparency = clr[4] / 255
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:FilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
		local temptable = Drawing.new("Square")
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = Vector2.new(width, height)
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Filled = true
		temptable.Thickness = 0
		temptable.Transparency = clr[4] / 255
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Line(visible, thickness, start_x, start_y, end_x, end_y, clr, tablename)
		temptable = Drawing.new("Line")
		temptable.Visible = visible
		temptable.Thickness = thickness
		temptable.From = Vector2.new(start_x, start_y)
		temptable.To = Vector2.new(end_x, end_y)
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Transparency = clr[4] / 255
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Image(visible, imagedata, pos_x, pos_y, width, height, transparency, tablename)
		local temptable = Drawing.new("Image")
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = Vector2.new(width, height)
		temptable.Transparency = transparency
		temptable.Data = imagedata or placeholderImage
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Text(text, font, visible, pos_x, pos_y, size, centered, clr, tablename)
		local temptable = Drawing.new("Text")
		temptable.Text = text
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = size
		temptable.Center = centered
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Transparency = clr[4] / 255
		temptable.Outline = false
		temptable.Font = font
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:OutlinedText(text, font, visible, pos_x, pos_y, size, centered, clr, clr2, tablename)
		local temptable = Drawing.new("Text")
		temptable.Text = text
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = size
		temptable.Center = centered
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Transparency = clr[4] / 255
		temptable.Outline = true
		temptable.OutlineColor = RGB(clr2[1], clr2[2], clr2[3])
		temptable.Font = font
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
		if tablename then
			table.insert(tablename, temptable)
		end
		return temptable
	end

	function Draw:Triangle(visible, filled, pa, pb, pc, clr, tablename)
		clr = clr or { 255, 255, 255, 1 }
		local temptable = Drawing.new("Triangle")
		temptable.Visible = visible
		temptable.Transparency = clr[4] or 1
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Thickness = 4.1
		if pa and pb and pc then
			temptable.PointA = Vector2.new(pa[1], pa[2])
			temptable.PointB = Vector2.new(pb[1], pb[2])
			temptable.PointC = Vector2.new(pc[1], pc[2])
		end
		temptable.Filled = filled
		table.insert(tablename, temptable)
		if tablename and not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Circle(visible, pos_x, pos_y, size, thickness, sides, clr, tablename)
		local temptable = Drawing.new("Circle")
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Visible = visible
		temptable.Radius = size
		temptable.Thickness = thickness
		temptable.NumSides = sides
		temptable.Transparency = clr[4]
		temptable.Filled = false
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:FilledCircle(visible, pos_x, pos_y, size, thickness, sides, clr, tablename)
		local temptable = Drawing.new("Circle")
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Visible = visible
		temptable.Radius = size
		temptable.Thickness = thickness
		temptable.NumSides = sides
		temptable.Transparency = clr[4]
		temptable.Filled = true
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	--ANCHOR MENU ELEMENTS

	function Draw:MenuOutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:OutlinedRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end
	end

	function Draw:MenuFilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:FilledRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end
	end

	function Draw:MenuImage(visible, imagedata, pos_x, pos_y, width, height, transparency, tablename)
		Draw:Image(visible, imagedata, pos_x + menu.x, pos_y + menu.y, width, height, transparency, tablename)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end
	end

	function Draw:MenuBigText(text, visible, centered, pos_x, pos_y, tablename)
		local text = Draw:OutlinedText(
			text,
			2,
			visible,
			pos_x + menu.x,
			pos_y + menu.y,
			13,
			centered,
			{ 255, 255, 255, 255 },
			{ 0, 0, 0 },
			tablename
		)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end

		return text
	end

	function Draw:CoolBox(name, x, y, width, height, tab)
		Draw:MenuOutlinedRect(true, x, y, width, height, { 0, 0, 0, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, width - 2, height - 2, { 20, 20, 20, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 2, y + 2, width - 3, 1, { 127, 72, 163, 255 }, tab)
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 3, width - 3, 1, { 87, 32, 123, 255 }, tab)
		table.insert(menu.clrs.dark, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 4, width - 3, 1, { 20, 20, 20, 255 }, tab)

		for i = 0, 7 do
			Draw:MenuFilledRect(true, x + 2, y + 5 + (i * 2), width - 4, 2, { 45, 45, 45, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(45, 45, 45) }, [2] = { start = 7, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuBigText(name, true, false, x + 6, y + 5, tab)
	end

	function Draw:CoolMultiBox(names, x, y, width, height, tab)
		Draw:MenuOutlinedRect(true, x, y, width, height, { 0, 0, 0, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, width - 2, height - 2, { 20, 20, 20, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 2, y + 2, width - 3, 1, { 127, 72, 163, 255 }, tab)
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 3, width - 3, 1, { 87, 32, 123, 255 }, tab)
		table.insert(menu.clrs.dark, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 4, width - 3, 1, { 20, 20, 20, 255 }, tab)

		--{35, 35, 35, 255}

		Draw:MenuFilledRect(true, x + 2, y + 5, width - 4, 18, { 30, 30, 30, 255 }, tab)
		Draw:MenuFilledRect(true, x + 2, y + 21, width - 4, 2, { 20, 20, 20, 255 }, tab)

		local selected = {}
		for i = 0, 8 do
			Draw:MenuFilledRect(true, x + 2, y + 5 + (i * 2), width - 159, 2, { 45, 45, 45, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } }
			)
			table.insert(selected, { postable = #menu.postable, drawn = tab[#tab] })
		end

		local length = 2
		local selected_pos = {}
		local click_pos = {}
		local nametext = {}
		for i, v in ipairs(names) do
			Draw:MenuBigText(v, true, false, x + 4 + length, y + 5, tab)
			if i == 1 then
				tab[#tab].Color = RGB(255, 255, 255)
			else
				tab[#tab].Color = RGB(170, 170, 170)
			end
			table.insert(nametext, tab[#tab])

			Draw:MenuFilledRect(true, x + length + tab[#tab].TextBounds.X + 8, y + 5, 2, 16, { 20, 20, 20, 255 }, tab)
			table.insert(selected_pos, { pos = x + length, length = tab[#tab - 1].TextBounds.X + 8 })
			table.insert(click_pos, {
				x = x + length,
				y = y + 5,
				width = tab[#tab - 1].TextBounds.X + 8,
				height = 18,
				name = v,
				num = i,
			})
			length += tab[#tab - 1].TextBounds.X + 10
		end

		local settab = 1
		for k, v in pairs(selected) do
			menu.postable[v.postable][2] = selected_pos[settab].pos
			v.drawn.Size = Vector2.new(selected_pos[settab].length, 2)
		end

		return { bar = selected, barpos = selected_pos, click_pos = click_pos, nametext = nametext }

		--Draw:MenuBigText(str, true, false, x + 6, y + 5, tab)
	end

	function Draw:Toggle(name, value, unsafe, x, y, tab)
		Draw:MenuOutlinedRect(true, x, y, 12, 12, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, 10, 10, { 0, 0, 0, 255 }, tab)

		local temptable = {}
		for i = 0, 3 do
			Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), 8, 2, { 0, 0, 0, 255 }, tab)
			table.insert(temptable, tab[#tab])
			if value then
				tab[#tab].Color = ColorRange(i, {
					[1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) },
					[2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) },
				})
			else
				tab[#tab].Color = ColorRange(i, {
					[1] = { start = 0, color = RGB(50, 50, 50) },
					[2] = { start = 3, color = RGB(30, 30, 30) },
				})
			end
		end

		Draw:MenuBigText(name, true, false, x + 16, y - 1, tab)
		if unsafe == true then
			tab[#tab].Color = RGB(90, 90, 90)
		end
		table.insert(temptable, tab[#tab])
		return temptable
	end

	function Draw:Keybind(key, x, y, tab)
		local temptable = {}
		Draw:MenuFilledRect(true, x, y, 44, 16, { 25, 25, 25, 255 }, tab)
		Draw:MenuBigText(KeyEnumToName(key), true, true, x + 22, y + 1, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x, y, 44, 16, { 30, 30, 30, 255 }, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 1, y + 1, 42, 14, { 0, 0, 0, 255 }, tab)

		return temptable
	end

	function Draw:ColorPicker(color, x, y, tab)
		local temptable = {}

		Draw:MenuOutlinedRect(true, x, y, 28, 14, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, 26, 12, { 0, 0, 0, 255 }, tab)

		Draw:MenuFilledRect(true, x + 2, y + 2, 24, 10, { color[1], color[2], color[3], 255 }, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 2, 24, 10, { color[1] - 40, color[2] - 40, color[3] - 40, 255 }, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 3, y + 3, 22, 8, { color[1] - 40, color[2] - 40, color[3] - 40, 255 }, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:Slider(name, stradd, value, minvalue, maxvalue, customvals, rounded, x, y, length, tab)
		Draw:MenuBigText(name, true, false, x, y - 3, tab)

		for i = 0, 3 do
			Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 3, color = RGB(30, 30, 30) } }
			)
		end

		local temptable = {}
		for i = 0, 3 do
			Draw:MenuFilledRect(
				true,
				x + 2,
				y + 14 + (i * 2),
				(length - 4) * ((value - minvalue) / (maxvalue - minvalue)),
				2,
				{ 0, 0, 0, 255 },
				tab
			)
			table.insert(temptable, tab[#tab])
			tab[#tab].Color = ColorRange(i, {
				[1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) },
				[2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) },
			})
		end
		Draw:MenuOutlinedRect(true, x, y + 12, length, 12, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 10, { 0, 0, 0, 255 }, tab)

		local textstr = ""

		if stradd == nil then
			stradd = ""
		end

		local decplaces = rounded and string.rep("0", math.log(1 / rounded) / math.log(10)) or 1
		if rounded and value == math.floor(value * decplaces) then
			textstr = tostring(value) .. "." .. decplaces .. stradd
		else
			textstr = tostring(value) .. stradd
		end

		Draw:MenuBigText(customvals[value] or textstr, true, true, x + (length * 0.5), y + 11, tab)
		table.insert(temptable, tab[#tab])
		table.insert(temptable, stradd)
		return temptable
	end

	function Draw:Dropbox(name, value, values, x, y, length, tab)
		local temptable = {}
		Draw:MenuBigText(name, true, false, x, y - 3, tab)

		for i = 0, 7 do
			Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 7, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuOutlinedRect(true, x, y + 12, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 20, { 0, 0, 0, 255 }, tab)

		Draw:MenuBigText(tostring(values[value]), true, false, x + 6, y + 16, tab)
		table.insert(temptable, tab[#tab])

		Draw:MenuBigText("-", true, false, x - 17 + length, y + 16, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:Combobox(name, values, x, y, length, tab)
		local temptable = {}
		Draw:MenuBigText(name, true, false, x, y - 3, tab)

		for i = 0, 7 do
			Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 7, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuOutlinedRect(true, x, y + 12, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 20, { 0, 0, 0, 255 }, tab)
		local textthing = ""
		for k, v in pairs(values) do
			if v[2] then
				if textthing == "" then
					textthing = v[1]
				else
					textthing ..= ", " .. v[1]
				end
			end
		end
		if string.len(textthing) > 25 then
			textthing = string_cut(textthing, 25)
		end
		textthing = textthing ~= "" and textthing or "None"
		Draw:MenuBigText(textthing, true, false, x + 6, y + 16, tab)
		table.insert(temptable, tab[#tab])

		Draw:MenuBigText("...", true, false, x - 27 + length, y + 16, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:Button(name, x, y, length, tab)
		local temptable = {}

		for i = 0, 8 do
			Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } }
			)
			table.insert(temptable, tab[#tab])
		end

		Draw:MenuOutlinedRect(true, x, y, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, length - 2, 20, { 0, 0, 0, 255 }, tab)
		temptable.text = Draw:MenuBigText(name, true, true, x + math.floor(length * 0.5), y + 4, tab)

		return temptable
	end

	function Draw:List(name, x, y, length, maxamount, columns, tab)
		local temptable = { uparrow = {}, downarrow = {}, liststuff = { rows = {}, words = {} } }

		for i, v in ipairs(name) do
			Draw:MenuBigText(
				v,
				true,
				false,
				(math.floor(length / columns) * i) - math.floor(length / columns) + 30,
				y - 3,
				tab
			)
		end

		Draw:MenuOutlinedRect(true, x, y + 12, length, 22 * maxamount + 4, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 22 * maxamount + 2, { 0, 0, 0, 255 }, tab)

		Draw:MenuFilledRect(true, x + length - 7, y + 16, 1, 1, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, tab)
		table.insert(temptable.uparrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(true, x + length - 8, y + 17, 3, 1, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, tab)
		table.insert(temptable.uparrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(true, x + length - 9, y + 18, 5, 1, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, tab)
		table.insert(temptable.uparrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])

		Draw:MenuFilledRect(
			true,
			x + length - 7,
			y + 16 + (22 * maxamount + 4) - 9,
			1,
			1,
			{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
			tab
		)
		table.insert(temptable.downarrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(
			true,
			x + length - 8,
			y + 16 + (22 * maxamount + 4) - 10,
			3,
			1,
			{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
			tab
		)
		table.insert(temptable.downarrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(
			true,
			x + length - 9,
			y + 16 + (22 * maxamount + 4) - 11,
			5,
			1,
			{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
			tab
		)
		table.insert(temptable.downarrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])

		for i = 1, maxamount do
			temptable.liststuff.rows[i] = {}
			if i ~= maxamount then
				Draw:MenuOutlinedRect(true, x + 4, (y + 13) + (22 * i), length - 8, 2, { 20, 20, 20, 255 }, tab)
				table.insert(temptable.liststuff.rows[i], tab[#tab])
			end

			if columns ~= nil then
				for i1 = 1, columns - 1 do
					Draw:MenuOutlinedRect(
						true,
						x + math.floor(length / columns) * i1,
						(y + 13) + (22 * i) - 18,
						2,
						16,
						{ 20, 20, 20, 255 },
						tab
					)
					table.insert(temptable.liststuff.rows[i], tab[#tab])
				end
			end

			temptable.liststuff.words[i] = {}
			if columns ~= nil then
				for i1 = 1, columns do
					Draw:MenuBigText(
						"",
						true,
						false,
						(x + math.floor(length / columns) * i1) - math.floor(length / columns) + 5,
						(y + 13) + (22 * i) - 16,
						tab
					)
					table.insert(temptable.liststuff.words[i], tab[#tab])
				end
			else
				Draw:MenuBigText("", true, false, x + 5, (y + 13) + (22 * i) - 16, tab)
				table.insert(temptable.liststuff.words[i], tab[#tab])
			end
		end

		return temptable
	end

	function Draw:ImageWithText(size, image, text, x, y, tab)
		local temptable = {}
		Draw:MenuOutlinedRect(true, x, y, size + 4, size + 4, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, size + 2, size + 2, { 0, 0, 0, 255 }, tab)
		Draw:MenuFilledRect(true, x + 2, y + 2, size, size, { 40, 40, 40, 255 }, tab)

		Draw:MenuBigText(text, true, false, x + size + 8, y, tab)
		table.insert(temptable, tab[#tab])

		Draw:MenuImage(true, BBOT_IMAGES[5], x + 2, y + 2, size, size, 1, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:TextBox(name, text, x, y, length, tab)
		for i = 0, 8 do
			Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuOutlinedRect(true, x, y, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, length - 2, 20, { 0, 0, 0, 255 }, tab)
		Draw:MenuBigText(text, true, false, x + 6, y + 4, tab)

		return tab[#tab]
	end
end

-- finish

local loadingthing = Draw:OutlinedText(
	"Loading...",
	2,
	true,
	math.floor(SCREEN_SIZE.x / 16),
	math.floor(SCREEN_SIZE.y / 16),
	13,
	true,
	{ 255, 50, 200, 255 },
	{ 0, 0, 0 }
)

function menu.Initialize(menutable)
	local bbmenu = {} -- this one is for the rendering n shi
	do
		Draw:MenuOutlinedRect(true, 0, 0, menu.w, menu.h, { 0, 0, 0, 255 }, bbmenu) -- first gradent or whatever
		Draw:MenuOutlinedRect(true, 1, 1, menu.w - 2, menu.h - 2, { 20, 20, 20, 255 }, bbmenu)
		Draw:MenuOutlinedRect(true, 2, 2, menu.w - 3, 1, { 127, 72, 163, 255 }, bbmenu)
		table.insert(menu.clrs.norm, bbmenu[#bbmenu])
		Draw:MenuOutlinedRect(true, 2, 3, menu.w - 3, 1, { 87, 32, 123, 255 }, bbmenu)
		table.insert(menu.clrs.dark, bbmenu[#bbmenu])
		Draw:MenuOutlinedRect(true, 2, 4, menu.w - 3, 1, { 20, 20, 20, 255 }, bbmenu)

		for i = 0, 19 do
			Draw:MenuFilledRect(true, 2, 5 + i, menu.w - 4, 1, { 20, 20, 20, 255 }, bbmenu)
			bbmenu[6 + i].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 20, color = RGB(35, 35, 35) } }
			)
		end
		Draw:MenuFilledRect(true, 2, 25, menu.w - 4, menu.h - 27, { 35, 35, 35, 255 }, bbmenu)

		Draw:MenuBigText(MenuName or "Bitch Bot", true, false, 6, 6, bbmenu)

		Draw:MenuOutlinedRect(true, 8, 22, menu.w - 16, menu.h - 30, { 0, 0, 0, 255 }, bbmenu) -- all this shit does the 2nd gradent
		Draw:MenuOutlinedRect(true, 9, 23, menu.w - 18, menu.h - 32, { 20, 20, 20, 255 }, bbmenu)
		Draw:MenuOutlinedRect(true, 10, 24, menu.w - 19, 1, { 127, 72, 163, 255 }, bbmenu)
		table.insert(menu.clrs.norm, bbmenu[#bbmenu])
		Draw:MenuOutlinedRect(true, 10, 25, menu.w - 19, 1, { 87, 32, 123, 255 }, bbmenu)
		table.insert(menu.clrs.dark, bbmenu[#bbmenu])
		Draw:MenuOutlinedRect(true, 10, 26, menu.w - 19, 1, { 20, 20, 20, 255 }, bbmenu)

		for i = 0, 14 do
			Draw:MenuFilledRect(true, 10, 27 + (i * 2), menu.w - 20, 2, { 45, 45, 45, 255 }, bbmenu)
			bbmenu[#bbmenu].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 15, color = RGB(35, 35, 35) } }
			)
		end
		Draw:MenuFilledRect(true, 10, 57, menu.w - 20, menu.h - 67, { 35, 35, 35, 255 }, bbmenu)
	end
	-- ok now the cool part :D
	--ANCHOR menu stuffz

	local tabz = {}
	for i = 1, #menutable do
		tabz[i] = {}
	end

	local tabs = {} -- i like tabby catz 🐱🐱🐱

	menu.multigroups = {}

	for k, v in pairs(menutable) do
		Draw:MenuFilledRect(
			true,
			10 + ((k - 1) * ((menu.w - 20) / #menutable)),
			27,
			((menu.w - 20) / #menutable),
			32,
			{ 30, 30, 30, 255 },
			bbmenu
		)
		Draw:MenuOutlinedRect(
			true,
			10 + ((k - 1) * ((menu.w - 20) / #menutable)),
			27,
			((menu.w - 20) / #menutable),
			32,
			{ 20, 20, 20, 255 },
			bbmenu
		)
		Draw:MenuBigText(
			v.name,
			true,
			true,
			math.floor(10 + ((k - 1) * ((menu.w - 20) / #menutable)) + (((menu.w - 20) / #menutable) * 0.5)),
			35,
			bbmenu
		)
		table.insert(tabs, { bbmenu[#bbmenu - 2], bbmenu[#bbmenu - 1], bbmenu[#bbmenu] })
		table.insert(menu.tabnames, v.name)

		menu.options[v.name] = {}
		menu.multigroups[v.name] = {}
		menu.mgrouptabz[v.name] = {}

		local y_offies = { left = 66, right = 66 }
		if v.content ~= nil then
			for k1, v1 in pairs(v.content) do
				if v1.autopos ~= nil then
					v1.width = menu.columns.width
					if v1.autopos == "left" then
						v1.x = menu.columns.left
						v1.y = y_offies.left
					elseif v1.autopos == "right" then
						v1.x = menu.columns.right
						v1.y = y_offies.right
					end
				end

				local groups = {}

				if type(v1.name) == "table" then
					groups = v1.name
				else
					table.insert(groups, v1.name)
				end

				local y_pos = 24

				for g_ind, g_name in ipairs(groups) do
					menu.options[v.name][g_name] = {}
					if type(v1.name) == "table" then
						menu.mgrouptabz[v.name][g_name] = {}
						menu.log_multi = { v.name, g_name }
					end

					local content = nil
					if type(v1.name) == "table" then
						y_pos = 28
						content = v1[g_ind].content
					else
						y_pos = 24
						content = v1.content
					end

					if content ~= nil then
						for k2, v2 in pairs(content) do
							if v2.type == "toggle" then
								menu.options[v.name][g_name][v2.name] = {}
								local unsafe = false
								if v2.unsafe then
									unsafe = true
								end
								menu.options[v.name][g_name][v2.name][4] = Draw:Toggle(v2.name, v2.value, unsafe, v1.x + 8, v1.y + y_pos, tabz[k])
								menu.options[v.name][g_name][v2.name][1] = v2.value
								menu.options[v.name][g_name][v2.name][7] = v2.value
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1 }
								menu.options[v.name][g_name][v2.name][6] = unsafe
								menu.options[v.name][g_name][v2.name].tooltip = v2.tooltip or nil
								if v2.extra ~= nil then
									if v2.extra.type == "keybind" then
										menu.options[v.name][g_name][v2.name][5] = {}
										menu.options[v.name][g_name][v2.name][5][4] = Draw:Keybind(
											v2.extra.key,
											v1.x + v1.width - 52,
											y_pos + v1.y - 2,
											tabz[k]
										)
										menu.options[v.name][g_name][v2.name][5][1] = v2.extra.key
										menu.options[v.name][g_name][v2.name][5][2] = v2.extra.type
										menu.options[v.name][g_name][v2.name][5][3] = { v1.x + v1.width - 52, y_pos + v1.y - 2 }
										menu.options[v.name][g_name][v2.name][5][5] = false
										menu.options[v.name][g_name][v2.name][5].toggletype = v2.extra.toggletype == nil and 1 or v2.extra.toggletype
										menu.options[v.name][g_name][v2.name][5].relvalue = false
										local event = event.new(("%s %s %s"):format(v.name, g_name, v2.name))
										event:connect(function(newval) 
											if menu:GetVal("Visuals", "Keybinds" ,"Log Keybinds") then 
												CreateNotification(("%s %s %s has been set to %s"):format(v.name, g_name, v2.name, newval and "true" or "false")) 
											end 
										end)
										menu.options[v.name][g_name][v2.name][5].event = event
										menu.options[v.name][g_name][v2.name][5].bind = table.insert(menu.keybinds, {
												menu.options[v.name][g_name][v2.name],
												tostring(v2.name),
												tostring(g_name),
												tostring(v.name),
											})
									elseif v2.extra.type == "single colorpicker" then
										menu.options[v.name][g_name][v2.name][5] = {}
										menu.options[v.name][g_name][v2.name][5][4] = Draw:ColorPicker(
											v2.extra.color,
											v1.x + v1.width - 38,
											y_pos + v1.y - 1,
											tabz[k]
										)
										menu.options[v.name][g_name][v2.name][5][1] = v2.extra.color
										menu.options[v.name][g_name][v2.name][5][2] = v2.extra.type
										menu.options[v.name][g_name][v2.name][5][3] = { v1.x + v1.width - 38, y_pos + v1.y - 1 }
										menu.options[v.name][g_name][v2.name][5][5] = false
										menu.options[v.name][g_name][v2.name][5][6] = v2.extra.name
									elseif v2.extra.type == "double colorpicker" then
										menu.options[v.name][g_name][v2.name][5] = {}
										menu.options[v.name][g_name][v2.name][5][1] = {}
										menu.options[v.name][g_name][v2.name][5][1][1] = {}
										menu.options[v.name][g_name][v2.name][5][1][2] = {}
										menu.options[v.name][g_name][v2.name][5][2] = v2.extra.type
										for i = 1, 2 do
											menu.options[v.name][g_name][v2.name][5][1][i][4] = Draw:ColorPicker(
												v2.extra.color[i],
												v1.x + v1.width - 38 - ((i - 1) * 34),
												y_pos + v1.y - 1,
												tabz[k]
											)
											menu.options[v.name][g_name][v2.name][5][1][i][1] = v2.extra.color[i]
											menu.options[v.name][g_name][v2.name][5][1][i][3] = { v1.x + v1.width - 38 - ((i - 1) * 34), y_pos + v1.y - 1 }
											menu.options[v.name][g_name][v2.name][5][1][i][5] = false
											menu.options[v.name][g_name][v2.name][5][1][i][6] = v2.extra.name[i]
										end
									end
								end
								y_pos += 18
							elseif v2.type == "slider" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][4] = Draw:Slider(
									v2.name,
									v2.stradd,
									v2.value,
									v2.minvalue,
									v2.maxvalue,
									v2.custom or {},
									v2.decimal,
									v1.x + 8,
									v1.y + y_pos,
									v1.width - 16,
									tabz[k]
								)
								menu.options[v.name][g_name][v2.name][1] = v2.value
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
								menu.options[v.name][g_name][v2.name][5] = false
								menu.options[v.name][g_name][v2.name][6] = { v2.minvalue, v2.maxvalue }
								menu.options[v.name][g_name][v2.name][7] = { v1.x + 7 + v1.width - 38, v1.y + y_pos - 1 }
								menu.options[v.name][g_name][v2.name].decimal = v2.decimal == nil and nil or v2.decimal
								menu.options[v.name][g_name][v2.name].stepsize = v2.stepsize
								menu.options[v.name][g_name][v2.name].custom = v2.custom or {}

								y_pos += 30
							elseif v2.type == "dropbox" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][1] = v2.value
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name][5] = false
								menu.options[v.name][g_name][v2.name][6] = v2.values

								if v2.x == nil then
									menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
									menu.options[v.name][g_name][v2.name][4] = Draw:Dropbox(
										v2.name,
										v2.value,
										v2.values,
										v1.x + 8,
										v1.y + y_pos,
										v1.width - 16,
										tabz[k]
									)
									y_pos += 40
								else
									menu.options[v.name][g_name][v2.name][3] = { v2.x + 7, v2.y - 1, v2.w }
									menu.options[v.name][g_name][v2.name][4] = Draw:Dropbox(v2.name, v2.value, v2.values, v2.x + 8, v2.y, v2.w, tabz[k])
								end
							elseif v2.type == "combobox" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][4] = Draw:Combobox(
										v2.name,
										v2.values,
										v1.x + 8,
										v1.y + y_pos,
										v1.width - 16,
										tabz[k]
									)
								menu.options[v.name][g_name][v2.name][1] = v2.values
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
								menu.options[v.name][g_name][v2.name][5] = false
								y_pos += 40
							elseif v2.type == "button" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][1] = false
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name].name = v2.name
								menu.options[v.name][g_name][v2.name].groupbox = g_name
								menu.options[v.name][g_name][v2.name].tab = v.name -- why is it all v, v1, v2 so ugly
								menu.options[v.name][g_name][v2.name].doubleclick = v2.doubleclick

								if v2.x == nil then
									menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
									menu.options[v.name][g_name][v2.name][4] = Draw:Button(v2.name, v1.x + 8, v1.y + y_pos, v1.width - 16, tabz[k])
									y_pos += 28
								else
									menu.options[v.name][g_name][v2.name][3] = { v2.x + 7, v2.y - 1, v2.w }
									menu.options[v.name][g_name][v2.name][4] = Draw:Button(v2.name, v2.x + 8, v2.y, v2.w, tabz[k])
								end
							elseif v2.type == "textbox" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][4] = Draw:TextBox(v2.name, v2.text, v1.x + 8, v1.y + y_pos, v1.width - 16, tabz[k])
								menu.options[v.name][g_name][v2.name][1] = v2.text
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name][3] = { v1.x + 7, v1.y + y_pos - 1, v1.width - 16 }
								menu.options[v.name][g_name][v2.name][5] = false
								menu.options[v.name][g_name][v2.name][6] = v2.file and true or false
								y_pos += 28
							elseif v2.type == "list" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][4] = Draw:List(
									v2.multiname,
									v1.x + 8,
									v1.y + y_pos,
									v1.width - 16,
									v2.size,
									v2.columns,
									tabz[k]
								)
								menu.options[v.name][g_name][v2.name][1] = nil
								menu.options[v.name][g_name][v2.name][2] = v2.type
								menu.options[v.name][g_name][v2.name][3] = 1
								menu.options[v.name][g_name][v2.name][5] = {}
								menu.options[v.name][g_name][v2.name][6] = v2.size
								menu.options[v.name][g_name][v2.name][7] = v2.columns
								menu.options[v.name][g_name][v2.name][8] = { v1.x + 8, v1.y + y_pos, v1.width - 16 }
								y_pos += 22 + (22 * v2.size)
							elseif v2.type == "image" then
								menu.options[v.name][g_name][v2.name] = {}
								menu.options[v.name][g_name][v2.name][1] = Draw:ImageWithText(v2.size, nil, v2.text, v1.x + 8, v1.y + y_pos, tabz[k])
								menu.options[v.name][g_name][v2.name][2] = v2.type
							end
						end
					end

					menu.log_multi = nil
				end

				y_pos += 2

				if type(v1.name) ~= "table" then
					if v1.autopos == nil then
						Draw:CoolBox(v1.name, v1.x, v1.y, v1.width, v1.height, tabz[k])
					else
						if v1.autofill then
							y_pos = (menu.h - 17) - v1.y
						elseif v1.size ~= nil then
							y_pos = v1.size
						end
						Draw:CoolBox(v1.name, v1.x, v1.y, v1.width, y_pos, tabz[k])
						y_offies[v1.autopos] += y_pos + 6
					end
				else
					if v1.autofill then
						y_pos = (menu.h - 17) - v1.y
						y_offies[v1.autopos] += y_pos + 6
					elseif v1.size ~= nil then
						y_pos = v1.size
						y_offies[v1.autopos] += y_pos + 6
					end

					local drawn

					if v1.autopos == nil then
						drawn = Draw:CoolMultiBox(v1.name, v1.x, v1.y, v1.width, v1.height, tabz[k])
					else
						drawn = Draw:CoolMultiBox(v1.name, v1.x, v1.y, v1.width, y_pos, tabz[k])
					end

					local group_vals = {}

					for _i, _v in ipairs(v1.name) do
						if _i == 1 then
							group_vals[_v] = true
						else
							group_vals[_v] = false
						end
					end
					table.insert(menu.multigroups[v.name], { vals = group_vals, drawn = drawn })
				end
			end
		end
	end

	menu.list.addval = function(list, option)
		table.insert(list[5], option)
	end

	menu.list.removeval = function(list, optionnum)
		if list[1] == optionnum then
			list[1] = nil
		end
		table.remove(list[5], optionnum)
	end

	menu.list.removeall = function(list)
		list[5] = {}
		for k, v in pairs(list[4].liststuff) do
			for i, v1 in ipairs(v) do
				for i1, v2 in ipairs(v1) do
					v2.Visible = false
				end
			end
		end
	end

	menu.list.setval = function(list, value)
		list[1] = value
	end

	Draw:MenuOutlinedRect(true, 10, 59, menu.w - 20, menu.h - 69, { 20, 20, 20, 255 }, bbmenu)

	Draw:MenuOutlinedRect(true, 11, 58, ((menu.w - 20) / #menutable) - 2, 2, { 35, 35, 35, 255 }, bbmenu)
	local barguy = { bbmenu[#bbmenu], menu.postable[#menu.postable] }

	local function setActiveTab(slot)
		barguy[1].Position = Vector2.new(
			(menu.x + 11 + ((((menu.w - 20) / #menutable) - 2) * (slot - 1))) + ((slot - 1) * 2),
			menu.y + 58
		)
		barguy[2][2] = (11 + ((((menu.w - 20) / #menutable) - 2) * (slot - 1))) + ((slot - 1) * 2)
		barguy[2][3] = 58

		for k, v in pairs(tabs) do
			if k == slot then
				v[1].Visible = false
				v[3].Color = RGB(255, 255, 255)
			else
				v[3].Color = RGB(170, 170, 170)
				v[1].Visible = true
			end
		end

		for k, v in pairs(tabz) do
			if k == slot then
				for k1, v1 in pairs(v) do
					v1.Visible = true
				end
			else
				for k1, v1 in pairs(v) do
					v1.Visible = false
				end
			end
		end

		for k, v in pairs(menu.multigroups) do
			if menu.tabnames[menu.activetab] == k then
				for k1, v1 in pairs(v) do
					for k2, v2 in pairs(v1.vals) do
						for k3, v3 in pairs(menu.mgrouptabz[k][k2]) do
							v3.Visible = v2
						end
					end
				end
			end
		end
	end

	setActiveTab(menu.activetab)

	local plusminus = {}

	Draw:OutlinedText("_", 1, false, 10, 10, 14, false, { 225, 225, 225, 255 }, { 20, 20, 20 }, plusminus)
	Draw:OutlinedText("+", 1, false, 10, 10, 14, false, { 225, 225, 225, 255 }, { 20, 20, 20 }, plusminus)

	local function set_plusminus(value, x, y)
		for i, v in ipairs(plusminus) do
			if value == 0 then
				v.Visible = false
			else
				v.Visible = true
			end
		end

		if value ~= 0 then
			plusminus[1].Position = Vector2.new(x + 3 + menu.x, y - 5 + menu.y)
			plusminus[2].Position = Vector2.new(x + 13 + menu.x, y - 1 + menu.y)

			if value == 1 then
				for i, v in ipairs(plusminus) do
					v.Color = RGB(225, 225, 225)
					v.OutlineColor = RGB(20, 20, 20)
				end
			else
				for i, v in ipairs(plusminus) do
					if i + 1 == value then
						v.Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
					else
						v.Color = RGB(255, 255, 255)
					end
					v.OutlineColor = RGB(0, 0, 0)
				end
			end
		end
	end

	set_plusminus(0, 20, 20)

	--DROP BOX THINGY
	local dropboxthingy = {}
	local dropboxtexty = {}

	Draw:OutlinedRect(false, 20, 20, 100, 22, { 20, 20, 20, 255 }, dropboxthingy)
	Draw:OutlinedRect(false, 21, 21, 98, 20, { 0, 0, 0, 255 }, dropboxthingy)
	Draw:FilledRect(false, 22, 22, 96, 18, { 45, 45, 45, 255 }, dropboxthingy)

	for i = 1, 30 do
		Draw:OutlinedText("", 2, false, 20, 20, 13, false, { 255, 255, 255, 255 }, { 0, 0, 0 }, dropboxtexty)
	end

	local function set_dropboxthingy(visible, x, y, length, value, values)
		for k, v in pairs(dropboxthingy) do
			v.Visible = visible
		end

		dropboxthingy[1].Position = Vector2.new(x, y)
		dropboxthingy[2].Position = Vector2.new(x + 1, y + 1)
		dropboxthingy[3].Position = Vector2.new(x + 2, y + 22)

		dropboxthingy[1].Size = Vector2.new(length, 21 * (#values + 1) + 3)
		dropboxthingy[2].Size = Vector2.new(length - 2, (21 * (#values + 1)) + 1)
		dropboxthingy[3].Size = Vector2.new(length - 4, (21 * #values) + 1 - 1)

		if visible then
			for i = 1, #values do
				dropboxtexty[i].Position = Vector2.new(x + 6, y + 26 + ((i - 1) * 21))
				dropboxtexty[i].Visible = true
				dropboxtexty[i].Text = values[i]
				if i == value then
					dropboxtexty[i].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
				else
					dropboxtexty[i].Color = RGB(255, 255, 255)
				end
			end
		else
			for k, v in pairs(dropboxtexty) do
				v.Visible = false
			end
		end
	end

	local function set_comboboxthingy(visible, x, y, length, values)
		for k, v in pairs(dropboxthingy) do
			v.Visible = visible
		end

		dropboxthingy[1].Position = Vector2.new(x, y)
		dropboxthingy[2].Position = Vector2.new(x + 1, y + 1)
		dropboxthingy[3].Position = Vector2.new(x + 2, y + 22)

		dropboxthingy[1].Size = Vector2.new(length, 22 * (#values + 1) + 2)
		dropboxthingy[2].Size = Vector2.new(length - 2, (22 * (#values + 1)))
		dropboxthingy[3].Size = Vector2.new(length - 4, (22 * #values))

		if visible then
			for i = 1, #values do
				dropboxtexty[i].Position = Vector2.new(x + 6, y + 26 + ((i - 1) * 22))
				dropboxtexty[i].Visible = true
				dropboxtexty[i].Text = values[i][1]
				if values[i][2] then
					dropboxtexty[i].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
				else
					dropboxtexty[i].Color = RGB(255, 255, 255)
				end
			end
		else
			for k, v in pairs(dropboxtexty) do
				v.Visible = false
			end
		end
	end

	set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })

	--MODE SELECT THING
	local modeselect = {}

	Draw:OutlinedRect(false, 20, 20, 100, 22, { 20, 20, 20, 255 }, modeselect)
	Draw:OutlinedRect(false, 21, 21, 98, 20, { 0, 0, 0, 255 }, modeselect)
	Draw:FilledRect(false, 22, 22, 96, 18, { 45, 45, 45, 255 }, modeselect)

	local modeselecttext = { "Hold", "Toggle", "Hold Off", "Always" }
	for i = 1, 4 do
		Draw:OutlinedText(
			modeselecttext[i],
			2,
			false,
			20,
			20,
			13,
			false,
			{ 255, 255, 255, 255 },
			{ 0, 0, 0 },
			modeselect
		)
	end

	local function set_modeselect(visible, x, y, value)
		for k, v in pairs(modeselect) do
			v.Visible = visible
		end

		if visible then
			modeselect[1].Position = Vector2.new(x, y)
			modeselect[2].Position = Vector2.new(x + 1, y + 1)
			modeselect[3].Position = Vector2.new(x + 2, y + 2)

			modeselect[1].Size = Vector2.new(70, 22 * 4 - 1)
			modeselect[2].Size = Vector2.new(70 - 2, 22 * 4 - 3)
			modeselect[3].Size = Vector2.new(70 - 4, 22 * 4 - 5)

			for i = 1, 4 do
				modeselect[i + 3].Position = Vector2.new(x + 6, y + 4 + ((i - 1) * 21))
				if value == i then
					modeselect[i + 3].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
				else
					modeselect[i + 3].Color = RGB(255, 255, 255)
				end
			end
		end
	end

	set_modeselect(false, 200, 400, 1)

	--COLOR PICKER
	local cp = {
		x = 400,
		y = 40,
		w = 280,
		h = 211,
		alpha = false,
		dragging_m = false,
		dragging_r = false,
		dragging_b = false,
		hsv = {
			h = 0,
			s = 0,
			v = 0,
			a = 0,
		},
		postable = {},
		drawings = {},
	}

	local function ColorpickerOutline(visible, pos_x, pos_y, width, height, clr, tablename) -- doing all this shit to make it easier for me to make this beat look nice and shit ya fell dog :dog_head:
		Draw:OutlinedRect(visible, pos_x + cp.x, pos_y + cp.y, width, height, clr, tablename)
		table.insert(cp.postable, { tablename[#tablename], pos_x, pos_y })
	end

	local function ColorpickerRect(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:FilledRect(visible, pos_x + cp.x, pos_y + cp.y, width, height, clr, tablename)
		table.insert(cp.postable, { tablename[#tablename], pos_x, pos_y })
	end

	local function ColorpickerImage(visible, imagedata, pos_x, pos_y, width, height, transparency, tablename)
		Draw:Image(visible, imagedata, pos_x, pos_y, width, height, transparency, tablename)
		table.insert(cp.postable, { tablename[#tablename], pos_x, pos_y })
	end

	local function ColorpickerText(text, visible, centered, pos_x, pos_y, tablename)
		Draw:OutlinedText(
			text,
			2,
			visible,
			pos_x + cp.x,
			pos_y + cp.y,
			13,
			centered,
			{ 255, 255, 255, 255 },
			{ 0, 0, 0 },
			tablename
		)
		table.insert(cp.postable, { tablename[#tablename], pos_x, pos_y })
	end

	ColorpickerRect(false, 1, 1, cp.w, cp.h, { 35, 35, 35, 255 }, cp.drawings)
	ColorpickerOutline(false, 1, 1, cp.w, cp.h, { 0, 0, 0, 255 }, cp.drawings)
	ColorpickerOutline(false, 2, 2, cp.w - 2, cp.h - 2, { 20, 20, 20, 255 }, cp.drawings)
	ColorpickerOutline(false, 3, 3, cp.w - 3, 1, { 127, 72, 163, 255 }, cp.drawings)
	table.insert(menu.clrs.norm, cp.drawings[#cp.drawings])
	ColorpickerOutline(false, 3, 4, cp.w - 3, 1, { 87, 32, 123, 255 }, cp.drawings)
	table.insert(menu.clrs.dark, cp.drawings[#cp.drawings])
	ColorpickerOutline(false, 3, 5, cp.w - 3, 1, { 20, 20, 20, 255 }, cp.drawings)
	ColorpickerText("color picker :D", false, false, 7, 6, cp.drawings)

	ColorpickerText("x", false, false, 268, 4, cp.drawings)

	ColorpickerOutline(false, 10, 23, 160, 160, { 30, 30, 30, 255 }, cp.drawings)
	ColorpickerOutline(false, 11, 24, 158, 158, { 0, 0, 0, 255 }, cp.drawings)
	ColorpickerRect(false, 12, 25, 156, 156, { 0, 0, 0, 255 }, cp.drawings)
	local maincolor = cp.drawings[#cp.drawings]
	ColorpickerImage(false, BBOT_IMAGES[1], 12, 25, 156, 156, 1, cp.drawings)

	--https://i.imgur.com/jG3NjxN.png
	local alphabar = {}
	ColorpickerOutline(false, 10, 189, 160, 14, { 30, 30, 30, 255 }, cp.drawings)
	table.insert(alphabar, cp.drawings[#cp.drawings])
	ColorpickerOutline(false, 11, 190, 158, 12, { 0, 0, 0, 255 }, cp.drawings)
	table.insert(alphabar, cp.drawings[#cp.drawings])
	ColorpickerImage(false, BBOT_IMAGES[2], 12, 191, 159, 10, 1, cp.drawings)
	table.insert(alphabar, cp.drawings[#cp.drawings])

	ColorpickerOutline(false, 176, 23, 14, 160, { 30, 30, 30, 255 }, cp.drawings)
	ColorpickerOutline(false, 177, 24, 12, 158, { 0, 0, 0, 255 }, cp.drawings)
	--https://i.imgur.com/2Ty4u2O.png
	ColorpickerImage(false, BBOT_IMAGES[3], 178, 25, 10, 156, 1, cp.drawings)

	ColorpickerText("New Color", false, false, 198, 23, cp.drawings)
	ColorpickerOutline(false, 197, 37, 75, 40, { 30, 30, 30, 255 }, cp.drawings)
	ColorpickerOutline(false, 198, 38, 73, 38, { 0, 0, 0, 255 }, cp.drawings)
	ColorpickerImage(false, BBOT_IMAGES[4], 199, 39, 71, 36, 1, cp.drawings)

	ColorpickerRect(false, 199, 39, 71, 36, { 255, 0, 0, 255 }, cp.drawings)
	local newcolor = cp.drawings[#cp.drawings]

	ColorpickerText("copy", false, true, 198 + 36, 41, cp.drawings)
	ColorpickerText("paste", false, true, 198 + 37, 56, cp.drawings)
	local newcopy = { cp.drawings[#cp.drawings - 1], cp.drawings[#cp.drawings] }

	ColorpickerText("Old Color", false, false, 198, 77, cp.drawings)
	ColorpickerOutline(false, 197, 91, 75, 40, { 30, 30, 30, 255 }, cp.drawings)
	ColorpickerOutline(false, 198, 92, 73, 38, { 0, 0, 0, 255 }, cp.drawings)
	ColorpickerImage(false, BBOT_IMAGES[4], 199, 93, 71, 36, 1, cp.drawings)

	ColorpickerRect(false, 199, 93, 71, 36, { 255, 0, 0, 255 }, cp.drawings)
	local oldcolor = cp.drawings[#cp.drawings]

	ColorpickerText("copy", false, true, 198 + 36, 103, cp.drawings)
	local oldcopy = { cp.drawings[#cp.drawings] }

	--ColorpickerRect(false, 197, cp.h - 25, 75, 20, {30, 30, 30, 255}, cp.drawings)
	ColorpickerText("[ Apply ]", false, true, 235, cp.h - 23, cp.drawings)
	local applytext = cp.drawings[#cp.drawings]

	local function set_newcolor(r, g, b, a)
		newcolor.Color = RGB(r, g, b)
		if a ~= nil then
			newcolor.Transparency = a / 255
		else
			newcolor.Transparency = 1
		end
	end

	local function set_oldcolor(r, g, b, a)
		oldcolor.Color = RGB(r, g, b)
		if a ~= nil then
			oldcolor.Transparency = a / 255
		else
			oldcolor.Transparency = 1
		end
	end
	-- all this color picker shit is disgusting, why can't it be in it's own fucking scope. these are all global
	local dragbar_r = {}
	Draw:OutlinedRect(true, 30, 30, 16, 5, { 0, 0, 0, 255 }, cp.drawings)
	table.insert(dragbar_r, cp.drawings[#cp.drawings])
	Draw:OutlinedRect(true, 31, 31, 14, 3, { 255, 255, 255, 255 }, cp.drawings)
	table.insert(dragbar_r, cp.drawings[#cp.drawings])

	local dragbar_b = {}
	Draw:OutlinedRect(true, 30, 30, 5, 16, { 0, 0, 0, 255 }, cp.drawings)
	table.insert(dragbar_b, cp.drawings[#cp.drawings])
	table.insert(alphabar, cp.drawings[#cp.drawings])
	Draw:OutlinedRect(true, 31, 31, 3, 14, { 255, 255, 255, 255 }, cp.drawings)
	table.insert(dragbar_b, cp.drawings[#cp.drawings])
	table.insert(alphabar, cp.drawings[#cp.drawings])

	local dragbar_m = {}
	Draw:OutlinedRect(true, 30, 30, 5, 5, { 0, 0, 0, 255 }, cp.drawings)
	table.insert(dragbar_m, cp.drawings[#cp.drawings])
	Draw:OutlinedRect(true, 31, 31, 3, 3, { 255, 255, 255, 255 }, cp.drawings)
	table.insert(dragbar_m, cp.drawings[#cp.drawings])

	local function set_dragbar_r(x, y)
		dragbar_r[1].Position = Vector2.new(x, y)
		dragbar_r[2].Position = Vector2.new(x + 1, y + 1)
	end

	local function set_dragbar_b(x, y)
		dragbar_b[1].Position = Vector2.new(x, y)
		dragbar_b[2].Position = Vector2.new(x + 1, y + 1)
	end

	local function set_dragbar_m(x, y)
		dragbar_m[1].Position = Vector2.new(x, y)
		dragbar_m[2].Position = Vector2.new(x + 1, y + 1)
	end

	local function set_colorpicker(visible, color, value, alpha, text, x, y)
		for k, v in pairs(cp.drawings) do
			v.Visible = visible
		end

		if visible then
			cp.x = clamp(x, 0, SCREEN_SIZE.x - cp.w)
			cp.y = clamp(y, 0, SCREEN_SIZE.y - cp.h)
			for k, v in pairs(cp.postable) do
				v[1].Position = Vector2.new(cp.x + v[2], cp.y + v[3])
			end

			local tempclr = RGB(color[1], color[2], color[3])
			local h, s, v = tempclr:ToHSV()
			cp.hsv.h = h
			cp.hsv.s = s
			cp.hsv.v = v

			set_dragbar_r(cp.x + 175, cp.y + 23 + math.floor((1 - h) * 156))
			set_dragbar_m(cp.x + 9 + math.floor(s * 156), cp.y + 23 + math.floor((1 - v) * 156))
			if not alpha then
				set_newcolor(color[1], color[2], color[3])
				set_oldcolor(color[1], color[2], color[3])
				cp.alpha = false
				for k, v in pairs(alphabar) do
					v.Visible = false
				end
				cp.h = 191
				for i = 1, 2 do
					cp.drawings[i].Size = Vector2.new(cp.w, cp.h)
				end
				cp.drawings[3].Size = Vector2.new(cp.w - 2, cp.h - 2)
			else
				cp.hsv.a = color[4]
				cp.alpha = true
				set_newcolor(color[1], color[2], color[3], color[4])
				set_oldcolor(color[1], color[2], color[3], color[4])
				cp.h = 211
				for i = 1, 2 do
					cp.drawings[i].Size = Vector2.new(cp.w, cp.h)
				end
				cp.drawings[3].Size = Vector2.new(cp.w - 2, cp.h - 2)
				set_dragbar_b(cp.x + 12 + math.floor(156 * (color[4] / 255)), cp.y + 188)
			end

			applytext.Position = Vector2.new(235 + cp.x, cp.y + cp.h - 23)
			maincolor.Color = Color3.fromHSV(h, 1, 1)
			cp.drawings[7].Text = text
		end
	end

	set_colorpicker(false, { 255, 0, 0 }, nil, false, "", 0, 0)

	--TOOL TIP
	local tooltip = {
		x = 0,
		y = 0,
		time = 0,
		active = false,
		text = "This does this and that i guess\npooping 24/7",
		drawings = {},
		postable = {},
	}

	local function ttOutline(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:OutlinedRect(visible, pos_x + tooltip.x, pos_y + tooltip.y, width, height, clr, tablename)
		table.insert(tooltip.postable, { tablename[#tablename], pos_x, pos_y })
	end

	local function ttRect(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:FilledRect(visible, pos_x + tooltip.x, pos_y + tooltip.y, width, height, clr, tablename)
		table.insert(tooltip.postable, { tablename[#tablename], pos_x, pos_y })
	end

	local function ttText(text, visible, centered, pos_x, pos_y, tablename)
		Draw:OutlinedText(
			text,
			2,
			visible,
			pos_x + tooltip.x,
			pos_y + tooltip.y,
			13,
			centered,
			{ 255, 255, 255, 255 },
			{ 0, 0, 0 },
			tablename
		)
		table.insert(tooltip.postable, { tablename[#tablename], pos_x, pos_y })
	end

	ttRect(
		false,
		tooltip.x + 1,
		tooltip.y + 1,
		1,
		28,
		{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
		tooltip.drawings
	)
	ttRect(
		false,
		tooltip.x + 2,
		tooltip.y + 1,
		1,
		28,
		{ menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40, 255 },
		tooltip.drawings
	)
	ttOutline(false, tooltip.x, tooltip.y, 4, 30, { 20, 20, 20, 255 }, tooltip.drawings)
	ttRect(false, tooltip.x + 4, tooltip.y, 100, 30, { 40, 40, 40, 255 }, tooltip.drawings)
	ttOutline(false, tooltip.x - 1, tooltip.y - 1, 102, 32, { 0, 0, 0, 255 }, tooltip.drawings)
	ttOutline(false, tooltip.x + 3, tooltip.y, 102, 30, { 20, 20, 20, 255 }, tooltip.drawings)
	ttText(tooltip.text, false, false, tooltip.x + 7, tooltip.y + 1, tooltip.drawings)

	local function set_tooltip(x, y, text, visible, dt)
		dt = dt or 0
		x = x or tooltip.x
		y = y or tooltip.y
		tooltip.x = x
		tooltip.y = y
		if tooltip.time < 1 and visible then
			if tooltip.time < -2 then
				tooltip.time = -2
			end
			tooltip.time += dt
		else
			tooltip.time -= dt
			if tooltip.time < -1 then
				tooltip.time = -1
			end
		end
		if tooltip.time > 1 then
			tooltip.time = 1
		end
		for k, v in ipairs(tooltip.drawings) do
			v.Visible = tooltip.time > 0
		end

		tooltip.active = visible
		if text then
			tooltip.drawings[7].Text = text
		end
		for k, v in pairs(tooltip.postable) do
			v[1].Position = Vector2.new(x + v[2], y + v[3])
			v[1].Transparency = (0.3 + tooltip.time) ^ 3 - 1
			if not menu.open then
				v[1].Transparency = 0
			end
		end
		tooltip.drawings[1].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
		tooltip.drawings[2].Color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40)

		local tb = tooltip.drawings[7].TextBounds

		tooltip.drawings[1].Size = Vector2.new(1, tb.Y + 3)
		tooltip.drawings[2].Size = Vector2.new(1, tb.Y + 3)
		tooltip.drawings[3].Size = Vector2.new(4, tb.Y + 5)
		tooltip.drawings[4].Size = Vector2.new(tb.X + 6, tb.Y + 5)
		tooltip.drawings[5].Size = Vector2.new(tb.X + 12, tb.Y + 7)
		tooltip.drawings[6].Size = Vector2.new(tb.X + 7, tb.Y + 5)
	end

	set_tooltip(500, 500, "", false)

	-- mouse shiz
	local bbmouse = {}
	local mousie = {
		x = 100,
		y = 240,
	}
	Draw:Triangle(
		true,
		true,
		{ mousie.x, mousie.y },
		{ mousie.x, mousie.y + 15 },
		{ mousie.x + 10, mousie.y + 10 },
		{ 127, 72, 163, 255 },
		bbmouse
	)
	table.insert(menu.clrs.norm, bbmouse[#bbmouse])
	Draw:Triangle(
		true,
		false,
		{ mousie.x, mousie.y },
		{ mousie.x, mousie.y + 15 },
		{ mousie.x + 10, mousie.y + 10 },
		{ 0, 0, 0, 255 },
		bbmouse
	)
	local lastMousePos = Vector2.new()
	function menu:set_mouse_pos(x, y)
		FireEvent("bb_mousemoved", lastMousePos ~= Vector2.new(x, y))
		for k = 1, #bbmouse do
			local v = bbmouse[k]
			v.PointA = Vector2.new(x, y + 36)
			v.PointB = Vector2.new(x, y + 36 + 15)
			v.PointC = Vector2.new(x + 10, y + 46)
		end
		lastMousePos = Vector2.new(x, y)
	end

	function menu:set_menu_clr(r, g, b)
		menu.watermark.rect[1].Color = RGB(r - 40, g - 40, b - 40)
		menu.watermark.rect[2].Color = RGB(r, g, b)

		for k, v in pairs(menu.clrs.norm) do
			v.Color = RGB(r, g, b)
		end
		for k, v in pairs(menu.clrs.dark) do
			v.Color = RGB(r - 40, g - 40, b - 40)
		end
		local menucolor = { r, g, b }
		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "toggle" then
						if not v2[1] then
							for i = 0, 3 do
								v2[4][i + 1].Color = ColorRange(i, {
									[1] = { start = 0, color = RGB(50, 50, 50) },
									[2] = { start = 3, color = RGB(30, 30, 30) },
								})
							end
						else
							for i = 0, 3 do
								v2[4][i + 1].Color = ColorRange(i, {
									[1] = { start = 0, color = RGB(menucolor[1], menucolor[2], menucolor[3]) },
									[2] = {
										start = 3,
										color = RGB(menucolor[1] - 40, menucolor[2] - 40, menucolor[3] - 40),
									},
								})
							end
						end
					elseif v2[2] == "slider" then
						for i = 0, 3 do
							v2[4][i + 1].Color = ColorRange(i, {
								[1] = { start = 0, color = RGB(menucolor[1], menucolor[2], menucolor[3]) },
								[2] = {
									start = 3,
									color = RGB(menucolor[1] - 40, menucolor[2] - 40, menucolor[3] - 40),
								},
							})
						end
					end
				end
			end
		end
	end

	local function UpdateConfigs()
		local configthing = menu.options["Settings"]["Configuration"]["Configs"]

		configthing[6] = GetConfigs()
		if configthing[1] > #configthing[6] then
			configthing[1] = #configthing[6]
		end
		configthing[4][1].Text = configthing[6][configthing[1]]
	end

	menu.keybind_open = nil

	menu.dropbox_open = nil

	menu.colorpicker_open = false

	menu.textboxopen = nil

	function menu:InputBeganMenu(key) --ANCHOR menu input
		if key.KeyCode == Enum.KeyCode.RightShift and not loadingthing.Visible then
			cp.dragging_m = false
			cp.dragging_r = false
			cp.dragging_b = false

			UpdateConfigs()
			if menu.open and not menu.fading then
				for k = 1, #menu.options do
					local v = menu.options[k]
					for k1, v1 in pairs(v) do
						for k2, v2 in pairs(v1) do
							if v2[2] == "slider" and v2[5] then
								v2[5] = false
							elseif v2[2] == "dropbox" and v2[5] then
								v2[5] = false
							elseif v2[2] == "combobox" and v2[5] then
								v2[5] = false
							elseif v2[2] == "toggle" then
								if v2[5] ~= nil then
									if v2[5][2] == "keybind" and v2[5][5] then
										v2[5][4][2].Color = RGB(30, 30, 30)
										v2[5][5] = false
									elseif v2[5][2] == "single colorpicker" and v2[5][5] then
										v2[5][5] = false
									end
								end
							elseif v2[2] == "button" then
								if v2[1] then
									for i = 0, 8 do
										v2[4][i + 1].Color = ColorRange(i, {
											[1] = { start = 0, color = RGB(50, 50, 50) },
											[2] = { start = 8, color = RGB(35, 35, 35) },
										})
									end
									v2[1] = false
								end
							end
						end
					end
				end
				menu.keybind_open = nil
				set_modeselect(false, 20, 20, 1)
				menu.dropbox_open = nil
				set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })
				menu.colorpicker_open = nil
				set_tooltip(nil, nil, nil, false)
				set_colorpicker(false, { 255, 0, 0 }, nil, false, "hahaha", 400, 200)
			end
			if not menu.fading then
				menu.fading = true
				menu.fadestart = tick()
			end
		end

		if menu == nil then
			return
		end

		if menu.textboxopen then
			if key.KeyCode == Enum.KeyCode.RightShift or key.KeyCode == Enum.KeyCode.Return then
				for k, v in pairs(menu.options) do
					for k1, v1 in pairs(v) do
						for k2, v2 in pairs(v1) do
							if v2[2] == "textbox" then
								if v2[5] then
									v2[5] = false
									v2[4].Color = RGB(255, 255, 255)
									menu.textboxopen = false
									v2[4].Text = v2[1]
								end
							end
						end
					end
				end
			end
		end

		if menu.open and not menu.fading then
			for k, v in pairs(menu.options) do
				for k1, v1 in pairs(v) do
					for k2, v2 in pairs(v1) do
						if v2[2] == "toggle" then
							if v2[5] ~= nil then
								if v2[5][2] == "keybind" and v2[5][5] and key.KeyCode.Value ~= 0 then
									v2[5][4][2].Color = RGB(30, 30, 30)
									v2[5][4][1].Text = KeyEnumToName(key.KeyCode)
									if KeyEnumToName(key.KeyCode) == "None" then
										v2[5][1] = nil
									else
										v2[5][1] = key.KeyCode
									end
									v2[5][5] = false
								end
							end
						elseif v2[2] == "textbox" then --ANCHOR TEXTBOXES
							if v2[5] then
								if not INPUT_SERVICE:IsKeyDown(Enum.KeyCode.LeftControl) then
									if string.len(v2[1]) <= 28 then
										if table.find(textBoxLetters, KeyEnumToName(key.KeyCode)) then
											if INPUT_SERVICE:IsKeyDown(Enum.KeyCode.LeftShift) then
												v2[1] ..= string.upper(KeyEnumToName(key.KeyCode))
											else
												v2[1] ..= string.lower(KeyEnumToName(key.KeyCode))
											end
										elseif KeyEnumToName(key.KeyCode) == "Space" then
											v2[1] ..= " "
										elseif keymodifiernames[KeyEnumToName(key.KeyCode)] ~= nil then
											if INPUT_SERVICE:IsKeyDown(Enum.KeyCode.LeftShift) then
												v2[1] ..= KeyModifierToName(KeyEnumToName(key.KeyCode), v2[6])
											else
												v2[1] ..= KeyEnumToName(key.KeyCode)
											end
										elseif KeyEnumToName(key.KeyCode) == "Back" and v2[1] ~= "" then
											v2[1] = string.sub(v2[1], 0, #v2[1] - 1)
										end
									end
									v2[4].Text = v2[1] .. "|"
								end
							end
						end
					end
				end
			end
		end
	end

	function menu:InputBeganKeybinds(key) -- this is super shit because once we add mouse we need to change all this shit to be the contextaction stuff
		if INPUT_SERVICE:GetFocusedTextBox() or menu.textboxopen then
			return
		end
		for i = 1, #self.keybinds do
			local value = self.keybinds[i][1]
			if key.KeyCode == value[5][1] then
				value[5].lastvalue = value[5].relvalue
				if value[5].toggletype == 2 then
					value[5].relvalue = not value[5].relvalue
				elseif value[5].toggletype == 1 then
					value[5].relvalue = true
				elseif value[5].toggletype == 3 then
					value[5].relvalue = false
				end
			elseif value[5].toggletype == 4 then
				value[5].relvalue = true
			end
			if value[5].lastvalue ~= value[5].relvalue then
				value[5].event:fire(value[5].relvalue)
			end
		end
	end

	function menu:InputEndedKeybinds(key)
		for i = 1, #self.keybinds do
			local value = self.keybinds[i][1]
			value[5].lastvalue = value[5].relvalue
			if key.KeyCode == value[5][1] then
				if value[5].toggletype == 1 then
					value[5].relvalue = false
				elseif value[5].toggletype == 3 then
					value[5].relvalue = true
				end
			end
			if value[5].lastvalue ~= value[5].relvalue then
				value[5].event:fire(value[5].relvalue)
			end
		end
	end

	function menu:SetMenuPos(x, y)
		for k, v in pairs(menu.postable) do
			if v[1].Visible then
				v[1].Position = Vector2.new(x + v[2], y + v[3])
			end
		end
	end

	function menu:MouseInArea(x, y, width, height)
		return LOCAL_MOUSE.x > x and LOCAL_MOUSE.x < x + width and LOCAL_MOUSE.y > 36 + y and LOCAL_MOUSE.y < 36 + y + height
	end

	function menu:MouseInMenu(x, y, width, height)
		return LOCAL_MOUSE.x > menu.x + x and LOCAL_MOUSE.x < menu.x + x + width and LOCAL_MOUSE.y > menu.y - 36 + y and LOCAL_MOUSE.y < menu.y - 36 + y + height
	end

	function menu:MouseInColorPicker(x, y, width, height)
		return LOCAL_MOUSE.x > cp.x + x and LOCAL_MOUSE.x < cp.x + x + width and LOCAL_MOUSE.y > cp.y - 36 + y and LOCAL_MOUSE.y < cp.y - 36 + y + height
	end

	local keyz = {}
	for k, v in pairs(Enum.KeyCode:GetEnumItems()) do
		keyz[v.Value] = v
	end

	function menu:GetVal(tab, groupbox, name, ...)
		local args = { ... }

		local option = menu.options[tab][groupbox][name]

		if args[1] == nil then
			if option[2] == "toggle" then
				local lastval = option[7]
				option[7] = option[1]
				return option[1], lastval
			elseif option[2] ~= "combobox" then
				return option[1]
			else
				local temptable = {}
				for k, v in ipairs(option[1]) do
					table.insert(temptable, v[2])
				end
				return temptable
			end
		else
			if args[1] == "keybind" or args[1] == "color" then
				if args[2] then
					return RGB(option[5][1][1], option[5][1][2], option[5][1][3])
				else
					return option[5][1]
				end
			elseif args[1] == "color1" then
				if args[2] then
					return RGB(option[5][1][1][1][1], option[5][1][1][1][2], option[5][1][1][1][3])
				else
					return option[5][1][1][1]
				end
			elseif args[1] == "color2" then
				if args[2] then
					return RGB(option[5][1][2][1][1], option[5][1][2][1][2], option[5][1][2][1][3])
				else
					return option[5][1][2][1]
				end
			end
		end
	end

	function menu:GetKey(tab, groupbox, name)
		local option = self.options[tab][groupbox][name][5]
		if self:GetVal(tab, groupbox, name) then
			if option.toggletype ~= 0 then
				if option.lastvalue == nil then
					option.lastvalue = option.relvalue
				end
				return option.relvalue, option.lastvalue, option.event
			else
				return false
			end
		end
	end

	function menu:SetKey(tab, groupbox, name, val)
		val = val or false
		local option = menu.options[tab][groupbox][name][5]
		if option.toggletype ~= 0 then
			option.lastvalue = option.relvalue
			option.relvalue = val
			if option.lastvalue ~= option.relvalue then
				option.event:fire(option.relvalue)
			end
		end
	end

	local menuElementTypes = { "toggle", "slider", "dropbox", "textbox" }
	local doubleclickDelay = 4
	local buttonsInQue = {}

	local function SaveCurSettings() --ANCHOR figgies
		local figgy = "BitchBot v2\nmade with <3 by nata and bitch\n\n" -- screw zarzel XD (and json and classy)

		for k, v in next, menuElementTypes do
			figgy ..= v .. "s {\n"
			for k1, v1 in pairs(menu.options) do
				for k2, v2 in pairs(v1) do
					for k3, v3 in pairs(v2) do
						if v3[2] == tostring(v) and k3 ~= "Configs" and k3 ~= "Player Status" and k3 ~= "ConfigName"
						then
							figgy ..= k1 .. "|" .. k2 .. "|" .. k3 .. "|" .. tostring(v3[1]) .. "\n"
						end
					end
				end
			end
			figgy = figgy .. "}\n"
		end
		figgy = figgy .. "comboboxes {\n"
		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "combobox" then
						local boolz = ""
						for k3, v3 in pairs(v2[1]) do
							boolz = boolz .. tostring(v3[2]) .. ", "
						end
						figgy = figgy .. k .. "|" .. k1 .. "|" .. k2 .. "|" .. boolz .. "\n"
					end
				end
			end
		end
		figgy = figgy .. "}\n"
		figgy = figgy .. "keybinds {\n"
		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "toggle" then
						if v2[5] ~= nil then
							if v2[5][2] == "keybind" then
								local toggletype = "|" .. tostring(v2[5].toggletype)

								if v2[5][1] == nil then
									figgy = figgy
										.. k
										.. "|"
										.. k1
										.. "|"
										.. k2
										.. "|nil"
										.. "|"
										.. tostring(v2[5].toggletype)
										.. "\n"
								else
									figgy = figgy
										.. k
										.. "|"
										.. k1
										.. "|"
										.. k2
										.. "|"
										.. tostring(v2[5][1].Value)
										.. "|"
										.. tostring(v2[5].toggletype)
										.. "\n"
								end
							end
						end
					end
				end
			end
		end
		figgy = figgy .. "}\n"
		figgy = figgy .. "colorpickers {\n"
		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "toggle" then
						if v2[5] ~= nil then
							if v2[5][2] == "single colorpicker" then
								local clrz = ""
								for k3, v3 in pairs(v2[5][1]) do
									clrz = clrz .. tostring(v3) .. ", "
								end
								figgy = figgy .. k .. "|" .. k1 .. "|" .. k2 .. "|" .. clrz .. "\n"
							end
						end
					end
				end
			end
		end
		figgy = figgy .. "}\n"
		figgy = figgy .. "double colorpickers {\n"
		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "toggle" then
						if v2[5] ~= nil then
							if v2[5][2] == "double colorpicker" then
								local clrz1 = ""
								for k3, v3 in pairs(v2[5][1][1][1]) do
									clrz1 = clrz1 .. tostring(v3) .. ", "
								end
								local clrz2 = ""
								for k3, v3 in pairs(v2[5][1][2][1]) do
									clrz2 = clrz2 .. tostring(v3) .. ", "
								end
								figgy = figgy .. k .. "|" .. k1 .. "|" .. k2 .. "|" .. clrz1 .. "|" .. clrz2 .. "\n"
							end
						end
					end
				end
			end
		end
		figgy = figgy .. "}\n"

		return figgy
	end

	local function LoadConfig(loadedcfg)
		local lines = {}

		for s in loadedcfg:gmatch("[^\r\n]+") do
			table.insert(lines, s)
		end

		if lines[1] == "BitchBot v2" then
			local start = nil
			for i, v in next, lines do
				if v == "toggles {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")

				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
				then
					if tt[4] == "true" then
						menu.options[tt[1]][tt[2]][tt[3]][1] = true
					else
						menu.options[tt[1]][tt[2]][tt[3]][1] = false
					end
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "sliders {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")
				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
				then
					menu.options[tt[1]][tt[2]][tt[3]][1] = tonumber(tt[4])
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "dropboxs {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")

				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
				then
					local num = tonumber(tt[4])
					if num > #menu.options[tt[1]][tt[2]][tt[3]][6] then
						num = #menu.options[tt[1]][tt[2]][tt[3]][6]
					elseif num < 0 then
						num = 1
					end
					menu.options[tt[1]][tt[2]][tt[3]][1] = num
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "textboxs {" then
					start = i
					break
				end
			end
			if start ~= nil then
				local end_ = nil
				for i, v in next, lines do
					if i > start and v == "}" then
						end_ = i
						break
					end
				end
				for i = 1, end_ - start - 1 do
					local tt = string.split(lines[i + start], "|")
					if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
					then
						menu.options[tt[1]][tt[2]][tt[3]][1] = tostring(tt[4])
					end
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "comboboxes {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")
				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
				then
					local subs = string.split(tt[4], ",")

					for i, v in ipairs(subs) do
						local opt = string.gsub(v, " ", "")
						if opt == "true" then
							menu.options[tt[1]][tt[2]][tt[3]][1][i][2] = true
						else
							menu.options[tt[1]][tt[2]][tt[3]][1][i][2] = false
						end
						if i == #subs - 1 then
							break
						end
					end
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "keybinds {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")
				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]][5] ~= nil
				then
					if tt[5] ~= nil then
						local toggletype = clamp(tonumber(tt[5]), 1, 4)
						if menu.options[tt[1]][tt[2]][tt[3]][5].toggletype ~= 0 then
							menu.options[tt[1]][tt[2]][tt[3]][5].toggletype = toggletype
						end
					end

					if tt[4] == "nil" then
						menu.options[tt[1]][tt[2]][tt[3]][5][1] = nil
					else
						menu.options[tt[1]][tt[2]][tt[3]][5][1] = keyz[tonumber(tt[4])]
					end
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "colorpickers {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")
				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
				then
					local subs = string.split(tt[4], ",")

					for i, v in ipairs(subs) do
						if menu.options[tt[1]][tt[2]][tt[3]][5][1][i] == nil then
							break
						end
						local opt = string.gsub(v, " ", "")
						menu.options[tt[1]][tt[2]][tt[3]][5][1][i] = tonumber(opt)
						if i == #subs - 1 then
							break
						end
					end
				end
			end

			local start = nil
			for i, v in next, lines do
				if v == "double colorpickers {" then
					start = i
					break
				end
			end
			local end_ = nil
			for i, v in next, lines do
				if i > start and v == "}" then
					end_ = i
					break
				end
			end
			for i = 1, end_ - start - 1 do
				local tt = string.split(lines[i + start], "|")
				if menu.options[tt[1]] ~= nil and menu.options[tt[1]][tt[2]] ~= nil and menu.options[tt[1]][tt[2]][tt[3]] ~= nil
				then
					local subs = { string.split(tt[4], ","), string.split(tt[5], ",") }

					for i, v in ipairs(subs) do
						for i1, v1 in ipairs(v) do
							if menu.options[tt[1]][tt[2]][tt[3]][5][1][i][1][i1] == nil then
								break
							end
							local opt = string.gsub(v1, " ", "")
							menu.options[tt[1]][tt[2]][tt[3]][5][1][i][1][i1] = tonumber(opt)
							if i1 == #v - 1 then
								break
							end
						end
					end
				end
			end

			for k, v in pairs(menu.options) do
				for k1, v1 in pairs(v) do
					for k2, v2 in pairs(v1) do
						if v2[2] == "toggle" then
							if not v2[1] then
								for i = 0, 3 do
									v2[4][i + 1].Color = ColorRange(i, {
										[1] = { start = 0, color = RGB(50, 50, 50) },
										[2] = { start = 3, color = RGB(30, 30, 30) },
									})
								end
							else
								for i = 0, 3 do
									v2[4][i + 1].Color = ColorRange(i, {
										[1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) },
										[2] = {
											start = 3,
											color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40),
										},
									})
								end
							end
							if v2[5] ~= nil then
								if v2[5][2] == "keybind" then
									v2[5][4][2].Color = RGB(30, 30, 30)
									v2[5][4][1].Text = KeyEnumToName(v2[5][1])
								elseif v2[5][2] == "single colorpicker" then
									v2[5][4][1].Color = RGB(v2[5][1][1], v2[5][1][2], v2[5][1][3])
									for i = 2, 3 do
										v2[5][4][i].Color = RGB(v2[5][1][1] - 40, v2[5][1][2] - 40, v2[5][1][3] - 40)
									end
								elseif v2[5][2] == "double colorpicker" then
									for i, v3 in ipairs(v2[5][1]) do
										v3[4][1].Color = RGB(v3[1][1], v3[1][2], v3[1][3])
										for i1 = 2, 3 do
											v3[4][i1].Color = RGB(v3[1][1] - 40, v3[1][2] - 40, v3[1][3] - 40)
										end
									end
								end
							end
						elseif v2[2] == "slider" then
							if v2[1] < v2[6][1] then
								v2[1] = v2[6][1]
							elseif v2[1] > v2[6][2] then
								v2[1] = v2[6][2]
							end

							local decplaces = v2.decimal and string.rep("0", math.log(1 / v2.decimal) / math.log(10))
							if decplaces and math.abs(v2[1]) < v2.decimal then
								v2[1] = 0
							end
							v2[4][5].Text = v2.custom[v2[1]] or (v2[1] == math.floor(v2[1]) and v2.decimal) and tostring(v2[1]) .. "." .. decplaces .. v2[4][6] or tostring(v2[1]) .. v2[4][6]
							-- v2[4][5].Text = tostring(v2[1]).. v2[4][6]

							for i = 1, 4 do
								v2[4][i].Size = Vector2.new((v2[3][3] - 4) * ((v2[1] - v2[6][1]) / (v2[6][2] - v2[6][1])), 2)
							end
						elseif v2[2] == "dropbox" then
							if v2[6][v2[1]] == nil then
								v2[1] = 1
							end
							v2[4][1].Text = v2[6][v2[1]]
						elseif v2[2] == "combobox" then
							local textthing = ""
							for k3, v3 in pairs(v2[1]) do
								if v3[2] then
									if textthing == "" then
										textthing = v3[1]
									else
										textthing = textthing .. ", " .. v3[1]
									end
								end
							end
							textthing = textthing ~= "" and textthing or "None"
							if string.len(textthing) > 25 then
								textthing = string_cut(textthing, 25)
							end
							v2[4][1].Text = textthing
						elseif v2[2] == "textbox" then
							v2[4].Text = v2[1]
						end
					end
				end
			end
		end
	end

	function menu.saveconfig()
		local figgy = SaveCurSettings()
		writefile(
			"bitchbot/"
				.. menu.game
				.. "/"
				.. menu.options["Settings"]["Configuration"]["ConfigName"][1]
				.. ".bb",
			figgy
		)
		CreateNotification('Saved "' .. menu.options["Settings"]["Configuration"]["ConfigName"][1] .. '.bb"!')
		UpdateConfigs()
	end
	
	function menu.loadconfig()
		local configname = "bitchbot/"
			.. menu.game
			.. "/"
			.. menu.options["Settings"]["Configuration"]["ConfigName"][1]
			.. ".bb"
		if not isfile(configname) then
			CreateNotification(
				'"'
					.. menu.options["Settings"]["Configuration"]["ConfigName"][1]
					.. '.bb" is not a valid config.'
			)
			return
		end
	
		local curcfg = SaveCurSettings()
		local loadedcfg = readfile(configname)
	
		if pcall(LoadConfig, loadedcfg) then
			CreateNotification('Loaded "' .. menu.options["Settings"]["Configuration"]["ConfigName"][1] .. '.bb"!')
		else
			LoadConfig(curcfg)
			CreateNotification(
				'There was an issue loading "'
					.. menu.options["Settings"]["Configuration"]["ConfigName"][1]
					.. '.bb"'
			)
		end
	end

	local function buttonpressed(bp)
		if bp.doubleclick then
			if buttonsInQue[bp] and tick() - buttonsInQue[bp] < doubleclickDelay then
				buttonsInQue[bp] = 0
			else
				for button, time in next, buttonsInQue do
					buttonsInQue[button] = 0
				end
				buttonsInQue[bp] = tick()
				return
			end
		end
		FireEvent("bb_buttonpressed", bp.tab, bp.groupbox, bp.name)
		--ButtonPressed:Fire(bp.tab, bp.groupbox, bp.name)
		if bp == menu.options["Settings"]["Cheat Settings"]["Unload Cheat"] then
			menu.fading = true
			wait()
			menu:unload()
		elseif bp == menu.options["Settings"]["Cheat Settings"]["Set Clipboard Game ID"] then
			setclipboard(game.JobId)
		elseif bp == menu.options["Settings"]["Configuration"]["Save Config"] then
			menu.saveconfig()
		elseif bp == menu.options["Settings"]["Configuration"]["Delete Config"] then
			delfile(
				"bitchbot/"
					.. menu.game
					.. "/"
					.. menu.options["Settings"]["Configuration"]["ConfigName"][1]
					.. ".bb"
			)
			CreateNotification('Deleted "' .. menu.options["Settings"]["Configuration"]["ConfigName"][1] .. '.bb"!')
			UpdateConfigs()
		elseif bp == menu.options["Settings"]["Configuration"]["Load Config"] then
			menu.loadconfig()
		elseif bp == menu.options["Visuals"]["Highlight Chams"]["Print Values"] then
			local hl = menu:GetVal("Visuals", "Highlight Chams", "Enable")
			local hlcf = Color3.fromRGB(unpack(menu:GetVal("Visuals", "Highlight Chams", "Enable", "color1")))
			local hlco = Color3.fromRGB(unpack(menu:GetVal("Visuals", "Highlight Chams", "Enable", "color2")))
			local hltype = menu:GetVal("Visuals", "Highlight Chams", "Highlight Type")
			print(hl)
			print(hltype - 1)
			print(menu.options["Visuals"]["Highlight Chams"]["Enable"][5][1][1][6])
			print(hlcf)
			print(menu.options["Visuals"]["Highlight Chams"]["Enable"][5][1][2][6])
			print(hlco)
		end
	end

	local function mousebutton2downfunc()
		if menu.colorpicker_open or menu.dropbox_open then
			return
		end

		for k, v in pairs(menu.options) do
			if menu.tabnames[menu.activetab] == k then
				for k1, v1 in pairs(v) do
					local pass = true
					for k3, v3 in pairs(menu.multigroups) do
						if k == k3 then
							for k4, v4 in pairs(v3) do
								for k5, v5 in pairs(v4.vals) do
									if k1 == k5 then
										pass = v5
									end
								end
							end
						end
					end

					if pass then
						for k2, v2 in pairs(v1) do --ANCHOR more menu bs
							if v2[2] == "toggle" then
								if v2[5] ~= nil then
									if v2[5][2] == "keybind" then
										if menu:MouseInMenu(v2[5][3][1], v2[5][3][2], 44, 16) then
											if menu.keybind_open ~= v2 and v2[5].toggletype ~= 0 then
												menu.keybind_open = v2
												set_modeselect(
													true,
													v2[5][3][1] + menu.x,
													v2[5][3][2] + 16 + menu.y,
													v2[5].toggletype
												)
											else
												menu.keybind_open = nil
												set_modeselect(false, 20, 20, 1)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	local function mousebutton1downfunc() --ANCHOR menu mouse down func
		menu.dropbox_open = nil
		menu.textboxopen = false

		set_modeselect(false, 20, 20, 1)
		if menu.keybind_open then
			local key = menu.keybind_open
			local foundkey = false
			for i = 1, 4 do
				if menu:MouseInMenu(key[5][3][1], key[5][3][2] + 16 + ((i - 1) * 21), 70, 21) then
					foundkey = true
					menu.keybind_open[5].toggletype = i
					menu.keybind_open[5].relvalue = false
				end
			end
			menu.keybind_open = nil
			if foundkey then
				return
			end
		end

		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "dropbox" and v2[5] then
						if not menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 24 * (#v2[6] + 1) + 3) then
							set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })
							v2[5] = false
						else
							menu.dropbox_open = v2
						end
					end
					if v2[2] == "combobox" and v2[5] then
						if not menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 24 * (#v2[1] + 1) + 3) then
							set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })
							v2[5] = false
						else
							menu.dropbox_open = v2
						end
					end
					if v2[2] == "toggle" then
						if v2[5] ~= nil then
							if v2[5][2] == "keybind" then
								if v2[5][5] == true then
									v2[5][4][2].Color = RGB(30, 30, 30)
									v2[5][5] = false
								end
							elseif v2[5][2] == "single colorpicker" then
								if v2[5][5] == true then
									if not menu:MouseInColorPicker(0, 0, cp.w, cp.h) then
										set_colorpicker(false, { 255, 0, 0 }, nil, false, "hahaha", 400, 200)
										v2[5][5] = false
										menu.colorpicker_open = nil
										menu.colorpicker_open = nil
									end
								end
							elseif v2[5][2] == "double colorpicker" then
								for k3, v3 in pairs(v2[5][1]) do
									if v3[5] == true then
										if not menu:MouseInColorPicker(0, 0, cp.w, cp.h) then
											set_colorpicker(false, { 255, 0, 0 }, nil, false, "hahaha", 400, 200)
											v3[5] = false
											menu.colorpicker_open = nil
											menu.colorpicker_open = nil
										end
									end
								end
							end
						end
					end
					if v2[2] == "textbox" and v2[5] then
						v2[4].Color = RGB(255, 255, 255)
						v2[5] = false
						v2[4].Text = v2[1]
					end
				end
			end
		end
		for i = 1, #menutable do
			if menu:MouseInMenu(
					10 + ((i - 1) * math.floor((menu.w - 20) / #menutable)),
					27,
					math.floor((menu.w - 20) / #menutable),
					32
				)
			then
				menu.activetab = i
				setActiveTab(menu.activetab)
				menu:SetMenuPos(menu.x, menu.y)
				set_tooltip(nil, nil, nil, false)
			end
		end
		if menu.colorpicker_open then
			if menu:MouseInColorPicker(197, cp.h - 25, 75, 20) then
				local tempclr = Color3.fromHSV(cp.hsv.h, cp.hsv.s, cp.hsv.v)
				menu.colorpicker_open[4][1].Color = tempclr
				for i = 2, 3 do
					menu.colorpicker_open[4][i].Color = RGB(
						math.floor(tempclr.R * 255) - 40,
						math.floor(tempclr.G * 255) - 40,
						math.floor(tempclr.B * 255) - 40
					)
				end
				if cp.alpha then
					menu.colorpicker_open[1] = {
						math.floor(tempclr.R * 255),
						math.floor(tempclr.G * 255),
						math.floor(tempclr.B * 255),
						cp.hsv.a,
					}
				else
					menu.colorpicker_open[1] = {
						math.floor(tempclr.R * 255),
						math.floor(tempclr.G * 255),
						math.floor(tempclr.B * 255),
					}
				end
				menu.colorpicker_open = nil
				menu.colorpicker_open = nil
				set_colorpicker(false, { 255, 0, 0 }, nil, false, "hahaha", 400, 200)
			end
			if menu:MouseInColorPicker(264, 2, 14, 14) then
				menu.colorpicker_open = nil
				menu.colorpicker_open = nil
				set_colorpicker(false, { 255, 0, 0 }, nil, false, "hahaha", 400, 200)
			end
			if menu:MouseInColorPicker(10, 23, 160, 160) then
				cp.dragging_m = true
			elseif menu:MouseInColorPicker(176, 23, 14, 160) then
				cp.dragging_r = true
			elseif menu:MouseInColorPicker(10, 189, 160, 14) and cp.alpha then
				cp.dragging_b = true
			end

			if menu:MouseInColorPicker(197, 37, 75, 20) then
				menu.copied_clr = newcolor.Color
			elseif menu:MouseInColorPicker(197, 57, 75, 20) then
				if menu.copied_clr ~= nil then
					local cpa = false
					local clrtable = { menu.copied_clr.R * 255, menu.copied_clr.G * 255, menu.copied_clr.B * 255 }
					if menu.colorpicker_open[1][4] ~= nil then
						cpa = true
						table.insert(clrtable, menu.colorpicker_open[1][4])
					end

					set_colorpicker(true, clrtable, menu.colorpicker_open, cpa, menu.colorpicker_open[6], cp.x, cp.y)
					local oldclr = menu.colorpicker_open[4][1].Color
					if menu.colorpicker_open[1][4] ~= nil then
						set_oldcolor(oldclr.R * 255, oldclr.G * 255, oldclr.B * 255, menu.colorpicker_open[1][4])
					else
						set_oldcolor(oldclr.R * 255, oldclr.G * 255, oldclr.B * 255)
					end
				end
			end

			if menu:MouseInColorPicker(197, 91, 75, 40) then
				menu.copied_clr = oldcolor.Color
			end
		else
			for k, v in pairs(menu.multigroups) do
				if menu.tabnames[menu.activetab] == k then
					for k1, v1 in pairs(v) do
						local c_pos = v1.drawn.click_pos
						--local selected = v1.drawn.bar
						local selected_pos = v1.drawn.barpos

						for k2, v2 in pairs(v1.drawn.click_pos) do
							if menu:MouseInMenu(v2.x, v2.y, v2.width, v2.height) then
								for _k, _v in pairs(v1.vals) do
									if _k == v2.name then
										v1.vals[_k] = true
									else
										v1.vals[_k] = false
									end
								end

								local settab = v2.num
								for _k, _v in pairs(v1.drawn.bar) do
									menu.postable[_v.postable][2] = selected_pos[settab].pos
									_v.drawn.Size = Vector2.new(selected_pos[settab].length, 2)
								end

								for i, v in pairs(v1.drawn.nametext) do
									if i == v2.num then
										v.Color = RGB(255, 255, 255)
									else
										v.Color = RGB(170, 170, 170)
									end
								end

								menu:set_menu_visibility(true)
								setActiveTab(menu.activetab)
								menu:SetMenuPos(menu.x, menu.y)
							end
						end
					end
				end
			end
			local newdropbox_open
			for k, v in pairs(menu.options) do
				if menu.tabnames[menu.activetab] == k then
					for k1, v1 in pairs(v) do
						local pass = true
						for k3, v3 in pairs(menu.multigroups) do
							if k == k3 then
								for k4, v4 in pairs(v3) do
									for k5, v5 in pairs(v4.vals) do
										if k1 == k5 then
											pass = v5
										end
									end
								end
							end
						end

						if pass then
							for k2, v2 in pairs(v1) do
								if v2[2] == "toggle" and not menu.dropbox_open then
									if menu:MouseInMenu(v2[3][1], v2[3][2], 30 + v2[4][5].TextBounds.x, 16) then
										if v2[6] then
											if menu:GetVal(
													"Settings",
													"Cheat Settings",
													"Allow Unsafe Features"
												) and v2[1] == false
											then
												v2[1] = true
											else
												v2[1] = false
											end
										else
											v2[1] = not v2[1]
										end
										if not v2[1] then
											for i = 0, 3 do
												v2[4][i + 1].Color = ColorRange(i, {
													[1] = { start = 0, color = RGB(50, 50, 50) },
													[2] = { start = 3, color = RGB(30, 30, 30) },
												})
											end
										else
											for i = 0, 3 do
												v2[4][i + 1].Color = ColorRange(i, {
													[1] = {
														start = 0,
														color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]),
													},
													[2] = {
														start = 3,
														color = RGB(
															menu.mc[1] - 40,
															menu.mc[2] - 40,
															menu.mc[3] - 40
														),
													},
												})
											end
										end
										--TogglePressed:Fire(k1, k2, v2)
										FireEvent("bb_togglepressed", k1, k2, v2)
									end
									if v2[5] ~= nil then
										if v2[5][2] == "keybind" then
											if menu:MouseInMenu(v2[5][3][1], v2[5][3][2], 44, 16) then
												v2[5][4][2].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
												v2[5][5] = true
											end
										elseif v2[5][2] == "single colorpicker" then
											if menu:MouseInMenu(v2[5][3][1], v2[5][3][2], 28, 14) then
												v2[5][5] = true
												menu.colorpicker_open = v2[5]
												menu.colorpicker_open = v2[5]
												if v2[5][1][4] ~= nil then
													set_colorpicker(
														true,
														v2[5][1],
														v2[5],
														true,
														v2[5][6],
														LOCAL_MOUSE.x,
														LOCAL_MOUSE.y + 36
													)
												else
													set_colorpicker(
														true,
														v2[5][1],
														v2[5],
														false,
														v2[5][6],
														LOCAL_MOUSE.x,
														LOCAL_MOUSE.y + 36
													)
												end
											end
										elseif v2[5][2] == "double colorpicker" then
											for k3, v3 in pairs(v2[5][1]) do
												if menu:MouseInMenu(v3[3][1], v3[3][2], 28, 14) then
													v3[5] = true
													menu.colorpicker_open = v3
													menu.colorpicker_open = v3
													if v3[1][4] ~= nil then
														set_colorpicker(
															true,
															v3[1],
															v3,
															true,
															v3[6],
															LOCAL_MOUSE.x,
															LOCAL_MOUSE.y + 36
														)
													else
														set_colorpicker(
															true,
															v3[1],
															v3,
															false,
															v3[6],
															LOCAL_MOUSE.x,
															LOCAL_MOUSE.y + 36
														)
													end
												end
											end
										end
									end
								elseif v2[2] == "slider" and not menu.dropbox_open then
									if menu:MouseInMenu(v2[7][1], v2[7][2], 22, 13) then
										local stepval = 1
										if v2.stepsize then
											stepval = v2.stepsize
										end
										if menu:modkeydown("shift", "left") then
											stepval = 0.1
										end
										if menu:MouseInMenu(v2[7][1], v2[7][2], 11, 13) then
											v2[1] -= stepval
										elseif menu:MouseInMenu(v2[7][1] + 11, v2[7][2], 11, 13) then
											v2[1] += stepval
										end

										if v2[1] < v2[6][1] then
											v2[1] = v2[6][1]
										elseif v2[1] > v2[6][2] then
											v2[1] = v2[6][2]
										end
										local decplaces = v2.decimal and string.rep("0", math.log(1 / v2.decimal) / math.log(10))
										if decplaces and math.abs(v2[1]) < v2.decimal then
											v2[1] = 0
										end
										v2[4][5].Text = v2.custom[v2[1]] or (v2[1] == math.floor(v2[1]) and v2.decimal) and tostring(v2[1]) .. "." .. decplaces .. v2[4][6] or tostring(v2[1]) .. v2[4][6]

										for i = 1, 4 do
											v2[4][i].Size = Vector2.new(
												(v2[3][3] - 4) * ((v2[1] - v2[6][1]) / (v2[6][2] - v2[6][1])),
												2
											)
										end
									elseif menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 28) then
										v2[5] = true
									end
								elseif v2[2] == "dropbox" then
									if menu.dropbox_open then
										if v2 ~= menu.dropbox_open then
											continue
										end
									end
									if menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 36) then
										if not v2[5] then
											set_dropboxthingy(
												true,
												v2[3][1] + menu.x + 1,
												v2[3][2] + menu.y + 13,
												v2[3][3],
												v2[1],
												v2[6]
											)
											v2[5] = true
											newdropbox_open = v2
										else
											set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })
											v2[5] = false
											newdropbox_open = nil
										end
									elseif menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 24 * (#v2[6] + 1) + 3) and v2[5]
									then
										for i = 1, #v2[6] do
											if menu:MouseInMenu(
													v2[3][1],
													v2[3][2] + 36 + ((i - 1) * 21),
													v2[3][3],
													21
												)
											then
												v2[4][1].Text = v2[6][i]
												v2[1] = i
												set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })
												v2[5] = false
												newdropbox_open = nil
											end
										end

										if v2 == menu.options["Settings"]["Configuration"]["Configs"] then
											local textbox = menu.options["Settings"]["Configuration"]["ConfigName"]
											local relconfigs = GetConfigs()
											textbox[1] = relconfigs[menu.options["Settings"]["Configuration"]["Configs"][1]]
											textbox[4].Text = textbox[1]
										end
									end
								elseif v2[2] == "combobox" then
									if menu.dropbox_open then
										if v2 ~= menu.dropbox_open then
											continue
										end
									end
									if menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 36) then
										if not v2[5] then
											set_comboboxthingy(
												true,
												v2[3][1] + menu.x + 1,
												v2[3][2] + menu.y + 13,
												v2[3][3],
												v2[1],
												v2[6]
											)
											v2[5] = true
											newdropbox_open = v2
										else
											set_dropboxthingy(false, 400, 200, 160, 1, { "HI q", "HI q", "HI q" })
											v2[5] = false
											newdropbox_open = nil
										end
									elseif menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 24 * (#v2[1] + 1) + 3) and v2[5]
									then
										for i = 1, #v2[1] do
											if menu:MouseInMenu(
													v2[3][1],
													v2[3][2] + 36 + ((i - 1) * 22),
													v2[3][3],
													23
												)
											then
												v2[1][i][2] = not v2[1][i][2]
												local textthing = ""
												for k, v in pairs(v2[1]) do
													if v[2] then
														if textthing == "" then
															textthing = v[1]
														else
															textthing = textthing .. ", " .. v[1]
														end
													end
												end
												textthing = textthing ~= "" and textthing or "None"
												if string.len(textthing) > 25 then
													textthing = string_cut(textthing, 25)
												end
												v2[4][1].Text = textthing
												set_comboboxthingy(
													true,
													v2[3][1] + menu.x + 1,
													v2[3][2] + menu.y + 13,
													v2[3][3],
													v2[1],
													v2[6]
												)
											end
										end
									end
								elseif v2[2] == "button" and not menu.dropbox_open then
									if menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 22) then
										if not v2[1] then
											buttonpressed(v2)
											if k2 == "Unload Cheat" then
												return
											end
											for i = 0, 8 do
												v2[4][i + 1].Color = ColorRange(i, {
													[1] = { start = 0, color = RGB(35, 35, 35) },
													[2] = { start = 8, color = RGB(50, 50, 50) },
												})
											end
											v2[1] = true
										end
									end
								elseif v2[2] == "textbox" and not menu.dropbox_open then
									if menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 22) then
										if not v2[5] then
											menu.textboxopen = v2

											v2[4].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
											v2[5] = true
										end
									end
								elseif v2[2] == "list" then
									--[[
									menu.options[v.name][v1.name][v2.name] = {}
									menu.options[v.name][v1.name][v2.name][4] = Draw:List(v2.name, v1.x + 8, v1.y + y_pos, v1.width - 16, v2.size, v2.columns, tabz[k])
									menu.options[v.name][v1.name][v2.name][1] = nil
									menu.options[v.name][v1.name][v2.name][2] = v2.type
									menu.options[v.name][v1.name][v2.name][3] = 1
									menu.options[v.name][v1.name][v2.name][5] = {}
									menu.options[v.name][v1.name][v2.name][6] = v2.size
									menu.options[v.name][v1.name][v2.name][7] = v2.columns
									menu.options[v.name][v1.name][v2.name][8] = {v1.x + 8, v1.y + y_pos, v1.width - 16}
									]]
									--
									if #v2[5] > v2[6] then
										for i = 1, v2[6] do
											if menu:MouseInMenu(v2[8][1], v2[8][2] + (i * 22) - 5, v2[8][3], 22)
											then
												if v2[1] == tostring(v2[5][i + v2[3] - 1][1][1]) then
													v2[1] = nil
												else
													v2[1] = tostring(v2[5][i + v2[3] - 1][1][1])
												end
											end
										end
									else
										for i = 1, #v2[5] do
											if menu:MouseInMenu(v2[8][1], v2[8][2] + (i * 22) - 5, v2[8][3], 22)
											then
												if v2[1] == tostring(v2[5][i + v2[3] - 1][1][1]) then
													v2[1] = nil
												else
													v2[1] = tostring(v2[5][i + v2[3] - 1][1][1])
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
			menu.dropbox_open = newdropbox_open
		end
		for k, v in pairs(menu.options) do
			for k1, v1 in pairs(v) do
				for k2, v2 in pairs(v1) do
					if v2[2] == "toggle" then
						if v2[6] then
							if not menu:GetVal("Settings", "Cheat Settings", "Allow Unsafe Features") then
								v2[1] = false
								for i = 0, 3 do
									v2[4][i + 1].Color = ColorRange(i, {
										[1] = { start = 0, color = RGB(50, 50, 50) },
										[2] = { start = 3, color = RGB(30, 30, 30) },
									})
								end
							end
						end
					end
				end
			end
		end
		if menu.open then
			if menu.options["Settings"]["Cheat Settings"]["Menu Accent"][1] then
				local clr = menu.options["Settings"]["Cheat Settings"]["Menu Accent"][5][1]
				menu.mc = { clr[1], clr[2], clr[3] }
			else
				menu.mc = { 127, 72, 163 }
			end
			menu:set_menu_clr(menu.mc[1], menu.mc[2], menu.mc[3])

			local wme = menu:GetVal("Settings", "Cheat Settings", "Watermark")
			for k, v in pairs(menu.watermark.rect) do
				v.Visible = wme
			end
			menu.watermark.text[1].Visible = wme
		end
	end

	local function mousebutton1upfunc()
		cp.dragging_m = false
		cp.dragging_r = false
		cp.dragging_b = false
		for k, v in pairs(menu.options) do
			if menu.tabnames[menu.activetab] == k then
				for k1, v1 in pairs(v) do
					for k2, v2 in pairs(v1) do
						if v2[2] == "slider" and v2[5] then
							v2[5] = false
						end
						if v2[2] == "button" and v2[1] then
							for i = 0, 8 do
								v2[4][i + 1].Color = ColorRange(i, {
									[1] = { start = 0, color = RGB(50, 50, 50) },
									[2] = { start = 8, color = RGB(35, 35, 35) },
								})
							end
							v2[1] = false
						end
					end
				end
			end
		end
	end

	local clickspot_x, clickspot_y, original_menu_x, original_menu_y = 0, 0, 0, 0

	menu.connections.mwf = LOCAL_MOUSE.WheelForward:Connect(function()
		if menu.open then
			for k, v in pairs(menu.options) do
				if menu.tabnames[menu.activetab] == k then
					for k1, v1 in pairs(v) do
						for k2, v2 in pairs(v1) do
							if v2[2] == "list" then
								if v2[3] > 1 then
									v2[3] -= 1
								end
							end
						end
					end
				end
			end
		end
	end)

	menu.connections.mwb = LOCAL_MOUSE.WheelBackward:Connect(function()
		if menu.open then
			for k, v in pairs(menu.options) do
				if menu.tabnames[menu.activetab] == k then
					for k1, v1 in pairs(v) do
						for k2, v2 in pairs(v1) do
							if v2[2] == "list" then
								if v2[5][v2[3] + v2[6]] ~= nil then
									v2[3] += 1
								end
							end
						end
					end
				end
			end
		end
	end)

	function menu:set_menu_alphaparency(transparency)
		for k, v in pairs(bbmouse) do
			v.Transparency = transparency / 255
		end
		for k, v in pairs(bbmenu) do
			v.Transparency = transparency / 255
		end
		for k, v in pairs(tabz[menu.activetab]) do
			v.Transparency = transparency / 255
		end
	end

	function menu:set_menu_visibility(visible)
		for k, v in pairs(bbmouse) do
			v.Visible = visible
		end
		for k, v in pairs(bbmenu) do
			v.Visible = visible
		end
		for k, v in pairs(tabz[menu.activetab]) do
			v.Visible = visible
		end

		if visible then
			for k, v in pairs(menu.multigroups) do
				if menu.tabnames[menu.activetab] == k then
					for k1, v1 in pairs(v) do
						for k2, v2 in pairs(v1.vals) do
							for k3, v3 in pairs(menu.mgrouptabz[k][k2]) do
								v3.Visible = v2
							end
						end
					end
				end
			end
		end
	end

	menu:set_menu_alphaparency(0)
	menu:set_menu_visibility(false)
	menu.lastActive = true
	menu.open = false
	menu.windowactive = true
	menu.connections.mousemoved = MouseMoved:connect(function(b)
		menu.windowactive = iswindowactive() or b
	end)

	local function renderSteppedMenu(fdt)
		menu.dt = fdt
		if menu.unloaded then
			return
		end
		SCREEN_SIZE = Camera.ViewportSize
		-- i pasted the old menu working ingame shit from the old source nate pls fix ty
		-- this is the really shitty alive check that we've been using since day one
		-- removed it :DDD
		-- im keepin all of our comments they're fun to look at
		-- i wish it showed comment dates that would be cool
		-- nah that would suck fk u (comment made on 3/4/2021 3:35 pm est by bitch)

		if menu.lastActive ~= menu.windowactive then
			setfpscap(menu.windowactive and (maxfps or 144) or 15)
		end

		menu.lastActive = menu.windowactive
		for button, time in next, buttonsInQue do
			if time and tick() - time < doubleclickDelay then
				button[4].text.Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
				button[4].text.Text = "Confirm?"
			else
				button[4].text.Color = Color3.new(1, 1, 1)
				button[4].text.Text = button.name
			end
		end
        -- Only free the cursor when OUR menu is open; never force LockCenter (let the game manage it)
        if menu.open then
            INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
        end
        --[[ if menu.open then
			if client.char.alive then
				INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
			else
				INPUT_SERVICE.MouseIconEnabled = false
			end
		else
			if client.char.alive then
				INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
				INPUT_SERVICE.MouseIconEnabled = false
			else
				INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
				INPUT_SERVICE.MouseIconEnabled = true
			end
		end ]]
		if menu.open then
			if menu.backspaceheld then
				local dt = tick() - menu.backspacetime
				if dt > 0.4 then
					menu.backspaceflags += 1
					if menu.backspaceflags % 5 == 0 then
						local textbox = menu.textboxopen
						textbox[1] = string.sub(textbox[1], 0, #textbox[1] - 1)
						textbox[4].Text = textbox[1] .. "|"
					end
				end
			end
		end
		if menu.fading then
			if menu.open then
				local timesincefade = tick() - menu.fadestart
				local fade_amount = 255 - math.floor((timesincefade * 10) * 255)
				set_plusminus(0, 20, 20)
				menu:set_menu_alphaparency(fade_amount)
				if fade_amount <= 0 then
					menu.open = false
					menu.fading = false
					menu:set_menu_alphaparency(0)
					menu:set_menu_visibility(false)
					-- Restore game cursor control when menu fully closes
					INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
					INPUT_SERVICE.MouseIconEnabled = false
				else
					menu:set_menu_alphaparency(fade_amount)
				end
			else
				menu:set_menu_visibility(true)
				setActiveTab(menu.activetab)
				local timesincefade = tick() - menu.fadestart
				local fade_amount = math.floor((timesincefade * 10) * 255)
				menu.fadeamount = fade_amount
				menu:set_menu_alphaparency(fade_amount)
				if fade_amount >= 255 then
					menu.open = true
					menu.fading = false
					menu:set_menu_alphaparency(255)
				else
					menu:set_menu_alphaparency(fade_amount)
				end
			end
		end
		menu:set_mouse_pos(LOCAL_MOUSE.x, LOCAL_MOUSE.y)
		set_tooltip(nil, nil, nil, false, fdt)
		if menu.open or menu.fading then
			set_plusminus(0, 20, 20)
			for k, v in pairs(menu.options) do
				if menu.tabnames[menu.activetab] == k then
					for k1, v1 in pairs(v) do
						local pass = true
						for k3, v3 in pairs(menu.multigroups) do
							if k == k3 then
								for k4, v4 in pairs(v3) do
									for k5, v5 in pairs(v4.vals) do
										if k1 == k5 then
											pass = v5
										end
									end
								end
							end
						end

						if pass then
							for k2, v2 in pairs(v1) do
								if v2[2] == "toggle" then
									if not menu.dropbox_open and not menu.colorpicker_open then
										if menu.open and menu:MouseInMenu(v2[3][1], v2[3][2], 30 + v2[4][5].TextBounds.x, 16)
										then
											if v2.tooltip then
												set_tooltip(
													menu.x + v2[3][1],
													menu.y + v2[3][2] + 18,
													v2.tooltip,
													true,
													fdt * 2--[[this is really fucking stupid]]
												)
											end
										end
									end
								elseif v2[2] == "slider" then
									if v2[5] then
										local new_val = (v2[6][2] - v2[6][1])  * (
												(
													LOCAL_MOUSE.x
													- menu.x
													- v2[3][1]
												) / v2[3][3]
											)
										v2[1] = (
												not v2.decimal and math.floor(new_val) or math.floor(new_val / v2.decimal) * v2.decimal
											) + v2[6][1]
										if v2[1] < v2[6][1] then
											v2[1] = v2[6][1]
										elseif v2[1] > v2[6][2] then
											v2[1] = v2[6][2]
										end
										local decplaces = v2.decimal and string.rep("0", math.log(1 / v2.decimal) / math.log(10))
										if decplaces and math.abs(v2[1]) < v2.decimal then
											v2[1] = 0
										end

										v2[4][5].Text = v2.custom[v2[1]] or (v2[1] == math.floor(v2[1]) and v2.decimal) and tostring(v2[1]) .. "." .. decplaces .. v2[4][6] or tostring(v2[1]) .. v2[4][6]
										for i = 1, 4 do
											v2[4][i].Size = Vector2.new(
												(v2[3][3] - 4) * ((v2[1] - v2[6][1]) / (v2[6][2] - v2[6][1])),
												2
											)
										end
										set_plusminus(1, v2[7][1], v2[7][2])
									else
										if not menu.dropbox_open then
											if menu:MouseInMenu(v2[3][1], v2[3][2], v2[3][3], 28) then
												if menu:MouseInMenu(v2[7][1], v2[7][2], 22, 13) then
													if menu:MouseInMenu(v2[7][1], v2[7][2], 11, 13) then
														set_plusminus(2, v2[7][1], v2[7][2])
													elseif menu:MouseInMenu(v2[7][1] + 11, v2[7][2], 11, 13) then
														set_plusminus(3, v2[7][1], v2[7][2])
													end
												else
													set_plusminus(1, v2[7][1], v2[7][2])
												end
											end
										end
									end
								elseif v2[2] == "list" then
									for k3, v3 in pairs(v2[4].liststuff) do
										for i, v4 in ipairs(v3) do
											for i1, v5 in ipairs(v4) do
												v5.Visible = false
											end
										end
									end
									for i = 1, v2[6] do
										if v2[5][i + v2[3] - 1] ~= nil then
											for i1 = 1, v2[7] do
												v2[4].liststuff.words[i][i1].Text = v2[5][i + v2[3] - 1][i1][1]
												v2[4].liststuff.words[i][i1].Visible = true

												if v2[5][i + v2[3] - 1][i1][1] == v2[1] and i1 == 1 then
													if menu.options["Settings"]["Cheat Settings"]["Menu Accent"][1]
													then
														local clr = menu.options["Settings"]["Cheat Settings"]["Menu Accent"][5][1]
														v2[4].liststuff.words[i][i1].Color = RGB(clr[1], clr[2], clr[3])
													else
														v2[4].liststuff.words[i][i1].Color = RGB(menu.mc[1], menu.mc[2], menu.mc[3])
													end
												else
													v2[4].liststuff.words[i][i1].Color = v2[5][i + v2[3] - 1][i1][2]
												end
											end
											for k3, v3 in pairs(v2[4].liststuff.rows[i]) do
												v3.Visible = true
											end
										elseif v2[3] > 1 then
											v2[3] -= 1
										end
									end
									if v2[3] == 1 then
										for k3, v3 in pairs(v2[4].uparrow) do
											if v3.Visible then
												v3.Visible = false
											end
										end
									else
										for k3, v3 in pairs(v2[4].uparrow) do
											if not v3.Visible then
												v3.Visible = true
												menu:SetMenuPos(menu.x, menu.y)
											end
										end
									end
									if v2[5][v2[3] + v2[6]] == nil then
										for k3, v3 in pairs(v2[4].downarrow) do
											if v3.Visible then
												v3.Visible = false
											end
										end
									else
										for k3, v3 in pairs(v2[4].downarrow) do
											if not v3.Visible then
												v3.Visible = true
												menu:SetMenuPos(menu.x, menu.y)
											end
										end
									end
								end
							end
						end
					end
				end
			end
			menu.inmenu = LOCAL_MOUSE.x > menu.x and LOCAL_MOUSE.x < menu.x + menu.w and LOCAL_MOUSE.y > menu.y - 32 and LOCAL_MOUSE.y < menu.y + menu.h
			menu.inmiddlemenu = LOCAL_MOUSE.x > menu.x + 9 and LOCAL_MOUSE.x < menu.x + menu.w - 9 and LOCAL_MOUSE.y > menu.y - 9 and LOCAL_MOUSE.y < menu.y + menu.h - 47
			if (
					--[[(
						LOCAL_MOUSE.x > menu.x and LOCAL_MOUSE.x < menu.x + menu.w and LOCAL_MOUSE.y > menu.y - 32 and LOCAL_MOUSE.y < menu.y - 11
					)]]
					(
						menu.inmenu and 
						not menu.inmiddlemenu
					) or menu.dragging
				) and not menu.dontdrag
			then
				if menu.mousedown then
					if not menu.dragging then
						clickspot_x = LOCAL_MOUSE.x
						clickspot_y = LOCAL_MOUSE.y - 36 original_menu_X = menu.x original_menu_y = menu.y
						menu.dragging = true
					end
					menu.x = (original_menu_X - clickspot_x) + LOCAL_MOUSE.x
					menu.y = (original_menu_y - clickspot_y) + LOCAL_MOUSE.y - 36
					if menu.y < 0 then
						menu.y = 0
					end
					if menu.x < -menu.w / 4 * 3 then
						menu.x = -menu.w / 4 * 3
					end
					if menu.x + menu.w / 4 > SCREEN_SIZE.x then
						menu.x = SCREEN_SIZE.x - menu.w / 4
					end
					if menu.y > SCREEN_SIZE.y - 20 then
						menu.y = SCREEN_SIZE.y - 20
					end
					menu:SetMenuPos(menu.x, menu.y)
				else
					menu.dragging = false
				end
			elseif menu.mousedown then
				menu.dontdrag = true
			elseif not menu.mousedown then
				menu.dontdrag = false
			end
			if menu.colorpicker_open then
				if cp.dragging_m then
					set_dragbar_m(
						clamp(LOCAL_MOUSE.x, cp.x + 12, cp.x + 167) - 2,
						clamp(LOCAL_MOUSE.y + 36, cp.y + 25, cp.y + 180) - 2
					)

					cp.hsv.s = (clamp(LOCAL_MOUSE.x, cp.x + 12, cp.x + 167) - cp.x - 12) / 155
					cp.hsv.v = 1 - ((clamp(LOCAL_MOUSE.y + 36, cp.y + 23, cp.y + 178) - cp.y - 23) / 155)
					newcolor.Color = Color3.fromHSV(cp.hsv.h, cp.hsv.s, cp.hsv.v)
				elseif cp.dragging_r then
					set_dragbar_r(cp.x + 175, clamp(LOCAL_MOUSE.y + 36, cp.y + 23, cp.y + 178))

					maincolor.Color = Color3.fromHSV(
							1 - ((clamp(LOCAL_MOUSE.y + 36, cp.y + 23, cp.y + 178) - cp.y - 23) / 155),
							1,
							1
						)

					cp.hsv.h = 1 - ((clamp(LOCAL_MOUSE.y + 36, cp.y + 23, cp.y + 178) - cp.y - 23) / 155)
					newcolor.Color = Color3.fromHSV(cp.hsv.h, cp.hsv.s, cp.hsv.v)
				elseif cp.dragging_b then
					set_dragbar_b(clamp(LOCAL_MOUSE.x, cp.x + 10, cp.x + 168), cp.y + 188)
					newcolor.Transparency = (clamp(LOCAL_MOUSE.x, cp.x + 10, cp.x + 168) - cp.x - 10) / 158
					cp.hsv.a = math.floor(((clamp(LOCAL_MOUSE.x, cp.x + 10, cp.x + 168) - cp.x - 10) / 158) * 255)
				else
					local setvisnew = menu:MouseInColorPicker(197, 37, 75, 40)
					for i, v in ipairs(newcopy) do
						v.Visible = setvisnew
					end

					local setvisold = menu:MouseInColorPicker(197, 91, 75, 40)
					for i, v in ipairs(oldcopy) do
						v.Visible = setvisold
					end
				end
			end
		else
			menu.dragging = false
		end
	end

	menu.connections.inputstart = INPUT_SERVICE.InputBegan:Connect(function(input)
		if menu then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				menu.mousedown = true
				if menu.open and not menu.fading then
					mousebutton1downfunc()
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				if menu.open and not menu.fading then
					mousebutton2downfunc()
				end
			end

			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode.Name:match("Shift") then
					local kcn = input.KeyCode.Name
					local direction = kcn:split("Shift")[1]
					menu.modkeys.shift.direction = direction:lower()
				end
				if input.KeyCode.Name:match("Alt") then
					local kcn = input.KeyCode.Name
					local direction = kcn:split("Alt")[1]
					menu.modkeys.alt.direction = direction:lower()
				end
			end
			if not menu then
				return
			end -- this fixed shit with unload
			menu:InputBeganMenu(input)
			menu:InputBeganKeybinds(input)
			if menu.open then
				if menu.tabnames[menu.activetab] == "Settings" then
					bbmenu[27].Text = menu:GetVal("Settings", "Cheat Settings", "Custom Menu Name") and menu:GetVal("Settings", "Cheat Settings", "MenuName") or "Bitch Bot"

					menu.watermark.text[1].Text = menu.options["Settings"]["Cheat Settings"]["MenuName"][1]
						.. menu.watermark.textString

					for i, v in ipairs(menu.watermark.rect) do
						local len = #menu.watermark.text[1].Text * 7 + 10
						if i == #menu.watermark.rect then
							len += 2
						end
						v.Size = Vector2.new(len, v.Size.y)
					end
				end
			end
			if input.KeyCode == Enum.KeyCode.Home then
				menu.stat_menu = not menu.stat_menu

				if graphs then
					for k, v in pairs(graphs) do
						if k ~= "other" then
							for k1, v1 in pairs(v) do
								if k1 ~= "pos" then
									for k2, v2 in pairs(v1) do
										v2.Visible = menu.stat_menu
									end
								end
							end
						end
					end

					if graphs.other then
						for k, v in pairs(graphs.other) do
							v.Visible = menu.stat_menu
						end
					end
				end
			end
		end
	end)

	menu.connections.inputended = INPUT_SERVICE.InputEnded:Connect(function(input)
		menu:InputEndedKeybinds(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			menu.mousedown = false
			if menu.open and not menu.fading then
				mousebutton1upfunc()
			end
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode.Name:match("Shift") then
				menu.modkeys.shift.direction = nil
			end
			if input.KeyCode.Name:match("Alt") then
				menu.modkeys.alt.direction = nil
			end
		end
	end)

	menu.connections.renderstepped = game.RunService.RenderStepped:Connect(renderSteppedMenu) -- fucking asshole 🖕🖕🖕

	function menu:unload()
		getgenv().v2 = nil
		self.unloaded = true

		for k, conn in next, self.connections do
			if not getrawmetatable(conn) then
				conn()
			else
				conn:Disconnect()
			end
			self.connections[k] = nil
		end

		game:service("ContextActionService"):UnbindAction("BB Keycheck")
		--[[ if self.game == "pf" then
			game:service("ContextActionService"):UnbindAction("BB PF check")
		elseif self.game == "uni" then
			game:service("ContextActionService"):UnbindAction("BB UNI check")
		end ]]

		local mt = getrawmetatable(game)

		setreadonly(mt, false)

		local oldmt = menu.oldmt

		if oldmt then
			for k, v in next, mt do
				if oldmt[k] then
					mt[k] = oldmt[k]
				end
			end
		else
			--TODO nate do this please
			-- remember to store any "game" metatable hooks PLEASE PLEASE because this will ensure it replaces the meta so that it UNLOADS properly
			--rconsoleerr("fatal error: no old game meta found! (UNLOAD PROBABLY WON'T WORK AS EXPECTED)")
		end

		setreadonly(mt, true)

		if menu.game == "pf" or menu.pfunload then
			menu:pfunload()
		end

		Draw:UnRender()
		CreateNotification = nil
		allrender = nil
		menu = nil
		Draw = nil
		self.unloaded = true
	end
end

local StatMenuRendered = event.new("StatMenuRendered")
menu.connections.heartbeatmenu = game.RunService.Heartbeat:Connect(function() --ANCHOR MENU HEARTBEAT
	if menu.y < 0 then
		menu.y = 0
		menu:SetMenuPos(menu.x, 0)
	end
	if menu.x < -menu.w / 4 * 3 then
		menu.x = -menu.w / 4 * 3
		menu:SetMenuPos(-menu.w / 4 * 3, menu.y)
	end
	if menu.x + menu.w / 4 > SCREEN_SIZE.x then
		menu.x = SCREEN_SIZE.x - menu.w / 4
		menu:SetMenuPos(SCREEN_SIZE.x - menu.w / 4, menu.y)
	end
	if menu.y > SCREEN_SIZE.y - 20 then
		menu.y = SCREEN_SIZE.y - 20
		menu:SetMenuPos(menu.x, SCREEN_SIZE.y - 20)
	end
	if menu.stat_menu == false then
		return
	end
end)

local function keycheck(actionName, inputState, inputObject)
	if actionName == "BB Keycheck" then
		if menu.open then
			if menu.textboxopen then
				if inputObject.KeyCode == Enum.KeyCode.Backspace then
					if menu.selectall then
						menu.textboxopen[1] = ""
						menu.textboxopen[4].Text = "|"
						menu.textboxopen[4].Color = RGB(unpack(menu.mc))
						menu.selectall = false
					end
					local on = inputState == Enum.UserInputState.Begin
					menu.backspaceheld = on
					menu.backspacetime = on and tick() or -1
					if not on then
						menu.backspaceflags = 0
					end
				end

				if inputObject.KeyCode ~= Enum.KeyCode.A and (not inputObject.KeyCode.Name:match("^Left") and not inputObject.KeyCode.Name:match("^Right")) and inputObject.KeyCode ~= Enum.KeyCode.RightShift
				then
					if menu.selectall then
						menu.textboxopen[4].Color = RGB(unpack(menu.mc))
						menu.selectall = false
					end
				end

				if inputObject.KeyCode == Enum.KeyCode.A then
					if inputState == Enum.UserInputState.Begin and INPUT_SERVICE:IsKeyDown(Enum.KeyCode.LeftControl)
					then
						menu.selectall = true
						local textbox = menu.textboxopen
						textbox[4].Color = RGB(menu.mc[3], menu.mc[2], menu.mc[1])
					end
				end

				return Enum.ContextActionResult.Sink
			end
		end

		return Enum.ContextActionResult.Pass
	end
end

game:service("ContextActionService"):BindAction("BB Keycheck", keycheck, false, Enum.UserInputType.Keyboard)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- FPS Unlocker: remove Roblox's 60fps cap at the earliest possible moment
pcall(function()
    if setfpscap then
        setfpscap(0) -- 0 = unlimited
    end
end)

if getgenv().OnyxLoaded == false or getgenv().OnyxLoaded == nil then
task.spawn(function() -- async: never blocks the game thread
-- Split into two functions so each gets a fresh 200-local budget (Luau limit)
local function _onyxGameLogic()

-- services
getgenv().Services = {}

getgenv().Services.Players            = game:GetService("Players")
getgenv().Services.ReplicatedFirst    = game:GetService("ReplicatedFirst")
getgenv().Services.ReplicatedStorage  = game:GetService("ReplicatedStorage")
getgenv().Services.RunService         = game:GetService("RunService")
getgenv().Services.UserInputService   = game:GetService("UserInputService")
getgenv().Services.Workspace          = game:GetService("Workspace")
getgenv().Services.Lighting           = game:GetService("Lighting")
getgenv().Services.CollectionService  = game:GetService("CollectionService")
getgenv().Services.HttpService        = game:GetService("HttpService")
pcall(function() getgenv().Services.NetworkClient = game:GetService("NetworkClient") end)
pcall(function() getgenv().Services.MarketplaceService = game:GetService("MarketplaceService") end)
pcall(function() getgenv().Services.TweenService = game:GetService("TweenService") end)
pcall(function() getgenv().Services.VirtualInputManager = game:GetService("VirtualInputManager") end)

getgenv().Players            = getgenv().Services.Players
getgenv().ReplicatedFirst    = getgenv().Services.ReplicatedFirst
getgenv().ReplicatedStorage  = getgenv().Services.ReplicatedStorage
getgenv().RunService         = getgenv().Services.RunService
getgenv().UserInputService   = getgenv().Services.UserInputService
getgenv().Workspace          = getgenv().Services.Workspace
getgenv().Lighting           = getgenv().Services.Lighting
getgenv().CollectionService  = getgenv().Services.CollectionService
getgenv().HttpService        = getgenv().Services.HttpService

local Players            = getgenv().Players
local ReplicatedFirst    = getgenv().ReplicatedFirst
local ReplicatedStorage  = getgenv().ReplicatedStorage
local RunService         = getgenv().RunService
local UserInputService   = getgenv().UserInputService
local Workspace          = getgenv().Workspace
local Lighting           = getgenv().Lighting
local CollectionService  = getgenv().CollectionService
local HttpService        = getgenv().HttpService

getgenv().LocalPlayer = getgenv().Players.LocalPlayer
local LocalPlayer     = getgenv().LocalPlayer

function getCamera()
    return Workspace.CurrentCamera
end

getgenv().Camera = getCamera()
local Camera     = getgenv().Camera

-- anti cheat bypass
local detectedScripts = {
    ["localscript3"] = true,
    ["miscellaneouscontroller"] = true,
    ["clientfighter"] = true,
}

local old_setmt; old_setmt = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
    if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
        local trace = debug.traceback()
        if trace:find("MiscellaneousController") then
            return old_setmt({1, 2, 3}, {})
        end
    end
    return old_setmt(tbl, mt)
end))

local overflow = false
local original_index; original_index = hookmetamethod(game, "__index", newcclosure(function(self, key, ...)
    if overflow then
        return original_index(self, key, ...)
    end
    overflow = true
    local caller = getcallingscript()
    if caller and detectedScripts[caller.Name:lower()] and (key == "Text" or key == "Name") then
        overflow = false
        return ""
    end
    overflow = false
    return original_index(self, key, ...)
end))

coroutine.wrap(function()
    pcall(function()
        local acTags = {"anticheat", "ac", "detection", "ban", "kick", "security", "moderation"}

        local function blockScript(obj)
            pcall(function()
                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local ok, name = pcall(function() return obj.Name:lower() end)
                    if not ok or not name then return end
                    for _, tag in ipairs(acTags) do
                        if name:find(tag) then
                            pcall(function() obj.Disabled = true end)
                            break
                        end
                    end
                end
            end)
        end

        pcall(function()
            for _, obj in ipairs(game:GetDescendants()) do
                blockScript(obj)
            end
        end)

        pcall(function()
            game.DescendantAdded:Connect(blockScript)
        end)
    end)

    pcall(function()
        local networkClient = game:GetService("NetworkClient")
        if networkClient then
            networkClient.ChildAdded:Connect(function(child)
                pcall(function()
                    local ok, name = pcall(function() return child.Name:lower() end)
                    if ok and name then
                        if name:find("anticheat") or name:find("detection") then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end)
            end)
        end
    end)
end)()

local fakeClientAlert
pcall(function()
    fakeClientAlert = Instance.new("RemoteEvent")
    fakeClientAlert.Name = "ClientAlert"
    fakeClientAlert.Parent = LocalPlayer
end)

pcall(function()
    local ls3 = ReplicatedFirst:WaitForChild("LocalScript3", 10)

    for _, fn in ipairs(getgc(false)) do
        if type(fn) ~= "function" then continue end

        local okEnv, env = pcall(getfenv, fn)
        if not okEnv or type(env) ~= "table" then continue end

        local okScr, scr = pcall(function() return rawget(env, "script") end)
        if not okScr or not scr or typeof(scr) ~= "Instance" then continue end

        local okStr, scrStr = pcall(tostring, scr)
        if not okStr then continue end

        local matches = (scr == ls3) or (type(scrStr) == "string" and scrStr:find("LoadingScreen"))
        if not matches then continue end

        local okConsts, consts = pcall(debug.getconstants, fn)
        if not okConsts or type(consts) ~= "table" then continue end

        for _, const in ipairs(consts) do
            if type(const) == "string" and (const:find("TakeTheL") or const:find("ban") or const:find("kick")) then
                pcall(function()
                    hookfunction(fn, function() end)
                end)
                break
            end
        end
    end
end)

-- utility functions
function isLobbyVisible()
    local success, result = pcall(function()
        return LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
    end)
    return success and result or false
end

function isTeammate(player)
    if not player then return false end
    local char = player.Character
    if not char then return false end
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and humanoidRootPart:FindFirstChild("TeammateLabel") then
        return true
    end
    return false
end

function isCharacterValid(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

function getAimPart(entity, aimPartName)
    if not entity then return nil end
    if aimPartName == "Random" then
        local parts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}
        return entity:FindFirstChild(parts[math.random(#parts)], true)
    end
    local part = entity:FindFirstChild(aimPartName, true)
    if part and part:IsA("BasePart") then return part end
    for _, name in ipairs({"Head", "UpperTorso", "HumanoidRootPart", "Torso"}) do
        local p = entity:FindFirstChild(name, true)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end

function isEntityVisible(entity, aimPart)
    if not entity or not aimPart then return false end
    local origin = Camera.CFrame.Position
    local direction = aimPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(entity)
end

function normalizePartName(name)
    if type(name) ~= "string" then return name end
    local map = {
        head             = "Head",
        humanoidrootpart = "HumanoidRootPart",
        uppertorso       = "UpperTorso",
        lowertorso       = "LowerTorso",
        torso            = "Torso",
        closest          = "Closest",
        random           = "Random",
        leftupperarm     = "LeftUpperArm",
        leftlowerarm     = "LeftLowerArm",
        rightupperarm    = "RightUpperArm",
        rightlowerarm    = "RightLowerArm",
        leftupperleg     = "LeftUpperLeg",
        leftlowerleg     = "LeftLowerLeg",
        rightupperleg    = "RightUpperLeg",
        rightlowerleg    = "RightLowerLeg",
    }
    return map[name:lower()] or name
end

getgenv().normalizePartName = normalizePartName

function worldToScreen(worldPos, cam)
    cam = cam or workspace.CurrentCamera
    if not cam or not worldPos then return nil, false end
    local v, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen or v.Z <= 0 then return v, false end
    return v, true
end

function screenCenter(cam)
    cam = cam or workspace.CurrentCamera
    if not cam then return Vector2.zero end
    return cam.ViewportSize / 2
end

-- Aimbot
getgenv().Aimbot = {
    Enabled = false,
    AimPart = "Head",
    Sensitivity = 15,
    Deadzone = 5,
    Prediction = 0.12,
    WallCheck = false,
    PersistTarget = false,
    PersistTime = 0.35,
    AimRadius = 150,
    UseFOV = true,
    FovShow = false,
    FovOutlineShow = false,
    FovOutlineColor = Color3.fromRGB(255, 255, 255),
    FovOutlineTransparency = 0.4,
    FovOutlineThickness = 1.5,
    FovFilled = false,
    FovFilledColor = Color3.fromRGB(255, 255, 255),
    FovBackgroundTransparency = 0.15,
}

getgenv().AimbotCurrentTarget = nil
getgenv().AimbotLastTargetTime = 0

if getgenv().AimbotFOVConnection then getgenv().AimbotFOVConnection:Disconnect() getgenv().AimbotFOVConnection = nil end
if getgenv().AimbotFOVCircleOutline then pcall(function() getgenv().AimbotFOVCircleOutline:Remove() end) getgenv().AimbotFOVCircleOutline = nil end
if getgenv().AimbotFOVCircleFill then pcall(function() getgenv().AimbotFOVCircleFill:Remove() end) getgenv().AimbotFOVCircleFill = nil end

local AimbotOutlineCircle = Drawing.new("Circle")
AimbotOutlineCircle.NumSides = 100
AimbotOutlineCircle.Filled = false
AimbotOutlineCircle.Visible = false
getgenv().AimbotFOVCircleOutline = AimbotOutlineCircle

local AimbotFillCircle = Drawing.new("Circle")
AimbotFillCircle.NumSides = 100
AimbotFillCircle.Filled = true
AimbotFillCircle.Visible = false
getgenv().AimbotFOVCircleFill = AimbotFillCircle

function IsAimbotTargetValid(player)
    local cfg = getgenv().Aimbot
    if not isCharacterValid(player) then return false end

    local char = player.Character
    local partName = normalizePartName(cfg.AimPart)
    local part = char:FindFirstChild(partName)

    if isTeammate(player) then return false end

    if not part then return false end

    if cfg.WallCheck then
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin)

        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist

        local result = Workspace:Raycast(origin, direction, rayParams)
        if result and not result.Instance:IsDescendantOf(char) then
            return false
        end
    end

    return true
end

function GetClosestAimbotTarget()
    local cfg = getgenv().Aimbot
    local closest = nil
    local shortest = math.huge
    local mouseLocation = UserInputService:GetMouseLocation()
    local partName = normalizePartName(cfg.AimPart)

    for _, player in pairs(Players:GetPlayers()) do
        if IsAimbotTargetValid(player) then
            local part = player.Character[partName]
            local pos, visible = Camera:WorldToViewportPoint(part.Position)

            if visible and pos.Z > 0 then
                local dist = (mouseLocation - Vector2.new(pos.X, pos.Y)).Magnitude
                local inFOV = (not cfg.UseFOV) or (dist <= cfg.AimRadius)

                if inFOV and dist < shortest then
                    shortest = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

getgenv().AimbotFOVConnection = RunService.RenderStepped:Connect(function(deltaTime)
    local success, err = pcall(function()
        local cfg = getgenv().Aimbot

        if isLobbyVisible() or shouldSuppressGameplayOverlays() then
            AimbotOutlineCircle.Visible = false
            AimbotFillCircle.Visible = false
            getgenv().AimbotCurrentTarget = nil
            return
        end

        local isMasterVisible = cfg.FovShow and cfg.FovOutlineShow
        local maxRadius = cfg.AimRadius or 100

        local screenCenter = Camera.ViewportSize / 2
        local mouseLocation = UserInputService:GetMouseLocation()

        if isMasterVisible then
            AimbotOutlineCircle.Position = screenCenter
            AimbotOutlineCircle.Radius = maxRadius
            AimbotOutlineCircle.Color = cfg.FovOutlineColor or Color3.fromRGB(255, 255, 255)
            AimbotOutlineCircle.Transparency = cfg.FovOutlineTransparency or 1
            AimbotOutlineCircle.Thickness = cfg.FovOutlineThickness or 1
            AimbotOutlineCircle.Visible = true

            if cfg.FovFilled then
                AimbotFillCircle.Position = screenCenter
                AimbotFillCircle.Radius = maxRadius
                AimbotFillCircle.Color = cfg.FovFilledColor or Color3.fromRGB(255, 255, 255)
                AimbotFillCircle.Transparency = cfg.FovBackgroundTransparency or 0.15
                AimbotFillCircle.Visible = true
            else
                AimbotFillCircle.Visible = false
            end
        else
            AimbotOutlineCircle.Visible = false
            AimbotFillCircle.Visible = false
        end

        if not cfg.Enabled then
            getgenv().AimbotCurrentTarget = nil
            return
        end

        if cfg.PersistTarget then
            if getgenv().AimbotCurrentTarget and IsAimbotTargetValid(getgenv().AimbotCurrentTarget) then
                if tick() - getgenv().AimbotLastTargetTime >= cfg.PersistTime then
                    getgenv().AimbotCurrentTarget = GetClosestAimbotTarget()
                    getgenv().AimbotLastTargetTime = tick()
                end
            else
                getgenv().AimbotCurrentTarget = GetClosestAimbotTarget()
                getgenv().AimbotLastTargetTime = tick()
            end
        else
            getgenv().AimbotCurrentTarget = GetClosestAimbotTarget()
        end

        if getgenv().AimbotCurrentTarget then
            local partName = normalizePartName(cfg.AimPart)
            local part = getgenv().AimbotCurrentTarget.Character[partName]
            local velocity = part.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
            local predictedPosition = part.Position + (velocity * cfg.Prediction)
            local pos, visible = Camera:WorldToViewportPoint(predictedPosition)

            if visible then
                local delta = Vector2.new(pos.X - mouseLocation.X, pos.Y - mouseLocation.Y)
                if delta.Magnitude <= cfg.Deadzone then return end
                local sensitivity = math.clamp(cfg.Sensitivity or 15, 1, 100)
                local multiplier = sensitivity / 100
                if mousemoverel then
                    mousemoverel(delta.X * multiplier, delta.Y * multiplier)
                end
            end
        end
    end)
    if not success then warn("Aimbot/FOV Error: " .. tostring(err)) end
end)

-- TriggerBot
getgenv().TriggerBot = {
    Enabled = false,
    FireRate = 0,
    WallCheck = true,
    BlacklistBody = {
        Head = false, UpperTorso = false, LowerTorso = false,
        LeftUpperArm = false, LeftLowerArm = false, RightUpperArm = false, RightLowerArm = false,
        LeftUpperLeg = false, LeftLowerLeg = false, RightUpperLeg = false, RightLowerLeg = false,
    },
    BodyPartsList = {
        "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm",
        "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"
    }
}

function ToggleBlacklistBody(partName)
    local cfg = getgenv().TriggerBot
    if cfg.BlacklistBody[partName] ~= nil then
        cfg.BlacklistBody[partName] = not cfg.BlacklistBody[partName]
        return cfg.BlacklistBody[partName]
    end
    return false
end

function GetBlacklistBodyStatus(partName)
    return getgenv().TriggerBot.BlacklistBody[partName] or false
end

function GetBlacklistedParts()
    local blacklisted = {}
    for partName, isBlacklisted in pairs(getgenv().TriggerBot.BlacklistBody) do
        if isBlacklisted then table.insert(blacklisted, partName) end
    end
    return blacklisted
end

getgenv().TriggerBotLastFire = 0

function IsValidTriggerTarget(player)
    local cfg = getgenv().TriggerBot
    if not isCharacterValid(player) then return false end

    local character = player.Character

    if isTeammate(player) then return false end

    local isR15 = character:FindFirstChild("UpperTorso") ~= nil
    local targetParts = {}

    if isR15 then
        for _, partName in ipairs(cfg.BodyPartsList) do
            if not cfg.BlacklistBody[partName] then
                local part = character:FindFirstChild(partName)
                if part then table.insert(targetParts, part) end
            end
        end
    else
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("Torso")

        if head and not cfg.BlacklistBody["Head"] then table.insert(targetParts, head) end
        if torso and not cfg.BlacklistBody["UpperTorso"] then table.insert(targetParts, torso) end
    end

    if #targetParts == 0 then return false end

    if cfg.WallCheck then
        local origin = Camera.CFrame.Position
        local checkPart = targetParts[1]
        local direction = checkPart.Position - origin
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = { LocalPlayer.Character }

        local result = Workspace:Raycast(origin, direction, rayParams)
        if result and not result.Instance:IsDescendantOf(character) then
            return false
        end
    end

    return true, targetParts
end

function GetMouseTargetPlayer()
    local cfg = getgenv().TriggerBot
    local Mouse = LocalPlayer:GetMouse()
    local target = Mouse.Target
    if not target then return nil end

    local character = target:FindFirstAncestorOfClass("Model")
    if not character then return nil end

    if character:IsA("Accessory") then character = character.Parent end

    local targetPlayer = Players:GetPlayerFromCharacter(character)
    if not targetPlayer then return nil end

    local actualPartName = target.Name
    if target.Parent and target.Parent:IsA("Accessory") then actualPartName = "Head" end

    if cfg.BlacklistBody[actualPartName] == true then return nil end

    local isValid = IsValidTriggerTarget(targetPlayer)
    if not isValid then return nil end

    return targetPlayer
end

function Fire()
    mouse1click()
end

getgenv().TriggerBotConnection = RunService.RenderStepped:Connect(function(deltaTime)
    local success, err = pcall(function()
        local cfg = getgenv().TriggerBot

        if isLobbyVisible() then return end
        if not cfg.Enabled then return end

        local now = tick()
        if now - getgenv().TriggerBotLastFire < cfg.FireRate then return end

        local targetPlayer = GetMouseTargetPlayer()

        if targetPlayer then
            getgenv().TriggerBotLastFire = now
            Fire()
        end
    end)
    if not success then warn("TriggerBot Error: " .. tostring(err)) end
end)

-- Silent Aim
local ok, err = pcall(function()

local Camera = getCamera()
local Utility = require(ReplicatedStorage.Modules.Utility)
local EnumLibrary = require(ReplicatedStorage.Modules.EnumLibrary)
local GameplayUtility = require(ReplicatedStorage.Modules.GameplayUtility)

getgenv().SilentAim = {
    Enabled = false,
    AimPart = "Head",
    Method = "FOV",
    AutoShoot = false,
    ClickInterval = 0.10,
    WallCheck = false,
    FOV = 300,
    ShowFOV = false,
    FovOutlineShow = false,
    FovOutlineColor = Color3.fromRGB(255, 255, 255),
    FovOutlineTransparency = 0.4,
    FovOutlineThickness = 1.5,
    FovFilled = false,
    FovFilledColor = Color3.fromRGB(255, 255, 255),
    FovBackgroundTransparency = 0.15,
    RandomAimParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
}

getgenv().SilentAimTargetEntity = nil
getgenv().SilentAimTargetPart = nil
getgenv().SilentAimAutoClickConnection = nil
getgenv().LastClickTime = 0

if getgenv().SilentAimFOVCircleOutline then pcall(function() getgenv().SilentAimFOVCircleOutline:Remove() end) end
if getgenv().SilentAimFOVCircleFill then pcall(function() getgenv().SilentAimFOVCircleFill:Remove() end) end

local OutlineCircle = Drawing.new("Circle")
OutlineCircle.NumSides = 100
OutlineCircle.Filled = false
OutlineCircle.Visible = false
getgenv().SilentAimFOVCircleOutline = OutlineCircle

local FillCircle = Drawing.new("Circle")
FillCircle.NumSides = 100
FillCircle.Filled = true
FillCircle.Visible = false
getgenv().SilentAimFOVCircleFill = FillCircle

function getBestSilentAimTarget()
    local cfg = getgenv().SilentAim
    if isLobbyVisible() then return nil, nil end

    local closestEntity, targetPart = nil, nil
    local shortestValue = math.huge

    local viewportSize = Camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    local localChar = LocalPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    local aimPartName = normalizePartName(cfg.AimPart)
    local method = tostring(cfg.Method or "FOV"):lower()

    for _, entity in ipairs(CollectionService:GetTagged("Entity")) do
        if entity == localChar then continue end
        if not entity:IsDescendantOf(workspace) then continue end

        local hum = entity:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local aimPart = getAimPart(entity, aimPartName)
        if not aimPart then continue end

        local plr = Players:GetPlayerFromCharacter(entity)
        if plr and isTeammate(plr) then continue end

        if cfg.WallCheck and not isEntityVisible(entity, aimPart) then continue end

        if method == "fov" then
            local sp, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            if onScreen and sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                if d <= cfg.FOV and d < shortestValue then
                    shortestValue = d
                    closestEntity = entity
                    targetPart = aimPart
                end
            end
        elseif method == "distance" then
            if localHRP then
                local d = (aimPart.Position - localHRP.Position).Magnitude
                if d < shortestValue then
                    shortestValue = d
                    closestEntity = entity
                    targetPart = aimPart
                end
            end
        end
    end

    return closestEntity, targetPart
end

local function updateFOV()
    local cfg = getgenv().SilentAim
    local visible = cfg.ShowFOV and cfg.Enabled and cfg.FovOutlineShow
    local center = Camera.ViewportSize / 2

    if visible then
        OutlineCircle.Position = center
        OutlineCircle.Radius = cfg.FOV
        OutlineCircle.Color = cfg.FovOutlineColor
        OutlineCircle.Transparency = cfg.FovOutlineTransparency
        OutlineCircle.Thickness = cfg.FovOutlineThickness
        OutlineCircle.Visible = true

        if cfg.FovFilled then
            FillCircle.Position = center
            FillCircle.Radius = cfg.FOV
            FillCircle.Color = cfg.FovFilledColor
            FillCircle.Transparency = cfg.FovBackgroundTransparency
            FillCircle.Visible = true
        else
            FillCircle.Visible = false
        end
    else
        OutlineCircle.Visible = false
        FillCircle.Visible = false
    end
end

local _fovFrame = 0
RunService.RenderStepped:Connect(function()
    _fovFrame = _fovFrame + 1
    if _fovFrame % 2 ~= 0 then return end
    pcall(updateFOV)
end)

local function stopAutoClick()
    if getgenv().SilentAimAutoClickConnection then
        getgenv().SilentAimAutoClickConnection:Disconnect()
        getgenv().SilentAimAutoClickConnection = nil
    end
end

local function startAutoClick()
    if getgenv().SilentAimAutoClickConnection then return end
    getgenv().SilentAimAutoClickConnection = RunService.Heartbeat:Connect(function()
        local cfg = getgenv().SilentAim
        if not cfg.AutoShoot then stopAutoClick() return end
        if isLobbyVisible() then return end
        if not getgenv().SilentAimTargetEntity then return end

        local now = tick()
        if now - getgenv().LastClickTime >= cfg.ClickInterval then
            getgenv().LastClickTime = now
            mouse1click()
        end
    end)
end

local oldGetEntities = GameplayUtility.GetEntitiesFromRaycast
GameplayUtility.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
    if getgenv().SilentAim.Enabled and getgenv().SilentAimTargetPart then
        local t = getgenv().SilentAimTargetPart
        local dist = (t.Position - origin).Magnitude
        dir = (t.Position - origin).Unit
        maxDist = math.max(maxDist or 0, dist + 5)
    end
    return oldGetEntities(self, envID, params, origin, dir, maxDist, ...)
end

local function CFD(origin, part)
    local cf = part.CFrame
    return {
        [utf8.char(1)] = {
            [utf8.char(0)] = Utility:EncodeCFrame(CFrame.lookAt(origin, part.Position)),
            [utf8.char(1)] = Utility:EncodeCFrame(cf),
            [utf8.char(2)] = part,
            [utf8.char(3)] = Utility:EncodeCFrame(cf:ToObjectSpace(CFrame.new(part.Position))),
        }
    }
end

local startShootEnum = EnumLibrary:ToEnum("StartShooting")
local oldFireServer
oldFireServer = hookfunction(
    ReplicatedStorage.Remotes.Replication.Fighter.UseItem.FireServer,
    newcclosure(function(self, objID, enumVal, camdata, extra)
        if getgenv().SilentAim.Enabled and enumVal == startShootEnum and getgenv().SilentAimTargetPart then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                camdata = CFD(root.Position, getgenv().SilentAimTargetPart)
            end
        end
        return oldFireServer(self, objID, enumVal, camdata, extra)
    end)
)

pcall(function()
    local gun = require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
    if gun then
        gun.IsFullyAiming = function() return true end
    end
end)

RunService.Heartbeat:Connect(function()
    Camera = workspace.CurrentCamera or Camera

    if getgenv().SilentAim.Enabled or getgenv().SilentAim.AutoShoot then
        getgenv().SilentAimTargetEntity, getgenv().SilentAimTargetPart = getBestSilentAimTarget()
    else
        getgenv().SilentAimTargetEntity, getgenv().SilentAimTargetPart = nil, nil
    end

    if getgenv().SilentAim.AutoShoot then
        if not getgenv().SilentAimAutoClickConnection then startAutoClick() end
    else
        stopAutoClick()
    end
end)
end)
if not ok then
    warn("SilentAim load error: " .. tostring(err))
end

-- Ragebot
getgenv().InstanceModuleCache = getgenv().InstanceModuleCache or {}

getgenv().shouldSuppressGameplayOverlays = getgenv().shouldSuppressGameplayOverlays or function()
    return false
end
local shouldSuppressGameplayOverlays = getgenv().shouldSuppressGameplayOverlays

local function instanceSafeRequire(moduleRef, timeoutSec)
    local cache = getgenv().InstanceModuleCache
    local key = typeof(moduleRef) == "Instance" and moduleRef:GetFullName() or tostring(moduleRef)
    if cache[key] ~= nil then return cache[key] end

    local deadline = timeoutSec and (os.clock() + timeoutSec) or math.huge
    local lastErr
    while os.clock() < deadline do
        if typeof(moduleRef) == "Instance" and not moduleRef.Parent then
            task.wait(0.1)
        else
            local ok, result = pcall(require, moduleRef)
            if ok then
                cache[key] = result
                return result
            end
            lastErr = result
            task.wait(0.1)
        end
    end
    warn("[instance] module load failed: " .. key .. " (" .. tostring(lastErr) .. ")")
    return nil
end

getgenv().InstanceRequire = instanceSafeRequire
getgenv().instanceSafeRequire = instanceSafeRequire

local Camera = getCamera()

getgenv().InstanceCombatLastShotAt = getgenv().InstanceCombatLastShotAt or 0
getgenv().InstanceUndergroundEnabled = getgenv().InstanceUndergroundEnabled or false

local function markCombatShot()
    getgenv().InstanceCombatLastShotAt = tick()
end
getgenv().InstanceMarkCombatShot = markCombatShot

getgenv().InstanceWorldToScreen = getgenv().InstanceWorldToScreen or worldToScreen
getgenv().InstanceScreenCenter = getgenv().InstanceScreenCenter or screenCenter

getgenv().ragebot = getgenv().ragebot or {}
local ragebot = getgenv().ragebot

do

local replicatedstorage = ReplicatedStorage
local players = Players
local runsvc = RunService
local userinput = UserInputService
local workspace = Workspace

local player = LocalPlayer
local camera = getCamera()

local modules = {
    enums = instanceSafeRequire(replicatedstorage.Modules.EnumLibrary, 3),
    fighter = instanceSafeRequire(player.PlayerScripts.Controllers.FighterController, 3),
    camcontrol = instanceSafeRequire(player.PlayerScripts.Controllers.CameraController, 3),
    utility = instanceSafeRequire(replicatedstorage.Modules.Utility, 3)
}

local MATCH_ID_ATTRS = {"MatchId", "DuelId", "RoundId", "GameId", "MatchUUID", "ArenaId", "InstanceId"}
local DUEL_STATE_ATTRS = {"InDuel", "InMatch", "InRound", "InGame", "InFight", "IsInMatch", "IsInDuel", "MatchActive", "Fighting"}
local SPAWN_SAFE_ATTRS = {"InSpawn", "InLobby", "IsSpectating", "InSafeZone", "InIntermission", "IsRespawning"}

local function inLive(targetPlr)
    if not targetPlr then return false end
    local live = workspace:FindFirstChild("Live")
    if not live then return false end
    if live:FindFirstChild(targetPlr.Name) then return true end
    if live:FindFirstChild(tostring(targetPlr.UserId)) then return true end
    for _, child in ipairs(live:GetChildren()) do
        if child.Name == targetPlr.Name or child.Name == tostring(targetPlr.UserId) then
            return true
        end
    end
    local char = targetPlr.Character
    if char and (char.Parent == live or char:IsDescendantOf(live)) then
        return true
    end
    local fc = modules.fighter
    if fc and type(fc.GetFighter) == "function" then
        local ok, fighter = pcall(fc.GetFighter, fc, targetPlr)
        if ok and fighter and fighter.Entity and fighter.Entity.Parent then
            if fighter.Entity.Parent == live or fighter.Entity:IsDescendantOf(live) then
                return true
            end
        end
    end
    return false
end

local function plrMid(targetPlr)
    if not targetPlr then return nil end
    for _, key in ipairs(MATCH_ID_ATTRS) do
        local v = targetPlr:GetAttribute(key)
        if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
            return tostring(v)
        end
    end
    local char = targetPlr.Character
    if char then
        for _, key in ipairs(MATCH_ID_ATTRS) do
            local v = char:GetAttribute(key)
            if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
                return tostring(v)
            end
        end
    end
    return nil
end

local function liveMatch()
    local lp = player
    if not lp then return false end
    for _, key in ipairs(SPAWN_SAFE_ATTRS) do
        local v = lp:GetAttribute(key)
        if v == true or v == 1 or v == "true" then
            return false
        end
    end
    local char = lp.Character
    if not char then return false end
    for _, key in ipairs(SPAWN_SAFE_ATTRS) do
        local cv = char:GetAttribute(key)
        if cv == true or cv == 1 or cv == "true" then
            return false
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return false end
    for _, key in ipairs(DUEL_STATE_ATTRS) do
        local v = lp:GetAttribute(key)
        if v == true or v == 1 or v == "true" then
            return true
        end
        local cv = char:GetAttribute(key)
        if cv == true or cv == 1 or cv == "true" then
            return true
        end
    end
    if inLive(lp) then
        return true
    end
    local fc = modules.fighter
    if fc and fc.LocalFighter and fc.LocalFighter.Entity and fc.LocalFighter.Entity.Parent then
        return true
    end
    local myMatchId = plrMid(lp)
    if myMatchId then
        for _, plr in players:GetPlayers() do
            if plr ~= lp and plrMid(plr) == myMatchId then
                return true
            end
        end
    end
    if fc then
        for _, list in ipairs({ fc.Fighters, fc.AllFighters }) do
            if list then
                for _, f in pairs(list) do
                    if f and f.Player and f.Player ~= lp and (f.IsEnemy or f.Enemy) then
                        local fChar = f.Player.Character
                        local fHum = fChar and fChar:FindFirstChildOfClass("Humanoid")
                        if fHum and fHum.Health > 0 then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local _instanceLobbyCache = { t = 0, v = true }
local function lobbyCache()
    local now = os.clock()
    if now - _instanceLobbyCache.t < 0.15 then
        return _instanceLobbyCache.v
    end
    _instanceLobbyCache.t = now
    _instanceLobbyCache.v = not liveMatch()
    return _instanceLobbyCache.v
end

getgenv().InstanceIsInActiveMatch = liveMatch
getgenv().InstanceIsInLobby = lobbyCache

getgenv().ragebot.config = {
    target = {
        enabled = false,
        character = nil,
        auto = false,
        autoshoot = true,
        shootAttempts = 1,
        hitpart = "head",
        lastchar = nil,
        lastplayer = nil,
        manualkey = false,
        immune = true,
        attackPosition = "default",
        attackCustomEnabled = false,
        weaponPick = "primary",
        forceWeapon = true,
        rageMasterOn = false,
        meleeFeetDrop = 3.5,
        underOffset = 4,
        customHeight = 2,
        customFront = 0,
        customSide = 0,
        customVertical = 0,
        customRadius = 0,
    },
    prediction = {
        enabled = false,
        multiplier = 1.2,
        velocity = Vector3.new(0, 0, 0),
        acceleration = Vector3.new(0, 0, 0),
        lastposition = nil,
        lasttime = 0,
        velbuffer = {},
        posbuffer = {},
        maxvelsamples = 15,
        maxpossamples = 5
    },
    orbit = {
        active = false,
        angle = 0,
        serverpos = nil,
        connection = nil,
        speed = 9000,
        height = 1,
        radius = 0,
        originalpos = nil
    },
    state = {
        reloading = false,
        outofammo = false,
        csyncactive = false,
        reloadStartedAt = 0,
    },
    voidhide = {
        enabled = true,
        originalPosition = nil,
        active = false,
        connection = nil
    },
    voidspam = {
        enabled = false,
        shoot_min = 1,
        shoot_max = 1,
        hide_min = 1,
        hide_max = 1,
        phase = nil,
        lastswitch = 0,
        currentduration = 0
    },
    visualizer = {
        enabled = true,
        tracer = {
            color = Color3.fromRGB(0, 186, 255),
            thickness = 1,
            transparency = 1,
            start_point = "cursor",
            outline = true,
            outline_color = Color3.fromRGB(0, 0, 0),
            outline_thickness = 1
        },
        indicator = {
            display_options = {"name", "position", "hit reg"},
            color = Color3.fromRGB(255, 255, 255),
            accent_color = Color3.fromRGB(0, 186, 255)
        }
    },
    hitNotifications = {
        enabled = true,
        color = Color3.fromRGB(235, 235, 235),
        textSize = 14,
        maxVisible = 8,
        duration = 3,
        stackGap = 6,
        position = "Top Left",
        offsetX = 12,
        offsetY = 12,
        inAnimation = "fade bounce",
        outAnimation = "fade",
        animInDuration = 0.52,
        animOutDuration = 0.38,
    },
    ragestatus = {
        enabled = false,
        mode = "static",
        color = Color3.fromRGB(235, 235, 235),
        staticOffsetX = 0,
        staticOffsetY = 40,
        showAmmo = true,
        hideOnReload = true,
        textSize = 15,
        lineGap = 15,
        fontName = "gotham",
    },
}

getgenv().ragebot.ragePerf = {
    lastAttackTick = 0,
    hitPartByPlayer = {},
    lastHitAtByPlayer = {},
    targetHudAt = 0,
    rageStatusAt = 0,
    restoreVisualAt = 0,
    killStartAt = nil,
    rageStatusCacheAt = 0,
    cachedRageStatusLine = "",
    cachedRageStatusDetail = "",
    lastRageStatusText = "",
    lastRageDetailText = "",
    lastRageAmmoText = "",
    lastRageColor = nil,
}

getgenv().ragebot.vhState = {
    active = false,
    hrp = nil,
    mainConnection = nil,
    restoreConnection = nil,
    currentVoidPos = nil,
    lastTeleportTime = 0
}

local config = getgenv().ragebot.config
local ragePerf = getgenv().ragebot.ragePerf
local vhState = getgenv().ragebot.vhState

local localfighter = modules.fighter.LocalFighter
local oldpos

local indicator = Drawing.new("Circle")
indicator.Thickness = 1.5
indicator.NumSides = 36
indicator.Filled = false
indicator.Transparency = 1
indicator.Visible = false
indicator.Radius = 12
indicator.Color = Color3.fromRGB(255, 50, 50)

local indicatoroutline = Drawing.new("Circle")
indicatoroutline.Thickness = 4
indicatoroutline.NumSides = 36
indicatoroutline.Filled = false
indicatoroutline.Transparency = 1
indicatoroutline.Visible = false
indicatoroutline.Radius = 12
indicatoroutline.Color = Color3.fromRGB(0, 0, 0)

local tracerline = Drawing.new("Line")
tracerline.Visible = false
tracerline.Thickness = 2
tracerline.Transparency = 1
tracerline.Color = Color3.fromRGB(0, 186, 255)

local traceroutline = Drawing.new("Line")
traceroutline.Visible = false
traceroutline.Thickness = 4
traceroutline.Transparency = 1
traceroutline.Color = Color3.fromRGB(0, 0, 0)

local lastdamagetime = {}

local function getweapon()
    local viewmodels = workspace:FindFirstChild("ViewModels")
    if not viewmodels then return nil end
    local firstperson = viewmodels:FindFirstChild("FirstPerson")
    if not firstperson then return nil end
    for _, child in ipairs(firstperson:GetChildren()) do
        local parts = {}
        for part in child.Name:gmatch("[^-]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end
        if #parts >= 2 then
            return parts[2]
        end
    end
    return nil
end

local function muzzlepos()
    local viewModels = workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, model in pairs(firstPerson:GetChildren()) do
        if model.Name:find(player.Name) then
            local itemVisual = model:FindFirstChild("ItemVisual")
            if itemVisual then
                local body = itemVisual:FindFirstChild("Body")
                if body then
                    local bodyPrimary = body:FindFirstChild("BodyPrimary")
                    if bodyPrimary then
                        local muzzle = bodyPrimary:FindFirstChild("_muzzle")
                        if muzzle then
                            return muzzle.WorldPosition
                        end
                    end
                end
            end
        end
    end
    return nil
end

local SLOTS = { primary = 1, secondary = 2, melee = 3 }
local MELEE_NMS = {
    ["Battle Axe"] = true, ["Chainsaw"] = true, ["Daggers"] = true, ["Fists"] = true,
    ["Gunblade"] = true, ["Katana"] = true, ["Knife"] = true,
    ["Scythe"] = true, ["Trowel"] = true,
}
local INFINITE_AMMO_WEAPONS = {
    ["Energy Rifle"] = true,
    ["Energy Pistols"] = true,
}

local function isInfiniteWeapon()
    local w = getweapon()
    if not w then return false end
    return INFINITE_AMMO_WEAPONS[w] == true
end

local function wantSlot()
    return SLOTS[config.target.weaponPick or "primary"] or 1
end

local function pickMelee()
    return (config.target.weaponPick or "primary") == "melee"
end

local function getammo()
    if isInfiniteWeapon() then return nil, nil, false end
    local success, controller = pcall(function()
        return instanceSafeRequire(player.PlayerScripts.Controllers.FighterController, 3)
    end)
    if success and controller and controller.LocalFighter and controller.LocalFighter.EquippedItem then
        local item = controller.LocalFighter.EquippedItem
        local itemName, current, maxAmmo = "", 0, 0
        local isMelee = false
        local ok = pcall(function()
            itemName = tostring(item:Get("Name") or item.Name or "")
            current = item:Get("CurrentAmmo") or item:Get("Ammo") or 0
            maxAmmo = item:Get("MaxAmmo") or item:Get("MaxBullets") or current
            if type(itemName) == "string" and itemName:lower():find("melee", 1, true) then
                isMelee = true
            end
            if MELEE_NMS[itemName] then isMelee = true end
        end)
        if not ok then
            return 0, 0, pickMelee()
        end
        if pickMelee() then isMelee = true end
        return tonumber(current) or 0, tonumber(maxAmmo) or 0, isMelee
    end
    return 0, 0, pickMelee()
end

local function meleeNm(nm)
    if type(nm) ~= "string" or nm == "" then return false end
    if nm:lower():find("melee", 1, true) then return true end
    return MELEE_NMS[nm] == true
end

local function itemMelee(item)
    if not item then return false end
    local nm = item:Get("Name") or item.Name
    if meleeNm(nm) then return true end
    local t = item:Get("ItemType") or item:Get("Type") or item:Get("Category")
    return type(t) == "string" and t:lower():find("melee", 1, true) ~= nil
end

local function isSling(weapon)
    return weapon and weapon:lower():find("slingshot", 1, true) ~= nil
end

local function lfItems()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf then return nil end
    return lf.Items
end

local function slotItem(slotIdx)
    local items = lfItems()
    if not items then return nil end
    if items[slotIdx] then return items[slotIdx] end
    if items[tostring(slotIdx)] then return items[tostring(slotIdx)] end
    for key, it in pairs(items) do
        if it and typeof(it) == "table" then
            local s = tonumber(it:Get("Slot") or it:Get("Index") or it:Get("ItemSlot") or key)
            if s == slotIdx then return it end
            local t = it:Get("ItemType") or it:Get("Type")
            if slotIdx == 3 and (t == "Melee" or (type(t) == "string" and t:lower():find("melee", 1, true))) then
                return it
            end
            if slotIdx == 1 and (t == "Primary" or t == 1 or t == "1") then return it end
            if slotIdx == 2 and (t == "Secondary" or t == 2 or t == "2") then return it end
        end
    end
    local ordered = {}
    for _, it in pairs(items) do
        if it then ordered[#ordered + 1] = it end
    end
    table.sort(ordered, function(a, b)
        local sa = tonumber(a:Get("Slot") or a:Get("Index")) or 99
        local sb = tonumber(b:Get("Slot") or b:Get("Index")) or 99
        return sa < sb
    end)
    return ordered[slotIdx]
end

local function whichSlot(item)
    if not item then return nil end
    local items = lfItems()
    local oid = item:Get("ObjectID")
    if items and oid then
        for idx = 1, 3 do
            local it = items[idx] or items[tostring(idx)]
            if it and it:Get("ObjectID") == oid then return idx end
        end
        for key, it in pairs(items) do
            if it and it:Get("ObjectID") == oid then
                local n = tonumber(key)
                if n and n >= 1 and n <= 3 then return n end
            end
        end
    end
    if itemMelee(item) then return 3 end
    return nil
end

local rageLastSlotForce = 0

local function pressSlot(slotIdx)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[slotIdx]
        if not kc then return end
        vim:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, kc, false, game)
    end)
    if keypress then
        pcall(keypress, ({ 0x31, 0x32, 0x33 })[slotIdx])
        task.wait(0.02)
        if keyrelease then pcall(keyrelease, ({ 0x31, 0x32, 0x33 })[slotIdx]) end
    end
end

local function rageOn()
    return config.target.rageMasterOn == true
end

local function eqSlot()
    if not rageOn() then return end
    local want = wantSlot()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf then return end
    local eq = lf.EquippedItem
    if eq and whichSlot(eq) == want then return end
    local now = tick()
    if now - rageLastSlotForce < 0.06 then return end
    rageLastSlotForce = now
    local item = slotItem(want)
    local oid = item and item:Get("ObjectID")
    if oid then
        local rm = replicatedstorage.Remotes.Replication.Fighter.UseItem
        for _, en in ipairs({ "Equip", "Switch", "Select", "EquipItem", "ChangeItem" }) do
            pcall(function()
                local ev = modules.enums:ToEnum(en)
                if ev then rm:FireServer(oid, ev, nil, nil) end
            end)
        end
    end
    pcall(function()
        if lf.EquipItem then lf:EquipItem(want) end
        if lf.Equip then lf:Equip(want) end
        if lf.SwitchToSlot then lf:SwitchToSlot(want) end
    end)
    pcall(function()
        local fc = modules.fighter
        if fc.EquipItem then fc:EquipItem(want) end
        if fc.SwitchItem then fc:SwitchItem(want) end
    end)
    pressSlot(want)
end

local function itemReload()
    if isInfiniteWeapon() then return false end
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf or not lf.EquippedItem then return false end
    local result = false
    pcall(function()
        local item = lf.EquippedItem
        for _, key in ipairs({ "Reloading", "IsReloading", "IsReload" }) do
            local value = item:Get(key)
            if value == true or value == 1 or value == "true" then
                result = true
                return
            end
        end
    end)
    if result then return true end
    local started = config.state.reloadStartedAt or 0
    return started > 0 and (tick() - started) < 1.75
end

local function tickAmmo()
    if isInfiniteWeapon() then
        config.state.outofammo = false
        config.state.reloading = false
        config.state.reloadStartedAt = 0
        return
    end
    local current, maxAmmo, melee = getammo()
    local wasOutOfAmmo = config.state.outofammo
    if melee then
        config.state.outofammo = false
    else
        config.state.outofammo = (tonumber(current) or 0) <= 0
    end
    local reloading = itemReload()
    if reloading and not config.state.reloading then
        config.state.reloadStartedAt = tick()
    elseif not reloading then
        config.state.reloadStartedAt = 0
    end
    config.state.reloading = reloading
    if config.state.outofammo and not wasOutOfAmmo then
        if isSling(getweapon()) then
            config.voidspam.phase = "hide"
        end
    elseif not config.state.outofammo and wasOutOfAmmo then
        if config.voidspam.enabled then
            config.voidspam.phase = "shoot"
            config.voidspam.lastswitch = tick()
        else
            config.voidspam.phase = nil
        end
    end
end

local function reloadHide(sling)
    if not (config.state.reloading and config.ragestatus.hideOnReload) then
        return false
    end
    local hrp = voidHrp()
    if hrp and not sling then
        snapVoid(hrp)
        return true
    end
    local randomX = math.random(-10000, 10000)
    local randomZ = math.random(-10000, 10000)
    config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
    if sling and localfighter and localfighter.Entity and localfighter.Entity.RootPart then
        pcall(function()
            localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
        end)
    end
    return true
end

local function isteammate(targetplayer)
    if not targetplayer then return false end

    local char = targetplayer.Character
    if not char then return false end

    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and humanoidRootPart:FindFirstChild("TeammateLabel") then
        return true
    end

    return false
end

local function valid(char)
    if not char or not char.Parent then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    local targetplayer = players:GetPlayerFromCharacter(char)
    if not targetplayer or isteammate(targetplayer) then return false end
    return true
end

local function nearest()
    local cursorpos = userinput:GetMouseLocation()
    local besttarget = nil
    local bestdistance = math.huge
    for _, targetplayer in players:GetPlayers() do
        if targetplayer ~= player and targetplayer.Character then
            local char = targetplayer.Character
            if valid(char) then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local wts = getgenv().InstanceWorldToScreen or worldToScreen
                    local screenpos, onscreen = wts(root.Position, camera)
                    if onscreen and screenpos then
                        local distance = (Vector2.new(screenpos.X, screenpos.Y) - cursorpos).Magnitude
                        if distance < bestdistance then
                            besttarget = char
                            bestdistance = distance
                        end
                    end
                end
            end
        end
    end
    return besttarget
end

local function hitpartfromname(character, partname)
    if not character then return nil end
    partname = normalizePartName(partname)
    if partname == "Closest" then
        local mypos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not mypos then return character:FindFirstChild("Head") end
        local closest, dist = nil, math.huge
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local d = (part.Position - mypos.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = part
                end
            end
        end
        return closest or character:FindFirstChild("Head")
    elseif partname == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso"}
        return character:FindFirstChild(parts[math.random(#parts)]) or character:FindFirstChild("Head")
    else
        return character:FindFirstChild(partname) or character:FindFirstChild("Head")
    end
end

local function updatevel()
    if not config.target.character or not config.prediction.enabled then
        config.prediction.velocity = Vector3.new(0, 0, 0)
        config.prediction.lastposition = nil
        return
    end
    local root = config.target.character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local now = tick()
    local dt = now - config.prediction.lasttime
    if dt > 0 and dt < 0.1 then
        local currentpos = root.Position
        if config.prediction.lastposition then
            local instantvel = (currentpos - config.prediction.lastposition) / dt
            config.prediction.velocity = config.prediction.velocity:Lerp(instantvel, 0.6)
        end
        config.prediction.lastposition = currentpos
        config.prediction.lasttime = now
    end
end

local function predict(targetpart, origin)
    if not config.prediction.enabled or not targetpart then
        return targetpart and targetpart.Position or Vector3.new()
    end
    local basepos = targetpart.Position
    local distance = (basepos - origin).Magnitude
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    local traveltime = distance / 3000
    local totaltime = (traveltime + ping) * config.prediction.multiplier
    return basepos + (config.prediction.velocity * totaltime)
end

local function canuse()
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if isInfiniteWeapon() then return true end
    local current, _, melee = getammo()
    if current == nil then return true end
    return current > 0 or melee
end

local function clampVs(v)
    return math.clamp(tonumber(v) or 1, 0.1, 2)
end

local function randVs(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if a == b then
        return a
    end
    return a + math.random() * (b - a)
end

local vfrLim, vfrDead = 2147483646, 1147483646
local vfrSnap = { cf = nil, lv = nil, av = nil }

local function clrVoidSnap()
    vfrSnap.cf, vfrSnap.lv, vfrSnap.av = nil, nil, nil
end

local function voidHrp()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function rndSkip(mi, ma, dmi, dma)
    local val = math.random(mi, ma)
    while val >= dmi and val <= dma do
        val = math.random(mi, ma)
    end
    return val
end

local function snapVoid(hrp)
    if not hrp then return end
    if lobbyCache() then return end
    vfrSnap.cf = hrp.CFrame
    vfrSnap.lv = hrp.AssemblyLinearVelocity
    vfrSnap.av = hrp.AssemblyAngularVelocity
    local lim, dead = vfrLim, vfrDead
    pcall(function()
        local p = Vector3.new(rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead))
        local v = Vector3.new(rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead))
        hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
        hrp.AssemblyLinearVelocity = v
        hrp.AssemblyAngularVelocity = v
    end)
end

local vfrCsyncDead = false
local vfrCsyncConn = runsvc:BindToRenderStep("vfr_csync", Enum.RenderPriority.First.Value, function()
    if vfrCsyncDead then return end
    if not vfrSnap.cf then return end
    if not player or not player.Parent then
        vfrCsyncDead = true
        pcall(function() runsvc:UnbindFromRenderStep("vfr_csync") end)
        return
    end
    local okHrp, hrp = pcall(voidHrp)
    if not okHrp or not hrp or not hrp.Parent or not hrp:IsDescendantOf(game) then return end
    pcall(function()
        hrp.CFrame = vfrSnap.cf
        hrp.AssemblyLinearVelocity = vfrSnap.lv
        hrp.AssemblyAngularVelocity = vfrSnap.av
    end)
end)
getgenv().vfrCsyncConn = vfrCsyncConn
getgenv().killVfrCsync = function()
    vfrCsyncDead = true
    pcall(function() runsvc:UnbindFromRenderStep("vfr_csync") end)
end

local function atkCfg()
    if pickMelee() and not config.target.attackCustomEnabled then
        local drop = tonumber(config.target.meleeFeetDrop) or 3.5
        return {
            height = 0,
            front = 0,
            side = 0,
            vertical = -drop,
            radius = 0,
        }
    end
    if config.target.attackCustomEnabled then
        return {
            height = config.target.customHeight or 2,
            front = config.target.customFront or 0,
            side = config.target.customSide or 0,
            vertical = config.target.customVertical or 0,
            radius = config.target.customRadius or 0,
        }
    end
    local mode = config.target.attackPosition or "default"
    local weapon = getweapon()
    if mode == "under" then
        return {
            height = 0,
            front = 0,
            side = 0,
            vertical = -(config.target.underOffset or 4),
            radius = 0,
        }
    end
    return {
        height = (weapon and weapon:lower():find("sniper")) and 8 or 2,
        front = 0,
        side = 0,
        vertical = 0,
        radius = 0,
    }
end

local function setOrbH(weapon)
    local settings = atkCfg()
    config.orbit.height = settings.height
end

local function orbBase(root)
    if not root then
        return Vector3.zero
    end
    local settings = atkCfg()
    local pos = root.Position
    local look = root.CFrame.LookVector
    local right = root.CFrame.RightVector
    return pos
        + (look * settings.front)
        + (right * settings.side)
        + Vector3.new(0, settings.vertical, 0)
end

local function setOrbR()
    local settings = atkCfg()
    config.orbit.radius = settings.radius or 0
end

local function refreshAtk()
    setOrbH(getweapon())
    setOrbR()
end

local function stopsync()
    if not config.state.csyncactive then return end
    if config.orbit.connection then
        config.orbit.connection:Disconnect()
        config.orbit.connection = nil
    end
    config.state.csyncactive = false
    config.orbit.active = false
    clrVoidSnap()
    config.voidspam.phase = nil
    if config.orbit.savedpos and localfighter and localfighter.Entity and localfighter.Entity.RootPart and not getgenv().InstanceUndergroundEnabled then
        local ok, pos = pcall(function() return config.orbit.savedpos end)
        if ok and pos then
            local currentPos = localfighter.Entity.RootPart.CFrame
            local distance = (currentPos.Position - pos.Position).Magnitude
            pcall(function()
                localfighter.Entity.RootPart.CFrame = pos
            end)
        end
    end
    config.orbit.serverpos = nil
    config.orbit.savedpos = nil
    config.voidspam.phase = nil
    oldpos = nil
end

local function isHidingPhase()
    return config.voidspam.enabled and config.voidspam.phase == "hide"
end

local function tickVoidSpam()
    if not config.voidspam.enabled then return end
    local now = tick()
    local elapsed = now - config.voidspam.lastswitch
    if config.voidspam.phase == "shoot" then
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "hide"
            config.voidspam.currentduration = randVs(config.voidspam.hide_min, config.voidspam.hide_max)
            config.voidspam.lastswitch = now
        end
    elseif config.voidspam.phase == "hide" then
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "shoot"
            config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
            config.voidspam.lastswitch = now
        end
    else
        config.voidspam.phase = "shoot"
        config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
        config.voidspam.lastswitch = now
    end
end

local function voidOk(sling)
    if not sling then return false end
    return config.voidspam.enabled or config.state.outofammo
end

local function tickVoid(sling, root)
    if sling then
        clrVoidSnap()
        return false
    end
    if not voidOk(sling) then
        clrVoidSnap()
        return false
    end
    local isHiding = config.state.outofammo or (config.voidspam.enabled and config.voidspam.phase == "hide")
    if isHiding then
        if config.voidspam.enabled and config.voidspam.phase == "hide" and not config.state.outofammo then
            local elapsed = tick() - config.voidspam.lastswitch
            if elapsed >= config.voidspam.currentduration then
                config.voidspam.phase = "shoot"
                config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
                config.voidspam.lastswitch = tick()
                clrVoidSnap()
                return false
            end
        end
        clrVoidSnap()
        local hrp = voidHrp()
        if hrp then
            snapVoid(hrp)
        else
            if config.state.csyncactive then
                return true
            end
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
        end
        return true
    end
    if config.voidspam.enabled and config.voidspam.phase == "shoot" then
        local elapsed = tick() - config.voidspam.lastswitch
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "hide"
            config.voidspam.currentduration = randVs(config.voidspam.hide_min, config.voidspam.hide_max)
            config.voidspam.lastswitch = tick()
        end
    end
    clrVoidSnap()
    return false
end

local function hideShot()
    if not config.voidspam.enabled then return end
    if isSling(getweapon()) then return end
end

local function voidhide()
    if vhState.active then return end
    vhState.active = true
    if not config.state.csyncactive then
        startsync()
    end
end

local stopvoid = function()
    vhState.active = false
    vhState.currentVoidPos = nil
    if vhState.mainConnection then
        vhState.mainConnection:Disconnect()
        vhState.mainConnection = nil
    end
end

local function startsync()
    if config.state.csyncactive then return end
    if config.target.immune then return end
    if not config.target.character or not valid(config.target.character) then return end
    eqSlot()
    config.state.csyncactive = true
    config.orbit.active = true
    local weapon = getweapon()
    setOrbH(weapon)
    setOrbR()
    if not config.orbit.savedpos then
        if localfighter and localfighter.Entity and localfighter.Entity.RootPart then
            config.orbit.savedpos = localfighter.Entity.RootPart.CFrame
        end
    end
    config.orbit.connection = runsvc.Heartbeat:Connect(function(dt)
        if not config.state.csyncactive then return end
        if config.target.immune then stopsync() return end
        if not config.target.character or not valid(config.target.character) then stopsync() return end
        if not localfighter or not localfighter.Entity or not localfighter.Entity.RootPart then stopsync() return end

        if config.target.immune then stopsync() return end

        setOrbR()
        oldpos = localfighter.Entity.RootPart.CFrame

        local function isQuickSwapActive()
            if pickMelee() then return false end
            local lf = modules.fighter and modules.fighter.LocalFighter
            if not lf or not lf.EquippedItem then return false end
            local name = tostring(lf.EquippedItem:Get("Name") or ""):lower()
            return name:find("fist", 1, true) or name:find("utility", 1, true)
        end

        local _weapon = getweapon()
        local checksling = isSling(_weapon)

        if isQuickSwapActive() then return end

        eqSlot()

        if reloadHide(checksling) then return end

        if not checksling and config.voidspam.enabled and not config.target.immune then
            tickVoidSpam()
            if config.voidspam.phase == "hide" then
                local randomX = math.random(-10000, 10000)
                local randomZ = math.random(-10000, 10000)
                config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
                pcall(function()
                    localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
                end)
                return
            end
        end

        if not config.target.character then stopsync() return end
        local root = config.target.character:FindFirstChild("HumanoidRootPart")
        if not root then stopsync() return end

        if not checksling and isHidingPhase() then
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
            pcall(function()
                localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
            end)
            return
        end

        if checksling then
            if vhState and vhState.active then
                local trg = config.target.character:FindFirstChild("HumanoidRootPart")
                if trg then
                    local flat = Vector3.new(trg.CFrame.LookVector.X, 0, trg.CFrame.LookVector.Z).Unit
                    config.orbit.serverpos = trg.Position + Vector3.new(0, 15, 0) + (flat * 5)
                end
            end
        end

        if config.state.outofammo and not checksling and _weapon and not isInfiniteWeapon() then
            local hrp = voidHrp()
            if hrp then
                snapVoid(hrp)
            else
                local randomX = math.random(-10000, 10000)
                local randomZ = math.random(-10000, 10000)
                config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
                pcall(function()
                    localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
                end)
            end
            return
        end

        local targetpos = orbBase(root)
        config.orbit.angle = config.orbit.angle + (config.orbit.speed * dt)
        local offset = Vector3.new(
            math.cos(config.orbit.angle) * config.orbit.radius,
            config.orbit.height,
            math.sin(config.orbit.angle) * config.orbit.radius
        )
        config.orbit.serverpos = targetpos + offset

        if not getgenv().InstanceUndergroundEnabled then
            if localfighter and localfighter.Entity and localfighter.Entity.RootPart then
                local currentPos = localfighter.Entity.RootPart.CFrame
                local newPos = CFrame.new(config.orbit.serverpos)
                local distance = (newPos.Position - currentPos.Position).Magnitude
                if distance < 2000 then
                    localfighter.Entity.RootPart.CFrame = newPos
                    config.orbit.savedpos = currentPos
                end
            end
        end
    end)
end

local function autoshoot()
    if not isSling(getweapon()) and config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    if not config.target.enabled or not config.target.character or not config.target.autoshoot then return end
    if config.target.immune then return end
    if not isSling(getweapon()) and config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    if config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    local weapon = getweapon()
    local checksling = isSling(weapon)
    eqSlot()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf or not lf.EquippedItem then return end
    if not isInfiniteWeapon() then
        if config.state.reloading or config.state.outofammo then return end
        if not canuse() then return end
    end
    local targetChar = config.target.character
    if not valid(targetChar) then return end
    local hitPart = hitpartfromname(targetChar, config.target.hitpart)
    if not hitPart then return end
    local shootPos
    local targetPos
    if vhState and vhState.active and checksling then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        shootPos = root and root.Position or Vector3.new()
        targetPos = predict(hitPart, shootPos)
    else
        if vhState and vhState.active then
            local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            shootPos = myRoot and myRoot.Position or Vector3.new()
        elseif config.state.csyncactive and config.orbit.serverpos then
            shootPos = config.orbit.serverpos
        else
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            shootPos = root and root.Position or Vector3.new()
        end
        targetPos = predict(hitPart, shootPos)
    end
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = modules.utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(1)] = modules.utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(2)] = hitPart,
            [utf8.char(3)] = modules.utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
        },
    }
    local equipped = lf.EquippedItem
    if equipped and equipped:Get("ObjectID") then
        ragePerf.lastAttackTick = tick()

        if getgenv().HitNotifyInstance then
            getgenv().HitNotifyInstance:MarkShot()
        end

        if getgenv().BulletTracersEnabled then
            local origin = getgenv().GetRageTracerOrigin and getgenv().GetRageTracerOrigin()
            if origin then
                local endPos = hitPart and hitPart.Position
                    or (getgenv().GetRageTracerEnd and getgenv().GetRageTracerEnd(origin))
                if endPos then
                    getgenv().FireBulletTracers(
                        origin, endPos,
                        getgenv().BulletTracersLifetime,
                        getgenv().BulletTracersColor
                    )
                end
            end
        end

        local attempts = math.clamp(math.floor(tonumber(config.target.shootAttempts) or 1), 1, 3)
        for _ = 1, attempts do
            pcall(function()
                replicatedstorage.Remotes.Replication.Fighter.UseItem:FireServer(
                    equipped:Get("ObjectID"),
                    modules.enums:ToEnum("StartShooting"),
                    data,
                    nil
                )
            end)
        end
        hideShot()
    end
end

local oldcamupdate = modules.camcontrol.Update
modules.camcontrol.Update = function(...)
    if getgenv().InstanceUndergroundEnabled then
        return oldcamupdate(...)
    elseif config.state.csyncactive and localfighter and localfighter.Entity and localfighter.Entity.RootPart and oldpos then
        localfighter.Entity.RootPart.CFrame = oldpos
    end
    return oldcamupdate(...)
end

local immuneList = {}
local onImmune = {}
local onVulnerable = {}

local function bindimmune(callback)
    table.insert(onImmune, callback)
end

local function bindvulnerable(callback)
    table.insert(onVulnerable, callback)
end

runsvc.Heartbeat:Connect(function()
    for _, plr in pairs(players:GetPlayers()) do
        if plr == player then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local immune = root and root:FindFirstChild("Attachment") ~= nil
        if immune and not immuneList[plr.Name] then
            immuneList[plr.Name] = true
            for _, cb in pairs(onImmune) do cb(plr) end
        elseif not immune and immuneList[plr.Name] then
            immuneList[plr.Name] = nil
            for _, cb in pairs(onVulnerable) do cb(plr) end
        end
    end
end)

bindimmune(function(plr)
    if config.target.lastplayer == plr then
        config.target.immune = true
        config.voidspam.phase = nil
        clrVoidSnap()
        indicator.Color = Color3.fromRGB(180, 0, 255)
        stopsync()
    end
end)

bindvulnerable(function(plr)
    if config.target.lastplayer == plr then
        config.target.immune = false
        indicator.Color = Color3.fromRGB(255, 50, 50)
        if config.target.enabled and config.target.character and valid(config.target.character) then
            startsync()
        end
    end
end)

local function cleartarget()
    config.target.enabled = false
    stopsync()
    config.target.character = nil
    config.target.lastchar = nil
    config.target.lastplayer = nil
    config.target.manualkey = false
    config.target.immune = false
    indicator.Color = Color3.fromRGB(255, 50, 50)
end

local function settarget(char)
    if not char then return end
    local targetplr = players:GetPlayerFromCharacter(char)
    config.target.enabled = true
    config.target.character = char
    config.target.lastchar = char
    config.target.lastplayer = targetplr
    config.target.immune = false
    indicator.Color = Color3.fromRGB(255, 50, 50)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root:FindFirstChild("Attachment") then
        config.target.immune = true
        indicator.Color = Color3.fromRGB(180, 0, 255)
    else
        eqSlot()
        startsync()
    end
end

local sling = {
    enabled = false,
    connections = {}
}

local function checksling()
    return isSling(getweapon())
end

local function nearplr()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local found, best = nil, math.huge
    for _, p in ipairs(players:GetPlayers()) do
        if p == player or not p.Character then continue end
        local head = p.Character:FindFirstChild("HitboxHead") or p.Character:FindFirstChild("Head")
        if not head then continue end
        local d = (head.Position - root.Position).Magnitude
        if d < best then
            found = head
            best = d
        end
    end
    return found
end

local function slingshotTP()
    if sling.connections.touch then return end
    sling.connections.touch = workspace.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Model") then
            if d.Name == "Slingshot" or d.Name == "CoreProjectile" or d.Name == "OuterProjectile" then
                task.spawn(function()
                    task.wait(0.06)
                    local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                    if not part then return end
                    part.CanTouch = true
                    for i = 1, 60 do
                        if not part.Parent or not part:IsDescendantOf(workspace) then break end
                        local target = nearplr()
                        if target and target:IsA("BasePart")
                            and target.Parent
                            and target:IsDescendantOf(workspace)
                        then
                            pcall(firetouchinterest, target, part, 0)
                            pcall(firetouchinterest, target, part, 1)
                        end
                        task.wait()
                    end
                end)
            end
        end
    end)
end

local function stopslingTP()
    if sling.connections.touch then
        sling.connections.touch:Disconnect()
        sling.connections.touch = nil
    end
end

local function targetpos()
    if not config.target.character then return nil end
    local root = config.target.character:FindFirstChild("HumanoidRootPart")
    return root and root.Position
end

local function updatesling()
    local slingon = checksling()
    local hastarget = config.target.enabled and config.target.character ~= nil
    if slingon then
        if not sling.enabled then
            sling.enabled = true
            slingshotTP()
        end
        if getgenv().InstanceSetUnderground then
            getgenv().InstanceSetUnderground(true)
        end
        vhState.active = hastarget
        if hastarget and not config.state.csyncactive then
            startsync()
        elseif not hastarget and config.state.csyncactive and not config.target.enabled then
            stopsync()
        end
    else
        if sling.enabled then
            sling.enabled = false
            stopslingTP()
        end
        vhState.active = false
    end
end

local function fflag()
    local hastarget = config.target.enabled and config.target.character and valid(config.target.character)
    local slingon = checksling()
    if hastarget and slingon then
        pcall(function()
            setfflag("TargetTimeDelayFacctorTenths", "999999")
        end)
    else
        pcall(function()
            setfflag("TGGagK2SMuXHC8Gh3DacXXoRLDQjnAoBpa6", "1")
        end)
    end
end

local targetHudAnimLast = tick()
local _ragbotHudFrame = 0
runsvc.RenderStepped:Connect(function()
    _ragbotHudFrame = _ragbotHudFrame + 1
    if _ragbotHudFrame % 2 ~= 0 then return end
    if not rageOn() then
        tracerline.Visible = false
        traceroutline.Visible = false
        if ragebot.hideRageStatus then
            ragebot.hideRageStatus()
        end
        if ragebot.updateHitNotifications then
            ragebot.updateHitNotifications(0)
        end
        return
    end

    if isLobbyVisible() then
        tracerline.Visible = false
        traceroutline.Visible = false
        if ragebot.hideRageStatus then
            ragebot.hideRageStatus()
        end
        if ragebot.updateHitNotifications then
            ragebot.updateHitNotifications(0)
        end
        return
    end

    if shouldSuppressGameplayOverlays() then
        tracerline.Visible = false
        traceroutline.Visible = false
        if ragebot.hideRageStatus then
            ragebot.hideRageStatus()
        end
        if ragebot.updateHitNotifications then
            ragebot.updateHitNotifications(0)
        end
        return
    end

    local now = tick()
    local hudDt = math.clamp(now - targetHudAnimLast, 0, 0.05)
    targetHudAnimLast = now
    if config.ragestatus and config.ragestatus.enabled and ragebot.drawStatus then
        ragebot.drawStatus()
    elseif ragebot.hideRageStatus then
        ragebot.hideRageStatus()
    end
    if ragebot.updateHitNotifications then
        ragebot.updateHitNotifications(hudDt)
    end
    if config.target.enabled and config.target.character and config.prediction.enabled then
        updatevel()
    end
end)

runsvc.Heartbeat:Connect(function()
    if not rageOn() then return end

    if isLobbyVisible() then return end

    fflag()
    updatesling()
    tickAmmo()
    if config.target.auto and not config.target.manualkey then
        local current, _, melee = getammo()
        local hasammo = current == nil or current > 0 or melee
        if hasammo and not config.state.reloading then
            if not config.target.enabled or not config.target.character or not valid(config.target.character) then
                local newtarget = nearest()
                if newtarget then
                    if config.target.enabled then stopsync() end
                    settarget(newtarget)
                end
            end
        end
    end
    if config.target.enabled and config.target.character then
        if not valid(config.target.character) then
            cleartarget()
            return
        end
        eqSlot()
        if config.target.autoshoot and not config.target.immune then
            autoshoot()
        end
    end
end)

ragebot.config = config
ragebot.nearest = nearest
ragebot.settarget = settarget
ragebot.cleartarget = cleartarget
ragebot.stopvoid = stopvoid
ragebot.vhState = vhState
ragebot.ragePerf = ragePerf
ragebot.getammo = getammo
ragebot.muzzlepos = muzzlepos
ragebot.valid = valid
ragebot.player = player
ragebot.eqSlot = eqSlot
ragebot.refreshAtk = refreshAtk

-- ── Round auto-start ────────────────────────────────────────
do
    local _rageLp = players.LocalPlayer
    local _wasInMatch = false
    local _roundWatchConns = {}

    local function _onRoundTransition()
        if not rageOn() then return end

        local nowIn = liveMatch()
        if nowIn and not _wasInMatch then
            if rageOn() then
                task.defer(function()
                    task.wait(0.25)
                    if not rageOn() then return end
                    if liveMatch() and not isLobbyVisible() then
                        local t = nearest()
                        if t then settarget(t) end
                    end
                end)
            end
        elseif not nowIn and _wasInMatch then
            cleartarget()
        end
        _wasInMatch = nowIn
    end

    local function _watchAttrs(obj)
        if not obj then return end
        local WATCH = {"InDuel","InMatch","InRound","InGame","InFight","IsInMatch",
                       "IsInDuel","MatchActive","Fighting","InSpawn","InLobby",
                       "InIntermission","IsRespawning","MatchId","DuelId","RoundId"}
        for _, key in ipairs(WATCH) do
            local conn = obj:GetAttributeChangedSignal(key):Connect(_onRoundTransition)
            table.insert(_roundWatchConns, conn)
        end
    end

    _watchAttrs(_rageLp)
    _rageLp.CharacterAdded:Connect(function(char)
        _onRoundTransition()
        _watchAttrs(char)
    end)
    if _rageLp.Character then
        _watchAttrs(_rageLp.Character)
    end

    local _lastPollTime = 0
    runsvc.Heartbeat:Connect(function()
        if not rageOn() then return end

        local now = os.clock()
        if now - _lastPollTime < 0.5 then return end
        _lastPollTime = now
        _onRoundTransition()
    end)

    ragebot._roundWatchConns = _roundWatchConns
end

do
local config = ragebot.config
local ragePerf = ragebot.ragePerf
local getammo = ragebot.getammo
local muzzlepos = ragebot.muzzlepos
local valid = ragebot.valid
local player = ragebot.player
local vhState = ragebot.vhState
local camera = workspace.CurrentCamera

local FONT_MAP = {
    gotham        = Enum.Font.Gotham,
    gothammedium  = Enum.Font.GothamMedium,
    gothambold    = Enum.Font.GothamBold,
    arial         = Enum.Font.Arial,
    arialbold     = Enum.Font.ArialBold,
    code          = Enum.Font.Code,
}

local function resolveFont()
    local name = tostring(config.ragestatus.fontName or "gotham"):lower()
    local map = {
        gotham       = 17,
        gothammedium = 18,
        gothambold   = 19,
        arial        = 1,
        arialbold    = 2,
        code         = 11,
    }
    return map[name] or 17
end

local function mkStatusLbl()
    local label = Drawing.new("Text")
    label.Size = config.ragestatus.textSize or 15
    label.Font = resolveFont()
    label.Outline = true
    label.Center = true
    label.Visible = false
    label.Color = config.ragestatus.color
    pcall(function()
        label.OutlineColor = Color3.fromRGB(0, 0, 0)
    end)
    return label
end

local rageStatusLine1 = mkStatusLbl()
local rageStatusLine2 = mkStatusLbl()

local function styleStatusLbl(label)
    label.Size = config.ragestatus.textSize or 15
    label.Font = resolveFont()
    label.Outline = true
    label.Color = config.ragestatus.color
    pcall(function()
        label.OutlineColor = Color3.fromRGB(0, 0, 0)
    end)
end

local function statusAnchor()
    local mode = config.ragestatus.mode or "static"
    local cam = camera or workspace.CurrentCamera
    if not cam then return Vector2.zero end

    if mode == "muzzle" or mode == "follow" then
        local mp
        if mode == "follow" and config.target.character then
            local head = config.target.character:FindFirstChild("Head")
            if head then mp = head.Position end
        end
        if not mp then
            mp = muzzlepos and muzzlepos()
        end
        if mp then
            local wts = getgenv().InstanceWorldToScreen or worldToScreen
            local screenPos, onScreen = wts(mp, cam)
            if onScreen and screenPos then
                return Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    elseif mode == "dynamic" then
        if config.target.character then
            local head = config.target.character:FindFirstChild("Head")
            if head then
                local wts = getgenv().InstanceWorldToScreen or worldToScreen
                local screenPos, onScreen = wts(head.Position, cam)
                if onScreen and screenPos then
                    return Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        end
    end

    return (cam.ViewportSize / 2) + Vector2.new(
        config.ragestatus.staticOffsetX or 0,
        config.ragestatus.staticOffsetY or 0
    )
end

local function rageActive()
    return config.target.enabled or config.target.auto or config.voidspam.enabled
end

local function killNm()
    if config.target.lastplayer then
        return config.target.lastplayer.Name
    end
    if config.target.character then
        local tp = game:GetService("Players"):GetPlayerFromCharacter(config.target.character)
        if tp then
            return tp.Name
        end
    end
    return "target"
end

local function inVoid()
    if vhState.active then return true end
    if config.voidspam.enabled and config.voidspam.phase == "hide" and isSling(getweapon()) then
        return true
    end
    if config.state.reloading and config.ragestatus.hideOnReload ~= false then
        return true
    end
    return false
end

local function isKilling()
    if not rageActive() then
        return false
    end
    if config.state.reloading or inVoid() then
        return false
    end
    if config.target.immune then
        return false
    end
    if not config.target.enabled or not config.target.character or not valid(config.target.character) then
        return false
    end
    if config.state.csyncactive then
        return true
    end
    if config.voidspam.enabled and config.voidspam.phase == "shoot" and isSling(getweapon()) then
        return true
    end
    if tick() - (ragePerf.lastAttackTick or 0) < 0.45 then
        return true
    end
    return false
end

local function hudAmmo()
    if isInfiniteWeapon() then return "∞" end
    local cur, maxAmmo, melee = getammo()
    if cur == nil then return "∞" end
    if melee then return "melee" end
    return string.format("%d/%d", math.floor(cur or 0), math.max(math.floor(maxAmmo or 0), 0))
end

local function fmtVsTime(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if math.abs(a - b) < 0.05 then
        return string.format("%.1fs", a)
    end
    return string.format("%.1f-%.1fs", a, b)
end

local function vsDetail()
    if not config.voidspam.enabled then
        return ""
    end
    local vs = config.voidspam
    return string.format(
        "void %s atk · %s hide",
        fmtVsTime(vs.shoot_min, vs.shoot_max),
        fmtVsTime(vs.hide_min, vs.hide_max)
    )
end

local function rageLines()
    local now = tick()
    if isKilling() then
        if not ragePerf.killStartAt then
            ragePerf.killStartAt = now
        end
    else
        ragePerf.killStartAt = nil
    end
    if config.state.reloading then
        return "ragebot: void hide", "reloading"
    end
    if inVoid() then
        local det = vsDetail()
        return "ragebot: void hide", det ~= "" and det or ""
    end
    if isKilling() then
        local name = killNm()
        local elapsed = now - (ragePerf.killStartAt or now)
        local hum = config.target.character and config.target.character:FindFirstChildOfClass("Humanoid")
        local main = string.format("ragebot : attacking (%s) · %.1fs", name, elapsed)
        local detailParts = {}
        local hpBit = hum and string.format("%.0f hp", hum.Health) or "hp ?"
        detailParts[#detailParts + 1] = hpBit
        local voidDetail = vsDetail()
        if voidDetail ~= "" then
            detailParts[#detailParts + 1] = voidDetail
        end
        return main, table.concat(detailParts, " · ")
    end
    if rageActive() and config.target.enabled and config.target.character then
        local hum = config.target.character:FindFirstChildOfClass("Humanoid")
        local hpBit = hum and string.format("%.0f hp", hum.Health) or "locked"
        return "ragebot: ready", hpBit
    end
    return "ragebot: idle", ""
end

local function drawStatus()
    if not config.ragestatus.enabled or shouldSuppressGameplayOverlays() then
        rageStatusLine1.Visible = false
        rageStatusLine2.Visible = false
        return
    end

    styleStatusLbl(rageStatusLine1)
    styleStatusLbl(rageStatusLine2)

    local anchor = statusAnchor()
    local gap = config.ragestatus.lineGap or 14
    local showAmmo = config.ragestatus.showAmmo ~= false
    if ragePerf.lastRageColor ~= config.ragestatus.color then
        ragePerf.lastRageColor = config.ragestatus.color
        styleStatusLbl(rageStatusLine1)
        styleStatusLbl(rageStatusLine2)
    end
    local mainLine, detailLine = rageLines()
    local ammoLine = showAmmo and hudAmmo() or ""
    local line2Text = detailLine
    if line2Text ~= "" and ammoLine ~= "" then
        line2Text = line2Text .. " · " .. ammoLine
    elseif line2Text == "" then
        line2Text = ammoLine
    end
    local lineCount = 1 + (line2Text ~= "" and 1 or 0)
    local topOffset = -(lineCount - 1) * (gap / 2)
    if mainLine ~= ragePerf.lastRageStatusText then
        ragePerf.lastRageStatusText = mainLine
        rageStatusLine1.Text = mainLine
    end
    rageStatusLine1.Position = anchor + Vector2.new(0, topOffset)
    rageStatusLine1.Visible = config.ragestatus.enabled
    local nextY = topOffset + gap
    if line2Text ~= "" then
        if line2Text ~= ragePerf.lastRageDetailText then
            ragePerf.lastRageDetailText = line2Text
            rageStatusLine2.Text = line2Text
        end
        rageStatusLine2.Position = anchor + Vector2.new(0, nextY)
        rageStatusLine2.Visible = config.ragestatus.enabled
    else
        ragePerf.lastRageDetailText = ""
        rageStatusLine2.Visible = false
    end
end

ragebot.drawStatus = drawStatus
ragebot.hideRageStatus = function()
    rageStatusLine1.Visible = false
    rageStatusLine2.Visible = false
end
ragebot.clrVoidSnap = clrVoidSnap

end
end

-- ============================================================
-- Gun Mod
-- ============================================================
getgenv().GunSystem = {
    CooldownEnabled = false,
    Cooldown = 0.0,
    SpreadEnabled = false,
    Spread = 0.0,
    RecoilEnabled = false,
    Recoil = 0.0,
    Backup = {}
}

task.spawn(function()
    local success, ItemLibrary = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ItemLibrary"))
    end)

    if not success or not ItemLibrary then return end

    local function scanAndBackup(tbl)
        for k, v in pairs(tbl) do
            if typeof(v) == "table" then
                if v.ShootCooldown ~= nil or v.ShootSpread ~= nil or v.ShootRecoil ~= nil then
                    if not getgenv().GunSystem.Backup[v] then
                        getgenv().GunSystem.Backup[v] = {
                            ShootCooldown = v.ShootCooldown,
                            ShootSpread = v.ShootSpread,
                            ShootRecoil = v.ShootRecoil
                        }
                    end
                end
                scanAndBackup(v)
            end
        end
    end

    scanAndBackup(ItemLibrary)
end)

function UpdateGunStats()
    local sys = getgenv().GunSystem

    for configTable, originalValues in pairs(sys.Backup) do
        if sys.CooldownEnabled then
            if originalValues.ShootCooldown ~= nil then configTable.ShootCooldown = sys.Cooldown end
        else
            if originalValues.ShootCooldown ~= nil then configTable.ShootCooldown = originalValues.ShootCooldown end
        end

        if sys.SpreadEnabled then
            if originalValues.ShootSpread ~= nil then configTable.ShootSpread = sys.Spread end
        else
            if originalValues.ShootSpread ~= nil then configTable.ShootSpread = originalValues.ShootSpread end
        end

        if sys.RecoilEnabled then
            if originalValues.ShootRecoil ~= nil then configTable.ShootRecoil = sys.Recoil end
        else
            if originalValues.ShootRecoil ~= nil then configTable.ShootRecoil = originalValues.ShootRecoil end
        end
    end
end

getgenv().UpdateGunStats = UpdateGunStats

-- ═══════════════════════════════════════════════════════════════
-- [移植包 2] Item Cooldown Modifier — 仿 Kicia InfoModifier
-- 來源：kicia source.txt → tbl17.gn (InfoModifier)
-- 原理：直接修改每個 ClientItem.Info 的冷卻欄位，並備份原始值以便還原
-- ═══════════════════════════════════════════════════════════════
getgenv().ItemCooldownSystem = {
    -- 各項 modifier 的開關與百分比（0 = 無冷卻，1 = 原始，2 = 兩倍慢）
    MeleeCooldown = { Enabled = false, Percentage = 0.0 },
    DashCooldown  = { Enabled = false, Percentage = 0.0 },
    AimSpeed      = { Enabled = false, Percentage = 1.0 },
    FireCooldown  = { Enabled = false, Percentage = 0.0 },
    ShootRecoil   = { Enabled = false, Percentage = 0.0 },
    AutomaticWeapon = { Enabled = false },
    MaxDoubleJumps  = { Enabled = false, Count = 676767 },
    _backupByItem = {},     -- [item] = { FieldName = originalValue }
    _appliedByItem = {},    -- [item] = true
    _hooked = false,
}

local ICS = getgenv().ItemCooldownSystem

-- 各欄位的 handler（對照 Kicia 的 handlers）
local ICS_HANDLERS = {
    MaxDoubleJumps = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.MaxDoubleJumps
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.MaxDoubleJumps = base
        else
            liveInfo.MaxDoubleJumps = cfg.Count or 676767
        end
    end,
    MeleeCooldown = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.AttackCooldown
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.AttackCooldown = base
        else
            liveInfo.AttackCooldown = base * (cfg.Percentage or 0.0)
        end
    end,
    DashCooldown = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.DashCooldown
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.DashCooldown = base
        else
            liveInfo.DashCooldown = base * (cfg.Percentage or 0.0)
        end
    end,
    AimSpeed = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.AimSpeed
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.AimSpeed = base
        else
            liveInfo.AimSpeed = base * (cfg.Percentage or 1.0)
        end
    end,
    FireCooldown = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.ShootCooldown
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.ShootCooldown = base
        else
            liveInfo.ShootCooldown = base * (cfg.Percentage or 0.0)
        end
    end,
    ShootRecoil = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.ShootRecoil
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.ShootRecoil = base
        else
            liveInfo.ShootRecoil = base * (cfg.Percentage or 0.0)
        end
    end,
    AutomaticWeapon = function(originalInfo, liveInfo, cfg)
        local base = originalInfo.InputSpammingEnabled
        if base == nil then return end
        if cfg == nil or cfg.Enabled ~= true then
            liveInfo.InputSpammingEnabled = base
        else
            local cloned = table.clone(base)
            cloned.StartShooting = 0
            cloned.StartReloading = 0
            liveInfo.InputSpammingEnabled = cloned
        end
    end,
}

-- 備份 item.Info 的原始值
local ICS_BACKUP_FIELDS = {
    "MaxDoubleJumps", "AttackCooldown", "DashCooldown", "AimSpeed",
    "ShootCooldown", "ShootRecoil", "InputSpammingEnabled",
}

function ICS.SnapshotAll()
    local fc = getgenv().ragebot and getgenv().ragebot.player
        and require(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.FighterController)
    local lf = fc and fc.LocalFighter
    if not lf then return end
    local items = lf.Items
    if type(items) ~= "table" then return end
    for _, item in pairs(items) do
        if item and not ICS._backupByItem[item] then
            ics_backup(item)   -- 只在没有 backup 时建立，避免覆盖正确原始值
        end
    end
    if lf.EquippedItem and not ICS._backupByItem[lf.EquippedItem] then
        ics_backup(lf.EquippedItem)
    end
end

local function ics_getInfo(item)
    if not item then return nil end
    local ok, info = pcall(function() return item:Get("Info") end)
    if not ok or type(info) ~= "table" then
        -- 有些版本 item.Info 是直接屬性
        ok, info = pcall(function() return item.Info end)
    end
    if type(info) ~= "table" then return nil end
    return info
end

local function ics_backup(item)
    if ICS._backupByItem[item] then return ICS._backupByItem[item] end
    local info = ics_getInfo(item)
    if not info then return nil end
    local backup = {}
    for _, field in ipairs(ICS_BACKUP_FIELDS) do
        local v = info[field]
        if v ~= nil then
            if type(v) == "table" then
                backup[field] = table.clone(v)
            else
                backup[field] = v
            end
        end
    end
    ICS._backupByItem[item] = backup
    return backup
end

local function ics_apply(item)
    local backup = ICS._backupByItem[item] or ics_backup(item)
    if not backup then return end
    local info = ics_getInfo(item)
    if not info then return end

    for handlerName, handler in pairs(ICS_HANDLERS) do
        local cfg = ICS[handlerName]
        local ok, err = pcall(handler, backup, info, cfg)
        if not ok then
            warn("[ItemCooldown] handler " .. handlerName .. " error: " .. tostring(err))
        end
    end
    ICS._appliedByItem[item] = true
end

local function ics_restore(item)
    local backup = ICS._backupByItem[item]
    if not backup then return end
    local info = ics_getInfo(item)
    if not info then return end
    for _, field in ipairs(ICS_BACKUP_FIELDS) do
        if backup[field] ~= nil then
            if type(backup[field]) == "table" then
                info[field] = table.clone(backup[field])
            else
                info[field] = backup[field]
            end
        end
    end
    ICS._appliedByItem[item] = nil
end

local function ics_applyAll()
    local fc = getgenv().ragebot and getgenv().ragebot.player
        and require(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.FighterController)
    local lf = fc and fc.LocalFighter
    if not lf then return end
    local items = lf.Items
    if type(items) ~= "table" then return end
    for _, item in pairs(items) do
        if item then ics_apply(item) end
    end
    -- 也套用到當前裝備的 item
    if lf.EquippedItem then ics_apply(lf.EquippedItem) end
end

local function ics_restoreAll()
    for item in pairs(ICS._backupByItem) do
        ics_restore(item)
    end
end

function ICS.Refresh()
    -- 套用到所有 item
    ics_applyAll()
    -- 同時更新全域模板（你原本的 GunSystem）
    if getgenv().UpdateGunStats then getgenv().UpdateGunStats() end
end

function ICS.RestoreAll()
    ics_restoreAll()
    if getgenv().UpdateGunStats then getgenv().UpdateGunStats() end
end

local function ics_restoreField(item, field)
    local backup = ICS._backupByItem[item]
    if not backup or backup[field] == nil then return end
    local info = ics_getInfo(item)
    if not info then return end
    if type(backup[field]) == "table" then
        info[field] = table.clone(backup[field])
    else
        info[field] = backup[field]
    end
end

function ICS.RestoreField(fieldName)
    local fc = getgenv().ragebot and getgenv().ragebot.player
        and require(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.FighterController)
    local lf = fc and fc.LocalFighter
    if not lf then return end
    local items = lf.Items
    if type(items) == "table" then
        for _, item in pairs(items) do
            if item then ics_restoreField(item, fieldName) end
        end
    end
    if lf.EquippedItem then ics_restoreField(lf.EquippedItem, fieldName) end
end

-- Hook FighterController 的 ItemAdded / ItemRemoved / EquippedItemChanged
task.spawn(function()
    local FC
    local deadline = os.clock() + 10
    while os.clock() < deadline do
        local ok, mod = pcall(function()
            return require(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.FighterController)
        end)
        if ok and mod then FC = mod break end
        task.wait(0.2)
    end
    if not FC then
        warn("[ItemCooldown] FighterController not found")
        return
    end

    if ICS._hooked then return end
    ICS._hooked = true

    local function onItemAdded(item)
        if not item then return end
        ics_backup(item)
        ics_apply(item)
    end

    -- 嘗試 hook ItemAdded signal（不同版本可能叫別的名字）
    local signals = {"ItemAdded", "ItemAddedSignal", "OnItemAdded", "ItemChanged"}
    for _, sigName in ipairs(signals) do
        local sig = FC[sigName]
        if sig and type(sig.Connect) == "function" then
            pcall(function()
                sig:Connect(onItemAdded)
            end)
        end
    end

    -- 也 hook LocalFighter 上的 signal
    local lf = FC.LocalFighter
    if lf then
        for _, sigName in ipairs(signals) do
            local sig = lf[sigName]
            if sig and type(sig.Connect) == "function" then
                pcall(function()
                    sig:Connect(onItemAdded)
                end)
            end
        end
    end

    -- 首次套用
    task.delay(0.5, function()
        ics_applyAll()
    end)

    -- 每次 Heartbeat 檢查裝備的 item 是否需要套用
    game:GetService("RunService").Heartbeat:Connect(function()
        local lf2 = FC.LocalFighter
        if not lf2 then return end
        local eq = lf2.EquippedItem
        if eq and not ICS._appliedByItem[eq] then
            ics_backup(eq)
            ics_apply(eq)
        end
    end)
end)

-- ============================================================
-- ESP
-- ============================================================
getgenv().ESP = {
    Enabled = false,
    Box = false,
    BoxFilled = false,
    Highlight = false,
    Health = false,
    Name = false,
    Tool = false,
    Tracer = false,
    Skeleton = false,
    TeamCheck = false,
    TeamColor = false,
    Gradient = false,
    ColorA = Color3.fromRGB(255, 0, 0),
    ColorB = Color3.fromRGB(0, 0, 255),
    GradientSpeed = 5,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 0.0,
    BoxFillTransparency = 0.85,
    Xray = false,
    XrayTransparency = 0.5,
}

Camera = getCamera()

getgenv().MapXrayCache = getgenv().MapXrayCache or setmetatable({}, {__mode = "k"})
getgenv().ESPObjects   = getgenv().ESPObjects or {}

getgenv().BonesR15 = getgenv().BonesR15 or {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
getgenv().BonesR6 = getgenv().BonesR6 or {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local MapXrayCache = getgenv().MapXrayCache
local ESPObjects   = getgenv().ESPObjects
local BonesR15     = getgenv().BonesR15
local BonesR6      = getgenv().BonesR6

function isSameTeam(player)
    local cfg = getgenv().ESP
    if not cfg.TeamCheck then return false end
    if not player or player == LocalPlayer then return false end
    local character = player.Character
    if not character then return false end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    if humanoidRootPart:FindFirstChild("TeammateLabel") then return true end
    return false
end

function getPlayerColor(player, distance)
    local cfg = getgenv().ESP
    if cfg.TeamColor and player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end

    if cfg.Gradient then
        local distFactor = (distance or 0) * 0.05
        local alpha = (math.sin((tick() * cfg.GradientSpeed) + distFactor) + 1) / 2
        return cfg.ColorA:Lerp(cfg.ColorB, math.clamp(alpha, 0, 1))
    end

    return cfg.Color
end

function getDrawingTransparency(customTrans)
    local cfg = getgenv().ESP
    local t = customTrans or cfg.Transparency
    return math.clamp(1 - t, 0, 1)
end

function newSquare()
    local sq = Drawing.new("Square")
    sq.Thickness = 1
    sq.Filled = false
    sq.Color = Color3.fromRGB(255,255,255)
    sq.Transparency = getDrawingTransparency()
    sq.Visible = false
    return sq
end

function newLine()
    local ln = Drawing.new("Line")
    ln.Thickness = 2
    ln.Transparency = getDrawingTransparency()
    ln.Visible = false
    return ln
end

function newText()
    local txt = Drawing.new("Text")
    txt.Size = 12
    txt.Color = Color3.fromRGB(255,255,255)
    txt.Center = true
    txt.Outline = true
    txt.Transparency = getDrawingTransparency()
    txt.Visible = false
    return txt
end

function createSkeleton(esp, isR6)
    local bones = isR6 and BonesR6 or BonesR15
    for i = 1,#bones do
        esp.Skeleton[i] = newLine()
    end
end

function createESP(player)
    if ESPObjects[player] then return end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local isR6 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R6
    local esp = {
        Box = newSquare(),
        BoxFill = newSquare(),
        HealthOutline = newLine(),
        HealthBar = newLine(),
        NameTag = newText(),
        ToolText = newText(),
        Tracer = newLine(),
        Skeleton = {},
        Highlight = nil,
        IsR6 = isR6,
    }
    createSkeleton(esp, isR6)
    ESPObjects[player] = esp
end

function clearESP(player)
    local esp = ESPObjects[player]
    if not esp then return end

    local singles = {"Box","BoxFill","HealthOutline","HealthBar","NameTag","ToolText","Tracer","Highlight"}
    for _, name in pairs(singles) do
        local obj = esp[name]
        if obj then
            if typeof(obj) == "Instance" then
                obj:Destroy()
            elseif obj.Visible ~= nil then
                obj.Visible = false
            end
            esp[name] = nil
        end
    end

    if esp.Skeleton then
        for _, line in pairs(esp.Skeleton) do
            if line and line.Visible ~= nil then
                line.Visible = false
            end
        end
        esp.Skeleton = nil
    end

    ESPObjects[player] = nil
end

function updateHighlight(player, char, currentColor)
    local cfg = getgenv().ESP
    local esp = ESPObjects[player]
    if not esp then return end

    if not cfg.Highlight or isSameTeam(player) then
        if esp.Highlight then
            esp.Highlight:Destroy()
            esp.Highlight = nil
        end
        return
    end

    if not esp.Highlight or not esp.Highlight.Parent then
        if esp.Highlight then esp.Highlight:Destroy() end

        local h = Instance.new("Highlight")
        h.Name = "ESPHighlight"
        h.FillTransparency = cfg.Transparency
        h.OutlineTransparency = cfg.Transparency
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        if char and char.Parent then h.Parent = char end
        esp.Highlight = h
    end

    if esp.Highlight then
        esp.Highlight.FillColor = currentColor
        esp.Highlight.OutlineColor = currentColor
        esp.Highlight.FillTransparency = cfg.Transparency
        esp.Highlight.OutlineTransparency = cfg.Transparency
    end
end

function onCharacterAdded(player, char)
    local humanoid = char:WaitForChild("Humanoid",5)
    if humanoid then
        humanoid.Died:Connect(function() clearESP(player) end)
    end
    createESP(player)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) onCharacterAdded(p, c) end)
end)

for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(c) onCharacterAdded(p, c) end)
end

Players.PlayerRemoving:Connect(function(player) clearESP(player) end)

local _espFrameCount = 0
RunService.RenderStepped:Connect(function()
    _espFrameCount = _espFrameCount + 1
    if _espFrameCount % 2 ~= 0 then return end
    local cfg = getgenv().ESP
    local currentBaseTransparency = getDrawingTransparency()
    local currentFillTransparency = getDrawingTransparency(cfg.BoxFillTransparency)

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do

        if isSameTeam(player) then
            local esp = ESPObjects[player]
            if esp then
                esp.Box.Visible = false
                esp.BoxFill.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthOutline.Visible = false
                esp.NameTag.Visible = false
                esp.ToolText.Visible = false
                esp.Tracer.Visible = false
                for _, l in pairs(esp.Skeleton) do l.Visible = false end
                if esp.Highlight then esp.Highlight:Destroy() esp.Highlight = nil end
            end
            continue
        end

        if player == LocalPlayer then
            if ESPObjects[player] then clearESP(player) end
            continue
        end

        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not (cfg.Enabled and player ~= LocalPlayer and char and humanoid and root and head and humanoid.Health > 0) then
            local esp = ESPObjects[player]
            if esp then
                esp.Box.Visible = false
                esp.BoxFill.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthOutline.Visible = false
                esp.NameTag.Visible = false
                esp.ToolText.Visible = false
                esp.Tracer.Visible = false
                for _, l in pairs(esp.Skeleton) do if l then l.Visible = false end end
                if esp.Highlight then esp.Highlight:Destroy() esp.Highlight = nil end
            end
            continue
        end

        createESP(player)

        local distance = localRoot and (localRoot.Position - root.Position).Magnitude or 0
        local teamColor = getPlayerColor(player, distance)

        updateHighlight(player, char, teamColor)

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
        local esp = ESPObjects[player]

        if not onScreen then
            esp.Box.Visible = false
            esp.BoxFill.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthOutline.Visible = false
            esp.NameTag.Visible = false
            esp.ToolText.Visible = false
            esp.Tracer.Visible = false
            for _,l in pairs(esp.Skeleton) do l.Visible = false end
            continue
        end

        local allParts
        if esp.IsR6 then
            allParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
        else
            allParts = {
                "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
                "LeftUpperArm", "LeftLowerArm", "LeftHand",
                "RightUpperArm", "RightLowerArm", "RightHand",
                "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                "RightUpperLeg", "RightLowerLeg", "RightFoot"
            }
        end

        local minX = math.huge
        local maxX = -math.huge
        local minY = math.huge
        local maxY = -math.huge

        local validCount = 0

        for _, partName in ipairs(allParts) do
            local part = char:FindFirstChild(partName)

            if part and part:IsA("BasePart") then
                local screenPos, visible = Camera:WorldToViewportPoint(part.Position)

                if screenPos.Z > 0.05 then
                    minX = math.min(minX, screenPos.X)
                    maxX = math.max(maxX, screenPos.X)

                    minY = math.min(minY, screenPos.Y)
                    maxY = math.max(maxY, screenPos.Y)

                    validCount = validCount + 1
                end
            end
        end

        local boxPosX, boxPosY, boxWidth, boxHeight

        if validCount >= 2 then

            local headScreen = Camera:WorldToViewportPoint(
                head.Position + Vector3.new(0, 0.5, 0)
            )

            local rootScreen = Camera:WorldToViewportPoint(
                root.Position
            )

            local bottomPart = char:FindFirstChild(
                esp.IsR6 and "Left Leg" or "LeftFoot"
            )

            local bottomScreen

            if bottomPart then
                bottomScreen = Camera:WorldToViewportPoint(
                    bottomPart.Position - Vector3.new(0, 0.8, 0)
                )
            end

            if headScreen.Z > 0.05 then
                minY = math.min(minY, headScreen.Y)
            end

            if bottomScreen and bottomScreen.Z > 0.05 then
                maxY = math.max(maxY, bottomScreen.Y)
            end

            local rawWidth = maxX - minX
            local rawHeight = maxY - minY

            local padding = math.clamp(
                rawHeight * 0.025,
                1,
                3
            )

            boxWidth = rawWidth + padding * 2
            boxHeight = rawHeight + padding * 2

            boxPosX = minX - padding
            boxPosY = minY - padding

            local maxReasonableWidth = rawHeight * 0.75

            if maxReasonableWidth > 0 then
                boxWidth = math.min(
                    boxWidth,
                    maxReasonableWidth
                )
            end

            local minReasonableWidth = rawHeight * 0.20

            if minReasonableWidth > 0 then
                boxWidth = math.max(
                    boxWidth,
                    minReasonableWidth
                )
            end

            local centerX = (minX + maxX) / 2

            boxPosX = centerX - boxWidth / 2

        else

            local headScreen = Camera:WorldToViewportPoint(head.Position)
            local rootScreen = Camera:WorldToViewportPoint(root.Position)

            if headScreen.Z > 0.05 and rootScreen.Z > 0.05 then

                local rawHeight = math.abs(
                    headScreen.Y - rootScreen.Y
                )

                local height = rawHeight * 2.0
                local width = height * 0.42

                boxWidth = width
                boxHeight = height

                boxPosX = rootScreen.X - width / 2
                boxPosY = rootScreen.Y - height / 2

            else

                esp.Box.Visible = false
                esp.BoxFill.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthOutline.Visible = false
                esp.NameTag.Visible = false
                esp.ToolText.Visible = false
                esp.Tracer.Visible = false

                for _, l in pairs(esp.Skeleton) do
                    if l then
                        l.Visible = false
                    end
                end

                continue
            end
        end

        esp.Box.Size = Vector2.new(boxWidth, boxHeight)
        esp.Box.Position = Vector2.new(boxPosX, boxPosY)
        esp.Box.Color = teamColor
        esp.Box.Transparency = currentBaseTransparency
        esp.Box.Visible = cfg.Box

        esp.BoxFill.Size = esp.Box.Size
        esp.BoxFill.Position = esp.Box.Position
        esp.BoxFill.Color = teamColor
        esp.BoxFill.Filled = true
        esp.BoxFill.Transparency = currentFillTransparency
        esp.BoxFill.Visible = cfg.BoxFilled and cfg.Box

        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
        esp.Tracer.Color = teamColor
        esp.Tracer.Transparency = currentBaseTransparency
        esp.Tracer.Visible = cfg.Tracer and cfg.Enabled

        local bones = esp.IsR6 and BonesR6 or BonesR15
        if cfg.Skeleton then
            for i,b in ipairs(bones) do
                local p1 = char:FindFirstChild(b[1])
                local p2 = char:FindFirstChild(b[2])
                if p1 and p2 then
                    local v1,o1 = Camera:WorldToViewportPoint(p1.Position)
                    local v2,o2 = Camera:WorldToViewportPoint(p2.Position)
                    if o1 and o2 then
                        esp.Skeleton[i].From = Vector2.new(v1.X,v1.Y)
                        esp.Skeleton[i].To   = Vector2.new(v2.X,v2.Y)
                        esp.Skeleton[i].Visible = true
                        esp.Skeleton[i].Color = teamColor
                        esp.Skeleton[i].Transparency = currentBaseTransparency
                    else
                        esp.Skeleton[i].Visible = false
                    end
                else
                    esp.Skeleton[i].Visible = false
                end
            end
        else
            for _,l in pairs(esp.Skeleton) do l.Visible = false end
        end

        if cfg.Health then
            local hpPercent = humanoid.Health / humanoid.MaxHealth
            esp.HealthOutline.From = Vector2.new(esp.Box.Position.X - 6, esp.Box.Position.Y)
            esp.HealthOutline.To   = Vector2.new(esp.Box.Position.X - 6, esp.Box.Position.Y + boxHeight)
            esp.HealthBar.From     = Vector2.new(esp.Box.Position.X - 6, esp.Box.Position.Y + boxHeight)
            esp.HealthBar.To       = Vector2.new(esp.Box.Position.X - 6, esp.Box.Position.Y + boxHeight - boxHeight*hpPercent)
            esp.HealthBar.Color    = Color3.fromRGB(255 - hpPercent*255, hpPercent*255, 0)

            esp.HealthOutline.Color = teamColor
            esp.HealthOutline.Transparency = currentBaseTransparency
            esp.HealthBar.Transparency = currentBaseTransparency
            esp.HealthOutline.Visible = true
            esp.HealthBar.Visible = true
        else
            esp.HealthOutline.Visible = false
            esp.HealthBar.Visible = false
        end

        if cfg.Name then
            esp.NameTag.Text = string.format("%s [%.1f]", player.Name, distance)
            esp.NameTag.Position = Vector2.new(rootPos.X, minY - 20)
            esp.NameTag.Color = teamColor
            esp.NameTag.Transparency = currentBaseTransparency
            esp.NameTag.Visible = true
        else
            esp.NameTag.Visible = false
        end

        if cfg.Tool then
            local toolName = "None"
            local characterTool = char:FindFirstChildOfClass("Tool")
            if characterTool then
                toolName = characterTool.Name
            else
                local viewModels = workspace:FindFirstChild("ViewModels")
                if viewModels then
                    for _, model in ipairs(viewModels:GetChildren()) do
                        if string.find(model.Name, player.Name, 1, true) then
                            local parts = string.split(model.Name, " - ")
                            if #parts >= 3 then
                                toolName = parts[#parts]
                            else
                                toolName = model.Name
                            end
                            break
                        end
                    end
                end
            end

            esp.ToolText.Text = toolName
            esp.ToolText.Position = Vector2.new(rootPos.X, minY - 35)
            esp.ToolText.Color = teamColor
            esp.ToolText.Transparency = currentBaseTransparency
            esp.ToolText.Visible = true
        else
            esp.ToolText.Visible = false
        end
    end
end)

function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid") ~= nil
end

function shouldIgnore(part)
    if isCharacterPart(part) then return true end
    if part:FindFirstAncestorWhichIsA("Tool") then return true end
    return false
end

function applyToPart(part)
    local cfg = getgenv().ESP
    if not part:IsA("BasePart") then return end
    if shouldIgnore(part) then return end

    if MapXrayCache[part] == nil then
        MapXrayCache[part] = part.LocalTransparencyModifier
    end
    part.LocalTransparencyModifier = cfg.XrayTransparency
end

function restorePart(part)
    local original = MapXrayCache[part]
    if original == nil then return end

    if part and part.Parent then
        part.LocalTransparencyModifier = original
    end
    MapXrayCache[part] = nil
end

function applyMapXray()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then applyToPart(obj) end
    end
end

function restoreMapXray()
    for part, _ in pairs(MapXrayCache) do restorePart(part) end
end

Workspace.DescendantAdded:Connect(function(obj)
    if getgenv().ESP.Xray and obj:IsA("BasePart") then applyToPart(obj) end
end)

function SetMapXray(state)
    if getgenv().ESP.Xray == state then return end
    getgenv().ESP.Xray = state
    if state then applyMapXray() else restoreMapXray() end
end

Players.PlayerRemoving:Connect(clearESP)

-- ============================================================
-- Item ESP
-- ============================================================
Camera = getCamera()

getgenv().ItemESP = getgenv().ItemESP or {
    Highlight = false,
    Name = false,
}

getgenv().TrackNames = getgenv().TrackNames or {
    ["Slingshot"] = {Enabled = false},
    ["Daggers"] = {Enabled = false},
    ["Paintball Gun"] = {Enabled = false},
    ["Grenade Launcher"] = {Enabled = false},
    ["Flare Gun"] = {Enabled = false},
    ["Molotov"] = {Enabled = false},
    ["Freeze Ray"] = {Enabled = false},
    ["Flashbang"] = {Enabled = false},
    ["Warpstone"] = {Enabled = false},
    ["Satchel"] = {Enabled = false},
    ["Subspace Tripmine"] = {Enabled = false},
    ["Smoke Grenade"] = {Enabled = false},
    ["Grenade"] = {Enabled = false},
    ["Bow"] = {Enabled = false},
    ["RPG"] = {Enabled = false}
}

getgenv().TrackColors = getgenv().TrackColors or {
    ["Slingshot"] = Color3.fromRGB(255, 0, 0),
    ["Daggers"] = Color3.fromRGB(20, 20, 20),
    ["Paintball Gun"] = Color3.fromRGB(0, 255, 0),
    ["Grenade Launcher"] = Color3.fromRGB(255, 120, 0),
    ["Flare Gun"] = Color3.fromRGB(255, 80, 80),
    ["Molotov"] = Color3.fromRGB(255, 100, 0),
    ["Freeze Ray"] = Color3.fromRGB(0, 255, 255),
    ["Flashbang"] = Color3.fromRGB(255, 255, 200),
    ["Warpstone"] = Color3.fromRGB(180, 0, 255),
    ["Satchel"] = Color3.fromRGB(200, 150, 100),
    ["Subspace Tripmine"] = Color3.fromRGB(255, 0, 255),
    ["Smoke Grenade"] = Color3.fromRGB(150, 150, 150),
    ["Grenade"] = Color3.fromRGB(0, 255, 0),
    ["Bow"] = Color3.fromRGB(255, 100, 100),
    ["RPG"] = Color3.fromRGB(255, 255, 0),
}

getgenv().TrackedObjects = getgenv().TrackedObjects or {}
getgenv().ObjectESP = getgenv().ObjectESP or setmetatable({}, {__mode = "k"})

local TrackNames     = getgenv().TrackNames
local TrackColors    = getgenv().TrackColors
local TrackedObjects = getgenv().TrackedObjects
local ObjectESP      = getgenv().ObjectESP

function createObjectESP(obj)
    if ObjectESP[obj] then
        return ObjectESP[obj]
    end

    local esp = {
        Highlight = nil,
        Name = Drawing.new("Text")
    }

    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Visible = false

    ObjectESP[obj] = esp

    obj.AncestryChanged:Connect(function(_, parent)
        if parent then
            return
        end

        local data = ObjectESP[obj]
        if not data then
            return
        end

        if data.Highlight then
            data.Highlight:Destroy()
        end

        if data.Name then
            data.Name:Remove()
        end

        ObjectESP[obj] = nil
        TrackedObjects[obj] = nil
    end)

    return esp
end

function getObjectPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position
        end
    end
end

function updateESP(obj, objectType)
    if not obj or not obj.Parent then
        return
    end

    local esp = createObjectESP(obj)
    local color = TrackColors[objectType] or Color3.fromRGB(255, 255, 255)

    local config = TrackNames[objectType]
    if not config or not config.Enabled then
        esp.Name.Visible = false
        if esp.Highlight then
            esp.Highlight:Destroy()
            esp.Highlight = nil
        end
        return
    end

    local pos = getObjectPosition(obj)
    if not pos then
        if esp.Highlight then
            esp.Highlight:Destroy()
            esp.Highlight = nil
        end
        esp.Name.Visible = false
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    local cfg = getgenv().ItemESP

    if cfg.Highlight then
        if not esp.Highlight then
            local h = Instance.new("Highlight")
            h.Name = "ItemESP"
            h.FillTransparency = 0.5
            h.OutlineTransparency = 1
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = obj
            esp.Highlight = h
        end

        esp.Highlight.FillColor = color
    elseif esp.Highlight then
        esp.Highlight:Destroy()
        esp.Highlight = nil
    end

    if cfg.Name and onScreen then
        esp.Name.Text = objectType
        esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y)
        esp.Name.Color = color
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
end

function tryTrack(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then
        return
    end

    local config = TrackNames[obj.Name]
    if config and config.Enabled then
        TrackedObjects[obj] = obj.Name
        createObjectESP(obj)
    end
end

function untrack(obj)
    local esp = ObjectESP[obj]

    if esp then
        if esp.Highlight then
            esp.Highlight:Destroy()
        end

        if esp.Name then
            esp.Name:Remove()
        end

        ObjectESP[obj] = nil
    end

    TrackedObjects[obj] = nil
end

for _, obj in ipairs(workspace:GetDescendants()) do
    tryTrack(obj)
end

workspace.DescendantAdded:Connect(tryTrack)
workspace.DescendantRemoving:Connect(untrack)

local _itemEspFrame = 0
RunService.RenderStepped:Connect(function()
    _itemEspFrame = _itemEspFrame + 1
    if _itemEspFrame % 2 ~= 0 then return end
    local cfg = getgenv().ItemESP
    if not cfg.Highlight and not cfg.Name then
        for obj, esp in pairs(ObjectESP) do
            if esp.Highlight then
                esp.Highlight:Destroy()
                esp.Highlight = nil
            end

            if esp.Name then
                esp.Name.Visible = false
            end
        end
        return
    end

    for obj, objectType in pairs(TrackedObjects) do
        if obj and obj.Parent then
            updateESP(obj, objectType)
        end
    end
end)

-- ============================================================
-- Unlocker
-- ============================================================
local _plrs = Players
local _rs   = ReplicatedStorage
local _http = HttpService
local _run  = RunService
local _ws   = Workspace
local _lp   = LocalPlayer

local _pscripts = _lp.PlayerScripts
local _ctrl    = _pscripts.Controllers
local _mods    = _rs:WaitForChild("Modules", 10)

getgenv().UnlockerSettings = getgenv().UnlockerSettings or {
    Skin = false,
    Wrap = false,
    Charm = false,
    Dance = false,
    Emote = false
}

local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

local _cosLib  = require(_mods:WaitForChild("CosmeticLibrary", 10))
local _itmLib  = require(_mods:WaitForChild("ItemLibrary", 10))
local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

getgenv().UnlockerEq    = getgenv().UnlockerEq    or {}
getgenv().UnlockerFavs  = getgenv().UnlockerFavs  or {}
getgenv().UnlockerBuildWep = getgenv().UnlockerBuildWep or nil

local _eq        = getgenv().UnlockerEq
local _favs      = getgenv().UnlockerFavs
local _buildingWep = getgenv().UnlockerBuildWep
local _viewProf  = nil
local _lastWep   = nil
local _fakeInv   = {}

local function _mkCosmetic(nm, ctype, opts)
    local _base = _cosLib.Cosmetics[nm]
    if not _base then return nil end
    local _d = {}
    for k, v in pairs(_base) do _d[k] = v end
    _d.Name = nm
    _d.Type = _d.Type or ctype
    _d.Seed = _d.Seed or math.random(1, 1000000)
    if _enumLib then
        local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
        if _s and _eid then
            _d.Enum = _eid
            _d.ObjectID = _d.ObjectID or _eid
        end
    end
    if opts then
        if opts.inverted ~= nil then _d.Inverted = opts.inverted end
        if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
    end
    return _d
end

local _cfgFile = "Onyx/unlocker_config.json"
local _saveLock = false

local function _stripForSave()
    local _out = {}
    for wn, cos in pairs(_eq) do
        _out[wn] = {}
        for ct, cd in pairs(cos) do
            if cd and cd.Name then
                _out[wn][ct] = {
                    Name = cd.Name,
                    Inverted = cd.Inverted,
                    OnlyUseFavorites = cd.OnlyUseFavorites
                }
            end
        end
    end
    return { equipped = _out, favorites = _favs }
end

local function _loadCfg()
    if not isfile or not readfile then return end
    local _ok1, _ex = pcall(isfile, _cfgFile)
    if not _ok1 or not _ex then return end
    local _ok2, _raw = pcall(readfile, _cfgFile)
    if not _ok2 or not _raw or _raw == "" then return end
    local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
    if not _ok3 or not _dec then return end
    if _dec.favorites then
        _favs = _dec.favorites
        getgenv().UnlockerFavs = _favs
    end
    if _dec.equipped then
        _eq = {}
        getgenv().UnlockerEq = _eq
        local _cnt = 0
        for wn, cos in pairs(_dec.equipped) do
            _eq[wn] = {}
            for ct, sd in pairs(cos) do
                if sd and sd.Name then
                    if _cosLib.Cosmetics[sd.Name] then
                        local _cloned = _mkCosmetic(sd.Name, ct, {
                            inverted = sd.Inverted,
                            favoritesOnly = sd.OnlyUseFavorites
                        })
                        if _cloned then
                            _eq[wn][ct] = _cloned
                            _cnt += 1
                        end
                    end
                end
            end
            if not next(_eq[wn]) then _eq[wn] = nil end
        end
    end
end

local function _saveCfg()
    if not writefile or _saveLock then return end
    _saveLock = true
    task.spawn(function()
        task.wait(1)
        local _payload = _stripForSave()
        local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
        if _ok then
            pcall(writefile, _cfgFile, _enc)
        end
        _saveLock = false
    end)
end

_loadCfg()

local function _isCosTypeAllowed(cosObj)
    if not cosObj or not cosObj.Type then return false end
    return getgenv().UnlockerSettings[cosObj.Type] == true
end

_cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" and getgenv().UnlockerSettings.Skin then return true end
    return false
end
_cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" and getgenv().UnlockerSettings.Skin then return true end
    return false
end
_cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" and getgenv().UnlockerSettings.Skin then return true end
    return false
end

local _origOwns = _cosLib.OwnsCosmetic
_cosLib.OwnsCosmetic = function(self, inv, nm, wep)
    if nm:find("MISSING_") or nm == "Bubble Gun" then
        return _origOwns(self, inv, nm, wep)
    end
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosTypeAllowed(c) then return true end
    return _origOwns(self, inv, nm, wep)
end

local _origGet = _datCtrl.Get
_datCtrl.Get = function(self, key)
    local _val = _origGet(self, key)
    if key == "CosmeticInventory" then
        local _prx = {}
        if _val then
            for k, v in pairs(_val) do
                local c = _cosLib.Cosmetics[k]
                if c and _isCosTypeAllowed(c) then _prx[k] = v end
            end
        end
        return setmetatable(_prx, {
            __index = function(t, k)
                local c = _cosLib.Cosmetics[k]
                if c and _isCosTypeAllowed(c) then return true end
                return nil
            end
        })
    end
    if key == "FavoritedCosmetics" then
        local _res = _val and table.clone(_val) or {}
        for wep, fv in pairs(_favs) do
            _res[wep] = _res[wep] or {}
            for nm, isFav in pairs(fv) do
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosTypeAllowed(c) then
                    _res[wep][nm] = isFav
                end
            end
        end
        return _res
    end
    return _val
end

local _origGetWep = _datCtrl.GetWeaponData
_datCtrl.GetWeaponData = function(self, wn)
    local _d = _origGetWep(self, wn)
    if not _d then return nil end
    local _m = {}
    for k, v in pairs(_d) do _m[k] = v end
    _m.Name = wn
    if _eq[wn] then
        for ct, cd in pairs(_eq[wn]) do
            _m[ct] = cd
        end
    end
    return _m
end

local _fightCtrl
pcall(function()
    _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
end)

if hookmetamethod then
    local _remotes   = _rs:FindFirstChild("Remotes")
    local _dataRem   = _remotes and _remotes:FindFirstChild("Data")
    local _equipRem  = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
    local _favRem    = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
    local _repRem    = _remotes and _remotes:FindFirstChild("Replication")
    local _fightRem  = _repRem and _repRem:FindFirstChild("Fighter")
    local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

    if _equipRem then
        local _onc
        _onc = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() ~= "FireServer" then
                return _onc(self, ...)
            end
            local _a = {...}

            if _useItmRem and self == _useItmRem then
                local _oid = _a[1]
                if _fightCtrl then
                    pcall(function()
                        local _f = _fightCtrl:GetFighter(_lp)
                        if _f and _f.Items then
                            for _, itm in pairs(_f.Items) do
                                if itm:Get("ObjectID") == _oid then
                                    _lastWep = itm.Name
                                    break
                                end
                            end
                        end
                    end)
                end
            end

            if self == _equipRem then
                local _wn   = _a[1]
                local _ct   = _a[2]
                local _cn   = _a[3]
                local _opts = _a[4] or {}
                if _cn and _cn ~= "None" and _cn ~= "" then
                    local _inv = _datCtrl:Get("CosmeticInventory")
                    if _inv and rawget(_inv, _cn) then
                        return _onc(self, ...)
                    end
                end
                _eq[_wn] = _eq[_wn] or {}
                if not _cn or _cn == "None" or _cn == "" then
                    _eq[_wn][_ct] = nil
                    if not next(_eq[_wn]) then _eq[_wn] = nil end
                else
                    local _cloned = _mkCosmetic(_cn, _ct, {
                        inverted = _opts.IsInverted,
                        favoritesOnly = _opts.OnlyUseFavorites
                    })
                    if _cloned then _eq[_wn][_ct] = _cloned end
                end
                task.defer(function()
                    pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                end)
                _saveCfg()
                return
            end

            if self == _favRem then
                local _cos = _cosLib.Cosmetics[_a[2]]
                if _cos then
                    _favs[_a[1]] = _favs[_a[1]] or {}
                    _favs[_a[1]][_a[2]] = _a[3] or nil
                    task.spawn(function()
                        pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                    end)
                    _saveCfg()
                end
                return
            end

            return _onc(self, ...)
        end)
    end
end

local _cliItem
pcall(function()
    _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
end)

if _cliItem and _cliItem._CreateViewModel then
    local _origCVM = _cliItem._CreateViewModel
    _cliItem._CreateViewModel = function(self, vmRef)
        local _wn  = self.Name
        local _wp  = self.ClientFighter and self.ClientFighter.Player
        _buildingWep = (_wp == _lp) and _wn or nil
        getgenv().UnlockerBuildWep = _buildingWep
        if _wp == _lp and _eq[_wn] then
            local _dk = self:ToEnum("Data")
            if vmRef[_dk] then
                if _eq[_wn].Skin then
                    vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin
                    vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name
                end
                if _eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = _eq[_wn].Charm end
                if _eq[_wn].Wrap  then vmRef[_dk][self:ToEnum("Wrap")]  = _eq[_wn].Wrap  end
            elseif vmRef.Data then
                if _eq[_wn].Skin then vmRef.Data.Skin  = _eq[_wn].Skin; vmRef.Data.Name = _eq[_wn].Skin.Name end
                if _eq[_wn].Charm then vmRef.Data.Charm = _eq[_wn].Charm end
                if _eq[_wn].Wrap  then vmRef.Data.Wrap  = _eq[_wn].Wrap  end
            end
        end
        local _r = _origCVM(self, vmRef)
        _buildingWep = nil
        getgenv().UnlockerBuildWep = nil
        return _r
    end
end

local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if _vmMod then
    local _CVM = require(_vmMod)
    local _origNew = _CVM.new
    _CVM.new = function(repData, cliItm)
        local _wp  = cliItm.ClientFighter and cliItm.ClientFighter.Player
        local _wn  = getgenv().UnlockerBuildWep or cliItm.Name
        if _wp == _lp and _eq[_wn] then
            local _RC  = require(_rs.Modules.ReplicatedClass)
            local _dk  = _RC:ToEnum("Data")
            repData[_dk] = repData[_dk] or {}
            local _cos = _eq[_wn]
            if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
            if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
            if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
        end
        return _origNew(repData, cliItm)
    end
end

-- ============================================================
-- Shaders
-- ============================================================
getgenv().Player = LocalPlayer
Player = getgenv().Player
Camera = getCamera()

getgenv().Effects = getgenv().Effects or {
    DOF = false,
    Bloom = false,
    ColorCorrection = false,
    Atmosphere = false,
    SunRays = false,
    DynamicExposure = false,
    SpecularBoost = false,
}
local Effects = getgenv().Effects

function remove(name)
    local obj = Lighting:FindFirstChild(name)
    if obj then obj:Destroy() end
end

remove("ProDOF")
remove("ProBloom")
remove("ProColor")
remove("ProAtmos")
remove("ProSun")

DOF = Instance.new("DepthOfFieldEffect")
DOF.Name = "ProDOF"
DOF.Enabled = Effects.DOF
DOF.InFocusRadius = 3
DOF.NearIntensity = 1
DOF.FarIntensity = 1
DOF.FocusDistance = 15
DOF.Parent = Lighting

Bloom = Instance.new("BloomEffect")
Bloom.Name = "ProBloom"
Bloom.Enabled = Effects.Bloom
Bloom.Intensity = 0.35
Bloom.Size = 32
Bloom.Threshold = 1
Bloom.Parent = Lighting

Color = Instance.new("ColorCorrectionEffect")
Color.Name = "ProColor"
Color.Enabled = Effects.ColorCorrection
Color.Brightness = 0
Color.Contrast = 0.2
Color.Saturation = 0.1
Color.Parent = Lighting

Atmos = Instance.new("Atmosphere")
Atmos.Name = "ProAtmos"
Atmos.Density = 0.35
Atmos.Offset = 0.1
Atmos.Color = Color3.fromRGB(200,220,255)
Atmos.Decay = Color3.fromRGB(120,120,140)
Atmos.Glare = 0.3
Atmos.Haze = 1
Atmos.Parent = Lighting

Atmos.Parent = Effects.Atmosphere and Lighting or nil

Sun = Instance.new("SunRaysEffect")
Sun.Name = "ProSun"
Sun.Enabled = Effects.SunRays
Sun.Intensity = 0.2
Sun.Spread = 0.6
Sun.Parent = Lighting

function applySpecular(state)
    if state then
        Lighting.EnvironmentSpecularScale = 1
        Lighting.EnvironmentDiffuseScale = 0.4
        Lighting.GlobalShadows = true
    else
        Lighting.EnvironmentSpecularScale = 0
        Lighting.EnvironmentDiffuseScale = 1
    end
end

applySpecular(Effects.SpecularBoost)

targetExposure = 0
currentExposure = 0
exposureSpeed = 2

focus = 15
targetFocus = 15

function getBrightness()
    local sunDir = Lighting:GetSunDirection()
    return Camera.CFrame.LookVector:Dot(sunDir)
end

function isFirstPerson()
    local char = Player.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    if not head then return false end
    return (Camera.CFrame.Position - head.Position).Magnitude < 1
end

local _lightingFrame = 0
RunService.RenderStepped:Connect(function(dt)
    _lightingFrame = _lightingFrame + 1
    if _lightingFrame % 3 ~= 0 then return end
    DOF.Enabled = Effects.DOF
    Bloom.Enabled = Effects.Bloom
    Color.Enabled = Effects.ColorCorrection
    Sun.Enabled = Effects.SunRays

    if Effects.Atmosphere then
        if not Atmos.Parent then
            Atmos.Parent = Lighting
        end
    else
        Atmos.Parent = nil
    end

    applySpecular(Effects.SpecularBoost)

    if Effects.DynamicExposure and Effects.ColorCorrection then
        local brightness = getBrightness()
        targetExposure = math.clamp(brightness * 0.5, -0.1, 0.2)
        currentExposure = currentExposure + (targetExposure - currentExposure) * dt * exposureSpeed
        Color.Brightness = currentExposure
    end

    if Effects.DOF and Player.Character then
        local head = Player.Character:FindFirstChild("Head")
        if head then
            local dist = (head.Position - Camera.CFrame.Position).Magnitude
            if isFirstPerson() then
                DOF.InFocusRadius = 8
                DOF.NearIntensity = 0.2
                DOF.FarIntensity = 0.4
                targetFocus = 50
            else
                DOF.InFocusRadius = 3
                DOF.NearIntensity = 1
                DOF.FarIntensity = 1
                targetFocus = dist
            end
        end

        focus = focus + (targetFocus - focus) * math.clamp(dt * 8, 0, 1)
        DOF.FocusDistance = focus
    end

    if Effects.Bloom then
        local look = Camera.CFrame.LookVector.Y
        Bloom.Intensity = 0.3 + math.abs(look) * 0.2
    end
end)

getgenv().ProLighting = Effects

getgenv().Skybox = getgenv().Skybox or {
    Enabled = false,
    Type = "Afternoon",
}

getgenv().OriginalLighting = getgenv().OriginalLighting or {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}
local OriginalLighting = getgenv().OriginalLighting

getgenv().Skyboxes = getgenv().Skyboxes or {
    ["Afternoon"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://162001926",
        SkyboxDn = "rbxassetid://161998893",
        SkyboxFt = "rbxassetid://162001897",
        SkyboxBk = "rbxassetid://162001887",
        SkyboxLf = "rbxassetid://162001904",
        SkyboxRt = "rbxassetid://162001919",
    },
    ["Blue Space"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://367149078",
        SkyboxDn = "rbxassetid://367147970",
        SkyboxFt = "rbxassetid://366731193",
        SkyboxBk = "rbxassetid://366731024",
        SkyboxLf = "rbxassetid://366731613",
        SkyboxRt = "rbxassetid://366731514",
    },
    ["Classic Roblox"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://11138465883",
        SkyboxDn = "rbxassetid://11138453351",
        SkyboxFt = "rbxassetid://11138458027",
        SkyboxBk = "rbxassetid://11138450201",
        SkyboxLf = "rbxassetid://11138460736",
        SkyboxRt = "rbxassetid://11138463127",
        SunTextureId = "rbxassetid://11138537872",
    },
    ["Cloudy"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://246480504",
        SkyboxDn = "rbxassetid://246480523",
        SkyboxFt = "rbxassetid://246480105",
        SkyboxBk = "rbxassetid://246480323",
        SkyboxLf = "rbxassetid://246480549",
        SkyboxRt = "rbxassetid://246480565",
    },
    ["Dusk"] = {
        StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://9778106496",
        SkyboxDn = "rbxassetid://9778110864",
        SkyboxFt = "rbxassetid://9778101192",
        SkyboxBk = "rbxassetid://9778108979",
        SkyboxLf = "rbxassetid://9778103329",
        SkyboxRt = "rbxassetid://9778104889",
    },
    ["Dawn"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://323478865",
        SkyboxDn = "rbxassetid://323481190",
        SkyboxFt = "rbxassetid://323480314",
        SkyboxBk = "rbxassetid://323479840",
        SkyboxLf = "rbxassetid://323480786",
        SkyboxRt = "rbxassetid://323480131",
    },
    ["Dark Skies"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://149397702",
        SkyboxDn = "rbxassetid://149397686",
        SkyboxFt = "rbxassetid://149397697",
        SkyboxBk = "rbxassetid://149397692",
        SkyboxLf = "rbxassetid://149397684",
        SkyboxRt = "rbxassetid://149397688",
    },
    ["Earth"] = {
        StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0,
        SkyboxUp = "rbxassetid://15753304473",
        SkyboxDn = "rbxassetid://15753362674",
        SkyboxFt = "rbxassetid://15753305823",
        SkyboxBk = "rbxassetid://15753305495",
        SkyboxLf = "rbxassetid://15753310707",
        SkyboxRt = "rbxassetid://15753304774",
    },
    ["Ethereal"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://16823395515",
        SkyboxDn = "rbxassetid://16823388586",
        SkyboxFt = "rbxassetid://16823390254",
        SkyboxBk = "rbxassetid://16823386986",
        SkyboxLf = "rbxassetid://16823392344",
        SkyboxRt = "rbxassetid://16823394120",
    },
    ["Galaxy"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://2049518578",
        SkyboxDn = "rbxassetid://2049519279",
        SkyboxFt = "rbxassetid://2049519882",
        SkyboxBk = "rbxassetid://2049520382",
        SkyboxLf = "rbxassetid://2049522478",
        SkyboxRt = "rbxassetid://2049521207",
    },
    ["Heaven"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://7951703855",
        SkyboxDn = "rbxassetid://7951706908",
        SkyboxFt = "rbxassetid://7951694757",
        SkyboxBk = "rbxassetid://7951826533",
        SkyboxLf = "rbxassetid://7951697216",
        SkyboxRt = "rbxassetid://7951700251",
    },
    ["Horizontal Milky Way"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://714276621",
        SkyboxDn = "rbxassetid://714276541",
        SkyboxFt = "rbxassetid://714276657",
        SkyboxBk = "rbxassetid://714276643",
        SkyboxLf = "rbxassetid://714276648",
        SkyboxRt = "rbxassetid://714276638",
    },
    ["Jungle"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://525546479",
        SkyboxDn = "rbxassetid://525544628",
        SkyboxFt = "rbxassetid://525548536",
        SkyboxBk = "rbxassetid://525546178",
        SkyboxLf = "rbxassetid://525550171",
        SkyboxRt = "rbxassetid://525545319",
    },
    ["Mountains"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://48015387",
        SkyboxDn = "rbxassetid://48015300",
        SkyboxFt = "rbxassetid://368388290",
        SkyboxBk = "rbxassetid://368385273",
        SkyboxLf = "rbxassetid://368390615",
        SkyboxRt = "rbxassetid://368385190",
    },
    ["Nebula"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://171448889",
        SkyboxDn = "rbxassetid://171448902",
        SkyboxFt = "rbxassetid://171448848",
        SkyboxBk = "rbxassetid://171448875",
        SkyboxLf = "rbxassetid://171448933",
        SkyboxRt = "rbxassetid://171448925",
    },
    ["Night"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://12064131",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121",
        SkyboxBk = "rbxassetid://12064107",
        SkyboxLf = "rbxassetid://12063984",
        SkyboxRt = "rbxassetid://12064115",
    },
    ["Night Light"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://171447068",
        SkyboxDn = "rbxassetid://171447094",
        SkyboxFt = "rbxassetid://171447041",
        SkyboxBk = "rbxassetid://171447054",
        SkyboxLf = "rbxassetid://171447128",
        SkyboxRt = "rbxassetid://171447111",
    },
    ["Ocean Sky"] = {
        StarCount = 3000, SunAngularSize = 1, MoonAngularSize = 0,
        SkyboxUp = "rbxassetid://11854708161",
        SkyboxDn = "rbxassetid://11854687121",
        SkyboxFt = "rbxassetid://11854693863",
        SkyboxBk = "rbxassetid://11854686548",
        SkyboxLf = "rbxassetid://11854696162",
        SkyboxRt = "rbxassetid://11854698541",
        SunTextureId = "rbxassetid://4774583925",
        MoonTextureId = "rbxassetid://4774580371",
    },
    ["Pink Clouds"] = {
        StarCount = 1334, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://271077958",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042556",
        SkyboxBk = "rbxassetid://271042516",
        SkyboxLf = "rbxassetid://271042310",
        SkyboxRt = "rbxassetid://271042467",
    },
    ["Red Dusk"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://136208328681929",
        SkyboxDn = "rbxassetid://123407860042117",
        SkyboxFt = "rbxassetid://132624761762466",
        SkyboxBk = "rbxassetid://85146619291315",
        SkyboxLf = "rbxassetid://102069641249982",
        SkyboxRt = "rbxassetid://136526747107728",
    },
    ["Redshift"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://401664936",
        SkyboxDn = "rbxassetid://401664862",
        SkyboxFt = "rbxassetid://401664960",
        SkyboxBk = "rbxassetid://401664839",
        SkyboxLf = "rbxassetid://401664881",
        SkyboxRt = "rbxassetid://401664901",
    },
    ["Saturn"] = {
        StarCount = 3000, SunAngularSize = 10, MoonAngularSize = 0,
        SkyboxUp = "rbxassetid://1898736761",
        SkyboxDn = "rbxassetid://1898727189",
        SkyboxFt = "rbxassetid://1898722814",
        SkyboxBk = "rbxassetid://1898724755",
        SkyboxLf = "rbxassetid://1898729298",
        SkyboxRt = "rbxassetid://1898741025",
        MoonTextureId = "rbxassetid://0",
    },
    ["SFOTH"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://1014449",
        SkyboxDn = "rbxassetid://1012891",
        SkyboxFt = "rbxassetid://1012887",
        SkyboxBk = "rbxassetid://1012890",
        SkyboxLf = "rbxassetid://1012889",
        SkyboxRt = "rbxassetid://1012888",
    },
    ["Smoke"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://171410742",
        SkyboxDn = "rbxassetid://171410748",
        SkyboxFt = "rbxassetid://171410730",
        SkyboxBk = "rbxassetid://171410736",
        SkyboxLf = "rbxassetid://171410766",
        SkyboxRt = "rbxassetid://171410755",
    },
    ["Solid Black"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://2013298",
        SkyboxDn = "rbxassetid://2013298",
        SkyboxFt = "rbxassetid://2013298",
        SkyboxBk = "rbxassetid://2013298",
        SkyboxLf = "rbxassetid://2013298",
        SkyboxRt = "rbxassetid://2013298",
    },
    ["Space"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://155441905",
        SkyboxDn = "rbxassetid://155441905",
        SkyboxFt = "rbxassetid://155441905",
        SkyboxBk = "rbxassetid://155441905",
        SkyboxLf = "rbxassetid://155441905",
        SkyboxRt = "rbxassetid://155441905",
    },
    ["Storm"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://171410789",
        SkyboxDn = "rbxassetid://171410792",
        SkyboxFt = "rbxassetid://171410775",
        SkyboxBk = "rbxassetid://171410784",
        SkyboxLf = "rbxassetid://171410807",
        SkyboxRt = "rbxassetid://171410798",
    },
    ["Sunset"] = {
        StarCount = 5000, SunAngularSize = 18, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://264907379",
        SkyboxDn = "rbxassetid://264907909",
        SkyboxFt = "rbxassetid://264909420",
        SkyboxBk = "rbxassetid://264908339",
        SkyboxLf = "rbxassetid://264909758",
        SkyboxRt = "rbxassetid://264908886",
    },
    ["Underworld"] = {
        StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://171561009",
        SkyboxDn = "rbxassetid://171561019",
        SkyboxFt = "rbxassetid://171560968",
        SkyboxBk = "rbxassetid://171560994",
        SkyboxLf = "rbxassetid://171561065",
        SkyboxRt = "rbxassetid://171561026",
    },
    ["Vertical Milky Way"] = {
        StarCount = 3000, SunAngularSize = 1.440000057220459, MoonAngularSize = 0.5699999928474426,
        SkyboxUp = "rbxassetid://5559302033",
        SkyboxDn = "rbxassetid://5559290893",
        SkyboxFt = "rbxassetid://5559300879",
        SkyboxBk = "rbxassetid://5559289158",
        SkyboxLf = "rbxassetid://5559292825",
        SkyboxRt = "rbxassetid://5559302989",
    },
    ["White"] = {
        StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11,
        SkyboxUp = "rbxassetid://321136141",
        SkyboxDn = "rbxassetid://321136141",
        SkyboxFt = "rbxassetid://321136141",
        SkyboxBk = "rbxassetid://321136141",
        SkyboxLf = "rbxassetid://321136141",
        SkyboxRt = "rbxassetid://321136141",
    },
}
local Skyboxes = getgenv().Skyboxes

local function getOrCreateSky()
    local sky = Lighting:FindFirstChild("CustomSky")
    if sky and sky:IsA("Sky") then
        return sky
    end

    sky = Instance.new("Sky")
    sky.Name = "CustomSky"
    sky.Parent = Lighting
    return sky
end

local function removeOtherSkies()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj.Name ~= "CustomSky" then
            obj:Destroy()
        end
    end
end

local function removeSky()
    local sky = Lighting:FindFirstChild("CustomSky")
    if sky then sky:Destroy() end
end

local function applySky()
    local cfg = getgenv().Skybox
    if not cfg.Enabled then
        removeSky()
        return
    end

    local data = Skyboxes[cfg.Type]
    if not data then return end

    removeOtherSkies()

    local sky = getOrCreateSky()

    for prop, asset in pairs(data) do
        sky[prop] = asset
    end

    if Lighting:FindFirstChild("CustomSky") ~= sky then
        sky.Parent = Lighting
    end
end

-- ============================================================
-- Weather & Lightning (visual only, Kicia-inspired)
-- ============================================================
getgenv().Weather = getgenv().Weather or {
    Enabled = false,
    Type = "sunny",
    Intensity = 150,
    Speed = 1,
    Size = 1,
    Spread = 1,
    Glow = 0,
    Color = Color3.fromRGB(255, 255, 255),
}

getgenv().WeatherLightning = getgenv().WeatherLightning or {
    Enabled = false,
    Color = ColorSequence.new(Color3.fromRGB(214, 230, 255)),
    Interval = 2,
    Distance = 80,
    Height = 220,
    Thickness = 4,
    Branches = 12,
    Flash = 8,
    Sparks = {
        Enabled = true,
        Color = ColorSequence.new(Color3.fromRGB(238, 246, 255)),
        Count = 18,
        Thickness = 2.2,
        Distance = 22,
        Speed = 22,
        Jaggedness = 4,
    },
    Explosion = {
        Enabled = true,
        Size = 0.45,
        Bolts = 14,
        Color = ColorSequence.new(Color3.fromRGB(150, 200, 255)),
    },
    Sound = {
        Enabled = false,
        Volume = 1,
        Delay = true,
        SoundId = "",
    },
}

local Weather         = getgenv().Weather
local WeatherLightning = getgenv().WeatherLightning

-- ====== 常數（對照 Kicia tbl17.hH） ======
local LCFG = {
    RadiusMin           = 20,
    GroundDrop          = 40,
    RayLength           = 1000,
    Jitter              = 30,
    ThunderSpeed        = 340,
    ThunderVolumeFloor  = 0.20,
    ThunderFalloff      = 600,
    ThunderPitchMin     = 0.85,
    ThunderPitchMax     = 1.10,
    FadeDuration        = 0.35,
    CleanupBuffer       = 0.05,
    FlickerMin          = 2,
    FlickerMax          = 3,
    FlickerOnMin        = 0.02,
    FlickerOnMax        = 0.045,
    FlickerOffMin       = 0.02,
    FlickerOffMax       = 0.05,
    FlickerDim          = 0.15,
}

-- ====== Weather folder 與 emitter anchor ======
local WeatherFolder       -- Folder
local WeatherAnchor       -- Part (在 folder 內)
local WeatherEmitters = {}  -- { Emitter=, Spec= }
local weatherKindActive   -- string: "rain" / "heavyRain" / "snow" / nil

local function ensureWeatherFolder()
    if WeatherFolder and WeatherFolder.Parent then
        return WeatherFolder, WeatherAnchor
    end

    local f = Instance.new("Folder")
    f.Name = "OnyxWeather"

    local anchor = Instance.new("Part")
    anchor.Name = "EmitterAnchor"
    anchor.Size = Vector3.new(220, 1, 220)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Parent = f

    f.Parent = workspace

    WeatherFolder = f
    WeatherAnchor = anchor
    return f, anchor
end

local RAIN_REMOTE_URL = "https://Onyx.eu.cc/assets/rain.png"
local RAIN_LOCAL_DIR  = "Onyx/assets"
local RAIN_LOCAL_PATH = RAIN_LOCAL_DIR .. "/rain.png"

local function ensureRainTexture()
    -- 1. 建目录
    if isfolder and makefolder then
        if not isfolder("Onyx") then makefolder("Onyx") end
        if not isfolder(RAIN_LOCAL_DIR) then makefolder(RAIN_LOCAL_DIR) end
    end

    -- 2. 下载（只下一次）
    if isfile and writefile then
        if not isfile(RAIN_LOCAL_PATH) then
            local ok, data = pcall(function()
                return game:HttpGet(RAIN_REMOTE_URL, true)
            end)
            if ok and type(data) == "string" and #data > 128 then
                pcall(writefile, RAIN_LOCAL_PATH, data)
            else
                warn("[Weather] rain.png download failed")
                return nil
            end
        end
    end

    -- 3. 转成 asset id
    local assetFn = getsynasset or getcustomasset
    if not assetFn then
        warn("[Weather] executor has no getcustomasset/getsynasset")
        return nil
    end
    local ok, asset = pcall(assetFn, RAIN_LOCAL_PATH)
    if ok and asset then
        return asset
    end
    warn("[Weather] getcustomasset failed: " .. tostring(asset))
    return nil
end

local RAIN_TEXTURE = ensureRainTexture()

local RAIN_TEX = RAIN_TEXTURE or "rbxasset://textures/particles/smoke_main.dds"

-- ====== 粒子 spec（對照 Kicia EmitterSpecsByPreset） ======
local WEATHER_SPECS = {
    rain = {
    {
        Texture = RAIN_TEX,
        TransparencyMax = 0.65,
        LifetimeMin = 0.7, LifetimeMax = 1.1,
        BaseRate = 45,                    -- 低频，每个粒子=一整片雨幕
        SpeedMin = 160, SpeedMax = 200,   -- 匀速下落
        SizeStart = 45, SizeEnd = 45,     -- 整片雨幕尺寸
        BaseSpread = 0.0,                 -- 零横向扩散
        BaseAccelerationY = -120,         -- 轻微加速，保持竖直
        RotationMin = 0, RotationMax = 0,
        RotationSpeedMin = 0, RotationSpeedMax = 0,
        -- 不设 Orientation，保持默认 FacingCameraWorldUp
    },
},
heavyRain = {
    {
        Texture = RAIN_TEX,
        TransparencyMax = 0.75,
        LifetimeMin = 0.5, LifetimeMax = 0.8,
        BaseRate = 90,                    -- 更密
        SpeedMin = 240, SpeedMax = 300,
        SizeStart = 55, SizeEnd = 55,
        BaseSpread = 0.0,
        BaseAccelerationY = -220,
        RotationMin = 0, RotationMax = 0,
        RotationSpeedMin = 0, RotationSpeedMax = 0,
    },
},
    snow = {
        {
            Texture = "rbxasset://textures/particles/smoke_main.dds",
            TransparencyMax = 0.15,
            LifetimeMin = 6, LifetimeMax = 9,
            BaseRate = 220,
            SpeedMin = 6, SpeedMax = 10,
            SizeStart = 0.35, SizeEnd = 0.25,
            BaseSpread = 0.4,
            BaseAccelerationY = -1,
        },
        {
            Texture = "rbxasset://textures/particles/sparkles_main.dds",
            TransparencyMax = 0.35,
            LifetimeMin = 6, LifetimeMax = 9,
            BaseRate = 60,
            SpeedMin = 5, SpeedMax = 8,
            SizeStart = 0.20, SizeEnd = 0.15,
            BaseSpread = 0.6,
            BaseAccelerationY = -0.5,
        },
    },
}

local function transparencyCurve(tMax)
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.15, tMax),
        NumberSequenceKeypoint.new(0.85, tMax),
        NumberSequenceKeypoint.new(1, 1),
    })
end

local function makeEmitter(spec, parent)
    local p = Instance.new("ParticleEmitter")
    p.Shape = Enum.ParticleEmitterShape.Box
    p.EmissionDirection = Enum.NormalId.Bottom
    p.Texture = spec.Texture
    p.Transparency = transparencyCurve(spec.TransparencyMax or 0.35)
    p.Lifetime = NumberRange.new(spec.LifetimeMin, spec.LifetimeMax)
    p.Rotation = NumberRange.new(spec.RotationMin or 0, spec.RotationMax or 0)
    p.RotSpeed = NumberRange.new(spec.RotationSpeedMin or 0, spec.RotationSpeedMax or 0)
    p.LightInfluence = 0
    if spec.Orientation then p.Orientation = spec.Orientation end
    p.Enabled = false
    p.Parent = parent
    return p
end

local function rebuildWeatherEmitters(kind)
    local folder, anchor = ensureWeatherFolder()
    if not folder or not anchor then return end

    for _, e in ipairs(WeatherEmitters) do
        e.Emitter:Destroy()
    end
    WeatherEmitters = {}
    weatherKindActive = kind

    local specs = WEATHER_SPECS[kind]
    if not specs then return end

    for _, spec in ipairs(specs) do
        local emitter = makeEmitter(spec, anchor)
        table.insert(WeatherEmitters, { Emitter = emitter, Spec = spec })
    end
end

local function reconcileWeather()
    local cfg = Weather

    if not cfg.Enabled then
        for _, e in ipairs(WeatherEmitters) do
            e.Emitter.Enabled = false
        end
        return
    end

    local kind = string.lower(cfg.Type or "sunny")
    local map = {
        ["rain"] = "rain",
        ["heavy rain"] = "heavyRain",
        ["snow"] = "snow",
    }

    local wanted = map[kind]
    if not wanted then
        for _, e in ipairs(WeatherEmitters) do
            e.Emitter.Enabled = false
        end
        return
    end

    if weatherKindActive ~= wanted or #WeatherEmitters == 0 then
        rebuildWeatherEmitters(wanted)
    end

    local intensity = tonumber(cfg.Intensity) or 150
    local speed = tonumber(cfg.Speed) or 1
    local size = tonumber(cfg.Size) or 1
    local spread = tonumber(cfg.Spread) or 1
    local glow = tonumber(cfg.Glow) or 0
    local color = ColorSequence.new(cfg.Color or Color3.fromRGB(255, 255, 255))

    for _, entry in ipairs(WeatherEmitters) do
        local e, spec = entry.Emitter, entry.Spec
        e.Enabled = true
        e.Rate = spec.BaseRate * (intensity / 150)
        e.Speed = NumberRange.new(spec.SpeedMin * speed, spec.SpeedMax * speed)
        e.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, spec.SizeStart * size),
            NumberSequenceKeypoint.new(1, spec.SizeEnd * size),
        })
        e.LightEmission = glow
        local s = spec.BaseSpread * 60 * spread
        e.SpreadAngle = Vector2.new(s, s)
        e.Color = color
        e.Acceleration = Vector3.new(0, spec.BaseAccelerationY, 0)
    end
end

local function updateWeatherAnchor()
    if not WeatherFolder or not WeatherFolder.Parent then return end
    if not WeatherAnchor or not WeatherAnchor.Parent then
        ensureWeatherFolder()
        return
    end
    local cam = workspace.CurrentCamera
    if cam then
        WeatherAnchor.CFrame = cam.CFrame * CFrame.new(0, 80, 0)
    end
end

local function cleanupWeather()
    for _, e in ipairs(WeatherEmitters) do
        if e.Emitter then e.Emitter:Destroy() end
    end
    WeatherEmitters = {}
    weatherKindActive = nil

    if WeatherFolder and WeatherFolder.Parent then
        WeatherFolder:Destroy()
    end
    WeatherFolder = nil
    WeatherAnchor = nil
end

-- ============================================================
-- Lightning (visual only)
-- ============================================================
local LightningFolder
local LightningPartsActive = {} -- [part] = expiryTime
local lastLightningAt = 0

local function ensureLightningFolder()
    if LightningFolder and LightningFolder.Parent then
        return LightningFolder
    end
    local f = Instance.new("Folder")
    f.Name = "OnyxLightning"
    f.Parent = workspace
    LightningFolder = f
    return f
end

local function makeBoltPart(parent, a, b, color, thickness)
    local dist = (b - a).Magnitude
    if dist <= 0.01 then return nil end
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Size = Vector3.new(thickness, thickness, dist)
    p.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -dist / 2)
    p.Transparency = 0
    p.Parent = parent
    return p
end

local function jitterPoint(base, factor)
    local j = LCFG.Jitter * factor
    return base + Vector3.new(
        (math.random() - 0.5) * j,
        (math.random() - 0.5) * j,
        (math.random() - 0.5) * j
    )
end

local function spawnLightningBolt(fromWorld, toWorld, cfg)
    local folder = ensureLightningFolder()
    local color = cfg.Color.Keypoints[1].Value
    local thickness = cfg.Thickness
    local branches = cfg.Branches or 0

    local segments = 24
    local points = { fromWorld }
    for i = 1, segments do
        local t = i / segments
        local base = fromWorld:Lerp(toWorld, t)
        local factor = 0.3 + 0.7 * (1 - math.sin(t * math.pi))
        table.insert(points, jitterPoint(base, factor))
    end
    points[#points] = toWorld

    local created = {}
    local prev = points[1]
    for i = 2, #points do
        local cur = points[i]
        local p = makeBoltPart(folder, prev, cur, color, thickness)
        if p then table.insert(created, p) end
        prev = cur
    end

    for _ = 1, branches do
        local t0 = 0.15 + math.random() * 0.65
        local idx = math.clamp(math.floor(t0 * #points), 1, #points)
        local a = points[idx]
        local dir = (toWorld - fromWorld).Unit
        local base = (dir + Vector3.new(
            (math.random() - 0.5) * 1.2,
            (math.random() - 0.5) * 1.2,
            (math.random() - 0.5) * 1.2
        )).Unit
        local branchEnd = a + base * (20 + math.random() * 40)
        local bseg = 6
        local bprev = a
        for i = 1, bseg do
            local bt = i / bseg
            local bcur = jitterPoint(a:Lerp(branchEnd, bt), 0.6)
            local p = makeBoltPart(folder, bprev, bcur, color, thickness * 0.6)
            if p then table.insert(created, p) end
            bprev = bcur
        end
    end

    return created
end

local function playThunder(distance, sound)
    if not sound or not sound.Enabled then return end
    local sid = sound.SoundId
    if not sid or sid == "" then return end
    local delay = (sound.Delay ~= false) and (distance / LCFG.ThunderSpeed) or 0
    local vol = (sound.Volume or 1) * math.max(LCFG.ThunderVolumeFloor, 1 - distance / LCFG.ThunderFalloff)
    local pitch = LCFG.ThunderPitchMin
        + math.random() * (LCFG.ThunderPitchMax - LCFG.ThunderPitchMin)

    task.delay(delay, function()
        local s = Instance.new("Sound")
        s.SoundId = sid
        s.Volume = vol
        s.PlaybackSpeed = pitch
        s.PlayOnRemove = true
        s.Parent = SoundService
        s:Destroy()
    end)
end

local function fireLightningStrike()
    if not WeatherLightning.Enabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    local camPos = cam.CFrame.Position
    local angle = math.random() * math.tau
    local rmin = math.min(LCFG.RadiusMin, WeatherLightning.Distance)
    local r = rmin + math.random() * (WeatherLightning.Distance - rmin)
    local wx = camPos.X + math.cos(angle) * r
    local wz = camPos.Z + math.sin(angle) * r

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        rayParams.FilterDescendantsInstances = { char }
    end

    local height = WeatherLightning.Height
    local groundY = camPos.Y - LCFG.GroundDrop
    local hit = workspace:Raycast(
        Vector3.new(wx, camPos.Y + height, wz),
        Vector3.new(0, -LCFG.RayLength, 0),
        rayParams
    )
    if hit then groundY = hit.Position.Y end

    local top = Vector3.new(wx, groundY + height, wz)
    local bottom = Vector3.new(wx, groundY, wz)
    local parts = spawnLightningBolt(top, bottom, WeatherLightning)
    local now = os.clock()
    for _, p in ipairs(parts) do
        LightningPartsActive[p] = now
    end

    -- flash
    if WeatherLightning.Flash and WeatherLightning.Flash > 0 then
        local flashPart = Instance.new("Part")
        flashPart.Anchored = true
        flashPart.CanCollide = false
        flashPart.CanQuery = false
        flashPart.CanTouch = false
        flashPart.Transparency = 1
        flashPart.Size = Vector3.one
        flashPart.CFrame = CFrame.new(bottom)
        flashPart.Parent = ensureLightningFolder()

        local light = Instance.new("PointLight")
        light.Color = WeatherLightning.Color.Keypoints[1].Value
        light.Brightness = WeatherLightning.Flash
        light.Range = 70
        light.Parent = flashPart

        task.spawn(function()
            for _ = 1, math.random(LCFG.FlickerMin, LCFG.FlickerMax) do
                light.Brightness = WeatherLightning.Flash * (0.6 + math.random() * 0.4)
                task.wait(LCFG.FlickerOnMin + math.random() * (LCFG.FlickerOnMax - LCFG.FlickerOnMin))
                light.Brightness = WeatherLightning.Flash * LCFG.FlickerDim
                task.wait(LCFG.FlickerOffMin + math.random() * (LCFG.FlickerOffMax - LCFG.FlickerOffMin))
            end
            local tw = TweenService:Create(light, TweenInfo.new(0.35), { Brightness = 0 })
            tw:Play()
            task.delay(0.5, function()
                if flashPart and flashPart.Parent then flashPart:Destroy() end
            end)
        end)
    end

    -- fade
    task.delay(0.12, function()
        for _, p in ipairs(parts) do
            if p and p.Parent then
                local tw = TweenService:Create(p, TweenInfo.new(LCFG.FadeDuration), { Transparency = 1 })
                tw:Play()
                task.delay(LCFG.FadeDuration + LCFG.CleanupBuffer, function()
                    if p and p.Parent then p:Destroy() end
                    LightningPartsActive[p] = nil
                end)
            end
        end
    end)

    local dist = math.sqrt((wx - camPos.X)^2 + (wz - camPos.Z)^2)
    playThunder(dist, WeatherLightning.Sound)
end

local function tickLightning()
    if not WeatherLightning.Enabled then return end
    if not Weather.Enabled then return end
    if not (Weather.Type == "rain" or Weather.Type == "heavy rain") then
        return
    end
    if os.clock() - lastLightningAt < WeatherLightning.Interval then return end
    lastLightningAt = os.clock()
    fireLightningStrike()
end

-- 清理殘留（找不到 parent 的 part 保險刪掉）
local function sweepLightning()
    for p, t in pairs(LightningPartsActive) do
        if not p or not p.Parent or os.clock() - t > 2.5 then
            if p and p.Parent then p:Destroy() end
            LightningPartsActive[p] = nil
        end
    end
end

local _weatherFrame = 0
RunService.RenderStepped:Connect(function()
    _weatherFrame = _weatherFrame + 1
    if _weatherFrame % 4 ~= 0 then return end
    pcall(reconcileWeather)
    pcall(updateWeatherAnchor)
    pcall(tickLightning)
    pcall(sweepLightning)
    pcall(applySky)
end)
-- ============================================================
-- Custom Fog
-- ============================================================
getgenv().CustomFog = getgenv().CustomFog or {
    Enabled = false,
    Start = 0,
    End = 150,
    Color = Color3.fromRGB(180, 180, 180),
    Density = 0.5,
    ColorEnabled = true,
}

local function getOrCreateAtmosphere()
    local atmos = Lighting:FindFirstChild("CustomFogAtmosphere")
    if not atmos then
        local oldAtmos = Lighting:FindFirstChildOfClass("Atmosphere")
        if oldAtmos and oldAtmos.Name ~= "CustomFogAtmosphere" then oldAtmos:Destroy() end

        atmos = Instance.new("Atmosphere")
        atmos.Name = "CustomFogAtmosphere"
        atmos.Parent = Lighting
    end
    return atmos
end

local function removeAtmosphere()
    local atmos = Lighting:FindFirstChild("CustomFogAtmosphere")
    if atmos then atmos:Destroy() end
end

local function updateFogSystem()
    local cfg = getgenv().CustomFog
    if not cfg.Enabled then
        removeAtmosphere()
        return
    end

    local atmos = getOrCreateAtmosphere()
    local targetColor = cfg.Color or Color3.fromRGB(180, 180, 180)

    atmos.Color = targetColor
    atmos.Decay = targetColor
    atmos.Density = cfg.Density or 0.5

    local startVal = cfg.Start or 0
    local endVal = cfg.End or 150
    atmos.Haze = math.clamp((1000 / (endVal - startVal)), 0, 10)
end

local _fogFrame = 0
RunService.RenderStepped:Connect(function()
    _fogFrame = _fogFrame + 1
    if _fogFrame % 4 ~= 0 then return end
    pcall(updateFogSystem)
end)

-- ============================================================
-- Eye Protection
-- ============================================================
getgenv().ColorCorrection = Lighting:FindFirstChild("EyeProtection")
if not getgenv().ColorCorrection then
    getgenv().ColorCorrection = Instance.new("ColorCorrectionEffect")
    getgenv().ColorCorrection.Name = "EyeProtection"
    getgenv().ColorCorrection.Parent = Lighting
end
local ColorCorrection = getgenv().ColorCorrection

getgenv().EyeProtection = getgenv().EyeProtection or {
    Enabled = false,
    Color = Color3.fromRGB(110, 90, 235),
    Brightness = -0.05,
    Contrast = -0.1,
    Saturation = -0.2,
}

task.spawn(function()
    while true do
        local cfg = getgenv().EyeProtection
        ColorCorrection.Enabled = cfg.Enabled
        ColorCorrection.TintColor = cfg.Color
        ColorCorrection.Brightness = cfg.Brightness
        ColorCorrection.Contrast = cfg.Contrast
        ColorCorrection.Saturation = cfg.Saturation
        task.wait()
    end
end)

-- ============================================================
-- ThirdPerson
-- ============================================================
local local_player = LocalPlayer

pcall(function()
    getgenv().CameraController = require(
        local_player:WaitForChild("PlayerScripts", 3)
            :WaitForChild("Controllers", 3)
            :WaitForChild("CameraController", 3)
    )
end)
local CameraController = getgenv().CameraController

getgenv().ThirdPerson = getgenv().ThirdPerson or {
    Enable = false,
}

getgenv().originalPOV = getgenv().originalPOV or nil
task.spawn(function()
    local state = CameraController.CameraState
    getgenv().originalPOV = state:GetPublicState()
end)

function ThirdPersonSetEnabled(v)
    getgenv().ThirdPerson.Enable = v

    if CameraController.SetThirdPersonOverride then
        CameraController:SetThirdPersonOverride(v)
    end

    if not v then
        local state = CameraController.CameraState
        if state:GetPublicState() ~= state.States.FirstPerson then
            if getgenv().originalPOV ~= nil and state.SetPublicState then
                pcall(function()
                    state:SetPublicState(getgenv().originalPOV)
                end)
            else
                pcall(function()
                    state:TogglePOV()
                end)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not getgenv().ThirdPerson.Enable then return end

    local state = CameraController.CameraState
    if state:GetPublicState() ~= state.States.ThirdPerson then
        pcall(function()
            state:TogglePOV()
        end)
    end
end)

-- ============================================================
-- Fly
-- ============================================================
getgenv().Player = LocalPlayer
Player = getgenv().Player
UIS = UserInputService

getgenv().Fly = getgenv().Fly or {
    flying = false,
    flyspeed = 50,
    keys = {
        W=false, A=false, S=false, D=false,
        E=false, Q=false,
        Space=false, LeftShift=false
    }
}
local Fly = getgenv().Fly
keys = Fly.keys

Character = nil
HRP = nil
Humanoid = nil

function CleanupForCharacter(char)
    if not char then return end

    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BodyVelocity") then
            v:Destroy()
        end
    end
end

getgenv().bv = getgenv().bv or nil

function BindCharacter(char)
    CleanupForCharacter(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")

    if Fly.flying then
        if getgenv().bv then getgenv().bv:Destroy() end
        getgenv().bv = Instance.new("BodyVelocity")
        getgenv().bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        getgenv().bv.Velocity = Vector3.zero
        getgenv().bv.Parent = HRP
    end
end

function EnableFlying()
    Fly.flying = true
    if HRP then
        if getgenv().bv then getgenv().bv:Destroy() end
        getgenv().bv = Instance.new("BodyVelocity")
        getgenv().bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        getgenv().bv.Velocity = Vector3.new(0,0,0)
        getgenv().bv.Parent = HRP
    end
end

function DisableFlying()
    Fly.flying = false
    if getgenv().bv then
        getgenv().bv:Destroy()
        getgenv().bv = nil
    end
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if keys[key] ~= nil then keys[key] = true end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if keys[key] ~= nil then keys[key] = false end
    end
end)

RunService.RenderStepped:Connect(function()
    if Fly.flying and HRP and getgenv().bv then
        local moveDir = Vector3.new(
            (keys.D and 1 or 0) - (keys.A and 1 or 0),
            (keys.Space and 1 or 0) - (keys.LeftShift  and 1 or 0),
            (keys.S and 1 or 0) - (keys.W and 1 or 0)
        )

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            local cam = Workspace.CurrentCamera
            local worldDir = cam.CFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z))
            getgenv().bv.Velocity = worldDir * Fly.flyspeed + Vector3.new(0, moveDir.Y * Fly.flyspeed, 0)
        else
            getgenv().bv.Velocity = Vector3.new(0, 0, 0)
        end
    end
end)

if Player.Character then
    BindCharacter(Player.Character)
end
Player.CharacterAdded:Connect(BindCharacter)

-- ============================================================
-- Infinite Jump
-- ============================================================
local player = LocalPlayer

local player = Players.LocalPlayer

getgenv().InfiniteJump = getgenv().InfiniteJump or false

getgenv().jumpConnection = getgenv().jumpConnection or nil

local function setupInfiniteJump(character)
    local humanoid = character:WaitForChild("Humanoid")

    if getgenv().jumpConnection then
        getgenv().jumpConnection:Disconnect()
        getgenv().jumpConnection = nil
    end

    getgenv().jumpConnection = UserInputService.JumpRequest:Connect(function()
        if getgenv().InfiniteJump and humanoid and humanoid.Parent then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

if player.Character then
    setupInfiniteJump(player.Character)
end

player.CharacterAdded:Connect(function(character)
    setupInfiniteJump(character)
end)

-- ============================================================
-- WalkSpeed
-- ============================================================
lp = LocalPlayer

getgenv().WalkSpeed = getgenv().WalkSpeed or {
    Enabled = false,
    Speed = 1,
}

getgenv().WalkSpeedCharacter = getgenv().WalkSpeedCharacter or nil
getgenv().WalkSpeedHumanoid = getgenv().WalkSpeedHumanoid or nil
getgenv().WalkSpeedHRP = getgenv().WalkSpeedHRP or nil
getgenv().WalkSpeedRenderConn = getgenv().WalkSpeedRenderConn or nil

function bindCharacter(char)
    getgenv().WalkSpeedCharacter = char
    getgenv().WalkSpeedHumanoid = char:WaitForChild("Humanoid")
    getgenv().WalkSpeedHRP = char:WaitForChild("HumanoidRootPart")

    getgenv().WalkSpeedHumanoid.WalkSpeed = 16
    getgenv().WalkSpeedHumanoid.AutoRotate = true
end

function enableCustomMove()
    if getgenv().WalkSpeedRenderConn then return end

    getgenv().WalkSpeedRenderConn = RunService.RenderStepped:Connect(function(dt)

        local cfg = getgenv().WalkSpeed
        if not cfg.Enabled then return end
        if not getgenv().WalkSpeedCharacter or not getgenv().WalkSpeedHumanoid or not getgenv().WalkSpeedHRP then return end
        if getgenv().WalkSpeedHumanoid.Health <= 0 then return end

        getgenv().WalkSpeedHumanoid.WalkSpeed = 0
        getgenv().WalkSpeedHumanoid.AutoRotate = false

        local moveDirection = getgenv().WalkSpeedHumanoid.MoveDirection

        if moveDirection.Magnitude > 0 then
            local displacement = moveDirection.Unit * cfg.Speed * dt
            getgenv().WalkSpeedHRP.CFrame = getgenv().WalkSpeedHRP.CFrame + displacement
        end
    end)
end

function disableCustomMove()
    if getgenv().WalkSpeedRenderConn then
        getgenv().WalkSpeedRenderConn:Disconnect()
        getgenv().WalkSpeedRenderConn = nil
    end

    if getgenv().WalkSpeedHumanoid then
        getgenv().WalkSpeedHumanoid.WalkSpeed = 16
        getgenv().WalkSpeedHumanoid.AutoRotate = true
    end
end

if lp.Character then
    bindCharacter(lp.Character)
end

lp.CharacterAdded:Connect(bindCharacter)

local _wsToggleFrame = 0
RunService.RenderStepped:Connect(function()
    _wsToggleFrame = _wsToggleFrame + 1
    if _wsToggleFrame % 3 ~= 0 then return end
    if getgenv().WalkSpeed.Enabled then
        enableCustomMove()
    else
        disableCustomMove()
    end
end)

-- ============================================================
-- Spin
-- ============================================================
player = LocalPlayer

player = Players.LocalPlayer
getgenv().Spin = getgenv().Spin or {
    Enabled = false,
    Speed = 1,
}

getgenv().spinConn = getgenv().spinConn or nil

function setup(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if getgenv().spinConn then
        getgenv().spinConn:Disconnect()
        getgenv().spinConn = nil
    end

    getgenv().spinConn = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then
            return
        end

        local cfg = getgenv().Spin
        if cfg.Enabled then
            if hum then
                hum.AutoRotate = false
            end

            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(cfg.Speed), 0)
        else
            if hum then
                hum.AutoRotate = true
            end
        end
    end)
end

if player.Character then
    setup(player.Character)
end

player.CharacterAdded:Connect(setup)

-- ============================================================
-- Noclip
-- ============================================================
local lp = LocalPlayer

getgenv().Noclip = getgenv().Noclip or false

getgenv().NoclipCharacter = getgenv().NoclipCharacter or nil

getgenv().targetParts = getgenv().targetParts or {
    ["HumanoidRootPart"] = true,
    ["PhysicalHitboxHead"] = true
}
local targetParts = getgenv().targetParts

local function bindCharacter(char)
    getgenv().NoclipCharacter = char
end

if lp.Character then
    bindCharacter(lp.Character)
end

lp.CharacterAdded:Connect(bindCharacter)

local _noclipCachedChar = nil
local _noclipCachedParts = {}
local function _rebuildNoclipCache(char)
    _noclipCachedChar = char
    _noclipCachedParts = {}
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and targetParts[v.Name] then
            table.insert(_noclipCachedParts, v)
        end
    end
end
RunService.Heartbeat:Connect(function()
    local char = getgenv().NoclipCharacter
    if not char then return end
    if char ~= _noclipCachedChar then _rebuildNoclipCache(char) end
    local state = not getgenv().Noclip
    for _, v in ipairs(_noclipCachedParts) do
        if v.Parent then v.CanCollide = state end
    end
end)

-- ============================================================
-- SlideBoost
-- ============================================================
getgenv().SlideBoost = getgenv().SlideBoost or {
    Enabled = false,
    Speed   = 100,
}

pcall(function()
    getgenv().mech = getgenv().mech or require(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.MechanicsController)
end)
local mech = getgenv().mech

local _slideFrame = 0
game:GetService("RunService").RenderStepped:Connect(function()
    _slideFrame = _slideFrame + 1
    if _slideFrame % 2 ~= 0 then return end
    local cfg = getgenv().SlideBoost
    if not cfg or not cfg.Enabled then return end

    if mech.IsSliding then
        mech._sliding_velocity.Velocity = mech._sliding_velocity.Velocity.Unit * cfg.Speed
    end
end)

-- ============================================================
-- Animation System
-- ============================================================
getgenv().Config = getgenv().Config or {
    Animation = "Agree",

    KnownAnimations = {
        ["Agree"] = { ID = 85429197687197, SOUNDS = {78663178795648}, LOOPSOUNDS = false },
        ["Coo Coo"] = { ID = 125921589993721, SOUNDS = {134218301690577, 71288358864209}, LOOPSOUNDS = false },
        ["Cream Cheese Honey"] = { ID = 71250144811352, SOUNDS = {120250934207816}, LOOPSOUNDS = true },
        ["Criss Cross"] = { ID = 95986480266032, SOUNDS = {120250934207816}, LOOPSOUNDS = true },
        ["Denial"] = { ID = 81555757574094, SOUNDS = {75485128790168, 13158735106, 13158735106, 13158735106}, LOOPSOUNDS = false },
        ["Facepalm"] = { ID = 103862270973168, SOUNDS = {88377109323880, 13160326139}, LOOPSOUNDS = false },
        ["Kneel"] = { ID = 84754316528381, SOUNDS = {134140996504107}, LOOPSOUNDS = false },
        ["Off of You"] = { ID = 105875604689697, SOUNDS = {137662451042014}, LOOPSOUNDS = true },
        ["ROFL"] = { ID = 73786487009083, SOUNDS = {122605533507524, 126514820442685}, LOOPSOUNDS = false },
        ["Round & Round"] = { ID = 104273989039620, SOUNDS = {129000171133220}, LOOPSOUNDS = true },
        ["Shivering"] = { ID = 102458102253574, SOUNDS = {121062822157622}, LOOPSOUNDS = true },
        ["Shoulder Brush"] = { ID = 119282539520778, SOUNDS = {79768694812211, 79768694812211, 79768694812211, 79768694812211}, LOOPSOUNDS = false },
        ["Side To Side"] = { ID = 77255514751814, SOUNDS = {88051081362116}, LOOPSOUNDS = true },
        ["Smile"] = { ID = 98020061651338, SOUNDS = {98020061651338, 100664444144490}, LOOPSOUNDS = true },
        ["Snow Angels"] = { ID = 93924392025280, SOUNDS = {}, LOOPSOUNDS = false },
        ["Superhero"] = { ID = 115000869501227, SOUNDS = {80133530921906, 98970356172671}, LOOPSOUNDS = true },
        ["Take The L"] = { ID = 104639476409829, SOUNDS = {116605809326430}, LOOPSOUNDS = true },
        ["Think"] = { ID = 133733650708343, SOUNDS = {13160326139, 13160326139}, LOOPSOUNDS = false },
        ["Vegetable"] = { ID = 95292230449040, SOUNDS = {120797927157164}, LOOPSOUNDS = true }
    }
}
local Config = getgenv().Config

getgenv().AnimationSystem = getgenv().AnimationSystem or {
    CurrentTrack = nil,
    CurrentSounds = {},
    Connections = {},
    Enabled = false,
}
local AnimationSystem = getgenv().AnimationSystem

function AnimationSystem:StopAll()
    if self.CurrentTrack then
        pcall(function()
            self.CurrentTrack:Stop()
            self.CurrentTrack:Destroy()
        end)
        self.CurrentTrack = nil
    end

    for _, sound in ipairs(self.CurrentSounds) do
        pcall(function()
            sound:Stop()
            sound:Destroy()
        end)
    end
    table.clear(self.CurrentSounds)

    for name, conn in pairs(self.Connections) do
        if conn then
            conn:Disconnect()
            self.Connections[name] = nil
        end
    end

    local animFolder = LocalPlayer:FindFirstChild("Animations")
    if animFolder then animFolder:Destroy() end

    local soundFolder = LocalPlayer:FindFirstChild("Sounds")
    if soundFolder then soundFolder:Destroy() end
end

function AnimationSystem:PlaySound(id, looped)
    local folder = LocalPlayer:FindFirstChild("Sounds") or Instance.new("Folder")
    folder.Name = "Sounds"
    folder.Parent = LocalPlayer

    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Looped = looped
    sound.Volume = 1
    sound.Parent = folder
    sound:Play()

    table.insert(self.CurrentSounds, sound)

    if not looped then
        sound.Ended:Connect(function()
            for i, s in ipairs(self.CurrentSounds) do
                if s == sound then
                    table.remove(self.CurrentSounds, i)
                    break
                end
            end
            pcall(function() sound:Destroy() end)
        end)
    end
end

function AnimationSystem:StartOverrideLoop()
    if self.Connections.Override then
        self.Connections.Override:Disconnect()
        self.Connections.Override = nil
    end

    self.Connections.Override = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        if not self.CurrentTrack then return end

        if not self.CurrentTrack.IsPlaying then
            self.CurrentTrack:Play()
        end
    end)
end

function AnimationSystem:PlayCurrent()
    local selected = Config and Config.KnownAnimations and Config.KnownAnimations[Config.Animation]
    if not selected then return end

    self:StopAll()

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid

    local folder = Instance.new("Folder")
    folder.Name = "Animations"
    folder.Parent = LocalPlayer

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(selected.ID)
    animation.Parent = folder

    local track = animator:LoadAnimation(animation)
    track.Looped = true
    track.Priority = Enum.AnimationPriority.Action4
    track:Play()
    self.CurrentTrack = track

    self.Connections.Died = humanoid.Died:Connect(function()
        self:StopAll()
    end)

    self:StartOverrideLoop()
end

function AnimationSystem:SetEnabled(v)
    self.Enabled = v
    if v then
        self:PlayCurrent()
    else
        self:StopAll()
    end
end

function AnimationSystem:InitCharacterListener()
    if self.CharacterConn then
        self.CharacterConn:Disconnect()
    end

    self.CharacterConn = LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        humanoid:WaitForChild("Animator", 5)

        task.wait(0.1)

        if self.Enabled then
            self:PlayCurrent()
        end
    end)
end

AnimationSystem:InitCharacterListener()

-- ============================================================
-- autoqueue
-- ============================================================
getgenv().autoqueue = getgenv().autoqueue or {
    QueueGonnaUse = "1v1",
    AutoMatch = false
}

Services.RunService.Heartbeat:Connect(function()
    if getgenv().autoqueue.AutoMatch == true then
        if isLobbyVisible() then
            pcall(function()
              ReplicatedStorage.Remotes.Matchmaking.JoinQueue:InvokeServer(getgenv().autoqueue.QueueGonnaUse)
          end)
        end
    end
end)

-- anti aim
getgenv().AntiAim = {
    Enabled = false,
    Yaw = "none",              -- none / jitter / spinbot / random
    Pitch = "none",            -- none / jitter / spinbot / random
    Angle = "none",            -- none / tilt 45 / tilt 90 / upside down / custom
    CustomAngle = 0,
    MinSpeed = 10,
    MaxSpeed = 20,
    MinAngle = 30,
    MaxAngle = 60,
    RandomAngle = false,
    Underground = false,
}

AntiAimState = {
    FrameCounter = 0,
    SmoothYaw = 0,
    SmoothPitch = 0,
    SmoothRoll = 0,
    UndergroundOldPos = nil,
}

function isAntiAimActive()
    local cfg = getgenv().AntiAim
    if not cfg.Enabled then return false end
    if cfg.Yaw == "none" and cfg.Pitch == "none" and cfg.Angle == "none" then
        return false
    end
    return true
end

local function curweap2()
    local viewModels = Workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, child in ipairs(firstPerson:GetChildren()) do
        local childName = child.Name
        local parts = {}
        for part in childName:gmatch("[^-]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end
        if #parts >= 2 then
            return parts[2]
        end
    end
    return nil
end

local fighter_controller
pcall(function()
    fighter_controller = require(
        LocalPlayer.PlayerScripts.Controllers.FighterController
    )
end)
local local_fighter = fighter_controller and fighter_controller.LocalFighter
local camera_controller
pcall(function()
    camera_controller = require(
        LocalPlayer.PlayerScripts.Controllers.CameraController
    )
end)

local function getFloorBelowPosition(pos)
    local rayOrigin = pos
    local rayDirection = Vector3.new(0, -500, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    if local_fighter and local_fighter.Entity and local_fighter.Entity.RootPart then
        raycastParams.FilterDescendantsInstances = { local_fighter.Entity.RootPart.Parent }
    end
    local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        return CFrame.new(Vector3.new(pos.X, result.Position.Y - 2, pos.Z))
    end
    return nil
end

local old_underground_camera_controller = camera_controller.Update
camera_controller.Update = function(...)
    local arguments = { ... }
    if getgenv().AntiAim.Underground
        and local_fighter and local_fighter.Entity and local_fighter.Entity.RootPart
        and AntiAimState.UndergroundOldPos then
        local_fighter.Entity.RootPart.CFrame = AntiAimState.UndergroundOldPos
    end
    return old_underground_camera_controller(table.unpack(arguments))
end

local function calculateYaw(deltaTime)
    local cfg = getgenv().AntiAim
    local yaw = 0
    local currentTime = tick()

    if cfg.Yaw == "jitter" then
        local minA = math.rad(cfg.MinAngle)
        local maxA = math.rad(cfg.MaxAngle)
        if cfg.RandomAngle then
            yaw = minA + math.random() * (maxA - minA)
            if math.random() > 0.5 then yaw = -yaw end
        else
            yaw = math.random() > 0.5 and minA or -minA
        end

    elseif cfg.Yaw == "spinbot" then
        local speed = cfg.MinSpeed / 10
            + math.random() * (cfg.MaxSpeed / 10 - cfg.MinSpeed / 10)
        yaw = (currentTime * speed) % (2 * math.pi)

    elseif cfg.Yaw == "random" then
        if AntiAimState.FrameCounter % 30 == 0 then
            yaw = math.rad(cfg.MaxAngle) * (math.random() * 2 - 1)
        else
            yaw = AntiAimState.SmoothYaw
        end
    end

    return yaw
end

local function calculatePitch()
    local cfg = getgenv().AntiAim
    local pitch = 0

    if cfg.Pitch == "jitter" then
        local minA = math.rad(cfg.MinAngle)
        local maxA = math.rad(cfg.MaxAngle)
        if cfg.RandomAngle then
            pitch = minA + math.random() * (maxA - minA)
            if math.random() > 0.5 then pitch = -pitch end
        else
            pitch = math.random() > 0.5 and minA or -minA
        end

    elseif cfg.Pitch == "spinbot" then
        pitch = math.sin(tick() * (cfg.MaxSpeed / 10)) * math.rad(cfg.MaxAngle)

    elseif cfg.Pitch == "random" then
        if AntiAimState.FrameCounter % 20 == 0 then
            pitch = math.rad(math.random(-89, 89))
        else
            pitch = AntiAimState.SmoothPitch
        end
    end

    return pitch
end

local function calculateRoll()
    local cfg = getgenv().AntiAim
    local roll = 0

    if cfg.Angle == "tilt 45" then
        roll = math.rad(45)
    elseif cfg.Angle == "tilt 90" then
        roll = math.rad(90)
    elseif cfg.Angle == "upside down" then
        roll = math.rad(180)
    elseif cfg.Angle == "custom" then
        roll = math.rad(cfg.CustomAngle)
    end

    return roll
end

local function flushAntiAimMovementState()
    AntiAimState.UndergroundOldPos = nil
    AntiAimState.FrameCounter = 0
    AntiAimState.SmoothYaw = 0
    AntiAimState.SmoothPitch = 0
    AntiAimState.SmoothRoll = 0

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

getgenv().InstanceFlushMovementState = function()
    flushAntiAimMovementState()
end

RunService.Heartbeat:Connect(function(deltaTime)
    if getgenv().InstanceConfigLoading then return end

    local cfg = getgenv().AntiAim

    if cfg.Underground then
        local curweap = curweap2()
        if not curweap then
            AntiAimState.UndergroundOldPos = nil
        elseif local_fighter and local_fighter.Entity and local_fighter.Entity.RootPart then
            AntiAimState.UndergroundOldPos = local_fighter.Entity.RootPart.CFrame
            local floorCFrame = getFloorBelowPosition(local_fighter.Entity.RootPart.Position)
            if floorCFrame then
                local_fighter.Entity.RootPart.CFrame = floorCFrame
            end
        end
    else
        AntiAimState.UndergroundOldPos = nil
    end

    if not isAntiAimActive() then return end

    local curweap = curweap2()
    if not curweap then return end

    local character = LocalPlayer.Character
    if not character then return end

    local rootpart = character:FindFirstChild("HumanoidRootPart")
    if not rootpart then return end

    AntiAimState.FrameCounter = AntiAimState.FrameCounter + 1

    local calculatedYaw = calculateYaw(deltaTime)
    local calculatedPitch = calculatePitch()
    local calculatedRoll = calculateRoll()

    local rotationCFrame = CFrame.Angles(calculatedPitch, calculatedYaw, calculatedRoll)
    rootpart.CFrame = rootpart.CFrame * rotationCFrame
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.defer(flushAntiAimMovementState)
end)

-- UI Library
local function clampVs(v)
    return math.clamp(tonumber(v) or 1, 0.1, 2)
end

local function randVs(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if a == b then
        return a
    end
    return a + math.random() * (b - a)
end

getgenv().InstanceSetUnderground = getgenv().InstanceSetUnderground or function(val)
    getgenv().InstanceUndergroundEnabled = val == true
end

if not getgenv().shouldSuppressGameplayOverlays then
    getgenv().shouldSuppressGameplayOverlays = function()
        if getgenv().InstanceIsMenuOpen then
            return getgenv().InstanceIsMenuOpen()
        end
        return false
    end
end

-- Export pure locals needed by the UI function
getgenv()._onyxBridge = {
    randVs                   = randVs,
    clampVs                  = clampVs,
    flushAntiAimMovementState = flushAntiAimMovementState,
}
end -- close _onyxGameLogic
local _glOk, _glErr = pcall(_onyxGameLogic)
if not _glOk then
    warn("[Onyx] _onyxGameLogic error: " .. tostring(_glErr))
end
-- Ensure bridge exists even if game logic partially failed
if not getgenv()._onyxBridge then
    getgenv()._onyxBridge = {}
end
getgenv()._onyxBridge.randVs = getgenv()._onyxBridge.randVs or function(a,b) return a end
getgenv()._onyxBridge.clampVs = getgenv()._onyxBridge.clampVs or function(v) return tonumber(v) or 1 end
getgenv()._onyxBridge.flushAntiAimMovementState = getgenv()._onyxBridge.flushAntiAimMovementState or function() end

local function _onyxUI()
-- Re-import locals exported by game logic
local randVs                   = getgenv()._onyxBridge.randVs
local clampVs                  = getgenv()._onyxBridge.clampVs
local flushAntiAimMovementState = getgenv()._onyxBridge.flushAntiAimMovementState
-- Re-import getgenv()-backed variables as locals for readability
local ragebot         = getgenv().ragebot
local rbCfg           = ragebot and ragebot.config or {}
local Effects         = getgenv().Effects         or {}
local Weather         = getgenv().Weather         or {}
local Skybox          = getgenv().Skybox          or {}
local CustomFog       = getgenv().CustomFog       or {}
local EyeProtection   = getgenv().EyeProtection   or {}
local Fly             = getgenv().Fly             or {}
local Config          = getgenv().Config          or {}
local AnimationSystem = getgenv().AnimationSystem
local ESPObjects      = getgenv().ESPObjects      or {}
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer     = Players.LocalPlayer
-- ============================================================
-- Onyx Premium – BitchBot UI Section
-- Library wrapper so HitNotify can call CreateNotification
-- ============================================================
local Library = {}
Library.Notify = function(self, msg)
    pcall(function() CreateNotification(tostring(msg)) end)
end

-- InstanceIsMenuOpen hook
getgenv().InstanceIsMenuOpen = function()
    return menu and menu.open
end

getgenv().shouldSuppressGameplayOverlays = function()
    if getgenv().InstanceIsMenuOpen then
        return getgenv().InstanceIsMenuOpen()
    end
    return false
end

-- ============================================================
-- Utility code preserved from original UI section
-- ============================================================
local MarketplaceService = Services.MarketplaceService
local TweenService       = Services.TweenService
local cache = {}

-- ── Bullet Tracers ──────────────────────────────────────────
getgenv().BulletTracersEnabled  = getgenv().BulletTracersEnabled  or false
getgenv().BulletTracersColor    = getgenv().BulletTracersColor    or Color3.fromRGB(255,255,255)
getgenv().BulletTracersLifetime = getgenv().BulletTracersLifetime or 1

local function FireBulletTracers(origin, endPos, lifetime, Color)
    if not origin or not endPos then return end
    local distance = (origin - endPos).Magnitude
    if distance <= 0.01 then return end
    local beam = Instance.new("Part")
    beam.Anchored   = true
    beam.CanCollide = false
    beam.CanQuery   = false
    beam.CanTouch   = false
    beam.Material   = Enum.Material.Neon
    beam.Color      = Color
    beam.Size       = Vector3.new(0.05, 0.05, distance)
    beam.Transparency = 0
    beam.CFrame     = CFrame.lookAt(origin, endPos) * CFrame.new(0,0,-distance/2)
    beam.Parent     = workspace
    task.delay(0.05, function()
        if not beam.Parent then return end
        local tween = TweenService:Create(beam, TweenInfo.new(lifetime), {Transparency=1})
        tween:Play()
        tween.Completed:Connect(function() beam:Destroy() end)
    end)
end

local MELEE_NMS_UI = {
    ["Battle Axe"]=true,["Chainsaw"]=true,["Daggers"]=true,["Fists"]=true,
    ["Gunblade"]=true,["Katana"]=true,["Knife"]=true,["Scythe"]=true,["Trowel"]=true,
}

local function getWeapon()
    local viewModels = workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, model in ipairs(firstPerson:GetChildren()) do
        if string.find(model.Name, LocalPlayer.Name, 1, true) then
            local parts = {}
            for part in model.Name:gmatch("[^-]+") do
                table.insert(parts, part:match("^%s*(.-)%s*$"))
            end
            if #parts >= 2 then return parts[2] end
        end
    end
    return nil
end

local function isGunEquipped()
    local weapon = getWeapon()
    if not weapon then return false end
    return MELEE_NMS_UI[weapon] ~= true
end

local function getViewmodelMuzzle()
    local viewModels = workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, model in ipairs(firstPerson:GetChildren()) do
        if string.find(model.Name, LocalPlayer.Name, 1, true) then
            local itemVisual = model:FindFirstChild("ItemVisual")
            if itemVisual then
                local body = itemVisual:FindFirstChild("Body")
                if body then
                    local bodyPrimary = body:FindFirstChild("BodyPrimary")
                    if bodyPrimary then
                        local muzzle = bodyPrimary:FindFirstChild("_muzzle")
                        if muzzle then
                            if muzzle:IsA("Attachment") then return muzzle.WorldPosition
                            elseif muzzle:IsA("BasePart") then return muzzle.Position end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getTracerEndPos(origin)
    local cam = workspace.CurrentCamera
    if not cam then return origin + Vector3.new(0,0,-1000) end
    local targetPart = getgenv().SilentAimTargetPart
    if getgenv().SilentAim and getgenv().SilentAim.Enabled and targetPart then
        return targetPart.Position
    end
    return cam.CFrame.Position + cam.CFrame.LookVector * 1000
end

-- ── HitNotify ───────────────────────────────────────────────
local HitNotify = {}
HitNotify.__index = HitNotify

local DEFAULT_CONFIG = { enabled=true, shotCreditWindow=4, hitCreditWindow=4 }

function HitNotify.new(library, config)
    local self = setmetatable({}, HitNotify)
    assert(library and type(library.Notify)=="function", "HitNotify.new need Notify's Library")
    self.library = library
    self.config  = {}
    for k,v in pairs(DEFAULT_CONFIG) do self.config[k]=v end
    for k,v in pairs(config or {}) do self.config[k]=v end
    self.Enabled             = self.config.enabled
    self.hpTrack             = {}
    self.humConn             = {}
    self.charConn            = {}
    self.hitPartByPlr        = {}
    self.lastHitAtPlr        = {}
    self.combatLastShotAt    = 0
    self.resolveQueues       = {}
    self.resolveBusy         = {}
    self.formatter           = nil
    self.filter              = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then self:_bindPlayer(plr) end
    end
    self._playerAddedConn    = Players.PlayerAdded:Connect(function(plr)
        if plr ~= LocalPlayer then self:_bindPlayer(plr) end
    end)
    self._playerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
        self:_unbindPlayer(plr)
    end)
    return self
end
function HitNotify:SetFormatter(fn) self.formatter=fn end
function HitNotify:SetFilter(fn)    self.filter=fn end
function HitNotify:MarkShot()       self.combatLastShotAt=tick() end
function HitNotify:NotifyProjectileImpact(hitPart)
    if not self.Enabled then return end
    if not hitPart then return end
    local plr,hum,bodyPart = self:_playerFromHitPart(hitPart)
    if not plr or not hum or plr==LocalPlayer then return end
    self.hitPartByPlr[plr]=bodyPart
    self.lastHitAtPlr[plr]=tick()
    if not self:_shouldNotify(plr) then return end
    self:_enqueueResolve(plr,hum,bodyPart)
end
function HitNotify:NotifyManual(targetName,damage,bodyPart)
    if not self.Enabled then return end
    self:_send(targetName,damage,bodyPart or "Body")
end
function HitNotify:_bindPlayer(plr)
    if plr==LocalPlayer then return end
    if self.charConn[plr] then self.charConn[plr]:Disconnect() end
    self.charConn[plr]=plr.CharacterAdded:Connect(function(char)
        self:_bindCharacter(plr,char)
    end)
    if plr.Character then self:_bindCharacter(plr,plr.Character) end
end
function HitNotify:_unbindPlayer(plr)
    if self.humConn[plr]  then self.humConn[plr]:Disconnect(); self.humConn[plr]=nil end
    if self.charConn[plr] then self.charConn[plr]:Disconnect(); self.charConn[plr]=nil end
    self.hpTrack[plr]=nil; self.resolveQueues[plr]=nil; self.resolveBusy[plr]=nil
end
function HitNotify:_bindCharacter(plr,char)
    if plr==LocalPlayer or not char then return end
    if self.humConn[plr] then self.humConn[plr]:Disconnect(); self.humConn[plr]=nil end
    local hum=char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",8)
    if not hum then return end
    self.hpTrack[plr]=hum.Health
    self.humConn[plr]=hum.HealthChanged:Connect(function(newHp)
        local last=self.hpTrack[plr]
        if last==nil then self.hpTrack[plr]=newHp; return end
        if newHp<last-0.01 then
            if self:_shouldNotify(plr) then
                local part=self.hitPartByPlr[plr] or "Body"
                self:_send(plr.Name,last-newHp,part)
                self.lastHitAtPlr[plr]=tick()
            end
            self.hpTrack[plr]=newHp
        elseif newHp>last then
            self.hpTrack[plr]=newHp
        end
    end)
end
function HitNotify:_shouldNotify(plr)
    if not self.Enabled or plr==LocalPlayer then return false end
    if self.filter then
        local ok,res=pcall(self.filter,plr)
        if ok and res==false then return false end
    end
    local win1=self.config.shotCreditWindow or 4
    if tick()-self.combatLastShotAt<win1 then return true end
    local win2=self.config.hitCreditWindow or 4
    local last=self.lastHitAtPlr[plr]
    if last~=nil and tick()-last<win2 then return true end
    return false
end
function HitNotify:_playerFromHitPart(hitPart)
    if not hitPart then return nil,nil,nil end
    local char=hitPart:FindFirstAncestorOfClass("Model")
    if not char and hitPart.Parent and hitPart.Parent:IsA("Model") then char=hitPart.Parent end
    if not char then return nil,nil,nil end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local plr=Players:GetPlayerFromCharacter(char)
    return plr,hum,hitPart.Name
end
function HitNotify:_send(name,dmg,part)
    local text
    if self.formatter then
        local ok,res=pcall(self.formatter,name,dmg,part)
        if ok and type(res)=="string" and res~="" then text=res end
    end
    if not text then
        text=string.format("hit %s for %d in the %s",name,math.floor(dmg+0.5),part or "Body")
    end
    pcall(function() self.library:Notify(text) end)
end
function HitNotify:_tryClaim(plr,hum,part,allowFallback)
    if not hum or not hum.Parent then return false end
    local last=self.hpTrack[plr]
    if last==nil then last=hum.Health; self.hpTrack[plr]=last end
    local cur=hum.Health; local dmg=last-cur
    if dmg>=0.01 then
        self:_send(plr.Name,dmg,part or self.hitPartByPlr[plr] or "Body")
        self.hpTrack[plr]=cur; self.lastHitAtPlr[plr]=tick(); return true
    end
    if allowFallback then
        self:_send(plr.Name,1,part or self.hitPartByPlr[plr] or "Body")
        self.lastHitAtPlr[plr]=tick(); return true
    end
    return false
end
function HitNotify:_resolveJob(plr,job)
    local hum,part=job.hum,job.bodyPart
    if not hum or not hum.Parent then return end
    if self:_tryClaim(plr,hum,part,false) then return end
    for _ = 1,15 do task.wait(0); if self:_tryClaim(plr,hum,part,false) then return end end
    for _ = 1,8  do task.wait(0.03); if self:_tryClaim(plr,hum,part,false) then return end end
    self:_tryClaim(plr,hum,part,true)
end
function HitNotify:_enqueueResolve(plr,hum,part)
    self.resolveQueues[plr]=self.resolveQueues[plr] or {}
    table.insert(self.resolveQueues[plr],{hum=hum,bodyPart=part,queuedAt=tick()})
    if self.resolveBusy[plr] then return end
    self.resolveBusy[plr]=true
    task.spawn(function()
        while self.resolveQueues[plr] and #self.resolveQueues[plr]>0 do
            local job=table.remove(self.resolveQueues[plr],1)
            self:_resolveJob(plr,job)
        end
        self.resolveBusy[plr]=false
    end)
end
function HitNotify:Destroy()
    if self._playerAddedConn    then self._playerAddedConn:Disconnect()    end
    if self._playerRemovingConn then self._playerRemovingConn:Disconnect() end
    for plr in pairs(self.humConn) do self:_unbindPlayer(plr) end
end

local HN    = HitNotify.new(Library)
HN.Enabled  = false
getgenv().HitNotifyInstance = HN
HN:SetFormatter(function(name,dmg,part)
    return string.format("hit %s for %d", name, math.floor(dmg+0.5))
end)

-- ── HitEffect ───────────────────────────────────────────────
local HitEffect = {}
HitEffect.__index = HitEffect

local DEFAULT_HIT_EFFECT_CONFIG = {
    enabled=false, color=Color3.fromRGB(255,80,80), outlineColor=Color3.fromRGB(0,0,0),
    font=Enum.Font.GothamBold, textSize=24, lifetime=0.8, riseDistance=3, spread=0.5,
}

function HitEffect.new(config)
    local self=setmetatable({},HitEffect)
    self.config={}
    for k,v in pairs(DEFAULT_HIT_EFFECT_CONFIG) do self.config[k]=v end
    for k,v in pairs(config or {}) do self.config[k]=v end
    self.active={}; return self
end
function HitEffect:SetColor(color)         self.config.color=color end
function HitEffect:SetOutlineColor(color)  self.config.outlineColor=color end
function HitEffect:SetFont(font)           self.config.font=font end
function HitEffect:SetTextSize(size)       self.config.textSize=size end
function HitEffect:SetLifetime(t)          self.config.lifetime=t end
function HitEffect:SetRiseDistance(d)      self.config.riseDistance=d end
function HitEffect:SetEnabled(v)           self.config.enabled=v end
function HitEffect:_spawn(worldPosition,amount)
    if not worldPosition then return end
    if not self.config.enabled then return end
    local anchor=Instance.new("Part")
    anchor.Name="HitEffect_Anchor"; anchor.Anchored=true; anchor.CanCollide=false
    anchor.CanQuery=false; anchor.CanTouch=false; anchor.Transparency=1
    anchor.Size=Vector3.new(0.1,0.1,0.1); anchor.CFrame=CFrame.new(worldPosition)
    anchor.Parent=workspace
    local billboard=Instance.new("BillboardGui")
    billboard.Name="HitEffect_DamageNumber"; billboard.Adornee=anchor
    billboard.Size=UDim2.new(0,120,0,40)
    billboard.StudsOffsetWorldSpace=Vector3.new((math.random()-0.5)*self.config.spread,math.random(0,1)*0.5,(math.random()-0.5)*self.config.spread)
    billboard.AlwaysOnTop=true; billboard.LightInfluence=0; billboard.MaxDistance=500
    billboard.Parent=anchor
    local label=Instance.new("TextLabel")
    label.Name="DamageLabel"; label.BackgroundTransparency=1
    label.Size=UDim2.new(1,0,1,0); label.Font=self.config.font
    label.Text=tostring(math.floor(amount+0.5))
    label.TextColor3=self.config.color; label.TextStrokeColor3=self.config.outlineColor
    label.TextStrokeTransparency=0; label.TextScaled=false; label.TextSize=self.config.textSize
    label.TextWrapped=false; label.Parent=billboard
    local startOffset=billboard.StudsOffsetWorldSpace
    local endOffset=startOffset+Vector3.new(0,self.config.riseDistance,0)
    local lifetime=self.config.lifetime
    TweenService:Create(billboard,TweenInfo.new(lifetime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{StudsOffsetWorldSpace=endOffset}):Play()
    TweenService:Create(label,TweenInfo.new(lifetime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    TweenService:Create(label,TweenInfo.new(lifetime*0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextSize=self.config.textSize*1.25}):Play()
    table.insert(self.active,anchor)
    task.delay(lifetime,function()
        if anchor and anchor.Parent then anchor:Destroy() end
        for i,v in ipairs(self.active) do if v==anchor then table.remove(self.active,i); break end end
    end)
end
function HitEffect:ShowOnPlayer(plr,amount,bodyPart)
    if not self.config.enabled then return end
    if not plr or not plr.Character then return end
    local char=plr.Character; local targetPart=nil
    if bodyPart and bodyPart~="Body" and char:FindFirstChild(bodyPart) then
        targetPart=char:FindFirstChild(bodyPart)
    end
    if not targetPart then
        targetPart=char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    if targetPart then self:_spawn(targetPart.Position,amount) end
end
function HitEffect:ClearAll()
    for _,gui in ipairs(self.active) do if gui and gui.Parent then gui:Destroy() end end
    self.active={}
end

local HE = HitEffect.new()
getgenv().HitEffectInstance = HE

local originalSend = HN._send
HN._send = function(self,name,dmg,part)
    originalSend(self,name,dmg,part)
    local plr=Players:FindFirstChild(name)
    if plr then HE:ShowOnPlayer(plr,dmg,part) end
end

-- Bullet Tracer hook
local ok2,err2=pcall(function()
    local EnumLibrary=require(ReplicatedStorage.Modules.EnumLibrary)
    local startShootEnum=EnumLibrary:ToEnum("StartShooting")
    local oldFireServer
    oldFireServer=hookfunction(
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem.FireServer,
        newcclosure(function(self,objID,enumVal,camdata,extra)
            if enumVal==startShootEnum then
                if HN then HN:MarkShot() end
                if getgenv().BulletTracersEnabled and isGunEquipped() then
                    local origin=getViewmodelMuzzle()
                    if origin then
                        local endPos=getTracerEndPos(origin)
                        if endPos then
                            FireBulletTracers(origin,endPos,getgenv().BulletTracersLifetime,getgenv().BulletTracersColor)
                        end
                    end
                end
            end
            return oldFireServer(self,objID,enumVal,camdata,extra)
        end)
    )
end)
if not ok2 then warn("BulletTracer hook error: "..tostring(err2)) end

getgenv().FireBulletTracers = FireBulletTracers
getgenv().GetRageTracerOrigin = function()
    local m=getViewmodelMuzzle(); if m then return m end
    local rb=getgenv().ragebot
    if rb and rb.config and rb.config.orbit and rb.config.orbit.serverpos then
        return rb.config.orbit.serverpos
    end
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    return hrp and (hrp.Position+Vector3.new(0,2,0)) or nil
end
getgenv().GetRageTracerEnd = function(origin)
    local rb=getgenv().ragebot
    if rb and rb.config and rb.config.target and rb.config.target.character then
        local head=rb.config.target.character:FindFirstChild("Head")
        if head then return head.Position end
    end
    local cam=workspace.CurrentCamera
    return cam and (cam.CFrame.Position+cam.CFrame.LookVector*1000) or nil
end

-- ── Hit Sounds setup ────────────────────────────────────────
local Sounds = {
    ["Neverlose"]      = "https://www.myinstants.com/media/sounds/neverlose-s.mp3",
    ["Star"]           = "https://www.myinstants.com/media/sounds/starshitsound.mp3",
    ["Rust"]           = "rbxassetid://4764109000",
    ["Minecraft XP"]   = "rbxassetid://6647877129",
    ["Minecraft Hit"]  = "rbxassetid://8766809464",
    ["Windows Error"]  = "rbxassetid://9066167010",
    ["pan"]            = "rbxassetid://7109756845",
    ["slap"]           = "rbxassetid://8907573127",
    ["oof"]            = "rbxassetid://79348298352567",
    ["quack"]          = "rbxassetid://2101511513",
    ["get out"]        = "rbxassetid://17573042535",
    ["E"]              = "rbxassetid://2168246346",
    ["Bonk"]           = "rbxassetid://130944130",
    ["Undertale slash"]= "rbxassetid://623904185",
}
local SOUND_FOLDER = "Onyx_sounds"
local SOUND_DIR    = SOUND_FOLDER.."/sounds"
local function isExternal(id) return type(id)=="string" and id:match("^https?://")~=nil end
local function safeFileName(name) return (name:gsub("[^%w%-_ ]",""):gsub("%s+","_"))..".mp3" end
if isfolder and makefolder then
    if not isfolder(SOUND_FOLDER) then makefolder(SOUND_FOLDER) end
    if not isfolder(SOUND_DIR)    then makefolder(SOUND_DIR)    end
end
local assetCache = {}
local function resolveSoundId(name)
    local raw=Sounds[name]; if not raw then return nil end
    if not isExternal(raw) then return raw end
    if assetCache[name] then return assetCache[name] end
    if not (isfile and writefile and (getsynasset or getcustomasset)) then return nil end
    local path=SOUND_DIR.."/"..safeFileName(name)
    if not isfile(path) then
        local ok,data=pcall(function() return game:HttpGet(raw,true) end)
        if not ok or type(data)~="string" or #data<128 then return nil end
        writefile(path,data)
    end
    local assetFn=getsynasset or getcustomasset
    local ok2,asset=pcall(assetFn,path)
    if not ok2 or not asset then return nil end
    assetCache[name]=asset; return asset
end
task.spawn(function()
    for name,id in pairs(Sounds) do
        if isExternal(id) then pcall(resolveSoundId,name); task.wait(0.4) end
    end
end)
local soundNames={}
for name in pairs(Sounds) do table.insert(soundNames,name) end
table.sort(soundNames)
local soundtochange="Rust"

getgenv().Volume             = getgenv().Volume             or 5
getgenv().HitSoundActive     = getgenv().HitSoundActive     or false
getgenv().HitSoundConnection = getgenv().HitSoundConnection or nil

-- ── Other Spoof helpers ──────────────────────────────────────
local Players_L = game:GetService("Players")
local OriginalNames = {}
local function SaveOriginalNames()
    for _,player in ipairs(Players_L:GetPlayers()) do
        if player~=Players_L.LocalPlayer then
            if not OriginalNames[player.Name] then
                OriginalNames[player.Name]={Name=player.Name,DisplayName=player.DisplayName}
            end
        end
    end
end
SaveOriginalNames()
Players_L.PlayerAdded:Connect(function(player)
    if player~=Players_L.LocalPlayer then
        OriginalNames[player.Name]={Name=player.Name,DisplayName=player.DisplayName}
    end
end)

local OriginalLevels = {}

-- AutoBan/AutoPick weapon value stores
local AutoBanWeapon1Val  = "Fists"
local AutoBanWeapon2Val  = "Riot Shield"
local AutoPickWeapon1Val = "Assault Rifle"
local AutoPickWeapon2Val = "Handgun"
local AutoPickWeapon3Val = "Fists"
local AutoPickWeapon4Val = "Grenade"
local AutoBanWeaponConnection  = nil
local AutoPickWeaponConnection = nil
local hasVoted = false
local hasPicked = false

-- Name spoof helpers
local NameToSpoof     = "discord.gg/Ukvunvy2UQ"
local OldName         = LocalPlayer.Name
local OldDisplayName  = LocalPlayer.DisplayName
getgenv().NameSpoofActive  = getgenv().NameSpoofActive  or false
getgenv().WinStreakActive   = getgenv().WinStreakActive  or false
getgenv().LevelActive       = getgenv().LevelActive     or false
getgenv().WinStreak         = getgenv().WinStreak       or 0
getgenv().Level             = getgenv().Level           or 0
getgenv().ChooseDevice      = getgenv().ChooseDevice    or ""
getgenv().DeviceSpoofActive = getgenv().DeviceSpoofActive or false
getgenv().OtherNameToSpoof  = getgenv().OtherNameToSpoof  or "Hacker"
getgenv().OtherNameSpoofActive = getgenv().OtherNameSpoofActive or false
getgenv().OtherLevel        = getgenv().OtherLevel      or 0
getgenv().OtherLevelActive  = getgenv().OtherLevelActive or false
getgenv().OtherWins         = getgenv().OtherWins       or 0
getgenv().OtherWinsActive   = getgenv().OtherWinsActive or false
getgenv()._OrigWinStreak    = nil
getgenv()._OrigLevel        = nil

local deviceSpoofs = {Computer="MouseKeyboard",Mobile="Touch",Console="Gamepad",VR="VR"}
local function spoofDevice(deviceType)
    local targetDevice=deviceSpoofs[deviceType]
    if targetDevice then
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
            :WaitForChild("Replication"):WaitForChild("Fighter")
            :WaitForChild("SetControls"):FireServer(targetDevice)
    end
end

-- ============================================================
-- BitchBot menu.Initialize — Full Onyx Premium Menutable
-- ============================================================
local weaponList = {"Assault Rifle","Distortion","Permafrost","Energy Rifle","Flamethrower","Grenade Launcher","Minigun","Paintball Gun","Bow","Burst Rifle","Crossbow","Gunblade","RPG","Shotgun","Sniper","Wildcat","Handgun","Energy Pistols","Exogun","Slingshot","Daggers","Flare Gun","Revolver","Shorty","Spray","Uzi","Fists","Katana","Knife","Chainsaw","Riot Shield","Scythe","Maul","Spear","Trowel","Battle Axe","Grenade","Freeze Ray","Flashbang","Jump Pad","Molotov","Satchel","Smoke Grenade","War Horn","Grappler","Medkit","Subspace Tripmine","Warpstone"}

local rbCfg = (ragebot and ragebot.config) or {}

menu.Initialize({
    -- ════════════════════════════════════════════
    { name = "Main",
      content = {
        -- ── Aimbot ──────────────────────────────
        { name = "Aimbot", autopos = "left",
          content = {
            { type="toggle", name="Aimbot Enabled", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().Aimbot.Enabled=v end },
            { type="toggle", name="Sticky Aim", value=false,
              callback=function(v) getgenv().Aimbot.PersistTarget=v end },
            { type="dropbox", name="Aim Part", value=1,
              values={"head","humanoidrootpart"},
              callback=function(v) getgenv().Aimbot.AimPart=v end },
            { type="slider", name="Sensitivity", value=15, minvalue=1, maxvalue=100,
              callback=function(v) getgenv().Aimbot.Sensitivity=v end },
            { type="slider", name="Dead Zone", value=5, minvalue=0, maxvalue=100,
              callback=function(v) getgenv().Aimbot.Deadzone=v end },
            { type="slider", name="Prediction", value=12, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().Aimbot.Prediction=v/100 end },
            -- FOV
            { type="toggle", name="Show FOV", value=true,
              callback=function(v) getgenv().Aimbot.FovShow=v end },
            { type="slider", name="FOV Size", value=150, minvalue=1, maxvalue=999,
              callback=function(v) getgenv().Aimbot.AimRadius=v end },
            { type="toggle", name="FOV Outline", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Outline Color"},
              callback=function(v) getgenv().Aimbot.FovOutlineShow=v end },
            { type="slider", name="Outline Trans", value=40, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().Aimbot.FovOutlineTransparency=v/100 end },
            { type="slider", name="Outline Thickness", value=15, minvalue=5, maxvalue=50, stradd="px",
              callback=function(v) getgenv().Aimbot.FovOutlineThickness=v/10 end },
            { type="toggle", name="FOV Filled", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Fill Color"},
              callback=function(v) getgenv().Aimbot.FovFilled=v end },
            { type="slider", name="Fill Trans", value=15, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().Aimbot.FovBackgroundTransparency=v/100 end },
          }
        },
        -- ── TriggerBot ──────────────────────────
        { name = "Trigger Bot", autopos = "right",
          content = {
            { type="toggle", name="TB Enabled", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().TriggerBot.Enabled=v end },
            { type="combobox", name="Body Blacklist",
              values={{"head",false},{"uppertorso",false},{"lowertorso",false},
                      {"leftupperarm",false},{"leftlowerarm",false},
                      {"rightupperarm",false},{"rightlowerarm",false},
                      {"leftupperleg",false},{"leftlowerleg",false},
                      {"rightupperleg",false},{"rightlowerleg",false}},
            },
          }
        },
        -- ── Silent Aim ──────────────────────────
        { name = "Silent Aim", autopos = "left",
          content = {
            { type="toggle", name="SA Enabled", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().SilentAim.Enabled=v end },
            { type="toggle", name="Auto Shoot", value=false,
              callback=function(v) getgenv().SilentAim.AutoShoot=v end },
            { type="dropbox", name="SA Aim Part", value=1,
              values={"head","humanoidrootpart","uppertorso","lowertorso","torso"},
              callback=function(v) getgenv().SilentAim.AimPart=v end },
            { type="dropbox", name="SA Method", value=1,
              values={"fov","distance"},
              callback=function(v) getgenv().SilentAim.Method=v end },
            { type="slider", name="SA FOV Size", value=150, minvalue=1, maxvalue=999,
              callback=function(v) getgenv().SilentAim.FOV=v end },
            { type="toggle", name="SA Show FOV", value=false,
              callback=function(v) getgenv().SilentAim.ShowFOV=v end },
            { type="toggle", name="SA FOV Outline", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Outline Color"},
              callback=function(v) getgenv().SilentAim.FovOutlineShow=v end },
            { type="slider", name="SA Outline Trans", value=40, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().SilentAim.FovOutlineTransparency=v/100 end },
            { type="slider", name="SA Outline Thick", value=15, minvalue=5, maxvalue=50, stradd="px",
              callback=function(v) getgenv().SilentAim.FovOutlineThickness=v/10 end },
            { type="toggle", name="SA FOV Filled", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Fill Color"},
              callback=function(v) getgenv().SilentAim.FovFilled=v end },
            { type="slider", name="SA Fill Trans", value=15, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().SilentAim.FovBackgroundTransparency=v/100 end },
          }
        },
        -- ── Ragebot ─────────────────────────────
        { name = "Ragebot", autopos = "right",
          content = {
            { type="toggle", name="RB Enabled", value=rbCfg.target.rageMasterOn,
              extra={type="keybind"},
              callback=function(v)
                rbCfg.target.rageMasterOn=v; rbCfg.target.auto=v
              end },
            { type="toggle", name="Autoshoot", value=rbCfg.target.autoshoot,
              callback=function(v) rbCfg.target.autoshoot=v end },
            { type="toggle", name="Force Weapon", value=rbCfg.target.forceWeapon,
              callback=function(v)
                rbCfg.target.forceWeapon=v
                if v and ragebot.eqSlot then ragebot.eqSlot() end
              end },
            { type="dropbox", name="Weapon Slot", value=1,
              values={"primary","secondary","melee"},
              callback=function(v)
                rbCfg.target.weaponPick=v
                if rbCfg.target.forceWeapon and ragebot.eqSlot then ragebot.eqSlot() end
                if ragebot.refreshAtk then ragebot.refreshAtk() end
              end },
            { type="dropbox", name="Hit Part", value=1,
              values={"head","humanoidrootpart","torso","uppertorso","closest","random"},
              callback=function(v) rbCfg.target.hitpart=v end },
            { type="slider", name="Shoot Attempts", value=1, minvalue=1, maxvalue=3, stradd="x",
              callback=function(v) rbCfg.target.shootAttempts=math.clamp(math.floor(v),1,3) end },
            { type="toggle", name="Prediction", value=rbCfg.prediction.enabled,
              callback=function(v) rbCfg.prediction.enabled=v end },
            { type="slider", name="Pred Mult", value=12, minvalue=1, maxvalue=30, stradd="x",
              callback=function(v) rbCfg.prediction.multiplier=v/10 end },
            { type="dropbox", name="Attack Pos", value=1,
              values={"default","under"},
              callback=function(v)
                rbCfg.target.attackPosition=v
                if ragebot.refreshAtk then ragebot.refreshAtk() end
              end },
            { type="toggle", name="Custom Offset", value=rbCfg.target.attackCustomEnabled,
              callback=function(v)
                rbCfg.target.attackCustomEnabled=v
                if ragebot.refreshAtk then ragebot.refreshAtk() end
              end },
            { type="slider", name="Custom Front", value=0, minvalue=-20, maxvalue=20, decimal=0.1,
              callback=function(v) rbCfg.target.customFront=v end },
            { type="slider", name="Custom Side", value=0, minvalue=-20, maxvalue=20, decimal=0.1,
              callback=function(v) rbCfg.target.customSide=v end },
            { type="slider", name="Custom Vertical", value=0, minvalue=-20, maxvalue=20, decimal=0.1,
              callback=function(v) rbCfg.target.customVertical=v end },
            { type="slider", name="Custom Radius", value=0, minvalue=0, maxvalue=20, decimal=0.1,
              callback=function(v) rbCfg.target.customRadius=v end },
          }
        },
        -- ── Ragebot Misc ────────────────────────
        { name = "Rage Misc", autopos = "left",
          content = {
            { type="toggle", name="Orbit", value=false,
              callback=function(v) rbCfg.orbit.active=v end },
            { type="slider", name="Orbit Radius", value=0, minvalue=0, maxvalue=30,
              callback=function(v) rbCfg.orbit.radius=v end },
            { type="slider", name="Orbit Speed", value=9000, minvalue=1, maxvalue=9000,
              callback=function(v) rbCfg.orbit.speed=v end },
            { type="slider", name="Orbit Height", value=1, minvalue=-20, maxvalue=20,
              callback=function(v) rbCfg.orbit.height=v end },
            { type="toggle", name="Void Spam", value=false,
              callback=function(v)
                rbCfg.voidspam.enabled=v
                if v then
                    if rbCfg.target.immune then rbCfg.voidspam.phase=nil; return end
                    rbCfg.voidspam.lastswitch=tick(); rbCfg.voidspam.phase="shoot"
                    rbCfg.voidspam.currentduration=randVs(rbCfg.voidspam.shoot_min,rbCfg.voidspam.shoot_max)
                else rbCfg.voidspam.phase=nil end
              end },
            { type="slider", name="Attack Time", value=10, minvalue=1, maxvalue=20, decimal=0.1, stradd="s",
              callback=function(v) rbCfg.voidspam.shoot_min=v; rbCfg.voidspam.shoot_max=v end },
            { type="slider", name="Hide Time", value=10, minvalue=1, maxvalue=20, decimal=0.1, stradd="s",
              callback=function(v) rbCfg.voidspam.hide_min=v; rbCfg.voidspam.hide_max=v end },
          }
        },
        -- ── Rage Status ─────────────────────────
        { name = "Rage Status", autopos = "right",
          content = {
            { type="toggle", name="Rage Status", value=false,
              callback=function(v) rbCfg.ragestatus.enabled=v end },
            { type="dropbox", name="Status Mode", value=1,
              values={"static","dynamic","follow"},
              callback=function(v) rbCfg.ragestatus.mode=v end },
            { type="toggle", name="Status Color", value=false,
              extra={type="single colorpicker", color={255,80,80}, name="Color"} },
            { type="slider", name="Status Offset X", value=0, minvalue=-500, maxvalue=500,
              callback=function(v) rbCfg.ragestatus.staticOffsetX=v end },
            { type="slider", name="Status Offset Y", value=40, minvalue=-500, maxvalue=500,
              callback=function(v) rbCfg.ragestatus.staticOffsetY=v end },
            { type="toggle", name="Show Ammo", value=false,
              callback=function(v) rbCfg.ragestatus.showAmmo=v end },
            { type="toggle", name="Hide on Reload", value=false,
              callback=function(v) rbCfg.ragestatus.hideOnReload=v end },
            { type="slider", name="Text Size", value=15, minvalue=8, maxvalue=30,
              callback=function(v) rbCfg.ragestatus.textSize=v end },
            { type="slider", name="Line Gap", value=15, minvalue=0, maxvalue=50,
              callback=function(v) rbCfg.ragestatus.lineGap=v end },
            { type="dropbox", name="Status Font", value=1,
              values={"gotham","gothammedium","gothambold","arial","arialbold","code"},
              callback=function(v) rbCfg.ragestatus.fontName=v end },
          }
        },
        -- ── Weapon ──────────────────────────────
        { name = "Weapon", autopos = "left",
          content = {
            { type="toggle", name="No Cooldown", value=false,
              callback=function(v)
                getgenv().GunSystem.CooldownEnabled=v; getgenv().GunSystem.Cooldown=0.0
                if getgenv().UpdateGunStats then getgenv().UpdateGunStats() end
              end },
            { type="toggle", name="No Spread", value=false,
              callback=function(v)
                getgenv().GunSystem.SpreadEnabled=v; getgenv().GunSystem.Spread=0.0
                if getgenv().UpdateGunStats then getgenv().UpdateGunStats() end
              end },
            { type="toggle", name="No Recoil", value=false,
              callback=function(v)
                getgenv().GunSystem.RecoilEnabled=v; getgenv().GunSystem.Recoil=0.0
                if getgenv().UpdateGunStats then getgenv().UpdateGunStats() end
              end },
            { type="toggle", name="No Melee CD", value=false,
              callback=function(v)
                getgenv().ItemCooldownSystem.MeleeCooldown.Enabled=v
                getgenv().ItemCooldownSystem.MeleeCooldown.Percentage=0.0
                getgenv().ItemCooldownSystem.Refresh()
              end },
            { type="toggle", name="No Dash CD", value=false,
              callback=function(v)
                getgenv().ItemCooldownSystem.DashCooldown.Enabled=v
                getgenv().ItemCooldownSystem.DashCooldown.Percentage=0.0
                getgenv().ItemCooldownSystem.Refresh()
              end },
            { type="toggle", name="Instant Aim", value=false,
              callback=function(v)
                local ICS=getgenv().ItemCooldownSystem
                if ICS and ICS.AimingSystem then ICS.AimingSystem.Enabled=v end
                if getgenv().UpdateGunStats then getgenv().UpdateGunStats() end
              end },
            { type="toggle", name="Auto Weapon", value=false,
              callback=function(v)
                getgenv().ItemCooldownSystem.AutomaticWeapon.Enabled=v
                getgenv().ItemCooldownSystem.Refresh()
              end },
            { type="toggle", name="Inf Double Jump", value=false,
              callback=function(v)
                getgenv().ItemCooldownSystem.MaxDoubleJumps.Enabled=v
                getgenv().ItemCooldownSystem.MaxDoubleJumps.Count=676767
                getgenv().ItemCooldownSystem.Refresh()
              end },
          }
        },
        -- ── Targeting ───────────────────────────
        { name = "Targeting", autopos = "right",
          content = {
            { type="toggle", name="Visible Only", value=false,
              callback=function(v)
                getgenv().Aimbot.WallCheck=v; getgenv().SilentAim.WallCheck=v
              end },
          }
        },
      }
    },
    -- ════════════════════════════════════════════
    { name = "ESP",
      content = {
        -- ── Player ESP ──────────────────────────
        { name = "Player ESP", autopos = "left",
          content = {
            { type="toggle", name="ESP Enabled", value=false,
              callback=function(v) getgenv().ESP.Enabled=v end },
            { type="toggle", name="Gradient", value=false,
              extra={type="double colorpicker", color={{255,0,0},{0,0,255}}, name={"Color A","Color B"}},
              callback=function(v) getgenv().ESP.Gradient=v end },
            { type="slider", name="Gradient Speed", value=1, minvalue=1, maxvalue=20,
              callback=function(v) getgenv().ESP.GradientSpeed=v end },
            { type="toggle", name="Static Color", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Color"},
              callback=function(v)
                -- color is read in sync loop
              end },
            { type="slider", name="Transparency", value=0, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().ESP.Transparency=v/100 end },
            { type="slider", name="Box Fill Trans", value=80, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().ESP.BoxFillTransparency=v/100 end },
            { type="toggle", name="Box", value=false,
              callback=function(v) getgenv().ESP.Box=v end },
            { type="toggle", name="Box Filled", value=false,
              callback=function(v) getgenv().ESP.BoxFilled=v end },
            { type="toggle", name="Highlight", value=false,
              callback=function(v) getgenv().ESP.Highlight=v end },
            { type="toggle", name="Health Bar", value=false,
              callback=function(v) getgenv().ESP.Health=v end },
            { type="toggle", name="Name", value=false,
              callback=function(v) getgenv().ESP.Name=v end },
            { type="toggle", name="Weapon", value=false,
              callback=function(v) getgenv().ESP.Tool=v end },
            { type="toggle", name="Tracer", value=false,
              callback=function(v) getgenv().ESP.Tracer=v end },
            { type="toggle", name="Skeleton", value=false,
              callback=function(v) getgenv().ESP.Skeleton=v end },
            { type="toggle", name="Team Check", value=false,
              callback=function(v) getgenv().ESP.TeamCheck=v end },
          }
        },
        -- ── Item ESP ────────────────────────────
        { name = "Item ESP", autopos = "right",
          content = {
            { type="toggle", name="Item Highlight", value=false,
              callback=function(v) getgenv().ItemESP.Highlight=v end },
            { type="toggle", name="Item Name", value=false,
              callback=function(v) getgenv().ItemESP.Name=v end },
            { type="toggle", name="Slingshot", value=false,
              callback=function(v) if TrackNames and TrackNames["Slingshot"] then TrackNames["Slingshot"].Enabled=v end end },
            { type="toggle", name="Daggers", value=false,
              callback=function(v) if TrackNames and TrackNames["Daggers"] then TrackNames["Daggers"].Enabled=v end end },
            { type="toggle", name="Paintball Gun", value=false,
              callback=function(v) if TrackNames and TrackNames["Paintball Gun"] then TrackNames["Paintball Gun"].Enabled=v end end },
            { type="toggle", name="Grenade Launcher", value=false,
              callback=function(v) if TrackNames and TrackNames["Grenade Launcher"] then TrackNames["Grenade Launcher"].Enabled=v end end },
            { type="toggle", name="Flare Gun", value=false,
              callback=function(v) if TrackNames and TrackNames["Flare Gun"] then TrackNames["Flare Gun"].Enabled=v end end },
            { type="toggle", name="Molotov", value=false,
              callback=function(v) if TrackNames and TrackNames["Molotov"] then TrackNames["Molotov"].Enabled=v end end },
            { type="toggle", name="Freeze Ray", value=false,
              callback=function(v) if TrackNames and TrackNames["Freeze Ray"] then TrackNames["Freeze Ray"].Enabled=v end end },
            { type="toggle", name="Flashbang", value=false,
              callback=function(v) if TrackNames and TrackNames["Flashbang"] then TrackNames["Flashbang"].Enabled=v end end },
            { type="toggle", name="Warpstone", value=false,
              callback=function(v) if TrackNames and TrackNames["Warpstone"] then TrackNames["Warpstone"].Enabled=v end end },
            { type="toggle", name="Satchel", value=false,
              callback=function(v) if TrackNames and TrackNames["Satchel"] then TrackNames["Satchel"].Enabled=v end end },
            { type="toggle", name="Smoke Grenade", value=false,
              callback=function(v) if TrackNames and TrackNames["Smoke Grenade"] then TrackNames["Smoke Grenade"].Enabled=v end end },
            { type="toggle", name="Grenade", value=false,
              callback=function(v) if TrackNames and TrackNames["Grenade"] then TrackNames["Grenade"].Enabled=v end end },
            { type="toggle", name="Bow", value=false,
              callback=function(v) if TrackNames and TrackNames["Bow"] then TrackNames["Bow"].Enabled=v end end },
            { type="toggle", name="RPG", value=false,
              callback=function(v) if TrackNames and TrackNames["RPG"] then TrackNames["RPG"].Enabled=v end end },
          }
        },
      }
    },
    -- ════════════════════════════════════════════
    { name = "World",
      content = {
        -- ── Custom Fog ──────────────────────────
        { name = "Custom Fog", autopos = "left",
          content = {
            { type="toggle", name="Fog Enabled", value=false,
              callback=function(v) getgenv().CustomFog.Enabled=v end },
            { type="slider", name="Fog Start", value=0, minvalue=0, maxvalue=1000,
              callback=function(v) getgenv().CustomFog.Start=v end },
            { type="slider", name="Fog End", value=1000, minvalue=0, maxvalue=10000,
              callback=function(v) getgenv().CustomFog.End=v end },
            { type="slider", name="Fog Density", value=0, minvalue=0, maxvalue=100, stradd="%",
              callback=function(v) getgenv().CustomFog.Density=v/100 end },
            { type="toggle", name="Fog Color", value=false,
              extra={type="single colorpicker", color={200,200,200}, name="Color"} },
          }
        },
        -- ── Shaders ─────────────────────────────
        { name = "Shaders", autopos = "right",
          content = {
            { type="toggle", name="DOF", value=false,
              callback=function(v) Effects.DOF=v end },
            { type="toggle", name="Bloom", value=false,
              callback=function(v) Effects.Bloom=v end },
            { type="toggle", name="Color Correction", value=false,
              callback=function(v) Effects.ColorCorrection=v end },
            { type="toggle", name="Atmosphere", value=false,
              callback=function(v) Effects.Atmosphere=v end },
            { type="toggle", name="Sun Rays", value=false,
              callback=function(v) Effects.SunRays=v end },
            { type="toggle", name="Dynamic Exposure", value=false,
              callback=function(v) Effects.DynamicExposure=v end },
            { type="toggle", name="Specular Boost", value=false,
              callback=function(v) Effects.SpecularBoost=v end },
          }
        },
        -- ── Weather ─────────────────────────────
        { name = "Weather", autopos = "left",
          content = {
            { type="toggle", name="Weather Enabled", value=false,
              callback=function(v) getgenv().Weather.Enabled=v end },
            { type="dropbox", name="Weather Type", value=1,
              values={"sunny","rain","heavy rain","night","snow"},
              callback=function(v) getgenv().Weather.Type=v end },
            { type="slider", name="Intensity", value=500, minvalue=1, maxvalue=1000,
              callback=function(v) getgenv().Weather.Intensity=v end },
            { type="slider", name="Speed", value=10, minvalue=2, maxvalue=30, decimal=0.1,
              callback=function(v) if Weather then Weather.Speed=v/10 end end },
            { type="slider", name="Size", value=10, minvalue=2, maxvalue=30, decimal=0.1,
              callback=function(v) if Weather then Weather.Size=v/10 end end },
            { type="slider", name="Spread", value=10, minvalue=0, maxvalue=30, decimal=0.1,
              callback=function(v) if Weather then Weather.Spread=v/10 end end },
            { type="slider", name="Glow", value=0, minvalue=0, maxvalue=10, decimal=0.1,
              callback=function(v) if Weather then Weather.Glow=v/10 end end },
            { type="toggle", name="Weather Color", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Color"} },
          }
        },
        -- ── Skybox ──────────────────────────────
        { name = "Skybox", autopos = "right",
          content = {
            { type="toggle", name="Skybox Enabled", value=false,
              callback=function(v) getgenv().Skybox.Enabled=v end },
            { type="dropbox", name="Skybox Type", value=1,
              values={"Afternoon","Blue Space","Classic Roblox","Cloudy","Dusk","Dawn","Dark Skies","Earth","Ethereal","Galaxy","Heaven","Horizontal Milky Way","Jungle","Mountains","Nebula","Night","Night Light","Ocean Sky","Pink Clouds","Red Dusk","Redshift","Saturn","SFOTH","Smoke","Solid Black","Space","Storm","Sunset","Underworld","Vertical Milky Way","White"},
              callback=function(v) getgenv().Skybox.Type=v end },
          }
        },
        -- ── Monitor Color ───────────────────────
        { name = "Monitor Color", autopos = "left",
          content = {
            { type="toggle", name="MC Enabled", value=false,
              extra={type="single colorpicker", color={110,90,235}, name="Filter"},
              callback=function(v) getgenv().EyeProtection.Enabled=v end },
            { type="slider", name="Brightness", value=0, minvalue=-100, maxvalue=100, decimal=0.01,
              callback=function(v) getgenv().EyeProtection.Brightness=v/100 end },
            { type="slider", name="Contrast", value=-10, minvalue=-100, maxvalue=100, decimal=0.01,
              callback=function(v) getgenv().EyeProtection.Contrast=v/100 end },
            { type="slider", name="Saturation", value=0, minvalue=-100, maxvalue=100, decimal=0.01,
              callback=function(v) getgenv().EyeProtection.Saturation=v/100 end },
          }
        },
        -- ── X-Ray ───────────────────────────────
        { name = "X-Ray", autopos = "right",
          content = {
            { type="toggle", name="Xray Enabled", value=false,
              callback=function(v) SetMapXray(v) end },
            { type="slider", name="Xray Trans", value=5, minvalue=0, maxvalue=10, decimal=0.1,
              callback=function(v)
                getgenv().ESP.XrayTransparency=v/10
                if getgenv().ESP.Xray then applyMapXray() end
              end },
          }
        },
      }
    },
    -- ════════════════════════════════════════════
    { name = "Visuals",
      content = {
        -- ── Anti ────────────────────────────────
        { name = "Anti", autopos = "left",
          content = {
            { type="toggle", name="Anti Flashbang", value=false,
              callback=function(v)
                local Misc=game:GetService("Players").LocalPlayer.PlayerScripts.Assets.Misc
                local Flash=Misc and (Misc:FindFirstChild("FlashbangEffect") or game:GetService("Lighting"):FindFirstChild("FlashbangEffect"))
                if Flash then Flash.Parent=v and game:GetService("Lighting") or Misc end
              end },
          }
        },
        -- ── Unlock ──────────────────────────────
        { name = "Unlock", autopos = "right",
          content = {
            { type="toggle", name="Skins", value=false,
              callback=function(v) getgenv().UnlockerSettings.Skin=v end },
            { type="toggle", name="Wraps", value=false,
              callback=function(v) getgenv().UnlockerSettings.Wrap=v end },
            { type="toggle", name="Charms", value=false,
              callback=function(v) getgenv().UnlockerSettings.Charm=v end },
            { type="toggle", name="Dances", value=false,
              callback=function(v) getgenv().UnlockerSettings.Dance=v end },
            { type="toggle", name="Emotes", value=false,
              callback=function(v) getgenv().UnlockerSettings.Emote=v end },
          }
        },
        -- ── Bullet Tracers ──────────────────────
        { name = "Bullet Tracers", autopos = "left",
          content = {
            { type="slider", name="Tracer Lifetime", value=10, minvalue=1, maxvalue=50, decimal=0.1,
              callback=function(v) getgenv().BulletTracersLifetime=v/10 end },
            { type="toggle", name="Tracers Enabled", value=false,
              extra={type="single colorpicker", color={255,255,255}, name="Color"},
              callback=function(v) getgenv().BulletTracersEnabled=v end },
          }
        },
        -- ── Notify Hit ──────────────────────────
        { name = "Notify Hit", autopos = "right",
          content = {
            { type="toggle", name="Notify Enabled", value=false,
              callback=function(v) HN.Enabled=v end },
          }
        },
        -- ── Hit Effect ──────────────────────────
        { name = "Hit Effect", autopos = "left",
          content = {
            { type="toggle", name="HE Enabled", value=false,
              extra={type="double colorpicker", color={{255,80,80},{0,0,0}}, name={"Damage","Outline"}},
              callback=function(v) HE:SetEnabled(v); if not v then HE:ClearAll() end end },
            { type="dropbox", name="HE Font", value=1,
              values={"GothamBold","Gotham","GothamBlack","Arial","ArialBold","SourceSansBold","SourceSans","Cartoon","Code"},
              callback=function(v)
                local ok,font=pcall(function() return Enum.Font[v] end)
                if ok and font then HE:SetFont(font) end
              end },
            { type="slider", name="HE Text Size", value=24, minvalue=10, maxvalue=60,
              callback=function(v) HE:SetTextSize(v) end },
            { type="slider", name="HE Lifetime", value=8, minvalue=2, maxvalue=30, decimal=0.1,
              callback=function(v) HE:SetLifetime(v/10) end },
            { type="slider", name="HE Rise Dist", value=30, minvalue=5, maxvalue=100, decimal=0.1,
              callback=function(v) HE:SetRiseDistance(v/10) end },
          }
        },
        -- ── Hit Sounds ──────────────────────────
        { name = "Hit Sounds", autopos = "right",
          content = {
            { type="dropbox", name="Hit Sound", value=1,
              values=soundNames,
              callback=function(v)
                soundtochange=v; getgenv().HitSound=resolveSoundId(v)
              end },
            { type="slider", name="Volume", value=5, minvalue=1, maxvalue=50,
              callback=function(v) getgenv().Volume=v end },
            { type="toggle", name="Hit Sound On", value=false,
              callback=function(v)
                getgenv().HitSoundActive=v
                if getgenv().HitSoundConnection then
                    getgenv().HitSoundConnection:Disconnect()
                    getgenv().HitSoundConnection=nil
                end
                if v then
                    getgenv().HitSound=resolveSoundId(soundtochange)
                    local ok,viewModel=pcall(function()
                        return game:GetService("Players").LocalPlayer.PlayerScripts
                            .Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ClientViewModel
                    end)
                    if not ok or not viewModel then return end
                    getgenv().HitSoundConnection=viewModel.ChildAdded:Connect(function(sv)
                        if not getgenv().HitSoundActive then return end
                        if not sv:IsA("Sound") then return end
                        if sv.SoundId=="rbxassetid://16537449730" then return end
                        local id=resolveSoundId(soundtochange); if not id then return end
                        sv.SoundId=id; sv.Pitch=1; sv.Volume=getgenv().Volume
                    end)
                end
              end },
          }
        },
      }
    },
    -- ════════════════════════════════════════════
    { name = "Character",
      content = {
        -- ── Movement ────────────────────────────
        { name = "Movement", autopos = "left",
          content = {
            { type="toggle", name="Velocity", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().WalkSpeed.Enabled=v end },
            { type="slider", name="Velocity Value", value=1, minvalue=1, maxvalue=1000,
              callback=function(v) getgenv().WalkSpeed.Speed=v end },
            { type="toggle", name="Slide Boost", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().SlideBoost.Enabled=v end },
            { type="slider", name="Slide Value", value=100, minvalue=1, maxvalue=500,
              callback=function(v) getgenv().SlideBoost.Speed=v end },
            { type="toggle", name="Infinite Jump", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().InfiniteJump=v end },
          }
        },
        -- ── Character ───────────────────────────
        { name = "Character", autopos = "right",
          content = {
            { type="toggle", name="Noclip", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().Noclip=v end },
            { type="toggle", name="Fly", value=false,
              extra={type="keybind"},
              callback=function(v)
                Fly.flying=v
                if v then EnableFlying() else DisableFlying() end
              end },
            { type="slider", name="Fly Speed", value=100, minvalue=1, maxvalue=1000,
              callback=function(v) Fly.flyspeed=v end },
            { type="toggle", name="Spin Bot", value=false,
              extra={type="keybind"},
              callback=function(v) getgenv().Spin.Enabled=v end },
            { type="slider", name="Spin Speed", value=5, minvalue=1, maxvalue=50,
              callback=function(v) getgenv().Spin.Speed=v end },
          }
        },
        -- ── Third Person ────────────────────────
        { name = "Third Person", autopos = "right",
          content = {
            { type="toggle", name="Third Person", value=false,
              extra={type="keybind"},
              callback=function(v) ThirdPersonSetEnabled(v) end },
          }
        },
        -- ── Animation ───────────────────────────
        { name = "Animation", autopos = "left",
          content = {
            { type="toggle", name="Anim Enabled", value=false,
              extra={type="keybind"},
              callback=function(v) AnimationSystem:SetEnabled(v) end },
            { type="dropbox", name="Animation Type", value=1,
              values={"Agree","Coo Coo","Cream Cheese Honey","Criss Cross","Denial","Facepalm","Kneel","Off of You","ROFL","Round & Round","Shivering","Shoulder Brush","Side To Side","Smile","Snow Angels","Superhero","Take The L","Think","Vegetable"},
              callback=function(v)
                Config.Animation=v
                if AnimationSystem.Enabled then AnimationSystem:PlayCurrent() end
              end },
          }
        },
        -- ── Anti Aim ────────────────────────────
        { name = "Anti Aim", autopos = "right",
          content = {
            { type="toggle", name="AA Enabled", value=false,
              callback=function(v)
                getgenv().AntiAim.Enabled=v
                if not v then flushAntiAimMovementState() end
              end },
            { type="dropbox", name="Yaw", value=1,
              values={"spin","static","jitter","random"},
              callback=function(v) getgenv().AntiAim.Yaw=v end },
            { type="dropbox", name="Pitch", value=1,
              values={"down","up","static","random"},
              callback=function(v) getgenv().AntiAim.Pitch=v end },
            { type="dropbox", name="Angle", value=1,
              values={"forward","backward","left","right","custom"},
              callback=function(v) getgenv().AntiAim.Angle=v end },
            { type="slider", name="Custom Angle", value=0, minvalue=-180, maxvalue=180,
              callback=function(v) getgenv().AntiAim.CustomAngle=v end },
            { type="slider", name="Min Speed", value=100, minvalue=0, maxvalue=1000,
              callback=function(v) getgenv().AntiAim.MinSpeed=v end },
            { type="slider", name="Max Speed", value=360, minvalue=0, maxvalue=1000,
              callback=function(v) getgenv().AntiAim.MaxSpeed=v end },
            { type="slider", name="Min Angle", value=0, minvalue=-180, maxvalue=180,
              callback=function(v) getgenv().AntiAim.MinAngle=v end },
            { type="slider", name="Max Angle", value=360, minvalue=0, maxvalue=360,
              callback=function(v) getgenv().AntiAim.MaxAngle=v end },
            { type="toggle", name="Random Angle", value=false,
              callback=function(v) getgenv().AntiAim.RandomAngle=v end },
            { type="toggle", name="Underground", value=false,
              callback=function(v)
                getgenv().AntiAim.Underground=v; getgenv().InstanceUndergroundEnabled=v
              end },
          }
        },
      }
    },
    -- ════════════════════════════════════════════
    { name = "Misc",
      content = {
        -- ── FPS ─────────────────────────────────
        { name = "FPS", autopos = "left",
          content = {
            { type="toggle", name="FPS Unlocker", value=true,
              callback=function(v)
                pcall(function() if setfpscap then setfpscap(v and 0 or 60) end end)
                getgenv().FPSUnlockEnabled=v
              end },
            { type="slider", name="FPS Cap", value=0, minvalue=30, maxvalue=400, stradd="fps",
              custom={[0]="Off"},
              callback=function(v)
                pcall(function()
                    if setfpscap and getgenv().FPSUnlockEnabled then
                        setfpscap(v==0 and 0 or v)
                    end
                end)
              end },
          }
        },
        -- ── Local Spoof ─────────────────────────
        { name = "Local Spoof", autopos = "right",
          content = {
            { type="dropbox", name="Device Type", value=1,
              values={"Computer","Mobile","Console","VR"},
              callback=function(v) getgenv().ChooseDevice=v end },
            { type="toggle", name="Device Spoof", value=false,
              callback=function(v)
                getgenv().DeviceSpoofActive=v
                if v then
                    task.spawn(function()
                        while getgenv().DeviceSpoofActive do
                            spoofDevice(getgenv().ChooseDevice); task.wait(1)
                        end
                    end)
                end
              end },
            { type="textbox", name="Name Input", value="discord.gg/Ukvunvy2UQ" },
            { type="toggle", name="Name Spoof", value=false,
              callback=function(v)
                getgenv().NameSpoofActive=v
                if v then
                    OldName=LocalPlayer.Name; OldDisplayName=LocalPlayer.DisplayName
                    task.spawn(function()
                        while getgenv().NameSpoofActive do
                            if LocalPlayer then
                                LocalPlayer.Name=NameToSpoof; LocalPlayer.DisplayName=NameToSpoof
                            end; task.wait(1)
                        end
                        if LocalPlayer then
                            LocalPlayer.Name=OldName; LocalPlayer.DisplayName=OldDisplayName
                        end
                    end)
                end
              end },
            { type="textbox", name="Win Streak", value="" },
            { type="toggle", name="Spoof Win Streak", value=false,
              callback=function(v)
                getgenv().WinStreakActive=v
                if v then
                    local player=game:GetService("Players").LocalPlayer
                    getgenv()._OrigWinStreak=player:GetAttribute("StatisticDuelsWinStreak")
                    task.spawn(function()
                        while getgenv().WinStreakActive do
                            local val=tonumber(getgenv().WinStreak)
                            if val then player:SetAttribute("StatisticDuelsWinStreak",val) else break end
                            task.wait(1)
                        end
                        pcall(function()
                            player:SetAttribute("StatisticDuelsWinStreak",getgenv()._OrigWinStreak or 0)
                        end)
                    end)
                end
              end },
            { type="textbox", name="Level Input", value="" },
            { type="toggle", name="Spoof Level", value=false,
              callback=function(v)
                getgenv().LevelActive=v
                if v then
                    local player=game:GetService("Players").LocalPlayer
                    getgenv()._OrigLevel=player:GetAttribute("Level")
                    task.spawn(function()
                        while getgenv().LevelActive do
                            local val=tonumber(getgenv().Level)
                            if val then player:SetAttribute("Level",val) else break end
                            task.wait(1)
                        end
                        pcall(function()
                            player:SetAttribute("Level",getgenv()._OrigLevel or 0)
                        end)
                    end)
                end
              end },
          }
        },
        -- ── Other Spoof ─────────────────────────
        { name = "Other Spoof", autopos = "left",
          content = {
            { type="textbox", name="Other Name", value="Hacker" },
            { type="toggle", name="Other Name Spoof", value=false,
              callback=function(v)
                getgenv().OtherNameSpoofActive=v
                if v then
                    task.spawn(function()
                        while getgenv().OtherNameSpoofActive do
                            for _,player in ipairs(Players_L:GetPlayers()) do
                                if player~=Players_L.LocalPlayer and player.Parent then
                                    pcall(function()
                                        player.Name=getgenv().OtherNameToSpoof or "Hacker"
                                        player.DisplayName=getgenv().OtherNameToSpoof or "Hacker"
                                    end)
                                end
                            end; task.wait(1)
                        end
                        for _,player in ipairs(Players_L:GetPlayers()) do
                            if player~=Players_L.LocalPlayer and player.Parent then
                                pcall(function()
                                    local orig=OriginalNames[player.Name]
                                    if orig then
                                        player.Name=orig.Name; player.DisplayName=orig.DisplayName
                                    end
                                end)
                            end
                        end
                    end)
                end
              end },
            { type="textbox", name="Other Level", value="0" },
            { type="toggle", name="Other Level Spoof", value=false,
              callback=function(v)
                getgenv().OtherLevelActive=v
                if v then
                    for _,player in ipairs(Players_L:GetPlayers()) do
                        if player~=Players_L.LocalPlayer then
                            OriginalLevels[player.UserId]=player:GetAttribute("Level")
                        end
                    end
                    task.spawn(function()
                        while getgenv().OtherLevelActive do
                            for _,player in ipairs(Players_L:GetPlayers()) do
                                if player~=Players_L.LocalPlayer and player.Parent then
                                    pcall(function() player:SetAttribute("Level",getgenv().OtherLevel) end)
                                end
                            end; task.wait(1)
                        end
                        for _,player in ipairs(Players_L:GetPlayers()) do
                            if player~=Players_L.LocalPlayer and player.Parent then
                                pcall(function() player:SetAttribute("Level",OriginalLevels[player.UserId] or 0) end)
                            end
                        end
                    end)
                end
              end },
            { type="textbox", name="Other Wins", value="0" },
            { type="toggle", name="Other Wins Spoof", value=false,
              callback=function(v)
                getgenv().OtherWinsActive=v
                if v then
                    task.spawn(function()
                        while getgenv().OtherWinsActive do
                            for _,player in ipairs(Players_L:GetPlayers()) do
                                if player~=Players_L.LocalPlayer and player.Parent then
                                    pcall(function() player:SetAttribute("StatisticDuelsWinStreak",getgenv().OtherWins) end)
                                end
                            end; task.wait(1)
                        end
                    end)
                end
              end },
            { type="toggle", name="Reset All Spoofs", value=false,
              callback=function(v)
                if v then
                    getgenv().OtherNameSpoofActive=false
                    getgenv().OtherLevelActive=false
                    getgenv().OtherWinsActive=false
                    -- reset toggle back to false immediately (best-effort)
                    task.defer(function()
                        pcall(function()
                            menu.options["Misc"]["Other Spoof"]["Reset All Spoofs"][1]=false
                        end)
                    end)
                end
              end },
          }
        },
        -- ── Auto Queue ──────────────────────────
        { name = "Auto Queue", autopos = "right",
          content = {
            { type="toggle", name="AQ Enabled", value=false,
              callback=function(v) getgenv().autoqueue.AutoMatch=v end },
            { type="dropbox", name="Queue Mode", value=1,
              values={"1v1","2v2","3v3","4v4","5v5"},
              callback=function(v) getgenv().autoqueue.QueueGonnaUse=v end },
          }
        },
        -- ── Auto Ban ────────────────────────────
        { name = "Auto Ban", autopos = "left",
          content = {
            { type="toggle", name="AB Enabled", value=false,
              callback=function(v)
                if AutoBanWeaponConnection then AutoBanWeaponConnection:Disconnect(); AutoBanWeaponConnection=nil end
                hasVoted=false
                if v then
                    local remotes=ReplicatedStorage:WaitForChild("Remotes",5)
                    local duels=remotes and remotes:WaitForChild("Duels",5)
                    local voteRemote=duels and duels:WaitForChild("Vote",5)
                    if not voteRemote then warn("Can not find vote remote!"); return end
                    AutoBanWeaponConnection=RunService.RenderStepped:Connect(function()
                        local playerGui=LocalPlayer:FindFirstChild("PlayerGui")
                        local mainGui=playerGui and playerGui:FindFirstChild("MainGui")
                        local mainFrame=mainGui and mainGui:FindFirstChild("MainFrame")
                        local duelInterface=mainFrame and mainFrame:FindFirstChild("DuelInterfaces") and mainFrame.DuelInterfaces:FindFirstChild("DuelInterface")
                        if duelInterface and duelInterface:FindFirstChild("Voting") then
                            local voting=duelInterface.Voting
                            local weapons=voting:FindFirstChild("Weapons")
                            local container1=weapons and weapons:FindFirstChild("Container")
                            local list=container1 and container1:FindFirstChild("List")
                            local container2=list and list:FindFirstChild("Container")
                            if container2 and container2:FindFirstChild("WeaponSlot") then
                                if not hasVoted then
                                    hasVoted=true
                                    voteRemote:FireServer(AutoBanWeapon1Val)
                                    voteRemote:FireServer(AutoBanWeapon2Val)
                                end
                            end
                        else
                            if hasVoted then hasVoted=false end
                        end
                    end)
                end
              end },
            { type="dropbox", name="Ban Slot 1", value=27,
              values=weaponList,
              callback=function(v) AutoBanWeapon1Val=v end },
            { type="dropbox", name="Ban Slot 2", value=31,
              values=weaponList,
              callback=function(v) AutoBanWeapon2Val=v end },
          }
        },
        -- ── Auto Loadout ────────────────────────
        { name = "Auto Loadout", autopos = "right",
          content = {
            { type="toggle", name="AL Enabled", value=false,
              callback=function(v)
                if AutoPickWeaponConnection then AutoPickWeaponConnection:Disconnect(); AutoPickWeaponConnection=nil end
                hasPicked=false
                if v then
                    local weaponPickRemote=ReplicatedStorage:WaitForChild("Remotes",5)
                        and ReplicatedStorage.Remotes:WaitForChild("Replication",5)
                        and ReplicatedStorage.Remotes.Replication:WaitForChild("Fighter",5)
                        and ReplicatedStorage.Remotes.Replication.Fighter:WaitForChild("PickWeapons",5)
                    local prePickRemote=ReplicatedStorage:WaitForChild("Remotes",5)
                        and ReplicatedStorage.Remotes:WaitForChild("Duels",5)
                        and ReplicatedStorage.Remotes.Duels:WaitForChild("PickWeaponsAheadOfTime",5)
                    if not weaponPickRemote then warn("Can not find weapon pick remotes!"); return end
                    AutoPickWeaponConnection=RunService.RenderStepped:Connect(function()
                        local playerGui=LocalPlayer:FindFirstChildOfClass("PlayerGui")
                        local selectionInterface=playerGui and playerGui:FindFirstChild("PickWeapons",true)
                        if selectionInterface and selectionInterface.Visible then
                            if not hasPicked then
                                hasPicked=true
                                local payload={[1]=AutoPickWeapon1Val,[2]=AutoPickWeapon2Val,[3]=AutoPickWeapon3Val,[4]=AutoPickWeapon4Val}
                                pcall(function() weaponPickRemote:FireServer(payload) end)
                                if prePickRemote then pcall(function() prePickRemote:FireServer(payload) end) end
                            end
                        else
                            if hasPicked then hasPicked=false end
                        end
                    end)
                end
              end },
            { type="dropbox", name="Pick Slot 1", value=1,
              values=weaponList,
              callback=function(v) AutoPickWeapon1Val=v end },
            { type="dropbox", name="Pick Slot 2", value=17,
              values=weaponList,
              callback=function(v) AutoPickWeapon2Val=v end },
            { type="dropbox", name="Pick Slot 3", value=27,
              values=weaponList,
              callback=function(v) AutoPickWeapon3Val=v end },
            { type="dropbox", name="Pick Slot 4", value=37,
              values=weaponList,
              callback=function(v) AutoPickWeapon4Val=v end },
          }
        },
      }
    },
    -- ════════════════════════════════════════════
    { name = "Settings",
      content = {
        { name = "Menu", autopos = "left",
          content = {
            { type="toggle", name="Menu Keybind", value=false,
              extra={type="keybind", key=Enum.KeyCode.RightShift} },
          }
        },
      }
    },
})

-- ============================================================
-- Post-init: color sync loop for colorpickers (since BitchBot
-- has no per-change callbacks on colorpickers, poll each frame)
-- ============================================================
local function bbColor(tab,group,name,which)
    local ok,v = pcall(function()
        if which=="color2" then
            return menu:GetVal(tab,group,name,"color2",true)
        else
            return menu:GetVal(tab,group,name,"color",true)
        end
    end)
    if ok and v then return v end
    return Color3.fromRGB(255,255,255)
end

task.spawn(function()
    while true do
        task.wait(0.05)
        pcall(function()
            -- Aimbot FOV colors
            getgenv().Aimbot.FovOutlineColor    = bbColor("Main","Aimbot","FOV Outline")
            getgenv().Aimbot.FovFilledColor      = bbColor("Main","Aimbot","FOV Filled")
            -- Silent Aim FOV colors
            getgenv().SilentAim.FovOutlineColor  = bbColor("Main","Silent Aim","SA FOV Outline")
            getgenv().SilentAim.FovFilledColor   = bbColor("Main","Silent Aim","SA FOV Filled")
            -- Ragebot status color
            rbCfg.ragestatus.color               = bbColor("Main","Rage Status","Status Color")
            -- ESP gradient colors
            getgenv().ESP.ColorA                 = bbColor("ESP","Player ESP","Gradient")
            getgenv().ESP.ColorB                 = bbColor("ESP","Player ESP","Gradient","color2")
            getgenv().ESP.Color                  = bbColor("ESP","Player ESP","Static Color")
            -- Fog color
            getgenv().CustomFog.Color            = bbColor("World","Custom Fog","Fog Color")
            -- Weather color
            if Weather then Weather.Color        = bbColor("World","Weather","Weather Color") end
            -- Monitor color
            getgenv().EyeProtection.Color        = bbColor("World","Monitor Color","MC Enabled")
            -- Bullet tracers color
            getgenv().BulletTracersColor         = bbColor("Visuals","Bullet Tracers","Tracers Enabled")
            -- Hit effect colors
            HE:SetColor(bbColor("Visuals","Hit Effect","HE Enabled"))
            HE:SetOutlineColor(bbColor("Visuals","Hit Effect","HE Enabled","color2"))
            -- Name spoof textbox
            local nameVal=menu:GetVal("Misc","Local Spoof","Name Input")
            if nameVal and nameVal~="" then NameToSpoof=nameVal end
            -- Win streak textbox
            local wsVal=tonumber(menu:GetVal("Misc","Local Spoof","Win Streak"))
            if wsVal then getgenv().WinStreak=wsVal end
            -- Level textbox
            local lvlVal=tonumber(menu:GetVal("Misc","Local Spoof","Level Input"))
            if lvlVal then getgenv().Level=lvlVal end
            -- Other spoof textboxes
            local onVal=menu:GetVal("Misc","Other Spoof","Other Name")
            if onVal and onVal~="" then getgenv().OtherNameToSpoof=onVal end
            local olVal=tonumber(menu:GetVal("Misc","Other Spoof","Other Level"))
            if olVal then getgenv().OtherLevel=olVal end
            local owVal=tonumber(menu:GetVal("Misc","Other Spoof","Other Wins"))
            if owVal then getgenv().OtherWins=owVal end
        end)
    end
end)

-- ============================================================
-- Cleanup on menu close / script end (best-effort)
-- ============================================================
task.spawn(function()
    game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
        pcall(function()
            if ragebot and ragebot.cleartarget then ragebot.cleartarget() end
            if ragebot and ragebot.stopvoid    then ragebot.stopvoid() end
        end)
        pcall(function() RunService:UnbindFromRenderStep("vfr_csync") end)
        pcall(function()
            if getgenv().AimbotFOVConnection   then getgenv().AimbotFOVConnection:Disconnect()   end
            if getgenv().TriggerBotConnection  then getgenv().TriggerBotConnection:Disconnect()  end
            if getgenv().SilentAimFOVCircleOutline then getgenv().SilentAimFOVCircleOutline:Remove() end
            if getgenv().SilentAimFOVCircleFill    then getgenv().SilentAimFOVCircleFill:Remove()    end
        end)
        pcall(function()
            if getgenv().HitSoundConnection then getgenv().HitSoundConnection:Disconnect() end
        end)
        pcall(function()
            for plr,_ in pairs(ESPObjects or {}) do clearESP(plr) end
        end)
    end)
end)

-- Hide the "Loading..." text now that the menu is fully initialized
pcall(function() loadingthing.Visible = false end)

getgenv().OnyxLoaded = true
end -- close _onyxUI
local _uiOk, _uiErr = pcall(_onyxUI)
if not _uiOk then
    warn("[Onyx] _onyxUI error: " .. tostring(_uiErr))
end
end) -- close inner task.spawn (OnyxLoaded guard)
end -- close if OnyxLoaded
end) -- close outer task.spawn (whole script)

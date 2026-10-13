--[[
	Project Nexus: Game Security Auditor & Automation Interface
	Version: 2.0 (Fluent UI)
	DISCLAIMER: Educational/testing purposes only. Use in your own sessions.

	FE-Compatible Features (other players can see):
		Chat: Chat Spam, Fake Admin, Fake System, Name Spam, Chat Backwards, Bubble Chat
		Animation: Jerk Off, Play Animation, Rthro Animation Spam, Emote Player
		Movement: HeadSit, Orbit, Fling, WalkFling, Fake Lag, Rotation Lock
		Physics: Freeze/Thaw, Velocity, Self-Terminate
		Visual: Particle Effects, Sound Spam, Glitch Effect, Hat Overflow, Accessory Spam
		Shopping: Fake Product/GamePass/Bulk Purchase
		Misc: Fake Kick screen, Flashback, Dash, Wallrun, Air Jump, Sit Spam

	Client-only features:
		Fly, Noclip, SpinBot, Anti-AFK
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local uis = UserInputService
local replicated = ReplicatedStorage
local ms = MarketplaceService

-- Ensure task.* utilities exist (some older exploit executors lack task.spawn)
if not task then
	task = {
		spawn = function(f) spawn(f) end,
		wait = function(t) wait(t) end,
	}
elseif not task.spawn then
	task.spawn = function(f) spawn(f) end
end
if not task.wait then task.wait = function(t) wait(t) end end

-- ==================== Fluent UI ====================
local Fluent
local FluentSuccess = pcall(function()
	Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

-- Retry with backup sources
if not FluentSuccess or not Fluent then
	for _, url in ipairs({
		"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
		"https://raw.githubusercontent.com/dawid-scripts/Fluent/master/init.lua",
		"https://raw.githubusercontent.com/dawid-scripts/Fluent/main/init.lua",
	}) do
		FluentSuccess = pcall(function()
			Fluent = loadstring(game:HttpGet(url))()
		end)
		if Fluent then break end
	end
end

if not FluentSuccess or not Fluent then
	warn("[Project Nexus] Fluent UI library failed to load (3 retries). Possible causes:")
	warn("  - No internet connection")
	warn("  - GitHub is blocked")
	warn("  - Outdated exploit executor")
	warn("  - Script must run inside Roblox via an exploit (Synapse, Fluxus, etc.)")
	return
end

	local menuToggleKey = Enum.KeyCode.LeftControl

local Window = Fluent:CreateWindow({
	Title = "Project Nexus",
	SubTitle = "Game Security Auditor",
	TabWidth = 95,
	Size = UDim2.fromOffset(900, 680),
	Acrylic = false,
	Theme = "Dark",
	MinimizeKey = menuToggleKey,
})

local CombatTab = Window:AddTab({Title = "Combat", Icon = "target"})
local VisualsTab = Window:AddTab({Title = "Visuals", Icon = "eye"})
local TriggerTab = Window:AddTab({Title = "Trigger", Icon = "mouse"})
local GunModsTab = Window:AddTab({Title = "Gun Mods", Icon = "crosshair"})
local MovementTab = Window:AddTab({Title = "Movement", Icon = "move"})
local TrollTab = Window:AddTab({Title = "Troll", Icon = "skull"})
local AnimationTab = Window:AddTab({Title = "Animation", Icon = "ghost"})
local ShopTab = Window:AddTab({Title = "Shop", Icon = "shopping-cart"})
local ScriptsTab = Window:AddTab({Title = "Scripts", Icon = "code"})
local MiscTab = Window:AddTab({Title = "Misc", Icon = "wrench"})
local SettingsTab = Window:AddTab({Title = "Settings", Icon = "settings"})

-- ==================== Exunys Modules ====================
local ExunysLoaded = false
local Aimbot, ESP, Crosshair, CenterDot
local Aimbot_Settings, Aimbot_FOV, Triggerbot
local Aimbot_DeveloperSettings
local ESP_Settings, ESP_Properties, ESP_DeveloperSettings
local SilentAimLoaded = false
local silentAimOldNamecall = nil
local silentAimActive = false

do
	local libSuccess = pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Roblox-Functions-Library/main/Library.lua"))()
	end)

	if libSuccess then
		local aimbotSuccess, aimbotResult = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()
		end)

		local espSuccess, espResult = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Exunys-ESP/main/src/ESP.lua"))()
		end)

		if aimbotSuccess and espSuccess and aimbotResult and espResult then
			Aimbot = aimbotResult
			ESP = espResult

			Aimbot_DeveloperSettings = Aimbot.DeveloperSettings
			Aimbot_Settings = Aimbot.Settings
			Aimbot_FOV = Aimbot.FOVSettings
			Triggerbot = Aimbot.Triggerbot

			ESP_Settings = ESP.Settings
			ESP_Properties = ESP.Properties
			ESP_DeveloperSettings = ESP.DeveloperSettings
			Crosshair = ESP_Properties.Crosshair
			CenterDot = Crosshair.CenterDot

			ESP_Settings.LoadConfigOnLaunch = false
			ESP_Settings.Enabled = false
			Crosshair.Enabled = false
			Aimbot_Settings.Enabled = false

			pcall(ESP.Load)
			pcall(Aimbot.Load)
			ExunysLoaded = true
		end
	end

	if not ExunysLoaded then
		warn("[Project Nexus] Failed to load Exunys Aimbot/ESP modules. Falling back to built-in systems.")
	end
end

-- ==================== State ====================

-- Combat - Aimbot (delegated to Exunys Aimbot V3 when loaded)
local aimbotEnabled = false
local aimKey = Enum.UserInputType.MouseButton2
local aimKeyIsKeyCode = false
local aimKeyMode = "hold"
local aimFovEnabled = true
local aimFovRadius = 120
local aimSmoothness = 0.1
local aimSmoothingMode = "linear"
local aimPrediction = 0.07
local aimPart = "Head"
local aimTeamCheck = true
local aimAliveCheck = true
local aimWallCheck = false
local aimToggleState = false
local aimHitChance = 100
local silentAimEnabled = false
local silentAimTeamCheck = false

-- Combat - Trigger Bot (delegated to Exunys Aimbot.Triggerbot when loaded)
local triggerBotEnabled = false
local triggerBotKey = Enum.UserInputType.MouseButton2
local triggerBotKeyIsKeyCode = false
local triggerBotDelay = 0

-- Combat - ESP & Crosshair (delegated to Exunys ESP when loaded)
espEnabled = false
espTeamCheck = true
espMaxDistance = 1000
espInstances = {}
local crosshairEnabled = false
local crosshairSize = 8
local crosshairColor = Color3.fromRGB(255, 255, 255)
local crosshairDynamic = true

-- Movement
local flyEnabled = false
local flyConn = nil
local flyKeyDownConn = nil
local flyKeyUpConn = nil
local flyBv = nil
local flyBg = nil
local flyCharacterRemovingConn = nil
local flySpeed = 60
local noclipEnabled = false
local noclipConn = nil
local bhopEnabled = false
local bhopConn = nil
local spinEnabled = false
local spinSpeed = 180
local spinConn = nil
local antiIdleEnabled = false
local antiIdleConn = nil
local walkSpeed = 16
local jumpPower = 50

-- Movement Tech
local dashEnabled = false
local dashSpeed = 100
local dashTime = 0.3
local wallrunEnabled = false
local wallrunConn = nil
local airJumpEnabled = false
local airJumpConn = nil
local airJumped = false
local flashbackPos = nil

-- Troll - Chat
local chatMsg = "Get rekt!"
local chatDelay = 0.2
local chatConn = nil
local chatSpamming = false

local nameSpamText = "[ADMIN] TROLL"
local nameSpamConn = nil
local nameSpamming = false

local backwardsMsg = "Get rekt!"
local backwardsConn = nil
local backwardsEnabled = false

local bubbleMsg = "Bubble spam"
local bubbleConn = nil
local bubbleEnabled = false

-- Troll - Physics
local headSitConn = nil
local orbitConn = nil
local orbitSpeed = 50
local orbitDist = 10

local flingEnabled = false
local flingConn = nil

local walkFlingEnabled = false
local walkFlingConn = nil

local fakeLagEnabled = false
local fakeLagConn = nil
local fakeLagInterval = 0.1

local rotLockEnabled = false
local rotLockConn = nil

local sitSpamEnabled = false
local sitSpamConn = nil
local sitSpamInterval = 0.1

local velocityConn = nil
local velocityAmount = 500

local hatOverflowEnabled = false
local hatOverflowConn = nil

local accessorySpamEnabled = false
local accessorySpamConn = nil

local viewmodelSpamEnabled = false
local viewmodelSpamConn = nil

local fakeAfkEnabled = false
local fakeAfkConn = nil

local soundId = "rbxassetid://12222077"
local soundVolume = 0.5
local soundLoop = true
local soundSpamEnabled = false
local soundConn = nil
local soundObj = nil

local fakeKickMsg = "You have been kicked from the game.\n\nKicked by: Server"

-- Animation
local jerkEnabled = false
local animTrack = nil
local animLoopEnabled = false
local rthroSpamEnabled = false
local rthroSpamConn = nil

-- Shop
local productId = "12345678"
local purchaseLoggerEnabled = false
local purchaseLoggerConn = nil
local purchaseLogs = {}
local lastLoggedProductId = nil

-- ==================== Utility ====================

function getChar()
	return player.Character
end

function getRoot()
	local char = getChar()
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

function getHumanoid()
	local char = getChar()
	if char and char:IsA("Model") then
		return char:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

function r15(plr)
	if not plr or not plr.Character then return false end
	return plr.Character:FindFirstChild("UpperTorso") ~= nil
end

function randomString(len)
	len = len or 10
	local s = ""
	for _ = 1, len do
		s = s .. string.char(math.random(97, 122))
	end
	return s
end

function findPartFromRayWithIgnoreList(origin, direction, ignore)
	local ray = Ray.new(origin, direction)
	if workspace.FindPartOnRayWithIgnoreList then
		return workspace:FindPartOnRayWithIgnoreList(ray, ignore or {})
	elseif workspace.FindPartOnRay then
		return workspace:FindPartOnRay(ray, (ignore and ignore[1]) or nil)
	end
	return nil
end

function findPlayer(name)
	if not name or name == "" then return nil end
	name = string.lower(tostring(name))
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.lower(plr.Name) == name then
			return plr
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(plr.Name), 1, #name) == name then
			return plr
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(plr.DisplayName or ""), 1, #name) == name then
			return plr
		end
	end
	return nil
end

function doNotify(title, content, duration)
	duration = duration or 3
	if Fluent then
		Fluent:Notify({ Title = title, Content = content, Duration = duration })
	else
		warn("[" .. title .. "] " .. content)
	end
end

-- ==================== Combat: Aimbot (Exunys Integration) ====================

function syncAimbotSettings()
	if not ExunysLoaded or not Aimbot_Settings then return end

	Aimbot_Settings.Enabled = aimbotEnabled
	Aimbot_Settings.Toggle = aimKeyMode == "toggle"
	Aimbot_Settings.LockPart = aimPart == "Head" and "Head"
		or aimPart == "HumanoidRootPart" and "HumanoidRootPart"
		or aimPart == "UpperTorso" and "UpperTorso"
		or aimPart == "LowerTorso" and "LowerTorso"
		or aimPart == "LeftHand" and "LeftHand"
		or aimPart == "RightHand" and "RightHand"
		or aimPart

	Aimbot_FOV.Radius = aimFovEnabled and aimFovRadius or 0

	Aimbot_Settings.OffsetToMoveDirection = aimPrediction > 0
	Aimbot_Settings.OffsetIncrement = aimPrediction * 100

	if aimSmoothingMode == "exponential" then
		Aimbot_Settings.LockMode = 2
	else
		Aimbot_Settings.LockMode = 1
	end

	Aimbot_Settings.Sensitivity = aimSmoothness
end

function setAimKey()
	Fluent:Notify({ Title = "Aim Key", Content = "Press any key within 5 seconds.", Duration = 5 })
	local con
	con = uis.InputBegan:Connect(function(input)
		if input.UserInputState == Enum.UserInputState.Begin then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				aimKey = input.KeyCode
				aimKeyIsKeyCode = true
				Aimbot_Settings.TriggerKey = input.KeyCode
				Fluent:Notify({ Title = "Aim Key", Content = "Set to: " .. tostring(input.KeyCode), Duration = 3 })
			else
				aimKey = input.UserInputType
				aimKeyIsKeyCode = false
				Aimbot_Settings.TriggerKey = input.UserInputType
				Fluent:Notify({ Title = "Aim Key", Content = "Set to: " .. tostring(input.UserInputType), Duration = 3 })
			end
			con:Disconnect()
		end
	end)
	delay(5, function() if con.Connected then con:Disconnect() end end)
end

function setTriggerKey()
	Fluent:Notify({ Title = "Trigger Key", Content = "Press any key within 5 seconds.", Duration = 5 })
	local con
	con = uis.InputBegan:Connect(function(input)
		if input.UserInputState == Enum.UserInputState.Begin then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				triggerBotKey = input.KeyCode
				triggerBotKeyIsKeyCode = true
				Triggerbot.Key = input.KeyCode
				Fluent:Notify({ Title = "Trigger Key", Content = "Set to: " .. tostring(input.KeyCode), Duration = 3 })
			else
				triggerBotKey = input.UserInputType
				triggerBotKeyIsKeyCode = false
				Triggerbot.Key = input.UserInputType
				Fluent:Notify({ Title = "Trigger Key", Content = "Set to: " .. tostring(input.UserInputType), Duration = 3 })
			end
			con:Disconnect()
		end
	end)
	delay(5, function() if con.Connected then con:Disconnect() end end)
end

function toggleAimbot(state)
	aimbotEnabled = state
	if Aimbot_Settings then
		Aimbot_Settings.Enabled = state
	end
	if state then
		syncAimbotSettings()
		doNotify("Aimbot", "Enabled.", 2)
	else
		doNotify("Aimbot", "Disabled.", 2)
	end
end

function toggleTriggerBot(state)
	triggerBotEnabled = state
	if Triggerbot then
		Triggerbot.Enabled = state
	end
	if state then
		doNotify("Trigger Bot", "Enabled.", 2)
	else
		doNotify("Trigger Bot", "Disabled.", 2)
	end
end
function drawCrosshair()
	if not ExunysLoaded or not Crosshair then
		if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
		if crosshairConn then crosshairConn:Disconnect() crosshairConn = nil end
		return
	end
	if not crosshairEnabled then
		Crosshair.Enabled = false
		if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
		if crosshairConn then crosshairConn:Disconnect() crosshairConn = nil end
		return
	end
	Crosshair.Enabled = true
	Crosshair.Size = crosshairSize
	Crosshair.Color = crosshairColor

	if crosshairDynamic then
		Crosshair.Position = 1 -- Mouse position
	else
		Crosshair.Position = 2 -- Center
	end
end

function toggleCrosshair(state)
	crosshairEnabled = state
	if Crosshair then
		Crosshair.Enabled = state
	end
	drawCrosshair()
	if state then
		doNotify("Crosshair", "Enabled.", 2)
	else
		if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
		if crosshairConn then crosshairConn:Disconnect() crosshairConn = nil end
		doNotify("Crosshair", "Disabled.", 2)
	end
end

-- ==================== Combat: Silent Aim ====================
-- Based on Exunys' ROBLOX Weapons Kit Silent Aim
-- Hooks __namecall to redirect FindPartOnRayWithIgnoreList from ClientWeaponsScript

local silentAimGetClosestPlayer = function()
	local closest, minDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			if silentAimEnabled and silentAimTeamCheck then
				if plr.Team and player.Team and plr.Team == player.Team then
					continue
				end
			end
			local char = plr.Character
			local head = char and char:FindFirstChild("Head")
			if head then
				local screenPos = camera:WorldToViewportPoint(head.Position)
				if screenPos.Z > 0 then
					local dist = (Vector2.new(uis:GetMouseLocation().X, uis:GetMouseLocation().Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < minDist then
						minDist = dist
						closest = plr
					end
				end
			end
		end
	end
	return closest
end

function toggleSilentAim(state)
	silentAimEnabled = state
	if not state then
		if silentAimOldNamecall then
			hookmetamethod(game, "__namecall", silentAimOldNamecall)
			silentAimOldNamecall = nil
		end
		silentAimActive = false
		doNotify("Silent Aim", "Disabled.", 2)
		return
	end

	silentAimOldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
		local args = table.pack(...)
		local method = getnamecallmethod()
		if not checkcaller() and method == "FindPartOnRayWithIgnoreList" then
			local script = getcallingscript()
			if script and script.Name == "ClientWeaponsScript" then
				local target = silentAimGetClosestPlayer()
				if target and target.Character and target.Character:FindFirstChild("Head") then
					for i = 1, args.n do
						if typeof(args[i]) == "Ray" then
							args[i] = Ray.new(args[i].Origin, (target.Character.Head.Position - args[i].Origin))
							break
						end
					end
					return silentAimOldNamecall(table.unpack(args, 1, args.n))
				end
			end
		end
		return silentAimOldNamecall(...)
	end))

	silentAimActive = true
	doNotify("Silent Aim", "Enabled. Redirects shots via __namecall hook.", 3)
end

-- ==================== Movement: Extended ====================

local infiniteJumpConn = nil

function toggleInfiniteJump()
	infiniteJumpEnabled = not infiniteJumpEnabled
	if infiniteJumpEnabled then
		infiniteJumpConn = uis.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Space then
				local humanoid = getHumanoid()
				if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
		doNotify("Infinite Jump", "Enabled.", 2)
	else
		if infiniteJumpConn then infiniteJumpConn:Disconnect() infiniteJumpConn = nil end
		doNotify("Infinite Jump", "Disabled.", 2)
	end
end

function toggleAntiStun()
	antiStunEnabled = not antiStunEnabled
	if antiStunEnabled then
		antiStunConn = RunService.Heartbeat:Connect(function()
			if not antiStunEnabled then
				if antiStunConn then antiStunConn:Disconnect() antiStunConn = nil end
				return
			end
			local root = getRoot()
			if root then
				if root.Velocity.Y < -50 then
					root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
				end
			end
		end)
		doNotify("Anti-Stun", "Enabled.", 2)
	else
		if antiStunConn then antiStunConn:Disconnect() antiStunConn = nil end
		doNotify("Anti-Stun", "Disabled.", 2)
	end
end

-- ==================== Troll: Extended ====================

function toggleChatVisible()
	chatVisibleEnabled = not chatVisibleEnabled
	if chatVisibleEnabled then
		local events = replicated:FindFirstChild("DefaultChatSystemChatEvents")
		if events then
			for _, v in ipairs(events:GetDescendants()) do
				if v:IsA("RemoteEvent") then
					chatVisibleConn = v.OnClientEvent:Connect(function(...)
						local args = {...}
						if #args > 0 then
							doNotify("Chat Visible", tostring(args[1]), 3)
						end
					end)
				end
			end
		end
		doNotify("Chat Visible", "Monitoring chat events.", 2)
	else
		if chatVisibleConn then chatVisibleConn:Disconnect() chatVisibleConn = nil end
		doNotify("Chat Visible", "Stopped.", 2)
	end
end

function toggleGravity()
	gravityEnabled = not gravityEnabled
	if gravityEnabled then
		workspace.Gravity = gravityValue
		gravityConn = RunService.Heartbeat:Connect(function()
			if not gravityEnabled then
				if gravityConn then gravityConn:Disconnect() end
				workspace.Gravity = 192.22
				return
			end
			workspace.Gravity = gravityValue
		end)
		doNotify("Gravity", "Set to: " .. gravityValue, 2)
	else
		if gravityConn then gravityConn:Disconnect() gravityConn = nil end
		workspace.Gravity = 192.22
		doNotify("Gravity", "Reset to default.", 2)
	end
end

function setTimeOfDay(hour)
	timeOfDay = hour
	Lighting.ClockTime = timeOfDay
	if timeConn then timeConn:Disconnect() end
	timeConn = RunService.Heartbeat:Connect(function()
		if not timeOfDay then
			if timeConn then timeConn:Disconnect() end
			return
		end
		Lighting.ClockTime = timeOfDay
	end)
	doNotify("Time", "Set to: " .. hour .. ":00", 2)
end

function toggleFakeDisconnect()
	fakeDisconnectEnabled = not fakeDisconnectEnabled
	if fakeDisconnectEnabled then
		local pg = player:FindFirstChild("PlayerGui")
		if not pg then return end
		local gui = Instance.new("ScreenGui")
		gui.Name = "FakeDisconnectGui"
		pcall(function() gui.ResetOnDestroy = false end)
		gui.Parent = pg

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		frame.BorderSizePixel = 0
		frame.ZIndex = 9999
		frame.Parent = gui

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.8, 0, 0.5, 0)
		label.Position = UDim2.new(0.1, 0, 0.4, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.Gotham
		label.Text = "Disconnected from game.\nReconnecting..."
		label.TextWrapped = true
		label.ZIndex = 10000
		label.Parent = gui

		game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
		doNotify("Fake Disconnect", "Displayed (re-enable in Settings).", 3)
	else
		local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("FakeDisconnectGui")
		if gui then gui:Destroy() end
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
		doNotify("Fake Disconnect", "Removed.", 2)
	end
end

-- ==================== General: Config & Stats ====================

function saveConfig()
	local config = {
		flySpeed = flySpeed,
		spinSpeed = spinSpeed,
		walkSpeed = walkSpeed,
		jumpPower = jumpPower,
		dashSpeed = dashSpeed,
		dashTime = dashTime,
		orbitSpeed = orbitSpeed,
		orbitDist = orbitDist,
		chatMsg = chatMsg,
		chatDelay = chatDelay,
		nameSpamText = nameSpamText,
		backwardsMsg = backwardsMsg,
		bubbleMsg = bubbleMsg,
		soundId = soundId,
		soundVolume = soundVolume,
		aimSpeed = aimSmoothness,
		aimPrediction = aimPrediction,
		aimFovRadius = aimFovRadius,
		aimPart = aimPart,
		aimHitChance = aimHitChance,
		triggerBotDelay = triggerBotDelay,
		gravityValue = gravityValue,
		timeOfDay = timeOfDay,
		boxEspColor = {r = boxEspColor.R * 255, g = boxEspColor.G * 255, b = boxEspColor.B * 255},
		chamsColor = {r = chamsColor.R * 255, g = chamsColor.G * 255, b = chamsColor.B * 255},
		tracerColor = {r = tracerColor.R * 255, g = tracerColor.G * 255, b = tracerColor.B * 255},
	}
	local json = HttpService:JSONEncode(config)
	if writefile then
		writefile("ProjectNexus_Config_" .. configName .. ".json", json)
		doNotify("Config", "Saved as: " .. configName, 2)
	else
		doNotify("Config", "writefile not available.", 3)
	end
end

function loadConfig()
	if not readfile then
		doNotify("Config", "readfile not available.", 3)
		return
	end
	local filename = "ProjectNexus_Config_" .. configName .. ".json"
	local success, data = pcall(function()
		return readfile(filename)
	end)
	if not success then
		doNotify("Config", "Config not found: " .. configName, 3)
		return
	end
	local config = HttpService:JSONDecode(data)

	flySpeed = config.flySpeed or flySpeed
	spinSpeed = config.spinSpeed or spinSpeed
	walkSpeed = config.walkSpeed or walkSpeed
	jumpPower = config.jumpPower or jumpPower
	dashSpeed = config.dashSpeed or dashSpeed
	dashTime = config.dashTime or dashTime
	orbitSpeed = config.orbitSpeed or orbitSpeed
	orbitDist = config.orbitDist or orbitDist
	chatMsg = config.chatMsg or chatMsg
	chatDelay = config.chatDelay or chatDelay
	nameSpamText = config.nameSpamText or nameSpamText
	backwardsMsg = config.backwardsMsg or backwardsMsg
	bubbleMsg = config.bubbleMsg or bubbleMsg
	soundId = config.soundId or soundId
	soundVolume = config.soundVolume or soundVolume
	aimSmoothness = config.aimSpeed or aimSmoothness
	aimPrediction = config.aimPrediction or aimPrediction
	aimFovRadius = config.aimFovRadius or aimFovRadius
	aimPart = config.aimPart or aimPart
	aimHitChance = config.aimHitChance or aimHitChance
	triggerBotDelay = config.triggerBotDelay or triggerBotDelay
	gravityValue = config.gravityValue or gravityValue
	timeOfDay = config.timeOfDay or timeOfDay

	if config.boxEspColor then
		boxEspColor = Color3.fromRGB(config.boxEspColor.r or 255, config.boxEspColor.g or 255, config.boxEspColor.b or 255)
	end
	if config.chamsColor then
		chamsColor = Color3.fromRGB(config.chamsColor.r or 255, config.chamsColor.g or 0, config.chamsColor.b or 0)
	end
	if config.tracerColor then
		tracerColor = Color3.fromRGB(config.tracerColor.r or 255, config.tracerColor.g or 255, config.tracerColor.b or 255)
	end

	updateEspSettings()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = walkSpeed
		humanoid.JumpPower = jumpPower
	end

	doNotify("Config", "Loaded: " .. configName, 3)
end

-- Performance stats
local perfConn = nil
function togglePerfStats()
	perfStatsEnabled = not perfStatsEnabled
	if perfStatsEnabled then
		local pg = player:FindFirstChild("PlayerGui")
		if not pg then return end
		local existing = pg:FindFirstChild("PerfStatsGui")
		if existing then existing:Destroy() end

		perfGui = Instance.new("ScreenGui")
		perfGui.Name = "PerfStatsGui"
		pcall(function() perfGui.ResetOnDestroy = false end)
		perfGui.Parent = pg

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 200, 0, 60)
		frame.Position = UDim2.new(1, -210, 0, 10)
		frame.BackgroundTransparency = 0.3
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.BorderSizePixel = 0
		frame.ZIndex = 9999
		frame.Parent = perfGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame

		perfLabel = Instance.new("TextLabel")
		perfLabel.Name = "PerfLabel"
		perfLabel.Size = UDim2.new(1, -10, 1, -10)
		perfLabel.Position = UDim2.new(0, 5, 0, 5)
		perfLabel.BackgroundTransparency = 1
		perfLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		perfLabel.Font = Enum.Font.Gotham
		perfLabel.TextSize = 14
		perfLabel.TextXAlignment = Enum.TextXAlignment.Left
		perfLabel.Text = "FPS: --\nPing: --ms"
		perfLabel.TextWrapped = true
		perfLabel.ZIndex = 10000
		perfLabel.Parent = frame

		local lastTick = tick()
		perfConn = RunService.RenderStepped:Connect(function()
			if not perfStatsEnabled then
				if perfConn then perfConn:Disconnect() perfConn = nil end
				return
			end
			if perfLabel and perfLabel.Parent then
				local now = tick()
				local fps = math.floor(1 / (now - lastTick))
				lastTick = now
				local ping = "Ping: " .. math.floor(player:GetNetworkPing() * 1000) .. "ms"
				perfLabel.Text = "FPS: " .. fps .. "\n" .. ping
			end
		end)
		doNotify("Performance", "Stats enabled.", 2)
	else
		if perfGui then perfGui:Destroy() perfGui = nil end
		if perfConn then perfConn:Disconnect() perfConn = nil end
		perfLabel = nil
		doNotify("Performance", "Stats disabled.", 2)
	end
end

function executeScript(code)
	if not code or code == "" then return end
	local success, result = pcall(function()
		local func = loadstring(code)
		if not func then error("Failed to compile code") end
		return func()
	end)
	if success then
		table.insert(scriptHistory, "> " .. code)
		doNotify("Scripts", "Execution successful.", 3)
	else
		local errMsg = tostring(result)
		table.insert(scriptHistory, "> " .. code .. "\n[ERROR] " .. errMsg)
		doNotify("Scripts", "Execution failed: " .. errMsg, 5)
	end
	lastScript = code
end

function clearScriptHistory()
	scriptHistory = {}
	doNotify("Scripts", "History cleared.", 2)
end

function copyScriptOutput(output)
	if output and typeof(output) ~= "nil" then
		local str = tostring(output)
		table.insert(scriptHistory, "output: " .. str)
		doNotify("Scripts", "Output: " .. str, 4)
	end
end

-- ==================== State Initialization ====================
-- Scripts state
scriptHistory = {}
lastScript = ""

-- Misc state
godmodeEnabled = false
godmodeConn = nil
cameraFovValue = 70
noFallDamageEnabled = false
noFallDamageConn = nil
walkSpeedValue = 16
jumpPowerValue = 50
walkSpeedOverrideEnabled = false
jumpPowerOverrideEnabled = false
walkSpeedConn = nil
jumpPowerConn = nil
highlightSelfEnabled = false
noCameraSwayEnabled = false
noBlurEnabled = false

-- Gun Mods state
gunRecoilPercent = 0
gunNoSpreadEnabled = false
gunInfAmmoEnabled = false
gunFastReloadEnabled = false
gunNoMuzzleFlash = false
gunNoShellEject = false
gunModConn = nil
gunLastCFrame = nil
gunCharConn = nil

-- Weapon cache for background scanner
weaponCache = {}
weaponCacheScanning = false
weaponCacheConn = nil

-- Forward declarations for scanner control (ensures visibility across all module blocks)
startWeaponScanner = nil
stopWeaponScanner = nil
function startWeaponScanner()
	weaponCacheScanning = true
	weaponCacheConn = task.spawn(function()
		while weaponCacheScanning do
			if not weaponCacheScanning then break end
			local newCache = {}
			if type(getgc) == "function" then
				for _, v in pairs(getgc(true)) do
					if type(v) == "table" and (
						(gunInfAmmoEnabled and (v.Ammo or v.CurrentAmmo or v.ClipSize or v.StoredAmmo)) or
						(gunNoSpreadEnabled and (v.Spread or v.MinSpread or v.MaxSpread or v.BulletSpread)) or
						(gunRecoilPercent > 0 and (v.Recoil or v.KickUp))
					) then
						table.insert(newCache, v)
					end
				end
			end
			weaponCache = newCache
			if not weaponCacheScanning then break end
			task.wait(2)
		end
	end)
end

function stopWeaponScanner()
	weaponCacheScanning = false
	weaponCache = {}
	if weaponCacheConn then
		local success = pcall(function()
			task.cancel(weaponCacheConn)
		end)
		weaponCacheConn = nil
	end
end

-- Config state
configName = "default"

-- Cleanup-safe connection tokens
aimMouseConn = nil
espConn = nil
espPlayerAddedConn = nil

-- ==================== Misc Features ====================

function toggleNoCameraSway()
	local cam = workspace.CurrentCamera
	if not cam then return end
	if noCameraSwayEnabled then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	else
		cam.CameraType = Enum.CameraType.Custom
	end
end

function toggleNoBlur()
	local blur = Lighting:FindFirstChildWhichIsA("BlurEffect")
	if noBlurEnabled then
		if blur then blur.Enabled = false end
	else
		if blur then blur.Enabled = true end
	end
end

function toggleNoFallDamage()
	noFallDamageEnabled = not noFallDamageEnabled
	local humanoid = getHumanoid()
	if not humanoid then return end
	if noFallDamageEnabled then
		noFallDamageConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			if humanoid and humanoid.Health < (humanoid.MaxHealth or 100) then
				local root = getRoot()
				if root and root.Velocity.Y < -50 then
					humanoid:ChangeState(Enum.HumanoidStateType.Landed)
				end
			end
		end)
		doNotify("Misc", "No fall damage enabled.", 3)
	else
		if noFallDamageConn then noFallDamageConn:Disconnect() noFallDamageConn = nil end
		doNotify("Misc", "No fall damage disabled.", 2)
	end
end

function toggleWalkSpeedOverride()
	walkSpeedOverrideEnabled = not walkSpeedOverrideEnabled
	local humanoid = getHumanoid()
	if not humanoid then return end
	if walkSpeedOverrideEnabled then
		walkSpeedConn = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if humanoid.WalkSpeed ~= walkSpeedValue then
				humanoid.WalkSpeed = walkSpeedValue
			end
		end)
		humanoid.WalkSpeed = walkSpeedValue
		doNotify("Misc", "WalkSpeed locked to " .. walkSpeedValue, 3)
	else
		if walkSpeedConn then walkSpeedConn:Disconnect() walkSpeedConn = nil end
		humanoid.WalkSpeed = 16
		doNotify("Misc", "WalkSpeed unlocked (default 16).", 2)
	end
end

function toggleJumpPowerOverride()
	jumpPowerOverrideEnabled = not jumpPowerOverrideEnabled
	local humanoid = getHumanoid()
	if not humanoid then return end
	if jumpPowerOverrideEnabled then
		jumpPowerConn = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
			if humanoid.JumpPower ~= jumpPowerValue then
				humanoid.JumpPower = jumpPowerValue
			end
		end)
		humanoid.JumpPower = jumpPowerValue
		doNotify("Misc", "JumpPower locked to " .. jumpPowerValue, 3)
	else
		if jumpPowerConn then jumpPowerConn:Disconnect() jumpPowerConn = nil end
		humanoid.JumpPower = 50
		doNotify("Misc", "JumpPower unlocked (default 50).", 2)
	end
end

function toggleHighlightSelf()
	highlightSelfEnabled = not highlightSelfEnabled
	local char = getChar()
	if not char then return end
	if highlightSelfEnabled then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(0, 255, 0)
		h.FillTransparency = 0.7
		h.OutlineColor = Color3.fromRGB(255, 255, 255)
		h.OutlineTransparency = 0.3
		h.Name = "SelfHighlight"
		h.Parent = char
	else
		local h = char:FindFirstChild("SelfHighlight")
		if h then h:Destroy() end
	end
	doNotify("Misc", "Self highlight " .. (highlightSelfEnabled and "enabled" or "disabled") .. ".", 3)
end

function toggleGodmode()
	godmodeEnabled = not godmodeEnabled
	if godmodeEnabled then
		local char = getChar()
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = 999999
				hum.Health = 999999
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
				godmodeConn = RunService.Heartbeat:Connect(function()
					if not godmodeEnabled then
						if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
						return
					end
					if hum and hum.Parent then
						if hum.MaxHealth ~= 999999 then hum.MaxHealth = 999999 end
						if hum.Health ~= 999999 then hum.Health = 999999 end
						hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
					else
						if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
						godmodeEnabled = false
						doNotify("Godmode", "Character lost. Disabled.", 3)
						return
					end
				end)
			end
		end
		doNotify("Godmode", "Enabled.", 2)
	else
		local char = getChar()
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = 100
				hum.Health = 100
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			end
		end
		if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
		doNotify("Godmode", "Disabled.", 2)
	end
end

-- ==================== Gun Mods ====================

function applyGunMods()
	if gunModConn then gunModConn:Disconnect() gunModConn = nil end
	if gunCharConn then gunCharConn:Disconnect() gunCharConn = nil end

	if gunRecoilPercent == 0 and not gunNoSpreadEnabled and not gunInfAmmoEnabled and not gunFastReloadEnabled and not gunNoMuzzleFlash and not gunNoShellEject then
		return
	end

	local function applyGunSettings(char)
		if not char then return end

		if gunInfAmmoEnabled or gunFastReloadEnabled then
			for _, tool in ipairs(char:GetChildren() or {}) do
				if tool:IsA("Tool") then
					for _, prop in ipairs({"Ammo", "Magazine", "Clip", "RoundsLeft", "CurrentAmmo", "ReserveAmmo", "Bullets", "Shots"}) do
						local val = tool:FindFirstChild(prop)
						if val and (val:IsA("IntValue") or val:IsA("NumberValue")) then
							val.Value = 999
						end
						if val and val:IsA("Folder") then
							for _, sub in ipairs(val:GetChildren() or {}) do
								if sub:IsA("IntValue") or sub:IsA("NumberValue") then
									sub.Value = 999
								end
							end
						end
					end
				end
			end
		end

		if gunNoMuzzleFlash or gunNoShellEject then
			for _, part in ipairs(char:GetDescendants() or {}) do
				if gunNoMuzzleFlash and (part:IsA("ParticleEmitter") or part:IsA("Beam")) then
					part.Enabled = false
				end
				if gunNoShellEject and (part:IsA("ParticleEmitter") or part:IsA("Trail")) then
					part.Enabled = false
				end
			end
		end
	end

	applyGunSettings(getChar())

	startWeaponScanner()

	gunCharConn = player.CharacterAdded:Connect(function()
		gunLastCFrame = nil
		applyGunSettings(getChar())
	end)

	gunModConn = RunService.RenderStepped:Connect(function()
		if gunRecoilPercent > 0 or gunNoSpreadEnabled or gunInfAmmoEnabled or gunFastReloadEnabled then
			local char = getChar()
			if not char then return end

			for _, v in ipairs(weaponCache) do
				if type(v) == "table" then
					if gunInfAmmoEnabled then
						if v.Ammo or v.CurrentAmmo or v.ClipSize or v.StoredAmmo then
							if v.Ammo then v.Ammo = 999 end
							if v.CurrentAmmo then v.CurrentAmmo = 999 end
							if v.ClipSize then v.ClipSize = 999 end
							if v.StoredAmmo then v.StoredAmmo = 999 end
						end
					end

					if gunNoSpreadEnabled then
						if v.Spread or v.MinSpread or v.MaxSpread or v.BulletSpread then
							if v.Spread then v.Spread = 0 end
							if v.MinSpread then v.MinSpread = 0 end
							if v.MaxSpread then v.MaxSpread = 0 end
							if v.BulletSpread then v.BulletSpread = 0 end
						end
					end

					if gunRecoilPercent > 0 then
						local multiplier = (100 - gunRecoilPercent) / 100
						if v.Recoil or v.KickUp then
							if v.Recoil then v.Recoil = v.Recoil * multiplier end
							if v.KickUp then v.KickUp = v.KickUp * multiplier end
						end
					end
				end
			end

			if gunRecoilPercent > 0 then
				local cam = workspace.CurrentCamera
				if not cam then return end
				local camCFrame = cam.CFrame
				if not gunLastCFrame then
					gunLastCFrame = camCFrame
				else
					local lookDiff = camCFrame.LookVector - gunLastCFrame.LookVector
					if lookDiff.Magnitude > 0.001 then
						if camCFrame.LookVector.Y > gunLastCFrame.LookVector.Y then
							local compensation = gunRecoilPercent / 100
							local newY = camCFrame.LookVector.Y * (1 - compensation)
							local newLook = Vector3.new(
								camCFrame.LookVector.X * (1 - compensation),
								newY,
								camCFrame.LookVector.Z * (1 - compensation)
							).Unit
							cam.CFrame = CFrame.fromMatrix(camCFrame.Position, camCFrame.RightVector, newLook, camCFrame.LookVector)
						end
					end
					gunLastCFrame = cam.CFrame
				end
			end
		end
		if gunFastReloadEnabled then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local success, tracks = pcall(function()
					return hum:GetAnimator():GetPlayingAnimationTracks()
				end)
				if success and tracks then
					for _, track in ipairs(tracks) do
						if track.Name:lower():find("reload") then
							track.Speed = 3
						end
					end
				end
			end
		end
	end)

	doNotify("Gun Mods", "Advanced memory scanners activated.", 3)
end

function toggleGunMods()
	if gunModConn then gunModConn:Disconnect() gunModConn = nil end
	if gunCharConn then gunCharConn:Disconnect() gunCharConn = nil end
	gunLastCFrame = nil
	stopWeaponScanner()
	if gunRecoilPercent > 0 or gunNoSpreadEnabled or gunInfAmmoEnabled or gunFastReloadEnabled or gunNoMuzzleFlash or gunNoShellEject then
		applyGunMods()
	else
		doNotify("Gun Mods", "All disabled.", 2)
	end
end

-- Auto-update check
function checkForUpdates()
	local success, result = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/your-repo/roblox_troll.lua/main/version.txt")
	end)
	if success then
		local latestVersion = result:gsub("%s+", "")
		local currentVersion = "2.0"
		if latestVersion ~= currentVersion then
			Fluent:Notify({
				Title = "Update Available",
				Content = "v" .. currentVersion .. " -> v" .. latestVersion .. "\nDownload new version!",
				Duration = 10
			})
		end
	end
end

-- ==================== Chat ====================

function sendChat(msg)
	local events = replicated:FindFirstChild("DefaultChatSystemChatEvents")
	if events and events:FindFirstChild("SayMessageRequest") then
		events.SayMessageRequest:FireServer(msg, "All")
		return true
	end
	local textChat = game:GetService("TextChatService")
	if textChat.TextChannels and textChat.TextChannels:FindFirstChild("RBXGeneral") then
		textChat.TextChannels.RBXGeneral:SendAsync(msg)
		return true
	end
	return false
end

function toggleChatSpam()
	chatSpamming = not chatSpamming
	if chatSpamming then
		if not chatMsg or chatMsg == "" then
			chatSpamming = false
			doNotify("Chat Spam", "Set a message first.", 3)
			return
		end
		chatConn = RunService.Heartbeat:Connect(function()
			if not chatSpamming then
				chatConn:Disconnect()
				chatConn = nil
				return
			end
			sendChat(chatMsg)
			wait(chatDelay)
		end)
		doNotify("Chat Spam", "Started: '" .. chatMsg .. "'", 2)
	else
		if chatConn then chatConn:Disconnect() chatConn = nil end
		doNotify("Chat Spam", "Stopped.", 2)
	end
end

function toggleNameSpam()
	nameSpamming = not nameSpamming
	if nameSpamming then
		nameSpamConn = RunService.Heartbeat:Connect(function()
			if not nameSpamming then
				nameSpamConn:Disconnect()
				nameSpamConn = nil
				return
			end
			sendChat(nameSpamText)
			wait(0.3)
		end)
		doNotify("Name Spam", "Started.", 2)
	else
		if nameSpamConn then nameSpamConn:Disconnect() nameSpamConn = nil end
		doNotify("Name Spam", "Stopped.", 2)
	end
end

function toggleBackwardsChat()
	backwardsEnabled = not backwardsEnabled
	if backwardsEnabled then
		backwardsConn = RunService.Heartbeat:Connect(function()
			if not backwardsEnabled then
				backwardsConn:Disconnect()
				backwardsConn = nil
				return
			end
			sendChat(string.reverse(backwardsMsg))
			wait(chatDelay)
		end)
		doNotify("Chat Backwards", "Started.", 2)
	else
		if backwardsConn then backwardsConn:Disconnect() backwardsConn = nil end
		doNotify("Chat Backwards", "Stopped.", 2)
	end
end

function toggleBubbleChat()
	bubbleEnabled = not bubbleEnabled
	if bubbleEnabled then
		bubbleConn = RunService.Heartbeat:Connect(function()
			if not bubbleEnabled then
				bubbleConn:Disconnect()
				bubbleConn = nil
				return
			end
			local root = getRoot()
			if root then
				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.new(0, 200, 0, 50)
				billboard.AlwaysOnTop = true
				billboard.StudsOffset = Vector3.new(0, 3, 0)
				billboard.Name = "BubbleChat"
				billboard.Parent = root

				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 1, 0)
				frame.BackgroundTransparency = 0.3
				frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				frame.BorderSizePixel = 0
				frame.Parent = billboard

				local uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = UDim.new(0.3, 0)
				uiCorner.Parent = frame

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -10, 1, -10)
				label.Position = UDim2.new(0, 5, 0, 5)
				label.BackgroundTransparency = 1
				label.Text = bubbleMsg
				label.Font = Enum.Font.SourceSans
				label.TextScaled = true
				label.TextColor3 = Color3.fromRGB(0, 0, 0)
				label.TextWrapped = true
				label.Parent = billboard

				Debris:AddItem(billboard, 3)
			end
			wait(0.5)
		end)
		doNotify("Bubble Chat", "Started.", 2)
	else
		if bubbleConn then bubbleConn:Disconnect() bubbleConn = nil end
		doNotify("Bubble Chat", "Stopped.", 2)
	end
end

function sendFakeAdmin(msg, targetName)
	local events = replicated:FindFirstChild("DefaultChatSystemChatEvents")
	if not events or not events:FindFirstChild("SayMessageRequest") then
		doNotify("Fake Admin", "Chat system not found.", 3)
		return
	end
	if targetName then
		events.SayMessageRequest:FireServer("[ADMIN] " .. targetName .. ": " .. msg, "All")
	else
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				events.SayMessageRequest:FireServer("[ADMIN] " .. plr.Name .. ": " .. msg, "All")
			end
		end
	end
	doNotify("Fake Admin", "Message sent: " .. msg, 2)
end

function sendFakeSystem(msg)
	local events = replicated:FindFirstChild("DefaultChatSystemChatEvents")
	if not events or not events:FindFirstChild("SayMessageRequest") then return end
	events.SayMessageRequest:FireServer(msg, "All")
	doNotify("Fake System", "Message sent.", 2)
end

-- ==================== Movement Features ====================

function toggleFly()
	flyEnabled = not flyEnabled
	if not flyEnabled then
		if flyConn then flyConn:Disconnect() flyConn = nil end
		if flyKeyDownConn then flyKeyDownConn:Disconnect() flyKeyDownConn = nil end
		if flyKeyUpConn then flyKeyUpConn:Disconnect() flyKeyUpConn = nil end
		if flyCharacterRemovingConn then flyCharacterRemovingConn:Disconnect() flyCharacterRemovingConn = nil end
		if flyBg then flyBg:Destroy() flyBg = nil end
		if flyBv then flyBv:Destroy() flyBv = nil end
		-- Zero residual velocity to prevent floating after fly disable
		local root = getRoot()
		if root and root:IsA("BasePart") then
			root.Velocity = Vector3.new(root.Velocity.X, math.min(root.Velocity.Y, 0), root.Velocity.Z)
		end
		-- Sweep for orphaned BodyVelocity/BodyGyro instances from dash/fling
		if root then
			for _, obj in ipairs(root:GetChildren()) do
				if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
					if obj.Name:find("Fly") or obj.Name:find("Dash") or obj.Name:find("Velocity") then
						obj:Destroy()
					end
				end
			end
		end
		doNotify("Fly", "Disabled.", 2)
		return
	end

	local root = getRoot()
	if not root then
		flyEnabled = false
		return
	end
	flyBg = Instance.new("BodyGyro")
	flyBg.P = 9e4
	flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	flyBg.CFrame = root.CFrame
	flyBg.Name = "FlyBodyGyro"
	flyBg.Parent = root

	flyBv = Instance.new("BodyVelocity")
	flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	flyBv.Velocity = Vector3.new(0, 0, 0)
	flyBv.Name = "FlyBodyVelocity"
	flyBv.Parent = root

	local CONTROL = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}

	flyKeyDownConn = uis.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 1 end
		if input.KeyCode == Enum.KeyCode.A then CONTROL.L = 1 end
		if input.KeyCode == Enum.KeyCode.S then CONTROL.B = 1 end
		if input.KeyCode == Enum.KeyCode.D then CONTROL.R = 1 end
		if input.KeyCode == Enum.KeyCode.Space then CONTROL.U = 1 end
		if input.KeyCode == Enum.KeyCode.LeftShift then CONTROL.D = 1 end
	end)
	flyKeyUpConn = uis.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0 end
		if input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0 end
		if input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0 end
		if input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0 end
		if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.LeftShift then CONTROL.D = 0 end
		if input.KeyCode == Enum.KeyCode.Space then CONTROL.U = 0 end
	end)

	local cam = workspace.CurrentCamera
	flyConn = RunService.Heartbeat:Connect(function()
		if not flyEnabled then return end
		if not root or not root.Parent then
			flyEnabled = false
			if flyConn then flyConn:Disconnect() flyConn = nil end
			if flyBg then flyBg:Destroy() flyBg = nil end
			if flyBv then flyBv:Destroy() flyBv = nil end
			return
		end
		local moveDir = cam.CFrame.LookVector * (CONTROL.F - CONTROL.B) + cam.CFrame.RightVector * (CONTROL.R - CONTROL.L)
		moveDir = Vector3.new(moveDir.X, moveDir.Y + (CONTROL.U - CONTROL.D), moveDir.Z)
		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit * flySpeed
		else
			moveDir = Vector3.new(0, 0, 0)
		end
		if flyBv then flyBv.Velocity = moveDir end
		if flyBg then flyBg.CFrame = cam.CFrame end
	end)

	flyCharacterRemovingConn = player.CharacterRemoving:Connect(function()
		flyEnabled = false
		if flyConn then flyConn:Disconnect() flyConn = nil end
		if flyKeyDownConn then flyKeyDownConn:Disconnect() flyKeyDownConn = nil end
		if flyKeyUpConn then flyKeyUpConn:Disconnect() flyKeyUpConn = nil end
		if flyCharacterRemovingConn then flyCharacterRemovingConn:Disconnect() flyCharacterRemovingConn = nil end
		if flyBg then flyBg:Destroy() flyBg = nil end
		if flyBv then flyBv:Destroy() flyBv = nil end
	end)
	doNotify("Fly", "Enabled. W/A/S/D + Space/Shift to fly.", 4)
end

function toggleNoclip()
	noclipEnabled = not noclipEnabled
	if noclipEnabled then
		noclipConn = RunService.Stepped:Connect(function()
			if not noclipEnabled then
				noclipConn:Disconnect() noclipConn = nil
				return
			end
			local char = getChar()
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
		doNotify("Noclip", "Enabled.", 2)
	else
		local char = getChar()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
		doNotify("Noclip", "Disabled.", 2)
	end
end

function toggleSpin()
	spinEnabled = not spinEnabled
	if spinEnabled then
		spinConn = RunService.Heartbeat:Connect(function()
			if not spinEnabled then
				spinConn:Disconnect() spinConn = nil
				return
			end
			local root = getRoot()
			if root then
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
			end
		end)
		doNotify("SpinBot", "Enabled.", 2)
	else
		if spinConn then spinConn:Disconnect() spinConn = nil end
		doNotify("SpinBot", "Disabled.", 2)
	end
end

function toggleBhop()
	bhopEnabled = not bhopEnabled
	if bhopEnabled then
		bhopConn = RunService.Heartbeat:Connect(function()
			if not bhopEnabled then
				bhopConn:Disconnect() bhopConn = nil
				return
			end
			local hum = getHumanoid()
			if hum then
				if hum:GetState() == Enum.HumanoidStateType.Running or hum.FloorMaterial ~= Enum.Material.Air then
					hum.Jump = true
				end
			end
		end)
		doNotify("Bunny Hop", "Enabled.", 2)
	else
		if bhopConn then bhopConn:Disconnect() bhopConn = nil end
		doNotify("Bunny Hop", "Disabled.", 2)
	end
end

function toggleAntiIdle()
	antiIdleEnabled = not antiIdleEnabled
	if not antiIdleEnabled then
		if antiIdleConn then antiIdleConn:Disconnect() antiIdleConn = nil end
		doNotify("Anti-AFK", "Disabled.", 2)
		return
	end
	pcall(function()
		local vu = game:GetService("VirtualUser")
		if player:FindFirstChild("PlayerScripts") then
			for _, v in ipairs(player.PlayerScripts:GetDescendants()) do
				if v:IsA("LocalScript") and v.Source and v.Source:find("Idle") then
					v:Destroy()
				end
			end
		end
		antiIdleConn = RunService.RenderStepped:Connect(function()
			if not antiIdleEnabled then
				if antiIdleConn then antiIdleConn:Disconnect() antiIdleConn = nil end
				return
			end
			vu:Button2Up(Vector2.new(0, 0), player)
		end)
	end)
	doNotify("Anti-AFK", "Enabled.", 2)
end

uis.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if dashEnabled then
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Q then
			local root = getRoot()
			if not root then return end
			local direction = camera.CFrame.LookVector
			local dashVelocity = Instance.new("BodyVelocity")
			dashVelocity.Name = "DashVelocity_" .. randomString(6)
			dashVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			dashVelocity.Velocity = direction * dashSpeed
			dashVelocity.Parent = root
			Debris:AddItem(dashVelocity, dashTime)
			root.Velocity = Vector3.new(0, 0, 0)
		end
	end
end)

function toggleDash()
	dashEnabled = not dashEnabled
	if dashEnabled then
		doNotify("Dash", "Enabled. Press Q/E to dash.", 4)
	else
		local root = getRoot()
		if root then
			local dv = root:FindFirstChildWhichIsA("BodyVelocity")
			if dv then dv:Destroy() end
		end
		doNotify("Dash", "Disabled.", 2)
	end
end

function toggleWallrun()
	wallrunEnabled = not wallrunEnabled
	if wallrunEnabled then
		wallrunConn = RunService.Heartbeat:Connect(function()
			if not wallrunEnabled then
				if wallrunConn then wallrunConn:Disconnect() wallrunConn = nil end
				return
			end
			local root = getRoot()
			if not root then return end
			local humanoid = getHumanoid()
			if not humanoid then return end

			local hitR = findPartFromRayWithIgnoreList(root.Position, root.CFrame.RightVector * 5, {player.Character})
			local hitL = findPartFromRayWithIgnoreList(root.Position, root.CFrame.RightVector * -5, {player.Character})

			if (hitR and hitR.CanCollide) or (hitL and hitL.CanCollide) then
				humanoid.PlatformStand = true
				root.Velocity = root.Velocity + Vector3.new(0, 50, 0)
				root.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
			else
				if humanoid.PlatformStand then
					humanoid.PlatformStand = false
				end
			end
		end)
		doNotify("Wallrun", "Enabled.", 2)
	else
		if wallrunConn then wallrunConn:Disconnect() wallrunConn = nil end
		local humanoid = getHumanoid()
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
		doNotify("Wallrun", "Disabled.", 2)
	end
end

function toggleAirJump()
	airJumpEnabled = not airJumpEnabled
	airJumped = false
	if airJumpEnabled then
		if airJumpConn then airJumpConn:Disconnect() airJumpConn = nil end
		airJumpConn = uis.InputBegan:Connect(function(input)
			if not airJumpEnabled then return end
			if input.KeyCode == Enum.KeyCode.Space then
				local humanoid = getHumanoid()
				if humanoid then
					if not airJumped and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
						humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						airJumped = true
					end
				end
			end
		end)
		doNotify("Air Jump", "Enabled. Jump again in mid-air.", 4)
	else
		if airJumpConn then airJumpConn:Disconnect() airJumpConn = nil end
		airJumped = false
		doNotify("Air Jump", "Disabled.", 2)
	end
end

player.CharacterAdded:Connect(function(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		hum = char:WaitForChild("Humanoid", 5)
	end
	if hum then
		hum.WalkSpeed = walkSpeed
		hum.JumpPower = jumpPower
		if walkSpeedOverrideEnabled then
			hum.WalkSpeed = walkSpeedValue
		end
		if jumpPowerOverrideEnabled then
			hum.JumpPower = jumpPowerValue
		end
		if walkSpeedOverrideEnabled and not walkSpeedConn then
			walkSpeedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if hum.WalkSpeed ~= walkSpeedValue then
					hum.WalkSpeed = walkSpeedValue
				end
			end)
		end
		if jumpPowerOverrideEnabled and not jumpPowerConn then
			jumpPowerConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if hum.JumpPower ~= jumpPowerValue then
					hum.JumpPower = jumpPowerValue
				end
			end)
		end
	end
end)

function doFlashback()
	if not flashbackPos then
		local root = getRoot()
		if root then
			flashbackPos = root.CFrame
			doNotify("Flashback", "Position saved.", 2)
		end
	else
		local root = getRoot()
		if root then
			root.CFrame = flashbackPos
			flashbackPos = nil
			doNotify("Flashback", "Returned to saved position.", 2)
		end
	end
end

-- ==================== Troll Features ====================

function teleportToPosition(x, y, z)
	local root = getRoot()
	if root then
		root.CFrame = CFrame.new(x, y, z)
	end
end

function teleportToPlayer(name)
	local target = findPlayer(name)
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		doNotify("Teleport", "Player not found or not loaded.", 3)
		return
	end
	local root = getRoot()
	local targetRoot = target.Character.HumanoidRootPart
	if root then
		local oldCFrame = root.CFrame
		root.CFrame = targetRoot.CFrame + Vector3.new(0, 8, 0)
		delay(3, function()
			if root and root.Parent then
				root.CFrame = oldCFrame
			end
		end)
		doNotify("Teleport", "Teleported to " .. target.Name .. " (returning in 3s)", 3)
	end
end

function bringPlayer(name)
	local target = findPlayer(name)
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		doNotify("Bring", "Player not found or not loaded.", 3)
		return
	end
	local targetRoot = target.Character.HumanoidRootPart
	local myRoot = getRoot()
	if myRoot and targetRoot then
		targetRoot.CFrame = myRoot.CFrame + Vector3.new(0, 8, 0)
		doNotify("Bring", "Brought " .. target.Name .. " to you.", 2)
	end
end

function orbitPlayer(name)
	local target = findPlayer(name)
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		doNotify("Orbit", "Player not found or not loaded.", 3)
		return
	end
	if orbitConn then orbitConn:Disconnect() end
	local angle = 0
	orbitConn = RunService.Heartbeat:Connect(function()
		if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
			orbitConn:Disconnect()
			return
		end
		local myRoot = getRoot()
		local targetRoot = target.Character.HumanoidRootPart
		if myRoot and targetRoot then
			angle = angle + 0.1 * orbitSpeed / 10
			local offset = CFrame.fromOrientation(0, math.rad(angle), 0) * CFrame.new(0, orbitDist, 0)
			myRoot.CFrame = targetRoot.CFrame * offset
		end
	end)
	doNotify("Orbit", "Orbiting " .. target.Name, 2)
end

function stopOrbit()
	if orbitConn then orbitConn:Disconnect() orbitConn = nil end
	doNotify("Orbit", "Stopped.", 2)
end

function headSitTarget(name)
	local target = findPlayer(name)
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		doNotify("HeadSit", "Player not found or not loaded.", 3)
		return
	end

	local char = getChar()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = true end

	if headSitConn then headSitConn:Disconnect() end
	headSitConn = RunService.Heartbeat:Connect(function()
		if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
			headSitConn:Disconnect()
			return
		end
		local targetRoot = target.Character.HumanoidRootPart
		local myRoot = getRoot()
		if myRoot and targetRoot then
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 1.6, 0.4)
		end
	end)

	target.AncestryChanged:Connect(function(_, parent)
		if not parent and headSitConn then
			headSitConn:Disconnect()
		end
	end)
	doNotify("HeadSit", "Sitting on " .. target.Name .. "'s head.", 2)
end

function stopHeadSit()
	if headSitConn then headSitConn:Disconnect() headSitConn = nil end
	local hum = getHumanoid()
	if hum then hum.Sit = false end
	doNotify("HeadSit", "Stopped.", 2)
end

function freezePlayer(name)
	local target = findPlayer(name)
	if not target or not target.Character then return end
	for _, part in ipairs(target.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	doNotify("Freeze", "Frozen " .. target.Name, 2)
end

function thawPlayer(name)
	local target = findPlayer(name)
	if not target or not target.Character then return end
	for _, part in ipairs(target.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	doNotify("Thaw", "Thawed " .. target.Name, 2)
end

function freezeAll()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			freezePlayer(plr.Name)
		end
	end
	doNotify("Freeze All", "All players frozen.", 2)
end

function thawAll()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			thawPlayer(plr.Name)
		end
	end
	doNotify("Thaw All", "All players thawed.", 2)
end

function startFling()
	if flingEnabled then return end
	flingEnabled = true
	local char = getChar()
	if not char then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0.3, 0.5)
			part.CanCollide = false
		end
	end

	local root = getRoot()
	if root then
		local bav = Instance.new("BodyAngularVelocity")
		bav.Name = "FlingAngularVelocity"
		bav.AngularVelocity = Vector3.new(0, 9999, 0)
		bav.MaxTorque = Vector3.new(0, math.huge, 0)
		bav.P = math.huge
		bav.Parent = root

		local bv = Instance.new("BodyVelocity")
		bv.Name = "FlingVelocity"
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bv.Velocity = Vector3.new(0, 100, 0)
		bv.Parent = root

		flingConn = RunService.Heartbeat:Connect(function()
			if not flingEnabled or not root then return end
			local bv2 = root:FindFirstChild("FlingVelocity")
			if bv2 then
				bv2.Velocity = Vector3.new(0, tick() * 100, 0)
			end
		end)
	end
	doNotify("Fling", "Started.", 2)
end

function stopFling()
	flingEnabled = false
	if flingConn then flingConn:Disconnect() flingConn = nil end
	local char = getChar()
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CustomPhysicalProperties = nil
				part.CanCollide = true
				part.Massless = false
			end
		end
	end
	local root = getRoot()
	if root then
		local bav = root:FindFirstChild("FlingAngularVelocity")
		local bv = root:FindFirstChild("FlingVelocity")
		if bav then bav:Destroy() end
		if bv then bv:Destroy() end
	end
	doNotify("Fling", "Stopped.", 2)
end

function toggleWalkFling()
	walkFlingEnabled = not walkFlingEnabled
	if walkFlingEnabled then
		local char = getChar()
		if not char then
			walkFlingEnabled = false
			return
		end

		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.2, 0.5)
				part.CanCollide = false
			end
		end

		local root = getRoot()
		if root then
			local bav = Instance.new("BodyAngularVelocity")
			bav.Name = "WalkFlingAngular"
			bav.AngularVelocity = Vector3.new(0, 50, 0)
			bav.MaxTorque = Vector3.new(0, 50000, 0)
			bav.P = 1250
			bav.Parent = root
		end

		walkFlingConn = RunService.Heartbeat:Connect(function()
			if not walkFlingEnabled or not root then return end
			local bv = root:FindFirstChild("WalkFlingVelocity") or Instance.new("BodyVelocity")
			bv.Name = "WalkFlingVelocity"
			bv.MaxForce = Vector3.new(50000, 100000, 50000)
			bv.Velocity = Vector3.new(0, 50, 0)
			bv.P = 1250
			bv.Parent = root
		end)
		doNotify("WalkFling", "Started.", 2)
	else
		local root = getRoot()
		if root then
			local bav = root:FindFirstChild("WalkFlingAngular")
			local bv = root:FindFirstChild("WalkFlingVelocity")
			if bav then bav:Destroy() end
			if bv then bv:Destroy() end
		end
		local char = getChar()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CustomPhysicalProperties = nil
					part.CanCollide = true
				end
			end
		end
		doNotify("WalkFling", "Stopped.", 2)
	end
end

function toggleFakeLag()
	fakeLagEnabled = not fakeLagEnabled
	if fakeLagEnabled then
		fakeLagConn = RunService.Heartbeat:Connect(function()
			if not fakeLagEnabled then
				if fakeLagConn then fakeLagConn:Disconnect() end
				local root = getRoot()
				if root then root.Anchored = false end
				return
			end
			local root = getRoot()
			if root then
				root.Anchored = not root.Anchored
			end
			wait(fakeLagInterval)
		end)
		doNotify("Fake Lag", "Started. Others will see you jitter.", 2)
	else
		if fakeLagConn then fakeLagConn:Disconnect() fakeLagConn = nil end
		local root = getRoot()
		if root then root.Anchored = false end
		doNotify("Fake Lag", "Stopped.", 2)
	end
end

function toggleRotationLock()
	rotLockEnabled = not rotLockEnabled
	if rotLockEnabled then
		rotLockConn = RunService.Heartbeat:Connect(function()
			if not rotLockEnabled then
				if rotLockConn then rotLockConn:Disconnect() end
				return
			end
			local root = getRoot()
			if root then
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
			end
		end)
		doNotify("Rotation Lock", "Enabled.", 2)
	else
		if rotLockConn then rotLockConn:Disconnect() rotLockConn = nil end
		doNotify("Rotation Lock", "Disabled.", 2)
	end
end

function toggleSitSpam()
	sitSpamEnabled = not sitSpamEnabled
	if sitSpamEnabled then
		sitSpamConn = RunService.Heartbeat:Connect(function()
			if not sitSpamEnabled then
				if sitSpamConn then sitSpamConn:Disconnect() end
				return
			end
			local hum = getHumanoid()
			if hum then
				hum.Sit = not hum.Sit
			end
			wait(sitSpamInterval)
		end)
		doNotify("Sit Spam", "Started.", 2)
	else
		if sitSpamConn then sitSpamConn:Disconnect() sitSpamConn = nil end
		local hum = getHumanoid()
		if hum then hum.Sit = false end
		doNotify("Sit Spam", "Stopped.", 2)
	end
end

function applyVelocity()
	local root = getRoot()
	if root then
		root.Velocity = Vector3.new(0, velocityAmount, 0)
		doNotify("Velocity", "Applied velocity: " .. velocityAmount, 2)
	end
end

function toggleVelocityLoop()
	if velocityConn then
		velocityConn:Disconnect()
		velocityConn = nil
	end
	local root = getRoot()
	if root then root.Velocity = Vector3.new(0, 0, 0) end
	doNotify("Velocity Loop", "Stopped.", 2)
end

-- This is called as a toggle from UI
local velocityLoopEnabled = false
uis.InputBegan:Connect(function() end) -- placeholder, not used

-- We'll use a separate function for velocity loop toggle
-- Called from UI callback with state already set

function startVelocityLoop()
	if velocityConn then return end
	velocityConn = RunService.Heartbeat:Connect(function()
		if not velocityConn then return end
		applyVelocity()
		wait(0.5)
	end)
	doNotify("Velocity Loop", "Started.", 2)
end

function stopVelocityLoop()
	if velocityConn then velocityConn:Disconnect() velocityConn = nil end
	local root = getRoot()
	if root then root.Velocity = Vector3.new(0, 0, 0) end
	doNotify("Velocity Loop", "Stopped.", 2)
end

function selfTerminate()
	local char = getChar()
	local hum = getHumanoid()
	if hum then
		hum:TakeDamage(math.huge)
	end
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.Velocity = Vector3.new(0, 10000, 0)
		end
	end
	doNotify("Self-Terminate", "Character terminated.", 3)
end

function spawnParticleEffect(effectType)
	local root = getRoot()
	if not root then return end
	local attachment = Instance.new("Attachment")
	attachment.Name = "TrollParticleAttachment"
	attachment.Parent = root

	local particle = Instance.new("ParticleEmitter")
	particle.Name = "TrollEffect"
	particle.Parent = attachment
	particle.Enabled = true

	if effectType == "sparkles" then
		particle.Texture = "rbxassetid://248625108"
		particle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		particle.Size = NumberSequence.new(0.5)
		particle.Transparency = NumberSequence.new(0.2)
		particle.Rate = 100
		particle.Lifetime = NumberRange.new(0.5)
		particle.Speed = NumberRange.new(0)
	elseif effectType == "fire" then
		particle.Texture = "rbxassetid://248625108"
		particle.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 0, 0))
		particle.Size = NumberSequence.new(0.3)
		particle.Transparency = NumberSequence.new(0.2)
		particle.Rate = 100
		particle.Lifetime = NumberRange.new(0.5)
		particle.Speed = NumberRange.new(5, 10)
	elseif effectType == "smoke" then
		particle.Texture = "rbxassetid://263464777"
		particle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		particle.Size = NumberSequence.new(1)
		particle.Transparency = NumberSequence.new(0.5)
		particle.Rate = 50
		particle.Lifetime = NumberRange.new(2)
		particle.Speed = NumberRange.new(1, 3)
	elseif effectType == "heart" then
		particle.Texture = "rbxassetid://258128537"
		particle.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
		particle.Size = NumberSequence.new(0.5)
		particle.Transparency = NumberSequence.new(0.1)
		particle.Rate = 50
		particle.Lifetime = NumberRange.new(1)
	elseif effectType == "spark" then
		particle.Texture = "rbxassetid://258128533"
		particle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 150, 0))
		particle.Size = NumberSequence.new(0.2)
		particle.Transparency = NumberSequence.new(0.1)
		particle.Rate = 200
		particle.Lifetime = NumberRange.new(0.5)
	end

	Debris:AddItem(particle, 3)
	Debris:AddItem(attachment, 3)
end

function toggleSoundSpam()
	soundSpamEnabled = not soundSpamEnabled
	if soundSpamEnabled then
		if not soundId or soundId == "" then
			soundSpamEnabled = false
			doNotify("Sound Spam", "Set a SoundId first.", 3)
			return
		end
		soundObj = Instance.new("Sound")
		soundObj.SoundId = soundId
		soundObj.Volume = soundVolume
		soundObj.Looped = soundLoop
		soundObj.Name = "TrollSound"
		soundObj.Parent = workspace
		soundObj:Play()

		soundConn = RunService.Heartbeat:Connect(function()
			if not soundSpamEnabled then return end
			if not soundObj.IsPlaying then
				soundObj:Play()
			end
		end)
		doNotify("Sound Spam", "Playing sound in workspace (visible to others).", 2)
	else
		if soundConn then soundConn:Disconnect() soundConn = nil end
		if soundObj then soundObj:Destroy() soundObj = nil end
		doNotify("Sound Spam", "Stopped.", 2)
	end
end

function playSoundOnce(sid)
	if not sid or sid == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = sid
	sound.Volume = soundVolume
	sound.Looped = false
	sound.Name = "TrollSoundOnce"
	sound.Parent = workspace
	sound:Play()
	Debris:AddItem(sound, 10)
end

function glitchScreen(duration)
	duration = duration or 2
	local start = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if tick() - start >= duration then
			conn:Disconnect()
			local char = getChar()
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Velocity = Vector3.new(0, 0, 0)
					end
				end
			end
			return
		end
		local root = getRoot()
		if root then
			root.CFrame = root.CFrame + Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
		end
		if camera then
			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(math.random(-5, 5)))
		end
	end)
	doNotify("Glitch", "Effect for " .. duration .. "s.", 2)
end

function toggleHatOverflow()
	hatOverflowEnabled = not hatOverflowEnabled
	if hatOverflowEnabled then
		hatOverflowConn = RunService.Heartbeat:Connect(function()
			if not hatOverflowEnabled then
				if hatOverflowConn then hatOverflowConn:Disconnect() end
				return
			end
			local char = getChar()
			if char then
				local tool = Instance.new("Tool")
				tool.Name = "Hat_" .. randomString(4)
				tool.RequiresHandle = false
				tool.Parent = char
				Debris:AddItem(tool, 1)
			end
			wait(0.1)
		end)
		doNotify("Hat Overflow", "Started.", 2)
	else
		if hatOverflowConn then hatOverflowConn:Disconnect() hatOverflowConn = nil end
		doNotify("Hat Overflow", "Stopped.", 2)
	end
end

function toggleAccessorySpam()
	accessorySpamEnabled = not accessorySpamEnabled
	if accessorySpamEnabled then
		accessorySpamConn = RunService.Heartbeat:Connect(function()
			if not accessorySpamEnabled then
				if accessorySpamConn then accessorySpamConn:Disconnect() end
				return
			end
			local char = getChar()
			if char then
				for _, desc in ipairs(char:GetDescendants()) do
					if desc:IsA("Accessory") and desc:FindFirstChild("Handle") then
						local parent = desc.Parent
						desc.Parent = nil
						desc.Parent = parent
					end
				end
			end
			wait(0.5)
		end)
		doNotify("Accessory Spam", "Started.", 2)
	else
		if accessorySpamConn then accessorySpamConn:Disconnect() accessorySpamConn = nil end
		doNotify("Accessory Spam", "Stopped.", 2)
	end
end

function toggleViewmodelSpam()
	viewmodelSpamEnabled = not viewmodelSpamEnabled
	if viewmodelSpamEnabled then
		viewmodelSpamConn = RunService.Heartbeat:Connect(function()
			if not viewmodelSpamEnabled then
				if viewmodelSpamConn then viewmodelSpamConn:Disconnect() end
				return
			end
			local char = getChar()
			if char then
				local tool = char:FindFirstChildWhichIsA("Tool")
				if tool then
					local clone = tool:Clone()
					clone.Parent = char
					Debris:AddItem(clone, 0.5)
				end
			end
			wait(0.1)
		end)
		doNotify("Viewmodel Spam", "Started.", 2)
	else
		if viewmodelSpamConn then viewmodelSpamConn:Disconnect() viewmodelSpamConn = nil end
		doNotify("Viewmodel Spam", "Stopped.", 2)
	end
end

function toggleFakeAFK()
	fakeAfkEnabled = not fakeAfkEnabled
	if fakeAfkEnabled then
		fakeAfkConn = RunService.Heartbeat:Connect(function()
			if not fakeAfkEnabled then
				if fakeAfkConn then fakeAfkConn:Disconnect() end
				return
			end
			local humanoid = getHumanoid()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				task.wait(0.1)
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
			wait(5)
		end)
		doNotify("Fake AFK", "Enabled.", 2)
	else
		if fakeAfkConn then fakeAfkConn:Disconnect() fakeAfkConn = nil end
		doNotify("Fake AFK", "Disabled.", 2)
	end
end

function fakeKick(msg)
	msg = msg or fakeKickMsg
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FakeKickGui"
	pcall(function() gui.ResetOnDestroy = false end)
	gui.Parent = pg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.ZIndex = 9999
	frame.Parent = gui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0.5, 0)
	label.Position = UDim2.new(0.1, 0, 0.25, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Text = msg
	label.TextWrapped = true
	label.ZIndex = 10000
	label.Parent = gui

	pcall(function()
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
	end)

	delay(10, function()
		if gui and gui.Parent then
			gui:Destroy()
			pcall(function()
				game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
			end)
		end
	end)
	doNotify("Fake Kick", "Displayed kick message.", 2)
end

-- ==================== Animation Features ====================

function startJerk()
	if jerkEnabled then return end
	jerkEnabled = true
	local char = getChar()
	if not char then jerkEnabled = false return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then jerkEnabled = false return end

 	local track = nil
	local jorkin = false
	local function stop()
		jerkEnabled = false
		jorkin = false
		if track then
			track:Stop()
			track = nil
		end
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then jerkEnabled = false return end
	local tool = Instance.new("Tool")
	tool.Name = "Jerk Off"
	tool.ToolTip = "jorking it"
	tool.RequiresHandle = false
	tool.Parent = backpack

	tool.Equipped:Connect(function() jorkin = true end)
	tool.Unequipped:Connect(function() jorkin = false end)
	humanoid.Died:Connect(stop)

	spawn(function()
		while jerkEnabled do
			if not jorkin then
				if not tool.Parent or not char then
					task.wait(0.1)
				end
				if not tool.Parent then
					tool.Parent = backpack or player.Character
				end
				if tool.Parent == char then
					tool:Activate()
				end
				task.wait()
				continue
			end
			local isR15 = r15(player)
			if not track then
				local anim = Instance.new("Animation")
				anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
				track = humanoid:LoadAnimation(anim)
			end
			if track then
				track.Priority = Enum.AnimationPriority.Action
			end
			track:Play()
			track:AdjustSpeed(isR15 and 0.7 or 0.65)
			track.TimePosition = 0.6
			task.wait(0.1)
			while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
			if track then
				track:Stop()
				track = nil
			end
		end
	end)
	doNotify("Jerk", "Started.", 2)
end

function stopJerk()
	jerkEnabled = false
	local char = getChar()
	if char then
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			local tool = backpack:FindFirstChild("Jerk Off")
			if tool then tool:Destroy() end
		end
	end
	doNotify("Jerk", "Stopped.", 2)
end

function playAnimation(animId)
	local humanoid = getHumanoid()
	if not humanoid then return end
	if animTrack then
		animTrack:Stop()
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	animTrack = humanoid:LoadAnimation(anim)
	animTrack:Play()
	doNotify("Animation", "Playing: " .. animId, 3)
end

function stopAnimation()
	if animTrack then
		animTrack:Stop()
		animTrack = nil
		doNotify("Animation", "Stopped.", 2)
	end
end

function toggleAnimLoop(animId)
	if not animId then
		if animLoopEnabled then
			toggleAnimLoop()
		else
			doNotify("Animation Loop", "Enter an Animation ID first.", 3)
		end
		return
	end
	animLoopEnabled = not animLoopEnabled
	if animLoopEnabled then
		local id = animId
		if not id:find("rbxassetid://") then
			id = "rbxassetid://" .. id
		end
		local humanoid = getHumanoid()
		if not humanoid then animLoopEnabled = false return end
		if animTrack then animTrack:Stop() end
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		animTrack = humanoid:LoadAnimation(anim)
		animTrack.Looped = true
		animTrack:Play()
		doNotify("Animation Loop", "Started: " .. id, 2)
	else
		stopAnimation()
		doNotify("Animation Loop", "Stopped.", 2)
	end
end

function emotePlayer(name)
	local target = findPlayer(name)
	if not target or not target.Character or not target.Character:FindFirstChildOfClass("Humanoid") then
		doNotify("Emote", "Player not found.", 3)
		return
	end
	local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local success = pcall(function()
		if humanoid.PerformEmote then
			humanoid:PerformEmote()
		end
	end)

	if not success then
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			task.wait(0.1)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	doNotify("Emote", "Emote triggered on " .. target.Name, 2)
end

local rthroAnims = {
	"rbxassetid://308745760", "rbxassetid://308745904", "rbxassetid://308745904",
	"rbxassetid://308746009", "rbxassetid://308746121", "rbxassetid://308746226",
	"rbxassetid://308746337", "rbxassetid://308746450", "rbxassetid://308746571",
	"rbxassetid://308746730", "rbxassetid://308746835",
}

function toggleRthroSpam()
	rthroSpamEnabled = not rthroSpamEnabled
	if rthroSpamEnabled then
		rthroSpamConn = RunService.Heartbeat:Connect(function()
			if not rthroSpamEnabled then
				if rthroSpamConn then rthroSpamConn:Disconnect() end
				return
			end
			local char = getChar()
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local animId = rthroAnims[math.random(1, #rthroAnims)]
					if animTrack then animTrack:Stop() end
					local anim = Instance.new("Animation")
					anim.AnimationId = animId
					animTrack = humanoid:LoadAnimation(anim)
					animTrack:Play()
				end
			end
			wait(0.3)
		end)
		doNotify("Rthro Spam", "Started.", 2)
	else
		if rthroSpamConn then rthroSpamConn:Disconnect() rthroSpamConn = nil end
		stopAnimation()
		doNotify("Rthro Spam", "Stopped.", 2)
	end
end

-- ==================== Fake Purchase ====================

-- Product type detection and firing table
local purchaseKinds = {
	Product = Enum.InfoType.Product,
	Gamepass = Enum.InfoType.GamePass,
	Asset = Enum.InfoType.Asset,
	Bundle = Enum.InfoType.Bundle,
}

local purchaseFire = {
	Product = function(id)
		ms:SignalPromptProductPurchaseFinished(player.UserId, id, true)
		return "Product"
	end,
	Gamepass = function(id)
		ms:SignalPromptGamePassPurchaseFinished(player, id, true)
		return "Gamepass"
	end,
	Asset = function(id)
		ms:SignalPromptPurchaseFinished(player, id, true)
		return "Asset"
	end,
	Bundle = function(id)
		ms:SignalPromptBundlePurchaseFinished(player, id, true)
		return "Bundle"
	end,
}

local knownKinds = {}
local infoCache = {}

local function getPurchaseInfo(kind, id)
	local key = kind .. ":" .. tostring(id)
	if infoCache[key] ~= nil then
		return infoCache[key]
	end
	local info = false
	if purchaseKinds[kind] and tonumber(id) then
		local ok, res = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(id), purchaseKinds[kind])
		end)
		if ok and type(res) == "table" then
			info = res
		end
	end
	infoCache[key] = info
	return info
end

local function detectPurchaseKind(id)
	local known = knownKinds[tostring(id)]
	if known and purchaseFire[known] then
		return known
	end
	for _, kind in ipairs({"Product", "Gamepass", "Asset"}) do
		if getPurchaseInfo(kind, id) then
			knownKinds[tostring(id)] = kind
			return kind
		end
	end
	return "Product"
end

function fakePurchaseAuto(pid)
	pid = tonumber(pid)
	if not pid then
		doNotify("Fake Purchase", "Invalid Product ID.", 3)
		return nil, nil
	end
	local kind = detectPurchaseKind(pid)
	local ok, res = pcall(function()
		return purchaseFire[kind](pid)
	end)
	if ok and res then
		doNotify("Fake Purchase", "Faked " .. res .. " purchase: " .. pid, 5)
		lastLoggedProductId = tostring(pid)
		return kind, pid
	else
		doNotify("Fake Purchase", "Error: " .. tostring(res), 4)
		return nil, pid
	end
end

function fakeProductPurchase(pid)
	pid = tonumber(pid)
	if not pid then
		doNotify("Fake Purchase", "Invalid Product ID.", 3)
		return
	end
	ms:SignalPromptProductPurchaseFinished(player.UserId, pid, true)
	doNotify("Fake Purchase", "Faked ProductPurchase: " .. pid, 5)
end

function fakeGamepassPurchase(pid)
	pid = tonumber(pid)
	if not pid then
		doNotify("Fake Purchase", "Invalid Product ID.", 3)
		return
	end
	ms:SignalPromptGamePassPurchaseFinished(player, pid, true)
	doNotify("Fake Purchase", "Faked GamePassPurchase: " .. pid, 5)
end

function fakeBulkPurchase(pid)
	pid = tonumber(pid)
	if not pid then
		doNotify("Fake Purchase", "Invalid Product ID.", 3)
		return
	end
	ms:SignalPromptBulkPurchaseFinished(player.UserId, pid, true)
	doNotify("Fake Purchase", "Faked BulkPurchase: " .. pid, 5)
end

function fakePurchaseFinished(pid)
	pid = tonumber(pid)
	if not pid then
		doNotify("Fake Purchase", "Invalid Product ID.", 3)
		return
	end
	ms:SignalPromptPurchaseFinished(player.UserId, pid, true)
	doNotify("Fake Purchase", "Faked PurchaseFinished: " .. pid, 5)
end

-- Purchase scanning helpers (from improved purchase faker)
local function httpRequest()
	return (typeof(request) == "function" and request)
		or (typeof(http_request) == "function" and http_request)
		or (syn and syn.request)
		or (http and http.request)
		or (fluxus and fluxus.request)
end

local function getJsonFromUrl(url)
	local body
	local hr = httpRequest()
	if hr then
		local ok, res = pcall(hr, {Url = url, Method = "GET"})
		if ok and type(res) == "table" and (res.StatusCode == 200 or (res.StatusCode == nil and res.Success)) then
			body = res.Body
		end
	end
	if not body then
		local ok, res = pcall(function()
			return game:HttpGet(url)
		end)
		if ok then
			body = res
		end
	end
	if type(body) ~= "string" or body == "" then
		return nil
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	return ok and data or nil
end

local function commas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

function scanGamePasses()
	local all = {}
	for _, host in ipairs({"apis.roblox.com", "apis.roproxy.com"}) do
		local url = ("https://%s/game-passes/v1/universes/%d/game-passes?passView=Full&pageSize=100"):format(host, game.GameId)
		local data = getJsonFromUrl(url)
		if data and type(data.gamePasses) == "table" then
			for _, p in ipairs(data.gamePasses) do
				local priceInfo = type(p.priceInformation) == "table" and p.priceInformation or {}
				local id = p.id or p.gamePassId
				if id then
					knownKinds[tostring(id)] = "Gamepass"
					table.insert(all, {
						id = id,
						name = p.displayName or p.name,
						price = p.price or priceInfo.defaultPriceInRobux or priceInfo.price,
						icon = nil,
						kind = "Gamepass",
					})
				end
			end
		end
		if #all > 0 then break end
	end
	return all
end

function scanDeveloperProducts()
	local ok, pages = pcall(function()
		return MarketplaceService:GetDeveloperProductsAsync()
	end)
	if not ok or not pages then return {} end
	local out = {}
	for _ = 1, 50 do
		local okPage, page = pcall(function()
			return pages:GetCurrentPage()
		end)
		if not okPage then break end
		for _, item in ipairs(page) do
			local iconId = item.IconImageAssetId
			local id = item.ProductId or item.DeveloperProductId
			if id then
				knownKinds[tostring(id)] = "Product"
				table.insert(out, {
					id = id,
					name = item.Name or item.DisplayName,
					price = item.PriceInRobux,
					icon = iconId and iconId ~= 0 and "rbxassetid://" .. iconId or nil,
					kind = "Product",
				})
			end
		end
		if pages.IsFinished or not pcall(function() pages:AdvanceToNextPageAsync() end) then
			break
		end
	end
	return out
end

local scannedProducts = {}

function refreshScannedProducts(onItemScanned)
	scannedProducts = {}
	-- Clear previous result buttons
	for _, btn in ipairs(scannableItemButtons) do
		if btn and btn.Destroy then
			pcall(function() btn:Destroy() end)
		end
	end
	scannableItemButtons = {}

	local passes = scanGamePasses()
	for _, p in ipairs(passes) do
		table.insert(scannedProducts, p)
	end
	local products = scanDeveloperProducts()
	for _, p in ipairs(products) do
		table.insert(scannedProducts, p)
	end
	lastLoggedProductId = nil
	if #scannedProducts > 0 then
		for _, p in ipairs(scannedProducts) do
			if p.id then
				lastLoggedProductId = tostring(p.id)
				doNotify("Scanner", p.kind .. ": " .. p.name .. " (" .. p.id .. ") R$" .. (p.price or "?"), 5)
				if onItemScanned then
					local btn = onItemScanned(p.name or tostring(p.id), p.id, p.kind, p.price)
					if btn then
						table.insert(scannableItemButtons, btn)
					end
				end
			end
		end
		doNotify("Scanner", "Scanned " .. #scannedProducts .. " items.", 4)
	else
		doNotify("Scanner", "No items found.", 3)
	end
end

-- Supported games list state
supportedGamesLoading = false
supportedGamesCache = {}
supportedGameButtons = {}

local SUPPORTED_URL = "https://loadstring.net/raw/TCiFuJc4kK"

local function clearGameButtons()
	for _, btn in ipairs(supportedGameButtons) do
		if btn and btn.Destroy then
			pcall(function() btn:Destroy() end)
		end
	end
	supportedGameButtons = {}
end

function refreshSupportedGames(onGameFound)
	clearGameButtons()
	supportedGameButtons = {}
	if supportedGamesLoading then
		return
	end
	supportedGamesLoading = true

	local ok, list = pcall(function()
		local code = game:HttpGet(SUPPORTED_URL)
		return loadstring(code)()
	end)

	supportedGamesLoading = false

	if not ok or type(list) ~= "table" then
		doNotify("Supported Games", "Failed to load list.", 3)
		return
	end

	-- Resolve universe IDs and player counts in parallel
	local entries = {}
	for i, entry in ipairs(list) do
		local placeId, name
		if type(entry) == "table" then
			placeId, name = entry.PlaceId or entry[1], entry.Name
		else
			placeId = entry
		end
		placeId = tonumber(placeId)
		if placeId then
			table.insert(entries, {placeId = placeId, name = name, order = i, here = placeId == game.PlaceId})
		end
	end

	-- Parallel fetch universe IDs
	local pending = #entries
	for _, e in ipairs(entries) do
		task.spawn(function()
			local okId, id = pcall(function()
				if e.placeId == game.PlaceId and game.GameId ~= 0 then
					return game.GameId
				end
				local d = getJsonFromUrl(("https://apis.roblox.com/universes/v1/places/%d/universe"):format(e.placeId))
				return tonumber(d and d.universeId)
			end)
			e.universeId = okId and id or nil
			pending -= 1
		end)
	end
	while pending > 0 do task.wait() end

	-- Fetch game stats for player counts
	local universeIds = {}
	for _, e in ipairs(entries) do
		if e.universeId then
			table.insert(universeIds, e.universeId)
		end
	end
	local gameStats = {}
	local i = 1
	while i <= #universeIds do
		local chunk = table.concat(universeIds, ",", i, math.min(i + 49, #universeIds))
		local d = getJsonFromUrl("https://games.roblox.com/v1/games?universeIds=" .. chunk)
		if d and type(d.data) == "table" then
			for _, g in ipairs(d.data) do
				gameStats[tonumber(g.id)] = g
			end
		end
		i += 50
	end

	for _, e in ipairs(entries) do
		local g = e.universeId and gameStats[e.universeId]
		local price = ""
		if e.here then
			price = "You're in this game!"
		elseif g then
			price = (g.playing or "?") .. " playing"
			if e.name then
				e.name = e.name
			elseif g.name then
				e.name = g.name
			end
		else
			price = "Offline"
		end
		if onGameFound then
			local btn = onGameFound(e.name or ("Place " .. e.placeId), e.placeId, price, e.here)
			if btn then
				table.insert(supportedGameButtons, btn)
			end
		end
		if e.here then
			doNotify("Supported Games", "You're in a supported game!", 4)
		end
	end
	doNotify("Supported Games", "Loaded " .. #supportedGameButtons .. " games.", 4)
end

function togglePurchaseLogger()
	purchaseLoggerEnabled = not purchaseLoggerEnabled
	if purchaseLoggerEnabled then
		purchaseLoggerConn = ms.PromptProductPurchaseFinished:Connect(function(plr, purchasedId, wasPurchased)
			local playerName = "Unknown"
			if typeof(plr) == "Instance" and plr:IsA("Player") then
				playerName = plr.Name
			elseif typeof(plr) == "string" then
				playerName = plr
			end
			lastLoggedProductId = tostring(purchasedId or 0)
			local entry = playerName .. " - Product: " .. lastLoggedProductId .. " - " .. tostring(wasPurchased or false)
			table.insert(purchaseLogs, entry)
			doNotify("Purchase Log", entry, 8)
		end)
		doNotify("Purchase Logger", "Enabled. Listening for events.", 4)
	else
		if purchaseLoggerConn then purchaseLoggerConn:Disconnect() purchaseLoggerConn = nil end
		doNotify("Purchase Logger", "Disabled.", 2)
	end
end

-- ==================== UI: Combat ====================
combatSection1 = CombatTab:AddSection("Aimbot")
combatSection2 = CombatTab:AddSection("Aimbot Settings")
combatSection6 = CombatTab:AddSection("Crosshair")

-- ==================== UI: Visuals ====================
visualsSection1 = VisualsTab:AddSection("ESP")

combatSection1:AddToggle("Aimbot", {
	Title = "Aimbot",
	Description = "Lock onto nearest target (Exunys Aimbot V3)",
	Default = false,
	Callback = function(state)
		toggleAimbot(state)
	end
})

combatSection1:AddButton({
	Title = "Set Aim Key",
	Description = "Click then press a key/mouse button",
	Callback = function()
		setAimKey()
	end
})

combatSection2:AddToggle("Toggle Mode", {
	Title = "Toggle Mode",
	Description = "Hold (off) or Toggle (on)",
	Default = false,
	Callback = function(state)
		aimKeyMode = state and "toggle" or "hold"
		if Aimbot_Settings then
			Aimbot_Settings.Toggle = state
		end
	end
})

combatSection2:AddToggle("Draw FOV", {
	Title = "Draw FOV",
	Description = "Show field of view circle",
	Default = true,
	Callback = function(state)
		aimFovEnabled = state
		if Aimbot_FOV then
			Aimbot_FOV.Radius = state and aimFovRadius or 0
		end
	end
})

combatSection2:AddSlider("FOV Radius", {
	Title = "FOV Radius",
	Description = "Aim assistance range (px)",
	Min = 10,
	Max = 720,
	Default = 120,
	Callback = function(value)
		aimFovRadius = value
		if aimFovEnabled and Aimbot_FOV then
			Aimbot_FOV.Radius = value
		end
	end,
		Rounding = 0,
})

combatSection2:AddSlider("Sensitivity", {
	Title = "Sensitivity",
	Description = "Lower = smoother aim (CFrame)",
	Min = 0,
	Max = 100,
	Default = 10,
	Callback = function(value)
		aimSmoothness = math.clamp(value / 100, 0.01, 1.0)
		if Aimbot_Settings then
			Aimbot_Settings.Sensitivity = aimSmoothness
		end
	end,
	Rounding = 0,
})

combatSection2:AddSlider("Prediction", {
	Title = "Prediction",
	Description = "Lead target (offset increment)",
	Min = 0,
	Max = 50,
	Default = 7,
	Callback = function(value)
		aimPrediction = value / 100
		if Aimbot_Settings then
			Aimbot_Settings.OffsetToMoveDirection = aimPrediction > 0
			Aimbot_Settings.OffsetIncrement = aimPrediction
		end
	end,
	Rounding = 0,
})

combatSection2:AddDropdown("Aim Part", {
	Title = "Aim Part",
	Description = "Body part to aim at",
	Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"},
	Default = "Head",
	Callback = function(value)
		aimPart = value
		if Aimbot_Settings then
			Aimbot_Settings.LockPart = value
		end
	end
})

combatSection2:AddToggle("Team Check", {
	Title = "Team Check",
	Description = "Don't target teammates",
	Default = true,
	Callback = function(state)
		aimTeamCheck = state
		if Aimbot_DeveloperSettings then
			if state then
				Aimbot_DeveloperSettings.TeamCheckOption = Aimbot_DeveloperSettings.TeamCheckOption or "Team"
			else
				Aimbot_DeveloperSettings.TeamCheckOption = "None"
			end
		end
	end
})

combatSection2:AddToggle("Alive Check", {
	Title = "Alive Check",
	Description = "Don't target dead players",
	Default = true,
	Callback = function(state)
		aimAliveCheck = state
	end
})

combatSection2:AddToggle("Wall Check", {
	Title = "Wall Check",
	Description = "Don't target occluded players",
	Default = false,
	Callback = function(state)
		aimWallCheck = state
	end
})

combatSection1:AddDropdown("Lock Mode", {
	Title = "Lock Mode",
	Description = "Aim lock method",
	Values = {"CFrame", "mousemoveabs", "mousemoverel"},
	Default = "CFrame",
	Callback = function(value)
		if Aimbot_Settings then
			if value == "CFrame" then
				Aimbot_Settings.LockMode = 1
			elseif value == "mousemoveabs" then
				Aimbot_Settings.LockMode = 3
			else
				Aimbot_Settings.LockMode = 3
			end
		end
	end
})

combatSection1:AddButton({
	Title = "Blacklist Player",
	Description = "Add player to blacklist (ignore)",
	Callback = function()
		if not ExunysLoaded then return end
		local playerName = Fluent.flags["BlacklistInput"] or ""
		if playerName == "" then
			doNotify("Blacklist", "Enter a player name first.", 2)
			return
		end
		local success = pcall(Aimbot.Blacklist, Aimbot, playerName)
		if success then
			doNotify("Blacklist", "Added: " .. playerName, 2)
		else
			doNotify("Blacklist", "Failed to blacklist: " .. playerName, 2)
		end
	end
})

combatSection1:AddInput("BlacklistInput", {
	Title = "Player Name",
	Description = "Player to blacklist",
	Placeholder = "Username",
	Callback = function(value) end
})

combatSection1:AddButton({
	Title = "Whitelist Player",
	Description = "Add player to whitelist",
	Callback = function()
		if not ExunysLoaded then return end
		local playerName = Fluent.flags["WhitelistInput"] or ""
		if playerName == "" then
			doNotify("Whitelist", "Enter a player name first.", 2)
			return
		end
		local success = pcall(Aimbot.Whitelist, Aimbot, playerName)
		if success then
			doNotify("Whitelist", "Added: " .. playerName, 2)
		else
			doNotify("Whitelist", "Failed to whitelist: " .. playerName, 2)
		end
	end
})

combatSection1:AddInput("WhitelistInput", {
	Title = "Player Name",
	Description = "Player to whitelist",
	Placeholder = "Username",
	Callback = function(value) end
})

visualsSection1:AddToggle("ESP", {
	Title = "ESP",
	Description = "Show enemy name, health, and outline (Exunys ESP)",
	Default = false,
	Callback = function(state)
		espEnabled = state
		if ESP_Settings then
			ESP_Settings.Enabled = state
		end
		if state then
			doNotify("ESP", "Enabled.", 2)
		else
			doNotify("ESP", "Disabled.", 2)
		end
	end
})

visualsSection1:AddToggle("Team Check", {
	Title = "Team Check",
	Description = "Don't show ESP for teammates",
	Default = true,
	Callback = function(state)
		espTeamCheck = state
		if ESP_DeveloperSettings then
			ESP_DeveloperSettings.TeamCheckOption = state and "Team" or "None"
		end
	end
})

visualsSection1:AddSlider("Render Distance", {
	Title = "Max Distance",
	Description = "Max distance to show ESP (studs)",
	Min = 100,
	Max = 2000,
	Default = 1000,
	Callback = function(value)
		espMaxDistance = value
		if ESP_Properties and ESP_Properties.ESP then
			ESP_Properties.ESP.MaxDistance = value
		end
	end,
	Rounding = 0
})

visualsSection1:AddColorpicker("ESP Color", {
	Title = "Name Color",
	Description = "ESP text color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(value)
		if ESP_Properties and ESP_Properties.ESP then
			ESP_Properties.ESP.Color = value
		end
	end
})

visualsSection1:AddToggle("Highlight", {
	Title = "Highlight",
	Description = "Show character highlights",
	Default = false,
	Callback = function(state)
		if ESP_Properties and ESP_Properties.Highlight then
			ESP_Properties.Highlight.Enabled = state
		end
	end
})

visualsSection1:AddToggle("Skeleton", {
	Title = "Skeleton",
	Description = "Show bone connections",
	Default = false,
	Callback = function(state)
		if ESP_Properties and ESP_Properties.Skeleton then
			ESP_Properties.Skeleton.Enabled = state
		end
	end
})

visualsSection1:AddToggle("Box", {
	Title = "Box",
	Description = "Show bounding box (Square)",
	Default = false,
	Callback = function(state)
		if ESP_Properties and ESP_Properties.Box then
			ESP_Properties.Box.Enabled = state
		end
	end
})

visualsSection1:AddToggle("Health Bar", {
	Title = "Health Bar",
	Description = "Show health bar",
	Default = false,
	Callback = function(state)
		if ESP_Properties and ESP_Properties.HealthBar then
			ESP_Properties.HealthBar.Enabled = state
		end
	end
})

-- ESP Developer Settings
visualsSection2 = VisualsTab:AddSection("ESP Developer Settings")

visualsSection2:AddDropdown("ESP Update Mode", {
	Title = "Update Mode",
	Description = "How often ESP updates",
	Values = {"RenderStepped", "Heartbeat", "Stepped"},
	Default = "RenderStepped",
	Callback = function(value)
		if ESP_DeveloperSettings then
			ESP_DeveloperSettings.UpdateMode = value
		end
	end
})

visualsSection2:AddDropdown("ESP Team Check", {
	Title = "Team Check Option",
	Description = "Method for team detection",
	Values = {"TeamColor", "Team"},
	Default = "TeamColor",
	Callback = function(value)
		if ESP_DeveloperSettings then
			ESP_DeveloperSettings.TeamCheckOption = value
		end
	end
})

visualsSection2:AddSlider("ESP Rainbow Speed", {
	Title = "Rainbow Speed",
	Description = "Speed of rainbow color cycling",
	Min = 1,
	Max = 30,
	Default = 5,
	Callback = function(value)
		if ESP_DeveloperSettings then
			ESP_DeveloperSettings.RainbowSpeed = value / 10
		end
	end,
	Rounding = 0,
})

visualsSection2:AddToggle("ESP Throttle", {
	Title = "Throttle Updates",
	Description = "Reduce ESP update frequency to save FPS",
	Default = false,
	Callback = function(state)
		if ESP_DeveloperSettings then
			ESP_DeveloperSettings.Throttle = state
		end
	end
})

-- Aimbot Developer Settings (in Combat tab)
combatSection3 = CombatTab:AddSection("Aimbot Developer")

combatSection3:AddDropdown("Aimbot Update Mode", {
	Title = "Update Mode",
	Description = "How often aimbot updates",
	Values = {"RenderStepped", "Heartbeat", "Stepped"},
	Default = "RenderStepped",
	Callback = function(value)
		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.UpdateMode = value
		end
	end
})

combatSection3:AddDropdown("Aimbot Team Check", {
	Title = "Team Check Option",
	Description = "Method for team detection",
	Values = {"TeamColor", "Team"},
	Default = "TeamColor",
	Callback = function(value)
		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.TeamCheckOption = value
		end
	end
})

combatSection3:AddSlider("Aimbot Rainbow Speed", {
	Title = "Rainbow Speed",
	Description = "FOV circle rainbow speed",
	Min = 1,
	Max = 30,
	Default = 10,
	Callback = function(value)
		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.RainbowSpeed = value / 10
		end
	end,
	Rounding = 0,
})

combatSection3:AddButton({
	Title = "Restart Aimbot",
	Description = "Reinitialize the aimbot module",
	Callback = function()
		if ExunysLoaded and Aimbot.Restart then
			pcall(Aimbot.Restart)
		end
	end
})

combatSection3:AddButton({
	Title = "Restart ESP",
	Description = "Reinitialize the ESP module",
	Callback = function()
		if ExunysLoaded and ESP.Restart then
			pcall(ESP.Restart)
		end
	end
})

combatSection6:AddToggle("Crosshair", {
	Title = "Crosshair",
	Description = "Draw custom crosshair (Exunys ESP)",
	Default = false,
	Callback = function(state)
		toggleCrosshair(state)
	end
})

combatSection6:AddSlider("Crosshair Size", {
	Title = "Crosshair Size",
	Description = "Size in pixels",
	Min = 4,
	Max = 24,
	Default = 8,
	Callback = function(value)
		crosshairSize = value
		if Crosshair then
			Crosshair.Size = value
		end
		if crosshairEnabled then drawCrosshair() end
	end,
	Rounding = 0,
})

combatSection6:AddColorpicker("Crosshair Color", {
	Title = "Crosshair Color",
	Description = "Color for crosshair",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(value)
		crosshairColor = value
		if Crosshair then
			Crosshair.Color = value
		end
	end
})

combatSection6:AddToggle("Dynamic Crosshair", {
	Title = "Dynamic Crosshair",
	Description = "Crosshair follows mouse movement",
	Default = true,
	Callback = function(state)
		crosshairDynamic = state
		if crosshairEnabled then drawCrosshair() end
	end
})

combatSection6:AddToggle("Center Dot", {
	Title = "Center Dot",
	Description = "Enable center dot on crosshair",
	Default = CenterDot and CenterDot.Enabled,
	Callback = function(state)
		if CenterDot then
			CenterDot.Enabled = state
		end
	end
})

combatSection6:AddSlider("Center Dot Size", {
	Title = "Center Dot Size",
	Description = "Radius of center dot",
	Min = 1,
	Max = 10,
	Default = CenterDot and CenterDot.Radius or 2,
	Callback = function(value)
		if CenterDot then
			CenterDot.Radius = value
		end
	end,
	Rounding = 0,
})

combatSection6:AddColorpicker("Center Dot Color", {
	Title = "Center Dot Color",
	Description = "Color of center dot",
	Default = Color3.fromRGB(0, 255, 0),
	Callback = function(value)
		if CenterDot then
			CenterDot.Color = value
		end
	end
})

-- Combat: Extended UI
triggerSection1 = TriggerTab:AddSection("Trigger Bot")

triggerSection1:AddToggle("Trigger Bot", {
	Title = "Trigger Bot",
	Description = "Auto-shoot when cursor hovers target (Exunys)",
	Default = false,
	Callback = function(state)
		toggleTriggerBot(state)
	end
})

triggerSection1:AddButton({
	Title = "Set Trigger Key",
	Description = "Click then press a key/mouse button",
	Callback = function()
		setTriggerKey()
	end
})

triggerSection1:AddInput("Trigger Delay", {
	Title = "Trigger Delay",
	Description = "Seconds before shot",
	Placeholder = "0",
	Callback = function(value)
		local val = tonumber(value)
		if val then
			triggerBotDelay = val
			if Triggerbot then
				Triggerbot.Delay = val
			end
		end
	end
})

triggerSection1:AddSlider("Hit Chance", {
	Title = "Hit Chance",
	Description = "Chance to fire (1-100). Note: Exunys Triggerbot has no native hit chance; this is informational.",
	Min = 1,
	Max = 100,
	Default = 100,
	Callback = function(value)
		aimHitChance = value
	end,
	Rounding = 0,
})

-- ==================== UI: Movement Extended ====================
movementSection4 = MovementTab:AddSection("Advanced Movement")

movementSection4:AddToggle("Infinite Jump", {
	Title = "Infinite Jump",
	Description = "Jump infinitely in air",
	Default = false,
	Callback = function(state)
		if infiniteJumpEnabled ~= state then toggleInfiniteJump() end
	end
})

movementSection4:AddToggle("Anti-Stun", {
	Title = "Anti-Stun",
	Description = "Prevent knockback",
	Default = false,
	Callback = function(state)
		if antiStunEnabled ~= state then toggleAntiStun() end
	end
})

-- ==================== UI: Troll Extended ====================
trollSection6 = TrollTab:AddSection("Extended Troll")

trollSection6:AddToggle("Chat Visible", {
	Title = "Chat Visible",
	Description = "Monitor and display chat events",
	Default = false,
	Callback = function(state)
		if chatVisibleEnabled ~= state then toggleChatVisible() end
	end
})

trollSection6:AddToggle("Gravity Control", {
	Title = "Gravity Control",
	Description = "Change workspace gravity",
	Default = false,
	Callback = function(state)
		if gravityEnabled ~= state then toggleGravity() end
	end
})

trollSection6:AddInput("Gravity Value", {
	Title = "Gravity Value",
	Description = "Workspace.Gravity value",
	Placeholder = "192.22",
	Callback = function(value)
		local val = tonumber(value)
		if val then
			gravityValue = val
			if gravityEnabled then toggleGravity(); toggleGravity() end
		end
	end
})

trollSection6:AddInput("Time of Day", {
	Title = "Time of Day",
	Description = "ClockTime (0-24)",
	Placeholder = "12",
	Callback = function(value)
		local val = tonumber(value)
		if val then setTimeOfDay(val) end
	end
})

trollSection6:AddButton({
	Title = "Fake Disconnect",
	Description = "Show fake disconnect screen",
	Callback = function()
		toggleFakeDisconnect()
	end
})

-- ==================== UI: Settings Extended ====================
settingsSection3 = SettingsTab:AddSection("Config")
settingsSection4 = SettingsTab:AddSection("Performance")

settingsSection3:AddInput("Config Name", {
	Title = "Config Name",
	Description = "Name for saving/loading configs",
	Placeholder = "default",
	Callback = function(value) configName = value end
})

settingsSection3:AddButton({
	Title = "Save Config",
	Description = "Save current settings",
	Callback = function() saveConfig() end
})

settingsSection3:AddButton({
	Title = "Load Config",
	Description = "Load saved settings",
	Callback = function() loadConfig() end
})

settingsSection4:AddToggle("Performance Stats", {
	Title = "Performance Stats",
	Description = "Show FPS and ping overlay",
	Default = false,
	Callback = function(state)
		if perfStatsEnabled ~= state then togglePerfStats() end
	end
})

settingsSection4:AddButton({
	Title = "Check for Updates",
	Description = "Check if newer version exists",
	Callback = function() checkForUpdates() end
})

-- ==================== UI: Movement Tab ====================
movementSection1 = MovementTab:AddSection("Movement Tech")
movementSection2 = MovementTab:AddSection("Player Stats")
movementSection3 = MovementTab:AddSection("Position")

movementSection1:AddToggle("Fly", {
	Title = "Fly",
	Description = "W/A/S/D + Space/Shift to fly",
	Default = false,
	Callback = function(state)
		if flyEnabled ~= state then toggleFly() end
	end
})

movementSection1:AddSlider("Fly Speed", {
	Title = "Fly Speed",
	Description = "Units per second",
	Min = 10,
	Max = 300,
	Default = 60,
	Callback = function(value) flySpeed = value end,
		Rounding = 0,
	})

movementSection1:AddToggle("Noclip", {
	Title = "Noclip",
	Description = "Walk through walls",
	Default = false,
	Callback = function(state)
		if noclipEnabled ~= state then toggleNoclip() end
	end
})

movementSection1:AddToggle("SpinBot", {
	Title = "SpinBot",
	Description = "Rotate rapidly (visible to others)",
	Default = false,
	Callback = function(state)
		if spinEnabled ~= state then toggleSpin() end
	end
})

movementSection1:AddToggle("Bunny Hop", {
	Title = "Bunny Hop",
	Description = "Auto-jump on ground contact",
	Default = false,
	Callback = function(state)
		if bhopEnabled ~= state then toggleBhop() end
	end
})

movementSection1:AddSlider("Spin Speed", {
	Title = "Spin Speed",
	Description = "Degrees per frame",
	Min = 10,
	Max = 500,
	Default = 180,
	Callback = function(value) spinSpeed = value end,
		Rounding = 0,
	})

movementSection1:AddToggle("Anti-AFK", {
	Title = "Anti-AFK",
	Description = "Prevent idle kick",
	Default = false,
	Callback = function(state)
		if antiIdleEnabled ~= state then toggleAntiIdle() end
	end
})

movementSection1:AddToggle("Dash", {
	Title = "Dash",
	Description = "Press Q/E to dash (customizable)",
	Default = false,
	Callback = function(state)
		dashEnabled = state
		if state then
			doNotify("Dash", "Enabled. Press Q/E to dash.", 4)
		end
	end
})

movementSection1:AddInput("Dash Speed", {
	Title = "Dash Speed",
	Description = "Units per second",
	Placeholder = "100",
	Callback = function(value)
		local val = tonumber(value)
		if val then dashSpeed = val end
	end
})

movementSection1:AddInput("Dash Duration", {
	Title = "Dash Duration",
	Description = "Seconds",
	Placeholder = "0.3",
	Callback = function(value)
		local val = tonumber(value)
		if val then dashTime = val end
	end
})

movementSection1:AddToggle("Wallrun", {
	Title = "Wallrun",
	Description = "Run along walls (visible to others)",
	Default = false,
	Callback = function(state)
		if wallrunEnabled ~= state then toggleWallrun() end
	end
})

movementSection1:AddToggle("Air Jump", {
	Title = "Air Jump",
	Description = "Double jump in mid-air",
	Default = false,
	Callback = function(state)
		if airJumpEnabled ~= state then toggleAirJump() end
	end
})

movementSection2:AddSlider("WalkSpeed", {
	Title = "WalkSpeed",
	Description = "Player movement speed",
	Min = 0,
	Max = 200,
	Default = 16,
	Callback = function(value)
		walkSpeed = value
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = value end
	end,
		Rounding = 0,
	})

movementSection2:AddSlider("JumpPower", {
	Title = "JumpPower",
	Description = "Player jump height",
	Min = 0,
	Max = 500,
	Default = 50,
	Callback = function(value)
		jumpPower = value
		local hum = getHumanoid()
		if hum then hum.JumpPower = value end
	end,
		Rounding = 0,
	})

movementSection3:AddButton({
	Title = "Flashback",
	Description = "Save/return to saved position (toggle)",
	Callback = function() doFlashback() end
})

movementSection3:AddInput("Teleport To Position", {
	Title = "Teleport To Position",
	Description = "x, y, z",
	Placeholder = "0,100,0",
	Callback = function(value)
		local parts = string.split(value:gsub("%s+", ""), ",")
		if #parts >= 3 then
			teleportToPosition(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]))
		end
	end
})

-- ==================== UI: Troll Tab ====================
local teleportPlayerName = ""
local bringPlayerName = ""
local orbitPlayerName = ""
local headSitName = ""
local freezePlayerName = ""
local thawPlayerName = ""
local emotePlayerName = ""

trollSection1 = TrollTab:AddSection("Targeting")
trollSection2 = TrollTab:AddSection("Physics")
trollSection3 = TrollTab:AddSection("Chat Troll")
trollSection4 = TrollTab:AddSection("Visual Troll")
trollSection5 = TrollTab:AddSection("Misc Troll")

trollSection1:AddInput("Teleport To Player", {
	Title = "Teleport To Player",
	Description = "Player name (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) teleportPlayerName = value end
})
trollSection1:AddButton({
	Title = "Teleport",
	Callback = function() teleportToPlayer(teleportPlayerName) end
})

trollSection1:AddInput("Bring Player", {
	Title = "Bring Player",
	Description = "Force move player to your position (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) bringPlayerName = value end
})
trollSection1:AddButton({
	Title = "Bring",
	Callback = function() bringPlayer(bringPlayerName) end
})

trollSection1:AddInput("Orbit Player", {
	Title = "Orbit Player",
	Description = "Orbit around a player (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) orbitPlayerName = value end
})
trollSection1:AddButton({
	Title = "Orbit",
	Callback = function() orbitPlayer(orbitPlayerName) end
})

trollSection1:AddButton({
	Title = "Stop Orbit",
	Callback = function() stopOrbit() end
})

trollSection1:AddInput("HeadSit", {
	Title = "HeadSit",
	Description = "Sit on a player's head (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) headSitName = value end
})
trollSection1:AddButton({
	Title = "HeadSit",
	Callback = function() headSitTarget(headSitName) end
})

trollSection1:AddButton({
	Title = "Stop HeadSit",
	Callback = function() stopHeadSit() end
})

trollSection2:AddButton({
	Title = "Toggle Fling",
	Description = "Spin and collide with players",
	Callback = function()
		if flingEnabled then stopFling() else startFling() end
	end
})

trollSection2:AddButton({
	Title = "Toggle WalkFling",
	Description = "Movement-based fling",
	Callback = function() toggleWalkFling() end
})

trollSection2:AddToggle("Fake Lag", {
	Title = "Fake Lag",
	Description = "Simulate network issues (visible)",
	Default = false,
	Callback = function(state)
		if fakeLagEnabled ~= state then toggleFakeLag() end
	end
})

trollSection2:AddInput("Lag Interval", {
	Title = "Lag Interval",
	Description = "Seconds between anchor toggles",
	Placeholder = "0.1",
	Callback = function(value)
		local val = tonumber(value)
		if val then fakeLagInterval = val end
	end
})

trollSection2:AddButton({
	Title = "Start Fake Lag",
	Description = "Manually start fake lag",
	Callback = function()
		if not fakeLagEnabled then toggleFakeLag() end
	end
})

	trollSection2:AddButton({
	Title = "Stop Fake Lag",
	Description = "Manually stop fake lag",
	Callback = function()
		if fakeLagEnabled then toggleFakeLag() end
	end
})

trollSection2:AddToggle("Rotation Lock", {
	Title = "Rotation Lock",
	Description = "Constantly spin (visible)",
	Default = false,
	Callback = function(state)
		if rotLockEnabled ~= state then toggleRotationLock() end
	end
})

trollSection2:AddSlider("Rotation Speed", {
	Title = "Rotation Speed",
	Description = "Degrees per frame",
	Min = 10,
	Max = 500,
	Default = 180,
	Callback = function(value) spinSpeed = value end,
		Rounding = 0,
	})

trollSection2:AddToggle("Sit Spam", {
	Title = "Sit Spam",
	Description = "Rapid sit toggle (visible)",
	Default = false,
	Callback = function(state)
		if sitSpamEnabled ~= state then toggleSitSpam() end
	end
})

trollSection2:AddInput("Sit Spam Interval", {
	Title = "Sit Spam Interval",
	Description = "Seconds between sits",
	Placeholder = "0.1",
	Callback = function(value)
		local val = tonumber(value)
		if val then sitSpamInterval = val end
	end
})

trollSection2:AddInput("Velocity Amount", {
	Title = "Velocity Amount",
	Description = "Velocity to apply (use Apply Velocity button below)",
	Placeholder = "500",
	Callback = function(value)
		local val = tonumber(value)
		if val then velocityAmount = val end
	end
})

trollSection2:AddButton({
	Title = "Apply Velocity",
	Description = "Apply velocity to your character",
	Callback = function() applyVelocity() end
})

trollSection2:AddToggle("Velocity Loop", {
	Title = "Velocity Loop",
	Description = "Continuously apply velocity",
	Default = false,
	Callback = function(state)
		if state then
			startVelocityLoop()
		else
			stopVelocityLoop()
		end
	end
})

trollSection2:AddButton({
	Title = "Freeze All",
	Description = "Freeze every other player",
	Callback = function() freezeAll() end
})

trollSection2:AddButton({
	Title = "Thaw All",
	Description = "Thaw every other player",
	Callback = function() thawAll() end
})

trollSection2:AddInput("Freeze Player", {
	Title = "Freeze Player",
	Description = "Freeze specific player (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) freezePlayerName = value end
})
trollSection2:AddButton({
	Title = "Freeze",
	Callback = function() freezePlayer(freezePlayerName) end
})

trollSection2:AddInput("Thaw Player", {
	Title = "Thaw Player",
	Description = "Thaw specific player (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) thawPlayerName = value end
})
trollSection2:AddButton({
	Title = "Thaw",
	Callback = function() thawPlayer(thawPlayerName) end
})

trollSection2:AddButton({
	Title = "Self-Terminate",
	Description = "Kill your character (ragdoll)",
	Callback = function() selfTerminate() end
})

trollSection3:AddInput("Chat Message", {
	Title = "Chat Message",
	Description = "Message to spam",
	Placeholder = "Get rekt!",
	Callback = function(value) chatMsg = value end
})

trollSection3:AddInput("Spam Delay", {
	Title = "Spam Delay",
	Description = "Seconds between messages",
	Placeholder = "0.2",
	Callback = function(value)
		local val = tonumber(value)
		if val then chatDelay = val end
	end
})

trollSection3:AddToggle("Chat Spam", {
	Title = "Chat Spam",
	Description = "Spam the message above",
	Default = false,
	Callback = function(state)
		if chatSpamming ~= state then toggleChatSpam() end
	end
})

trollSection3:AddInput("Fake Admin", {
	Title = "Fake Admin",
	Description = "targetName|message  or  just message",
	Placeholder = "PlayerName|You got trolled!",
	Callback = function(value)
		local pName, msg = string.match(value, "^([^|]+)|(.+)$")
		if pName and msg then
			sendFakeAdmin(msg, pName)
		else
			sendFakeAdmin(value)
		end
	end
})

trollSection3:AddInput("Fake System Message", {
	Title = "Fake System Message",
	Description = "Send system-like message",
	Placeholder = "Game shutting down in 5 minutes!",
	Callback = function(value) sendFakeSystem(value) end
})

trollSection3:AddInput("Name Spam Text", {
	Title = "Name Spam Text",
	Description = "Text for rapid chat spam",
	Placeholder = "[ADMIN] TROLL",
	Callback = function(value) nameSpamText = value end
})

trollSection3:AddToggle("Name Spam", {
	Title = "Name Spam",
	Description = "Rapid chat spam",
	Default = false,
	Callback = function(state)
		if nameSpamming ~= state then toggleNameSpam() end
	end
})

trollSection3:AddInput("Backwards Message", {
	Title = "Backwards Message",
	Description = "Message to send reversed",
	Placeholder = "Get rekt!",
	Callback = function(value) backwardsMsg = value end
})

trollSection3:AddToggle("Chat Backwards", {
	Title = "Chat Backwards",
	Description = "Spam reversed messages",
	Default = false,
	Callback = function(state)
		if backwardsEnabled ~= state then toggleBackwardsChat() end
	end
})

trollSection3:AddInput("Bubble Chat Message", {
	Title = "Bubble Chat Message",
	Description = "Text for 3D bubbles",
	Placeholder = "Bubble spam",
	Callback = function(value) bubbleMsg = value end
})

trollSection3:AddToggle("Bubble Chat", {
	Title = "Bubble Chat",
	Description = "Spawn 3D chat bubbles",
	Default = false,
	Callback = function(state)
		if bubbleEnabled ~= state then toggleBubbleChat() end
	end
})

trollSection4:AddInput("Particle Effect", {
	Title = "Particle Effect",
	Description = "sparkles, fire, smoke, heart, spark",
	Placeholder = "sparkles",
	Callback = function(value) spawnParticleEffect(value) end
})

trollSection4:AddInput("Sound ID", {
	Title = "Sound ID",
	Description = "Roblox asset ID for sound",
	Placeholder = "rbxassetid://12222077",
	Callback = function(value)
		local id = value:match("(%d+)")
		if id then soundId = "rbxassetid://" .. id end
	end
})

trollSection4:AddSlider("Sound Volume", {
	Title = "Sound Volume",
	Description = "0 to 100",
	Min = 0,
	Max = 100,
	Default = 50,
	Callback = function(value)
		soundVolume = value / 100
		if soundObj then soundObj.Volume = soundVolume end
	end,
		Rounding = 0,
	})

trollSection4:AddToggle("Sound Loop", {
	Title = "Sound Loop",
	Description = "Sound loops continuously",
	Default = true,
	Callback = function(state)
		soundLoop = state
		if soundObj then soundObj.Looped = state end
	end
})

trollSection4:AddToggle("Sound Spam", {
	Title = "Sound Spam",
	Description = "Play sound in workspace (visible)",
	Default = false,
	Callback = function(state)
		if soundSpamEnabled ~= state then toggleSoundSpam() end
	end
})

trollSection4:AddInput("Glitch Duration", {
	Title = "Glitch Duration",
	Description = "Seconds of glitch effect",
	Placeholder = "2",
	Callback = function(value)
		local val = tonumber(value)
		if val then glitchScreen(val) end
	end
})

trollSection4:AddButton({
	Title = "Glitch Screen",
	Description = "Trigger screen glitch",
	Callback = function() glitchScreen(2) end
})

trollSection5:AddToggle("Hat Overflow", {
	Title = "Hat Overflow",
	Description = "Spam tool creation (visible)",
	Default = false,
	Callback = function(state)
		if hatOverflowEnabled ~= state then toggleHatOverflow() end
	end
})

trollSection5:AddToggle("Accessory Spam", {
	Title = "Accessory Spam",
	Description = "Rapidly re-parent accessories (visible)",
	Default = false,
	Callback = function(state)
		if accessorySpamEnabled ~= state then toggleAccessorySpam() end
	end
})

trollSection5:AddToggle("Viewmodel Spam", {
	Title = "Viewmodel Spam",
	Description = "Clone held tool rapidly",
	Default = false,
	Callback = function(state)
		if viewmodelSpamEnabled ~= state then toggleViewmodelSpam() end
	end
})

trollSection5:AddToggle("Fake AFK", {
	Title = "Fake AFK",
	Description = "Appear AFK via state changes",
	Default = false,
	Callback = function(state)
		if fakeAfkEnabled ~= state then toggleFakeAFK() end
	end
})

trollSection5:AddInput("Fake Kick Message", {
	Title = "Fake Kick Message",
	Description = "Custom kick message",
	Placeholder = "You have been kicked...",
	Callback = function(value) fakeKickMsg = value end
})

trollSection5:AddButton({
	Title = "Fake Kick",
	Description = "Display fake kick screen",
	Callback = function() fakeKick() end
})

-- ==================== UI: Animation Tab ====================
animSection1 = AnimationTab:AddSection("Jerk Off")
animSection2 = AnimationTab:AddSection("Animation Player")
animSection3 = AnimationTab:AddSection("Rthro Spam")

animSection1:AddButton({
	Title = "Jerk Off",
	Description = "Play jerk animation (visible to others)",
	Callback = function()
		if jerkEnabled then stopJerk() else startJerk() end
	end
})

animSection1:AddButton({
	Title = "Stop Jerk",
	Callback = function() stopJerk() end
})

animSection2:AddInput("Animation ID", {
	Title = "Animation ID",
	Description = "rbxassetid:// or just asset ID",
	Placeholder = "rbxassetid://72042024",
	Callback = function(value)
		local id = value
		if not value:find("rbxassetid://") then
			id = "rbxassetid://" .. value
		end
		playAnimation(id)
	end
})

animSection2:AddToggle("Loop Animation", {
	Title = "Loop Animation",
	Description = "Enter ID, then toggle to loop",
	Default = false,
	Callback = function(state)
		if animLoopEnabled ~= state then
			toggleAnimLoop()
		end
	end
})

animSection2:AddInput("Loop Animation ID", {
	Title = "Loop Animation ID",
	Description = "Animation to loop",
	Placeholder = "rbxassetid://72042024",
	Callback = function(value)
		local id = value
		if not value:find("rbxassetid://") then
			id = "rbxassetid://" .. value
		end
		if animLoopEnabled then
			stopAnimation()
			animTrack = nil
			animLoopEnabled = false
		end
		toggleAnimLoop(id)
	end
})

animSection2:AddButton({
	Title = "Stop Animation",
	Callback = function() stopAnimation() end
})

animSection2:AddInput("Emote Player", {
	Title = "Emote Player",
	Description = "Force emote on target (partial supported)",
	Placeholder = "PlayerName",
	Callback = function(value) emotePlayerName = value end
})
animSection2:AddButton({
	Title = "Trigger Emote",
	Callback = function() emotePlayer(emotePlayerName) end
})

animSection2:AddButton({
	Title = "Reset Animation",
	Description = "Reset character's animation",
	Callback = function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid:LoadAnimation():Stop()
		end
	end
})

animSection3:AddToggle("Rthro Spam", {
	Title = "Rthro Spam",
	Description = "Random R15 animations (visible to others)",
	Default = false,
	Callback = function(state)
		if rthroSpamEnabled ~= state then toggleRthroSpam() end
	end
})

animSection3:AddButton({
	Title = "Stop Rthro Spam",
	Callback = function()
		rthroSpamEnabled = false
		if rthroSpamConn then rthroSpamConn:Disconnect() rthroSpamConn = nil end
		stopAnimation()
		doNotify("Rthro Spam", "Stopped.", 2)
	end
})

-- ==================== UI: Shop Tab ====================
shopSection1 = ShopTab:AddSection("Fake Purchase")
shopSection2 = ShopTab:AddSection("Purchase Scanner")

-- State for dynamic scan result buttons
local scannableItemButtons = {}

shopSection1:AddInput("Product ID", {
	Title = "Product ID",
	Description = "Roblox product ID",
	Placeholder = "12345678",
	Callback = function(value) productId = value end
})

shopSection1:AddButton({
	Title = "Purchase Item",
	Description = "Fire all purchase signal types for this ID",
	Callback = function() fakePurchaseAuto(productId) end
})

-- Auto-purchase state
autoPurchaseEnabled = false
autoPurchaseConn = nil

shopSection1:AddToggle("Auto-Purchase", {
	Title = "Auto-Purchase",
	Description = "Auto-fake purchases on prompt",
	Default = false,
	Callback = function(state)
		autoPurchaseEnabled = state
		if state then
			autoPurchaseConn = ms.PromptProductPurchaseRequested:Connect(function(plr, pid)
				if plr == player then
					fakePurchaseAuto(pid)
				end
			end)
			local gpConn = ms.PromptGamePassPurchaseRequested:Connect(function(plr, gpId)
				if plr == player then
					fakeGamepassPurchase(gpId)
				end
			end)
			local pConn = ms.PromptPurchaseRequested:Connect(function(plr, assetId)
				if plr == player then
					fakePurchaseFinished(assetId)
				end
			end)
			local bConn = ms.PromptBundlePurchaseRequested:Connect(function(plr, bundleId)
				if plr == player then
					fakePurchaseFinished(bundleId)
				end
			end)
			_G._autoPurchaseConns = {gpConn, pConn, bConn}
			doNotify("Auto-Purchase", "Listening for purchase prompts.", 3)
		else
			if autoPurchaseConn then autoPurchaseConn:Disconnect() autoPurchaseConn = nil end
			if _G._autoPurchaseConns then
				for _, c in ipairs(_G._autoPurchaseConns) do
					pcall(function() c:Disconnect() end)
				end
				_G._autoPurchaseConns = nil
			end
			doNotify("Auto-Purchase", "Stopped.", 2)
		end
	end
})

shopSection2:AddButton({
	Title = "Scan Products",
	Description = "Scan game for passes and products",
	Callback = function()
		refreshScannedProducts(function(name, id, kind, price)
			local priceText = price and (" R$" .. price) or ""
			return shopSection2:AddButton({
				Title = name .. " - " .. id .. priceText,
				Description = "Click to copy ID | " .. kind,
				Callback = function()
					pcall(function()
						setclipboard(tostring(id))
					end)
					lastLoggedProductId = tostring(id)
					doNotify("Scanner", "Copied ID: " .. id .. " (" .. kind .. ")", 3)
				end
			})
		end)
	end
})

shopSection2:AddButton({
	Title = "Clear Results",
	Description = "Clear all scanned items",
	Callback = function()
		for _, btn in ipairs(scannableItemButtons) do
			if btn and btn.Destroy then
				pcall(function() btn:Destroy() end)
			end
		end
		scannableItemButtons = {}
		doNotify("Scanner", "Results cleared.", 2)
	end
})

-- ==================== UI: Supported Games ====================
shopSection3 = ShopTab:AddSection("Supported Games")

shopSection3:AddButton({
	Title = "Refresh Game List",
	Description = "Load supported games list",
	Callback = function()
		refreshSupportedGames(function(name, placeId, priceText, isHere)
			return shopSection3:AddButton({
				Title = name,
				Description = "PlaceID: " .. placeId .. " | " .. priceText,
				Callback = function()
					if placeId == game.PlaceId then
						doNotify("Supported Games", "You're already in this game!", 3)
					else
						pcall(function()
							TeleportService:Teleport(placeId, player)
						end)
						doNotify("Supported Games", "Teleporting to " .. name .. "...", 3)
					end
				end
			})
		end)
	end
})

shopSection3:AddButton({
	Title = "Clear Game List",
	Description = "Clear all game buttons",
	Callback = function()
		clearGameButtons()
		doNotify("Supported Games", "List cleared.", 2)
	end
})

-- ==================== UI: Settings Tab ====================
settingsSection1 = SettingsTab:AddSection("UI Settings")
settingsSection2 = SettingsTab:AddSection("Quick Actions")

settingsSection1:AddButton({
	Title = "Set Menu Toggle Key",
	Description = "Click then press a key to toggle the menu",
	Callback = function()
		Fluent:Notify({ Title = "Menu Key", Content = "Press any key within 5 seconds.", Duration = 5 })
		local con
		con = uis.InputBegan:Connect(function(input)
			if input.UserInputState == Enum.UserInputState.Begin then
				menuToggleKey = input.KeyCode
				con:Disconnect()
				if Window then
					Window.MinimizeKey = menuToggleKey
				end
				Fluent:Notify({ Title = "Menu Key", Content = "Set to: " .. tostring(input.KeyCode), Duration = 3 })
			end
		end)
		delay(5, function() if con.Connected then con:Disconnect() end end)
	end
})

settingsSection1:AddToggle("Dark Theme", {
	Title = "Dark Theme",
	Description = "Use dark Fluent theme",
	Default = true,
	Callback = function(state)
		if Fluent and Fluent.SetTheme then
			Fluent:SetTheme(state and "Dark" or "Light")
		end
	end
})

settingsSection1:AddSlider("UI Transparency", {
	Title = "UI Transparency",
	Description = "Window background transparency",
	Min = 0,
	Max = 50,
	Default = 10,
	Callback = function(value)
		if Fluent and Fluent.SetTransparency then
			Fluent:SetTransparency(value / 100)
		end
	end,
		Rounding = 0,
	})

settingsSection2:AddButton({
	Title = "Unload Script",
	Description = "Remove all effects and close UI",
	Callback = function()
		chatSpamming = false
		nameSpamming = false
		backwardsEnabled = false
		bubbleEnabled = false
		flingEnabled = false
		walkFlingEnabled = false
		fakeLagEnabled = false
		rotLockEnabled = false
		sitSpamEnabled = false
		hatOverflowEnabled = false
		accessorySpamEnabled = false
		viewmodelSpamEnabled = false
		fakeAfkEnabled = false
		soundSpamEnabled = false
		rthroSpamEnabled = false
		animLoopEnabled = false
 		purchaseLoggerEnabled = false
		aimbotEnabled = false
		espEnabled = false
		aimToggleState = false
		triggerBotEnabled = false
		crosshairEnabled = false
		silentAimEnabled = false
		gunRecoilPercent = 0
		gunNoSpreadEnabled = false
		gunInfAmmoEnabled = false
		gunFastReloadEnabled = false
		gunNoMuzzleFlash = false
		gunNoShellEject = false
		infiniteJumpEnabled = false
		antiStunEnabled = false
		chatVisibleEnabled = false
		gravityEnabled = false
		fakeDisconnectEnabled = false
		flashbackPos = nil
		if aimConn then aimConn:Disconnect() end
		aimConn = nil
		if aimMouseConn and aimMouseConn.Connected then aimMouseConn:Disconnect() end
		aimMouseConn = nil
		if fovCircle then
			if Drawing then fovCircle:Remove() else fovCircle:Destroy() end
		end
		fovCircle = nil
		if espConn and espConn.Connected then espConn:Disconnect() end
		espConn = nil
		if espPlayerAddedConn and espPlayerAddedConn.Connected then espPlayerAddedConn:Disconnect() end
		espPlayerAddedConn = nil
		for plr, cache in pairs(espInstances) do
			if cache.BillboardGui then cache.BillboardGui:Destroy() end
			if cache.Highlight then cache.Highlight:Destroy() end
		end
		espInstances = {}

		if noclipConn then noclipConn:Disconnect() noclipConn = nil end
		noclipEnabled = false
		if spinConn then spinConn:Disconnect() spinConn = nil end
		spinEnabled = false
		flyEnabled = false
		if flyConn then flyConn:Disconnect() flyConn = nil end
		if flyKeyDownConn then flyKeyDownConn:Disconnect() flyKeyDownConn = nil end
		if flyKeyUpConn then flyKeyUpConn:Disconnect() flyKeyUpConn = nil end
		if flyCharacterRemovingConn then flyCharacterRemovingConn:Disconnect() flyCharacterRemovingConn = nil end
		if flyBg then flyBg:Destroy() flyBg = nil end
		if flyBv then flyBv:Destroy() flyBv = nil end
		-- Sweep orphaned BodyVelocity/BodyGyro from character on unload
		local root = getRoot()
		if root then
			for _, obj in ipairs(root:GetChildren()) do
				if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
					obj:Destroy()
				end
			end
		end
		if bhopConn then bhopConn:Disconnect() bhopConn = nil end
		bhopEnabled = false
		if wallrunConn then wallrunConn:Disconnect() wallrunConn = nil end
		wallrunEnabled = false
		if airJumpConn then airJumpConn:Disconnect() airJumpConn = nil end
		airJumpEnabled = false
		if chatConn then chatConn:Disconnect() end
		if nameSpamConn then nameSpamConn:Disconnect() end
		if backwardsConn then backwardsConn:Disconnect() end
		if bubbleConn then bubbleConn:Disconnect() end
		if flingConn then flingConn:Disconnect() end
		if walkFlingConn then walkFlingConn:Disconnect() end
		if fakeLagConn then fakeLagConn:Disconnect() end
		if rotLockConn then rotLockConn:Disconnect() end
		if sitSpamConn then sitSpamConn:Disconnect() end
		if velocityConn then velocityConn:Disconnect() end
		if hatOverflowConn then hatOverflowConn:Disconnect() end
		if accessorySpamConn then accessorySpamConn:Disconnect() end
		if viewmodelSpamConn then viewmodelSpamConn:Disconnect() end
		if fakeAfkConn then fakeAfkConn:Disconnect() end
		if soundConn then soundConn:Disconnect() end
		if rthroSpamConn then rthroSpamConn:Disconnect() end
	if gunModConn then gunModConn:Disconnect() gunModConn = nil end
		if gunCharConn then gunCharConn:Disconnect() gunCharConn = nil end
		stopWeaponScanner()
    	if purchaseLoggerConn then purchaseLoggerConn:Disconnect() purchaseLoggerConn = nil end
		if autoPurchaseConn then autoPurchaseConn:Disconnect() autoPurchaseConn = nil end
		if _G._autoPurchaseConns then
			for _, c in ipairs(_G._autoPurchaseConns) do
				pcall(function() c:Disconnect() end)
			end
			_G._autoPurchaseConns = nil
		end
		autoPurchaseEnabled = false
		if infiniteJumpConn then infiniteJumpConn:Disconnect() infiniteJumpConn = nil end
		if antiStunConn then antiStunConn:Disconnect() antiStunConn = nil end
		if antiIdleConn then antiIdleConn:Disconnect() antiIdleConn = nil end
		if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
		if walkSpeedConn then walkSpeedConn:Disconnect() walkSpeedConn = nil end
		if jumpPowerConn then jumpPowerConn:Disconnect() jumpPowerConn = nil end
		if noFallDamageConn then noFallDamageConn:Disconnect() noFallDamageConn = nil end
		if chatVisibleConn then chatVisibleConn:Disconnect() end
		if gravityConn then gravityConn:Disconnect() end
		if timeConn then timeConn:Disconnect() end
		if perfConn then perfConn:Disconnect() end
		if crosshairConn then crosshairConn:Disconnect() crosshairConn = nil end
		if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end

		if perfGui then perfGui:Destroy() perfGui = nil end
		if perfLabel then perfLabel = nil end
		workspace.Gravity = 192.22
		Lighting.ClockTime = 0

		if soundObj then soundObj:Destroy() end
		stopHeadSit()
		stopOrbit()
		stopJerk()
		stopAnimation()

		local char = getChar()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CustomPhysicalProperties = nil
					part.CanCollide = true
					part.Massless = false
					part.Velocity = Vector3.new(0, 0, 0)
					local bg = part:FindFirstChildWhichIsA("BodyGyro")
					local bv = part:FindFirstChildWhichIsA("BodyVelocity")
					if bg then bg:Destroy() end
					if bv then bv:Destroy() end
				end
				if part:IsA("ParticleEmitter") then
					part:Destroy()
				end
				if part:IsA("Attachment") and part.Name == "TrollParticleAttachment" then
					part:Destroy()
				end
			end
		end

 		local fakeGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("FakeKickGui")
		if fakeGui then fakeGui:Destroy() end
		local fakeDiscGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("FakeDisconnectGui")
		if fakeDiscGui then fakeDiscGui:Destroy() end
			pcall(function()
			game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
		end)

		if silentAimOldNamecall then
			pcall(function()
				hookmetamethod(game, "__namecall", silentAimOldNamecall)
			end)
			silentAimOldNamecall = nil
		end
		silentAimActive = false
		silentAimEnabled = false

		if ExunysLoaded then
			pcall(ESP.Exit, ESP)
			pcall(Aimbot.Exit, Aimbot)
		end

		if Window and Window.Destroy then
			Window:Destroy()
		end
		doNotify("Project Nexus", "Unloaded. Goodbye.", 3)
	end
})

settingsSection2:AddButton({
	Title = "Destroy All Particles",
	Description = "Remove particle effects from self",
	Callback = function()
		local char = getChar()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("ParticleEmitter") then
					part:Destroy()
				end
				if part:IsA("Attachment") and part.Name == "TrollParticleAttachment" then
					part:Destroy()
				end
			end
		end
		doNotify("Clean", "Removed all particles.", 2)
	end
})

settingsSection2:AddButton({
	Title = "Restore Character",
	Description = "Reset character to default state",
	Callback = function()
		player:LoadCharacter()
		flashbackPos = nil
		stopFling()
		doNotify("Restore", "Character reset.", 2)
	end
})

-- ==================== UI: Scripts Tab ====================
local scriptSection1 = ScriptsTab:AddSection("Executor")
local scriptSection2 = ScriptsTab:AddSection("History")

scriptSection1:AddInput("Lua Code", {
	Title = "Lua Code",
	Description = "Enter Lua code to execute",
	Placeholder = "print('hello')",
	Callback = function(value) lastScript = value end
})

scriptSection1:AddButton({
	Title = "Execute",
	Description = "Run the code above",
	Callback = function() executeScript(lastScript) end
})

scriptSection2:AddButton({
	Title = "View History",
	Description = "Print command history to console",
	Callback = function()
		if #scriptHistory == 0 then
			doNotify("Scripts", "History is empty.", 2)
		else
			for _, entry in ipairs(scriptHistory) do
				print("[Scripts] " .. entry)
			end
			doNotify("Scripts", "History printed to console.", 3)
		end
	end
})

scriptSection2:AddButton({
	Title = "Clear History",
	Description = "Clear command history",
	Callback = function() clearScriptHistory() end
})

-- Common Scripts section
scriptSection3 = ScriptsTab:AddSection("Common Scripts")

scriptSection3:AddButton({
	Title = "DEX Explorer",
	Description = "Execute DEX Explorer",
	Callback = function()
		executeScript([[
		local DEX = game:HttpGet("https://raw.githubusercontent.com/ligma-wtf/ligma-wtf/main/Releases/DEX.lua")
		loadstring(DEX)()
		]])
	end
})

scriptSection3:AddButton({
	Title = "Infinite Yield",
	Description = "Execute Infinite Yield admin script",
	Callback = function()
		executeScript([[
		local IY = game:HttpGet("https://raw.githubusercontent.com/EdgeLP/Infinite-Yield/master/source.lua")
		loadstring(IY)()
		]])
	end
})

scriptSection3:AddButton({
	Title = "Simple Spy",
	Description = "Execute Simple Spy v2 (remotes logger)",
	Callback = function()
		executeScript([[
		local SS = game:HttpGet("https://raw.githubusercontent.com/78n/simple-spy-v2/main/SimpleSpy.lua")
		loadstring(SS)()
		]])
	end
})

scriptSection3:AddButton({
	Title = "Dark Dex",
	Description = "Execute Dark Dex v2",
	Callback = function()
		executeScript([[
		local DD = game:HttpGet("https://raw.githubusercontent.com/DarkModFallen/Dark-Dex/main/source.lua")
		loadstring(DD)()
		]])
	end
})

scriptSection3:AddButton({
	Title = "Fate Bootstrap",
	Description = "Execute Fate Admin (universal)",
	Callback = function()
		executeScript([[
		local FB = game:HttpGet("https://raw.githubusercontent.com/Fate-Dev/Fate-Base64/main/FateMain.lua")
		loadstring(FB)()
		]])
	end
})

scriptSection3:AddButton({
	Title = "Load Custom Script",
	Description = "Execute URL in Lua Code box above",
	Callback = function()
		if lastScript and lastScript:match("^https?://") then
			pcall(function()
				local code = game:HttpGet(lastScript)
				executeScript(code)
			end)
		else
			doNotify("Scripts", "Enter a URL or Lua code in the text box.", 3)
		end
	end
})

-- ==================== UI: Misc Tab ====================
miscSection1 = MiscTab:AddSection("Camera")
miscSection2 = MiscTab:AddSection("Movement")
miscSection3 = MiscTab:AddSection("Visual")
miscSection4 = MiscTab:AddSection("Other")

miscSection1:AddSlider("Camera FOV", {
	Title = "Camera FOV",
	Description = "Adjust camera field of view (0 = default)",
	Min = 0,
	Max = 120,
	Default = 0,
	Callback = function(value)
		cameraFovValue = value
		if value > 0 then
			pcall(function() workspace.CurrentCamera.FieldOfView = value end)
		else
			pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
		end
	end,
	Rounding = 0
})

miscSection1:AddToggle("No Camera Sway", {
	Title = "No Camera Sway",
	Description = "Remove camera sway and head bob",
	Default = false,
	Callback = function(state)
		noCameraSwayEnabled = state
		toggleNoCameraSway()
	end
})

miscSection1:AddToggle("No Blur", {
	Title = "No Blur",
	Description = "Disable blur effects",
	Default = false,
	Callback = function(state)
		noBlurEnabled = state
		toggleNoBlur()
	end
})

miscSection2:AddToggle("No Fall Damage", {
	Title = "No Fall Damage",
	Description = "Take no damage from falling",
	Default = false,
	Callback = function(state) toggleNoFallDamage() end
})

miscSection2:AddButton({
	Title = "Lock WalkSpeed",
	Description = "Lock WalkSpeed to current value (16 = default)",
	Callback = function() toggleWalkSpeedOverride() end
})

miscSection2:AddButton({
	Title = "Lock JumpPower",
	Description = "Lock JumpPower to current value (50 = default)",
	Callback = function() toggleJumpPowerOverride() end
})

miscSection3:AddToggle("Highlight Self", {
	Title = "Highlight Self",
	Description = "Glow effect around your character",
	Default = false,
	Callback = function(state)
		highlightSelfEnabled = state
		local char = getChar()
		if not char then return end
		if state then
			if not char:FindFirstChild("SelfHighlight") then
				local h = Instance.new("Highlight")
				h.FillColor = Color3.fromRGB(0, 255, 0)
				h.FillTransparency = 0.7
				h.OutlineColor = Color3.fromRGB(255, 255, 255)
				h.OutlineTransparency = 0.3
				h.Name = "SelfHighlight"
				h.Parent = char
			end
		else
			local h = char:FindFirstChild("SelfHighlight")
			if h then h:Destroy() end
		end
		doNotify("Misc", "Self highlight " .. (state and "enabled" or "disabled") .. ".", 3)
	end
})

miscSection4:AddToggle("Godmode", {
	Title = "Godmode",
	Description = "Infinite health - take no damage",
	Default = false,
	Callback = function(state)
		if godmodeEnabled ~= state then toggleGodmode() end
	end
})

miscSection4:AddToggle("No Fall Damage", {
	Title = "No Fall Damage",
	Description = "Take no damage from falling",
	Default = false,
	Callback = function(state)
		if noFallDamageEnabled ~= state then toggleNoFallDamage() end
	end
})

-- ==================== UI: Gun Mods Tab ====================
gunSection1 = GunModsTab:AddSection("Mods")

gunSection1:AddSlider("Recoil %", {
	Title = "Recoil %",
	Description = "Remove recoil (0-100%)",
	Min = 0,
	Max = 100,
	Default = 0,
	Callback = function(value)
		gunRecoilPercent = value
		toggleGunMods()
	end,
	Rounding = 0
})

gunSection1:AddToggle("No Spread", {
	Title = "No Spread",
	Description = "Remove bullet spread",
	Default = false,
	Callback = function(state)
		gunNoSpreadEnabled = state
		toggleGunMods()
	end
})

gunSection1:AddToggle("Infinite Ammo", {
	Title = "Infinite Ammo",
	Description = "Unlimited ammo and magazines",
	Default = false,
	Callback = function(state)
		gunInfAmmoEnabled = state
		toggleGunMods()
	end
})

gunSection1:AddToggle("Fast Reload", {
	Title = "Fast Reload",
	Description = "Skip/dramatically speed up reload",
	Default = false,
	Callback = function(state)
		gunFastReloadEnabled = state
		toggleGunMods()
	end
})

gunSection1:AddToggle("No Muzzle Flash", {
	Title = "No Muzzle Flash",
	Description = "Hide muzzle flash particles",
	Default = false,
	Callback = function(state)
		gunNoMuzzleFlash = state
		toggleGunMods()
	end
})

gunSection1:AddToggle("No Shell Eject", {
	Title = "No Shell Eject",
	Description = "Hide shell ejection particles",
	Default = false,
		Callback = function(state)
		gunNoShellEject = state
		toggleGunMods()
	end
})

gunSection2 = GunModsTab:AddSection("Silent Aim")

gunSection2:AddToggle("Silent Aim", {
	Title = "Silent Aim",
	Description = "Redirect shots via __namecall hook (Exunys)",
	Default = false,
	Callback = function(state)
		toggleSilentAim(state)
	end
})

gunSection2:AddToggle("SA Team Check", {
	Title = "Team Check",
	Description = "Don't target teammates with silent aim",
	Default = false,
	Callback = function(state)
		silentAimTeamCheck = state
	end
})

gunSection2:AddToggle("Aim At Head", {
	Title = "Primary Target Part",
	Description = "Target player's head for silent aim",
	Default = true,
	Callback = function(state)
		-- Silent aim always targets Head; this toggle is for visual feedback
	end
})

-- ==================== Load ====================
pcall(function() Window:SelectTab(1) end)
-- Fallback: ensure first tab container is visible (in case task.spawn fails)
delay(0.5, function()
    pcall(function()
        local coreGui = game:FindFirstChild("CoreGui") or player:FindFirstChild("PlayerGui")
        if coreGui then
            for _, desc in ipairs(coreGui:GetDescendants() or {}) do
                if desc:IsA("Frame") and desc.Name == "ContainerFrame" then
                    desc.Visible = true
                    break
                end
			end
		end
	end)
end)
doNotify("Project Nexus", "Loaded v2.0. Check all tabs for FE-compatible troll features.", 5)

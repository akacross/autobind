script_name("autobind")
script_description("Autobind Menu")
script_version("1.8.12")
script_authors("akacross")
script_url("https://akacross.net/")

local changelog = {
	["1.8.11"] = {
		"Fixed: Autoaccept now waits if the player is attacked. (You can still be prisoned if you heal while in a gunfight)",
		"Fixed: Autoaccept automatically detects when you are in a point. (You no longer need to manually toggle it, it will deactivate when point ends)" -- WIP
	},
	["1.8.10"] = {
		"Improved: Autovest is much more reliable now and responsive. (I am going to start changelog from here on.)",
	},
	["1.8.09"] = {
		"Initial Rerelease."
	}
}

-- Script Information
local scriptPath = thisScript().path
local scriptName = thisScript().name
local scriptVersion = thisScript().version

-- Dependency Manager
local function safeRequire(module)
    local success, result = pcall(require, module)
    return success and result or nil, result
end

-- Requirements
local dependencies = {
    {name = 'moonloader', var = 'moonloader', extras = {dlstatus = 'download_status'}},
    {name = 'mimgui', var = 'imgui'},
    {name = 'ffi', var = 'ffi'},
    {name = 'samp.events', var = 'sampev'},
    {name = 'memory', var = 'mem'},
    {name = 'vkeys', var = 'vk'},
    {name = 'game.keys', var = 'gkeys'},
    {name = 'windows.message', var = 'wm'},
    {name = 'fAwesome6', var = 'fa'},
    {name = 'encoding', var = 'encoding'}
}

-- Load modules
local loadedModules, statusMessages = {}, {success = {}, failed = {}}
for _, dep in ipairs(dependencies) do
    local loadedModule, errorMsg = safeRequire(dep.name)
    loadedModules[dep.var] = loadedModule
    table.insert(statusMessages[loadedModule and "success" or "failed"], loadedModule and dep.name or string.format("%s (%s)", dep.name, errorMsg))
end

-- Assign loaded modules to local variables
for var, module in pairs(loadedModules) do
    _G[var] = module
end

-- Assign extra fields
for _, dep in ipairs(dependencies) do
    if dep.extras and loadedModules[dep.var] then
        for extraVar, extraField in pairs(dep.extras) do
            _G[extraVar] = loadedModules[dep.var][extraField]
        end
    end
end

-- Print status messages
print("Loaded modules: " .. table.concat(statusMessages.success, ", "))
if #statusMessages.failed > 0 then
    print("Failed to load modules: " .. table.concat(statusMessages.failed, ", "))
end

-- Dynamically set script dependencies based on loaded modules
script_dependencies(table.unpack(statusMessages.success))

-- Encoding
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Get path
local function getPath(type)
    local config = getWorkingDirectory() .. '\\config\\'
    local resource = getWorkingDirectory() .. '\\resource\\'
    local settings = config .. scriptName .. '\\'

    local paths = {
        config = config,
        settings = settings,
        resource = resource,
        skins = resource .. 'skins\\'
    }
    return type and (paths[type] or error("Invalid path type")) or paths
end

-- Get file paths
local function getFile(type)
    local files = {
        settings = getPath('settings') .. 'autobind.json',
        update = getPath('settings') .. 'update.txt',
        skins = getPath('settings') .. 'skins.json',
		names = getPath('settings') .. 'names.json'
    }
    return files[type] or error("Invalid file type")
end

-- Fetch URLs
local function fetchUrls(type, isBeta)
    local baseUrl = "https://raw.githubusercontent.com/akacross/" .. scriptName .. "/main/"
    local subPath = isBeta and "beta/" or ""
    local paths = {
        script = baseUrl .. subPath .. scriptName .. ".lua",
        update = baseUrl .. subPath .. scriptName .. ".txt",
        skins = baseUrl .. "resource/" .. "skins/"
    }
    return paths[type] or error("Invalid URL type")
end

-- Global Variables
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle

-- Define thread variables
local threads = {
	autovest = nil,
	autoaccept = nil,
	captureSpam = nil,
	keybinds = nil
}

-- Screen Resolution
local resX, resY = getScreenResolution()

-- Autobind Config
local autobind = {
	Settings = {},
	AutoBind = {},
	AutoVest = {},
	Window = {},
	Keybinds = {},
	BlackMarket = {},
	FactionLocker = {}
}

-- Default Settings
local autobind_defaultSettings = {
	Settings = {
		enable = true,
		autoSave = true,
		mode = "Family",
		familyFreq = 0,
		familyTurf = false,
		capturePoint = false,
		disableAfterCapturing = true,
		factionFreq = 0,
		factionTurf = false,
		Frisk = {
			target = false,
			mustAim = true
		},
	},
	AutoBind = {
		enable = true,
		autoRepair = true,
		autoBadge = true,
	},
	AutoVest = {
		enable = true,
		everyone = false,
		useSkins = true,
		autoFetchSkins = true,
		autoFetchNames = false,
		donor = false,
		skins = {123},
		names = {"Cross_Maddox"},
		skinsUrl = "https://raw.githubusercontent.com/akacross/autobind/main/skins.json",
		namesUrl = "https://raw.githubusercontent.com/akacross/autobind/main/names.json",
	},
	Window = {
		Pos = {x = resX / 2, y = resY / 2},
		Size = {x = 600, y = 428},
	},
	Keybinds = {
		Accept = {Toggle = true, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}},
		Offer = {Toggle = true, Keys = {VK_MENU, VK_O}, Type = {'KeyDown', 'KeyPressed'}},
		BlackMarket = {Toggle = false, Keys = {VK_MENU, VK_X}, Type = {'KeyDown', 'KeyPressed'}},
		FactionLocker = {Toggle = false, Keys = {VK_MENU, VK_X}, Type = {'KeyDown', 'KeyPressed'}},
		BikeBind = {Toggle = false, Keys = {VK_SHIFT}, Type = {'KeyDown', 'KeyDown'}},
		SprintBind = {Toggle = true, Keys = {VK_F11}, Type = {'KeyPressed'}},
		Frisk = {Toggle = false, Keys = {VK_MENU, VK_F}, Type = {'KeyDown', 'KeyPressed'}},
		TakePills = {Toggle = false, Keys = {VK_F3}, Type = {'KeyPressed'}}
	},
	BlackMarket = {1, 9, 13},
	FactionLocker = {1, 2, 9, 8}
}

-- Commands
local commands = {
	vestnear = "vestnear",
	repairnear = "repairnear",
	sprintbind = "sprintbind",
	bikebind = "bikebind",
	find = "hfind",
	tcap = "turfcap",
	autovest = "autovest",
	autoaccept = "autoaccept",
	ddmode = "donormode",
}

-- Auto Find
local autofind ={
	enable = false,
	playerName = "",
	playerId = -1,
}

-- Capture Spam
local captog = false

-- Key Press Type
local PressType = {KeyDown = isKeyDown, KeyPressed = wasKeyPressed}

-- Timers
local timers = {
	Vest = {timer = 0, last = 0},
	VestCD = {timer = 1.5, last = 0},
	AcceptCD = {timer = 1.5, last = 0},
	Heal = {timer = 12, last = 0},
	Find = {timer = 19.5, last = 0},
	Muted = {timer = 13, last = 0},
	Binds = {timer = 1, last = {}}
}

-- Guard
local guardTime = 13.5
local ddguardTime = 6
local isBodyguard = true

-- Frequency
local currentFamilyFreq = 0
local currentFactionFreq = 0

-- Auto Accept
local autoaccepter = false
local autoacceptertoggle = false
local autoaccepternick = ""

-- Factions
local factions = {
	skins = {
		61, 71, 73, 141, 163, 164, 165, 166, 179, 191, 206, 253, 255, 265, 266, 267, 280, 281, 
		282, 283, 284, 285, 286, 287, 288, 294, 300, 301, 306, 309, 310, 311, 120, 253
	},
	colors = {
		-14269954, -7500289, -14911565, -3368653
	}
}

-- Menu Variables
local menu = {
	settings = new.bool(false),
	pageId = 1,
	skins = new.bool(false),
	blackmarket = new.bool(false),
	factionlocker = new.bool(false)
}

local changekey = {}

-- Dragging Box
local selectedbox = false
local size = {
    {x = 0, y = 0}
}

-- Skin Editor
local skinTexture = {}
local skinEditor = {
	selected = -1,
	page = 1
}

-- Spec State
local specState = false

-- Bike
local bikeIds = {[481] = true, [509] = true, [510] = true}

-- Moto
local motoIds = {
	[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, 
	[521] = true, [522] = true, [523] = true, [581] = true, [586] = true
}

-- Invalid Animations
local invalidAnimsSet = {
    [1158] = true, [1159] = true, [1160] = true, [1161] = true, [1162] = true,
    [1163] = true, [1164] = true, [1165] = true, [1166] = true, [1167] = true,
    [1069] = true, [1070] = true, [746] = true
}

-- Command Data
local cmdData = {
    ["/bm"] = {counter = 0, lastTime = 0},
    ["/locker"] = {counter = 0, lastTime = 0}
}

-- Black Market Variables
local bmbool = false
local bmstate = 0
local bmcmd = 0

-- Locker Variables
local lockerbool = false
local lockerstate = 0
local lockercmd = 0

-- Black Market Equipment Menu
local blackMarketItems = {
    {label = 'Health/Armor', index = 2, weapon = nil}, -- 1
    {label = 'Silenced Pistol', index = 6, weapon = 22}, -- 2
    {label = '9mm Pistol', index = 7, weapon = 23}, -- 3
    {label = 'Shotgun', index = 8, weapon = 25}, -- 4
    {label = 'MP5', index = 9, weapon = 29}, -- 5
    {label = 'UZI', index = 10, weapon = 28}, -- 6
    {label = 'Tec-9', index = 11, weapon = 32}, -- 7
    {label = 'Country Rifle', index = 12, weapon = 33}, -- 8
    {label = 'Deagle', index = 13, weapon = 24}, -- 9
    {label = 'AK-47', index = 14, weapon = 30}, -- 10
    {label = 'M4', index = 15, weapon = 31}, -- 11
    {label = 'Spas-12', index = 16, weapon = 27}, -- 12
    {label = 'Sniper Rifle', index = 17, weapon = 34} -- 13
}

local blackMarketExclusiveGroups = {
	{2, 3, 9},  -- Silenced Pistol, 9mm Pistol, Deagle
	{4, 12},    -- Shotgun, Spas-12
	{5, 6, 7},  -- MP5, UZI, Tec-9
	{8, 13},    -- Country Rifle, Sniper Rifle
	{10, 11}    -- AK-47, M4
}

-- Locker Equipment Menu
local lockerMenuItems = {
	{label = 'Deagle', index = 1},
	{label = 'Shotgun', index = 2},
	{label = 'SPAS-12', index = 3},
	{label = 'MP5', index = 4},
	{label = 'M4', index = 5},
	{label = 'AK-47', index = 6},
	{label = 'Sniper', index = 9},
	{label = 'Armor', index = 10},
	{label = 'Health', index = 11}
}

local lockerExclusiveGroups = {
	{2, 3}, -- Shotgun, SPAS-12
	{5, 6} -- M4, AK-47
}

-- Initialize
function main()
	local paths = getPath(nil)
    for _, dir in pairs({"config", "settings", "resource", "skins"}) do
        createDirectory(paths[dir])
    end

    autobind = handleConfigFile(getFile("settings"), autobind_defaultSettings, autobind, {{"AutoVest", "skins"}, {"AutoVest", "names"}, "Keybinds"})

	if autobind.Settings.mode == "Factions" then
		autobind.Settings.mode = "Faction"
	end

    while not isSampAvailable() do wait(100) end

	sampRegisterChatCommand(scriptName, function()
		menu.pageId = 1
		menu.settings[0] = not menu.settings[0]
	end)

	if autobind.Settings.enable then
		registerChatCommands()
	end

	if autobind.AutoVest.autoFetchSkins then
		fetchDataFromURL(autobind.AutoVest.skinsUrl, 'skins', function(decodedData)
			autobind.AutoVest.skins = decodedData
		end)
	end

	if autobind.AutoVest.autoFetchNames then
		fetchDataFromURL(autobind.AutoVest.namesUrl, 'names', function(decodedData)
			autobind.AutoVest.names = decodedData
		end)
	end

	downloadSkins()

	local startedThreads, failedThreads = createThreads()
	print(string.format("%s v%s has loaded successfully! Threads: %s.", firstToUpper(scriptName), scriptVersion, table.concat(startedThreads, ", ")))
	if #failedThreads > 0 then
		print("Threads failed to start: " .. table.concat(failedThreads, ", "))
	end

	while true do wait(5)
		resumeThreads()
	end
end

-- onD3DPresent
function onD3DPresent()
	if not autobind.Settings.enable or not autobind.Keybinds.SprintBind then
		return
	end

	-- Sprint Bind
	if autobind.Settings.enable and autobind.Keybinds.SprintBind.Toggle and (isButtonPressed(h, gkeys.player.SPRINT) and (isCharOnFoot(ped) or isCharInWater(ped))) then
		setGameKeyState(gkeys.player.SPRINT, 0)
	end
end

-- Get visible players
function getVisiblePlayers(maxDist, type)
    local visiblePlayers = {}
    for _, peds in pairs(getAllChars()) do
        local myX, myY, myZ = getCharCoordinates(ped)
        local playerX, playerY, playerZ = getCharCoordinates(peds)
        local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, myX, myY, myZ)
        if peds ~= ped and distance < maxDist then
            local result, playerId = sampGetPlayerIdByCharHandle(peds)
            if result and not sampIsPlayerPaused(playerId) then
				if sampGetPlayerNickname(playerId):find("_") then
					if (type == "armor" and sampGetPlayerArmor(playerId) < 49) or (type == "car" and not isCharInAnyCar(ped) and isCharInAnyCar(peds)) or (type == "all") then
						table.insert(visiblePlayers, {playerId = playerId, distance = distance})
					end
				end
            end
        end
    end
    table.sort(visiblePlayers, function(a, b) return a.distance < b.distance end)
    return visiblePlayers
end

-- Check if any of the specified menus is active
function activeCheck(chat, dialog, scoreboard, console, pause)
	return (chat and not sampIsChatInputActive()) and 
		   (dialog and not sampIsDialogActive()) and 
		   (scoreboard and not sampIsScoreboardOpen()) and 
		   (console and not isSampfuncsConsoleActive()) and 
		   (pause and not isPauseMenuActive())
end

-- Check if admin duty is active
function checkAdminDuty()
    local _, aduty = getSampfuncsGlobalVar("aduty")
    local _, HideMe = getSampfuncsGlobalVar("HideMe")
	return aduty == 0 and (not specState or HideMe == 0)
end

function toggleBind(bind)
	autobind.Keybinds[bind].Toggle = not autobind.Keybinds[bind].Toggle
	formattedAddChatMessage(string.format("%s: %s", bind, autobind.Keybinds[bind].Toggle and '{008000}on' or '{FF0000}off'))
end

-- Auto Vest
local function checkBodyguardCondition()
    return isBodyguard or autobind.AutoVest.donor
end

local function checkAnimationCondition(playerId)
    local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
    local pAnimId2 = sampGetPlayerAnimationId(playerId)
    return not (invalidAnimsSet[pAnimId] or pAnimId2 == 746 or isButtonPressed(h, gkeys.player.LOCKTARGET))
end

-- Vest Mode Conditions
local function vestModeConditions(playerId)
    if autobind.AutoVest.everyone then
        return true
    end

    for k, v in pairs(autobind.AutoVest.names) do
        if v == sampGetPlayerNickname(playerId) then
            return true
        end
    end

	local result, peds = sampGetCharHandleBySampPlayerId(playerId)
	if not result then
		return false
	end
	
	if autobind.Settings.mode == "Family" then
		return has_number(autobind.AutoVest.skins, getCharModel(peds))
	elseif autobind.Settings.mode == "Faction" then
		local color = convertColor(sampGetPlayerColor(playerId), true, false, false)
		return has_number(factions.colors, joinARGB(255, color[1], color[2], color[3], true)) and 
			(not autobind.AutoVest.useSkins or has_number(factions.skins, getCharModel(peds)))
	end
    return false
end

-- Check muted
function checkMuted()
	if localClock() - timers.Muted.last < timers.Muted.timer then
		return true
	end
	return false
end

-- Reset timer
function resetTimer(additionalTime, timer)
	timer.last = localClock() - (timer.timer - 0.2) + (additionalTime or 0)
end

-- Check and send vest
function checkAndSendVest(prevest)
	if not autobind.Settings.enable then
		return "Autobind is disabled"
	end
    
    if not checkAdminDuty() then
        return
    end

	if not autobind.AutoVest.enable and not prevest then
        return
    end

	if not checkBodyguardCondition() then
		return "You are not a bodyguard."
	end

    local currentTime = localClock()
	if currentTime - timers.VestCD.last < timers.VestCD.timer then
		return
	end

	if checkMuted() then
		return "You have been muted for spamming. Please wait."
	end

    if currentTime - timers.Vest.last < timers.Vest.timer then
        local timeLeft = math.ceil(timers.Vest.timer - (currentTime - timers.Vest.last))
        return string.format("You must wait %d seconds before sending vest.", timeLeft > 1 and timeLeft or 1)
    end

    for _, player in ipairs(getVisiblePlayers(6, prevest and "all" or "armor")) do
        if checkAnimationCondition(player.playerId) then
            if vestModeConditions(player.playerId) then
                sampSendChat(autobind.AutoVest.donor and '/guardnear' or string.format("/guard %d 200", player.playerId))
                timers.VestCD.last = currentTime
				return
            end
        end
    end
	return "No suitable player found to vest."
end

-- Check and accept vest
function checkAndAcceptVest(autoaccept)
	if not autobind.Settings.enable then
		return "Autobind is disabled"
	end

	if not checkAdminDuty() then
        return
    end

	local currentTime = localClock()
	if currentTime - timers.AcceptCD.last < timers.AcceptCD.timer then
		return
	end

	if checkMuted() then
		return "You have been muted for spamming. Please wait."
	end

	if currentTime - timers.Heal.last < timers.Heal.timer then
		local timeLeft = math.ceil(timers.Heal.timer - (currentTime - timers.Heal.last))
		return string.format("You must wait %d seconds before healing.", timeLeft > 1 and timeLeft or 1)
	end

	if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
		for _, player in ipairs(getVisiblePlayers(4, "all")) do
			if autoaccept and autoacceptertoggle then
				if sampGetPlayerNickname(player.playerId) == autoaccepternick then
					sampSendChat("/accept bodyguard")
					timers.AcceptCD.last = currentTime
					return
				end
			end
		end
		return autoacceptertoggle and string.format("You are not close enough to %s.", autoaccepternick:gsub("_", " ")) or "No one offered you bodyguard."
	else
		return "You are already have a vest."
	end
end

-- Threads
local function createAutovestThread()
	timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime

    threads.autovest = coroutine.create(function()
        while true do
            local success, message = pcall(checkAndSendVest, false)
            if not success then
                print("Error in checkAndSendVest: " .. tostring(message))
            end
            coroutine.yield()
        end
    end)
end

local function createAutoacceptThread()
	threads.autoaccept = coroutine.create(function()
		while true do
			local success, message = pcall(checkAndAcceptVest, autoaccepter)
			if not success then
				print("Error in checkAndAcceptVest: " .. tostring(message))
			end
			coroutine.yield()
		end
	end)
end

local function createKeybindThread()
	local function acceptBodyguard()
		local message = checkAndAcceptVest(true)
		if message then
			formattedAddChatMessage(message)
		end
	end
	
	local function offerBodyguard()
		local message = checkAndSendVest(true)
		if message then
			formattedAddChatMessage(message)
		end
	end
	
	local function blackMarket()
		if not bmbool then
			bmbool = true
			sendCommandWithTimer("/bm")
		end
	end
	
	local function factionLocker()
		if not lockerbool then
			lockerbool = true
			sendCommandWithTimer("/locker")
		end
	end
	
	local function bikeBind()
		if isCharOnAnyBike(ped) then
            local veh = storeCarCharIsInNoSave(ped)
            if not isCarInAirProper(veh) then
                if bikeIds[getCarModel(veh)] then
                    setGameKeyUpDown(gkeys.vehicle.ACCELERATE, 255, 0)
                elseif motoIds[getCarModel(veh)] then
                    setGameKeyUpDown(gkeys.vehicle.STEERUP_STEERDOWN, -128, 0)
                end
            end
        end
	end
	
	local function sprintBind()
		toggleBind("SprintBind")
	end
	
	local function frisk()
		if checkAdminDuty() and not checkMuted() then
			local targeting, _ = getCharPlayerIsTargeting(h)
			for _, player in ipairs(getVisiblePlayers(5, "all")) do
				if (isButtonPressed(h, gkeys.player.LOCKTARGET) and autobind.Settings.Frisk.mustAim) or not autobind.Settings.Frisk.mustAim then
					if (targeting and autobind.Settings.Frisk.target) or not autobind.Settings.Frisk.target then
						sampSendChat(string.format("/frisk %d", player.playerId))
						break
					end
				end
			end
		end
	end
	
	local function takePills()
		if checkAdminDuty() and not checkMuted() then
			sampSendChat("/takepills")
		end
	end

    threads.keybinds = coroutine.create(function()
        while true do
            if autobind.Settings.enable then
				local currentTime = localClock()
				local keyFunctions = {
					Accept = acceptBodyguard,
					Offer = offerBodyguard,
					BlackMarket = blackMarket,
					FactionLocker = factionLocker,
					BikeBind = bikeBind,
					SprintBind = sprintBind,
					Frisk = frisk,
					TakePills = takePills
				}
			
				for key, value in pairs(autobind.Keybinds) do
					local bind = {
						keys = value.Keys,
						type = value.Type
					}
			
					if keycheck(bind) and (value.Toggle or key == "BikeBind" or key == "SprintBind") then
						if activeCheck(true, true, true, true, true) and not menu.settings[0] then
							if key == "BikeBind" or not timers.Binds.last[key] or (currentTime - timers.Binds.last[key]) >= timers.Binds.timer then
								local success, error = pcall(keyFunctions[key])
								if not success then
									print(string.format("Error in %s function: %s", key, error))
								end
								timers.Binds.last[key] = currentTime
							end
						end
					end
				end
			end
			coroutine.yield()
        end
    end)
end

local function createCaptureSpamThread()
    local lastCaptureTime = 0
    local captureInterval = 1.5

    local function captureSpam()
        local currentTime = localClock()
        if currentTime - lastCaptureTime >= captureInterval then
            sampSendChat("/capturf")
            lastCaptureTime = currentTime
        end
    end

    threads.captureSpam = coroutine.create(function()
        while true do
            if autobind.Settings.enable and captog and not checkMuted() and checkAdminDuty() then
				print("Capturing spam")
                local status, err = pcall(captureSpam)
                if not status then
                    print("Error in capture spam thread: " .. err)
                end
            end
            coroutine.yield()
        end
    end)
end

-- Resume threads
function resumeThreads()
    for threadName, thread in pairs(threads) do
        if thread then
            local status = coroutine.status(thread)
            if status == "suspended" then
                local success, result = pcall(coroutine.resume, thread)
                if not success then
                    print(string.format("Error resuming thread '%s': %s", threadName, result))
                end
            elseif status == "dead" then
                print(string.format("Thread '%s' has finished execution", threadName))
                threads[threadName] = nil  -- Remove dead thread from the table
            else
                print(string.format("Thread '%s' is in an unexpected state: %s", threadName, status))
            end
        end
    end
end

-- Create threads
function createThreads()
	createAutovestThread()
	createAutoacceptThread()
	createKeybindThread()
	createCaptureSpamThread()

	local startedThreads = {}
	local failedThreads = {}
	for name, thread in pairs(threads) do
		if thread and coroutine.status(thread) == "suspended" then
			table.insert(startedThreads, name)
		else
			table.insert(failedThreads, name)
		end
	end

	return startedThreads, failedThreads
end

function toggleCaptureSpam()
	captog = not captog
	formattedAddChatMessage(captog and string.format("{FFFF00}Starting capture attempt... (type /%s to toggle)", commands.tcap) or "{FFFF00}Capture spam ended.")
end

-- Register chat commands
function registerChatCommands()
	sampRegisterChatCommand(commands.vestnear, function()
		local message = checkAndSendVest(true)
		if message then
			formattedAddChatMessage(message)
		end
	end)

	sampRegisterChatCommand(commands.repairnear, function()
		if autobind.Settings.enable and not checkMuted() and checkAdminDuty() then
			for _, player in ipairs(getVisiblePlayers(5, "car")) do
				sampSendChat(string.format("/repair %d 1", player.playerId))
				break
			end
		end
	end)
	
	sampRegisterChatCommand(commands.find, function(params)
		if autobind.Settings.enable then
			lua_thread.create(function()
				local function stopFinding()
					autofind.enable = false
				end
	
				local function startFinding()
					autofind.enable = true
					formattedAddChatMessage(string.format("Finding: {00a2ff}%s{ffffff}. /%s again to toggle.", autofind.playerName, commands.find))
					while autofind.enable do
						local currentTime = localClock()
						if sampIsPlayerConnected(autofind.playerId) then
							if checkAdminDuty() then
								if currentTime - timers.Find.last >= timers.Find.timer and not checkMuted() then
									timers.Find.last = currentTime
									sampSendChat(string.format("/find %d", autofind.playerId))
								end
							else
								stopFinding()
							end
						else
							stopFinding()
							formattedAddChatMessage("The player you were finding has disconnected, you are no longer finding anyone.")
						end
						wait(10)
					end
				end
	
				if not checkMuted() then
					if string.len(params) > 0 then
						if checkAdminDuty() then
							local result, playerid, name = findPlayer(params)
							if result then
								autofind.playerId = playerid
								autofind.playerName = name
								if not autofind.enable then
									startFinding()
								else
									formattedAddChatMessage(string.format("Now finding: {00a2ff}%s{ffffff}.", name))
								end
							else
								formattedAddChatMessage("Invalid player specified.")
							end
						else
							sampSendChat(string.format("/find %s", params))
						end
					else
						if autofind.enable then
							stopFinding()
							formattedAddChatMessage("You are no longer finding anyone.")
						else
							formattedAddChatMessage(string.format('USAGE: /%s [playerid/partofname]', commands.find))
						end
					end
				else
					formattedAddChatMessage(string.format("You are muted, you cannot use the /%s command.", commands.find))
				end
			end)
		end
	end)

	sampRegisterChatCommand(commands.tcap, function()
		if autobind.Settings.enable then
			toggleCaptureSpam()
		end
	end)

	sampRegisterChatCommand(commands.sprintbind, function()
		if autobind.Settings.enable then
			toggleBind("SprintBind")
		end
	end)

	sampRegisterChatCommand(commands.bikebind, function()
		if autobind.Settings.enable then
			toggleBind("BikeBind")
		end
	end)

	sampRegisterChatCommand(commands.autovest, function()
		if autobind.Settings.enable then
			autobind.AutoVest.enable = not autobind.AutoVest.enable
			formattedAddChatMessage(string.format("Automatic vest %s.", autobind.AutoVest.enable and 'enabled' or 'disabled'))
		end
	end)

	sampRegisterChatCommand(commands.autoaccept, function()
		if autobind.Settings.enable then
			autoaccepter = not autoaccepter
			formattedAddChatMessage(string.format("Auto Accept is now %s.", autoaccepter and 'enabled' or 'disabled'))
		end
	end)

	sampRegisterChatCommand(commands.ddmode, function()
		if autobind.Settings.enable then
			autobind.AutoVest.donor = not autobind.AutoVest.donor
			formattedAddChatMessage(string.format("Diamond Donator is now %s.", autobind.AutoVest.donor and 'enabled' or 'disabled'))

			timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime
		end
	end)
end

-- Save config on script terminate
function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		-- Save config
		if autobind.Settings.autoSave then
			saveConfigWithErrorHandling(getFile("settings"), autobind)
		end

		-- Unregister chat commands
		for _, command in pairs(commands) do
			sampUnregisterChatCommand(command)
		end
	end
end

function onWindowMessage(msg, wparam, lparam)
	if wparam == VK_ESCAPE and (menu.settings[0]) then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            menu.settings[0] = false
        end
    end
end

--Your gang is already attempting to capture this turf.
--
function sampev.onServerMessage(color, text)
	local mode, motdMsg = text:match("([Family|LSPD|SASD|FBI|ARES].+) MOTD: (.+)")
	if mode and motdMsg and color == -65366 then
		if mode:match("Family") then
			autobind.Settings.mode = mode
			saveConfigWithErrorHandling(getFile("settings"), autobind)

			local freq, allies = motdMsg:match("[Ff]req:?%s*(-?%d+)%s*[/%s]*[Aa]llies:?%s*([^,]+)")
			if freq and allies then
				print("Frequency detected", freq)
				currentFamilyFreq = freq

				print("Allies detected", allies)

				local newMessage = motdMsg:gsub("[Ff]req:?%s*(-?%d+)", "")
				newMessage = newMessage:gsub("^%s*,%s*", "")
				print("New message: " .. newMessage)

				return {color, string.format("%s MOTD: %s", mode, newMessage)}
			end
		elseif mode:match("[LSPD|SASD|FBI|ARES]") then
			autobind.Settings.mode = "Faction"
			saveConfigWithErrorHandling(getFile("settings"), autobind)
			if autoaccepter then
				formattedAddChatMessage(string.format("Auto Accept is now disabled. because you are now in Faction Mode."))
				autoaccepter = false
			end

			local freqType, freq = motdMsg:match("[/|%s*]%s*([RL FREQ:|FREQ:].-)%s*(-?%d+)")
			if freqType and freq then
				print("Faction frequency detected: " .. freq) 
				currentFactionFreq = freq

				local newMessage = motdMsg:gsub(freqType .. "%s*" .. freq:gsub("%-", "%%%-") .. "%s*", "")
				newMessage = newMessage:gsub("%s*/%s*/%s*", " / ")
				print("New message: " .. newMessage)

				return {color, string.format("%s MOTD: %s", mode, newMessage)}
			end
		end
	end

	local freq = text:match("You have set the frequency of your portable radio to (-?%d+) kHz.")
	if freq then
		if tonumber(freq) == 0 then
			if autobind.Settings.mode == "Family" then
				currentFamilyFreq = 0
				autobind.Settings.familyFreq = 0
			elseif autobind.Settings.mode == "Faction" then
				currentFactionFreq = 0
				autobind.Settings.factionFreq = 0
			end
		else
			return {color, string.format("You have set the frequency to your %s portable radio.", autobind.Settings.mode)}
		end
	end

	--[[local div, rank, nickname, message = text:match("%*%*%s*(%a*%s*)%s*(%a+)%s+([%a%s]+):%s*(.*)%s*%*%*")
	if rank and nickname and message and color == -1920073729 then
		print("Rank: " .. rank, "Nickname: " .. nickname, "Message: " .. message)
	end]]

	local freq, playerName, message = text:match("%*%* Radio %((%-?%d+) kHz%) %*%* (.-): (.+)")
	if freq and playerName and message then
		local playerId = sampGetPlayerIdByNickname(playerName:gsub("%s+", "_"))
		local playerColor = convertColor(sampGetPlayerColor(playerId), false, false, true)
		return {color, string.format("** %s Radio ** {%s}%s (%d): {FFFFFF}%s", autobind.Settings.mode, playerColor, playerName, playerId, message)}
	end

	-- Auto Capture
	if text:find("The time is now") and color == -86 then
		lua_thread.create(function()
			wait(0)
			if autobind.Settings.enable and not checkMuted() and checkAdminDuty() then
				local mode = autobind.Settings.mode
				if (autobind.Settings.factionTurf and mode == "Faction") or (autobind.Settings.familyTurf and mode == "Family") then
					sampSendChat("/capturf")
					if autobind.Settings.disableAfterCapturing and mode == "Family" then
						autobind.Settings.familyTurf = false
					end
				end
				if autobind.Settings.capturePoint and mode == "Family" then
					sampSendChat("/capture")
					if autobind.Settings.disableAfterCapturing then
						autobind.Settings.capturePoint = false
					end
				end
			end
		end)
	end

	-- Vest/Accept
	if text:find("That player isn't near you.") and color == -1347440726 then
		resetTimer(2, timers.Vest)
	end
	
	if text:find("You can't /guard while aiming.") and color == -1347440726 then
		resetTimer(0.5, timers.Vest)
	end
	
	local cooldown = text:match("You must wait (%d+) seconds? before selling another vest%.?")
	if cooldown then
		resetTimer(tonumber(cooldown) + 0.5, timers.Vest)
	end

	local nickname = text:match("%* You offered protection to (.+) for %$200%.")
	if nickname then
		-- = nickname -- Overlay
		timers.Vest.last = localClock()
	end

	if text:find("You are not a bodyguard.") and color ==  -1347440726 then
		isBodyguard = false
	end

	if text:match("%* You are now a Bodyguard, type /help to see your new commands.") then
		isBodyguard = true
	end

	if text:find("You are not near the person offering you guard!") and color == -1347440726 then
		formattedAddChatMessage(string.format("You are not close enough to %s.", autoaccepternick:gsub("_", " ")))
		return false
	end

	local nickname = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
	if nickname and color == 869072810 then
		autoaccepternick = nickname:gsub("%s+", "_") -- Overlay
		autoacceptertoggle = true
	end

	local nickname = text:match("%* You accepted the protection for %$200 from (.+)%.")
	if nickname then
		autoaccepternick = ""
		autoacceptertoggle = false
	end

	-- Find
	if text:match("You have already searched for someone - wait a little.") then
		resetTimer(5, timers.Find)
	end

	if text:match("You can't find that person as they're hidden in one of their turfs.") then
		resetTimer(5, timers.Find)
	end

	-- Accept Repair
	if text:find("wants to repair your car for $1") then
		lua_thread.create(function()
			wait(0)
			if autobind.Settings.enable and not checkMuted() and checkAdminDuty() then
				if autobind.AutoBind.autoRepair then
					sampSendChat("/accept repair")
				end
			end
		end)
	end

	-- Auto Badge
	if text:find("Your hospital bill") and color == -8224086 then
		lua_thread.create(function()
			wait(0)
			if autobind.Settings.enable and not checkMuted() and checkAdminDuty() then
				if autobind.AutoBind.autoBadge then
					sampSendChat("/badge")
				end
			end
		end)
	end

	-- Muted
	if text:match("You have been muted automatically for spamming. Please wait 10 seconds and try again.") then
		timers.Muted.last = localClock()
	end

	--[[if text:match("You are not a Sapphire or Diamond Donator!") or
	   text:match("You are not at the black market!") or
	   text:match("You can't do this right now.") or
	   text:match("You have been muted automatically for spamming. Please wait 10 seconds and try again.") or
	   text:match("You are muted from submitting commands right now.") and bmbool then
        bmbool = false
		bmstate = 0
        bmcmd = 0
    end

	if text:match('You are not in range of your lockers.') or
	   text:match('You have been muted automatically for spamming. Please wait 10 seconds and try again.') or
	   text:match('You are muted from submitting commands right now.') or
	   text:match("You can't use your lockers if you were recently shot.") and lockerbool then
        lockerbool = false
		lockerstate = 0
        lockercmd = 0
    end]]

	-- Help
	if text:match("*** OTHER *** /cellphonehelp /carhelp /househelp /toyhelp /renthelp /jobhelp /leaderhelp /animhelp /fishhelp /insurehelp /businesshelp /bankhelp") then
		lua_thread.create(function()
			wait(0)
			sampAddChatMessage(string.format("*** AUTOBIND *** /%s /%s /%s /%s /%s /%s", scriptName, commands.repairnear, commands.find, commands.tcap, commands.sprintbind, commands.bikebind), -1)
			sampAddChatMessage(string.format("*** AUTOVEST *** /%s /%s /%s /%s", commands.autovest, commands.ddmode, commands.autoaccept, commands.vestnear), -1)
		end)
	end
end

function sampev.onSendTakeDamage(senderID, damage, weapon, Bodypart)
	if senderID ~= 65535 and damage > 0 then
		timers.Heal.last = localClock()  -- Start the heal timer
	end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	
end

function sampev.onTogglePlayerSpectating(state)
    specState = state
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local smallIcons = {"PLUS", "MINUS"}
    local defaultIcons = {
		"SHIELD_PLUS", "POWER_OFF", "FLOPPY_DISK", "REPEAT", "PERSON_BOOTH", "ERASER",
		"RETWEET", "GEAR", "CART_SHOPPING", "KEYBOARD", "KEYBOARD_DOWN",
    }
    loadFontAwesome6Icons(smallIcons, 6, "solid")
    loadFontAwesome6Icons(defaultIcons, 12, "solid")

	for i = 0, 311 do
		if skinTexture[i] == nil then
			skinTexture[i] = imgui.CreateTextureFromFile(string.format("%s\\Skin_%d.png", getPath("skins"), i))
		end
	end

    apply_custom_style()
end)

imgui.OnFrame(function() return menu.settings[0] end,
function()
	local title = string.format("%s %s - v%s", fa.SHIELD_PLUS, firstToUpper(scriptName), scriptVersion)
	local newPos, status = imgui.handleWindowDragging(autobind.Window.Pos, autobind.Window.Size, imgui.ImVec2(0.5, 0.5))
    if status and menu.settings[0] then autobind.Window.Pos = newPos end
    imgui.SetNextWindowPos(autobind.Window.Pos, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(autobind.Window.Size, imgui.Cond.Always)
	if imgui.Begin(title, menu.settings, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
		if imgui.BeginChild("##1", imgui.ImVec2(85, 392), true) then
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			if imgui.CustomButton(
				fa.POWER_OFF,
				autobind.Settings.enable and imgui.ImVec4(0.15, 0.59, 0.18, 0.7) or imgui.ImVec4(1, 0.19, 0.19, 0.5),
				autobind.Settings.enable and imgui.ImVec4(0.15, 0.59, 0.18, 0.5) or imgui.ImVec4(1, 0.19, 0.19, 0.3),
				autobind.Settings.enable and imgui.ImVec4(0.15, 0.59, 0.18, 0.4) or imgui.ImVec4(1, 0.19, 0.19, 0.2),
				imgui.ImVec2(75, 75)) then
				autobind.Settings.enable = not autobind.Settings.enable
				if autobind.Settings.enable then
					registerChatCommands()
				else
					for _, command in pairs(commands) do
						sampUnregisterChatCommand(command)
					end
				end
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Toggles all functionalities')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 81))

			if imgui.CustomButton(
				fa.FLOPPY_DISK,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then
				saveConfigWithErrorHandling(getFile("settings"), autobind)
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Save configuration')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 157))

			if imgui.CustomButton(
				fa.REPEAT,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then
				autobind = handleConfigFile(getFile("settings"), autobind_defaultSettings, autobind, {{"AutoVest", "skins"}, {"AutoVest", "names"}, "Keybinds"})
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reload configuration')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 233))

			if imgui.CustomButton(
				fa.ERASER,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then
				ensureDefaults(autobind, autobind_defaultSettings, true, {{"Settings", "mode"}, {"Settings", "freq"}})
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Load default configuration')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 309))

			if imgui.CustomButton(
				fa.RETWEET .. ' Update',
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then

			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Check for update [Disabled]')
			end
		end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(92, 28))

		if imgui.BeginChild("##2", imgui.ImVec2(500, 88), true) then

			imgui.SetCursorPos(imgui.ImVec2(5,5))
			if imgui.CustomButton(string.format("%s  Settings", fa("GEAR")),
				menu.pageId == 1 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(165, 75)) then
				menu.pageId = 1
			end

			imgui.SetCursorPos(imgui.ImVec2(170, 5))

			if imgui.CustomButton(string.format("%s  %s Skins", fa("PERSON_BOOTH"), autobind.Settings.mode),
				menu.pageId == 2 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(165, 75)) then

				menu.pageId = 2
			end

			imgui.SetCursorPos(imgui.ImVec2(335, 5))

			if imgui.CustomButton(string.format("%s  Names", fa("PERSON_BOOTH")),
				menu.pageId == 3 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(165, 75)) then

				menu.pageId = 3
			end
		end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(92, 112))

		if imgui.BeginChild("##3", imgui.ImVec2(500, 276), true) then
			if menu.pageId == 1 then
				imgui.SetCursorPos(imgui.ImVec2(5, 10))
				imgui.BeginChild("##config", imgui.ImVec2(330, 255), false)
					-- Autobind/Capture
					imgui.Text('Auto Bind:')
					if imgui.Checkbox('Capture Spam', new.bool(captog)) then
						toggleCaptureSpam()
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Capture spam will automatically type /capturf every 1.5 seconds.')
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)

					local switchTurf = autobind.Settings.mode:lower() .. "Turf"
					if imgui.Checkbox('Capture (Turfs)', new.bool(autobind.Settings[switchTurf])) then
						autobind.Settings[switchTurf] = not autobind.Settings[switchTurf]

						if switchTurf == "familyTurf" then
							autobind.Settings.capturePoint = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Capture (Turfs) will automatically type /capturf at signcheck time.')
					end

					if autobind.Settings.mode == "Family" then
						-- Disable/Capture
						if imgui.Checkbox('Disable after capturing', new.bool(autobind.Settings.disableAfterCapturing)) then
							autobind.Settings.disableAfterCapturing = not autobind.Settings.disableAfterCapturing
						end
						if imgui.IsItemHovered() then
							imgui.SetTooltip('Disable after capturing: prevents capture spam after the point/turf has been secured.')
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						if imgui.Checkbox('Capture (Points)', new.bool(autobind.Settings.capturePoint)) then
							autobind.Settings.capturePoint = not autobind.Settings.capturePoint
							if autobind.Settings.capturePoint then
								autobind.Settings.familyTurf = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.SetTooltip('Capture (Points) will automatically type /capturf at signcheck time.')
						end
					end

					if imgui.Checkbox('Accept Repair', new.bool(autobind.AutoBind.autoRepair)) then
						autobind.AutoBind.autoRepair = not autobind.AutoBind.autoRepair
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Accept Repair will automatically accept repair requests.')
					end

					if autobind.Settings.mode == "Faction" then
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						if imgui.Checkbox('Auto Badge', new.bool(autobind.AutoBind.autoBadge)) then 
							autobind.AutoBind.autoBadge = not autobind.AutoBind.autoBadge 
						end
						if imgui.IsItemHovered() then
							imgui.SetTooltip('Automatically types /badge after spawning from the hopsital.')
						end
					end

					-- Auto Vest
					imgui.Text('Auto Vest:')
					if imgui.Checkbox("Enable", new.bool(autobind.AutoVest.enable)) then
						autobind.AutoVest.enable = not autobind.AutoVest.enable
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Enable for automatic vesting.')
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Diamond Donator", new.bool(autobind.AutoVest.donor)) then
						autobind.AutoVest.donor = not autobind.AutoVest.donor
						timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Enable for Diamond Donators. Uses /guardnear does not have armor/paused checks.')
					end

					-- Accept
					if imgui.Checkbox('Auto Accept', new.bool(autoaccepter)) then
						autoaccepter = not autoaccepter
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Accept Vest will automatically accept vest requests.')
					end

					imgui.Text('Frisk:')
					if imgui.Checkbox("Targeting", new.bool(autobind.Settings.Frisk.target)) then
						autobind.Settings.Frisk.target = not autobind.Settings.Frisk.target
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Must be targeting a player to frisk. (Green Blip above the player)')
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Must Aim", new.bool(autobind.Settings.Frisk.mustAim)) then
						autobind.Settings.Frisk.mustAim = not autobind.Settings.Frisk.mustAim
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Must be aiming to frisk.')
					end
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(340, 5))
				if imgui.BeginChild("##keybinds", imgui.ImVec2(155, 263), true) then
					if imgui.Button(fa.CART_SHOPPING .. " BM Locker") then
						menu.blackmarket[0] = not menu.blackmarket[0]
					end
					keyEditor('BlackMarket')
					if autobind.Settings.mode == "Faction" then
						if imgui.Button(fa.CART_SHOPPING .. " Faction Locker") then
							menu.factionlocker[0] = not menu.factionlocker[0]
						end
						keyEditor('FactionLocker')
					end
					keyEditor('Accept')
					keyEditor('Offer')
					keyEditor('TakePills')
					keyEditor('BikeBind')
					keyEditor('SprintBind')
					keyEditor('Frisk')
				end
				imgui.EndChild()
			end

			if menu.pageId == 2 then
				if autobind.Settings.mode == "Family" then
					imgui.PushItemWidth(334)
					local url = new.char[128](autobind.AutoVest.skinsUrl)
					if imgui.InputText('##skins_url', url, sizeof(url)) then
						autobind.AutoVest.skinsUrl = u8:decode(str(url))
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip("URL to fetch skins from, must be a JSON array of skin IDs")
					end
					imgui.SameLine()
					imgui.PopItemWidth()
					if imgui.Button("Fetch") then
						fetchDataFromURL(autobind.AutoVest.skinsUrl, 'skins', function(decodedData)
							autobind.AutoVest.skins = decodedData
						end)
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip("Fetches skins from provided URL")
					end
					imgui.SameLine()
					if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchSkins)) then
						autobind.AutoVest.autoFetchSkins = not autobind.AutoVest.autoFetchSkins
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip("Fetch skins at startup")
					end

					local columns = 8  -- Number of columns in the grid
					local imageSize = imgui.ImVec2(50, 95)  -- Size of each image
					local spacing = 11.2  -- Spacing between images
					local start = imgui.GetCursorPos()  -- Starting position
				
					for i, skinId in ipairs(autobind.AutoVest.skins) do
						-- Calculate position
						local column = (i - 1) % columns
						local row = math.floor((i - 1) / columns)
						local posX = start.x + column * (imageSize.x + spacing)
						local posY = start.y + row * (imageSize.y + spacing)
				
						-- Set position and draw the image
						imgui.SetCursorPos(imgui.ImVec2(posX, posY))
						imgui.Image(skinTexture[skinId], imageSize)
				
						-- Draw the "X" button on top of the image
						imgui.SetCursorPos(imgui.ImVec2(posX + imageSize.x - 20, posY))
						imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))  -- Transparent background
						imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1, 0, 0, 0.5))  -- Red when hovered
						imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1, 0, 0, 0.5))  -- Red when active
						if imgui.Button("x##"..i, imgui.ImVec2(20, 20)) then
							table.remove(autobind.AutoVest.skins, i)
						end
						imgui.PopStyleColor(3)
				
						if imgui.IsItemHovered() then
							imgui.SetTooltip("Skin "..skinId)
						end
					end
				
					-- Add the "Add Skin" button in the next available slot
					local addButtonIndex = #autobind.AutoVest.skins + 1
					local column = (addButtonIndex - 1) % columns
					local row = math.floor((addButtonIndex - 1) / columns)
					local posX = start.x + column * (imageSize.x + spacing)
					local posY = start.y + row * (imageSize.y + spacing)
				
					imgui.SetCursorPos(imgui.ImVec2(posX, posY))
					if imgui.Button(u8"Add\nSkin", imageSize) then
						autobind.AutoVest.skins[#autobind.AutoVest.skins + 1] = 0
						menu.skins[0] = not menu.skins[0]
						skinEditor.selected = #autobind.AutoVest.skins
					end
				elseif autobind.Settings.mode == "Faction" then
					if imgui.Checkbox("Use Skins", new.bool(autobind.AutoVest.useSkins)) then
						autobind.AutoVest.useSkins = not autobind.AutoVest.useSkins
					end

					local columns = 8  -- Number of columns in the grid
					local imageSize = imgui.ImVec2(50, 95)  -- Size of each image
					local spacing = 11.2  -- Spacing between images
					local start = imgui.GetCursorPos()  -- Starting position
				
					for i, skinId in ipairs(factions.skins) do
						-- Calculate position
						local column = (i - 1) % columns
						local row = math.floor((i - 1) / columns)
						local posX = start.x + column * (imageSize.x + spacing)
						local posY = start.y + row * (imageSize.y + spacing)
				
						-- Set position and draw the image
						imgui.SetCursorPos(imgui.ImVec2(posX, posY))
						imgui.Image(skinTexture[skinId], imageSize)
						if imgui.IsItemHovered() then
							imgui.SetTooltip("Skin "..skinId)
						end
					end
				end
			end

			if menu.pageId == 3 then
				imgui.PushItemWidth(334)
				local url = new.char[128](autobind.AutoVest.namesUrl)
				if imgui.InputText('##names_url', url, sizeof(url)) then
					autobind.AutoVest.namesUrl = u8:decode(str(url))
				end
				if imgui.IsItemHovered() then
					imgui.SetTooltip("URL to fetch names from, must be a JSON array of names")
				end
				imgui.SameLine()
				imgui.PopItemWidth()
				if imgui.Button("Fetch") then
					fetchDataFromURL(autobind.AutoVest.namesUrl, 'names', function(decodedData)
						autobind.AutoVest.names = decodedData
					end)
				end
				if imgui.IsItemHovered() then
					imgui.SetTooltip("Fetches names from provided URL")
				end
				imgui.SameLine()
				if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchNames)) then
					autobind.AutoVest.autoFetchNames = not autobind.AutoVest.autoFetchNames
				end
				if imgui.IsItemHovered() then
					imgui.SetTooltip("Fetch names at startup")
				end

				for key, value in pairs(autobind.AutoVest.names) do
					local nick = new.char[128](value)
					if imgui.InputText('Nickname##'..key, nick, sizeof(nick)) then
						autobind.AutoVest.names[key] = u8:decode(str(nick))
					end
					imgui.SameLine()
					if imgui.Button(u8"x##"..key) then
						table.remove(autobind.AutoVest.names, key)
					end
				end
				if imgui.Button(u8"Add Name") then
					autobind.AutoVest.names[#autobind.AutoVest.names + 1] = "Name"
				end
			end
		end
		imgui.EndChild()
		imgui.SetCursorPos(imgui.ImVec2(92, 384))

		if imgui.BeginChild("##5", imgui.ImVec2(500, 36), true) then
			if imgui.Checkbox('Autosave', new.bool(autobind.Settings.autoSave)) then
				autobind.Settings.autoSave = not autobind.Settings.autoSave
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Automatically saves your settings when you exit the game')
			end
			imgui.SameLine()
			if imgui.Checkbox('Everyone', new.bool(autobind.AutoVest.everyone)) then
				autobind.AutoVest.everyone = not autobind.AutoVest.everyone
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('With this enabled, the vest will be applied to everyone on the server')
			end
		end
		imgui.EndChild()
	end
	imgui.End()
end)

imgui.OnFrame(function() return menu.settings[0] and menu.skins[0] end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.Window.Pos.x, autobind.Window.Pos.y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(505, 390), imgui.Cond.FirstUseEver)
	imgui.Begin(u8("Skin Menu"), menu.skins, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)
		imgui.SetWindowFocus()
		if skinEditor.page == 15 then max = 299 else max = 41+(21*(skinEditor.page-2)) end
		for i = 21+(21*(skinEditor.page-2)), max do
			if i <= 27+(21*(skinEditor.page-2)) and i ~= 21+(21*(skinEditor.page-2)) then
				imgui.SameLine()
			elseif i <= 34+(21*(skinEditor.page-2)) and i > 28+(21*(skinEditor.page-2)) then
				imgui.SameLine()
			elseif i <= 41+(21*(skinEditor.page-2)) and i > 35+(21*(skinEditor.page-2)) then
				imgui.SameLine()
			end
			if imgui.ImageButton(skinTexture[i], imgui.ImVec2(55, 100)) then
				autobind.AutoVest.skins[skinEditor.selected] = i
				menu.skins[0] = false
			end
			if imgui.IsItemHovered() then imgui.SetTooltip("Skin "..i.."") end
		end

		imgui.SetCursorPos(imgui.ImVec2(555, 360))

		imgui.Indent(210)

		if imgui.Button(u8"Previous", new.bool) and skinEditor.page > 0 then
			if skinEditor.page == 1 then
				skinEditor.page = 15
			else
				skinEditor.page = skinEditor.page - 1
			end
		end
		imgui.SameLine()
		if imgui.Button(u8"Next", new.bool) and skinEditor.page < 16 then
			if skinEditor.page == 15 then
				skinEditor.page = 1
			else
				skinEditor.page = skinEditor.page + 1
			end
		end
		imgui.SameLine()
		imgui.Text("Page "..skinEditor.page.."/15")
	imgui.End()
end)

-- Helper function to check if a table contains a value
local function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function createCheckbox(label, index, tbl, exclusiveGroups, maxSelections)
    local isChecked = tableContains(tbl, index)
    if imgui.Checkbox(label, new.bool(isChecked)) then
        if isChecked then
            for i, v in ipairs(tbl) do
                if v == index then
                    table.remove(tbl, i)
                    break
                end
            end
        else
            if #tbl < maxSelections then
                table.insert(tbl, index)
                if exclusiveGroups then
                    for _, group in ipairs(exclusiveGroups) do
                        if tableContains(group, index) then
                            for _, exclusiveIndex in ipairs(group) do
                                if exclusiveIndex ~= index then
                                    for i, v in ipairs(tbl) do
                                        if v == exclusiveIndex then
                                            table.remove(tbl, i)
                                            break
                                        end
                                    end
                                end
                            end
                            break  -- Exit the loop once the relevant group is found and processed
                        end
                    end
                end
            end
        end
    end
end

local function createMenu(title, items, tbl, exclusiveGroups, maxSelections)
    imgui.Text(title)
    for index, item in ipairs(items) do
        createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
    end
end

imgui.OnFrame(function() return menu.settings[0] and menu.blackmarket[0] end,
function()
    imgui.SetNextWindowPos(imgui.ImVec2(autobind.Window.Pos.x - (autobind.Window.Size.x * 0.635), autobind.Window.Pos.y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    if imgui.Begin("BM Settings", menu.blackmarket, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize) then
        createMenu('Black-Market Equipment:', blackMarketItems, autobind.BlackMarket, blackMarketExclusiveGroups, 4)
    end
    imgui.End()
end)

imgui.OnFrame(function() return menu.settings[0] and menu.factionlocker[0] end,
function()
    imgui.SetNextWindowPos(imgui.ImVec2(autobind.Window.Pos.x + (autobind.Window.Size.x * 0.607), autobind.Window.Pos.y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    if imgui.Begin("Faction Locker", menu.factionlocker, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize) then
        createMenu('Locker Equipment:', lockerMenuItems, autobind.FactionLocker, lockerExclusiveGroups, 4)
    end
    imgui.End()
end)

-- Key Editor
function keyEditor(name)
    if not autobind.Keybinds[name] then
        print("Warning: autobind.Keybinds[" .. name .. "] is nil")
        return
    end

    if not autobind.Keybinds[name].Keys then
        autobind.Keybinds[name].Keys = {}
    end

    imgui.BeginGroup()

    imgui.Text(name .. ":")

	if imgui.Checkbox((autobind.Keybinds[name].Toggle and "Enabled" or "Disabled") .. "##" .. name, new.bool(autobind.Keybinds[name].Toggle)) then
		autobind.Keybinds[name].Toggle = not autobind.Keybinds[name].Toggle
	end

    for i, key in ipairs(autobind.Keybinds[name].Keys) do
        local buttonText = changekey[name] and changekey[name] == i and fa.KEYBOARD_DOWN or 
            (key ~= 0 and vk.id_to_name(key) or fa.KEYBOARD)

        if imgui.Button(buttonText .. '##' .. name .. i) then
            changekey[name] = i
            lua_thread.create(function()
                while changekey[name] == i do 
                    wait(0)
                    local keydown, result = getDownKeys()
                    if result then
                        autobind.Keybinds[name].Keys[i] = keydown
                        changekey[name] = false
                    end
                end
            end)
        end

        -- Add a combo box for key type selection
        imgui.SameLine()
        imgui.PushItemWidth(75)
        local keyTypes = {"KeyDown", "KeyPressed"}
        
        local currentType = autobind.Keybinds[name].Type
        if type(currentType) == "table" then
            currentType = currentType[i] or "KeyDown"
        elseif type(currentType) ~= "string" then
            currentType = "KeyDown"
        end
        
        if imgui.BeginCombo("##KeyType"..name..i, currentType:gsub("Key", "")) then
            for _, keyType in ipairs(keyTypes) do
                if imgui.Selectable(keyType:gsub("Key", ""), currentType == keyType) then
                    if type(autobind.Keybinds[name].Type) ~= "table" then
                        autobind.Keybinds[name].Type = {autobind.Keybinds[name].Type or "KeyDown"}
                    end
                    autobind.Keybinds[name].Type[i] = keyType
                end
            end
            imgui.EndCombo()
        end
        imgui.PopItemWidth()
    end

    if imgui.Button(fa.PLUS .. "##add" .. name) then
        local nextIndex = #autobind.Keybinds[name].Keys + 1
        if nextIndex <= 3 then
            table.insert(autobind.Keybinds[name].Keys, 0)
            if type(autobind.Keybinds[name].Type) ~= "table" then
                autobind.Keybinds[name].Type = {autobind.Keybinds[name].Type or "KeyDown"}
            end
            table.insert(autobind.Keybinds[name].Type, "KeyDown")
        end
    end

    imgui.SameLine()

    if imgui.Button(fa.MINUS .. "##remove" .. name) then
        if #autobind.Keybinds[name].Keys > 0 then
            table.remove(autobind.Keybinds[name].Keys)
            if type(autobind.Keybinds[name].Type) == "table" then
                table.remove(autobind.Keybinds[name].Type)
            end
        end
    end

    imgui.EndGroup()
end

-- Fetch Data From URL
function fetchDataFromURL(url, path, callback)
	downloadFiles({{url = url, path = getFile(path), replace = true}}, function(result)
		if result then
			local file = io.open(getFile(path), "r")
			if file then
				local content = file:read("*all")
				file:close()
				
				local success, decodedData = pcall(decodeJson, content)
				if success and type(decodedData) == "table" then
					callback(decodedData)
				else
					print("Error decoding JSON or invalid data structure "..content)
				end
			else
				print("Error opening file: " .. path)
			end
		end
	end)
end

-- Generate Skins Urls
local function generateSkinsUrls()
    local files = {}
    for i = 0, 311 do
        table.insert(files, {
            url = string.format("%s/Skin_%d.png", fetchUrls("skins"), i),
            path = string.format("%s/Skin_%d.png", getPath("skins"), i),
            replace = false
        })
    end
    return files
end

-- Download Skins
function downloadSkins()
	downloadFiles(generateSkinsUrls(), function(result)
        if result then 
            formattedAddChatMessage("All skins downloaded successfully!", -1) 
        end
	end)
end

-- Utility Functions
function downloadFiles(table, onCompleteCallback)
    local downloadsInProgress = 0
    local downloadsStarted = false
    local callbackCalled = false

    local function download_handler(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            downloadsInProgress = downloadsInProgress - 1
        end

        if downloadsInProgress == 0 and onCompleteCallback and not callbackCalled then
            callbackCalled = true
            onCompleteCallback(downloadsStarted)
        end
    end

    for _, file in ipairs(table) do
        if not doesFileExist(file.path) or file.replace then
            downloadsInProgress = downloadsInProgress + 1
            downloadsStarted = true
            downloadUrlToFile(file.url, file.path, download_handler)
        end
    end

    if not downloadsStarted and onCompleteCallback and not callbackCalled then
        callbackCalled = true
        onCompleteCallback(downloadsStarted)
    end
end

function handleConfigFile(path, defaults, configVar, ignoreKeys)
    ignoreKeys = ignoreKeys or {}
    if doesFileExist(path) then
        local config, err = loadConfig(path)
        if not config then
            print("Error loading config from " .. path .. ": " .. err)

            local newpath = path:gsub("%.[^%.]+$", ".bak")
            local success, err2 = os.rename(path, newpath)
            if not success then
                print("Error renaming config: " .. err2)
                os.remove(path)
            end
            handleConfigFile(path, defaults, configVar)
        else
            local result = ensureDefaults(config, defaults, false, ignoreKeys)
            if result then
                local success, err3 = saveConfig(path, config)
                if not success then
                    print("Error saving config: " .. err3)
                end
            end
            return config
        end
    else
        local result = ensureDefaults(configVar, defaults, true)
        if result then
            local success, err = saveConfig(path, configVar)
            if not success then
                print("Error saving config: " .. err)
            end
        end
    end
    return configVar
end

function ensureDefaults(config, defaults, reset, ignoreKeys)
    ignoreKeys = ignoreKeys or {}
    local status = false

    local function isIgnored(key, path)
        local fullPath = table.concat(path, ".") .. "." .. key
        for _, ignoreKey in ipairs(ignoreKeys) do
            if type(ignoreKey) == "table" then
                local ignorePath = table.concat(ignoreKey, ".")
                if fullPath == ignorePath then
                    return true
                end
            elseif key == ignoreKey then
                return true
            end
        end
        return false
    end

    local function cleanupConfig(conf, def, path)
        local localStatus = false
        for k, v in pairs(conf) do
            local newPath = {unpack(path)}
            table.insert(newPath, k)
            if not isIgnored(k, path) then
                if def[k] == nil then
                    conf[k] = nil
                    localStatus = true
                elseif type(conf[k]) == "table" and type(def[k]) == "table" then
                    localStatus = cleanupConfig(conf[k], def[k], newPath) or localStatus
                end
            end
        end
        return localStatus
    end

    local function copyDefaults(t, d, p)
        for k, v in pairs(d) do
            local newPath = {unpack(p)}
            table.insert(newPath, k)
            if not isIgnored(k, p) then
                if type(v) == "table" then
                    if type(t[k]) ~= "table" then
                        t[k] = {}
                        status = true
                    end
                    copyDefaults(t[k], v, newPath)
                elseif t[k] == nil or (reset and not isIgnored(k, p)) then
                    t[k] = v
                    status = true
                end
            end
        end
    end

    copyDefaults(config, defaults, {})
    status = cleanupConfig(config, defaults, {}) or status

    return status
end

function loadConfig(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil, "Could not open file."
    end

    local content = file:read("*a")
    file:close()

    if not content or content == "" then
        return nil, "Config file is empty."
    end

    local success, decoded = pcall(decodeJson, content)
    if success then
        if next(decoded) == nil then
            return nil, "JSON format is empty."
        else
            return decoded, nil
        end
    else
        return nil, "Failed to decode JSON: " .. decoded
    end
end

function saveConfig(filePath, config)
    local file = io.open(filePath, "w")
    if not file then
        return false, "Could not save file."
    end
    file:write(encodeJson(config, false))
    file:close()
    return true
end

function saveConfigWithErrorHandling(path, config)
    local success, err = saveConfig(path, config)
    if not success then
        print("Error saving config to " .. path .. ": " .. err)
    end
    return success
end

function convertColor(color, normalize, includeAlpha, hexColor)
    if type(color) ~= "number" then
        error("Invalid color value. Expected a number.")
    end

    local r = bit.band(bit.rshift(color, 16), 0xFF)
    local g = bit.band(bit.rshift(color, 8), 0xFF)
    local b = bit.band(color, 0xFF)
    local a = includeAlpha and bit.band(bit.rshift(color, 24), 0xFF) or 255

    if normalize then
        r, g, b, a = r / 255, g / 255, b / 255, a / 255
    end

    if hexColor then
        return includeAlpha and string.format("%02X%02X%02X%02X", a, r, g, b) or string.format("%02X%02X%02X", r, g, b)
    else
        return includeAlpha and {r, g, b, a} or {r, g, b}
    end
end

function joinARGB(a, r, g, b, normalized)
    if normalized then
        a, r, g, b = math.floor(a * 255), math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    end

    local function clamp(value)
        return math.max(0, math.min(255, value))
    end

    return bit.bor(bit.lshift(clamp(a), 24), bit.lshift(clamp(r), 16), bit.lshift(clamp(g), 8), clamp(b))
end

function formattedAddChatMessage(string)
    sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} %s", firstToUpper(scriptName), string), -1)
end

function firstToUpper(string)
    return (string:gsub("^%l", string.upper))
end

function removeHexBrackets(text)
    return string.gsub(text, "{%x+}", "")
end

function compareVersions(version1, version2)
    local function parseVersion(version)
        local parts = {}
        for part in version:gmatch("(%d+)") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end

    local v1 = parseVersion(version1)
    local v2 = parseVersion(version2)

    local maxLength = math.max(#v1, #v2)
    for i = 1, maxLength do
        local part1 = v1[i] or 0
        local part2 = v2[i] or 0
        if part1 ~= part2 then
            return (part1 > part2) and 1 or -1
        end
    end
    return 0
end

function getDownKeys()
    local keyslist = nil
    local bool = false
    for k, v in pairs(vk) do
        if isKeyDown(v) then
            keyslist = v
            bool = true
        end
    end
    return keyslist, bool
end

function keycheck(bind)
    local r = true
    if not bind.keys then
        return false
    end
    for i = 1, #bind.keys do
        r = r and PressType[bind.type[i]](bind.keys[i])
    end
    return r
end

function has_number(tab, val)
    for index, value in ipairs(tab) do
        if tonumber(value) == val then
            return true
        end
    end
    return false
end

function setGameKeyUpDown(key, value, delay)
	setGameKeyState(key, value)
	wait(delay)
	setGameKeyState(key, 0)
end

function imgui.CustomButton(name, color, colorHovered, colorActive, size)
    local clr = imgui.Col
    imgui.PushStyleColor(clr.Button, color)
    imgui.PushStyleColor(clr.ButtonHovered, colorHovered)
    imgui.PushStyleColor(clr.ButtonActive, colorActive)
    if not size then size = imgui.ImVec2(0, 0) end
    local result = imgui.Button(name, size)
    imgui.PopStyleColor(3)
    return result
end

function findPlayer(target)
    if not target then return nil end

    local targetId = tonumber(target)
    if targetId and sampIsPlayerConnected(targetId) then
        return true, targetId, sampGetPlayerNickname(targetId)
    end

    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) then
            local name = sampGetPlayerNickname(i)
            if name:lower():find("^" .. target:lower()) then
                return true, i, name
            end
        end
    end

    return nil
end

function sampGetPlayerIdByNickname(nick)
	nick = tostring(nick)
	local _, myid = sampGetPlayerIdByCharHandle(ped)
	if nick == sampGetPlayerNickname(myid) then return myid end
	for i = 0, sampGetMaxPlayerId(false) do
		if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
			return i
		end
	end
end

function calculateWindowSize(lines, padding)
    local totalHeight = 0
    local maxWidth = 0
    local lineSpacing = imgui.GetTextLineHeightWithSpacing() - imgui.GetTextLineHeight()

    for _, text in ipairs(lines) do
        local processedText = removeHexBrackets(text)
        local textSize = imgui.CalcTextSize(processedText)
        totalHeight = totalHeight + textSize.y + lineSpacing
        if textSize.x > maxWidth then
            maxWidth = textSize.x
        end
    end
    totalHeight = totalHeight - lineSpacing

    local windowSize = imgui.ImVec2(
        maxWidth + padding.x * 2,
        totalHeight + padding.y * 2
    )
    return windowSize
end

function imgui.handleWindowDragging(pos, size, pivot)
    local mpos = imgui.GetMousePos()
    local offset = {x = size.x * pivot.x, y = size.y * pivot.y}
    local boxPos = {x = pos.x - offset.x, y = pos.y - offset.y}

    if mpos.x >= boxPos.x and mpos.x <= boxPos.x + size.x and mpos.y >= boxPos.y and mpos.y <= boxPos.y + size.y then
        if imgui.IsMouseClicked(0) and not imgui.IsAnyItemHovered() then
            selectedbox = true
            tempOffset = {x = mpos.x - boxPos.x, y = mpos.y - boxPos.y}
        end
    end
    if selectedbox then
        if imgui.IsMouseReleased(0) then
            selectedbox = false
        else
            if imgui.IsAnyItemHovered() then
				selectedbox = false
			else
                local newBoxPos = {x = mpos.x - tempOffset.x, y = mpos.y - tempOffset.y}
                return {x = newBoxPos.x + offset.x, y = newBoxPos.y + offset.y}, true
            end
        end
    end
    return {x = pos.x, y = pos.y}, false
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local col = imgui.Col

    local function designText(text__)
        local pos = imgui.GetCursorPos()
        if sampGetChatDisplayMode() == 2 then
            for i = 1, 1 --[[Shadow degree]] do
                imgui.SetCursorPos(imgui.ImVec2(pos.x + i, pos.y))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
                imgui.SetCursorPos(imgui.ImVec2(pos.x - i, pos.y))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
                imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y + i))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
                imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y - i))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
            end
        end
        imgui.SetCursorPos(pos)
    end

    -- Ensure color codes are in the form of {RRGGBBAA}
    text = text:gsub('{(%x%x%x%x%x%x)}', '{%1FF}')

    local color = colors[col.Text]
    local start = 1
    local a, b = text:find('{........}', start)

    while a do
        local t = text:sub(start, a - 1)
        if #t > 0 then
            designText(t)
            imgui.TextColored(color, t)
            imgui.SameLine(nil, 0)
        end

        local clr = text:sub(a + 1, b - 1)
        if clr:upper() == 'STANDART' then
            color = colors[col.Text]
        else
            clr = tonumber(clr, 16)
            if clr then
                local r = bit.band(bit.rshift(clr, 24), 0xFF)
                local g = bit.band(bit.rshift(clr, 16), 0xFF)
                local b = bit.band(bit.rshift(clr, 8), 0xFF)
                local a = bit.band(clr, 0xFF)
                color = imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
            end
        end

        start = b + 1
        a, b = text:find('{........}', start)
    end

    imgui.NewLine()
    if #text >= start then
        imgui.SameLine(nil, 0)
        designText(text:sub(start))
        imgui.TextColored(color, text:sub(start))
    end
end

function imgui.CustomButtonWithTooltip(name, color, colorHovered, colorActive, size, tooltip)
    local clr = imgui.Col
    imgui.PushStyleColor(clr.Button, color)
    imgui.PushStyleColor(clr.ButtonHovered, colorHovered)
    imgui.PushStyleColor(clr.ButtonActive, colorActive)
    if not size then size = imgui.ImVec2(0, 0) end
    local result = imgui.Button(name, size)
    imgui.PopStyleColor(3)
    if imgui.IsItemHovered() and tooltip then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
        imgui.SetTooltip(tooltip)
        imgui.PopStyleVar()
    end
    return result
end

function loadFontAwesome6Icons(iconList, fontSize, style)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    config.GlyphMinAdvanceX = 14
    local builder = imgui.ImFontGlyphRangesBuilder()
    
    for _, icon in ipairs(iconList) do
        builder:AddText(fa(icon))
    end
    
    local glyphRanges = imgui.ImVector_ImWchar()
    builder:BuildRanges(glyphRanges)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85(style), fontSize, config, glyphRanges[0].Data)
end

function apply_custom_style()
	imgui.SwitchContext()
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2
	local style = imgui.GetStyle()
	style.WindowRounding = 0
	style.WindowPadding = ImVec2(8, 8)
	style.WindowTitleAlign = ImVec2(0.5, 0.5)
	style.FrameRounding = 0
	style.ItemSpacing = ImVec2(8, 4)
	style.ScrollbarSize = 10
	style.ScrollbarRounding = 3
	style.GrabMinSize = 10
	style.GrabRounding = 0
	style.Alpha = 1
	style.FramePadding = ImVec2(4, 3)
	style.ItemInnerSpacing = ImVec2(4, 4)
	style.TouchExtraPadding = ImVec2(0, 0)
	style.IndentSpacing = 21
	style.ColumnsMinSpacing = 6
	style.ButtonTextAlign = ImVec2(0.5, 0.5)
	style.DisplayWindowPadding = ImVec2(22, 22)
	style.DisplaySafeAreaPadding = ImVec2(4, 4)
	style.AntiAliasedLines = true
	style.CurveTessellationTol = 1.25
	local colors = style.Colors
	local clr = imgui.Col
	colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
	colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
	colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
end

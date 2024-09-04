script_name("autobind")
script_description("Autobind Menu")
script_version("1.8.13a")
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
	keybinds = nil,
	pointbounds = nil
}

-- Key Press Type
local PressType = {KeyDown = isKeyDown, KeyPressed = wasKeyPressed}

-- Spec State
local specState = false

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
		Pos = {x = resX / 2, y = resY / 2}
	},
	BlackMarket = {
		Pos = {x = resX / 5, y = resY / 2},
        Kit1 = {1, 9, 13},
        Kit2 = {1, 9, 12},
        Kit3 = {1, 9, 4},
		Locations = {}
    },
    FactionLocker = {1, 2, 9, 8},
	Keybinds = {
        Accept = {Toggle = true, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}},
        Offer = {Toggle = true, Keys = {VK_MENU, VK_O}, Type = {'KeyDown', 'KeyPressed'}},
        BlackMarket1 = {Toggle = false, Keys = {VK_MENU, VK_1}, Type = {'KeyDown', 'KeyPressed'}},
        BlackMarket2 = {Toggle = false, Keys = {VK_MENU, VK_2}, Type = {'KeyDown', 'KeyPressed'}},
        BlackMarket3 = {Toggle = false, Keys = {VK_MENU, VK_3}, Type = {'KeyDown', 'KeyPressed'}},
        FactionLocker = {Toggle = false, Keys = {VK_MENU, VK_X}, Type = {'KeyDown', 'KeyPressed'}},
        BikeBind = {Toggle = false, Keys = {VK_SHIFT}, Type = {'KeyDown', 'KeyDown'}},
        SprintBind = {Toggle = true, Keys = {VK_F11}, Type = {'KeyPressed'}},
        Frisk = {Toggle = false, Keys = {VK_MENU, VK_F}, Type = {'KeyDown', 'KeyPressed'}},
        TakePills = {Toggle = false, Keys = {VK_F3}, Type = {'KeyPressed'}}
    }
}

-- Commands
local commands = {
	vestnear = "vestnear",
	repairnear = "repairnear",
	sprintbind = "sprintbind",
	bikebind = "bikebind",
	find = "hfind",
	tcap = "capspam",
	autovest = "autovest",
	autoaccept = "autoaccept",
	ddmode = "donormode",
}

-- Timers
local timers = {
	Vest = {timer = 0.0, last = 0},
	VestCD = {timer = 0.8, last = 0},
	AcceptCD = {timer = 0.8, last = 0},
	Heal = {timer = 12.0, last = 0},
	Find = {timer = 19.5, last = 0},
	Muted = {timer = 13.0, last = 0},
	Binds = {timer = 0.5, last = {}}
}

-- Guard
local guardTime = 13.5
local ddguardTime = 6.5
local isBodyguard = true

-- Frequency
local currentFamilyFreq = 0
local currentFactionFreq = 0

-- Auto Accept
local accepter = {
	enable = false,
	received = false,
	playerName = "",
	playerId = -1
}

-- Auto Find
local autofind ={
	enable = false,
	playerName = "",
	playerId = -1
}

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

-- Capture Spam
local captureSpam = false

-- Menu Variables
local menu = {
	settings = new.bool(false),
	pageId = 1,
	skins = new.bool(false),
	blackmarket = new.bool(false),
	factionlocker = new.bool(false)
}

-- Change Key
local changekey = {}

-- Calculate Size
local size = {
    {x = 0, y = 0}
}

-- Currently Dragging
local currentlyDragging = nil

-- Skin Editor
local skinTexture = {}
local skinEditor = {
	selected = -1,
	page = 1,
	fontSize = 12,
	font = nil
}

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

-- Black Market Equipment Menu
local blackMarketItems = {
    {label = 'Health/Armor', index = 2, weapon = nil, price = 350}, -- 1
    {label = 'Silenced', index = 6, weapon = 22, price = 150}, -- 2
    {label = '9mm', index = 7, weapon = 23, price = 200}, -- 3
    {label = 'Shotgun', index = 8, weapon = 25, price = 400}, -- 4
    {label = 'MP5', index = 9, weapon = 29, price = 550}, -- 5
    {label = 'UZI', index = 10, weapon = 28, price = 700}, -- 6
    {label = 'Tec-9', index = 11, weapon = 32, price = 700}, -- 7
    {label = 'Country Rifle', index = 12, weapon = 33, price = 850}, -- 8
    {label = 'Deagle', index = 13, weapon = 24, price = 1000}, -- 9
    {label = 'AK-47', index = 14, weapon = 30, price = 1400}, -- 10
    {label = 'M4', index = 15, weapon = 31, price = 1400}, -- 11
    {label = 'Spas-12', index = 16, weapon = 27, price = 2250}, -- 12
    {label = 'Sniper Rifle', index = 17, weapon = 34, price = 3850} -- 13
}

-- Black Market Exclusive Groups
local blackMarketExclusiveGroups = {
	{2, 3, 9},  -- Silenced, 9mm, Deagle
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

local gzData = nil
local enteredPoint = false
local leaveTime = nil
local preventHeal = false

local getItemFromBM = 0
local gettingItem = false
local currentKey = nil

ffi.cdef[[
	struct stGangzone {
		float fPosition[4];
		uint32_t dwColor;
		uint32_t dwAltColor;
	};

	struct stGangzonePool {
		struct stGangzone *pGangzone[1024];
		int iIsListed[1024];
	};
]]

function loadConfigs()
	local ignoreKeys = {
		{"AutoVest", "skins"}, {"AutoVest", "names"}, 
		{"Keybinds", "BlackMarket1"}, {"Keybinds", "BlackMarket2"}, {"Keybinds", "BlackMarket3"},
		{"Keybinds", "FactionLocker"},
		{"Keybinds", "BikeBind"},
		{"Keybinds", "SprintBind"},
		{"Keybinds", "Frisk"},
		{"Keybinds", "TakePills"},
		{"Keybinds", "Accept"},
		{"Keybinds", "Offer"},
		{"BlackMarket", "Kit1"},
		{"BlackMarket", "Kit2"},
		{"BlackMarket", "Kit3"},
		{"BlackMarket", "Locations"}
	}

	-- Handle Config File
    local success, config, err = handleConfigFile(getFile("settings"), autobind_defaultSettings, autobind, ignoreKeys)
	if not success then
		print("Failed to handle config file: " .. err)
		return
	end
	autobind = config
end

-- Initialize
function main()
	-- Check if SAMP/SAMPFUNCS is loaded
	if not isSampLoaded() or not isSampfuncsLoaded() then return end

	-- Create Directories
	local paths = getPath(nil)
    for _, dir in pairs({"config", "settings", "resource", "skins"}) do
        createDirectory(paths[dir])
    end

	-- Load Configs
	loadConfigs()

	-- Fix Factions Mode (Temporary)
	if autobind.Settings.mode == "Factions" then
		autobind.Settings.mode = "Faction"
	end

	-- Wait for SAMP
    while not isSampAvailable() do wait(100) end

	-- Register Menu Command
	sampRegisterChatCommand(scriptName, function()
		menu.pageId = 1
		menu.settings[0] = not menu.settings[0]
	end)

	sampRegisterChatCommand("areyouin", function()
		formattedAddChatMessage("Entered Point: " .. (enteredPoint and "true" or "false"))
	end)

	-- Register Chat Commands
	if autobind.Settings.enable then
		registerChatCommands()
	end

	-- Download Skins
	downloadSkins()

	-- Wait for SAMP to be connected
	while sampGetGamestate() ~= 3 do wait(100) end

	-- Fetch Skins
	if autobind.AutoVest.autoFetchSkins then
		fetchDataFromURL(autobind.AutoVest.skinsUrl, 'skins', function(decodedData)
			autobind.AutoVest.skins = decodedData
		end)
	end

	-- Fetch Names
	if autobind.AutoVest.autoFetchNames then
		fetchDataFromURL(autobind.AutoVest.namesUrl, 'names', function(decodedData)
			autobind.AutoVest.names = decodedData
		end)
	end

	-- Create Threads
	local startedThreads, failedThreads = createThreads()
	print(string.format("%s v%s has loaded successfully! Threads: %s.", firstToUpper(scriptName), scriptVersion, table.concat(startedThreads, ", ")))
	if #failedThreads > 0 then
		print("Threads failed to start: " .. table.concat(failedThreads, ", "))
	end

	-- Resume Threads
	while true do wait(1) 
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

-- Heal timer
function checkHeal()
	if localClock() - timers.Heal.last < timers.Heal.timer then
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

	if checkHeal() then
		local timeLeft = math.ceil(timers.Heal.timer - (currentTime - timers.Heal.last))
		return string.format("You must wait %d seconds before healing.", timeLeft > 1 and timeLeft or 1)
	end

	if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
		for _, player in ipairs(getVisiblePlayers(4, "all")) do
			if autoaccept and accepter.received then
				if sampGetPlayerNickname(player.playerId) == accepter.playerName then
					sampSendChat("/accept bodyguard")
					timers.AcceptCD.last = currentTime
					return
				end
			end
		end
		return accepter.received and string.format("You are not close enough to %s (%d)", accepter.playerName:gsub("_", " "), accepter.playerId) or "No one offered you bodyguard."
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
			local success, message = pcall(checkAndAcceptVest, accepter.enable)
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

	-- Adjustable Z axis limits
	local zTopLimit = 0.7  -- Top limit of the Z axis
	local zBottomLimit = -0.7  -- Bottom limit of the Z axis

	-- Function to check if the player is within any black market location
	local function isInBlackMarketLocation()
		local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
		for _, location in pairs(autobind.BlackMarket.Locations) do
			local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, location.x, location.y, location.z)
			local zDifference = playerZ - location.z
			print(distance, zDifference)
			if distance <= location.radius and zDifference <= zTopLimit and zDifference >= zBottomLimit then
				return true
			end
		end
		return false
	end

	-- Function to check if the player already has the item
	local function playerHasItem(item)
		if item.weapon then
			return hasCharGotWeapon(ped, item.weapon)
		elseif item.label == 'Health/Armor' then
			local health = getCharHealth(ped) - 5000000
			local armor = getCharArmour(ped)
			return health == 100 and armor == 100
		end
		return false
	end

	-- Handle Black Market
	local function handleBlackMarket(kitNumber)
		if isPlayerControlOn(h) then
			if not checkMuted() then
				if isInBlackMarketLocation() then
					getItemFromBM = kitNumber
					local kit = autobind.BlackMarket["Kit" .. kitNumber]
					for _, index in ipairs(kit) do
						local item = blackMarketItems[index]
						if item then
							if not playerHasItem(item) then
								currentKey = item.index
								gettingItem = true
								sampSendChat("/bm")
								repeat wait(0) until not gettingItem
							else
								formattedAddChatMessage(string.format("{FFFF00}Skipping item: %s (already have it)", item.label))
							end
						end
					end
					getItemFromBM = 0
					gettingItem = false
					currentKey = nil
				else
					formattedAddChatMessage("{FF0000}You are not at the black market!")
				end
			else
				formattedAddChatMessage("{FF0000}You have been muted for spamming, please wait.")
			end
		else
			formattedAddChatMessage("{FF0000}You are frozen, please wait.")
		end
	end
	
	local function blackMarket1()
		handleBlackMarket(1)
	end
	
	local function blackMarket2()
		handleBlackMarket(2)
	end
	
	local function blackMarket3()
		handleBlackMarket(3)
	end
	
	local function factionLocker()

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
					BlackMarket1 = blackMarket1,
					BlackMarket2 = blackMarket2,
					BlackMarket3 = blackMarket3,
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

-- Capture Spam Thread
local function createCaptureSpamThread()
    local lastCaptureTime = 0
    local captureInterval = 1.5

    local function createCaptureSpam()
        local currentTime = localClock()
        if currentTime - lastCaptureTime >= captureInterval then
            sampSendChat("/capturf")
            lastCaptureTime = currentTime
        end
    end

    threads.captureSpam = coroutine.create(function()
        while true do
            if autobind.Settings.enable and captureSpam and not checkMuted() and checkAdminDuty() then
                local status, err = pcall(createCaptureSpam)
                if not status then
                    print("Error in capture spam thread: " .. err)
                end
            end
            coroutine.yield()
        end
    end)
end

-- Pointbounds Thread
local function createPointboundsThread()
	-- Get the gangzone pool pointer
	gzData = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())

	-- Create the pointbounds
	local function createPointbounds()
		if autobind.Settings.mode == "Family" then
			if not enteredPoint then
				for i = 0, 1023 do
					if gzData.iIsListed[i] ~= 0 and gzData.pGangzone[i] ~= nil then
						local pos = gzData.pGangzone[i].fPosition
						local color = gzData.pGangzone[i].dwColor
						local ped_pos = { getCharCoordinates(PLAYER_PED) }
				
						local min1, max1 = math.min(pos[0], pos[2]), math.max(pos[0], pos[2])
						local min2, max2 = math.min(pos[1], pos[3]), math.max(pos[1], pos[3])
				
						-- Check if player is within the gangzone
						if i >= 34 and i <= 45 then
							if ped_pos[1] >= min1 and ped_pos[1] <= max1 and ped_pos[2] >= min2 and ped_pos[2] <= max2 and color == 2348810495 then
								enteredPoint = true
								break
							else
								if enteredPoint then
									leaveTime = os.time()
									preventHeal = true
								end
								enteredPoint = false
							end
						end
					end
				end
			end
		end
	end

    threads.pointbounds = coroutine.create(function()
        while true do
            if autobind.Settings.enable then
                local status, err = pcall(createPointbounds)
                if not status then
                    print("Error in pointbounds thread: " .. err)
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
	createPointboundsThread()

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
	if checkAdminDuty() then
		captureSpam = not captureSpam
		formattedAddChatMessage(captureSpam and string.format("{FFFF00}Starting capture attempt... (type /%s to toggle)", commands.tcap) or "{FFFF00}Capture spam ended.")
	end
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
			accepter.enable = not accepter.enable
			formattedAddChatMessage(string.format("Auto Accept is now %s.", accepter.enable and 'enabled' or 'disabled'))
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
			if accepter.enable then
				formattedAddChatMessage(string.format("Auto Accept is now disabled. because you are now in Faction Mode."))
				accepter.enable = false
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
		formattedAddChatMessage(string.format("You are not close enough to %s.", accepter.playerName:gsub("_", " ")))
		return false
	end

	-- Reset heal timer (5 seconds)
	if text:match("You can't heal if you were recently shot, except within points, events, minigames, and paintball.") then
		resetTimer(5, timers.Heal)
	end

	local nickname = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
	if nickname and color == 869072810 then
		lua_thread.create(function()
			wait(0)
			if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 and ((accepter.enable and not checkHeal()) or (accepter.enable and enteredPoint)) and not checkMuted() then
				accepter.playerName = nickname:gsub("%s+", "_") -- Overlay
				accepter.playerId = sampGetPlayerIdByNickname(accepter.playerName)
				sampSendChat("/accept bodyguard")
				accepter.received = false
				wait(1000)
			end

			if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
				accepter.playerName = nickname:gsub("%s+", "_") -- Overlay
				accepter.playerId = sampGetPlayerIdByNickname(accepter.playerName)
				accepter.received = true
			end
		end)
	end

	-- You can't afford the Protection!
	if text:match("You can't afford the Protection!") then
		accepter.received = false
	end

	-- needs to be renabled via /pay or /withdraw/awithdraw

	local nickname = text:match("%* You accepted the protection for %$200 from (.+)%.")
	if nickname then
		accepter.playerName = ""
		accepter.playerId = -1
		accepter.received = false
	end

	if text:match("You are not a Diamond Donator!") then
		timers.Vest.timer = guardTime
		autobind.AutoVest.donor = false
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

    if getItemFromBM > 0 then
        if text:match("You are not a Sapphire or Diamond Donator!") and color == -1077886209 then
            getItemFromBM = 0
            gettingItem = false
            currentKey = nil
        end
    end

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
	print("SENDER", senderID, "DAMAGE", damage, "WEAPON", weapon, "BODYPART", Bodypart)
	if senderID ~= 65535 and damage > 0 then
		if autobind.Settings.mode == "Family" then
			if preventHeal then
				local currentTime = os.time()
				if currentTime - leaveTime >= 180 then
					preventHeal = false
				else
					print("Heal timer is prevented for 3 minutes after leaving the pointbounds.")
					return
				end
			end
		end

		if not enteredPoint or autobind.Settings.mode == "Faction" then
			timers.Heal.last = localClock()
		end
	end
end

-- Dynamic Black Market Locations (From the server)
function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
	if text:match("Type /blackmarket to purchase items") or text:match("Type /dlocker to purchase items") then
		autobind.BlackMarket.Locations[id] = {x = position.x, y = position.y, z = position.z, radius = 13.0}
	end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if getItemFromBM > 0 then
        if not title:find("Black Market") then 
            getItemFromBM = 0 
            gettingItem = false
            currentKey = nil
            return false 
        end
        sampSendDialogResponse(id, 1, currentKey, nil)
        gettingItem = false
        return false
    end
end

function sampev.onTogglePlayerSpectating(state)
    specState = state
end

imgui.OnInitialize(function()
	-- Disable ini file
    imgui.GetIO().IniFilename = nil

	-- Load FontAwesome Icons
	local defaultIcons = {
		"SHIELD_PLUS", "POWER_OFF", "FLOPPY_DISK", "REPEAT", "PERSON_BOOTH", "ERASER",
		"RETWEET", "GEAR", "CART_SHOPPING", "LINK", "DOLLAR_SIGN"
    }
    loadFontAwesome6Icons(defaultIcons, 12, "solid")

	-- Load the font with the desired size
	local fontFile = getFolderPath(0x14) .. '\\trebucbd.ttf'
	assert(doesFileExist(fontFile), '[autobind] Font "' .. fontFile .. '" doesn\'t exist!')
	skinEditor.font = imgui.GetIO().Fonts:AddFontFromFileTTF(fontFile, skinEditor.fontSize)

	-- Load FontAwesome Icons
	local keyEditorIcons = {"KEYBOARD", "KEYBOARD_DOWN"}
    loadFontAwesome6Icons(keyEditorIcons, 12, "solid")

	-- Load Skins
	for i = 0, 311 do
		if skinTexture[i] == nil then
			skinTexture[i] = imgui.CreateTextureFromFile(string.format("%s\\Skin_%d.png", getPath("skins"), i))
		end
	end

	-- Apply the custom style
    apply_custom_style()
end)

local function createRow(label, tooltip, setting, toggleFunction, sameLine)
    if imgui.Checkbox(label, new.bool(setting)) then
        toggleFunction()
    end
    imgui.CustomTooltip(tooltip)

    if sameLine then
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetWindowWidth() / 2.0)
    end
end

imgui.OnFrame(function() return menu.settings[0] end,
function()
	assert(isSampLoaded(), "Samp not loaded")
	if not isSampAvailable() then return end

	local title = string.format("%s %s - v%s", fa.SHIELD_PLUS, firstToUpper(scriptName), scriptVersion)
	local newPos, status = imgui.handleWindowDragging("Settings", autobind.Window.Pos, imgui.ImVec2(600, 428), imgui.ImVec2(0.5, 0.5))
    if status and menu.settings[0] then autobind.Window.Pos = newPos end
    imgui.SetNextWindowPos(autobind.Window.Pos, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(588, 420), imgui.Cond.Always)
	if imgui.Begin(title, menu.settings, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
		-- Define button properties for the first child
		local buttons1 = {
			{icon = fa.POWER_OFF, tooltip = string.format('%s Toggles all functionalities. (%s%s{FFFFFF})', fa.POWER_OFF, autobind.Settings.enable and '{00FF00}' or '{FF0000}', autobind.Settings.enable and 'ON' or 'OFF'), action = function()
				autobind.Settings.enable = not autobind.Settings.enable
				if autobind.Settings.enable then
					registerChatCommands()
				else
					for _, command in pairs(commands) do
						sampUnregisterChatCommand(command)
					end
				end
			end, color = function() return autobind.Settings.enable and imgui.ImVec4(0.15, 0.59, 0.18, 0.7) or imgui.ImVec4(1, 0.19, 0.19, 0.5) end},
			{icon = fa.FLOPPY_DISK, tooltip = 'Save configuration', action = function()
				saveConfigWithErrorHandling(getFile("settings"), autobind)
			end},
			{icon = fa.REPEAT, tooltip = 'Reload configuration', action = function()
				loadConfigs()
			end},
			{icon = fa.ERASER, tooltip = 'Load default configuration', action = function()
				ensureDefaults(autobind, autobind_defaultSettings, true, {{"Settings", "mode"}, {"Settings", "freq"}})
			end},
			{icon = fa.RETWEET .. ' Update', tooltip = 'Check for update [Disabled]', action = function()
				-- do something?
			end}
		}

		-- Define button properties for the second child
		local buttons2 = {
			{icon = fa("GEAR"), label = "Settings", pageId = 1, tooltip = "Open Settings"},
			{icon = fa("PERSON_BOOTH"), label = autobind.Settings.mode .. " Skins", pageId = 2, tooltip = "Open Skins"},
			{icon = fa("PERSON_BOOTH"), label = "Names", pageId = 3, tooltip = "Open Names"}
		}

		-- First child
		if imgui.BeginChild("##1", imgui.ImVec2(85, 382), false) then
			for i, button in ipairs(buttons1) do
				imgui.SetCursorPos(imgui.ImVec2(0, (i - 1) * 76))
				if imgui.CustomButton(button.icon, button.color and button.color() or imgui.ImVec4(0.16, 0.16, 0.16, 0.9), imgui.ImVec4(0.40, 0.12, 0.12, 1), imgui.ImVec4(0.30, 0.08, 0.08, 1), imgui.ImVec2(75, 75)) then
					button.action()
				end
				imgui.CustomTooltip(button.tooltip)
			end
		end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(85, 28))

		-- Second child
		if imgui.BeginChild("##2", imgui.ImVec2(500, 88), false) then
			for i, button in ipairs(buttons2) do
				imgui.SetCursorPos(imgui.ImVec2((i - 1) * 165, 0))
				if imgui.CustomButton(string.format("%s  %s", button.icon, button.label), menu.pageId == button.pageId and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9), imgui.ImVec4(0.40, 0.12, 0.12, 1), imgui.ImVec4(0.30, 0.08, 0.08, 1), imgui.ImVec2(165, 75)) then
					menu.pageId = button.pageId
				end
				if menu.pageId ~= i then
					imgui.CustomTooltip(button.tooltip)
				end
			end
		end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(85, 110))
		if imgui.BeginChild("##3", imgui.ImVec2(500, 276), false) then
			if menu.pageId == 1 then
				imgui.SetCursorPos(imgui.ImVec2(10, 1))
				imgui.BeginChild("##config", imgui.ImVec2(300, 255), false)
					-- Autobind/Capture
					imgui.Text('Auto Bind:')
					createRow('Capture Spam', 'Capture spam will automatically type /capturf every 1.5 seconds.', captureSpam, toggleCaptureSpam, true)
				
					local switchTurf = autobind.Settings.mode:lower() .. "Turf"
					createRow('Capture (Turfs)', 'Capture (Turfs) will automatically type /capturf at signcheck time.', autobind.Settings[switchTurf], function()
						autobind.Settings[switchTurf] = not autobind.Settings[switchTurf]
						if switchTurf == "familyTurf" then
							autobind.Settings.capturePoint = false
						end
					end, false)
				
					if autobind.Settings.mode == "Family" then
						createRow('Disable capturing', 'Disable capturing after capturing: turns off auto capturing after the point/turf has been secured.', autobind.Settings.disableAfterCapturing, function()
							autobind.Settings.disableAfterCapturing = not autobind.Settings.disableAfterCapturing
						end, true)
				
						createRow('Capture (Points)', 'Capture (Points) will automatically type /capturf at signcheck time.', autobind.Settings.capturePoint, function()
							autobind.Settings.capturePoint = not autobind.Settings.capturePoint
							if autobind.Settings.capturePoint then
								autobind.Settings.familyTurf = false
							end
						end, false)
					end
				
					createRow('Accept Repair', 'Accept Repair will automatically accept repair requests.', autobind.AutoBind.autoRepair, function()
						autobind.AutoBind.autoRepair = not autobind.AutoBind.autoRepair
					end, false)
				
					if autobind.Settings.mode == "Faction" then
						createRow('Auto Badge', 'Automatically types /badge after spawning from the hospital.', autobind.AutoBind.autoBadge, function()
							autobind.AutoBind.autoBadge = not autobind.AutoBind.autoBadge
						end, true)
					end
				
					-- Auto Vest
					imgui.NewLine()
					imgui.Text('Auto Vest:')
					createRow('Enable', 'Enable for automatic vesting.', autobind.AutoVest.enable, function()
						autobind.AutoVest.enable = not autobind.AutoVest.enable
					end, true)
				
					createRow('Diamond Donator', 'Enable for Diamond Donators. Uses /guardnear does not have armor/paused checks.', autobind.AutoVest.donor, function()
						autobind.AutoVest.donor = not autobind.AutoVest.donor
						timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime
					end, false)
				
					-- Accept
					createRow('Auto Accept', 'Accept Vest will automatically accept vest requests.', accepter.enable, function()
						accepter.enable = not accepter.enable
					end, false)
				
					imgui.NewLine()
					imgui.Text('Frisk:')
					createRow('Targeting', 'Must be targeting a player to frisk. (Green Blip above the player)', autobind.Settings.Frisk.target, function()
						autobind.Settings.Frisk.target = not autobind.Settings.Frisk.target
					end, true)
				
					createRow('Must Aim', 'Must be aiming to frisk.', autobind.Settings.Frisk.mustAim, function()
						autobind.Settings.Frisk.mustAim = not autobind.Settings.Frisk.mustAim
					end, false)
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(322, 1))
				if imgui.BeginChild("##keybinds", imgui.ImVec2(175, 270), false) then
					-- Define the key editor table
					local keyEditors = {
						{label = "Accept", key = "Accept", description = "Accepts a vest from someone. (Options are to the left)"},
						{label = "Offer", key = "Offer", description = "Offers a vest to someone. (Options are to the left)"},
						{label = "Take-Pills", key = "TakePills", description = "Types /takepills."},
						{label = "Frisk", key = "Frisk", description = "Frisks a player. (Options are to the left)"},
						{label = "Bike-Bind", key = "BikeBind", description = "Makes bikes/motorcycles/quads faster by holding the bind key while riding."},
						{label = "Sprint-Bind", key = "SprintBind", description = "Makes you sprint faster by holding the bind key while sprinting. (This is only the toggle)"},
					}

					-- Use the key editor table to call keyEditor for each entry
					imgui.SetCursorPos(imgui.ImVec2(0, 6))
					for index, editor in ipairs(keyEditors) do
						keyEditor(editor.label, editor.key, editor.description)
					end
				end
				imgui.EndChild()
			end

			if menu.pageId == 2 then
				imgui.SetCursorPos(imgui.ImVec2(10, 1))
				if imgui.BeginChild("##skins", imgui.ImVec2(487, 270), false) then
					if autobind.Settings.mode == "Family" then
						imgui.PushItemWidth(334)
						local url = new.char[128](autobind.AutoVest.skinsUrl)
						if imgui.InputText('##skins_url', url, sizeof(url)) then
							autobind.AutoVest.skinsUrl = u8:decode(str(url))
						end
						imgui.CustomTooltip(string.format('URL to fetch skins from, must be a JSON array of skin IDs,\n%s "%s"', fa.LINK, autobind.AutoVest.skinsUrl))
						imgui.SameLine()
						imgui.PopItemWidth()
						if imgui.Button("Fetch") then
							fetchDataFromURL(autobind.AutoVest.skinsUrl, 'skins', function(decodedData)
								autobind.AutoVest.skins = decodedData
							end)
						end
						imgui.CustomTooltip("Fetches skins from provided URL")
						imgui.SameLine()
						if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchSkins)) then
							autobind.AutoVest.autoFetchSkins = not autobind.AutoVest.autoFetchSkins
						end
						imgui.CustomTooltip("Fetch skins at startup")

						local columns = 8  -- Number of columns in the grid
						local imageSize = imgui.ImVec2(50, 80)  -- Size of each image
						local spacing = 10.0  -- Spacing between images
						local start = imgui.GetCursorPos()  -- Starting position
					
						for i, skinId in ipairs(autobind.AutoVest.skins) do
							-- Calculate position
							local column = (i - 1) % columns
							local row = math.floor((i - 1) / columns)
							local posX = start.x + column * (imageSize.x + spacing)
							local posY = start.y + row * (imageSize.y + spacing / 4)
					
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
							imgui.CustomTooltip("Skin "..skinId)
						end
					
						-- Add the "Add Skin" button in the next available slot
						local addButtonIndex = #autobind.AutoVest.skins + 1
						local column = (addButtonIndex - 1) % columns
						local row = math.floor((addButtonIndex - 1) / columns)
						local posX = start.x + column * (imageSize.x + spacing)
						local posY = start.y + row * (imageSize.y + spacing / 4)
					
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
						local imageSize = imgui.ImVec2(50, 80)  -- Size of each image
						local spacing = 10.0  -- Spacing between images
						local start = imgui.GetCursorPos()  -- Starting position
					
						for i, skinId in ipairs(factions.skins) do
							-- Calculate position
							local column = (i - 1) % columns
							local row = math.floor((i - 1) / columns)
							local posX = start.x + column * (imageSize.x + spacing)
							local posY = start.y + row * (imageSize.y + spacing / 4)
					
							-- Set position and draw the image
							imgui.SetCursorPos(imgui.ImVec2(posX, posY))
							imgui.Image(skinTexture[skinId], imageSize)
							imgui.CustomTooltip("Skin "..skinId)
						end
					end
				end
				imgui.EndChild()
			end

			if menu.pageId == 3 then
				imgui.SetCursorPos(imgui.ImVec2(10, 1))
				if imgui.BeginChild("##names", imgui.ImVec2(487, 263), false) then
					imgui.PushItemWidth(326)
					local url = new.char[128](autobind.AutoVest.namesUrl)
					if imgui.InputText('##names_url', url, sizeof(url)) then
						autobind.AutoVest.namesUrl = u8:decode(str(url))
					end
					imgui.CustomTooltip(string.format('URL to fetch names from, must be a JSON array of names,\n%s "%s"', fa.LINK, autobind.AutoVest.namesUrl))
					imgui.SameLine()
					imgui.PopItemWidth()
					if imgui.Button("Fetch") then
						fetchDataFromURL(autobind.AutoVest.namesUrl, 'names', function(decodedData)
							autobind.AutoVest.names = decodedData
						end)
					end
					imgui.CustomTooltip("Fetches names from provided URL")
					imgui.SameLine()
					if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchNames)) then
						autobind.AutoVest.autoFetchNames = not autobind.AutoVest.autoFetchNames
					end
					imgui.CustomTooltip("Fetch names at startup")
				
					local itemsPerRow = 3  -- Number of items per row
					local itemCount = 0
				
					for key, value in pairs(autobind.AutoVest.names) do
						local nick = new.char[128](value)
						imgui.PushItemWidth(130)  -- Adjust the width of the input field
						if imgui.InputText('##Nickname'..key, nick, sizeof(nick)) then
							autobind.AutoVest.names[key] = u8:decode(str(nick))
						end
						imgui.PopItemWidth()
						imgui.SameLine()
						if imgui.Button(u8"x##"..key) then
							table.remove(autobind.AutoVest.names, key)
						end
				
						itemCount = itemCount + 1
						if itemCount % itemsPerRow ~= 0 then
							imgui.SameLine()
						end
					end
					if imgui.Button(u8"Add Name", imgui.ImVec2(130, 20)) then
						autobind.AutoVest.names[#autobind.AutoVest.names + 1] = "Name"
					end
				end
				imgui.EndChild()
			end
		end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(92, 386.5))
		if imgui.BeginChild("##5", imgui.ImVec2(500, 20), false) then
			if imgui.Checkbox('Autosave', new.bool(autobind.Settings.autoSave)) then
				autobind.Settings.autoSave = not autobind.Settings.autoSave
			end
			imgui.CustomTooltip('Automatically saves your settings when you exit the game')
			imgui.SameLine()
			if imgui.Checkbox('Everyone', new.bool(autobind.AutoVest.everyone)) then
				autobind.AutoVest.everyone = not autobind.AutoVest.everyone
			end
			imgui.CustomTooltip('With this enabled, the vest will be applied to everyone on the server')
			imgui.SameLine()
			if imgui.Button(fa.CART_SHOPPING .. " BM Settings") then
				menu.blackmarket[0] = not menu.blackmarket[0]
			end
			imgui.CustomTooltip('Open the Black Market settings')
			if autobind.Settings.mode == "Faction" then
				imgui.SameLine()
				if imgui.Button(fa.CART_SHOPPING .. " Faction Locker") then
					menu.factionlocker[0] = not menu.factionlocker[0]
				end
				imgui.CustomTooltip('Open the Faction Locker settings')
			end
		end
		imgui.EndChild()
	end
	imgui.End()
end)

imgui.OnFrame(function() return menu.settings[0] and menu.skins[0] end,
function()
	assert(isSampLoaded(), "Samp not loaded")
	if not isSampAvailable() then return end

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
			imgui.CustomTooltip("Skin "..i.."")
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
    imgui.Text(title.. ":")
    local handledIndices = {}
    
    -- Handle exclusive groups first
    for _, group in ipairs(exclusiveGroups) do
        for _, index in ipairs(group) do
            local item = items[index]
            if item then
                createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
				imgui.CustomTooltip(string.format("Price: $%s", formatNumber(item.price)))
                imgui.SameLine()
                table.insert(handledIndices, index)
            end
        end
        imgui.NewLine()
    end
    
    -- Handle remaining items
    for index, item in ipairs(items) do
        if not tableContains(handledIndices, index) then
            createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
			imgui.CustomTooltip(string.format("Price: $%s", formatNumber(item.price)))
        end
    end
end

local kitId = 1

imgui.OnFrame(function() return menu.settings[0] and menu.blackmarket[0] end,
function()
	-- Returns if Samp is not loaded
    assert(isSampLoaded(), "Samp not loaded")

	-- Returns if Samp is not available
    if not isSampAvailable() then return end

	-- Blackmarket Window

	local newPos, status = imgui.handleWindowDragging("BlackMarket", autobind.BlackMarket.Pos, imgui.ImVec2(226, 290), imgui.ImVec2(0.5, 0.5))
    if status and menu.settings[0] then autobind.BlackMarket.Pos = newPos end

	local totalPrice = 0
	for _, index in ipairs(autobind.BlackMarket[string.format("Kit%d", kitId)]) do
		local item = blackMarketItems[index]
		if item and item.price then
			totalPrice = totalPrice + item.price
		end
	end

    imgui.SetNextWindowPos(autobind.BlackMarket.Pos, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    if imgui.Begin(string.format("BM - Kit: %d - $%s", kitId, formatNumber(totalPrice)), menu.blackmarket, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
        local availWidth = imgui.GetContentRegionAvail().x
        local buttonWidth = availWidth / 3 - 5

		-- Define a table to map kitId to key and menu data
		local kits = {
			{id = 1, key = 'BlackMarket1', menu = autobind.BlackMarket.Kit1},
			{id = 2, key = 'BlackMarket2', menu = autobind.BlackMarket.Kit2},
			{id = 3, key = 'BlackMarket3', menu = autobind.BlackMarket.Kit3}
		}

		-- Create buttons for each kit
		for _, kit in ipairs(kits) do
			if imgui.Button(fa.CART_SHOPPING .. " Kit " .. kit.id, imgui.ImVec2(buttonWidth, 0)) then
				kitId = kit.id
			end
			imgui.SameLine()
		end

		-- Remove the last SameLine to avoid layout issues
		imgui.NewLine()

		-- Display the key editor and menu based on the selected kitId
		for _, kit in ipairs(kits) do
			if kitId == kit.id then
				keyEditor("Keybind", kit.key)
				createMenu('Selection', blackMarketItems, kit.menu, blackMarketExclusiveGroups, 4)
			end
		end
    end
    imgui.End()
end)

imgui.OnFrame(function() return menu.settings[0] and menu.factionlocker[0] end,
function()
	-- Returns if Samp is not loaded
    assert(isSampLoaded(), "Samp not loaded")

	-- Returns if Samp is not available
    if not isSampAvailable() then return end
	
	-- Faction Locker Window
    imgui.SetNextWindowPos(imgui.ImVec2(autobind.Window.Pos.x + (600 * 0.607), autobind.Window.Pos.y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    if imgui.Begin("Faction Locker", menu.factionlocker, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
		keyEditor("Keybind", "FactionLocker")
        createMenu('Selection', lockerMenuItems, autobind.FactionLocker, lockerExclusiveGroups, 4)
    end
    imgui.End()
end)

-- Custom function to display tooltips based on key type
local function showKeyTypeTooltip(keyType)
    local tooltips = {
        KeyDown = "Triggers when the key is held down. (Repeats until the key is released)",
        KeyPressed = "Triggers when the key is just pressed down. (Does not repeat until the key is released and pressed again)."
    }
    imgui.CustomTooltip(tooltips[keyType] or "Unknown key type.")
end

local function correctKeyName(keyName)
	return keyName:gsub("Left ", ""):gsub("Right ", ""):gsub("Context ", ""):gsub("Numpad", "Num")
end

-- Key Editor
function keyEditor(title, index, description)
    if not autobind.Keybinds[index] then
        print("Warning: autobind.Keybinds[" .. index .. "] is nil")
        return
    end

    if not autobind.Keybinds[index].Keys then
        autobind.Keybinds[index].Keys = {}
    end

    -- Adjustable parameters
    local fontSize = 18  -- Font size for the text
    local padding = imgui.ImVec2(8, 6)  -- Padding around buttons
    local comboWidth = 70  -- Width of the combo box
    local verticalSpacing = 2  -- Vertical spacing after the last key entry

    -- Load the font with the desired size
    imgui.PushFont(skinEditor.font)

    imgui.BeginGroup()

    -- Title and description
    imgui.AlignTextToFramePadding()
    imgui.Text(title .. ":")
    if description then
        imgui.CustomTooltip(description)
    end

    imgui.SameLine()
    if imgui.Checkbox((autobind.Keybinds[index].Toggle and "Enabled" or "Disabled") .. "##" .. index, new.bool(autobind.Keybinds[index].Toggle)) then
        autobind.Keybinds[index].Toggle = not autobind.Keybinds[index].Toggle
    end
    imgui.CustomTooltip(string.format("Toggle this key binding. %s", autobind.Keybinds[index].Toggle and "{00FF00}(Enabled)" or "{FF0000}(Disabled)"))

    for i, key in ipairs(autobind.Keybinds[index].Keys) do
        local buttonText = changekey[index] and changekey[index] == i and fa.KEYBOARD_DOWN or (key ~= 0 and correctKeyName(vk.id_to_name(key)) or fa.KEYBOARD)
        local buttonSize = imgui.CalcTextSize(buttonText) + padding

        -- Button to change key
        imgui.AlignTextToFramePadding()
        if imgui.Button(buttonText .. '##' .. index .. i, buttonSize) then
            changekey[index] = i
            lua_thread.create(function()
                while changekey[index] == i do 
                    wait(0)
                    local keydown, result = getDownKeys()
                    if result then
                        autobind.Keybinds[index].Keys[i] = keydown
                        changekey[index] = false
                    end
                end
            end)
        end
        imgui.CustomTooltip(string.format("Press to change, Key: %d", i))

        -- Combo box for key type selection
        imgui.SameLine()
        local keyTypes = {"KeyDown", "KeyPressed"}
        
        local currentType = autobind.Keybinds[index].Type
        if type(currentType) == "table" then
            currentType = currentType[i] or "KeyDown"
        elseif type(currentType) ~= "string" then
            currentType = "KeyDown"
        end
        
        imgui.PushItemWidth(comboWidth)
        if imgui.BeginCombo("##KeyType"..index..i, currentType:gsub("Key", "")) then
            for _, keyType in ipairs(keyTypes) do
                if imgui.Selectable(keyType:gsub("Key", ""), currentType == keyType) then
                    if type(autobind.Keybinds[index].Type) ~= "table" then
                        autobind.Keybinds[index].Type = {autobind.Keybinds[index].Type or "KeyDown"}
                    end
                    autobind.Keybinds[index].Type[i] = keyType
                end
                showKeyTypeTooltip(keyType)
            end
            imgui.EndCombo()
        end
        imgui.PopItemWidth()
        showKeyTypeTooltip(currentType)

        -- Add the "-" button next to the first key slot if there are multiple keys
        if i == 1 and #autobind.Keybinds[index].Keys > 1 then
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local minusButtonSize = imgui.CalcTextSize("-") + padding
            if imgui.Button("-##remove" .. index, minusButtonSize) then
                table.remove(autobind.Keybinds[index].Keys)
                if type(autobind.Keybinds[index].Type) == "table" then
                    table.remove(autobind.Keybinds[index].Type)
                end
            end
            imgui.CustomTooltip("Remove this key binding.")
        end

        -- Add the "+" button next to the last key slot
        if i == #autobind.Keybinds[index].Keys then
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local plusButtonSize = imgui.CalcTextSize("+") + padding
            if imgui.Button("+##add" .. index, plusButtonSize) then
                local nextIndex = #autobind.Keybinds[index].Keys + 1
                if nextIndex <= 3 then
                    table.insert(autobind.Keybinds[index].Keys, 0)
                    if type(autobind.Keybinds[index].Type) ~= "table" then
                        autobind.Keybinds[index].Type = {autobind.Keybinds[index].Type or "KeyDown"}
                    end
                    table.insert(autobind.Keybinds[index].Type, "KeyDown")
                end
            end
            imgui.CustomTooltip("Add a new key binding.")
        end
    end

    -- If there are no keys, show the "+" button
    if #autobind.Keybinds[index].Keys == 0 then
        imgui.AlignTextToFramePadding()
        local plusButtonSize = imgui.CalcTextSize("+") + padding
        if imgui.Button("+##add" .. index, plusButtonSize) then
            table.insert(autobind.Keybinds[index].Keys, 0)
            if type(autobind.Keybinds[index].Type) ~= "table" then
                autobind.Keybinds[index].Type = {autobind.Keybinds[index].Type or "KeyDown"}
            end
            table.insert(autobind.Keybinds[index].Type, "KeyDown")
        end
        imgui.CustomTooltip("Add a new key binding.")
    end

    -- Add vertical spacing after the last key entry
    imgui.Dummy(imgui.ImVec2(0, verticalSpacing))

    imgui.EndGroup()
    imgui.PopFont()
end

-- Fetch Data From URL
function fetchDataFromURL(url, path, callback)
	-- Debug: Starting download
	print("Starting download from URL:", url, "to path:", path)
	
	downloadFiles({{url = url, path = getFile(path), replace = true}}, function(result)
		-- Debug: Download result
		print("Download result:", result)
		
		if result then
			local file = io.open(getFile(path), "r")
			if file then
				-- Debug: File opened successfully
				print("File opened successfully:", path)
				
				local content = file:read("*all")
				file:close()
				
				-- Debug: File content read
				print("File content read:", content)
				
				local success, decoded = pcall(decodeJson, content)
				if success then
					-- Debug: JSON decoded successfully
					print("JSON decoded successfully:", decoded)
					
					if next(decoded) == nil then
						print("JSON format is empty. URL:", url)
					else
						callback(decoded)
					end
				else
					-- Debug: Failed to decode JSON
					print("Failed to decode JSON: " .. decoded, "URL: ", url)
				end
			else
				-- Debug: Error opening file
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
            return handleConfigFile(path, defaults, configVar)
        else
            local result = ensureDefaults(config, defaults, false, ignoreKeys)
            if result then
                local success, err2 = saveConfig(path, config)
                if not success then
                    return false, nil, "Error saving config: " .. err2
                end
            end
            return true, config, nil
        end
    else
        local result = ensureDefaults(configVar, defaults, true)
        if result then
            local success, err = saveConfig(path, configVar)
            if not success then
                return false, nil, "Error saving config: " .. err
            end
        end
    end
    return true, configVar, nil
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

function formatNumber(n)
    n = tostring(n)
    return n:reverse():gsub("...","%0,",math.floor((#n-1)/3)):reverse()
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

function imgui.handleWindowDragging(menuId, pos, size, pivot)
    local mpos = imgui.GetMousePos()
    local offset = {x = size.x * pivot.x, y = size.y * pivot.y}
    local boxPos = {x = pos.x - offset.x, y = pos.y - offset.y}

    -- Get screen resolution
    local screenWidth, screenHeight = imgui.GetIO().DisplaySize.x, imgui.GetIO().DisplaySize.y

    if mpos.x >= boxPos.x and mpos.x <= boxPos.x + size.x and mpos.y >= boxPos.y and mpos.y <= boxPos.y + size.y then
        if imgui.IsMouseClicked(0) and not imgui.IsAnyItemHovered() then
            currentlyDragging = menuId
            tempOffset = {x = mpos.x - boxPos.x, y = mpos.y - boxPos.y}
        end
    end

    if currentlyDragging == menuId then
        if imgui.IsMouseReleased(0) then
            currentlyDragging = nil
        else
            if imgui.IsAnyItemHovered() then
                currentlyDragging = nil
            else
                local newBoxPos = {x = mpos.x - tempOffset.x, y = mpos.y - tempOffset.y}

                -- Clamp the new position within the screen bounds
                newBoxPos.x = math.max(0, math.min(newBoxPos.x, screenWidth - size.x))
                newBoxPos.y = math.max(0, math.min(newBoxPos.y, screenHeight - size.y))

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
    if tooltip then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
        imgui.CustomTooltip(tooltip)
        imgui.PopStyleVar()
    end
    return result
end

function imgui.CustomTooltip(tooltip)
    if imgui.IsItemHovered() and tooltip then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
        imgui.BeginTooltip()
        imgui.TextColoredRGB(tooltip)
        imgui.EndTooltip()
        imgui.PopStyleVar()
    end
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

script_name("autobind")
script_author("akacross")
script_url("https://akacross.net/")

local script_version = 1.8
local script_version_text = '1.8'

require"lib.moonloader"
require"lib.sampfuncs"

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle
local sampev = require 'lib.samp.events'
local mem = require 'memory'
local https = require 'ssl.https'
local dlstatus = require('moonloader').download_status
local vk = require 'vkeys'
local keys  = require 'game.keys'
local wm  = require 'lib.windows.message'
local fa = require 'fAwesome6'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local path = getWorkingDirectory() .. '\\config\\'
local cfgFile = path .. 'autobind.json'
local skinspath = getWorkingDirectory() .. '/resource/' .. 'skins/'
local script_path = thisScript().path
local script_url = "https://raw.githubusercontent.com/akacross/autobind/main/autobind.lua"
local update_url = "https://raw.githubusercontent.com/akacross/autobind/main/autobind.txt"
local skins_url = "https://raw.githubusercontent.com/akacross/autobind/main/resource/skins/"
local resX, resY = getScreenResolution()

local autobind = {}
local autobind_defaultSettings = {
	autosave = true,
	autoupdate = true,
	ddmode = false,
	capturf = false,
	capture = false,
	autoacceptsex = false,
	autoacceptrepair = false,
	disableaftercapping = false,
	factionboth = false,
	enablebydefault = true,
	sound = true,
	timercorrection = true,
	messages = false,
	customskins = true,
	gettarget = false,
	notification = {false, false},
	notification_hide = {true, true},
	showprevest = true,
	notification_capper = true,
	notification_capper_hide = false,
	point_turf_mode = false,
	vestmode = 2,
	timer = 12,
	point_capper_timer = 14,
	turf_capper_timer = 17,
	skinsurl = "https://akacross.net/skins.html",
	skins = {},
	autovestsettingscmd = "autobind",
	helpcmd = "autobind.help",
	vestnearcmd = "vestnear",
	sexnearcmd = "sexnear",
	repairnearcmd = "repairnear",
	hfindcmd = "hfind",
	tcapcmd = "tcap",
	sprintbindcmd = "sprintbind",
	bikebindcmd = "bikebind",
	autoacceptercmd = "av",
	ddmodecmd = "ddmode",
	vestmodecmd = "vestmode",
	factionbothcmd = "factionboth",
	autovestcmd = "autovest",
	turfmodecmd = 'turfmode',
	pointmodecmd = 'pointmode',
	offerpos = {10, 273},
	offeredpos = {10, 348},
	capperpos = {10, 396},
	menupos = {resX / 2, resY / 2},
	names = {},
	Keybinds = {
	  Accept = {Toggle = true, Keybind = VK_MENU..','..VK_V, Dual = true},
	  Offer = {Toggle = true, Keybind = VK_MENU..','..VK_O, Dual = true},
	  BlackMarket = {Toggle = false, Keybind = VK_MENU..','..VK_X, Dual = true},
	  FactionLocker = {Toggle = false, Keybind = VK_MENU..','..VK_X, Dual = true},
	  BikeBind = {Toggle = false, Keybind = VK_SHIFT, Dual = false},
	  SprintBind = {Toggle = true, Keybind = VK_F11, Dual = false},
	  Frisk = {Toggle = false, Keybind = VK_MENU..','..VK_F, Dual = true},
	  TakePills = {Toggle = false, Keybind = VK_F3, Dual = false}
	},
	BlackMarket = {true, false, false, false, false, false, false, false, true, false, false, false, false},
	FactionLocker = {true, true, false, true, false, false, false, false, false, true, true},
	SprintBind = {delay = 10},
	Frisk = {false, false}
}

local _enabled = true
local menu = new.bool(false)
local _menu = 1
local skinmenu = new.bool(false)
local bmmenu = new.bool(false)
local factionlockermenu = new.bool(false)
local helpmenu = new.bool(false)
local _you_are_not_bodyguard = true
local autoaccepter = false
local autoacceptertoggle = false
local specstate = false
local updateskin = false
local timeset = {false, false}
local flashing = {false, false}
local _last_vest = 0
local _last_point_capper = 0
local _last_turf_capper = 0
local _last_point_capper_refresh = 0
local _last_turf_capper_refresh = 0
local sampname = 'Nobody'
local playerid = -1
local sampname2 = 'Nobody'
local playerid2 = -1
local point_capper = 'Nobody'
local turf_capper = 'Nobody'
local point_capper_capturedby = 'Nobody'
local turf_capper_capturedby = 'Nobody'
local point_location = "No captured point"
local turf_location = "No captured turf "
local cooldown = 0
local point_capper_timer = 750
local turf_capper_timer = 1050
local pointtime = 0
local turftime = 0
local pointspam = false
local turfspam = false
local disablepointspam = false
local disableturfspam = false
local hide = {false, false}
local capper_hide = false
local skins = {}
local factions = {61,71,73,120,141,163,164,165,166,191,255,265,266,267,280,281,282,283,284,285,286,287,288,294,312,300,301,306,307,309,310,311}
local factions_color = {-14269954, -7500289, -14911565, -3368653}
local changekey = {}
local changekey2 = {}
local PressType = {KeyDown = isKeyDown, KeyPressed = wasKeyPressed}
local inuse_key = false
local bmbool = false
local bmstate = 0
local bmcmd = 0
local lockerbool = false
local lockerstate = 0
local lockercmd = 0
local inuse_move = false
local temp = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}
local size = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}
--local mpos = {x = 0, y = 0}
local selectedbox = {false, false, false,false}
local skinTexture = {}
local selected = -1
local page = 1
local bike, moto = {[481] = true, [509] = true, [510] = true}, {[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true}
local captog = false
local autofind, cooldown_bool = false, false
local testing = false

local pointnamelist = {
	"Fossil Fuel Company",
	"Materials Pickup 1",
	"Drug Factory",
	"Materials Factory 1",
	"Drug House",
	"Materials Pickup 2",
	"Crack Lab",
	"Materials Factory 2",
	"Auto Export Company",
	"Materials Pickup 3"
}

local turfnamelist = {
	"East Beach",
	"Las Colinas",
	"Playa del Seville",
	"Los Flores",
	"East Los Santos East",
	"East Los Santos West",
	"Jefferson",
	"Glen Park",
	"Ganton",
	"North Willowfield",
	"South Willowfield",
	"Idlewood",
	"El Corona",
	"Little Mexico",
	"Commerce",
	"Pershing Square",
	"Verdant Bluffs",
	"LSI Airport",
	"Ocean Docks",
	"Downtown Los Santos",
	"Mulholland Intersection",
	"Temple",
	"Mulholland",
	"Market",
	"Vinewood",
	"Marina",
	"Verona Beach",
	"Richman",
	"Rodeo",
	"Santa Maria Beach"
}

local pointzoneids = {
	30,
	31,
	38,
	32,
	36,
	37,
	34,
	35,
	39
}

local turfzoneids = {
	0,
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
	15,
	16,
	17,
	18,
	19,
	20,
	21,
	22,
	23,
	24,
	25,
	26
}

-- Black Market Equipment Menu
local blackMarketItems = {
	{label = 'Full Health and Armor', index = 1},
	{label = 'Silenced Pistol', index = 2},
	{label = '9mm Pistol', index = 3},
	{label = 'Shotgun', index = 4},
	{label = 'MP5', index = 5},
	{label = 'UZI', index = 6},
	{label = 'Tec-9', index = 7},
	{label = 'Country Rifle', index = 8},
	{label = 'Deagle', index = 9},
	{label = 'AK-47', index = 10},
	{label = 'M4', index = 11},
	{label = 'Spas-12', index = 12},
	{label = 'Sniper Rifle', index = 13}
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
	{label = 'Smoke Grenade', index = 7},
	{label = 'Camera', index = 8},
	{label = 'Sniper', index = 9},
	{label = 'Vest', index = 10},
	{label = 'First Aid Kit', index = 11}
}

local function registerChatCommands()
	sampRegisterChatCommand(autobind.autovestsettingscmd, function()
		_menu = 1
		menu[0] = not menu[0]
	end)

	sampRegisterChatCommand(autobind.helpcmd, function()
		helpmenu[0] = not helpmenu[0]
	end)

	sampRegisterChatCommand(autobind.vestnearcmd, function()
		if _enabled then
			for PlayerID = 0, sampGetMaxPlayerId(false) do
				local result, playerped = sampGetCharHandleBySampPlayerId(PlayerID)
				if result and not sampIsPlayerPaused(PlayerID) and sampGetPlayerArmor(PlayerID) < 49 then
					local myX, myY, myZ = getCharCoordinates(ped)
					local playerX, playerY, playerZ = getCharCoordinates(playerped)
					if getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ) < 6 then
						local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
						local pAnimId2 = sampGetPlayerAnimationId(playerid)
						local aim, _ = getCharPlayerIsTargeting(h)
						if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162 and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167 and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
							sendGuard(PlayerID)
						end
					end
				end
			end
		end
	end)
	sampRegisterChatCommand(autobind.sexnearcmd, function()
		if _enabled then
			local result, id = getClosestPlayerId(5, 2)
			if result and isCharInAnyCar(ped) then
				sampSendChat(string.format("/sex %d 1", id))
			end
		end
	end)
	sampRegisterChatCommand(autobind.repairnearcmd, function()
		if _enabled then
			local result, id = getClosestPlayerId(5, 2)
			if result then
				sampSendChat(string.format("/repair %d 1", id))
			end
		end
	end)

	sampRegisterChatCommand(autobind.hfindcmd, function(params) -- Scumbag Locator
		if _enabled then
			lua_thread.create(function()
				if string.len(params) > 0 then
					local result, playerid, name = getTarget(params)
					if result then
						if not autofind then
							target = playerid
							autofind = true
							sampAddChatMessage("FINDING: {00a2ff}"..name.."{ffffff}. /hfind again to toggle.", -1)
							while autofind and not cooldown_bool do
								wait(10)
								if sampIsPlayerConnected(target) then
									cooldown_bool = true
									sampSendChat("/find "..target)
									wait(19000)
									cooldown_bool = false
								else
									autofind = false
									sampAddChatMessage("The player you were finding has disconnected, you are no longer finding anyone.", -1)
								end
							end
						elseif autofind then
							target = playerid
							sampAddChatMessage("NOW FINDING: {00a2ff}"..name.."{ffffff}.", -1)
						end
					else
						sampAddChatMessage("Invalid player specified.", 11645361)
					end
				elseif autofind and string.len(params) == 0 then
					autofind = false
					sampAddChatMessage("You are no longer finding anyone.", -1)
				else
					sampAddChatMessage('USAGE: /hfind [playerid/partofname]', -1)
				end
			end)
		end
	end)

	sampRegisterChatCommand(autobind.tcapcmd, function()
		if _enabled then
			captog = not captog
		end
	end)

	sampRegisterChatCommand(autobind.sprintbindcmd, function()
		if _enabled then
			autobind.Keybinds.SprintBind.Toggle = not autobind.Keybinds.SprintBind.Toggle
			sampAddChatMessage('[Autobind]{ffff00} Sprintbind: '..(autobind.Keybinds.SprintBind.Toggle and '{008000}on' or '{FF0000}off'), -1)
		end
	end)

	sampRegisterChatCommand(autobind.bikebindcmd, function()
		if _enabled then
			autobind.Keybinds.BikeBind.Toggle = not autobind.Keybinds.BikeBind.Toggle
			sampAddChatMessage('[Autobind]{ffff00} Bikebind: '..(autobind.Keybinds.BikeBind.Toggle and '{008000}on' or '{FF0000}off'), -1)
		end
	end)

	sampRegisterChatCommand(autobind.autovestcmd, function()
		if _enabled then
			_enabled = not _enabled
			sampAddChatMessage(string.format("[Autobind]{ffff00} Automatic vest %s.", _enabled and 'enabled' or 'disabled'), 1999280)
		end
	end)

	sampRegisterChatCommand(autobind.autoacceptercmd, function()
		if _enabled then
			if autobind.vestmode == 0 then
				autoaccepter = not autoaccepter
				sampAddChatMessage(string.format("[Autobind]{ffff00} Autoaccepter is now %s.", autoaccepter and 'enabled' or 'disabled'), 1999280)
			else
				sampAddChatMessage("[Autobind]{ffff00} Autoaccepter is for families only.", 1999280)
			end
		end
	end)

	sampRegisterChatCommand(autobind.ddmodecmd, function()
		if _enabled then
			autobind.ddmode = not autobind.ddmode
			sampAddChatMessage(string.format("[Autobind]{ffff00} ddmode is now %s.", autobind.ddmode and 'enabled' or 'disabled'), 1999280)

			autobind.timer = autobind.ddmode and 7 or 12
		end
	end)

	sampRegisterChatCommand(autobind.factionbothcmd, function()
		if _enabled then
			autobind.factionboth  = not autobind.factionboth
			sampAddChatMessage(string.format("[Autobind]{ffff00} factionbothcmd is now %s.", autobind.factionboth and 'enabled' or 'disabled'), 1999280)
		end
	end)

	sampRegisterChatCommand(autobind.vestmodecmd, function(params)
		if _enabled then
			if string.len(params) > 0 then
				if params == 'families' then
					autobind.vestmode = 0
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Families.", 1999280)
				elseif params == 'factions' then
					autobind.vestmode = 1
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Factions.", 1999280)
				elseif params == 'everyone' then
					autobind.vestmode = 2
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Everyone.", 1999280)
				elseif params == 'names' then
					autobind.vestmode = 3
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Names.", 1999280)
				else
					sampAddChatMessage("[Autobind]{ffff00} vestmode is currently set to "..vestmodename(autobind.vestmode)..".", 1999280)
					sampAddChatMessage('USAGE: /'..autobind.vestmodecmd..' [families/factions/everyone/names]', -1)
				end
			else
				sampAddChatMessage("[Autobind]{ffff00} vestmode is currently set to "..vestmodename(autobind.vestmode)..".", 1999280)
				sampAddChatMessage('USAGE: /'..autobind.vestmodecmd..' [families/factions/everyone/names]', -1)
			end
		end
	end)

	sampRegisterChatCommand(autobind.pointmodecmd, function(params)
		if _enabled then
			sampAddChatMessage("[Autobind]{ffff00} pointmode enabled.", 1999280)
			autobind.point_turf_mode = true
		end
	end)

	sampRegisterChatCommand(autobind.turfmodecmd, function(params)
		if _enabled then
			sampAddChatMessage("[Autobind]{ffff00} turfmode enabled.", 1999280)
			autobind.point_turf_mode = false
		end
	end)
end

function main()
	for _, dir in ipairs({path, skinspath}) do
		createDirectory(dir)
	end
	autobind = handleConfigFile(cfgFile, autobind_defaultSettings, autobind)

	while not isSampAvailable() do wait(100) end

	if autobind.autoupdate then
		--update_script(false)
	end

	skins_script()

	local res_aduty, aduty = getSampfuncsGlobalVar("aduty")
	if res_aduty then
		if aduty == 0 then
			setSampfuncsGlobalVar('aduty', 0)
		end
	else
		setSampfuncsGlobalVar('aduty', 0)
	end

	local res_hideme, hideme = getSampfuncsGlobalVar("HideMe_check")
	if res_hideme then
		if hideme == 0 then
			setSampfuncsGlobalVar('HideMe_check', 0)
		end
	else
		setSampfuncsGlobalVar('HideMe_check', 0)
	end

	mp3 = loadAudioStream("moonloader\\resource\\autobind\\sound.mp3")

	autobind.timer = autobind.ddmode and 7 or 12

	registerChatCommands()

	if not autobind.enablebydefault then
		_enabled = false
	end

	loadskinidsurl()

	--[[lua_thread.create(function()
		while true do wait(15)
			mpos = imgui.GetMousePos()
		end
	end)]]

	lua_thread.create(function()
		while true do wait(0)
			listenToKeybinds()
		end
	end)

	lua_thread.create(function()
		while true do wait(0)
			if _enabled and captog then
				sampAddChatMessage("{FFFF00}Starting capture spam... (type /tcap to toggle)",-1)
				while captog do
					sampSendChat("/capturf")
					wait(1500)
				end
				sampAddChatMessage("{FFFF00}Capture spam ended.",-1)
			end
		end
	end)

	lua_thread.create(function()
		while true do wait(0)
			if _enabled and autobind.Keybinds.SprintBind.Toggle and getPadState(h, keys.player.SPRINT) == 255 and (isCharOnFoot(ped) or isCharInWater(ped)) then
				setGameKeyUpDown(keys.player.SPRINT, 255, autobind.SprintBind.delay)
			end
		end
	end)

	while true do wait(0)
		if _enabled then
			if getCharArmour(ped) > 49 and not autobind.showprevest then
				sampname2 = 'Nobody'
				playerid2 = -1

				if autobind.notification_hide[2] then
					hide[2] = false
				end
			end
		end

		local _, aduty = getSampfuncsGlobalVar("aduty")
		local _, HideMe = getSampfuncsGlobalVar("HideMe_check")
		if _enabled and autobind.timer <= localClock() - _last_vest and not specstate and HideMe == 0 and aduty == 0 then
			if _you_are_not_bodyguard then
				autobind.timer = autobind.ddmode and 7 or 12
				for PlayerID = 0, sampGetMaxPlayerId(false) do
					local result, playerped = sampGetCharHandleBySampPlayerId(PlayerID)
					if result and not sampIsPlayerPaused(PlayerID) and sampGetPlayerArmor(PlayerID) < 49 then
						local myX, myY, myZ = getCharCoordinates(ped)
						local playerX, playerY, playerZ = getCharCoordinates(playerped)
						if getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ) < 6 then
							local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
							local pAnimId2 = sampGetPlayerAnimationId(playerid)
							local aim, _ = getCharPlayerIsTargeting(h)
							if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162 and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167 and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
								if autobind.vestmode == 0 then
									if autobind.customskins then
										if has_number(autobind.skins, getCharModel(playerped)) then
											sendGuard(PlayerID)
											break
										end
									else
										if has_number(skins, getCharModel(playerped)) then
											sendGuard(PlayerID)
											break
										end
									end
								end
								if autobind.vestmode == 1 then
									local color = sampGetPlayerColor(PlayerID)
									local r, g, b = hex2rgb(color)
									color = join_argb_int(255, r, g, b)
									if (autobind.factionboth and has_number(factions, getCharModel(playerped)) and has_number(factions_color, color)) or (not autobind.factionboth and has_number(factions, getCharModel(playerped)) or has_number(factions_color, color)) then
										sendGuard(PlayerID)
										break
									end
								end
								if autobind.vestmode == 2 then
									sendGuard(PlayerID)
									break
								end
								if autobind.vestmode == 3 then
									for k, v in pairs(autobind.names) do
										if v == sampGetPlayerNickname(PlayerID) then
											sendGuard(PlayerID)
											break
										end
									end
								end
								break
							end
						end
					end
				end
			end
			if autoaccepter and autoacceptertoggle then
				local _, playerped = storeClosestEntities(ped)
				local result, PlayerID = sampGetPlayerIdByCharHandle(playerped)
				if result and playerped ~= ped then
					if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
						autoaccepternickname = sampGetPlayerNickname(PlayerID)

						local playerx, playery, playerz = getCharCoordinates(ped)
						local pedx, pedy, pedz = getCharCoordinates(playerped)

						if getDistanceBetweenCoords3d(playerx, playery, playerz, pedx, pedy, pedz) < 4 then
							if autoaccepternickname == autoaccepternick then
								sampSendChat("/accept bodyguard")

								autoacceptertoggle = false
							end
						end
					end
				end
			end
		end

		if _enabled and autobind.point_capper_timer <= localClock() - _last_point_capper_refresh then
			if flashing[1] and not timeset[1] and not disablepointspam then
				sampSendChat("/pointinfo")
				_last_point_capper_refresh = localClock()
				lua_thread.create(function()
					pointspam = true
					wait(3000)
					pointspam = false
				end)
			end
		end

		if _enabled and autobind.turf_capper_timer <= localClock() - _last_turf_capper_refresh then
			if flashing[2] and not timeset[2] and not disableturfspam then
				sampSendChat("/turfinfo")
				_last_turf_capper_refresh = localClock()
				lua_thread.create(function()
					turfspam = true
					wait(3000)
					turfspam = false
				end)
			end
		end
	end
end

local function acceptBodyguard()
    sampSendChat("/accept bodyguard")
end

local function offerGuard()
    for PlayerID = 0, sampGetMaxPlayerId(false) do
        local result, playerped = sampGetCharHandleBySampPlayerId(PlayerID)
        if result and not sampIsPlayerPaused(PlayerID) and sampGetPlayerArmor(PlayerID) < 49 then
            local myX, myY, myZ = getCharCoordinates(ped)
            local playerX, playerY, playerZ = getCharCoordinates(playerped)
            if getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ) < 6 then
                local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
                local pAnimId2 = sampGetPlayerAnimationId(playerid)
                local aim, _ = getCharPlayerIsTargeting(h)
                if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162 and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167 and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
                    sendGuard(PlayerID)
                    return
                end
            end
        end
    end
end

local function blackMarket()
    if not bmbool then
        bmbool = true
        sendBMCmd()
    end
end

local function factionLocker()
    if not lockerbool and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
        lockerbool = true
        sendLockerCmd()
    end
end

local function bikeBind()
    if not isPauseMenuActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsScoreboardOpen() and autobind.Keybinds.BikeBind.Toggle then
        if isCharOnAnyBike(ped) then
            local veh = storeCarCharIsInNoSave(ped)
            if not isCarInAirProper(veh) then
                if bike[getCarModel(veh)] then
                    setGameKeyUpDown(keys.vehicle.ACCELERATE, 255, 0)
                elseif moto[getCarModel(veh)] then
                    setGameKeyUpDown(keys.vehicle.STEERUP_STEERDOWN, -128, 0)
                end
            end
        end
    end
end

local function sprintBind()
    autobind.Keybinds.SprintBind.Toggle = not autobind.Keybinds.SprintBind.Toggle
    sampAddChatMessage('[Autobind]{ffff00} Sprintbind: '..(autobind.Keybinds.SprintBind.Toggle and '{008000}on' or '{FF0000}off'), -1)
end

local function frisk()
    local _, playerped = storeClosestEntities(ped)
    local result, id = sampGetPlayerIdByCharHandle(playerped)
    local result2, target = getCharPlayerIsTargeting(h)
    if result then
        if (result2 and autobind.Frisk[1]) or not autobind.Frisk[1] then
            if (target == playerped and autobind.Frisk[1]) or not autobind.Frisk[1] then
                if (isPlayerAiming(true, true) and autobind.Frisk[2]) or not autobind.Frisk[2] then
                    sampSendChat(string.format("/frisk %d", id))
                end
            end
        end
    end
end

local function takePills()
    sampSendChat("/takepills")
end

local keyFunctions = {
    Accept = acceptBodyguard,
    Offer = offerGuard,
    BlackMarket = blackMarket,
    FactionLocker = factionLocker,
    BikeBind = bikeBind,
    SprintBind = sprintBind,
    Frisk = frisk,
    TakePills = takePills
}

function listenToKeybinds()
    if not _enabled then return end

    for key, value in pairs(autobind.Keybinds) do
        local keybind = value.Dual and split(value.Keybind, ",") or {value.Keybind}
        local keyTypes = value.Dual and {'KeyDown', 'KeyPressed'} or {'KeyPressed'}

        if keycheck({k = keybind, t = keyTypes}) and (value.Toggle or key == "BikeBind" or key == "SprintBind") then
            local success, error = pcall(keyFunctions[key])
            if not success then
                print(string.format("Error in %s function: %s", key, error))
            else
                print(string.format("%s function executed successfully", key))
            end
            if key ~= "BikeBind" then
                wait(1000)
            end
        end
    end
end

function sendGuard(id)
	if autobind.ddmode then
		sampSendChat('/guardnear')
	else
		sampSendChat(string.format("/guard %d 200", id))
	end

	if autobind.notification_hide[1] then
		hide[1] = true
	end

	sampname = sampGetPlayerNickname(id)
	playerid = id
	if autobind.sound then
		if mp3 ~= nil then
			setAudioStreamVolume(mp3, 10)
			setAudioStreamState(mp3, 1)
		end
	end
	_last_vest = localClock()
end

function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		if autobind.autosave then
			saveConfigWithErrorHandling(cfgFile, autobind)
		end
	end
end

function onWindowMessage(msg, wparam, lparam)
	if wparam == VK_ESCAPE and (menu[0] or skinmenu[0] or bmmenu[0] or factionlockermenu[0] or helpmenu[0]) then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            menu[0] = false
			skinmenu[0] = false
			bmmenu[0] = false
			factionlockermenu[0] = false
			helpmenu[0] = false
        end
    end
end

function sampev.onGangZoneFlash(zoneId, color)
	lua_thread.create(function()
		wait(0)
		for k, v in pairs(pointzoneids) do
			if v == zoneId then
				flashing[1] = true
			end
		end
		for k, v in pairs(turfzoneids) do
			if v == zoneId then
				flashing[2] = true
			end
		end
	end)
end
function sampev.onGangZoneStopFlash(zoneId)
	lua_thread.create(function()
		wait(0)
		for k, v in pairs(pointzoneids) do
			if v == zoneId then
				flashing[1] = false
			end
		end
		for k, v in pairs(turfzoneids) do
			if v == zoneId then
				flashing[2] = false
			end
		end
	end)
end

function sampev.onSetSpawnInfo(team, skin, _unused, position, rotation, weapons, ammo)
	lua_thread.create(function()
		wait(3000)
		if not once then
			if flashing[1] and not timeset[1] and not disablepointspam then
				sampSendChat("/pointinfo")
				_last_point_capper_refresh = localClock()
				lua_thread.create(function()
					pointspam = true
					wait(3000)
					pointspam = false
				end)
			end
			if flashing[2] and not timeset[2] and not disableturfspam then
				sampSendChat("/turfinfo")
				_last_turf_capper_refresh = localClock()
				lua_thread.create(function()
					turfspam = true
					wait(3000)
					turfspam = false
				end)
			end
			once = true
		end
	end)
end

function sampev.onServerMessage(color, text)
	if text:match("*** GENERAL *** /cancel /accept /eject /usepot /usecrack /contract /service /checkweed /findcartuning /settings /info /chud") then
		sampAddChatMessage(text, -1)
		sampAddChatMessage("*** AUTOBIND *** /autobind /vestnear /sexnear /repairnear /hfind /tcap /sprintbind /bikebind", -1)
		sampAddChatMessage("*** AUTOVEST *** /av /ddmode /vestmode /factionboth /autovest /pointmode, /turfmode", -1)
		return false
	end

	if text:find("The time is now") and color == -86 then
		if autobind.capturf then
			sampSendChat("/capturf")
			if autobind.disableaftercapping then
				autobind.capturf = false
			end
		end
		if autobind.capture then
			sampSendChat("/capture")
			if autobind.disableaftercapping then
				autobind.capture = false
			end
		end
	end

	if text:find("has Offered you to have Sex with them, for") then
		if autobind.autoacceptsex then
			sampSendChat("/accept sex")
		end
	end

	if text:find("wants to repair your car for $1") then
		if autobind.autoacceptrepair then
			sampSendChat("/accept repair")
		end
	end

	if text:match("You are not a Sapphire or Diamond Donator!") or
	   text:match("You are not at the black market!") or
	   text:match("You can't do this right now.") or
	   text:match("You have been muted automatically for spamming. Please wait 10 seconds and try again.") or
	   text:match("You are muted from submitting commands right now.") and bmbool == 1 then
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
    end

	if text:match("Point Info:") then
		if pointspam then
			return false
		end
	end

	if text:match("No family has capped the point or the point is not ready to be capped.") then
		disablepointspam = true
		if pointspam then
			return false
		end
	end

	for k, v in pairs(pointnamelist) do
		if text:find("*") and text:find(v) and text:find('Capper:') and text:find('Family:') and text:find('Time left:') and color == -86 then
			local location, nickname, pointname, number = ""
			if string.contains(text, "Less than", false) then
				location, nickname, pointname, number = text:match("* (.+) | Capper: (.+) | Family: (.+) | Time left: Less than (.+) minute")
			else
				location, nickname, pointname, number = text:match("* (.+) | Capper: (.+) | Family: (.+) | Time left: (.+) minutes")
			end

			point_capper = pointname
			pointtime = number
			point_capper_capturedby = nickname
			point_location = location

			if autobind.notification_capper_hide then
				capper_hide = true
			end
			if pointspam then
				return false
			end
		end
	end


	if text:find("Turf Info:") then
		if turfspam then
			return false
		end
	end

	if text:find("Nobody is attempting to capture any turfs or no turfs are available for capture yet.") then
		disableturfspam = true
		if turfspam then
			return false
		end
	end

	for k, v in pairs(turfnamelist) do
		if text:find("*") and text:find(v) and text:find('Capper:') and (text:find('Family:') or text:find('By:')) and text:find('Time left:') and color == -86 then
			local location, nickname, turfname, number = ""
			if string.contains(text, 'Family:', false) then
				if string.contains(text, "Less than", false) then
					location, nickname, turfname, number = text:match("* (.+) | Capper: (.+) | Family: (.+) | Time left: Less than (.+) minute")
				else
					location, nickname, turfname, number = text:match("* (.+) | Capper: (.+) | Family: (.+) | Time left: (.+) minutes")
				end
			end
			if string.contains(text, 'By:', false) then
				if string.contains(text, "Less than", false) then
					location, nickname, turfname, number = text:match("* (.+) | Capper: (.+) | By: (.+) | Time left: Less than (.+) minute")
				else
					location, nickname, turfname, number = text:match("* (.+) | Capper: (.+) | By: (.+) | Time left: (.+) minutes")
				end
			end

			turf_capper = turfname
			turftime = number
			turf_capper_capturedby = nickname
			turf_location = location

			if autobind.notification_capper_hide then
				capper_hide = true
			end
			if turfspam then
				return false
			end
		end
		break
	end

	if text:find("is attempting to take over of the") and text:find('for') and text:find('they\'ll own it in 10 minutes.') and color == -65366 then
		local nickname, location, pointname = text:match("(.+) is attempting to take over of the (.+) for (.+), they'll own it in 10 minutes.")
		nickname = nickname:gsub("%s+", "_")

		point_capper = pointname
		point_capper_capturedby = nickname
		point_location = location

		_last_point_capper = localClock()
		timeset[1] = true
		disablepointspam = false
		if autobind.notification_capper_hide then
			capper_hide = true
		end
	end

	if text:find("is attempting to take control of") and text:find('for') and text:find('(15 minutes remaining)') and color == -65366 then
		local nickname, location, turfname = text:match("(.+) is attempting to take control of (.+) for (.+) %(15 minutes remaining%).")
		nickname = nickname:gsub("%s+", "_")

		turf_capper = turfname
		turf_capper_capturedby = nickname
		turf_location = location

		_last_turf_capper = localClock()
		timeset[2] = true
		disableturfspam = false
		if autobind.notification_capper_hide then
			capper_hide = true
		end
	end

	for k, v in pairs(pointnamelist) do
		if text:find("has taken control of") and text:find(v) and color == -65366 then
			point_capper = 'Nobody'
			point_capper_capturedby = 'Nobody'
			point_location = "No captured point"
			pointtime = 0

			timeset[1] = false
			if autobind.notification_capper_hide then
				capper_hide = false
			end

			if autoaccepter and autobind.vestmode == 0 then
				autoaccepter = false

				sampAddChatMessage("[Autobind]{ffff00} Automatic vest disabled because point had ended.", 1999280)
			end
		end
	end

	for k, v in pairs(turfnamelist) do
		if text:find("has taken control of") and text:find(v) and color == -65366 then
			turf_capper = 'Nobody'
			turf_capper_capturedby = 'Nobody'
			turf_location = "No captured turf"
			turftime = 0

			timeset[2] = false
			if autobind.notification_capper_hide then
				capper_hide = false
			end
		end
	end


	if text:find("That player isn't near you.") and color == -1347440726 then
		if autobind.ddmode then
			_last_vest = localClock() - 6.8
		else
			_last_vest = localClock() - 11.8
		end

		if autobind.messages then
			return false
		end
	end

	if text:find("You can't /guard while aiming.") and color == -1347440726 then
		if autobind.ddmode then
			_last_vest = localClock() - 6.8
		else
			_last_vest = localClock() - 11.8
		end

		if autobind.messages then
			return false
		end
	end

	if text:find("You must wait") and text:find("seconds before selling another vest.") and autobind.timercorrection then
		cooldown = string.match (text, "%d+")
		autobind.timer = cooldown + 0.5

		if autobind.messages then
			return false
		end
	end

	if text:find("* You offered protection to ") and text:find(" for $200.") and color == 869072810 then
		if autobind.messages then
			return false
		end
	end

	if text:find("You accepted the protection for $200 from") and color == 869072810 then
		sampname2 = 'Nobody'
		playerid2 = -1

		if autobind.notification_hide[2] then
			hide[2] = false
		end

		if autobind.messages then
			return false
		end
	end

	if text:find("You are not a bodyguard.") and color ==  -1347440726 then
		sampname = 'Nobody'
		playerid = -1

		_you_are_not_bodyguard = false

		if autobind.notification_hide[1] then
			hide[1] = false
		end
	end

	if text:find("accepted your protection, and the $200 was added to your money.") and color == 869072810 then
		sampname = 'Nobody'
		playerid = -1

		if autobind.notification_hide[1] then
			hide[1] = false
		end

		if autobind.messages then
			return false
		end
	end

	if text:match("* You are now a Bodyguard, type /help to see your new commands.") then
		_you_are_not_bodyguard = true
	end

	if text:find("* Bodyguard ") and text:find(" wants to protect you for $200, type /accept bodyguard to accept.") and color == 869072810 then
		lua_thread.create(function()
			wait(0)
			if autobind.notification_hide[2] then
				hide[2] = true
			end

			if color >= 40 and text ~= 746 then
				autoaccepternick = text:match("%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.")
				autoaccepternick = autoaccepternick:gsub("%s+", "_")

				sampname2 = autoaccepternick
				playerid2 = sampGetPlayerIdByNickname(autoaccepternick)
				autoacceptertoggle = true
			end

			if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 and autoaccepter and not specstate then
				sampSendChat("/accept bodyguard")

				autoacceptertoggle = false
			end
		end)

		if autobind.messages then
			return false
		end
	end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	if bmbool then
		local bmItems = {
			{weapon = 24, menuIndex = 6},
			{weapon = 24, menuIndex = 7},
			{weapon = 27, menuIndex = 8},
			{weapon = 29, menuIndex = 9},
			{weapon = 29, menuIndex = 10},
			{weapon = 29, menuIndex = 11},
			{weapon = 34, menuIndex = 12},
			{weapon = 24, menuIndex = 13},
			{weapon = 31, menuIndex = 14},
			{weapon = 31, menuIndex = 15},
			{weapon = 27, menuIndex = 16},
			{weapon = 34, menuIndex = 17}
		}
		
		if title:find('Black Market') then
			if bmstate == 0 then
				if (getCharArmour(ped) == 100 and getCharHealth(ped) - 5000000 == 100) or not autobind.BlackMarket[1] then
					bmstate = 1
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 2, nil)
				bmstate = 1
				sendBMCmd()
				return false
			end
		
			for i, item in ipairs(bmItems) do
				if bmstate == i then
					if hasCharGotWeapon(ped, item.weapon) or not autobind.BlackMarket[i + 1] then
						bmstate = i + 1
						sampev.onShowDialog(id, style, title, button1, button2, text)
						return false
					end
					sampSendDialogResponse(id, 1, item.menuIndex, nil)
					bmstate = i + 1
					sendBMCmd()
					return false
				end
			end
		
			if bmstate == #bmItems + 1 then
				bmbool = false
				bmstate = 0
				bmcmd = 0
				sampev.onShowDialog(id, style, title, button1, button2, text)
				return false
			end
		end
	end

	if lockerbool then
		local lockerItems = {
			{weapon = 24, menuIndex = 0, configIndex = 1},  -- Deagle
			{weapon = 25, menuIndex = 1, configIndex = 2},  -- Shotgun
			{weapon = 27, menuIndex = 2, configIndex = 3},  -- SPAS-12
			{weapon = 29, menuIndex = 3, configIndex = 4},  -- MP5
			{weapon = 31, menuIndex = 4, configIndex = 5},  -- M4
			{weapon = 30, menuIndex = 5, configIndex = 6},  -- AK-47
			{weapon = 17, menuIndex = 6, configIndex = 7},  -- Smoke Grenade
			{weapon = 43, menuIndex = 7, configIndex = 8},  -- Camera
			{weapon = 34, menuIndex = 8, configIndex = 9},  -- Sniper Rifle
			{armor = true, menuIndex = 9, configIndex = 10},  -- Armor
			{health = true, menuIndex = 10, configIndex = 11}  -- Health
		}
		
		if title:find('LSPD Menu') or title:find('FBI Menu') or title:find('ARES Menu') then
			sampSendDialogResponse(id, 1, 1, nil)
			return false
		end
		
		if title:find('LSPD Equipment') or title:find('FBI Weapons') or title:find('ARES Equipment') then
			for i, item in ipairs(lockerItems) do
				if lockerstate == i - 1 then
					local shouldSkip = false
					if item.weapon then
						shouldSkip = hasCharGotWeapon(PLAYER_PED, item.weapon) or not autobind.FactionLocker[item.configIndex]
					elseif item.armor then
						shouldSkip = getCharArmour(PLAYER_PED) == 100 or not autobind.FactionLocker[item.configIndex]
					elseif item.health then
						shouldSkip = getCharHealth(ped) - 5000000 == 100 or not autobind.FactionLocker[item.configIndex]
					end
		
					if shouldSkip then
						lockerstate = i
						sampev.onShowDialog(id, style, title, button1, button2, text)
						return false
					end
		
					sampSendDialogResponse(id, 1, item.menuIndex, nil)
					lockerstate = i
					sendLockerCmd()
					return false
				end
			end
		
			-- If we've reached this point, we've gone through all items
			lockerbool = false
			lockerstate = 0
			lockercmd = 0
			return false
		end
	end
end

function sampev.onTogglePlayerSpectating(state)
    specstate = state
end

imgui.OnInitialize(function()
	apply_custom_style() -- apply custom style

	local config = imgui.ImFontConfig()
	config.MergeMode = true
    config.PixelSnapH = true
    config.GlyphMinAdvanceX = 14
    local builder = imgui.ImFontGlyphRangesBuilder()
    local list = {
		"SHIELD_PLUS",
		"POWER_OFF",
		"FLOPPY_DISK",
		"REPEAT",
		"PERSON_BOOTH",
		"ERASER",
		"RETWEET",
		"GEAR",
		"CART_SHOPPING"
	}
	for _, b in ipairs(list) do
		builder:AddText(fa(b))
	end
	defaultGlyphRanges1 = imgui.ImVector_ImWchar()
	builder:BuildRanges(defaultGlyphRanges1)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85('regular'), 14, config, defaultGlyphRanges1[0].Data)

	imgui.GetIO().IniFilename = nil
end)

--[[imgui.OnFrame(function() return (autobind.notification[1] or hide[1] or menu[0]) and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.offeredpos[1], autobind.offeredpos[2]))
	imgui.Begin("offered", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		imgui.AnimProgressBar('##Timer', autobind.timer - (localClock() - _last_vest), autobind.timer, 50)
		if autobind.timer - (localClock() - _last_vest) > 0 then
			imgui.Text(string.format("Next vest in: %d\nYou offered a vest to:\n%s[%s]\nVestmode: %s", autobind.timer - (localClock() - _last_vest), sampname, playerid, vestmodename(autobind.vestmode)))
		else
			imgui.Text(string.format("Next vest in: 0\nYou offered a vest to:\n%s[%s]\nVestmode: %s", sampname, playerid, vestmodename(autobind.vestmode)))

			if autobind.notification[1] then
				sampname = 'Nobody'
				playerid = -1
			end

			if autobind.notification_hide[1] then
				sampname = 'Nobody'
				playerid = -1
				hide[1] = false
			end
		end
		if menu[0] then
			size[1] = imgui.GetWindowSize()
		end
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return (autobind.notification[2] or hide[2] or menu[0]) and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.offerpos[1], autobind.offerpos[2]))
	imgui.Begin("offer", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		imgui.Text(string.format("You got an offer from: \n%s[%s]\nAutoaccepter is %s", sampname2, playerid2, autoaccepter and 'enabled' or 'disabled'))
		if menu[0] then
			size[2] = imgui.GetWindowSize()
		end
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return (autobind.notification_capper or capper_hide or menu[0]) and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.capperpos[1], autobind.capperpos[2]))
	imgui.Begin("point/turf", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		local point_turf_timer = (autobind.point_turf_mode and point_capper_timer or turf_capper_timer) - (localClock() - (autobind.point_turf_mode and _last_point_capper or _last_turf_capper))
		local minutes, seconds = disp_time(point_turf_timer)
		if autobind.point_turf_mode then
			if timeset[1] then
				if point_turf_timer > 0 then
					imgui.Text(string.format("%s is attemping to capture the Point\nCaptured by %s\nLocation: %s\nMinutes: %d, Seconds: %d", point_capper, point_capper_capturedby, point_location, minutes, seconds))
				else
					imgui.Text(string.format("%s is attemping to capture the Point\nCaptured by %s\nLocation: %s\nMinutes: 0, Seconds: 0", point_capper, point_capper_capturedby, point_location))
				end
			else
				imgui.Text(string.format("%s is attemping to capture the Point\nCaptured by %s\nLocation: %s\nMinutes: %s", point_capper, point_capper_capturedby, point_location, pointtime))
			end
		else
			if timeset[2] then
				if point_turf_timer > 0 then
					imgui.Text(string.format("%s is attemping to capture the Turf\nCaptured by %s\nLocation: %s\nMinutes: %d, Seconds: %d", turf_capper, turf_capper_capturedby, turf_location, minutes, seconds))
				else
					imgui.Text(string.format("%s is attemping to capture the Turf\nCaptured by %s\nLocation: %s\nMinutes: 0, Seconds: 0", turf_capper, turf_capper_capturedby, turf_location))
				end
			else
				imgui.Text(string.format("%s is attemping to capture the Turf\nCaptured by %s\nLocation: %s\nMinutes: %s", turf_capper, turf_capper_capturedby, turf_location, turftime))
			end
		end
		if menu[0] then
			size[3] = imgui.GetWindowSize()
		end
	imgui.End()
end).HideCursor = true]]

imgui.OnFrame(function() return menu[0] end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1], autobind.menupos[2]))
	imgui.SetNextWindowSize(imgui.ImVec2(600, 428))
	imgui.Begin(fa.SHIELD_PLUS..script.this.name.." Settings - Version: " .. script_version_text, menu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.BeginChild("##1", imgui.ImVec2(85, 392), true)

			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			if imgui.CustomButton(
				fa.POWER_OFF,
				_enabled and imgui.ImVec4(0.15, 0.59, 0.18, 0.7) or imgui.ImVec4(1, 0.19, 0.19, 0.5),
				_enabled and imgui.ImVec4(0.15, 0.59, 0.18, 0.5) or imgui.ImVec4(1, 0.19, 0.19, 0.3),
				_enabled and imgui.ImVec4(0.15, 0.59, 0.18, 0.4) or imgui.ImVec4(1, 0.19, 0.19, 0.2),
				imgui.ImVec2(75, 75)) then
				_enabled = not _enabled
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Toggles Notifications')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 81))

			if imgui.CustomButton(
				fa.FLOPPY_DISK,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then
				saveConfigWithErrorHandling(cfgFile, autobind)
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Save the Script')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 157))

			if imgui.CustomButton(
				fa.REPEAT,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then
				autobind = handleConfigFile(cfgFile, autobind_defaultSettings, autobind)
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reload the config')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 233))

			if imgui.CustomButton(
				fa.ERASER,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(75, 75)) then
				ensureDefaults(autobind, autobind_defaultSettings, true)
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reset the Script to default settings')
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
				imgui.SetTooltip('Update the script')
			end

		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(92, 28))

		imgui.BeginChild("##2", imgui.ImVec2(500, 88), true)

			imgui.SetCursorPos(imgui.ImVec2(5,5))
			if imgui.CustomButton(fa("GEAR") .. '  Settings',
				_menu == 1 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(165, 75)) then
				_menu = 1
			end

			imgui.SetCursorPos(imgui.ImVec2(170, 5))

			if imgui.CustomButton(fa("PERSON_BOOTH") .. '  Skins',
				_menu == 2 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(165, 75)) then

				_menu = 2
			end

			imgui.SetCursorPos(imgui.ImVec2(335, 5))

			if imgui.CustomButton(fa("PERSON_BOOTH") .. '  Names',
				_menu == 3 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1),
				imgui.ImVec4(0.30, 0.08, 0.08, 1),
				imgui.ImVec2(165, 75)) then

				_menu = 3
			end
		imgui.EndChild()

		imgui.SetCursorPos(imgui.ImVec2(92, 112))

		imgui.BeginChild("##3", imgui.ImVec2(500, 276), true)
			if _menu == 1 then
				imgui.SetCursorPos(imgui.ImVec2(5, 10))

				imgui.BeginChild("##config", imgui.ImVec2(330, 120), false)

					imgui.Text('AutoBind:')
					if imgui.Checkbox('Cap Spam (Turfs)', new.bool(captog)) then
						captog = not captog
					end

					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)

					if imgui.Checkbox('Capturf (Turfs)', new.bool(autobind.capturf)) then
						autobind.capturf = not autobind.capturf
						if autobind.capturf then
							autobind.capture = false
						end
					end
					if imgui.Checkbox('Disable when it ends', new.bool(autobind.disableaftercapping)) then
						autobind.disableaftercapping = not autobind.disableaftercapping
					end

					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)


					if imgui.Checkbox('Capture (Points)', new.bool(autobind.capture)) then
						autobind.capture = not autobind.capture
						if autobind.capture then
							autobind.capturf = false
						end
					end

					if imgui.Checkbox('Auto Accept Repair', new.bool(autobind.autoacceptrepair)) then
						autobind.autoacceptrepair = not autobind.autoacceptrepair
					end

					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)

					if imgui.Checkbox('Auto Accept Sex', new.bool(autobind.autoacceptsex)) then
						autobind.autoacceptsex = not autobind.autoacceptsex
					end

					if imgui.Checkbox('Auto Accept Vest', new.bool(autoaccepter)) then
						autoaccepter = not autoaccepter
					end

					imgui.Text('AutoVest:')
					imgui.PushItemWidth(290)
					local text_skinsurl = new.char[256](autobind.skinsurl)
					if imgui.InputText('##skinsurl', text_skinsurl, sizeof(text_skinsurl), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.skinsurl = u8:decode(str(text_skinsurl))
					end
					imgui.PopItemWidth()

					if imgui.Checkbox("Diamond Donator", new.bool(autobind.ddmode)) then
						autobind.ddmode = not autobind.ddmode
						autobind.timer = autobind.ddmode and 7 or 12
					end

					if imgui.IsItemHovered() then
						imgui.SetTooltip('If you are Diamond Donator toggle this on.')
					end

					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Show Prevest",  new.bool(autobind.showprevest)) then
						autobind.showprevest = not autobind.showprevest
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('If vest is below 49 it will disable prevest show')
					end

					if imgui.Checkbox("Sound", new.bool(autobind.sound)) then
						autobind.sound = not autobind.sound
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Timer fix", new.bool(autobind.timercorrection)) then
						autobind.timercorrection = not autobind.timercorrection
					end
					if imgui.Checkbox("Enabled by default", new.bool(autobind.enablebydefault)) then
						autobind.enablebydefault = not autobind.enablebydefault
					end

					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Compare Both", new.bool(autobind.factionboth)) then
						autobind.factionboth = not autobind.factionboth
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Compare faction (ticked color and skin) or (unticked color or skin)')
					end

					if imgui.Checkbox("Always Offered",  new.bool(autobind.notification[2])) then
						autobind.notification[2] = not autobind.notification[2]
						if autobind.notification[2] then
							autobind.notification_hide[2] = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Always Display Offered')
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Hide Offered",  new.bool(autobind.notification_hide[2])) then
						autobind.notification_hide[2] = not autobind.notification_hide[2]
						if autobind.notification_hide[2] then
							autobind.notification[2] = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Always Hide Offered')
					end

					if imgui.Checkbox("Always Offer",  new.bool(autobind.notification[1])) then
						autobind.notification[1] = not autobind.notification[1]
						if autobind.notification[1] then
							autobind.notification_hide[1] = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Always Display Offer')
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)

					if imgui.Checkbox("Hide Offer",  new.bool(autobind.notification_hide[1])) then
						autobind.notification_hide[1] = not autobind.notification_hide[1]
						if autobind.notification_hide[1] then
							autobind.notification[1] = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Always Hide Offer')
					end

					if imgui.Checkbox("Always Point/Turf",  new.bool(autobind.notification_capper)) then
						autobind.notification_capper = not autobind.notification_capper
						if autobind.notification_capper then
							autobind.notification_capper_hide = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Always Display Turf/Point')
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Hide Point/Turf",  new.bool(autobind.notification_capper_hide)) then
						autobind.notification_capper_hide = not autobind.notification_capper_hide
						if autobind.notification_capper_hide then
							autobind.notification_capper = false
						end
					end
					if imgui.IsItemHovered() then
						imgui.SetTooltip('Always Hide Turf/Point')
					end
					if imgui.Checkbox("Message Spam", new.bool(autobind.messages)) then
						autobind.messages = not autobind.messages
					end

					imgui.Text('Frisk:')
					if imgui.Checkbox("Player Target", new.bool(autobind.Frisk[1])) then
						autobind.Frisk[1] = not autobind.Frisk[1]
					end
					imgui.SameLine()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
					if imgui.Checkbox("Player Aim", new.bool(autobind.Frisk[2])) then
						autobind.Frisk[2] = not autobind.Frisk[2]
					end
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(5, 135))

				imgui.BeginChild("##Separator", imgui.ImVec2(330, 0), false)
					imgui.Separator()
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(5, 145))

				imgui.BeginChild("##cmds", imgui.ImVec2(330, 70), false)
					imgui.Text("Settings Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_autovestsettingscmd = new.char[25](autobind.autovestsettingscmd)
					if imgui.InputText('##Autobindsettings command', text_autovestsettingscmd, sizeof(text_autovestsettingscmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.autovestsettingscmd = u8:decode(str(text_autovestsettingscmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Vest Near Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_vestnearcmd = new.char[25](autobind.vestnearcmd)
					if imgui.InputText('##vestnearcmd', text_vestnearcmd, sizeof(text_vestnearcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.vestnearcmd = u8:decode(str(text_vestnearcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Sex Near Command")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_sexnearcmd = new.char[25](autobind.sexnearcmd)
					if imgui.InputText('##sexnearcmd', text_sexnearcmd, sizeof(text_sexnearcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.sexnearcmd = u8:decode(str(text_sexnearcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Repair Near Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_repairnearcmd = new.char[25](autobind.repairnearcmd)
					if imgui.InputText('##repairnearcmd', text_repairnearcmd, sizeof(text_repairnearcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.repairnearcmd = u8:decode(str(text_repairnearcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("hFind Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_hfindcmd = new.char[25](autobind.hfindcmd)
					if imgui.InputText('##hfindcmd', text_hfindcmd, sizeof(text_hfindcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.hfindcmd = u8:decode(str(text_hfindcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Spam Cap Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_tcapcmd = new.char[25](autobind.tcapcmd)
					if imgui.InputText('##tcapcmd', text_tcapcmd, sizeof(text_tcapcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.tcapcmd = u8:decode(str(text_tcapcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Sprint Bind Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_sprintbindcmd = new.char[25](autobind.sprintbindcmd)
					if imgui.InputText('##sprintbindcmd', text_sprintbindcmd, sizeof(text_sprintbindcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.sprintbindcmd = u8:decode(str(text_sprintbindcmd))
					end
					imgui.PopItemWidth()
					imgui.Text("Bike Bind Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_bikebindcmd = new.char[25](autobind.bikebindcmd)
					if imgui.InputText('##bikebindcmd', text_bikebindcmd, sizeof(text_bikebindcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.bikebindcmd = u8:decode(str(text_bikebindcmd))
					end
					imgui.PopItemWidth()


					imgui.Text("Autovest Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_autovestcmd = new.char[25](autobind.autovestcmd)
					if imgui.InputText('##autovestcmd', text_autovestcmd, sizeof(text_autovestcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.autovestcmd = u8:decode(str(text_autovestcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Autoaccepter Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)

					local text_autoacceptercmd = new.char[25](autobind.autoacceptercmd)
					if imgui.InputText('##autoacceptercmd', text_autoacceptercmd, sizeof(text_autoacceptercmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.autoacceptercmd = u8:decode(str(text_autoacceptercmd))
					end
					imgui.PopItemWidth()

					imgui.Text("DD-Mode Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_ddmodecmd = new.char[25](autobind.ddmodecmd)
					if imgui.InputText('##ddmodecmd', text_ddmodecmd, sizeof(text_ddmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.ddmodecmd = u8:decode(str(text_ddmodecmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Vest Mode Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_vestmodecmd = new.char[25](autobind.vestmodecmd)
					if imgui.InputText('##vestmodecmd', text_vestmodecmd, sizeof(text_vestmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.vestmodecmd = u8:decode(str(text_vestmodecmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Faction Both Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_factionbothcmd = new.char[25](autobind.factionbothcmd)
					if imgui.InputText('##factionbothcmd', text_factionbothcmd, sizeof(text_factionbothcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.factionbothcmd = u8:decode(str(text_factionbothcmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Point Mode Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_pointmodecmd = new.char[25](autobind.pointmodecmd)
					if imgui.InputText('##pointmodecmd', text_pointmodecmd, sizeof(text_pointmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.pointmodecmd = u8:decode(str(text_pointmodecmd))
					end
					imgui.PopItemWidth()

					imgui.Text("Turf Mode Command:")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_turfmodecmd = new.char[25](autobind.turfmodecmd)
					if imgui.InputText('##turfmodecmd', text_turfmodecmd, sizeof(text_turfmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.turfmodecmd = u8:decode(str(text_turfmodecmd))
					end
					imgui.PopItemWidth()
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(5, 220))

				imgui.BeginChild("##saveandreset", imgui.ImVec2(330, 45), false)
					imgui.Text("Changing this will require the script to restart")
					imgui.Spacing()
					imgui.SetCursorPosX(imgui.GetWindowWidth() / 5.7)
					if imgui.Button(fa.ARROWS_REPEAT .. " Save and restart the script") then
						saveConfigWithErrorHandling(cfgFile, autobind)
						thisScript():reload()
					end
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(340, 5))

				imgui.BeginChild("##keybinds", imgui.ImVec2(155, 263), true)
					if imgui.Button(fa.CART_SHOPPING .. " BM Settings") then
						bmmenu[0] = not bmmenu[0]
					end

					if imgui.Button(fa.CART_SHOPPING .. " Faction Locker") then
						factionlockermenu[0] = not factionlockermenu[0]
					end

					dualswitch("Accept Bodyguard:", "Accept")
					if not inuse_key then
						keychange('Accept')
					end

					dualswitch("Offer Bodyguard:", "Offer")
					if not inuse_key then
						keychange('Offer')
					end

					dualswitch("Black Market:", "BlackMarket")
					if not inuse_key then
						keychange('BlackMarket')
					end

					dualswitch("Faction Locker:", "FactionLocker")
					if not inuse_key then
						keychange('FactionLocker')
					end

					dualswitch("BikeBind:", "BikeBind")
					if not inuse_key then
						keychange('BikeBind')
					end

					dualswitch("Sprintbind:", "SprintBind", true)
					imgui.PushItemWidth(40)
					delay = new.int(autobind.SprintBind.delay)
					if imgui.DragInt('Speed', delay, 0.5, 0, 200) then
						autobind.SprintBind.delay = delay[0]
					end
					imgui.PopItemWidth()
					if not inuse_key then
						keychange('SprintBind')
					end

					dualswitch("Frisk:", "Frisk")
					if not inuse_key then
						keychange('Frisk')
					end

					dualswitch("TakePills:", "TakePills")
					if not inuse_key then
						keychange('TakePills')
					end
				imgui.EndChild()
			end

			if _menu == 2 then
				if imgui.Checkbox("Custom Skins", new.bool(autobind.customskins)) then
					autobind.customskins = not autobind.customskins
					if not autobind.customskins and not updateskin then
						loadskinidsurl()
					end
				end
				imgui.SameLine()
				if imgui.Button(u8"Add Skin") then
					autobind.skins[#autobind.skins + 1] = 0
				end
				imgui.SameLine()
				if imgui.Button("Update Skins") and not updateskin then
					lua_thread.create(function()
						updateskin = true
						loadskinidsurl()
						wait(5000)
						updateskin = false
					end)
				end
				for k, v in ipairs(autobind.skins) do
					local skinid = new.int[1](v)
					if imgui.InputInt('##skinid'..k, skinid, 1, 1) then
						if skinid[0] <= 311 and skinid[0] >= 0 then
							autobind.skins[k] = skinid[0]
						end
					end
					imgui.SameLine()
					if imgui.Button(u8"Pick Skin##"..k) then
						skinmenu[0] = not skinmenu[0]
						selected = k
					end
					imgui.SameLine()
					if imgui.Button(u8"x##"..k) then
						table.remove(autobind.skins, k)
					end
				end
			end

			if _menu == 3 then
				if imgui.Button(u8"Add Name") then
					autobind.names[#autobind.names + 1] = "Firstname_Lastname"
				end
				imgui.SameLine()
				if imgui.Checkbox("GetTarget",  new.bool(autobind.gettarget)) then
					autobind.gettarget = not autobind.gettarget
				end

				for key, value in pairs(autobind.names) do
					nick = new.char[128](value)
					if imgui.InputText('Nickname##'..key, nick, sizeof(nick), imgui.InputTextFlags.EnterReturnsTrue) then
						if autobind.gettarget then
							local res, playerid, playername = getTarget(u8:decode(str(nick)))
							if res then
								autobind.names[key] = playername
							end
						else
							autobind.names[key] = u8:decode(str(nick))
						end
					end
					imgui.SameLine()
					if imgui.Button(u8"x##"..key) then
						table.remove(autobind.names, key)
					end
				end
			end
		imgui.EndChild()
		imgui.SetCursorPos(imgui.ImVec2(92, 384))

		imgui.BeginChild("##5", imgui.ImVec2(500, 36), true)

			if imgui.Checkbox('Autosave', new.bool(autobind.autosave)) then
				autobind.autosave = not autobind.autosave
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Autosave')
			end
			imgui.SameLine()
			if imgui.Checkbox('Auto-Update', new.bool(autobind.autoupdate)) then
				autobind.autoupdate = not autobind.autoupdate
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Auto-Update')
			end

			imgui.SameLine()

			if imgui.Button(vestmodename(autobind.vestmode)) then
				if autobind.vestmode == 3 then
					autobind.vestmode = 0
				else
					autobind.vestmode = autobind.vestmode + 1
				end
			end
			imgui.SameLine()

			if imgui.Button(autobind.point_turf_mode and 'Point' or 'Turf') then
				autobind.point_turf_mode = not autobind.point_turf_mode
			end
		imgui.EndChild()
	imgui.End()
end)

local frameDrawer = imgui.OnFrame(function() return skinmenu[0] end,
function()
	for i = 0, 311 do
		if skinTexture[i] == nil then
			skinTexture[i] = imgui.CreateTextureFromFile("moonloader/resource/skins/Skin_"..i..".png")
		end
	end
end,
function(self)
	if not menu[0] then
		skinmenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] + (600 / 13), autobind.menupos[2]))
	imgui.SetNextWindowSize(imgui.ImVec2(505, 390), imgui.Cond.FirstUseEver)
	imgui.Begin(u8("Skin Menu"), skinmenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar)
		imgui.SetWindowFocus()
		if page == 15 then max = 299 else max = 41+(21*(page-2)) end
		for i = 21+(21*(page-2)), max do
			if i <= 27+(21*(page-2)) and i ~= 21+(21*(page-2)) then
				imgui.SameLine()
			elseif i <= 34+(21*(page-2)) and i > 28+(21*(page-2)) then
				imgui.SameLine()
			elseif i <= 41+(21*(page-2)) and i > 35+(21*(page-2)) then
				imgui.SameLine()
			end
			if imgui.ImageButton(skinTexture[i], imgui.ImVec2(55, 100)) then
				autobind.skins[selected] = i
				skinmenu[0] = false
			end
			if imgui.IsItemHovered() then imgui.SetTooltip("Skin "..i.."") end
		end

		imgui.SetCursorPos(imgui.ImVec2(555, 360))

		imgui.Indent(210)

		if imgui.Button(u8"Previous", new.bool) and page > 0 then
			if page == 1 then
				page = 15
			else
				page = page - 1
			end
		end
		imgui.SameLine()
		if imgui.Button(u8"Next", new.bool) and page < 16 then
			if page == 15 then
				page = 1
			else
				page = page + 1
			end
		end
		imgui.SameLine()
		imgui.Text("Page "..page.."/15")
	imgui.End()
end)

local function createCheckbox(label, index, table, exclusiveGroups)
    if imgui.Checkbox(label, new.bool(table[index])) then
        table[index] = not table[index]
        if table[index] and exclusiveGroups then
            for _, group in ipairs(exclusiveGroups) do
                for _, exclusiveIndex in ipairs(group) do
                    if exclusiveIndex ~= index then
                        table[exclusiveIndex] = false
                    end
                end
            end
        end
    end
end

local function createMenu(title, items, table, exclusiveGroups)
    imgui.Text(title)
    for _, item in ipairs(items) do
        createCheckbox(item.label, item.index, table, exclusiveGroups)
    end
end

imgui.OnFrame(function() return bmmenu[0] end,
function()
	if not menu[0] then
		bmmenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] - 164, autobind.menupos[2]))
    imgui.Begin(string.format("BM Settings", script.this.name, script.this.version), bmmenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		createMenu('Black-Market Equipment:', blackMarketItems, autobind.BlackMarket, blackMarketExclusiveGroups)
    imgui.End()
end)

imgui.OnFrame(function() return factionlockermenu[0] end,
function()
	if not menu[0] then
		factionlockermenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] + 599, autobind.menupos[2]))
    imgui.Begin(string.format("Faction Locker", script.this.name, script.this.version), factionlockermenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		createMenu('Locker Equipment:', lockerMenuItems, autobind.FactionLocker)
	imgui.End()
end)

imgui.OnFrame(function() return helpmenu[0] end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.Begin(string.format("Help Menu", script.this.name, script.this.version), helpmenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		imgui.Text("/autobind (Add Description )")
		imgui.Text("/vestnear (Add Description )")
		imgui.Text("/sexnear (Add Description )")
		imgui.Text("/repairnear (Add Description )")
		imgui.Text("/hfind (Add Description )")
		imgui.Text("/tcap (Add Description )")
		imgui.Text("/sprintbind (Add Description )")
		imgui.Text("/bikebind (Add Description )")
		imgui.Text("/av (Add Description )")
		imgui.Text("/ddmode (Add Description )")
		imgui.Text("/vestmode (Add Description )")
		imgui.Text("/factionboth (Add Description )")
		imgui.Text("/autovest (Add Description )")
		imgui.Text("/turfmode (Add Description )")
		imgui.Text("/pointmode (Add Description )")
	imgui.End()
end)

function dualswitch(title, key)
	imgui.Text(title)
	if imgui.Checkbox("Dual Keybind##"..key, new.bool(autobind.Keybinds[key].Dual)) then
		local key_split = split(autobind.Keybinds[key].Keybind, ",")
		if autobind.Keybinds[key].Dual then
			if string.contains(autobind.Keybinds[key].Keybind, ',', false) then
				inuse_key = true
				autobind.Keybinds[key] = {
					Toggle = autobind.Keybinds[key].Toggle,
					Dual = false,
					Keybind = tostring(key_split[2])
				}
				inuse_key = false
			end
		else
			inuse_key = true
			autobind.Keybinds[key] = {
				Toggle = autobind.Keybinds[key].Toggle,
				Dual = true,
				Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
			}
			inuse_key = false
		end
	end
	if imgui.Checkbox("Toggle Keybind##"..key, new.bool(autobind.Keybinds[key].Toggle)) then
		autobind.Keybinds[key].Toggle = not autobind.Keybinds[key].Toggle
	end
end

function loadskinidsurl()
	if not autobind.customskins then
		urlstring = https.request(autobind.skinsurl)
		if urlstring ~= nil then
			for skinid in string.match(urlstring, "<body>(.+)</body>").gmatch(urlstring, "%d*") do
				if string.len(skinid) > 0 then
					table.insert(skins, skinid)
				end
			end
		end
	end
end

function skins_script()
	for i = 0, 311 do
		if not doesFileExist(skinspath ..'Skin_'.. i ..'.png') then
			downloadUrlToFile(skins_url ..'Skin_'.. i ..'.png', skinspath ..'Skin_'.. i..'.png', function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} Skin_%d.png Downloaded", script.this.name, i), -1)
				end
			end)
		end
	end
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

    local function isIgnored(key)
        for _, ignoreKey in ipairs(ignoreKeys) do
            if key == ignoreKey then
                return true
            end
        end
        return false
    end

    local function isEmptyTable(t)
        return next(t) == nil
    end

    local function cleanupConfig(conf, def)
        local localStatus = false
        for k, v in pairs(conf) do
            if isIgnored(k) then
                return
            elseif def[k] == nil then
                conf[k] = nil
                localStatus = true
            elseif type(conf[k]) == "table" and type(def[k]) == "table" then
                localStatus = cleanupConfig(conf[k], def[k]) or localStatus
                if isEmptyTable(conf[k]) then
                    conf[k] = nil
                    localStatus = true
                end
            end
        end
        return localStatus
    end

    local function applyDefaults(conf, def)
        local localStatus = false
        for k, v in pairs(def) do
            if isIgnored(k) then
                return
            elseif conf[k] == nil or reset then
                if type(v) == "table" then
                    conf[k] = {}
                    localStatus = applyDefaults(conf[k], v) or localStatus
                else
                    conf[k] = v
                    localStatus = true
                end
            elseif type(v) == "table" and type(conf[k]) == "table" then
                localStatus = applyDefaults(conf[k], v) or localStatus
            end
        end
        return localStatus
    end

    setmetatable(config, {__index = function(t, k)
        if type(defaults[k]) == "table" then
            t[k] = {}
            applyDefaults(t[k], defaults[k])
            return t[k]
        end
    end})

    status = applyDefaults(config, defaults)
    status = cleanupConfig(config, defaults) or status
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
    file:write(encodeJson(config, true))
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

function comparePivots(pivot1, pivot2)
    return pivot1.x == pivot2.x and pivot1.y == pivot2.y
end

function findPivotIndex(pivot)
    for i, p in ipairs(pivots) do
        if comparePivots(p.value, pivot) then
            return p.name .. " " .. p.icon
        end
    end
    return "Unknown"
end

function formattedAddChatMessage(string, color)
    sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} %s", firstToUpper(scriptName), string), color)
end

function firstToUpper(string)
    return (string:gsub("^%l", string.upper))
end

function removeHexBrackets(text)
    return string.gsub(text, "{%x+}", "")
end

function formatWantedString(entry)
    local pingInfo = wanted.Settings.Ping and string.format(" (Ping: %d):", sampGetPlayerPing(entry.id)) or ""
    local chargeColor = entry.charges == 6 and "FF0000FF" or "B4B4B4"
    local chargeInfo = wanted.Settings.Stars and string.rep(fa.STAR, entry.charges) or string.format("%d outstanding %s.", entry.charges, entry.charges == 1 and "charge" or "charges")
    
    return string.format("%s (%d):%s {%s}%s", entry.name, entry.id, pingInfo, chargeColor, chargeInfo)
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

function sendBMCmd()
	lua_thread.create(function()
		bmcmd = bmcmd + 1
		if bmcmd ~= 3 then
			wait(500)
			sampSendChat("/bm")
		else
			wait(2000)
			bmcmd = 0
			sampSendChat("/bm")
		end
	end)
end

function sendLockerCmd()
	lua_thread.create(function()
		lockercmd = lockercmd + 1
		if lockercmd ~= 3 then
			wait(500)
			sampSendChat("/locker")
		else
			wait(2000)
			lockercmd = 0
			sampSendChat("/locker")
		end
	end)
end

function string.contains(str, matchstr, matchorfind)
	if matchorfind then
		if str:match(matchstr) then
			return true
		end
		return false
	else
		if str:find(matchstr) then
			return true
		end
		return false
	end
end

function keychange(name)
    if not autobind.Keybinds[name] then
        print("Warning: autobind.Keybinds[" .. name .. "] is nil")
        return
    end

    if not autobind.Keybinds[name].Dual then
        if not inuse_key then
            local buttonText = changekey[name] and 'Press any key' or (autobind.Keybinds[name].Keybind and vk.id_to_name(tonumber(autobind.Keybinds[name].Keybind)) or "Unknown")
            if imgui.Button(buttonText .. '##' .. name) then
                changekey[name] = true
                lua_thread.create(function()
                    while changekey[name] do wait(0)
                        local keydown, result = getDownKeys()
                        if result then
                            autobind.Keybinds[name].Keybind = string.format("%s", keydown)
                            changekey[name] = false
                        end
                    end
                end)
            end
        end
    else
        if not inuse_key then
            if autobind.Keybinds[name].Keybind and autobind.Keybinds[name].Keybind:find(",") then
                local key_split = split(autobind.Keybinds[name].Keybind, ",")
                if key_split[1] and key_split[2] then
                    local buttonText1 = changekey[name] and 'Press any key' or vk.id_to_name(tonumber(key_split[1]))
                    if imgui.Button(buttonText1 .. '##1' .. name) then
                        changekey[name] = true
                        lua_thread.create(function()
                            while changekey[name] do wait(0)
                                local keydown, result = getDownKeys()
                                if result then
                                    autobind.Keybinds[name].Keybind = string.format("%s,%s", keydown, key_split[2])
                                    changekey[name] = false
                                end
                            end
                        end)
                    end
                    imgui.SameLine()
                    local buttonText2 = changekey2[name] and 'Press any key' or vk.id_to_name(tonumber(key_split[2]))
                    if imgui.Button(buttonText2 .. '##2' .. name) then
                        changekey2[name] = true
                        lua_thread.create(function()
                            while changekey2[name] do wait(0)
                                local keydown, result = getDownKeys()
                                if result then
                                    autobind.Keybinds[name].Keybind = string.format("%s,%s", key_split[1], keydown)
                                    changekey2[name] = false
                                end
                            end
                        end)
                    end
                else
                    print("Warning: Invalid keybind format for " .. name)
                end
            else
                print("Warning: Invalid or missing keybind for " .. name)
            end
        end
    end
end

function getClosestPlayerId(maxdist, type)
	for i = 0, sampGetMaxPlayerId(false) do
        local result, remotePlayer = sampGetCharHandleBySampPlayerId(i)
        if result and not sampIsPlayerPaused(i) then
			local remotePlayerX, remotePlayerY, remotePlayerZ = getCharCoordinates(remotePlayer);
            local myPosX, myPosY, myPosZ = getCharCoordinates(playerPed)
            local dist = getDistanceBetweenCoords3d(remotePlayerX, remotePlayerY, remotePlayerZ, myPosX, myPosY, myPosZ)
            if dist <= maxdist then
				if type == 1 then
					return result, i
				elseif type == 2 and not isCharInAnyCar(ped) and isCharInAnyCar(remotePlayer) then
					return result, i
				end
			end
		end
    end
	return false, -1
end

function isPlayerAiming(thirdperson, firstperson)
	local id = mem.read(11989416, 2, false)
	if thirdperson and (id == 5 or id == 53 or id == 55 or id == 65) then return true end
	if firstperson and (id == 7 or id == 8 or id == 16 or id == 34 or id == 39 or id == 40 or id == 41 or id == 42 or id == 45 or id == 46 or id == 51 or id == 52) then return true end
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

function keycheck(k)
    local r = true
    for i = 1, #k.k do r = r and PressType[k.t[i]](k.k[i]) end
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

function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function split(str, delim, plain) -- bh FYP
   local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
   repeat
       local npos, epos = string.find(str, delim, pos, plain)
       table.insert(tokens, string.sub(str, pos, npos and npos - 1))
       pos = epos and epos + 1
   until not pos
   return tokens
end

function setGameKeyUpDown(key, value, delay)
	setGameKeyState(key, value)
	wait(delay)
	setGameKeyState(key, 0)
end

function disp_time(time)
  local remaining = time % 86400
  local minutes = math.floor(remaining/60)
  remaining = remaining % 60
  local seconds = remaining
  if (minutes < 10) then
    minutes = "0" .. tostring(minutes)
  end
  if (seconds < 10) then
    seconds = "0" .. tostring(seconds)
  end
  return tonumber(minutes), tonumber(seconds)
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

function getTarget(str)
	if str ~= nil then
		local maxplayerid, players = sampGetMaxPlayerId(false), {}
		for i = 0, maxplayerid do
			if sampIsPlayerConnected(i) then
				players[i] = sampGetPlayerNickname(i)
			end
		end
		for k, v in pairs(players) do
			if v:lower():find("^"..str:lower()) or string.match(k, str) then
				target = split((players[k] .. " " .. k), " ")
				playername = players[k]
				return true, target[2], playername
			elseif k == maxplayerid then
				return false
			end
		end
	end
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

function vestmodename(vestmode)
	if vestmode == 0 then
		return 'Families'
	elseif vestmode == 1 then
		return 'Factions'
	elseif vestmode == 2 then
		return 'Everyone'
	elseif vestmode == 3 then
		return 'Names'
	end
end

function hex2rgb(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r / 255, g / 255, b / 255
end

function join_argb_int(a, r, g, b)
	local argb = b * 255
    argb = bit.bor(argb, bit.lshift(g * 255, 8))
    argb = bit.bor(argb, bit.lshift(r * 255, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function imgui.AnimProgressBar(label, int, int2, duration, size)
	local function bringFloatTo(from, to, start_time, duration)
		local timer = os.clock() - start_time
		if timer >= 0.00 and timer <= duration then; local count = timer / (duration / int2); return from + (count * (to - from) / int2),timer,false
		end; return (timer > duration) and to or from,timer,true
	end
    if int > int2 then imgui.TextColored(imgui.ImVec4(1,0,0,0.7),'error func imgui.AnimProgressBar(*),int > 100') return end
    if IMGUI_ANIM_PROGRESS_BAR == nil then IMGUI_ANIM_PROGRESS_BAR = {} end
    if IMGUI_ANIM_PROGRESS_BAR ~= nil and IMGUI_ANIM_PROGRESS_BAR[label] == nil then
        IMGUI_ANIM_PROGRESS_BAR[label] = {int = (int or 0),clock = 0}
    end
    local mf = math.floor
    local p = IMGUI_ANIM_PROGRESS_BAR[label];
    if (p['int']) ~= (int) then
        if p.clock == 0 then; p.clock = os.clock(); end
        local d = {bringFloatTo(p.int,int,p.clock,(duration or 2.25))}
        if d[1] > int  then
            if ((d[1])-0.01) < (int) then; p.clock = 0; p.int = mf(d[1]-0.01); end
        elseif d[1] < int then
            if ((d[1])+0.01) > (int) then; p.clock = 0; p.int = mf(d[1]+0.01); end
        end
        p.int = d[1];
    end
    --imgui.PushStyleVarVec2(6, 15)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(1, 1, 1, 0.20)) -- background color progress bar
    imgui.PushStyleColor(imgui.Col.PlotHistogram, imgui.ImVec4(1, 1, 1, 0.30)) -- fill color progress bar
    imgui.ProgressBar(p.int / int2,size or imgui.ImVec2(-1,15))
    imgui.PopStyleColor(3)
    --imgui.PopStyleVar()
end

function apply_custom_style()
	imgui.SwitchContext()
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2
	local style = imgui.GetStyle()
	style.WindowRounding = 0
	style.WindowPadding = ImVec2(8, 8)
	style.WindowTitleAlign = ImVec2(0.5, 0.5)
	--style.ChildWindowRounding = 0
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
	--style.AntiAliasedShapes = true
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
	--colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	--colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	--colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	--colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	--colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	--colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

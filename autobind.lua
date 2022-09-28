script_name("Autobind")
script_author("akacross", "spnKO", "Farid", "P-Greggy", "checkdasound")
script_url("https://akacross.net/")
script_tester = {"Taro"}

local script_version = 1.7
local script_version_text = '1.7'

if getMoonloaderVersion() >= 27 then
	require 'libstd.deps' {
	   'fyp:mimgui',
	   'fyp:fa-icons-4',
	   'donhomka:extensions-lite'
	}
end

require"lib.moonloader"
require"lib.sampfuncs"
require 'extensions-lite'

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle
local sampev = require 'lib.samp.events'
local mem = require 'memory'
local https = require 'ssl.https'
local vk = require 'vkeys'
local keys  = require 'game.keys'
local wm  = require 'lib.windows.message'
local faicons = require 'fa-icons'
local ti = require 'tabler_icons'
local fa = require 'fAwesome5'
local dlstatus = require('moonloader').download_status
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local path = getWorkingDirectory() .. '\\config\\' 
local cfg = path .. 'autobind.ini'
local skinspath = getWorkingDirectory() .. '/resource/' .. 'skins/' 
local script_path = thisScript().path
local script_url = "https://raw.githubusercontent.com/akacross/autobind/main/autobind.lua"
local update_url = "https://raw.githubusercontent.com/akacross/autobind/main/autobind.txt"
local skins_url = "https://raw.githubusercontent.com/akacross/autobind/main/resource/skins/"

local blank = {}
local autobind = {}
local _enabled = true
local isIniLoaded = false
local isGamePaused = false
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
local hide = {false, false}
local capper_hide = false
local skins = {}
local factions = {61, 71, 73, 141, 163, 164, 165, 166, 191, 255, 265, 266, 267, 280, 281, 282, 283, 284, 285, 286, 287, 288, 294, 312, 300, 301, 306, 309, 310, 311, 120}
local factions_color = {-14269954, -7500289, -14911565}
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
local size = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}
local selectedbox = {false, false, false}
local skinTexture = {}
local selected = -1
local page = 1
local bike, moto = {[481] = true, [509] = true, [510] = true}, {[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true}
local captog = false
local autofind, cooldown = false, false

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

local function loadIconicFont(fromfile, fontSize, min, max, fontdata)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = new.ImWchar[3](min, max, 0)
	if fromfile then
		imgui.GetIO().Fonts:AddFontFromFileTTF(fontdata, fontSize, config, iconRanges)
	else
		imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fontdata, fontSize, config, iconRanges)
	end
end

imgui.OnInitialize(function()
	apply_custom_style() -- apply custom style

	loadIconicFont(false, 14.0, faicons.min_range, faicons.max_range, faicons.get_font_data_base85())
	loadIconicFont(true, 14.0, fa.min_range, fa.max_range, 'moonloader/resource/fonts/fa-solid-900.ttf')
	loadIconicFont(false, 14.0, ti.min_range, ti.max_range, ti.get_font_data_base85())
	
	imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return isIniLoaded and (autobind.notification[1] or hide[1] or menu[0]) and not isGamePaused and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) end,
function()
	if menu[0] then
		local mpos = imgui.GetMousePos()
		if mpos.x >= autobind.offerpos[1] and 
		   mpos.x <= autobind.offerpos[1] + size[1].x and 
		   mpos.y >= autobind.offerpos[2] and 
		   mpos.y <= autobind.offerpos[2] + size[1].y then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[1] = true
			end
		end
		if selectedbox[1] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[1] = false
			else
				autobind.offerpos[1] = mpos.x - (size[1].x / 2)
				autobind.offerpos[2] = mpos.y - (size[1].y / 2)
			end
		end
	end

	imgui.SetNextWindowPos(imgui.ImVec2(autobind.offerpos[1], autobind.offerpos[2]), imgui.Cond.Always)
	imgui.Begin("offer", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		if autobind.timer - (localClock() - _last_vest) > 0 then
			imgui.Text(string.format("You offered a vest to:\n%s[%s]\nNext vest in: %d\nVestmode: %s", sampname, playerid, autobind.timer - (localClock() - _last_vest), vestmodename(autobind.vestmode)))
		else
			imgui.Text(string.format("You offered a vest to:\n%s[%s]\nNext vest in: 0\nVestmode: %s", sampname, playerid, vestmodename(autobind.vestmode)))
				
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
		size[1] = imgui.GetWindowSize()
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return isIniLoaded and (autobind.notification[2] or hide[2] or menu[0]) and not isGamePaused and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) end,
function()
	if menu[0] then
		local mpos = imgui.GetMousePos()
		if mpos.x >= autobind.offeredpos[1] and 
		   mpos.x <= autobind.offeredpos[1] + size[2].x and 
		   mpos.y >= autobind.offeredpos[2] and 
		   mpos.y <= autobind.offeredpos[2] + size[2].y then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[2] = true
			end
		end
		if selectedbox[2] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[2] = false
			else
				autobind.offeredpos[1] = mpos.x - (size[2].x / 2)
				autobind.offeredpos[2] = mpos.y - (size[2].y / 2)
			end
		end
	end

	imgui.SetNextWindowPos(imgui.ImVec2(autobind.offeredpos[1], autobind.offeredpos[2]), imgui.Cond.Always)
	imgui.Begin("offered", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		if autobind.vestmode == 0 then
			imgui.Text(string.format("You got an offer from: \n%s[%s]\nAutoaccepter is %s", sampname2, playerid2, autoaccepter and 'enabled' or 'disabled'))
		else
			imgui.Text(string.format("You got an offer from: \n%s[%s]", sampname2, playerid2))
		end
		size[2] = imgui.GetWindowSize()
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return isIniLoaded and (autobind.notification_capper or capper_hide or menu[0]) and not isGamePaused and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) end,
function()
	if menu[0] then
		local mpos = imgui.GetMousePos()
		if mpos.x >= autobind.capperpos[1] and 
		   mpos.x <= autobind.capperpos[1] + size[3].x and 
		   mpos.y >= autobind.capperpos[2] and 
		   mpos.y <= autobind.capperpos[2] + size[3].y then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[3] = true
			end
		end
		if selectedbox[3] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[3] = false
			else
				autobind.capperpos[1] = mpos.x - (size[3].x / 2)
				autobind.capperpos[2] = mpos.y - (size[3].y / 2)
			end
		end
	end

	imgui.SetNextWindowPos(imgui.ImVec2(autobind.capperpos[1], autobind.capperpos[2]), imgui.Cond.Always)
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
		size[3] = imgui.GetWindowSize()
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return isIniLoaded and menu[0] and not isGamePaused end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
	imgui.Begin(fa.ICON_FA_SHIELD_ALT .. string.format(" %s Settings - Version: %s", script.this.name, script_version_text), menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)

		imgui.BeginChild("##1", imgui.ImVec2(85, 392), true)
				
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
      
			if imgui.CustomButton(
				faicons.ICON_POWER_OFF, 
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
				faicons.ICON_FLOPPY_O,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				saveIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Save the Script')
			end
      
			imgui.SetCursorPos(imgui.ImVec2(5, 157))

			if imgui.CustomButton(
				faicons.ICON_REPEAT, 
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				loadIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reload the Script')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 233))

			if imgui.CustomButton(
				faicons.ICON_ERASER, 
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				blankIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reset the Script to default settings')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 309))

			if imgui.CustomButton(
				faicons.ICON_RETWEET .. ' Update',
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1),  
				imgui.ImVec2(75, 75)) then
				update_script(true)
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Update the script')
			end
      
		imgui.EndChild()
		
		imgui.SetCursorPos(imgui.ImVec2(92, 28))

		imgui.BeginChild("##2", imgui.ImVec2(500, 88), true)
      
			imgui.SetCursorPos(imgui.ImVec2(5,5))
			if imgui.CustomButton(fa.ICON_FA_COG .. '  Settings',
				_menu == 1 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(165, 75)) then
				_menu = 1
			end

			imgui.SetCursorPos(imgui.ImVec2(170, 5))
			  
			if imgui.CustomButton(fa.ICON_FA_PERSON_BOOTH .. '  Skins',
				_menu == 2 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(165, 75)) then
			  
				_menu = 2
			end
			
			imgui.SetCursorPos(imgui.ImVec2(335, 5))
			
			if imgui.CustomButton(fa.ICON_FA_PERSON_BOOTH .. '  Names',
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
					imgui.Text("Settings Command:  ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_autovestsettingscmd = new.char[256](autobind.autovestsettingscmd)
					if imgui.InputText('##Autovestsettings command', text_autovestsettingscmd, sizeof(text_autovestsettingscmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.autovestsettingscmd = u8:decode(str(text_autovestsettingscmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Vest Near Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_vestnearcmd = new.char[256](autobind.vestnearcmd)
					if imgui.InputText('##vestnearcmd', text_vestnearcmd, sizeof(text_vestnearcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.vestnearcmd = u8:decode(str(text_vestnearcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Sex Near Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_sexnearcmd = new.char[256](autobind.sexnearcmd)
					if imgui.InputText('##sexnearcmd', text_sexnearcmd, sizeof(text_sexnearcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.sexnearcmd = u8:decode(str(text_sexnearcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Repair Near Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_repairnearcmd = new.char[256](autobind.repairnearcmd)
					if imgui.InputText('##repairnearcmd', text_repairnearcmd, sizeof(text_repairnearcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.repairnearcmd = u8:decode(str(text_repairnearcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("hFind Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_hfindcmd = new.char[256](autobind.hfindcmd)
					if imgui.InputText('##hfindcmd', text_hfindcmd, sizeof(text_hfindcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.hfindcmd = u8:decode(str(text_hfindcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Spam Cap Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_tcapcmd = new.char[256](autobind.tcapcmd)
					if imgui.InputText('##tcapcmd', text_tcapcmd, sizeof(text_tcapcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.tcapcmd = u8:decode(str(text_tcapcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Sprint Bind Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_sprintbindcmd = new.char[256](autobind.sprintbindcmd)
					if imgui.InputText('##sprintbindcmd', text_sprintbindcmd, sizeof(text_sprintbindcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.sprintbindcmd = u8:decode(str(text_sprintbindcmd))
					end
					imgui.PopItemWidth()
					imgui.Text("Bike Bind Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_bikebindcmd = new.char[256](autobind.bikebindcmd)
					if imgui.InputText('##bikebindcmd', text_bikebindcmd, sizeof(text_bikebindcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.bikebindcmd = u8:decode(str(text_bikebindcmd))
					end
					imgui.PopItemWidth()


					imgui.Text("Autovest Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_autovestcmd = new.char[256](autobind.autovestcmd)
					if imgui.InputText('##autovestcmd', text_autovestcmd, sizeof(text_autovestcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.autovestcmd = u8:decode(str(text_autovestcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Autoaccepter Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					
					local text_autoacceptercmd = new.char[256](autobind.autoacceptercmd)
					if imgui.InputText('##autoacceptercmd', text_autoacceptercmd, sizeof(text_autoacceptercmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.autoacceptercmd = u8:decode(str(text_autoacceptercmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("DD-Mode Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_ddmodecmd = new.char[256](autobind.ddmodecmd)
					if imgui.InputText('##ddmodecmd', text_ddmodecmd, sizeof(text_ddmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.ddmodecmd = u8:decode(str(text_ddmodecmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Vest Mode Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_vestmodecmd = new.char[256](autobind.vestmodecmd)
					if imgui.InputText('##vestmodecmd', text_vestmodecmd, sizeof(text_vestmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.vestmodecmd = u8:decode(str(text_vestmodecmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Faction Both Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_factionbothcmd = new.char[256](autobind.factionbothcmd)
					if imgui.InputText('##factionbothcmd', text_factionbothcmd, sizeof(text_factionbothcmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.factionbothcmd = u8:decode(str(text_factionbothcmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Point Mode Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_pointmodecmd = new.char[256](autobind.pointmodecmd)
					if imgui.InputText('##pointmodecmd', text_pointmodecmd, sizeof(text_pointmodecmd), imgui.InputTextFlags.EnterReturnsTrue) then
						autobind.pointmodecmd = u8:decode(str(text_pointmodecmd))
					end
					imgui.PopItemWidth()
					
					imgui.Text("Turf Mode Command: ")
					imgui.SameLine()
					imgui.PushItemWidth(125)
					local text_turfmodecmd = new.char[256](autobind.turfmodecmd)
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
					if imgui.Button(fa.ICON_FA_SYNC_ALT .. " Save and restart the script") then
						saveIni()
						thisScript():reload()
					end
				imgui.EndChild()

				imgui.SetCursorPos(imgui.ImVec2(340, 5))

				imgui.BeginChild("##keybinds", imgui.ImVec2(155, 263), true)
					if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " BM Settings") then
						bmmenu[0] = not bmmenu[0]
					end
					
					if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Faction Locker") then
						factionlockermenu[0] = not factionlockermenu[0]
					end
				
					imgui.Text("Accept Bodyguard:")
					if imgui.Checkbox("Dual Keybind##Accept", new.bool(autobind.Keybinds["Accept"].Dual)) then
						local key_split = split(autobind.Keybinds["Accept"].Keybind, ",")
						if autobind.Keybinds["Accept"].Dual then
							if string.contains(autobind.Keybinds['Accept'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["Accept"].Dual = false
								autobind.Keybinds["Accept"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["Accept"].Dual = true
							autobind.Keybinds["Accept"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##Accept", new.bool(autobind.Keybinds["Accept"].Toggle)) then
						autobind.Keybinds["Accept"].Toggle = not autobind.Keybinds["Accept"].Toggle
					end
					keychange('Accept', autobind.Keybinds["Accept"].Dual)
					
					imgui.Text("Offer Bodyguard:")
					if imgui.Checkbox("Dual Keybind##Offer", new.bool(autobind.Keybinds["Offer"].Dual)) then
						local key_split = split(autobind.Keybinds["Offer"].Keybind, ",")
						if autobind.Keybinds["Offer"].Dual then
							if string.contains(autobind.Keybinds['Offer'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["Offer"].Dual = false
								autobind.Keybinds["Offer"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["Offer"].Dual = true
							autobind.Keybinds["Offer"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##Offer", new.bool(autobind.Keybinds["Offer"].Toggle)) then
						autobind.Keybinds["Offer"].Toggle = not autobind.Keybinds["Offer"].Toggle
					end
					keychange('Offer', autobind.Keybinds["Offer"].Dual)
					
					imgui.Text("Black Market:")
					if imgui.Checkbox("Dual Keybind##BlackMarket", new.bool(autobind.Keybinds["BlackMarket"].Dual)) then
						local key_split = split(autobind.Keybinds["BlackMarket"].Keybind, ",")
						if autobind.Keybinds["BlackMarket"].Dual then
							if string.contains(autobind.Keybinds['BlackMarket'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["BlackMarket"].Dual = false
								autobind.Keybinds["BlackMarket"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["BlackMarket"].Dual = true
							autobind.Keybinds["BlackMarket"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##BlackMarket", new.bool(autobind.Keybinds["BlackMarket"].Toggle)) then
						autobind.Keybinds["BlackMarket"].Toggle = not autobind.Keybinds["BlackMarket"].Toggle
					end
					keychange('BlackMarket', autobind.Keybinds["BlackMarket"].Dual)
					
					imgui.Text("Faction Locker:")
					if imgui.Checkbox("Dual Keybind##FactionLocker", new.bool(autobind.Keybinds["FactionLocker"].Dual)) then
						local key_split = split(autobind.Keybinds["FactionLocker"].Keybind, ",")
						if autobind.Keybinds["FactionLocker"].Dual then
							if string.contains(autobind.Keybinds['FactionLocker'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["FactionLocker"].Dual = false
								autobind.Keybinds["FactionLocker"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["FactionLocker"].Dual = true
							autobind.Keybinds["FactionLocker"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##FactionLocker", new.bool(autobind.Keybinds["FactionLocker"].Toggle)) then
						autobind.Keybinds["FactionLocker"].Toggle = not autobind.Keybinds["FactionLocker"].Toggle
					end
					keychange('FactionLocker', autobind.Keybinds["FactionLocker"].Dual)
					
					imgui.Text("BikeBind:")
					if imgui.Checkbox("Dual Keybind##BikeBind", new.bool(autobind.Keybinds["BikeBind"].Dual)) then
						local key_split = split(autobind.Keybinds["BikeBind"].Keybind, ",")
						if autobind.Keybinds["BikeBind"].Dual then
							if string.contains(autobind.Keybinds['BikeBind'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["BikeBind"].Dual = false
								autobind.Keybinds["BikeBind"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["BikeBind"].Dual = true
							autobind.Keybinds["BikeBind"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##BikeBind", new.bool(autobind.Keybinds["BikeBind"].Toggle)) then
						autobind.Keybinds["BikeBind"].Toggle = not autobind.Keybinds["BikeBind"].Toggle
					end
					keychange('BikeBind', autobind.Keybinds["BikeBind"].Dual)
					
					imgui.Text("Sprintbind:")
					if imgui.Checkbox("Dual Keybind##SprintBind", new.bool(autobind.Keybinds["SprintBind"].Dual)) then
						local key_split = split(autobind.Keybinds["SprintBind"].Keybind, ",")
						if autobind.Keybinds["SprintBind"].Dual then
							if string.contains(autobind.Keybinds['SprintBind'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["SprintBind"].Dual = false
								autobind.Keybinds["SprintBind"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["SprintBind"].Dual = true
							autobind.Keybinds["SprintBind"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##SprintBind", new.bool(autobind.Keybinds["SprintBind"].Toggle)) then
						autobind.Keybinds["SprintBind"].Toggle = not autobind.Keybinds["SprintBind"].Toggle
					end
					imgui.PushItemWidth(40) 
					delay = new.int(autobind.SprintBind.delay)
					if imgui.DragInt('Speed', delay, 0.5, 0, 200) then 
						autobind.SprintBind.delay = delay[0] 
					end
					imgui.PopItemWidth()
					keychange('SprintBind', autobind.Keybinds["SprintBind"].Dual)
					
					imgui.Text("Frisk:")
					if imgui.Checkbox("Dual Keybind##Frisk", new.bool(autobind.Keybinds["Frisk"].Dual)) then
						local key_split = split(autobind.Keybinds["Frisk"].Keybind, ",")
						if autobind.Keybinds["Frisk"].Dual then
							if string.contains(autobind.Keybinds['Frisk'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["Frisk"].Dual = false
								autobind.Keybinds["Frisk"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["Frisk"].Dual = true
							autobind.Keybinds["Frisk"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##Frisk", new.bool(autobind.Keybinds["Frisk"].Toggle)) then
						autobind.Keybinds["Frisk"].Toggle = not autobind.Keybinds["Frisk"].Toggle
					end
					keychange('Frisk', autobind.Keybinds["Frisk"].Dual)
					
					imgui.Text("TakePills:")
					if imgui.Checkbox("Dual Keybind##TakePills", new.bool(autobind.Keybinds["TakePills"].Dual)) then
						local key_split = split(autobind.Keybinds["TakePills"].Keybind, ",")
						if autobind.Keybinds["TakePills"].Dual then
							if string.contains(autobind.Keybinds['Frisk'].Keybind, ',', true) then
								inuse_key = true
								autobind.Keybinds["TakePills"].Dual = false
								autobind.Keybinds["TakePills"].Keybind = tostring(key_split[2])
								inuse_key = false
							end
						else
							inuse_key = true
							autobind.Keybinds["TakePills"].Dual = true
							autobind.Keybinds["TakePills"].Keybind = tostring(VK_MENU)..','..tostring(key_split[1])
							inuse_key = false
						end
					end
					if imgui.Checkbox("Toggle Keybind##TakePills", new.bool(autobind.Keybinds["TakePills"].Toggle)) then
						autobind.Keybinds["TakePills"].Toggle = not autobind.Keybinds["TakePills"].Toggle
					end
					keychange('TakePills', autobind.Keybinds["TakePills"].Dual)
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
				saveIni() 
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

local frameDrawer = imgui.OnFrame(function() return isIniLoaded and skinmenu[0] and not isGamePaused end,
function()
	for i = 0, 311 do
		if skinTexture[i] == nil then
			skinTexture[i] = imgui.CreateTextureFromFile("moonloader/resource/skins/Skin_"..i..".png")
		end
	end
end,
function(self)
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(505, 390), imgui.Cond.FirstUseEver)
	imgui.Begin(u8("Skin Menu"), skinmenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar)
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

imgui.OnFrame(function() return isIniLoaded and bmmenu[0] and not isGamePaused end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

    imgui.Begin(string.format("BM Settings", script.this.name, script.this.version), bmmenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize) 
	
		imgui.Text('Black-Market Equipment:')
		
		if imgui.Checkbox('Full Health and Armor', new.bool(autobind.BlackMarket[1])) then 
			autobind.BlackMarket[1] = not autobind.BlackMarket[1] 
		end
		
		if imgui.Checkbox('Silenced Pistol', new.bool(autobind.BlackMarket[2])) then 
			autobind.BlackMarket[2] = not autobind.BlackMarket[2]
			if autobind.BlackMarket[2] then
				autobind.BlackMarket[3] = false
				autobind.BlackMarket[9] = false
			end
		end
		
		if imgui.Checkbox('9mm Pistol', new.bool(autobind.BlackMarket[3])) then 
			autobind.BlackMarket[3] = not autobind.BlackMarket[3] 
			if autobind.BlackMarket[3] then
				autobind.BlackMarket[2] = false
				autobind.BlackMarket[9] = false
			end
		end
		
		if imgui.Checkbox('Shotgun', new.bool(autobind.BlackMarket[4])) then 
			autobind.BlackMarket[4] = not autobind.BlackMarket[4] 
			if autobind.BlackMarket[4] then
				autobind.BlackMarket[12] = false
			end
		end
		if imgui.Checkbox('MP5', new.bool(autobind.BlackMarket[5])) then 
			autobind.BlackMarket[5] = not autobind.BlackMarket[5]
			if autobind.BlackMarket[5] then
				autobind.BlackMarket[6] = false
				autobind.BlackMarket[7] = false
			end
		end
		
		if imgui.Checkbox('UZI', new.bool(autobind.BlackMarket[6])) then 
			autobind.BlackMarket[6] = not autobind.BlackMarket[6]
			if autobind.BlackMarket[6] then
				autobind.BlackMarket[5] = false
				autobind.BlackMarket[7] = false
			end
		end
		
		if imgui.Checkbox('Tec-9', new.bool(autobind.BlackMarket[7])) then 
			autobind.BlackMarket[7] = not autobind.BlackMarket[7] 
			if autobind.BlackMarket[7] then
				autobind.BlackMarket[5] = false
				autobind.BlackMarket[6] = false
			end
		end
		
		if imgui.Checkbox('Country Rifle', new.bool(autobind.BlackMarket[8])) then 
			autobind.BlackMarket[8] = not autobind.BlackMarket[8] 
			if autobind.BlackMarket[8] then
				autobind.BlackMarket[13] = false
			end
		end
		
		if imgui.Checkbox('Deagle', new.bool(autobind.BlackMarket[9])) then 
			autobind.BlackMarket[9] = not autobind.BlackMarket[9]
			if autobind.BlackMarket[9] then
				autobind.BlackMarket[2] = false
				autobind.BlackMarket[3] = false
			end
		end
		
		if imgui.Checkbox('AK-47', new.bool(autobind.BlackMarket[10])) then 
			autobind.BlackMarket[10] = not autobind.BlackMarket[10]
			if autobind.BlackMarket[10] then
				autobind.BlackMarket[11] = false
			end
		end
		if imgui.Checkbox('M4', new.bool(autobind.BlackMarket[11])) then 
			autobind.BlackMarket[11] = not autobind.BlackMarket[11]
			if autobind.BlackMarket[11] then
				autobind.BlackMarket[10] = false
			end
		end
		
		if imgui.Checkbox('Spas-12', new.bool(autobind.BlackMarket[12])) then 
			autobind.BlackMarket[12] = not autobind.BlackMarket[12]
			if autobind.BlackMarket[12] then
				autobind.BlackMarket[4] = false
			end
		end
		
		if imgui.Checkbox('Sniper Rifle', new.bool(autobind.BlackMarket[13])) then 
			autobind.BlackMarket[13] = not autobind.BlackMarket[13] 
			if autobind.BlackMarket[13] then
				autobind.BlackMarket[8] = false
			end
		end
    imgui.End()
end)

imgui.OnFrame(function() return isIniLoaded and factionlockermenu[0] and not isGamePaused end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

    imgui.Begin(string.format("Faction Locker", script.this.name, script.this.version), factionlockermenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize) 
		imgui.Text('Locker Equipment:')
		if imgui.Checkbox('Deagle', new.bool(autobind.FactionLocker[1])) then 
			autobind.FactionLocker[1] = not autobind.FactionLocker[1] 
		end
		if imgui.Checkbox('Shotgun', new.bool(autobind.FactionLocker[2])) then 
			autobind.FactionLocker[2] = not autobind.FactionLocker[2] 
		end 
		if imgui.Checkbox('SPAS-12', new.bool(autobind.FactionLocker[3])) then 
			autobind.FactionLocker[3] = not autobind.FactionLocker[3] 
		end 
		if imgui.Checkbox('MP5', new.bool(autobind.FactionLocker[4])) then 
			autobind.FactionLocker[4] = not autobind.FactionLocker[4] 
		end 
		if imgui.Checkbox('M4', new.bool(autobind.FactionLocker[5])) then 
			autobind.FactionLocker[5] = not autobind.FactionLocker[5] 
		end
		if imgui.Checkbox('AK-47', new.bool(autobind.FactionLocker[6])) then 
			autobind.FactionLocker[6] = not autobind.FactionLocker[6] 
		end
		if imgui.Checkbox('Smoke Grenade', new.bool(autobind.FactionLocker[7])) then 
			autobind.FactionLocker[7] = not autobind.FactionLocker[7] 
		end
		if imgui.Checkbox('Camera', new.bool(autobind.FactionLocker[8])) then 
			autobind.FactionLocker[8] = not autobind.FactionLocker[8] 
		end
		if imgui.Checkbox('Sniper', new.bool(autobind.FactionLocker[9])) then 
			autobind.FactionLocker[9] = not autobind.FactionLocker[9]
		end
		if imgui.Checkbox('Vest', new.bool(autobind.FactionLocker[10])) then 
			autobind.FactionLocker[10] = not autobind.FactionLocker[10] 
		end
		if imgui.Checkbox('First Aid Kit', new.bool(autobind.FactionLocker[11])) then 
			autobind.FactionLocker[11] = not autobind.FactionLocker[11] 
		end
	imgui.End()
end)

imgui.OnFrame(function() return isIniLoaded and helpmenu[0] and not isGamePaused end,
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

function main()
	if not doesDirectoryExist(path) then createDirectory(path) end
	if not doesDirectoryExist(skinspath) then createDirectory(skinspath) end
	if doesFileExist(cfg) then loadIni() else blankIni() end
	while not isSampAvailable() do wait(100) end
	sampAddChatMessage("["..script.this.name..'] '.. "{FF1A74}(/autobind, autobind.help) Authors: " .. table.concat(thisScript().authors, ", ")..", Testers: ".. table.concat(script_tester, ", "), -1)
	
	if autobind.autoupdate then
		update_script(false)
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
							while autofind and not cooldown do
								wait(10)
								if sampIsPlayerConnected(target) then
									cooldown = true
									sampSendChat("/find "..target)
									wait(19000)
									cooldown = false
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
	
	if not autobind.enablebydefault then
		_enabled = false
	end
	
	loadskinidsurl()
	
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
										end
									else
										if has_number(skins, getCharModel(playerped)) then
											sendGuard(PlayerID)
										end
									end
								end
								if autobind.vestmode == 1 then
									local color = sampGetPlayerColor(PlayerID)
									local r, g, b = hex2rgb(color)
									color = join_argb_int(255, r, g, b)
									if (autobind.factionboth and has_number(factions, getCharModel(playerped)) and has_number(factions_color, color)) or (not autobind.factionboth and has_number(factions, getCharModel(playerped)) or has_number(factions_color, color)) then
										sendGuard(PlayerID)
									end
								end
								if autobind.vestmode == 2 then
									sendGuard(PlayerID)
								end
								if autobind.vestmode == 3 then
									for k, v in pairs(autobind.names) do
										if v == sampGetPlayerNickname(PlayerID) then
											sendGuard(PlayerID)
										end
									end
								end
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
			if flashing[1] and not timeset[1] then
				sampSendChat("/pointinfo")
				_last_point_capper_refresh = localClock()
			end
		end
		
		if _enabled and autobind.turf_capper_timer <= localClock() - _last_turf_capper_refresh then
			if flashing[2] and not timeset[2] then
				sampSendChat("/turfinfo")
				_last_turf_capper_refresh = localClock()
			end
		end
	end	
end

function listenToKeybinds()
	for k, v in pairs(autobind.Keybinds) do
		if _enabled then
			if string.contains(v.Keybind, ',', true) then
				local key_split = split(v.Keybind, ",")
				if k == 'Accept' and v.Toggle then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
						sampSendChat("/accept bodyguard")
						wait(1000)
					end
				end
				if k == 'Offer' and v.Toggle then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
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
										wait(1000)
									end
								end
							end
						end
					end
				end
				if k == "BlackMarket" and v.Toggle then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
						if not bmbool then
							bmbool = true
							sendBMCmd()
						end 
					end
				end
				if k == "FactionLocker" and v.Toggle then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
						if not lockerbool and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
							lockerbool = true
							sendLockerCmd()
						end
					end
				end
				if k == "BikeBind" then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyDown'}}) then
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
				end
				if k == "SprintBind" then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
						autobind.Keybinds.SprintBind.Toggle = not autobind.Keybinds.SprintBind.Toggle 
						sampAddChatMessage('[Autobind]{ffff00} Sprintbind: '..(autobind.Keybinds.SprintBind.Toggle and '{008000}on' or '{FF0000}off'), -1) 
					end
				end
				if k == "Frisk" and v.Toggle then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
						local _, playerped = storeClosestEntities(ped)
						local result, id = sampGetPlayerIdByCharHandle(playerped)
						local result2, target = getCharPlayerIsTargeting(h)
						if result then
							if (result2 and autobind.Frisk[1]) or not autobind.Frisk[1] then
								if (target == playerped and autobind.Frisk[1]) or not autobind.Frisk[1] then
									if (isPlayerAiming(true, true) and autobind.Frisk[2]) or not autobind.Frisk[2] then
										sampSendChat(string.format("/frisk %d", id))
										wait(1000)
									end
								end
							end
						end
					end
				end
				if k == 'TakePills' and v.Toggle then
					if keycheck({k  = {key_split[1], key_split[2]}, t = {'KeyDown', 'KeyPressed'}}) then
						sampSendChat("/takepills")
						wait(1000)
					end
				end
			else
				if k == 'Accept' and v.Toggle then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
						sampSendChat("/accept bodyguard")
						wait(1000)
					end
				end
					
				if k == 'Offer' and v.Toggle then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
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
										wait(1000)
									end
								end
							end
						end
					end
				end
				if k == "BlackMarket" and v.Toggle then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
						if not bmbool then
							bmbool = true
							sendBMCmd()
						end 
					end
				end
				if k == "FactionLocker" and v.Toggle then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
						if not lockerbool and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
							lockerbool = true
							sendLockerCmd()
						end
					end
				end
				if k == "BikeBind" then
					if keycheck({k  = {v.Keybind}, t = {'KeyDown'}}) then
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
				end
				if k == "SprintBind" then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
						autobind.Keybinds.SprintBind.Toggle = not autobind.Keybinds.SprintBind.Toggle
						sampAddChatMessage('[Autobind]{ffff00} Sprintbind: '..(autobind.Keybinds.SprintBind.Toggle and '{008000}on' or '{FF0000}off'), -1)
						wait(1000)
					end
				end
				if k == "Frisk" and v.Toggle then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
						local _, playerped = storeClosestEntities(ped)
						local result, id = sampGetPlayerIdByCharHandle(playerped)
						local result2, target = getCharPlayerIsTargeting(h)
						if result then
							if (result2 and autobind.Frisk[1]) or not autobind.Frisk[1] then
								if (target == playerped and autobind.Frisk[1]) or not autobind.Frisk[1] then
									if (isPlayerAiming(true, true) and autobind.Frisk[2]) or not autobind.Frisk[2] then
										sampSendChat(string.format("/frisk %d", id))
										wait(1000)
									end
								end
							end
						end
					end
				end
				if k == 'TakePills' and v.Toggle then
					if keycheck({k  = {v.Keybind}, t = {'KeyPressed'}}) then
						sampSendChat("/takepills")
						wait(1000)
					end
				end
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
			saveIni() 
		end 
	end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == wm.WM_KILLFOCUS then
		isGamePaused = true
	elseif msg == wm.WM_SETFOCUS then
		isGamePaused = false
	end

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
		wait(0)
		if flashing[1] and not timeset[1] then
			sampSendChat("/pointinfo")
			_last_point_capper_refresh = localClock()
		end
		if flashing[2] and not timeset[2] then
			sampSendChat("/turfinfo")
			_last_turf_capper_refresh = localClock()
		end
	end)
end

function sampev.onServerMessage(color, text)
	if text:find("The time is now") then 
		print(color)
		if autobind.capturf then 
			sampSendChat("/capturf") 
			if autobind.disableaftercapping then
				ab.tog[1] = false
			end
		end 
		if autobind.capture then 
			sampSendChat("/capture") 
			if autobind.disableaftercapping then
				ab.tog[2] = false
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

	for k, v in pairs(pointnamelist) do
		if text:find("*") and text:find(v) and text:find('Capper:') and text:find('Family:') and text:find('Time left:') and color == -86 then
			local location, nickname, pointname, number = ""
			if string.contains(text, "Less than", false) then
				location, nickname, pointname, number = text:match("* (.+) | Capper: (.+) | Family: (.+) | Time left: (.+) minutes")
			else
				location, nickname, pointname, number = text:match("* (.+) | Capper: (.+) | Family: (.+) | Time left: Less than (.+) minute")
			end
			
			point_capper = pointname 
			pointtime = number
			point_capper_capturedby = nickname
			point_location = location

			if autobind.notification_capper_hide then
				capper_hide = true
			end
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
		end
	end

	if text:find("is attempting to take over of the") and text:find('for') and text:find('they\'ll own it in 10 minutes.') and color == -65366 then
		local nickname, location, pointname = text:match("(.+) is attempting to take over of the (.+) for (.+), they'll own it in 10 minutes.")
		nickname = nickname:gsub("%s+", "_")
		
		point_capper = pointname
		point_capper_capturedby = nickname
		point_location = location
	
		_last_point_capper = localClock()
		timeset[1] = true
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
			if bmstate == 1 then
				if hasCharGotWeapon(ped, 24) or not autobind.BlackMarket[2] then
					bmstate = 2
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 6, nil)
				bmstate = 2
				sendBMCmd()
				return false
			end
			
			if bmstate == 2 then
				if hasCharGotWeapon(ped, 24) or not autobind.BlackMarket[3] then
					bmstate = 3
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 7, nil)
				bmstate = 3
				sendBMCmd()
				return false
			end
			if bmstate == 3 then
				if hasCharGotWeapon(ped, 27) or not autobind.BlackMarket[4] then
					bmstate = 4
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 8, nil)
				bmstate = 4
				sendBMCmd()
				return false
			end
			if bmstate == 4 then
				if hasCharGotWeapon(ped, 29) or not autobind.BlackMarket[5] then
					bmstate = 5
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 9, nil)
				bmstate = 5
				sendBMCmd()
				return false
			end
			if bmstate == 5 then
				if hasCharGotWeapon(ped, 29) or not autobind.BlackMarket[6] then
					bmstate = 6
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 10, nil)
				bmstate = 6
				sendBMCmd()
				return false
			end
			if bmstate == 6 then
				if hasCharGotWeapon(ped, 29) or not autobind.BlackMarket[7] then
					bmstate = 7
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 11, nil)
				bmstate = 7
				sendBMCmd()
				return false
			end
			if bmstate == 7 then
				if hasCharGotWeapon(ped, 34) or not autobind.BlackMarket[8] then
					bmstate = 8
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 12, nil) 
				bmstate = 8
				sendBMCmd()
				return false
			end
			if bmstate == 8 then
				if hasCharGotWeapon(ped, 24) or not autobind.BlackMarket[9] then
					bmstate = 9
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 13, nil)
				bmstate = 9
				sendBMCmd()
				return false
			end
			if bmstate == 9 then
				if hasCharGotWeapon(ped, 31) or not autobind.BlackMarket[10] then
					bmstate = 10
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 14, nil) 
				bmstate = 10
				sendBMCmd()
				return false
			end
			if bmstate == 10 then
				if hasCharGotWeapon(ped, 31) or not autobind.BlackMarket[11] then
					bmstate = 11
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 15, nil)
				bmstate = 11
				sendBMCmd()
				return false
			end
			
			if bmstate == 11 then
				if hasCharGotWeapon(ped, 27) or not autobind.BlackMarket[12] then
					bmstate = 12
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 16, nil)
				bmstate = 12
				sendBMCmd()
				return false
			end
			if bmstate == 12 then
				if hasCharGotWeapon(ped, 34) or not autobind.BlackMarket[13] then
					bmbool = false
					bmstate = 0
					bmcmd = 0
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 17, nil)
				bmbool = false
				bmstate = 0
				bmcmd = 0
				return false
			end
		end
	end
	if lockerbool then
		if title:find('LSPD Menu') or title:find('FBI Menu') or title:find('ARES Menu') then
			sampSendDialogResponse(id, 1, 1, nil)
			return false
		end
		
		if title:find('LSPD Equipment') or title:find('FBI Weapons') or title:find('ARES Equipment') then
		
			--Deagle
			if lockerstate == 0 then
				if hasCharGotWeapon(PLAYER_PED, 24) or autobind.FactionLocker[1] == false then
					lockerstate = 1
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 0, nil)
				lockerstate = 1
				sendLockerCmd()
				return false
			end

			--Shotgun
			if lockerstate == 1 then
				if hasCharGotWeapon(PLAYER_PED, 25) or hasCharGotWeapon(PLAYER_PED, 27) or autobind.FactionLocker[2] == false then
					lockerstate = 2
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 1, nil)
				lockerstate = 2
				sendLockerCmd()
				return false
			end

			--SPAS-12
			if lockerstate == 2 then
				if hasCharGotWeapon(PLAYER_PED, 27) or autobind.FactionLocker[3] == false then
					lockerstate = 3
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 2, nil)
				lockerstate = 3
				sendLockerCmd()
				return false
			end

			--MP5
			if lockerstate == 3 then
				if hasCharGotWeapon(PLAYER_PED, 29) or autobind.FactionLocker[4] == false then
					lockerstate = 4
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 3, nil)
				lockerstate = 4
				sendLockerCmd()
				return false
			end

			--M4
			if lockerstate == 4 then
				if hasCharGotWeapon(PLAYER_PED, 31) or autobind.FactionLocker[5] == false then
					lockerstate = 5
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 4, nil)
				lockerstate = 5
				sendLockerCmd()
				return false
			end

			--AK-47
			if lockerstate == 5 then
				if hasCharGotWeapon(PLAYER_PED, 30) or autobind.FactionLocker[6] == false then
					lockerstate = 6
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 5, nil)
				lockerstate = 6
				sendLockerCmd()
				return false
			end

			--Smoke Grenade
			if lockerstate == 6 then
				if hasCharGotWeapon(PLAYER_PED, 17) or autobind.FactionLocker[7] == false then
					lockerstate = 7
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 6, nil)
				lockerstate = 7
				sendLockerCmd()
				return false
			end     

			--Camera
			if lockerstate == 7 then
				if hasCharGotWeapon(PLAYER_PED, 43) or autobind.FactionLocker[8] == false then
					lockerstate = 8
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 7, nil)
				lockerstate = 8
				sendLockerCmd()
				return false
			end

			--Sniper Rifle
			if lockerstate == 8 then
				if hasCharGotWeapon(PLAYER_PED, 34) or autobind.FactionLocker[9] == false then
					lockerstate = 9
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 8, nil)
				lockerstate = 9
				sendLockerCmd()
				return false
			end

			--Armor
			if lockerstate == 9 then
				if(getCharArmour(PLAYER_PED) == 100 or autobind.FactionLocker[10] == false) then
					lockerstate = 10
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end

				sampSendDialogResponse(id, 1, 9, nil)
				lockerstate = 10
				sendLockerCmd()
				return false
			end
		  
			--Health
			if lockerstate == 10 then
				if getCharHealth(ped) - 5000000 == 100 or autobind.FactionLocker[11] == false then
					lockerbool = false
					lockerstate = 0
					lockercmd = 0
					return false
				end

				sampSendDialogResponse(id, 1, 10, nil)
				lockerbool = false
				lockerstate = 0
				lockercmd = 0
				return false
			end
		end
	end
end

function sampev.onTogglePlayerSpectating(state)
    specstate = state
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

function update_script(noupdatecheck)
	local update_text = https.request(update_url)
	if update_text ~= nil then
		update_version = update_text:match("version: (.+)")
		if tonumber(update_version) > script_version then
			sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} New version found! The update is in progress..", script.this.name), -1)
			downloadUrlToFile(script_url, script_path, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update was successful! Reloading the script in 20 seconds!", script.this.name), -1)
					lua_thread.create(function() 
						menu[0] = false
						skinmenu[0] = false
						bmmenu[0] = false
						factionlockermenu[0] = false
						helpmenu[0] = false
						wait(20000) 
						thisScript():reload()
					end)
				end
			end)
		else
			if noupdatecheck then
				sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} No new version found..", script.this.name), -1)
			end
		end
	end
end

function blankIni()
	autobind = {}
	repairmissing()
	saveIni()
	isIniLoaded = true
end

function loadIni()
	local f = io.open(cfg, "r")
	if f then
		autobind = decodeJson(f:read("*all"))
		f:close()
	end
	repairmissing()
	saveIni()
	isIniLoaded = true
end

function saveIni()
	if type(autobind) == "table" then
		local f = io.open(cfg, "w")
		f:close()
		if f then
			f = io.open(cfg, "r+")
			f:write(encodeJson(autobind))
			f:close()
		end
	end
end

function repairmissing()
	if autobind.autosave == nil then 
		autobind.autosave = true
	end
	if autobind.autoupdate == nil then 
		autobind.autoupdate = false
	end
	if autobind.ddmode == nil then
		autobind.ddmode = false
	end
	if autobind.capturf == nil then
		autobind.capturf = false
	end
	if autobind.capture == nil then
		autobind.capture = false
	end
	if autobind.autoacceptsex == nil then
		autobind.autoacceptsex = false
	end
	if autobind.autoacceptrepair == nil then
		autobind.autoacceptrepair = false
	end
	if autobind.disableaftercapping == nil then
		autobind.disableaftercapping = false
	end
	if autobind.factionboth == nil then 
		autobind.factionboth = false
	end
	if autobind.enablebydefault == nil then 
		autobind.enablebydefault = true
	end
	if autobind.sound == nil then 
		autobind.sound = true
	end
	if autobind.timercorrection == nil then 
		autobind.timercorrection = true
	end
	if autobind.messages == nil then 
		autobind.messages = false
	end
	if autobind.customskins == nil then 
		autobind.customskins = true
	end
	if autobind.gettarget == nil then
		autobind.gettarget = false
	end
	if autobind.notification == nil then
		autobind.notification = {}
	end
	if autobind.notification[1] == nil then 
		autobind.notification[1] = true
	end
	if autobind.notification[2] == nil then 
		autobind.notification[2] = true
	end
	if autobind.notification_hide == nil then
		autobind.notification_hide = {}
	end
	if autobind.notification_hide[1] == nil then 
		autobind.notification_hide[1] = false
	end
	if autobind.notification_hide[2] == nil then 
		autobind.notification_hide[2] = false
	end
	if autobind.showprevest == nil then 
		autobind.showprevest = true
	end
	if autobind.notification_capper == nil then 
		autobind.notification_capper = true
	end
	if autobind.notification_capper_hide == nil then 
		autobind.notification_capper_hide = false
	end
	if autobind.point_turf_mode == nil then 
		autobind.point_turf_mode = false
	end
	if autobind.vestmode == nil then 
		autobind.vestmode = 2
	end
	if autobind.timer == nil then 
		autobind.timer = 12
	end
	if autobind.point_capper_timer == nil then 
		autobind.point_capper_timer = 14
	end
	if autobind.turf_capper_timer == nil then 
		autobind.turf_capper_timer = 17
	end
	if autobind.skinsurl == nil then
		autobind.skinsurl = "https://akacross.net/skins.html"
	end
	if autobind.skins == nil then
		autobind.skins = {}
	end
	if autobind.autovestsettingscmd == nil then 
		autobind.autovestsettingscmd = "autobind"
	end
	if autobind.helpcmd == nil then 
		autobind.helpcmd = "autobind.help"
	end
	if autobind.vestnearcmd == nil then 
		autobind.vestnearcmd = "vestnear"
	end
	if autobind.sexnearcmd == nil then 
		autobind.sexnearcmd = "sexnear"
	end
	if autobind.repairnearcmd == nil then 
		autobind.repairnearcmd = "repairnear"
	end
	if autobind.hfindcmd == nil then 
		autobind.hfindcmd = "hfind"
	end
	if autobind.tcapcmd == nil then 
		autobind.tcapcmd = "tcap"
	end
	if autobind.sprintbindcmd == nil then 
		autobind.sprintbindcmd = "sprintbind"
	end
	if autobind.bikebindcmd == nil then 
		autobind.bikebindcmd = "bikebind"
	end
	if autobind.autoacceptercmd == nil then 
		autobind.autoacceptercmd = "av"
	end
	if autobind.ddmodecmd == nil then 
		autobind.ddmodecmd = "ddmode"
	end
	if autobind.vestmodecmd == nil then 
		autobind.vestmodecmd = "vestmode"
	end
	if autobind.factionbothcmd == nil then 
		autobind.factionbothcmd = "factionboth"
	end
	if autobind.autovestcmd == nil then 
		autobind.autovestcmd = "autovest"
	end
	if autobind.turfmodecmd == nil then 
		autobind.turfmodecmd = 'turfmode'
	end
	if autobind.pointmodecmd == nil then 
		autobind.pointmodecmd = 'pointmode'
	end
	if autobind.offerpos == nil then 
		autobind.offerpos = {10, 273}
	end
	if autobind.offeredpos == nil then 
		autobind.offeredpos = {10, 348}
	end
	if autobind.capperpos == nil then 
		autobind.capperpos = {10, 396}
	end
	if autobind.names == nil then 
		autobind.names = {}
	end
	if autobind.Keybinds == nil then
		autobind.Keybinds = {}
	end
	if autobind.Keybinds.Accept == nil then
		autobind.Keybinds.Accept = {}
	end
	if autobind.Keybinds.Accept.Toggle == nil then 
		autobind.Keybinds.Accept.Toggle = true
	end
	if autobind.Keybinds.Accept.Keybind == nil then 
		autobind.Keybinds.Accept.Keybind = tostring(VK_MENU)..','..tostring(VK_V)
	end
	if autobind.Keybinds.Accept.Dual == nil then 
		autobind.Keybinds.Accept.Dual = true
	end
	if autobind.Keybinds.Offer == nil then
		autobind.Keybinds.Offer = {}
	end
	if autobind.Keybinds.Offer.Toggle == nil then 
		autobind.Keybinds.Offer.Toggle = true
	end
	if autobind.Keybinds.Offer.Keybind == nil then 
		autobind.Keybinds.Offer.Keybind = tostring(VK_MENU)..','..tostring(VK_O)
	end
	if autobind.Keybinds.Offer.Dual == nil then 
		autobind.Keybinds.Offer.Dual = true
	end
	if autobind.Keybinds.BlackMarket == nil then
		autobind.Keybinds.BlackMarket = {}
	end
	if autobind.Keybinds.BlackMarket.Toggle == nil then 
		autobind.Keybinds.BlackMarket.Toggle = false
	end
	if autobind.Keybinds.BlackMarket.Keybind == nil then 
		autobind.Keybinds.BlackMarket.Keybind = tostring(VK_MENU)..','..tostring(VK_X)
	end
	if autobind.Keybinds.BlackMarket.Dual == nil then 
		autobind.Keybinds.BlackMarket.Dual = true
	end
	if autobind.Keybinds.FactionLocker == nil then
		autobind.Keybinds.FactionLocker = {}
	end
	if autobind.Keybinds.FactionLocker.Toggle == nil then 
		autobind.Keybinds.FactionLocker.Toggle = false
	end
	if autobind.Keybinds.FactionLocker.Keybind == nil then 
		autobind.Keybinds.FactionLocker.Keybind = tostring(VK_MENU)..','..tostring(VK_X)
	end
	if autobind.Keybinds.FactionLocker.Dual == nil then 
		autobind.Keybinds.FactionLocker.Dual = true
	end
	if autobind.Keybinds.BikeBind == nil then
		autobind.Keybinds.BikeBind = {}
	end
	if autobind.Keybinds.BikeBind.Toggle == nil then 
		autobind.Keybinds.BikeBind.Toggle = false
	end
	if autobind.Keybinds.BikeBind.Keybind == nil then 
		autobind.Keybinds.BikeBind.Keybind = tostring(VK_SHIFT)
	end
	if autobind.Keybinds.BikeBind.Dual == nil then 
		autobind.Keybinds.BikeBind.Dual = false
	end
	if autobind.Keybinds.SprintBind == nil then
		autobind.Keybinds.SprintBind = {}
	end
	if autobind.Keybinds.SprintBind.Toggle == nil then 
		autobind.Keybinds.SprintBind.Toggle = true
	end
	if autobind.Keybinds.SprintBind.Keybind == nil then 
		autobind.Keybinds.SprintBind.Keybind = tostring(VK_F11)
	end
	if autobind.Keybinds.SprintBind.Dual == nil then 
		autobind.Keybinds.SprintBind.Dual = false
	end
	if autobind.Keybinds.Frisk == nil then
		autobind.Keybinds.Frisk = {}
	end
	if autobind.Keybinds.Frisk.Toggle == nil then 
		autobind.Keybinds.Frisk.Toggle = false
	end
	if autobind.Keybinds.Frisk.Keybind == nil then 
		autobind.Keybinds.Frisk.Keybind = tostring(VK_MENU)..','..tostring(VK_F)
	end
	if autobind.Keybinds.Frisk.Dual == nil then 
		autobind.Keybinds.Frisk.Dual = true
	end
	if autobind.Keybinds.TakePills == nil then
		autobind.Keybinds.TakePills = {}
	end
	if autobind.Keybinds.TakePills.Toggle == nil then 
		autobind.Keybinds.TakePills.Toggle = false
	end
	if autobind.Keybinds.TakePills.Keybind == nil then 
		autobind.Keybinds.TakePills.Keybind = tostring(VK_F3)
	end
	if autobind.Keybinds.TakePills.Dual == nil then 
		autobind.Keybinds.TakePills.Dual = false
	end
	
	if autobind.BlackMarket == nil then
		autobind.BlackMarket = {}
	end
	if autobind.BlackMarket[1] == nil then 
		autobind.BlackMarket[1] = true
	end
	if autobind.BlackMarket[2] == nil then 
		autobind.BlackMarket[2] = false
	end
	if autobind.BlackMarket[3] == nil then 
		autobind.BlackMarket[3] = false
	end
	if autobind.BlackMarket[4] == nil then 
		autobind.BlackMarket[4] = false
	end
	if autobind.BlackMarket[5] == nil then 
		autobind.BlackMarket[5] = false
	end
	if autobind.BlackMarket[6] == nil then 
		autobind.BlackMarket[6] = false
	end
	if autobind.BlackMarket[7] == nil then 
		autobind.BlackMarket[7] = false
	end
	if autobind.BlackMarket[8] == nil then 
		autobind.BlackMarket[8] = false
	end
	if autobind.BlackMarket[9] == nil then 
		autobind.BlackMarket[9] = true
	end
	if autobind.BlackMarket[10] == nil then 
		autobind.BlackMarket[10] = false
	end
	if autobind.BlackMarket[11] == nil then 
		autobind.BlackMarket[11] = false
	end
	if autobind.BlackMarket[12] == nil then 
		autobind.BlackMarket[12] = false
	end
	if autobind.BlackMarket[13] == nil then 
		autobind.BlackMarket[13] = false
	end
	
	if autobind.FactionLocker == nil then
		autobind.FactionLocker = {}
	end
	if autobind.FactionLocker[1] == nil then 
		autobind.FactionLocker[1] = true
	end
	if autobind.FactionLocker[2] == nil then 
		autobind.FactionLocker[2] = true
	end
	if autobind.FactionLocker[3] == nil then 
		autobind.FactionLocker[3] = false
	end
	if autobind.FactionLocker[4] == nil then 
		autobind.FactionLocker[4] = true
	end
	if autobind.FactionLocker[5] == nil then 
		autobind.FactionLocker[5] = false
	end
	if autobind.FactionLocker[6] == nil then 
		autobind.FactionLocker[6] = false
	end
	if autobind.FactionLocker[7] == nil then 
		autobind.FactionLocker[7] = false
	end
	if autobind.FactionLocker[8] == nil then 
		autobind.FactionLocker[8] = false
	end
	if autobind.FactionLocker[9] == nil then 
		autobind.FactionLocker[9] = false
	end
	if autobind.FactionLocker[10] == nil then 
		autobind.FactionLocker[10] = true
	end
	if autobind.FactionLocker[11] == nil then 
		autobind.FactionLocker[11] = true
	end
	
	if autobind.SprintBind == nil then
		autobind.SprintBind = {}
	end
	if autobind.SprintBind.delay == nil then 
		autobind.SprintBind.delay = 10
	end
	
	if autobind.Frisk == nil then
		autobind.Frisk = {}
	end
	if autobind.Frisk[1] == nil then 
		autobind.Frisk[1] = false
	end
	if autobind.Frisk[2] == nil then 
		autobind.Frisk[2] = false
	end
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

function keychange(name, dual)
	if not dual then
		if imgui.Button(changekey[name] and 'Press any key' or vk.id_to_name(tonumber(autobind.Keybinds[name].Keybind))..'##'..name) then
			if not autobind.Keybinds[name].Dual and not inuse_key then
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
		if autobind.Keybinds[name].Keybind:match(",") and autobind.Keybinds[name].Dual and not inuse_key then
			local key_split = split(autobind.Keybinds[name].Keybind, ",")
			if imgui.Button(changekey[name] and 'Press any key' or vk.id_to_name(tonumber(key_split[1]))..'##1'..name) then
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
			if imgui.Button(changekey2[name] and 'Press any key' or vk.id_to_name(tonumber(key_split[2]))..'##2'..name) then
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
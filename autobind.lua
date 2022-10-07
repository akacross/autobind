script_name("Autobind")
script_author("akacross", "spnKO", "Farid", "P-Greggy")
script_url("https://akacross.net/")
script_tester = {"Taro", "Marowan", "Adib", "Kobe", "Liam", "Patsy"}

local script_version = 2.3
local script_version_text = '2.3'

require"lib.moonloader"
require"lib.sampfuncs"

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local mainc = imgui.ImVec4(0.98, 0.26, 0.26, 1.00)
local ped, h = playerPed, playerHandle
local sampev = require 'lib.samp.events'
local mem = require 'memory'
local https = require 'ssl.https'
local dlstatus = require('moonloader').download_status
local lfs = require 'lfs'
local flag = require ('moonloader').font_flag
local vk = require 'vkeys'
local keys  = require 'game.keys'
local wm  = require 'lib.windows.message'
local fa = require 'fAwesome6'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local path = getWorkingDirectory() .. '\\config\\' 
local resourcepath = getWorkingDirectory() .. '/resource/'
local skinspath = resourcepath .. 'skins/' 
local audiopath =  resourcepath .. "audio/"
local audiofolder =  audiopath .. thisScript().name .. "/"
local autobind_cfg = path .. thisScript().name .. '.ini'
local help_cfg = path .. 'help.ini'
local script_path = thisScript().path
local script_url = "https://raw.githubusercontent.com/akacross/autobind/main/autobind.lua"
local update_url = "https://raw.githubusercontent.com/akacross/autobind/main/autobind.txt"
local skins_url = "https://raw.githubusercontent.com/akacross/autobind/main/resource/skins/"
local sounds_url = "https://raw.githubusercontent.com/akacross/autobind/main/resource/audio/Autobind/"

local blank = {}
local help = {}
local autobind = {}
local _enabled = true
local _autovest = true
local isIniLoaded = false
local isGamePaused = false
local menu = new.bool(false)
local imguisettings = new.bool(false)
local _menu = 1
local skinmenu = new.bool(false)
local bmmenu = new.bool(false)
local factionlockermenu = new.bool(false)
local ganglockermenu = new.bool(false)
local _you_are_not_bodyguard = true
local paths = {}
local sounds = nil
local autoaccepter = false
local autoacceptertoggle = false
local specstate = false
local updateskin = false
local faidtoggle = false
local timeset = {false, false}
local flashing = {false, false}
local point_capper_timer = 750
local turf_capper_timer = 1050
local faid_timer = 3
local _last_vest = 0
local _last_point_capper = 0
local _last_turf_capper = 0
local _last_point_capper_refresh = 0
local _last_turf_capper_refresh = 0
local _last_timer_faid = 0
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
local pointtime = 0
local turftime = 0
local pointspam = false
local turfspam = false
local disablepointspam = false
local disableturfspam = false
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
local gangbool = false
local gangstate = 0
local gangcmd = 0
local inuse_move = false
local temp = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}
local size = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}
local menusize = {580, 410}
local selectedbox = {false, false, false,false}
local skinTexture = {}
local selected = -1
local page = 1
local bike, moto = {[481] = true, [509] = true, [510] = true}, {[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true}
local captog = false
local autofind, cooldown_bool = false, false
local streamedplayers = nil
local fid = nil
local selected2 = false
local inuse_move = false

local fa6fontlist = {
	"thin",
	"light",
	"regular",
	"solid",
	"duotone"
}

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

imgui.OnInitialize(function()
	mainc = imgui.ImVec4(autobind.imcolor[1], autobind.imcolor[2], autobind.imcolor[3], autobind.imcolor[4])
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
		"CART_SHOPPING",
		"ARROWS_REPEAT"
	}
	for _, b in ipairs(list) do
		builder:AddText(fa(b))
	end
	defaultGlyphRanges1 = imgui.ImVector_ImWchar()
	builder:BuildRanges(defaultGlyphRanges1)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85(autobind.fa6), 14, config, defaultGlyphRanges1[0].Data)
	
	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return isIniLoaded and (autobind.notification[1] or hide[1] or menu[0]) and not isGamePaused and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) and _enabled and _autovest end,
function()
	if menu[0] then
		if mposX >= autobind.offeredpos[1] and 
		   mposX <= autobind.offeredpos[1] + size[1].x and 
		   mposY >= autobind.offeredpos[2] and 
		   mposY <= autobind.offeredpos[2] + size[1].y then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[1] = true
				temp[1].x = mposX - autobind.offeredpos[1]
				temp[1].y = mposY - autobind.offeredpos[2]
			end
		end
		if selectedbox[1] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[1] = false
			else
				autobind.offeredpos[1] = mposX - temp[1].x
				autobind.offeredpos[2] = mposY - temp[1].y
			end
		end
	end

	imgui.SetNextWindowPos(imgui.ImVec2(autobind.offeredpos[1], autobind.offeredpos[2]))
	imgui.Begin("offered", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		if autobind.progressbar.toggle then
			imgui.AnimProgressBar('##Timer', autobind.timer - (localClock() - _last_vest), autobind.timer, 50, imgui.ImVec2(-1,15), 
				imgui.ImVec4(autobind.progressbar.colorfade[1], autobind.progressbar.colorfade[2], autobind.progressbar.colorfade[3], autobind.progressbar.colorfade[4]), 
				imgui.ImVec4(autobind.progressbar.color[1], autobind.progressbar.color[2], autobind.progressbar.color[3], autobind.progressbar.color[4])
			)
		end
		if autobind.timer - (localClock() - _last_vest) > 0 then
			imgui.Text(string.format("%sYou offered a vest to:\n%s[%s]\nVestmode: %s", autobind.timertext and string.format("Next vest in: %d\n", autobind.timer - (localClock() - _last_vest)) or '', sampname, playerid, vestmodename(autobind.vestmode)))
		else
			imgui.Text(string.format("%sYou offered a vest to:\n%s[%s]\nVestmode: %s", autobind.timertext and "Next vest in: 0\n" or "", sampname, playerid, vestmodename(autobind.vestmode)))
				
			if autobind.notification[1] and not autobind.showpreoffered then
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

imgui.OnFrame(function() return isIniLoaded and (autobind.notification[2] or hide[2] or menu[0]) and not isGamePaused and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) and _enabled and _autovest end,
function()
	if menu[0] then
		if mposX >= autobind.offerpos[1] and 
		   mposX <= autobind.offerpos[1] + size[2].x and 
		   mposY >= autobind.offerpos[2] and 
		   mposY <= autobind.offerpos[2] + size[2].y then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[2] = true
				temp[2].x = mposX - autobind.offerpos[1]
				temp[2].y = mposY - autobind.offerpos[2]
			end
		end
		if selectedbox[2] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[2] = false
			else
				autobind.offerpos[1] = mposX - temp[2].x
				autobind.offerpos[2] = mposY - temp[2].y
			end
		end
	end

	imgui.SetNextWindowPos(imgui.ImVec2(autobind.offerpos[1], autobind.offerpos[2]))
	imgui.Begin("offer", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
		imgui.Text(string.format("You got an offer from: \n%s[%s]\nAutoaccepter is %s", sampname2, playerid2, autoaccepter and 'enabled' or 'disabled'))
		if menu[0] then
			size[2] = imgui.GetWindowSize()
		end
	imgui.End()
end).HideCursor = true

imgui.OnFrame(function() return isIniLoaded and (autobind.notification_capper or capper_hide or menu[0]) and not isGamePaused and not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) and _enabled end,
function()
	if menu[0] then
		if mposX >= autobind.capperpos[1] and 
		   mposX <= autobind.capperpos[1] + size[3].x and 
		   mposY >= autobind.capperpos[2] and 
		   mposY <= autobind.capperpos[2] + size[3].y then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[3] = true
				temp[3].x = mposX - autobind.capperpos[1]
				temp[3].y = mposY - autobind.capperpos[2]
			end
		end
		if selectedbox[3] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[3] = false
			else
				autobind.capperpos[1] = mposX - temp[3].x
				autobind.capperpos[2] = mposY - temp[3].y
			end
		end
	end

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
end).HideCursor = true

imgui.OnFrame(function() return isIniLoaded and menu[0] and not isGamePaused end,
function()
	if menu[0] then
		if mposX >= autobind.menupos[1] and 
		   mposX <= autobind.menupos[1] + menusize[1] - 20 and 
		   mposY >= autobind.menupos[2] and 
		   mposY <= autobind.menupos[2] + 20 then
			if imgui.IsMouseClicked(0) and not inuse_move then
				inuse_move = true 
				selectedbox[4] = true
				temp[4].x = mposX - autobind.menupos[1]
				temp[4].y = mposY - autobind.menupos[2]
			end
		end
		if selectedbox[4] then
			if imgui.IsMouseReleased(0) then
				inuse_move = false 
				selectedbox[4] = false
			else
				autobind.menupos[1] = mposX - temp[4].x
				autobind.menupos[2] = mposY - temp[4].y
			end
		end
	end 
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1], autobind.menupos[2]))
	imgui.SetNextWindowSize(imgui.ImVec2(menusize[1], menusize[2]))
	imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.Begin(fa.SHIELD_PLUS..script.this.name.." Settings - Version: " .. script_version_text, menu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
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
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Toggles Notifications')
					imgui.PopStyleVar()
				end
			
				imgui.SetCursorPos(imgui.ImVec2(5, 81))
				
				if imgui.CustomButton(
					fa.FLOPPY_DISK,
					imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1), 
					imgui.ImVec2(75, 75)) then
					autobind_saveIni()
				end
				if imgui.IsItemHovered() then
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Save the Script')
					imgui.PopStyleVar()
				end
		  
				imgui.SetCursorPos(imgui.ImVec2(5, 157))

				if imgui.CustomButton(
					fa.REPEAT, 
					imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1), 
					imgui.ImVec2(75, 75)) then
					autobind_loadIni()
				end
				if imgui.IsItemHovered() then
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Reload the Script')
					imgui.PopStyleVar()
				end

				imgui.SetCursorPos(imgui.ImVec2(5, 233))

				if imgui.CustomButton(
					fa.ERASER, 
					imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1), 
					imgui.ImVec2(75, 75)) then
					autobind_blankIni()
				end
				if imgui.IsItemHovered() then
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Reset the Script to default settings')
					imgui.PopStyleVar()
				end

				imgui.SetCursorPos(imgui.ImVec2(5, 309))

				if imgui.CustomButton(
					fa.RETWEET .. ' Update',
					imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1),  
					imgui.ImVec2(75, 75)) then
					update_script(true)
				end
				if imgui.IsItemHovered() then
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Update the script')
					imgui.PopStyleVar()
				end
		  
			imgui.EndChild()
			
			imgui.SetCursorPos(imgui.ImVec2(75, 20))

			imgui.BeginChild("##2", imgui.ImVec2(500, 88), true)
		  
				imgui.SetCursorPos(imgui.ImVec2(5,5))
				if imgui.CustomButton(fa.GEAR .. '  Settings',
					_menu == 1 and imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.8) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1), 
					imgui.ImVec2(165, 75)) then
					_menu = 1
				end

				imgui.SetCursorPos(imgui.ImVec2(170, 5))
				  
				if imgui.CustomButton(fa.PERSON_BOOTH .. '  Skins',
					_menu == 2 and imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.8) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1), 
					imgui.ImVec2(165, 75)) then
				  
					_menu = 2
				end
				
				imgui.SetCursorPos(imgui.ImVec2(335, 5))
				
				if imgui.CustomButton(fa.PERSON_BOOTH .. '  Names',
					_menu == 3 and imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.8) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 0.5), 
					imgui.ImVec4(mainc.x, mainc.y, mainc.z, 1), 
					imgui.ImVec2(165, 75)) then
				  
					_menu = 3
				end
			imgui.EndChild()

			imgui.SetCursorPos(imgui.ImVec2(85, 102))
			
			imgui.BeginChild("##3", imgui.ImVec2(500, 290), true)
				if _menu == 1 then
					imgui.SetCursorPos(imgui.ImVec2(5, 2))
				
					imgui.BeginChild("##config", imgui.ImVec2(330, 275), false)
					
						imgui.Text('AutoBind:')
						if imgui.Checkbox('Cap Spam (Turfs)', new.bool(captog)) then 
							captog = not captog 
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Spams /capturf every 1.5 seconds')
							imgui.PopStyleVar()
						end
						
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						if imgui.Checkbox('Capturf (Turfs)', new.bool(autobind.capturf)) then 
							autobind.capturf = not autobind.capturf
							if autobind.capturf then
								autobind.capture = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Types /capturf when the message appears')
							imgui.PopStyleVar()
						end
						if imgui.Checkbox('Disable after capping', new.bool(autobind.disableaftercapping)) then 
							autobind.disableaftercapping = not autobind.disableaftercapping 
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Disables /capture and /capturf at the end of the them')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						
						if imgui.Checkbox('Capture (Points)', new.bool(autobind.capture)) then 
							autobind.capture = not autobind.capture 
							if autobind.capture then
								autobind.capturf = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Types /capture when the message appears')
							imgui.PopStyleVar()
						end
						if imgui.Checkbox('Auto Accept Repair', new.bool(autobind.autoacceptrepair)) then 
							autobind.autoacceptrepair = not autobind.autoacceptrepair 
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Auto accepts repair at 1 dollar')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						if imgui.Checkbox('Auto Accept Sex', new.bool(autobind.autoacceptsex)) then 
							autobind.autoacceptsex = not autobind.autoacceptsex 
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Auto accepts sex at any value')
							imgui.PopStyleVar()
						end
						
						if imgui.Checkbox('Auto Accept Vest', new.bool(autoaccepter)) then 
							autoaccepter = not autoaccepter 
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Auto accepts vest')
							imgui.PopStyleVar()
						end
						
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						if imgui.Checkbox('Auto Badge', new.bool(autobind.badge)) then 
							autobind.badge = not autobind.badge 
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Automatically enables /badge when going to the hopsital.')
							imgui.PopStyleVar()
						end
						if imgui.Checkbox("Auto FAid", new.bool(autobind.faid)) then
							autobind.faid = not autobind.faid
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Automatically enables firstaid kit')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						imgui.PushItemWidth(40) 
						local faidnumber = new.int(autobind.faidnumber)
						if imgui.DragInt('Faid Number', faidnumber, 1, 15, 99) then 
							autobind.faidnumber = faidnumber[0] 
						end
						imgui.PopItemWidth()
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Specifies ammount of HP to use faid')
							imgui.PopStyleVar()
						end
						
						if imgui.Checkbox("Renew FAid", new.bool(autobind.renewfaid)) then
							autobind.renewfaid = not autobind.renewfaid
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Auto renews after wearing off')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						imgui.PushItemWidth(40)
						if imgui.Checkbox("FAid Only AV", new.bool(not autobind.faidautovestonly)) then
							autobind.faidautovestonly = not autobind.faidautovestonly
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('If enabled auto firstaid only works if autovester is enabled')
							imgui.PopStyleVar()
						end
						
						imgui.PushItemWidth(120)
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						if imgui.BeginCombo("##Message Spam", "Message Spam") then
							if imgui.Checkbox("Wear off", new.bool(autobind.messages.noeffect)) then
								autobind.messages.noeffect = not autobind.messages.noeffect
							end
							if imgui.Checkbox("No Firstaid", new.bool(autobind.messages.nofaid)) then
								autobind.messages.nofaid = not autobind.messages.nofaid
							end
							imgui.EndCombo()
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Disables messages sent by the server')
							imgui.PopStyleVar()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
					
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
							
							if autobind.ddmode then
								_you_are_not_bodyguard = true
							end
						end
						
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('If you are Diamond Donator toggle this on.')
							imgui.PopStyleVar()
						end
						
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						
						if imgui.Checkbox("Timer fix", new.bool(autobind.timercorrection)) then
							autobind.timercorrection = not autobind.timercorrection
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Corrects the timer, if a vest is missed')
							imgui.PopStyleVar()
						end
						
						if imgui.Checkbox("Show Preoffered",  new.bool(autobind.showpreoffered)) then
							autobind.showpreoffered = not autobind.showpreoffered
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))	
								imgui.SetTooltip('If disabled it will erase the offered value to "Nobody", at the end of the timer')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						if imgui.Checkbox("Show Prevest",  new.bool(autobind.showprevest)) then
							autobind.showprevest = not autobind.showprevest
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))	
								imgui.SetTooltip('If vest is below 49 it will disable prevest show')
							imgui.PopStyleVar()
						end
						if imgui.Checkbox("Enabled by default", new.bool(autobind.enablebydefault)) then
							autobind.enablebydefault = not autobind.enablebydefault
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Enables autovester by default if enabled')
							imgui.PopStyleVar()
						end
						
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						if imgui.Checkbox("Compare Both", new.bool(autobind.factionboth)) then
							autobind.factionboth = not autobind.factionboth
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))	
								imgui.SetTooltip('Compare faction (ticked color and skin) or (unticked color or skin)')
							imgui.PopStyleVar()
						end
						
						if imgui.Checkbox("Always Offered",  new.bool(autobind.notification[1])) then
							autobind.notification[1] = not autobind.notification[1]
							if autobind.notification[1] then
								autobind.notification_hide[1] = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))	
								imgui.SetTooltip('Always Display Offered')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						if imgui.Checkbox("Hide Offered",  new.bool(autobind.notification_hide[1])) then
							autobind.notification_hide[1] = not autobind.notification_hide[1]
							if autobind.notification_hide[1] then
								autobind.notification[1] = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))	
								imgui.SetTooltip('Always Hide Offered')
							imgui.PopStyleVar()
						end

						if imgui.Checkbox("Always Offer",  new.bool(autobind.notification[2])) then
							autobind.notification[2] = not autobind.notification[2]
							if autobind.notification[2] then
								autobind.notification_hide[2] = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Always Display Offer')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						if imgui.Checkbox("Hide Offer",  new.bool(autobind.notification_hide[2])) then
							autobind.notification_hide[2] = not autobind.notification_hide[2]
							if autobind.notification_hide[2] then
								autobind.notification[2] = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Always Hide Offer')
							imgui.PopStyleVar()
						end
						
						if imgui.Checkbox("Progress Bar", new.bool(autobind.progressbar.toggle)) then
							autobind.progressbar.toggle = not autobind.progressbar.toggle
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Toggles progress bar from the menu')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						if imgui.Checkbox("Timer Text", new.bool(autobind.timertext)) then
							autobind.timertext = not autobind.timertext
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Toggles timer text from the menu')
							imgui.PopStyleVar()
						end
						
						imgui.PushItemWidth(120)
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						if imgui.BeginCombo("##Message Spam2", "Message Spam##2") then
							if imgui.Checkbox("Offered Vest", new.bool(autobind.messages.offered)) then
								autobind.messages.offered = not autobind.messages.offered
							end
							if imgui.Checkbox("Offer Vest", new.bool(autobind.messages.bodyguard)) then
								autobind.messages.bodyguard = not autobind.messages.bodyguard
							end
							if imgui.Checkbox("Accepted Your Vest", new.bool(autobind.messages.acceptedyour)) then
								autobind.messages.acceptedyour = not autobind.messages.acceptedyour
							end
							if imgui.Checkbox("Accepted There Vest", new.bool(autobind.messages.accepted)) then
								autobind.messages.accepted = not autobind.messages.accepted
							end
							
							if imgui.Checkbox("You Must Wait", new.bool(autobind.messages.youmustwait)) then
								autobind.messages.youmustwait = not autobind.messages.youmustwait
							end
							if imgui.Checkbox("Aiming", new.bool(autobind.messages.aiming)) then
								autobind.messages.aiming = not autobind.messages.aiming
							end
							if imgui.Checkbox("Player Not Near", new.bool(autobind.messages.playnotnear)) then
								autobind.messages.playnotnear = not autobind.messages.playnotnear
							end
							imgui.EndCombo()
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Disables messages sent by the server')
							imgui.PopStyleVar()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
				
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						imgui.PushItemWidth(120)
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						if imgui.BeginCombo("##ColorsProgressBar", "Progressbar") then
							local color2 = new.float[4](autobind.progressbar.color[1], autobind.progressbar.color[2], autobind.progressbar.color[3], autobind.progressbar.color[4])
							if imgui.ColorEdit4('##Color', color2, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then 
								autobind.progressbar.color[1] = color2[0]
								autobind.progressbar.color[2] = color2[1]
								autobind.progressbar.color[3] = color2[2]
								autobind.progressbar.color[4] = color2[3]
							end
							imgui.SameLine()
							imgui.Text("Color")
							local color1 = new.float[4](autobind.progressbar.colorfade[1], autobind.progressbar.colorfade[2], autobind.progressbar.colorfade[3], autobind.progressbar.colorfade[4])
							if imgui.ColorEdit4('##Fade Color', color1, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then 
								autobind.progressbar.colorfade[1] = color1[0]
								autobind.progressbar.colorfade[2] = color1[1]
								autobind.progressbar.colorfade[3] = color1[2]
								autobind.progressbar.colorfade[4] = color1[3]
							end
							imgui.SameLine()
							imgui.Text("Fade Color")
							imgui.EndCombo()
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Progress Bar Colors')
							imgui.PopStyleVar()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
						
						imgui.PushItemWidth(120)
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						if imgui.BeginCombo("##Offered Sound", "Offered Sound") then
							sound_dropdownmenu(1)
							imgui.EndCombo()
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Plays a sound if you offered a vest to someone')
							imgui.PopStyleVar()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						imgui.PushItemWidth(120)
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						if imgui.BeginCombo("##Offer Sound", "Offered Sound") then
							sound_dropdownmenu(2)
							imgui.EndCombo()
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Plays a sound if you get a offer from someone')
							imgui.PopStyleVar()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
						
						imgui.Text('Point/Turf Menu:')
						if imgui.Checkbox("Always Point/Turf",  new.bool(autobind.notification_capper)) then
							autobind.notification_capper = not autobind.notification_capper
							if autobind.notification_capper then
								autobind.notification_capper_hide = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Always Display Turf/Point')
							imgui.PopStyleVar()
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
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Always Hide Turf/Point')
							imgui.PopStyleVar()
						end
						
						imgui.Text('Frisk:')
						if imgui.Checkbox("Player Target", new.bool(autobind.Frisk[1])) then
							autobind.Frisk[1] = not autobind.Frisk[1]
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Checks if you are targeting a player')
							imgui.PopStyleVar()
						end
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						if imgui.Checkbox("Player Aim", new.bool(autobind.Frisk[2])) then
							autobind.Frisk[2] = not autobind.Frisk[2]
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Checks if you are only aiming')
							imgui.PopStyleVar()
						end
						
						imgui.PushItemWidth(120)
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						if imgui.BeginCombo("##Sniper Sound", "Sniper Sound") then
							sound_dropdownmenu(3)
							imgui.EndCombo()
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Plays a sound the player has a sniper rifle')
							imgui.PopStyleVar()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
						
						imgui.Text('Streamed Players:')
						
						local choices = {'Left', 'Center', 'Right'}
						imgui.PushItemWidth(120)
						if imgui.BeginCombo("##align", choices[autobind.streamedplayers.alignfont]) then
							for i = 1, #choices do
								if imgui.Selectable(choices[i]..'##'..i, autobind.streamedplayers.alignfont == i) then
									autobind.streamedplayers.alignfont = i
								end
							end
							imgui.EndCombo()
						end
						imgui.PopItemWidth()
						
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						local choices2 = {'Bold', 'Italics', 'Border', 'Shadow'}
						imgui.PushItemWidth(120)
						if imgui.BeginCombo("##flags", 'Flags') then
							for i = 1, #choices2 do
								if imgui.Checkbox(choices2[i], new.bool(autobind.streamedplayers.fontflag[i])) then
									autobind.streamedplayers.fontflag[i] = not autobind.streamedplayers.fontflag[i] 
									createfont() 
								end
							end
							imgui.EndCombo()
						end
						imgui.PopItemWidth()
						
						imgui.PushItemWidth(120) 
						local text = new.char[30](autobind.streamedplayers.font)
						if imgui.InputText('##font', text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
							autobind.streamedplayers.font = u8:decode(str(text))
							createfont() 
						end
						imgui.PopItemWidth()
						
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						imgui.BeginGroup()
							if imgui.Button('+##1') and autobind.streamedplayers.fontsize < 72 then 
								autobind.streamedplayers.fontsize = autobind.streamedplayers.fontsize + 1 
								createfont()
							end
							
							imgui.SameLine()
							imgui.Text(tostring(autobind.streamedplayers.fontsize))
							imgui.SameLine()
							
							if imgui.Button('-##1') and autobind.streamedplayers.fontsize > 4 then 
								autobind.streamedplayers.fontsize = autobind.streamedplayers.fontsize - 1 
								createfont()
							end
							imgui.SameLine()
							imgui.Text('FontSize')
						imgui.EndGroup()
						
						
						imgui.PushItemWidth(95) 
						tcolor = new.float[4](hex2rgba(autobind.streamedplayers.color))
						if imgui.ColorEdit4('##color', tcolor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then 
							autobind.streamedplayers.color = join_argb(tcolor[3] * 255, tcolor[0] * 255, tcolor[1] * 255, tcolor[2] * 255) 
						end 
						imgui.PopItemWidth()
						imgui.SameLine()
						imgui.Text('Color')
						imgui.SameLine()
						imgui.SetCursorPosX(imgui.GetWindowWidth() / 1.8)
						
						if imgui.Checkbox("Toggle",  new.bool(autobind.streamedplayers.toggle)) then
							autobind.streamedplayers.toggle = not autobind.streamedplayers.toggle
							if autobind.streamedplayers.toggle then
								autobind.notification_capper_hide = false
							end
						end
						if imgui.IsItemHovered() then
							imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
								imgui.SetTooltip('Toggles streamed players')
							imgui.PopStyleVar()
						end
						
						imgui.Text('Commands:')
						imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(4, 4))
						imgui.PushItemWidth(120)
						if imgui.BeginCombo("##cmds", 'Commands') then
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
							
							imgui.Text("Changing this will require the script to restart")
							imgui.Spacing()
							imgui.SetCursorPosX(imgui.GetWindowWidth() / 5.7)
							if imgui.Button(fa.ARROWS_REPEAT .. " Save and restart the script") then
								autobind_saveIni()
								thisScript():reload()
							end
							imgui.EndCombo()
						end
						imgui.PopItemWidth()
						imgui.PopStyleVar()
						
					imgui.EndChild()

					imgui.SetCursorPos(imgui.ImVec2(340, 5))

					imgui.BeginChild("##keybinds", imgui.ImVec2(151, 270), true)
						dualswitch("Accept Bodyguard:", "Accept", true)
						keychange('Accept')
						
						dualswitch("Offer Bodyguard:", "Offer", true)
						keychange('Offer')
						
						dualswitch("Black Market:", "BlackMarket", true)
						keychange('BlackMarket')
						
						dualswitch("Faction Locker:", "FactionLocker", true)
						keychange('FactionLocker')
						
						dualswitch("Gang Locker:", "GangLocker", true)
						keychange('GangLocker')
						
						dualswitch("BikeBind:", "BikeBind", true)
						keychange('BikeBind')
						
						dualswitch("Sprintbind:", "SprintBind", true)
						imgui.PushItemWidth(40) 
						delay = new.int(autobind.SprintBind.delay)
						if imgui.DragInt('Speed', delay, 0.5, 0, 200) then 
							autobind.SprintBind.delay = delay[0] 
						end
						imgui.PopItemWidth()
						keychange('SprintBind')
						
						dualswitch("Frisk:", "Frisk", true)
						keychange('Frisk')
						
						dualswitch("TakePills:", "TakePills", true)
						keychange('TakePills')
						
						dualswitch("FAid:", "FAid", true)
						keychange('FAid')
						
						dualswitch("Accept Death:", "AcceptDeath", true)
						keychange('AcceptDeath')
					imgui.EndChild()
				end
				
				if _menu == 2 then
					if autobind.customskins then
						if imgui.Checkbox("Custom Skins", new.bool(autobind.customskins)) then
							autobind.customskins = not autobind.customskins
						end
						imgui.SameLine()
						if imgui.Button(u8"Add Skin") then
							autobind.skins2[#autobind.skins2 + 1] = 0
						end
						for k, v in ipairs(autobind.skins2) do
							local skinid = new.int[1](v)
							if imgui.InputInt('##skinid'..k, skinid, 1, 1) then
								if skinid[0] <= 311 and skinid[0] >= 0 then
									autobind.skins2[k] = skinid[0]
								end
							end 
							imgui.SameLine()
							if imgui.Button(u8"Pick Skin##"..k) then
								skinmenu[0] = not skinmenu[0]
								selected = k
							end
							imgui.SameLine()
							if imgui.Button(u8"x##"..k) then
								table.remove(autobind.skins2, k)
							end
						end
					else
						if imgui.Checkbox("Custom Skins", new.bool(autobind.customskins)) then
							autobind.customskins = not autobind.customskins
						end
						imgui.SameLine()
						if imgui.Checkbox("Custom Gang Skins", new.bool(autobind.gangcustomskins)) then
							autobind.gangcustomskins = not autobind.gangcustomskins
							if not autobind.gangcustomskins and not updateskin then
								loadskinidsurl()
							end
						end
						imgui.SameLine()
						if imgui.Button(u8"Add Gang Skin") then
							autobind.skins[#autobind.skins + 1] = 0
						end
						imgui.SameLine()
						if imgui.Button("Update Gang Skins URL") and not updateskin then
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
			imgui.SetCursorPos(imgui.ImVec2(90, 384))
			
			imgui.BeginChild("##5", imgui.ImVec2(500, 36), true)
				
				if imgui.Checkbox('Autosave', new.bool(autobind.autosave)) then 
					autobind.autosave = not autobind.autosave 
					autobind_saveIni() 
				end
				if imgui.IsItemHovered() then
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Autosave')
					imgui.PopStyleVar()
				end
				imgui.SameLine()
				if imgui.Checkbox('Auto-Update', new.bool(autobind.autoupdate)) then 
					autobind.autoupdate = not autobind.autoupdate 
				end
				if imgui.IsItemHovered() then
					imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
						imgui.SetTooltip('Auto-Update')
					imgui.PopStyleVar()
				end
				
				imgui.SameLine()
				
				if imgui.Button(vestmodename(autobind.vestmode)) then
					if autobind.vestmode == 4 then
						autobind.vestmode = 0
					else
						autobind.vestmode = autobind.vestmode + 1
					end
				end
				imgui.SameLine()
				
				if imgui.Button(autobind.point_turf_mode and 'Point' or 'Turf') then
					autobind.point_turf_mode = not autobind.point_turf_mode
				end
				
				imgui.SameLine()
				imgui.PushItemWidth(75)
				imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
				if imgui.BeginCombo("##1", "Lockers") then
					if imgui.Button(fa.CART_SHOPPING .. " BM Settings") then
						bmmenu[0] = not bmmenu[0]
					end
						
					if imgui.Button(fa.CART_SHOPPING .. " Faction Locker") then
						factionlockermenu[0] = not factionlockermenu[0]
					end
					
					if imgui.Button(fa.CART_SHOPPING .. " Gang Locker") then
						ganglockermenu[0] = not ganglockermenu[0]
					end
					imgui.EndCombo()
				end
				imgui.PopItemWidth()
				imgui.PopStyleVar()
				
				imgui.SameLine()
				if imgui.Button("ImGUI Settings") then
					imguisettings[0] = not imguisettings[0]
				end
			imgui.EndChild()
		imgui.End()
	imgui.PopStyleVar(1)
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
	if not menu[0] then
		skinmenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] + (menusize[1] / 13), autobind.menupos[2]))
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
				if autobind.customskins then
					autobind.skins2[selected] = i
				else
					autobind.skins[selected] = i
				end
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
	if not menu[0] then
		bmmenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] - 164, autobind.menupos[2]))
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
	if not menu[0] then
		factionlockermenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] + 579, autobind.menupos[2]))
    imgui.Begin("Faction Locker", factionlockermenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize) 
		imgui.Text('Locker Equipment:')
		if imgui.Checkbox('Deagle', new.bool(autobind.FactionLocker[1])) then 
			autobind.FactionLocker[1] = not autobind.FactionLocker[1] 
		end
		if imgui.Checkbox('Shotgun', new.bool(autobind.FactionLocker[2])) then 
			autobind.FactionLocker[2] = not autobind.FactionLocker[2] 
			if autobind.FactionLocker[2] then
				autobind.FactionLocker[3] = false
			end
		end 
		if imgui.Checkbox('SPAS-12', new.bool(autobind.FactionLocker[3])) then 
			autobind.FactionLocker[3] = not autobind.FactionLocker[3] 
			if autobind.FactionLocker[3] then
				autobind.FactionLocker[2] = false
			end
		end 
		if imgui.Checkbox('MP5', new.bool(autobind.FactionLocker[4])) then 
			autobind.FactionLocker[4] = not autobind.FactionLocker[4] 
		end 
		if imgui.Checkbox('M4', new.bool(autobind.FactionLocker[5])) then 
			autobind.FactionLocker[5] = not autobind.FactionLocker[5] 
			if autobind.FactionLocker[5] then
				autobind.FactionLocker[6] = false
			end
		end
		if imgui.Checkbox('AK-47', new.bool(autobind.FactionLocker[6])) then 
			autobind.FactionLocker[6] = not autobind.FactionLocker[6] 
			if autobind.FactionLocker[6] then
				autobind.FactionLocker[5] = false
			end
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

imgui.OnFrame(function() return isIniLoaded and ganglockermenu[0] and not isGamePaused end,
function()
	if not menu[0] then
		ganglockermenu[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] + 579, autobind.menupos[2]))
    imgui.Begin("Gang Locker", ganglockermenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize) 
		imgui.Text('Gang Equipment:')
		if imgui.Checkbox('Shotgun', new.bool(autobind.GangLocker[1])) then 
			autobind.GangLocker[1] = not autobind.GangLocker[1] 
		end
		if imgui.Checkbox('MP5', new.bool(autobind.GangLocker[2])) then 
			autobind.GangLocker[2] = not autobind.GangLocker[2] 
		end 
		if imgui.Checkbox('Deagle', new.bool(autobind.GangLocker[3])) then 
			autobind.GangLocker[3] = not autobind.GangLocker[3] 
		end 
		if imgui.Checkbox('AK-47', new.bool(autobind.GangLocker[4])) then 
			autobind.GangLocker[4] = not autobind.GangLocker[4] 
		end 
		if imgui.Checkbox('M4', new.bool(autobind.GangLocker[5])) then 
			autobind.GangLocker[5] = not autobind.GangLocker[5] 
		end
		if imgui.Checkbox('Spas-12', new.bool(autobind.GangLocker[6])) then 
			autobind.GangLocker[6] = not autobind.GangLocker[6] 
		end
		if imgui.Checkbox('Sniper', new.bool(autobind.GangLocker[7])) then 
			autobind.GangLocker[7] = not autobind.GangLocker[7] 
		end
	imgui.End()
end)

imgui.OnFrame(function() return isIniLoaded and imguisettings[0] and not isGamePaused end,
function()
	if not menu[0] then
		imguisettings[0] = false
	end
	imgui.SetNextWindowPos(imgui.ImVec2(autobind.menupos[1] + (menusize[1] / 5), autobind.menupos[2]))
    imgui.Begin(fa.GEAR.." ImGUI Settings", imguisettings, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize) 
		imgui.SetWindowFocus()
		local color = new.float[3](autobind.imcolor[1], autobind.imcolor[2], autobind.imcolor[3])
		if imgui.ColorEdit3('##Menu Color', color, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then 
			autobind.imcolor[1] = color[0]
			autobind.imcolor[2] = color[1]
			autobind.imcolor[3] = color[2]
		end
		imgui.SameLine()
		imgui.Text("Menu Color")
		
		imgui.SameLine()
		imgui.PushItemWidth(95)
		if imgui.BeginCombo("fAwesome 6 Icons##1", autobind.fa6) then
			for k, v in pairs(fa6fontlist) do
				if imgui.Selectable(v, v == autobind.fa6) then
					autobind.fa6 = v
				end
			end
			imgui.EndCombo()
		end
		imgui.PopItemWidth()
		
		imgui.BeginChild("##saveandreset", imgui.ImVec2(330, 45), false)
			imgui.Text("Changing this will require the script to restart")
			imgui.Spacing()	
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 5.7)
			if imgui.Button(fa.ARROWS_REPEAT .. " Save and restart the script") then
				autobind_saveIni()
				thisScript():reload()
			end
		imgui.EndChild()
	imgui.End()
end)

function onD3DPresent()	
	if not isPauseMenuActive() and not sampIsScoreboardOpen() and sampGetChatDisplayMode() > 0 and not isKeyDown(VK_F10) and autobind.streamedplayers.toggle and _enabled then
		if fid and streamedplayers then
			renderfont(
				autobind.streamedplayers.pos[1], 
				autobind.streamedplayers.pos[2], 
				fid, 
				streamedplayers, 
				autobind.streamedplayers.alignfont, 
				autobind.streamedplayers.color
			)
		end
	end
end

function renderfont(x, y, fontid, value, align, color)
	renderFontDrawText(fontid, value, x - aligntext(fontid, value, align), y, color)
end

function main()
	if not doesDirectoryExist(path) then createDirectory(path) end
	if not doesDirectoryExist(resourcepath) then createDirectory(resourcepath) end
	if not doesDirectoryExist(skinspath) then createDirectory(skinspath) end
	if not doesDirectoryExist(audiopath) then createDirectory(audiopath) end
	if not doesDirectoryExist(audiofolder) then createDirectory(audiofolder) end
	if doesFileExist(autobind_cfg) then autobind_loadIni() else autobind_blankIni() end
	if doesFileExist(autobind_cfg) then help_loadIni() else help_blankIni() end
	while not isSampAvailable() do wait(100) end
	
	if autobind.autoupdate then
		wait(5000)
		update_script(false)
	end
	
	createfont()
	skins_script()
	sounds_script()
	
	paths = scanGameFolder(audiofolder, paths)
	
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
	
	autobind.timer = autobind.ddmode and 7 or 12
	
	register_help_commands()

	if not autobind.enablebydefault then
		_enabled = false
		_autovest = false
	end
	
	if not autobind.gangcustomskins then
		wait(5000)
		loadskinidsurl()
	end

	sampRegisterChatCommand(autobind.autovestsettingscmd, function() 
		_menu = 1
		menu[0] = not menu[0]
	end)

	sampRegisterChatCommand(autobind.vestnearcmd, function() 
		if _enabled and _autovest then
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
		_autovest = not _autovest
		sampAddChatMessage(string.format("[Autobind]{ffff00} Automatic vest %s.", _autovest and 'enabled' or 'disabled'), 1999280)
	end)
	
	sampRegisterChatCommand(autobind.autoacceptercmd, function() 
		if _enabled then
			autoaccepter = not autoaccepter
			sampAddChatMessage(string.format("[Autobind]{ffff00} Autoaccepter is now %s.", autoaccepter and 'enabled' or 'disabled'), 1999280)
		end
	end)
	
	sampRegisterChatCommand(autobind.ddmodecmd, function() 
		if _enabled then
			autobind.ddmode = not autobind.ddmode
			sampAddChatMessage(string.format("[Autobind]{ffff00} ddmode is now %s.", autobind.ddmode and 'enabled' or 'disabled'), 1999280)
			
			autobind.timer = autobind.ddmode and 7 or 12
			
			if autobind.ddmode then
				_you_are_not_bodyguard = true
			end
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
				if params:match('families') then
					autobind.vestmode = 0
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Families.", 1999280)
				elseif params:match('factions') then
					autobind.vestmode = 1
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Factions.", 1999280)
				elseif params:match('everyone') then
					autobind.vestmode = 2
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Everyone.", 1999280)
				elseif params:match('names') then
					autobind.vestmode = 3
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Names.", 1999280)
				elseif params:match('skins') then
					autobind.vestmode = 4
					sampAddChatMessage("[Autobind]{ffff00} vestmode is now set to Skins.", 1999280)
				else
					sampAddChatMessage("[Autobind]{ffff00} vestmode is currently set to "..vestmodename(autobind.vestmode)..".", 1999280)
					sampAddChatMessage('USAGE: /'..autobind.vestmodecmd..' [families/factions/everyone/names/skins]', -1)
				end
			else
				sampAddChatMessage("[Autobind]{ffff00} vestmode is currently set to "..vestmodename(autobind.vestmode)..".", 1999280)
				sampAddChatMessage('USAGE: /'..autobind.vestmodecmd..' [families/factions/everyone/names/skins]', -1)
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
	
	lua_thread.create(function() 
		while true do wait(15)
			mposX, mposY = getCursorPos()
			fontmove()
			streamedplayers = "Streamed Players: " ..sampGetPlayerCount(true) - 1
		end
	end)
	
	lua_thread.create(function() 
		while true do wait(15)
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
	
	sampAddChatMessage("["..script.this.name..'] '.. "{FF1A74}(/autobind) Authors: " .. table.concat(thisScript().authors, ", ")..", Testers: ".. table.concat(script_tester, ", "), -1)
	
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
		if _enabled and _autovest and autobind.timer <= localClock() - _last_vest and not specstate and HideMe == 0 and aduty == 0 then
			if _you_are_not_bodyguard then
				autobind.timer = autobind.ddmode and 7 or 12
				for PlayerID = 0, sampGetMaxPlayerId(false) do
					local result, playerped = sampGetCharHandleBySampPlayerId(PlayerID)
					if result and not sampIsPlayerPaused(PlayerID) and sampGetPlayerArmor(PlayerID) < 49 then
						local myX, myY, myZ = getCharCoordinates(ped)
						local playerX, playerY, playerZ = getCharCoordinates(playerped)
						local dist = getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ)
						if (autobind.ddmode and tostring(dist) or dist) < (autobind.ddmode and tostring(0.9) or 6) then
							local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
							local pAnimId2 = sampGetPlayerAnimationId(playerid)
							local aim, _ = getCharPlayerIsTargeting(h)
							if pAnimId ~= 1158 and pAnimId ~= 1159 and pAnimId ~= 1160 and pAnimId ~= 1161 and pAnimId ~= 1162 and pAnimId ~= 1163 and pAnimId ~= 1164 and pAnimId ~= 1165 and pAnimId ~= 1166 and pAnimId ~= 1167 and pAnimId ~= 1069 and pAnimId ~= 1070 and pAnimId2 ~= 746 and not aim then
								if autobind.vestmode == 0 then
									if autobind.gangcustomskins then
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
								if autobind.vestmode == 4 then
									if autobind.customskins then
										if has_number(autobind.skins2, getCharModel(playerped)) then
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
				
		if _enabled and faid_timer <= localClock() - _last_timer_faid then
			if autoaccepter or autobind.faidautovestonly then
				if getCharHealth(ped) - 5000000 < autobind.faidnumber and autobind.faid and not faidtoggle then
					sampSendChat("/faid")
					_last_timer_faid = localClock()
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

function listenToKeybinds()
	if _enabled and not menu[0] and not inuse_key then
		if autobind.Keybinds.Accept.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.Accept.Dual then 
				key, key2 = autobind.Keybinds.Accept.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.Accept.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.Accept.Keybind}, t = {'KeyPressed'}})) then
				sampSendChat("/accept bodyguard")
				wait(1000)
			end
		end
		if autobind.Keybinds.Offer.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.Offer.Dual then 
				key, key2 = autobind.Keybinds.Offer.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.Offer.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.Offer.Keybind}, t = {'KeyPressed'}})) then
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
		if autobind.Keybinds.BlackMarket.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.BlackMarket.Dual then 
				key, key2 = autobind.Keybinds.BlackMarket.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.BlackMarket.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.BlackMarket.Keybind}, t = {'KeyPressed'}})) then
				if not bmbool then
					bmbool = true
					sendBMCmd()
				end 					
			end
		end
		if autobind.Keybinds.FactionLocker.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.FactionLocker.Dual then 
				key, key2 = autobind.Keybinds.FactionLocker.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.FactionLocker.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.FactionLocker.Keybind}, t = {'KeyPressed'}})) then
				if not lockerbool and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
					lockerbool = true
					sendLockerCmd()
				end
			end
		end
		
		local key, key2 = nil
		if autobind.Keybinds.BikeBind.Dual then 
			key, key2 = autobind.Keybinds.BikeBind.Keybind:match("(.+),(.+)") 
		end
		if (key and key2 and autobind.Keybinds.BikeBind.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyDown'}}) or keycheck({k  = {autobind.Keybinds.BikeBind.Keybind}, t = {'KeyDown'}})) then
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
			
		local key, key2 = nil
		if autobind.Keybinds.SprintBind.Dual then 
			key, key2 = autobind.Keybinds.SprintBind.Keybind:match("(.+),(.+)") 
		end
		if (key and key2 and autobind.Keybinds.SprintBind.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.SprintBind.Keybind}, t = {'KeyPressed'}})) then
			autobind.Keybinds.SprintBind.Toggle = not autobind.Keybinds.SprintBind.Toggle 
			sampAddChatMessage('[Autobind]{ffff00} Sprintbind: '..(autobind.Keybinds.SprintBind.Toggle and '{008000}on' or '{FF0000}off'), -1) 
		end
		
		if autobind.Keybinds.Frisk.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.Frisk.Dual then 
				key, key2 = autobind.Keybinds.Frisk.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.Frisk.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.Frisk.Keybind}, t = {'KeyPressed'}})) then
				local _, playerped = storeClosestEntities(ped)
				local result, id = sampGetPlayerIdByCharHandle(playerped)
				local result2, target = getCharPlayerIsTargeting(h)
				if result then
					if result2 and autobind.Frisk[1] or not autobind.Frisk[1] then
						if target == playerped and autobind.Frisk[1] or not autobind.Frisk[1] then
							if isPlayerAiming(true, true) and autobind.Frisk[2] or not autobind.Frisk[2] then
								sampSendChat(string.format("/frisk %d", id))
								wait(1000)
							end
						end
					end
				end
			end
		end
				
		if autobind.Keybinds.TakePills.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.TakePills.Dual then 
				key, key2 = autobind.Keybinds.TakePills.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.TakePills.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.TakePills.Keybind}, t = {'KeyPressed'}})) then
				sampSendChat("/takepills")
				wait(1000)
			end
		end
				
		if autobind.Keybinds.AcceptDeath.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.AcceptDeath.Dual then 
				key, key2 = autobind.Keybinds.AcceptDeath.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.AcceptDeath.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.AcceptDeath.Keybind}, t = {'KeyPressed'}})) then
				sampSendChat("/accept death")
				wait(1000)
			end
		end
				
		if autobind.Keybinds.FAid.Toggle then
			local key, key2 = nil
			if autobind.Keybinds.FAid.Dual then 
				key, key2 = autobind.Keybinds.FAid.Keybind:match("(.+),(.+)") 
			end
			if (key and key2 and autobind.Keybinds.FAid.Dual and keycheck({k  = {key, key2}, t = {'KeyDown', 'KeyPressed'}}) or keycheck({k  = {autobind.Keybinds.FAid.Keybind}, t = {'KeyPressed'}})) then
				sampSendChat("/faid")
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

	playsound(1)

	_last_vest = localClock()
end

function onScriptTerminate(scr, quitGame) 
	if scr == script.this then 
		if autobind.autosave then 
			autobind_saveIni() 
		end 
	end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == wm.WM_KILLFOCUS then
		isGamePaused = true
	elseif msg == wm.WM_SETFOCUS then
		isGamePaused = false
	end

	if wparam == VK_ESCAPE and (menu[0] or skinmenu[0] or bmmenu[0] or factionlockermenu[0]) then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            menu[0] = false
			skinmenu[0] = false
			bmmenu[0] = false
			factionlockermenu[0] = false
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
	if _enabled then
		if text:match("You don't have a first aid kit!") and color == -1263159297 then
			lua_thread.create(function()
				wait(0)
				faidtoggle = true
			end)
			if autobind.messages.nofaid then
				return false
			end
		end
		
		if text:match("DIAMOND DONATOR: You have purchased a 10 first aid kits for $2,500.") and color == -1210979329 then
			lua_thread.create(function()
				wait(0)
				faidtoggle = false
			end)
		end
		
		if text:match("/firstaid /treatinjury") and color == 869072810 then
			lua_thread.create(function()
				wait(0)
				faidtoggle = false
			end)
		end

		if text:match("You already have a first aid kit on, use /firstaidoff to turn it off!") and color == -1263159297 then
			lua_thread.create(function()
				wait(0)
				faidtoggle = true
			end)
			if autobind.messages.faidon then
				return false
			end
		end
		
		if text:match("Your first aid kit no longer takes effect.") and color == -1263159297 then
			lua_thread.create(function()
				wait(0)
				faidtoggle = false
				if autobind.renewfaid and autobind.faid then
					sampSendChat("/faid")
				end
			end)
			if autobind.messages.noeffect  then
				return false
			end
		end

		if text:match("Weapon: Sniper Rifle.") then
			print("4 "..color)
			playsound(3)
		end
		
		if text:find("Your hospital bill") and color == -8224086 then
			if autobind.badge then
				sampSendChat("/badge")
			end
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
			print("5 "..color)
			if autobind.autoacceptsex then
				sampSendChat("/accept sex")
			end
		end
		
		if text:find("wants to repair your car for $1") then 
			print("6 "..color)
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
		   text:match("You can't do this right now.") or 
		   text:match("You can't use your lockers if you were recently shot.") and lockerbool then
			lockerbool = false
			lockerstate = 0
			lockercmd = 0
		end
		
		if text:match('You are not at your family gun locker.') or 
		   text:match('You have been muted automatically for spamming. Please wait 10 seconds and try again.') or 
		   text:match("You can't do this right now.") or 
		   text:match('You are muted from submitting commands right now.') and lockerbool then
			gangbool = false
			gangstate = 0
			gangcmd = 0
		end

		if text:match("Point Info:") and color == -5963606 then
			if pointspam then
				return false
			end
		end
		
		if text:match("No family has capped the point or the point is not ready to be capped.") and color == -1077886209 then
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
		
		
		if text:find("Turf Info:") and color == -5963606 then
			if turfspam then
				return false
			end
		end
		
		if text:find("Nobody is attempting to capture any turfs or no turfs are available for capture yet.") and color == -1077886209 then
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
			lua_thread.create(function()
				wait(0)
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
			end)
		end
		

		if text:find("That player isn't near you.") and color == -1347440726 then
			lua_thread.create(function()
				wait(0)
				if autobind.ddmode then
					_last_vest = localClock() - 6.8
				else
					_last_vest = localClock() - 11.8
				end
			end)
			
			if autobind.messages.playnotnear then
				return false
			end
		end

		if text:find("You can't /guard while aiming.") and color == -1347440726 then
			lua_thread.create(function()
				wait(0)
				if autobind.ddmode then
					_last_vest = localClock() - 6.8
				else
					_last_vest = localClock() - 11.8
				end
			end)
			
			if autobind.messages.aiming then
				return false
			end
		end

		if text:find("You must wait") and text:find("seconds before selling another vest.") and autobind.timercorrection then
			lua_thread.create(function()
				wait(0)
				cooldown = string.match (text, "%d+")
				autobind.timer = cooldown + 0.5
			end)
			
			if autobind.messages.youmustwait then
				return false
			end
		end

		if text:find("* You offered protection to ") and text:find(" for $200.") and color == 869072810 then
			if autobind.messages.offered then
				return false
			end
		end
		
		if text:find("You accepted the protection for $200 from") and color == 869072810 then
			lua_thread.create(function()
				wait(0)
				sampname2 = 'Nobody'
				playerid2 = -1
			
				if autobind.notification_hide[2] then
					hide[2] = false
				end
			end)
			
			if autobind.messages.accepted then
				return false
			end
		end
			
		if text:find("You are not a bodyguard.") and color ==  -1347440726 then
			lua_thread.create(function()
				wait(0)
				sampname = 'Nobody'
				playerid = -1
			
				_you_are_not_bodyguard = false
			
				if autobind.notification_hide[1] then
					hide[1] = false
				end
			end)
		end
		
		if text:find("accepted your protection, and the $200 was added to your money.") and color == 869072810 then
			lua_thread.create(function()
				wait(0)
				sampname = 'Nobody'
				playerid = -1
				
				if autobind.notification_hide[1] then
					hide[1] = false
				end
			end)
			
			if autobind.messages.acceptedyour then
				return false
			end
		end
		
		if text:match("* You are now a Bodyguard, type /help to see your new commands.") then
			lua_thread.create(function()
				wait(0)
				_you_are_not_bodyguard = true
			end)
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
				
				playsound(2)
				
				if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 and autoaccepter and not specstate then
					sampSendChat("/accept bodyguard")

					autoacceptertoggle = false
				end
			end)
			
			if autobind.messages.bodyguard then
				return false
			end
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
	if gangbool then
		if title:find('Family Gun Locker') then
			if gangstate == 0 then -- shotgun
				if hasCharGotWeapon(ped, 25) or not autobind.GangLocker[1] then
					gangstate = 1
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 0, nil)
				gangstate = 1
				sendGangCmd()
				return false
			end
			
			if gangstate == 1 then -- mp5
				if hasCharGotWeapon(ped, 29) or not autobind.GangLocker[2] then
					gangstate = 2
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 1, nil)
				gangstate = 2
				sendGangCmd()
				return false
			end
			if gangstate == 2 then -- deagle
				if hasCharGotWeapon(ped, 24) or not autobind.GangLocker[3] then
					gangstate = 3
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 2, nil)
				gangstate = 3
				sendGangCmd()
				return false
			end
			if gangstate == 3 then -- ak47
				if hasCharGotWeapon(ped, 30) or not autobind.GangLocker[4] then
					gangstate = 4
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 3, nil)
				gangstate = 4
				sendGangCmd()
				return false
			end
			if gangstate == 4 then -- m4
				if hasCharGotWeapon(ped, 31) or not autobind.GangLocker[5] then
					gangstate = 5
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 4, nil)
				gangstate = 5
				sendGangCmd()
				return false
			end
			if gangstate == 5 then -- spas12
				if hasCharGotWeapon(ped, 27) or not autobind.GangLocker[6] then
					gangstate = 6
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 5, nil)
				gangstate = 6
				sendGangCmd()
				return false
			end
			if gangstate == 6 then -- sniper
				if hasCharGotWeapon(ped, 34) or not autobind.GangLocker[7] then
					gangbool = false
					gangstate = 0
					gangcmd = 0
					sampev.onShowDialog(id, style, title, button1, button2, text)
					return false
				end
				sampSendDialogResponse(id, 1, 6, nil)
				gangbool = false
				gangstate = 0
				gangcmd = 0
				return false
			end
		end
	end
end

function sampev.onTogglePlayerSpectating(state)
    specstate = state
end

function dualswitch(title, key, checkbox)
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
	if imgui.Checkbox("Toggle Keybind##"..key, new.bool(autobind.Keybinds[key].Toggle)) and checkbox then
		autobind.Keybinds[key].Toggle = not autobind.Keybinds[key].Toggle
	end
end

function fontmove()
	if fid and mposX and mposY and streamedplayers and menu[0] then
		width_text, height_text = renderGetFontDrawTextLength(fid, streamedplayers), renderGetFontDrawHeight(fid)
		if mposX >= autobind.streamedplayers.pos[1] - aligntext(fid, streamedplayers, autobind.streamedplayers.alignfont) and 
		   mposX <= (autobind.streamedplayers.pos[1] - aligntext(fid, streamedplayers, autobind.streamedplayers.alignfont)) + width_text and 
		   mposY >= autobind.streamedplayers.pos[2] and 
		   mposY <= autobind.streamedplayers.pos[2] + height_text then
			if isKeyJustPressed(VK_LBUTTON) and not inuse then 
				inuse = true 
				selected2 = true 
				temp[5].x = mposX - autobind.streamedplayers.pos[1]
				temp[5].y = mposY - autobind.streamedplayers.pos[2]
			end
		end
		if selected2 then
			if wasKeyReleased(VK_LBUTTON) then
				inuse = false 
				selected2 = false
			else
				autobind.streamedplayers.pos[1] = mposX - temp[5].x
				autobind.streamedplayers.pos[2] = mposY - temp[5].y
			end
		end
	end
end

function createfont()
	flags, flagids = {}, {flag.BOLD,flag.ITALICS,flag.BORDER,flag.SHADOW}
	for i = 1, 4 do 
		flags[i] = autobind.streamedplayers.fontflag[i] and flagids[i] or 0 
	end 
	fid = renderCreateFont(autobind.streamedplayers.font, autobind.streamedplayers.fontsize, flags[1] + flags[2] + flags[3] + flags[4])
end

function aligntext(fid, value, align)
	local l = renderGetFontDrawTextLength(fid, value) 
	if align == 1 then 
		return l
	elseif align == 2 then 
		return l / 2 
	elseif align == 3 then 
		return 0 
	end
end

function playsound(id)
	if autobind.audio.toggle[id] then
		if doesFileExist(autobind.audio.paths[id]) then
			sounds = loadAudioStream(autobind.audio.paths[id])
			if sounds ~= nil then
				setAudioStreamVolume(sounds, autobind.audio.volumes[id])
				setAudioStreamState(sounds, 1)
			end
		else
			sampAddChatMessage(string.format("Error: Sound does not exist \"%s\"", autobind.audio.paths[id]), -1)
		end
	end
end

function loadskinidsurl()
	urlstring = https.request(autobind.skinsurl)
	if urlstring ~= nil then
		for skinid in string.match(urlstring, "<body>(.+)</body>").gmatch(urlstring, "%d*") do
			if string.len(skinid) > 0 then 
				table.insert(skins, skinid)
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

function sounds_script()
	local sounds = {"sound1.mp3", "sound2.mp3", "sound3.mp3", "sound4.mp3", "sound5.mp3", "sound6.mp3", "sound7.mp3", "sound8.mp3", "roblox.mp3", "mw2.mp3", "bingbong.mp3"}
	for k, v in pairs(sounds) do
		if not doesFileExist(audiofolder .. v) then
			downloadUrlToFile(sounds_url .. v, audiofolder .. v, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} %s Downloaded", script.this.name, v))
				end
			end)
		end
	end
end

function update_script(noupdatecheck)
	local update_text = https.request(update_url)
	if update_text ~= nil then
		update_version = update_text:match("version: (.+)")
		if update_version ~= nil then
			if tonumber(update_version) > script_version then
				sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} New version found! The update is in progress..", script.this.name), -1)
				downloadUrlToFile(script_url, script_path, function(id, status)
					if status == dlstatus.STATUS_ENDDOWNLOADDATA then
						sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update was successful!", script.this.name), -1)
						lua_thread.create(function() 
							menu[0] = false
							skinmenu[0] = false
							bmmenu[0] = false
							factionlockermenu[0] = false
							wait(500) 
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
end

function help_blankIni()
	help = {}
	help_repairmissing()
	help_saveIni()
	isIniLoaded = true
end

function help_loadIni()
	local f = io.open(help_cfg, "r")
	if f then
		help = decodeJson(f:read("*all"))
		f:close()
	end
	help_repairmissing()
	help_saveIni()
	isIniLoaded = true
end

function help_saveIni()
	if type(help) == "table" then
		local f = io.open(help_cfg, "w")
		f:close()
		if f then
			f = io.open(help_cfg, "r+")
			f:write(encodeJson(help))
			f:close()
		end
	end
end

function help_repairmissing()
	if help.autosave == nil then 
		help.autosave = true
	end
	local resX, resY = getScreenResolution()
	if help.menupos == nil then 
		help.menupos = {
			string.format("%d", resX / 2), 
			string.format("%d", resY / 2)
		}
		help.menupos = {
			tonumber(help.menupos[1]), 
			tonumber(help.menupos[2])
		}
	end
	if help.commands == nil then
		help.commands = {}
	end
end

function autobind_blankIni()
	autobind = {}
	autobind_repairmissing()
	autobind_saveIni()
	isIniLoaded = true
end

function autobind_loadIni()
	local f = io.open(autobind_cfg, "r")
	if f then
		autobind = decodeJson(f:read("*all"))
		f:close()
	end
	autobind_repairmissing()
	autobind_saveIni()
	isIniLoaded = true
end

function autobind_saveIni()
	if type(autobind) == "table" then
		local f = io.open(autobind_cfg, "w")
		f:close()
		if f then
			f = io.open(autobind_cfg, "r+")
			f:write(encodeJson(autobind))
			f:close()
		end
	end
end

function autobind_repairmissing()
	if autobind.autosave == nil then 
		autobind.autosave = true
	end
	if autobind.autoupdate == nil then 
		autobind.autoupdate = true
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
	if autobind.timercorrection == nil then 
		autobind.timercorrection = true
	end
	if autobind.customskins == nil then 
		autobind.customskins = false
	end
	if autobind.gangcustomskins == nil then 
		autobind.gangcustomskins = false
	end
	if autobind.gettarget == nil then
		autobind.gettarget = false
	end
	if autobind.notification == nil then
		autobind.notification = {}
	end
	if autobind.notification[1] == nil then 
		autobind.notification[1] = false
	end
	if autobind.notification[2] == nil then 
		autobind.notification[2] = false
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
		autobind.notification_capper = false
	end
	if autobind.notification_capper_hide == nil then 
		autobind.notification_capper_hide = false
	end
	if autobind.point_turf_mode == nil then 
		autobind.point_turf_mode = false
	end
	
	if autobind.badge == nil then
		autobind.badge = true
	end
	
	if autobind.faid == nil then
		autobind.faid = false
	end
	
	if autobind.faidnumber == nil then
		autobind.faidnumber = 49
	end
	
	if autobind.renewfaid == nil then
		autobind.renewfaid = false
	end
	
	if autobind.faidautovestonly == nil then
		autobind.faidautovestonly = false
	end
	
	if autobind.showpreoffered == nil then
		autobind.showpreoffered = true
	end
	
	if autobind.vestmode == nil then 
		autobind.vestmode = 0
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
		autobind.skinsurl = "https://thesoupkitchen.akacross.net/skins.html"
	end
	if autobind.skins == nil then
		autobind.skins = {}
	end
	if autobind.skins2 == nil then
		autobind.skins2 = {}
	end
	if autobind.customskins == nil then
		autobind.customskins = false
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
		autobind.capperpos = {10, 435}
	end
	
	local resX, resY = getScreenResolution()
	if autobind.menupos == nil then 
		autobind.menupos = {
			string.format("%d", (resX / 2) - menusize[1] / 2), 
			string.format("%d", (resY / 2) - menusize[2] / 2)
		}
		autobind.menupos = {
			tonumber(autobind.menupos[1]), 
			tonumber(autobind.menupos[2])
		}
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
	
	if autobind.Keybinds.GangLocker == nil then
		autobind.Keybinds.GangLocker = {}
	end
	if autobind.Keybinds.GangLocker.Toggle == nil then 
		autobind.Keybinds.GangLocker.Toggle = false
	end
	if autobind.Keybinds.GangLocker.Keybind == nil then 
		autobind.Keybinds.GangLocker.Keybind = tostring(VK_MENU)..','..tostring(VK_X)
	end
	if autobind.Keybinds.GangLocker.Dual == nil then 
		autobind.Keybinds.GangLocker.Dual = true
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
	
	if autobind.Keybinds.AcceptDeath == nil then
		autobind.Keybinds.AcceptDeath = {}
	end
	if autobind.Keybinds.AcceptDeath.Toggle == nil then 
		autobind.Keybinds.AcceptDeath.Toggle = true
	end
	if autobind.Keybinds.AcceptDeath.Keybind == nil then 
		autobind.Keybinds.AcceptDeath.Keybind = tostring(VK_OEM_MINUS)
	end
	if autobind.Keybinds.AcceptDeath.Dual == nil then 
		autobind.Keybinds.AcceptDeath.Dual = false
	end
	
	if autobind.Keybinds.FAid == nil then
		autobind.Keybinds.FAid = {}
	end
	if autobind.Keybinds.FAid.Toggle == nil then 
		autobind.Keybinds.FAid.Toggle = false
	end
	if autobind.Keybinds.FAid.Keybind == nil then 
		autobind.Keybinds.FAid.Keybind = tostring(VK_MENU)..','..tostring(VK_N)
	end
	if autobind.Keybinds.FAid.Dual == nil then 
		autobind.Keybinds.FAid.Dual = true
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
	
	if autobind.GangLocker == nil then
		autobind.GangLocker = {}
	end
	if autobind.GangLocker[1] == nil then 
		autobind.GangLocker[1] = true
	end
	if autobind.GangLocker[2] == nil then 
		autobind.GangLocker[2] = false
	end
	if autobind.GangLocker[3] == nil then 
		autobind.GangLocker[3] = false
	end
	if autobind.GangLocker[4] == nil then 
		autobind.GangLocker[4] = false
	end
	if autobind.GangLocker[5] == nil then 
		autobind.GangLocker[5] = false
	end
	if autobind.GangLocker[6] == nil then 
		autobind.GangLocker[6] = false
	end
	if autobind.GangLocker[7] == nil then 
		autobind.GangLocker[7] = false
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
	
	if autobind.imcolor == nil then
		autobind.imcolor = {}
	end
	if autobind.imcolor[1] == nil then 
		autobind.imcolor[1] = 0.98
	end
	
	if autobind.imcolor[2] == nil then 
		autobind.imcolor[2] = 0.26
	end
	
	if autobind.imcolor[3] == nil then 
		autobind.imcolor[3] = 0.26
	end
	
	if autobind.imcolor[4] == nil then 
		autobind.imcolor[4] = 1.00
	end
	
	if autobind.fa6 == nil then 
		autobind.fa6 = 'regular'
	end
	
	if autobind.progressbar == nil then 
		autobind.progressbar = {}
	end
	if autobind.progressbar.toggle == nil then
		autobind.progressbar.toggle = false
	end
	if autobind.progressbar.color == nil then 
		autobind.progressbar.color = {}
	end
	if autobind.progressbar.color[1] == nil then 
		autobind.progressbar.color[1] = 0.98
	end
	
	if autobind.progressbar.color[2] == nil then 
		autobind.progressbar.color[2] = 0.26
	end
	
	if autobind.progressbar.color[3] == nil then 
		autobind.progressbar.color[3] = 0.26
	end
	
	if autobind.progressbar.color[4] == nil then 
		autobind.progressbar.color[4] = 1.00
	end
	
	if autobind.progressbar.colorfade == nil then 
		autobind.progressbar.colorfade = {}
	end
	if autobind.progressbar.colorfade[1] == nil then 
		autobind.progressbar.colorfade[1] = 0.98
	end
	
	if autobind.progressbar.colorfade[2] == nil then 
		autobind.progressbar.colorfade[2] = 0.26
	end
	
	if autobind.progressbar.colorfade[3] == nil then 
		autobind.progressbar.colorfade[3] = 0.26
	end
	
	if autobind.progressbar.colorfade[4] == nil then 
		autobind.progressbar.colorfade[4] = 0.50
	end
	if autobind.timertext == nil then 
		autobind.timertext = true
	end
	
	if autobind.audio == nil then 
		autobind.audio = {}
	end
	
	if autobind.audio.toggle == nil then 
		autobind.audio.toggle = {}
	end
	if autobind.audio.toggle[1] == nil then 
		autobind.audio.toggle[1] = true
	end
	if autobind.audio.toggle[2] == nil then 
		autobind.audio.toggle[2] = true
	end
	if autobind.audio.toggle[3] == nil then 
		autobind.audio.toggle[3] = false
	end
	
	if autobind.audio.sounds == nil then 
		autobind.audio.sounds = {}
	end
	if autobind.audio.sounds[1] == nil then 
		autobind.audio.sounds[1] = "sound1.mp3"
	end
	if autobind.audio.sounds[2] == nil then 
		autobind.audio.sounds[2] = "sound2.mp3"
	end
	if autobind.audio.sounds[3] == nil then 
		autobind.audio.sounds[3] = "sound3.mp3"
	end
	
	if autobind.audio.paths == nil then 
		autobind.audio.paths = {}
	end
	if autobind.audio.paths[1] == nil then 
		autobind.audio.paths[1] = audiofolder .. "sound1.mp3"
	end
	if autobind.audio.paths[2] == nil then 
		autobind.audio.paths[2] = audiofolder .. "sound2.mp3"
	end
	if autobind.audio.paths[3] == nil then 
		autobind.audio.paths[3] = audiofolder .. "sound3.mp3"
	end
	
	if autobind.audio.volumes == nil then 
		autobind.audio.volumes = {}
	end
	if autobind.audio.volumes[1] == nil then 
		autobind.audio.volumes[1] = 0.10
	end
	if autobind.audio.volumes[2] == nil then 
		autobind.audio.volumes[2] = 0.10
	end
	if autobind.audio.volumes[3] == nil then 
		autobind.audio.volumes[3] = 0.10
	end
	
	if autobind.streamedplayers == nil then 
		autobind.streamedplayers = {}
	end
	
	if autobind.streamedplayers.toggle == nil then 
		autobind.streamedplayers.toggle = false
	end
	
	if autobind.streamedplayers.pos == nil then 
		autobind.streamedplayers.pos = {}
	end
	if autobind.streamedplayers.pos[1] == nil then 
		autobind.streamedplayers.pos[1] = 244
	end
	if autobind.streamedplayers.pos[2] == nil then 
		autobind.streamedplayers.pos[2] = 401
	end
	
	if autobind.streamedplayers.color == nil then 
		autobind.streamedplayers.color = -1
	end
	
	if autobind.streamedplayers.color == nil then 
		autobind.streamedplayers.color = -1
	end
	
	if autobind.streamedplayers.font == nil then 
		autobind.streamedplayers.font = "Arial"
	end
	
	if autobind.streamedplayers.fontsize == nil then 
		autobind.streamedplayers.fontsize = 12
	end
	
	if autobind.streamedplayers.fontflag == nil then 
		autobind.streamedplayers.fontflag = {}
	end
	if autobind.streamedplayers.fontflag[1] == nil then 
		autobind.streamedplayers.fontflag[1] = true
	end
	if autobind.streamedplayers.fontflag[2] == nil then 
		autobind.streamedplayers.fontflag[2] = true
	end
	if autobind.streamedplayers.fontflag[3] == nil then 
		autobind.streamedplayers.fontflag[3] = true
	end
	if autobind.streamedplayers.fontflag[4] == nil then 
		autobind.streamedplayers.fontflag[4] = true
	end
	
	if autobind.streamedplayers.alignfont == nil then 
		autobind.streamedplayers.alignfont = 2
	end
	
	if autobind.messages == false or autobind.messages == true then 
		autobind.messages = {}
	end
	if autobind.messages == nil then 
		autobind.messages = {}
	end
	if autobind.messages.bodyguard == nil then
		autobind.messages.bodyguard = false
	end
	if autobind.messages.acceptedyour == nil then
		autobind.messages.acceptedyour = false
	end
	if autobind.messages.accepted == nil then
		autobind.messages.accepted = false
	end
	if autobind.messages.offered == nil then
		autobind.messages.offered = false
	end
	if autobind.messages.youmustwait == nil then
		autobind.messages.youmustwait = false
	end
	if autobind.messages.aiming == nil then
		autobind.messages.aiming = false
	end
	if autobind.messages.playnotnear == nil then
		autobind.messages.playnotnear = false
	end
	if autobind.messages.noeffect == nil then
		autobind.messages.noeffect = false
	end
	if autobind.messages.nofaid == nil then
		autobind.messages.nofaid = false
	end
end

function sendBMCmd()
	lua_thread.create(function()
		bmcmd = bmcmd + 1
		if bmcmd ~= 3 then
			wait(250)
			sampSendChat("/bm")
		else    
			wait(1000)
			bmcmd = 0
			sampSendChat("/bm")
		end
	end)
end

function sendLockerCmd()
	lua_thread.create(function()
		lockercmd = lockercmd + 1
		if lockercmd ~= 3 then
			wait(250)
			sampSendChat("/locker")
		else    
			wait(1000)
			lockercmd = 0
			sampSendChat("/locker")
		end
	end)
end

function sendGangCmd()
	lua_thread.create(function()
		gangcmd = gangcmd + 1
		if gangcmd ~= 3 then
			wait(250)
			sampSendChat("/glocker")
		else    
			wait(1000)
			gangcmd = 0
			sampSendChat("/glocker")
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

function scanGameFolder(path, tables)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            --local f = path..'\\'..file
			local f = path..file
			local file_extension = string.match(file, "([^\\%.]+)$") -- Avoids double "extension" file names from being included and seen as "audiofile"
            if file_extension:match("mp3") or file_extension:match("mp4") or file_extension:match("wav") or file_extension:match("m4a") or file_extension:match("flac") or file_extension:match("m4r") or file_extension:match("ogg")
			or file_extension:match("mp2") or file_extension:match("amr") or file_extension:match("wma") or file_extension:match("aac") or file_extension:match("aiff") then
				table.insert(tables, file)
                tables[file] = f
            end 
            if lfs.attributes(f, "mode") == "directory" then
                tables = scanGameFolder(f, tables)
            end 
        end
    end
    return tables
end

function keychange(name)
	if not autobind.Keybinds[name].Dual then
		if not inuse_key then
			if imgui.Button(changekey[name] and 'Press any key' or vk.id_to_name(tonumber(autobind.Keybinds[name].Keybind))..'##'..name) then
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
			if autobind.Keybinds[name].Keybind:find(",") then
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

function register_help_commands()
	for i = 0, #help.commands do
		if help.commands[i] ~= nil then
			if help.commands[i]:find("*** AUTOBIND ***") then
				table.remove(help.commands, i)
			end
			if help.commands[i]:find("*** AUTOVEST ***") then
				table.remove(help.commands, i)
			end
		end
	end
	
	lua_thread.create(function() 
		help.commands[#help.commands + 1] = string.format("*** AUTOBIND *** /%s /%s /%s /%s /%s /%s /%s /%s", autobind.autovestsettingscmd, autobind.vestnearcmd,autobind.sexnearcmd,autobind.repairnearcmd,autobind.hfindcmd,autobind.tcapcmd,autobind.sprintbindcmd,autobind.bikebindcmd)
		help.commands[#help.commands + 1] = string.format("*** AUTOVEST *** /%s /%s /%s /%s /%s /%s, /%s", autobind.autoacceptercmd,autobind.ddmodecmd,autobind.vestmodecmd,autobind.factionbothcmd,autobind.autovestcmd,autobind.turfmodecmd,autobind.pointmodecmd)
		wait(500)
		help_saveIni()
	end)
end

function emul_rpc(hook, parameters)
    local bs_io = require 'samp.events.bitstream_io'
    local handler = require 'samp.events.handlers'
    local extra_types = require 'samp.events.extra_types'
    local hooks = {

        --[[ Outgoing rpcs
        ['onSendEnterVehicle'] = { 'int16', 'bool8', 26 },
        ['onSendClickPlayer'] = { 'int16', 'int8', 23 },
        ['onSendClientJoin'] = { 'int32', 'int8', 'string8', 'int32', 'string8', 'string8', 'int32', 25 },
        ['onSendEnterEditObject'] = { 'int32', 'int16', 'int32', 'vector3d', 27 },
        ['onSendCommand'] = { 'string32', 50 },
        ['onSendSpawn'] = { 52 },
        ['onSendDeathNotification'] = { 'int8', 'int16', 53 },
        ['onSendDialogResponse'] = { 'int16', 'int8', 'int16', 'string8', 62 },
        ['onSendClickTextDraw'] = { 'int16', 83 },
        ['onSendVehicleTuningNotification'] = { 'int32', 'int32', 'int32', 'int32', 96 },
        ['onSendChat'] = { 'string8', 101 },
        ['onSendClientCheckResponse'] = { 'int8', 'int32', 'int8', 103 },
        ['onSendVehicleDamaged'] = { 'int16', 'int32', 'int32', 'int8', 'int8', 106 },
        ['onSendEditAttachedObject'] = { 'int32', 'int32', 'int32', 'int32', 'vector3d', 'vector3d', 'vector3d', 'int32', 'int32', 116 },
        ['onSendEditObject'] = { 'bool', 'int16', 'int32', 'vector3d', 'vector3d', 117 },
        ['onSendInteriorChangeNotification'] = { 'int8', 118 },
        ['onSendMapMarker'] = { 'vector3d', 119 },
        ['onSendRequestClass'] = { 'int32', 128 },
        ['onSendRequestSpawn'] = { 129 },
        ['onSendPickedUpPickup'] = { 'int32', 131 },
        ['onSendMenuSelect'] = { 'int8', 132 },
        ['onSendVehicleDestroyed'] = { 'int16', 136 },
        ['onSendQuitMenu'] = { 140 },
        ['onSendExitVehicle'] = { 'int16', 154 },
        ['onSendUpdateScoresAndPings'] = { 155 },
        ['onSendGiveDamage'] = { 'int16', 'float', 'int32', 'int32', 115 },
        ['onSendTakeDamage'] = { 'int16', 'float', 'int32', 'int32', 115 },]]

        -- Incoming rpcs
        ['onInitGame'] = { 139 },
        ['onPlayerJoin'] = { 'int16', 'int32', 'bool8', 'string8', 137 },
        ['onPlayerQuit'] = { 'int16', 'int8', 138 },
        ['onRequestClassResponse'] = { 'bool8', 'int8', 'int32', 'int8', 'vector3d', 'float', 'Int32Array3', 'Int32Array3', 128 },
        ['onRequestSpawnResponse'] = { 'bool8', 129 },
        ['onSetPlayerName'] = { 'int16', 'string8', 'bool8', 11 },
        ['onSetPlayerPos'] = { 'vector3d', 12 },
        ['onSetPlayerPosFindZ'] = { 'vector3d', 13 },
        ['onSetPlayerHealth'] = { 'float', 14 },
        ['onTogglePlayerControllable'] = { 'bool8', 15 },
        ['onPlaySound'] = { 'int32', 'vector3d', 16 },
        ['onSetWorldBounds'] = { 'float', 'float', 'float', 'float', 17 },
        ['onGivePlayerMoney'] = { 'int32', 18 },
        ['onSetPlayerFacingAngle'] = { 'float', 19 },
        --['onResetPlayerMoney'] = { 20 },
        --['onResetPlayerWeapons'] = { 21 },
        ['onGivePlayerWeapon'] = { 'int32', 'int32', 22 },
        --['onCancelEdit'] = { 28 },
        ['onSetPlayerTime'] = { 'int8', 'int8', 29 },
        ['onSetToggleClock'] = { 'bool8', 30 },
        ['onPlayerStreamIn'] = { 'int16', 'int8', 'int32', 'vector3d', 'float', 'int32', 'int8', 32 },
        ['onSetShopName'] = { 'string256', 33 },
        ['onSetPlayerSkillLevel'] = { 'int16', 'int32', 'int16', 34 },
        ['onSetPlayerDrunk'] = { 'int32', 35 },
        ['onCreate3DText'] = { 'int16', 'int32', 'vector3d', 'float', 'bool8', 'int16', 'int16', 'encodedString4096', 36 },
        --['onDisableCheckpoint'] = { 37 },
        ['onSetRaceCheckpoint'] = { 'int8', 'vector3d', 'vector3d', 'float', 38 },
        --['onDisableRaceCheckpoint'] = { 39 },
        --['onGamemodeRestart'] = { 40 },
        ['onPlayAudioStream'] = { 'string8', 'vector3d', 'float', 'bool8', 41 },
        --['onStopAudioStream'] = { 42 },
        ['onRemoveBuilding'] = { 'int32', 'vector3d', 'float', 43 },
        ['onCreateObject'] = { 44 },
        ['onSetObjectPosition'] = { 'int16', 'vector3d', 45 },
        ['onSetObjectRotation'] = { 'int16', 'vector3d', 46 },
        ['onDestroyObject'] = { 'int16', 47 },
        ['onPlayerDeathNotification'] = { 'int16', 'int16', 'int8', 55 },
        ['onSetMapIcon'] = { 'int8', 'vector3d', 'int8', 'int32', 'int8', 56 },
        ['onRemoveVehicleComponent'] = { 'int16', 'int16', 57 },
        ['onRemove3DTextLabel'] = { 'int16', 58 },
        ['onPlayerChatBubble'] = { 'int16', 'int32', 'float', 'int32', 'string8', 59 },
        ['onUpdateGlobalTimer'] = { 'int32', 60 },
        ['onShowDialog'] = { 'int16', 'int8', 'string8', 'string8', 'string8', 'encodedString4096', 61 },
        ['onDestroyPickup'] = { 'int32', 63 },
        ['onLinkVehicleToInterior'] = { 'int16', 'int8', 65 },
        ['onSetPlayerArmour'] = { 'float', 66 },
        ['onSetPlayerArmedWeapon'] = { 'int32', 67 },
        ['onSetSpawnInfo'] = { 'int8', 'int32', 'int8', 'vector3d', 'float', 'Int32Array3', 'Int32Array3', 68 },
        ['onSetPlayerTeam'] = { 'int16', 'int8', 69 },
        ['onPutPlayerInVehicle'] = { 'int16', 'int8', 70 },
        --['onRemovePlayerFromVehicle'] = { 71 },
        ['onSetPlayerColor'] = { 'int16', 'int32', 72 },
        ['onDisplayGameText'] = { 'int32', 'int32', 'string32', 73 },
        --['onForceClassSelection'] = { 74 },
        ['onAttachObjectToPlayer'] = { 'int16', 'int16', 'vector3d', 'vector3d', 75 },
        ['onInitMenu'] = { 76 },
        ['onShowMenu'] = { 'int8', 77 },
        ['onHideMenu'] = { 'int8', 78 },
        ['onCreateExplosion'] = { 'vector3d', 'int32', 'float', 79 },
        ['onShowPlayerNameTag'] = { 'int16', 'bool8', 80 },
        ['onAttachCameraToObject'] = { 'int16', 81 },
        ['onInterpolateCamera'] = { 'bool', 'vector3d', 'vector3d', 'int32', 'int8', 82 },
        ['onGangZoneStopFlash'] = { 'int16', 85 },
        ['onApplyPlayerAnimation'] = { 'int16', 'string8', 'string8', 'bool', 'bool', 'bool', 'bool', 'int32', 86 },
        ['onClearPlayerAnimation'] = { 'int16', 87 },
        ['onSetPlayerSpecialAction'] = { 'int8', 88 },
        ['onSetPlayerFightingStyle'] = { 'int16', 'int8', 89 },
        ['onSetPlayerVelocity'] = { 'vector3d', 90 },
        ['onSetVehicleVelocity'] = { 'bool8', 'vector3d', 91 },
        ['onServerMessage'] = { 'int32', 'string32', 93 },
        ['onSetWorldTime'] = { 'int8', 94 },
        ['onCreatePickup'] = { 'int32', 'int32', 'int32', 'vector3d', 95 },
        ['onMoveObject'] = { 'int16', 'vector3d', 'vector3d', 'float', 'vector3d', 99 },
        ['onEnableStuntBonus'] = { 'bool', 104 },
        ['onTextDrawSetString'] = { 'int16', 'string16', 105 },
        ['onSetCheckpoint'] = { 'vector3d', 'float', 107 },
        ['onCreateGangZone'] = { 'int16', 'vector2d', 'vector2d', 'int32', 108 },
        ['onPlayCrimeReport'] = { 'int16', 'int32', 'int32', 'int32', 'int32', 'vector3d', 112 },
        ['onGangZoneDestroy'] = { 'int16', 120 },
        ['onGangZoneFlash'] = { 'int16', 'int32', 121 },
        ['onStopObject'] = { 'int16', 122 },
        ['onSetVehicleNumberPlate'] = { 'int16', 'string8', 123 },
        ['onTogglePlayerSpectating'] = { 'bool32', 124 },
        ['onSpectatePlayer'] = { 'int16', 'int8', 126 },
        ['onSpectateVehicle'] = { 'int16', 'int8', 127 },
        ['onShowTextDraw'] = { 134 },
        ['onSetPlayerWantedLevel'] = { 'int8', 133 },
        ['onTextDrawHide'] = { 'int16', 135 },
        ['onRemoveMapIcon'] = { 'int8', 144 },
        ['onSetWeaponAmmo'] = { 'int8', 'int16', 145 },
        ['onSetGravity'] = { 'float', 146 },
        ['onSetVehicleHealth'] = { 'int16', 'float', 147 },
        ['onAttachTrailerToVehicle'] = { 'int16', 'int16', 148 },
        ['onDetachTrailerFromVehicle'] = { 'int16', 149 },
        ['onSetWeather'] = { 'int8', 152 },
        ['onSetPlayerSkin'] = { 'int32', 'int32', 153 },
        ['onSetInterior'] = { 'int8', 156 },
        ['onSetCameraPosition'] = { 'vector3d', 157 },
        ['onSetCameraLookAt'] = { 'vector3d', 'int8', 158 },
        ['onSetVehiclePosition'] = { 'int16', 'vector3d', 159 },
        ['onSetVehicleAngle'] = { 'int16', 'float', 160 },
        ['onSetVehicleParams'] = { 'int16', 'int16', 'bool8', 161 },
        --['onSetCameraBehind'] = { 162 },
        ['onChatMessage'] = { 'int16', 'string8', 101 },
        ['onConnectionRejected'] = { 'int8', 130 },
        ['onPlayerStreamOut'] = { 'int16', 163 },
        ['onVehicleStreamIn'] = { 164 },
        ['onVehicleStreamOut'] = { 'int16', 165 },
        ['onPlayerDeath'] = { 'int16', 166 },
        ['onPlayerEnterVehicle'] = { 'int16', 'int16', 'bool8', 26 },
        ['onUpdateScoresAndPings'] = { 'PlayerScorePingMap', 155 },
        ['onSetObjectMaterial'] = { 84 },
        ['onSetObjectMaterialText'] = { 84 },
        ['onSetVehicleParamsEx'] = { 'int16', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 24 },
        ['onSetPlayerAttachedObject'] = { 'int16', 'int32', 'bool', 'int32', 'int32', 'vector3d', 'vector3d', 'vector3d', 'int32', 'int32', 113 }

    }
    local handler_hook = {
        ['onInitGame'] = true,
        ['onCreateObject'] = true,
        ['onInitMenu'] = true,
        ['onShowTextDraw'] = true,
        ['onVehicleStreamIn'] = true,
        ['onSetObjectMaterial'] = true,
        ['onSetObjectMaterialText'] = true
    }
    local extra = {
        ['PlayerScorePingMap'] = true,
        ['Int32Array3'] = true
    }
    local hook_table = hooks[hook]
    if hook_table then
        local bs = raknetNewBitStream()
        if not handler_hook[hook] then
            local max = #hook_table-1
            if max > 0 then
                for i = 1, max do
                    local p = hook_table[i]
                    if extra[p] then extra_types[p]['write'](bs, parameters[i])
                    else bs_io[p]['write'](bs, parameters[i]) end
                end
            end
        else
            if hook == 'onInitGame' then handler.on_init_game_writer(bs, parameters)
            elseif hook == 'onCreateObject' then handler.on_create_object_writer(bs, parameters)
            elseif hook == 'onInitMenu' then handler.on_init_menu_writer(bs, parameters)
            elseif hook == 'onShowTextDraw' then handler.on_show_textdraw_writer(bs, parameters)
            elseif hook == 'onVehicleStreamIn' then handler.on_vehicle_stream_in_writer(bs, parameters)
            elseif hook == 'onSetObjectMaterial' then handler.on_set_object_material_writer(bs, parameters, 1)
            elseif hook == 'onSetObjectMaterialText' then handler.on_set_object_material_writer(bs, parameters, 2) end
        end
        raknetEmulRpcReceiveBitStream(hook_table[#hook_table], bs)
        raknetDeleteBitStream(bs)
    end
end

function imgui.AnimProgressBar(label, int, int2, duration, size, color, color2)
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
	local clr = imgui.Col
    imgui.PushStyleColor(clr.Text, imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(clr.FrameBg, color) -- background color progress bar
    imgui.PushStyleColor(clr.PlotHistogram, color2) -- fill color progress bar
    imgui.ProgressBar(p.int / int2,size or imgui.ImVec2(-1,15))
    imgui.PopStyleColor(3)
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

function sound_dropdownmenu(i)
	if imgui.Checkbox('Toggle##'..i, new.bool(autobind.audio.toggle[i])) then 
		autobind.audio.toggle[i] = not autobind.audio.toggle[i]
	end  
	imgui.PushItemWidth(150)
	if imgui.BeginCombo("##sounds2"..i, autobind.audio.sounds[i]) then
		for k, v in pairs(paths) do
			k = tostring(k)
			if k:match(".+%.mp3") or k:match(".+%.mp4") or k:match(".+%.wav") or k:match(".+%.m4a") or k:match(".+%.flac") or k:match(".+%.m4r") or k:match(".+%.ogg") or k:match(".+%.mp2") or k:match(".+%.amr") or k:match(".+%.wma") or k:match(".+%.aac") or k:match(".+%.aiff") then
				if imgui.Selectable(u8(k), true) then 
					autobind.audio.sounds[i] = k
					autobind.audio.paths[i] = v
					playsound(i)
				end
			end
		end
		imgui.EndCombo()
	end
	imgui.PopItemWidth()
	
	imgui.PushItemWidth(150)
	local volume = new.float[1](autobind.audio.volumes[i])
	if imgui.SliderFloat(u8'##Volume##' .. i, volume, 0, 1) then
		autobind.audio.volumes[i] = volume[0]
	end
	imgui.PopItemWidth()
	
	if imgui.IsItemHovered() then
		imgui.SetTooltip('Volume Control')
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
	elseif vestmode == 4 then
		return 'Skins'
	end
end

function hex2rgba(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r / 255, g / 255, b / 255, a / 255
end

function hex2rgba_int(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r, g, b, a
end

function hex2rgb(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r / 255, g / 255, b / 255
end

function hex2rgb_int(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r, g, b
end

function join_argb(a, r, g, b)
	local argb = b
	argb = bit.bor(argb, bit.lshift(g, 8))  -- g
	argb = bit.bor(argb, bit.lshift(r, 16)) -- r
	argb = bit.bor(argb, bit.lshift(a, 24)) -- a
	return argb
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
	style.DisplayWindowPadding = ImVec2(0, 0)
	style.DisplaySafeAreaPadding = ImVec2(4, 4)
	style.AntiAliasedLines = true
	style.CurveTessellationTol = 1.25
	
	local colors = style.Colors
	local clr = imgui.Col
	colors[clr.FrameBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(mainc.x, mainc.y, mainc.z, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.67)
    colors[clr.TitleBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 0.6)
    colors[clr.TitleBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
    colors[clr.TitleBgCollapsed]       = ImVec4(mainc.x, mainc.y, mainc.z, 0.40)
	colors[clr.CheckMark]              = ImVec4(mainc.x + 0.13, mainc.y + 0.13, mainc.z + 0.13, 0.8)
	colors[clr.SliderGrab]             = ImVec4(mainc.x, mainc.y, mainc.z, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(mainc.x, mainc.y, mainc.z, 1.00)
	colors[clr.Button]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
	colors[clr.ButtonActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.Header]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.40)
	colors[clr.HeaderHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
	colors[clr.HeaderActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
    colors[clr.ResizeGripHovered]      = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
    colors[clr.ResizeGripActive]       = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]                 = ImVec4(0.06, 0.06, 0.06, 0.00)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
end

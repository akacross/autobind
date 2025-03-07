script_name("autobind")
script_description("Autobind is a collection of useful features and modifications")
script_version("1.8.25a5")
script_authors("akacross")
script_url("https://akacross.net/")

local shortName = "ab"

local scriptPath = thisScript().path
local scriptName = thisScript().name
local scriptVersion = thisScript().version
local scriptDesc = thisScript().description

local workingDir = getWorkingDirectory()

local Paths = {
    libraries = workingDir .. '\\lib\\',
    config = workingDir .. '\\config\\',
    resource = workingDir .. '\\resource\\',
    windowsFonts = getFolderPath(0x14) .. '\\'
}

Paths.settings = Paths.config .. scriptName .. '\\'
Paths.skins = Paths.resource .. 'skins\\'
Paths.fonts = Paths.resource .. 'fonts\\'

local Files = {
    script = Paths.settings .. scriptName .. '.lua',
    fawesome5 = Paths.fonts .. 'fa-solid-900.ttf',
    trebucbd = Paths.windowsFonts .. 'trebucbd.ttf'
}

local baseUrl = "https://raw.githubusercontent.com/akacross/"

local function getBaseUrl(beta, scriptname)
    local branch = beta and "beta/" or ""
    return string.format("%s%s/main/%s", baseUrl, scriptname, branch)
end

local Urls = {
    libraries = getBaseUrl(false, "libraries") .. "lib/",
    resource = getBaseUrl(false, "libraries") .. "resource/",
    script = function(beta)
        return getBaseUrl(beta, scriptName) .. scriptName .. ".lua"
    end,
    update = function(beta)
        return getBaseUrl(beta, scriptName) .. "update.json"
    end,
    skinsPath = getBaseUrl(false, scriptName) .. "resource/skins/",
    skins = getBaseUrl(false, scriptName) .. "skins.json",
    names = getBaseUrl(false, scriptName) .. "names.json",
    charges = getBaseUrl(false, scriptName) .. "charges.json",
    changelog = getBaseUrl(false, scriptName) .. "changelog.json",
    betatesters = getBaseUrl(true, scriptName) .. "betatesters.json"
}

local function safeRequire(moduleName)
    local ok, result = pcall(require, moduleName)
    return ok and result or nil, result
end

local dependencies = {
    {required = false, name = 'ltn12', var = 'ltn12', localFile = "ltn12.lua"},
    {required = false, name = 'ssl.https', var = 'https', 
        localFiles = {
            "ssl.dll",
            "ssl.lua", 
            "ssl/https.lua"
        }
    },
    {required = false, name = 'socket.http', var = 'http', 
        localFiles = {
            "socket.lua",
            "socket/core.dll",
            "socket/ftp.lua",
            "socket/headers.lua",
            "socket/http.lua",
            "socket/smtp.lua",
            "socket/tp.lua"
        }
    },
    {required = false, name = 'socket.url', var = 'url', localFile = "socket/url.lua"},
    {required = false, name = 'lfs', var = 'lfs', localFile = "lfs.dll"},
    {required = false, name = 'lanes', var = 'lanes', 
        localFiles = {
            "lanes.lua",
            "lanes/core.dll"
        }, 
        callback = function(module) return module.configure() end
    },
    {required = true, name = 'moonloader', var = 'moonloader', localFile = "moonloader.lua"}, 
    {required = true, name = 'ffi', var = 'ffi'},
    {required = true, name = 'memory', var = 'mem'},
    {required = true, name = 'vkeys', var = 'vk', localFile = "vkeys.lua"},
    {required = true, name = 'game.keys', var = 'gkeys',
        localFiles = {
            "game/globals.lua", 
            "game/keys.lua", 
            "game/models.lua", 
            "game/weapons.lua"
        }
    },
    {required = true, name = 'windows.message', var = 'wm',
        localFiles = {
            "windows/init.lua", 
            "windows/message.lua"
        }
    },
    {required = true, name = 'mimgui', var = 'imgui',
        localFiles = {
            "mimgui/cdefs.lua",
            "mimgui/cimguidx9.dll",
            "mimgui/dx9.lua",
            "mimgui/imgui.lua",
            "mimgui/init.lua"
        }
    },
    {required = true, name = 'encoding', var = 'encoding',
        localFiles = {
            "encoding.lua",
            "iconv.dll"
        }
    },
    {required = true, name = "tabler_icons", var = "ti", localFile = "tabler_icons.lua"},
    {required = true, name = 'fAwesome5', var = 'fa', localFile = "fAwesome5.lua", resourceFile = "fonts/fa-solid-900.ttf"},
    {import = true, name = "mimtoasts", var = "mimtoasts", localFile = "mimtoasts.lua"},
    {required = true, name = 'samp.events', var = 'sampev',
        localFiles = {
            "samp/events.lua",
            "samp/raknet.lua",
            "samp/synchronization.lua",
            "samp/events/bitstream_io.lua",
            "samp/events/core.lua",
            "samp/events/extra_types.lua",
            "samp/events/handlers.lua",
            "samp/events/utils.lua"
        }
    },
    {required = true, name = "akacross.downloads", var = "downloads", localFile = "akacross/downloads.lua"},
    {required = true, name = "akacross.configs", var = "configs", localFile = "akacross/configs.lua"},
    {required = true, name = "akacross.colors", var = "colors", localFile = "akacross/colors.lua"},
    {required = true, name = "akacross.imgui_funcs", var = "imgui_funcs", localFile = "akacross/imgui_funcs.lua"}
}

local function downloadFiles(table, onCompleteCallback)
    local downloadsInProgress = 0
    local downloadsStarted = false
    local callbackCalled = false

    for _, file in ipairs(table) do
        local folderPath = file.path:match("^(.*)[\\/].+$")
        if folderPath and #folderPath > 0 then
            createDirectory(folderPath)
        end

        downloadsInProgress = downloadsInProgress + 1
        downloadsStarted = true
        downloadUrlToFile(file.url, file.path, function(id, status, p1, p2)
            if status == 6 then
                downloadsInProgress = downloadsInProgress - 1
            end

            if downloadsInProgress == 0 and onCompleteCallback and not callbackCalled then
                callbackCalled = true
                onCompleteCallback(downloadsStarted)
            end
        end)
    end

    if not downloadsStarted and onCompleteCallback and not callbackCalled then
        callbackCalled = true
        onCompleteCallback(downloadsStarted)
    end
end

local missingFiles = {}

local function checkAndDownloadDependencies(callback)
    for _, dep in ipairs(dependencies) do
        local filesMissing = false

        if dep.localFiles then
            for _, file in ipairs(dep.localFiles) do
                local fullPath = Paths.libraries .. file:gsub("/", "\\")
                if not doesFileExist(fullPath) then
                    filesMissing = true
                    table.insert(missingFiles, {
                        url = Urls.libraries .. file,
                        path = fullPath
                    })
                end
            end
        elseif dep.localFile then
            local fullPath = Paths.libraries .. dep.localFile:gsub("/", "\\")
            if not doesFileExist(fullPath) then
                filesMissing = true
                table.insert(missingFiles, {
                    url = Urls.libraries .. dep.localFile,
                    path = fullPath
                })
            end
        end
        
        if dep.resourceFile then
            local fullPath = Paths.resource .. dep.resourceFile:gsub("/", "\\")
            if not doesFileExist(fullPath) then
                filesMissing = true
                table.insert(missingFiles, {
                    url = Urls.resource .. dep.resourceFile,
                    path = fullPath
                })
            end
        end

        if not filesMissing then
            if dep.import == nil then
                local mod = safeRequire(dep.name)
                if not mod then
                    print("Missing dependency and no download info provided: " .. dep.name)
                end
            end
        end
    end

    if #missingFiles > 0 then
        downloadFiles(missingFiles, function(downloadResult)
            if downloadResult then
                lua_thread.create(function()
                    wait(1000)
                    thisScript():reload()
                end)
            else
                print("Download failed. Please check your internet connection and try again.")
            end
        end)
    else
        callback()
    end
end

function main()
    while not isSampAvailable() do wait(100) end

    if #missingFiles > 0 then
        local missingFileText = #missingFiles == 1 and "file" or "files"
        sampAddChatMessage(("[%s] {FFFFFF}Some dependencies are missing, downloading now... (Missing: %d %s)"):format(shortName:upper(), #missingFiles, missingFileText), 0xBA4747) -- #BA4747
    end

    wait(-1)
end

-- Start checking (and, if needed, downloading) missing dependencies.
local mainScript, scriptError = xpcall(checkAndDownloadDependencies, debug.traceback, function()

local statusMessages = {success = {}, failed = {}}

for _, dep in ipairs(dependencies) do
    if dep.required then
        local mod, err = safeRequire(dep.name)
        if mod and dep.callback then
            local ok, result = pcall(dep.callback, mod)
            if ok then
                mod = result
            else
                mod = nil
                err = result
            end
        end

        if mod then
            local depName = dep.name:gsub("^.-%.", "")
            table.insert(statusMessages.success, depName)
            _G[dep.var] = mod

            if dep.extras then
                for extraVar, extraField in pairs(dep.extras) do
                    _G[extraVar] = mod[extraField]
                end
            end
        else
            table.insert(statusMessages.failed, ("%s (%s)"):format(dep.name, err))
        end
    end
    
    if dep.import then
        local result, mod, err = pcall(import, Paths.libraries .. dep.localFile)
        if result and mod then
            table.insert(statusMessages.success, dep.name)
            _G[dep.var] = mod
        else
            table.insert(statusMessages.failed, ("%s (%s)"):format(dep.name, err))
        end
    end
end

print("Loaded modules: " .. table.concat(statusMessages.success, ", "))
if #statusMessages.failed > 0 then
    print("Failed to load modules: " .. table.concat(statusMessages.failed, ", "))
end

-- Dynamically set script dependencies if needed.
script_dependencies(table.unpack(statusMessages.success))

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local pivots = {
    {name = "Top-Left", value = {x = 0.0, y = 0.0}, icon = fa.ICON_FA_ARROW_LEFT},
    {name = "Top-Center", value = {x = 0.5, y = 0.0}, icon = fa.ICON_FA_ARROW_UP},
    {name = "Top-Right", value = {x = 1.0, y = 0.0}, icon = fa.ICON_FA_ARROW_RIGHT},
    {name = "Center-Left", value = {x = 0.0, y = 0.5}, icon = fa.ICON_FA_ARROW_LEFT},
    {name = "Center", value = {x = 0.5, y = 0.5}, icon = fa.ICON_FA_SQUARE},
    {name = "Center-Right", value = {x = 1.0, y = 0.5}, icon = fa.ICON_FA_ARROW_RIGHT},
    {name = "Bottom-Left", value = {x = 0.0, y = 1.0}, icon = fa.ICON_FA_ARROW_LEFT},
    {name = "Bottom-Center", value = {x = 0.5, y = 1.0}, icon = fa.ICON_FA_ARROW_DOWN},
    {name = "Bottom-Right", value = {x = 1.0, y = 1.0}, icon = fa.ICON_FA_ARROW_RIGHT}
}

local locationTypes = {}

for _, pointName in ipairs({
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
}) do
    locationTypes[pointName] = "point"
end

for _, turfName in ipairs({
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
}) do
    locationTypes[turfName] = "turf"
end

local radioStations = {
    [0] = {name = "Playback FM", desc = "Classic East Coast Hip Hop"},
    [1] = {name = "K-Rose", desc = "Classic Country"},
    [2] = {name = "K-DST", desc = "Classic Rock"},
    [3] = {name = "Bounce FM", desc = "Funk, Disco"},
    [4] = {name = "SF-UR", desc = "House"},
    [5] = {name = "Radio Los Santos", desc = "West Coast Hip Hop, Gangsta Rap"},
    [6] = {name = "Radio X", desc = "Alternative Rock, Grunge"},
    [7] = {name = "CSR 103.9", desc = "New Jack Swing, Contemporary Soul"},
    [8] = {name = "K-JAH West", desc = "Reggae, Dancehall"},
    [9] = {name = "Master Sounds 98.3", desc = "Rare Groove, Classic Funk"},
    [10] = {name = "WCTR", desc = "Talk Radio"},
    [11] = {name = "User Track", desc = "Personal Audio Files"},
    [12] = {name = "Radio Off", desc = "Turns off the radio"},
    [24] = {name = "User Track", desc = "Personal Audio Files"},
}

function getRadioStationName(stationId)
    return radioStations[stationId].name or "Unknown"
end

function getRadioStationDesc(stationId)
    return radioStations[stationId].desc or "Unknown"
end

local timeNames = {
    [0] = "Midnight",
    [1] = "Early Morning",
    [2] = "Early Morning",
    [3] = "Early Morning",
    [4] = "Early Morning",
    [5] = "Early Morning",
    [6] = "Dawn",
    [7] = "Morning",
    [8] = "Morning",
    [9] = "Morning",
    [10] = "Late Morning",
    [11] = "Late Morning",
    [12] = "Noon",
    [13] = "Afternoon",
    [14] = "Afternoon",
    [15] = "Afternoon",
    [16] = "Late Afternoon",
    [17] = "Evening",
    [18] = "Evening",
    [19] = "Evening",
    [20] = "Dusk",
    [21] = "Night",
    [22] = "Night",
    [23] = "Late Night"
}

function getTimeName(hour)
    return timeNames[hour] or "Invalid hour"
end

local weatherNames = {
    [0] = "Extra Sunny",
    [1] = "Sunny",
    [2] = "Extra Sunny Smog",
    [3] = "Sunny Smog",
    [4] = "Cloudy",
    [5] = "Sunny",
    [6] = "Extra Sunny",
    [7] = "Cloudy",
    [8] = "Rainy",
    [9] = "Foggy",
    [10] = "Sunny",
    [11] = "Extra Sunny",
    [12] = "Cloudy",
    [13] = "Extra Sunny",
    [14] = "Sunny",
    [15] = "Cloudy",
    [16] = "Rainy",
    [17] = "Extra Sunny",
    [18] = "Sunny",
    [19] = "Sandstorm",
    [20] = "Underwater",
    [21] = "Extracolours 1",
    [22] = "Extracolours 2"
}

local function getWeatherName(weatherId)
    return weatherNames[weatherId] or "Unknown"
end

local bikeIds = {[481] = true, [509] = true, [510] = true}
local motoIds = {
	[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, 
	[521] = true, [522] = true, [523] = true, [581] = true, [586] = true
}

local invalidAnimsSet = {
    [1158] = true, [1159] = true, [1160] = true, [1161] = true, [1162] = true,
    [1163] = true, [1164] = true, [1165] = true, [1166] = true, [1167] = true,
    [1069] = true, [1070] = true, [746] = true
}

local clrRGBA = {} -- onServerMessage color table
for name, color in pairs(colors.list()) do
    local clrs = colors.convertColor(color, false, true, false)

    if name == "WHITE" or 
       name == "GREY" or 
       name == "PURPLE" or 
       name == "YELLOW" or 
       name == "LIGHTBLUE" or 
       name == "TEAM_MED_COLOR" or
       name == "NEWS" or
       name == "BLACK" then
        clrs.a = 170
    elseif name == "DEPTRADIO" then
        clrs.a = 74
    else
        if name ~= "TEAM_BLUE_COLOR" then
            clrs.a = 255
        end
    end

    if name == "TEAM_BLUE_COLOR" then
        clrRGBA["ARRESTED"] = colors.joinARGB(clrs.r, clrs.g, clrs.b, 170, false)
    end

    clrRGBA[name] = colors.joinARGB(clrs.r, clrs.g, clrs.b, clrs.a, false)
end

local imguiRGBA = {}
for name, color in pairs(colors.list()) do
    local clrs = colors.convertColor(color, true, true, false)

    if name == "REALRED" or 
       name == "REALGREEN" or
       name == "RED" or
       name == "GREEN" or
       name == "FADE5" or
       name == "DARKGREY" or
       name == "YELLOW" or
       name == "ORANGE" or
       name == "ARES" then
        clrs.a = 0.8
    else
        clrs.a = 1.0
    end

    if name == "ARES" then
        imguiRGBA["ARESALT"] = imgui.ImVec4(clrs.r, clrs.g, clrs.b, 0.6)
        imguiRGBA["ARESALT2"] = imgui.ImVec4(clrs.r, clrs.g, clrs.b, 0.5)
        imguiRGBA["ARESALT3"] = imgui.ImVec4(clrs.r, clrs.g, clrs.b, 0.4)
    end

    imguiRGBA[name] = imgui.ImVec4(clrs.r, clrs.g, clrs.b, clrs.a)
end

-- Global Variables
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle

local autoReboot = false

local chargeList = nil
local changelog = nil
local betatesters = nil

local resX, resY = getScreenResolution()

local isLoadingObjects = false
local cursorActive = false
local chatInputActive = false
local isGameFocused = true
local isPlayerAFK = false

local specData = {
	id = -1,
    name = "",
	state = false
}

local funcsLoop = {
    callbackCalled = false
}

local autobind_defaultSettings = {
	Settings = {
        enableDebugMessages = false,
        checkForUpdates = true,
        updateInProgress = false,
        lastVersion = "",
        fetchBeta = false,
        sprintBind = true,
        autoReconnect = true,
        autoRepair = true,
        autoFind = true,
        autoPicklockOnFail = false,
        autoPicklockOnSuccess = false,
        autoFarm = false,
        noRadio = false,
        favoriteRadio = 6,
        callSecondaryBackup = false,
        notifySkins = false,
		mode = "Family",
        HZRadio = true,
        LoginMusic = true,
        mustTargetToFrisk = false,
        mustAimToFrisk = true,
        blankMessagesAtConnection = true
	},
    Family = {
        frequency = 0,
        turf = false,
        point = false,
        disableAfterCapturing = true
    },
    Faction = {
        type = "",
        frequency = 0,
        turf = true,
        modifyRadioChat = false,
        autoBadge = true,
        hideChargeReporter = false,
        hideArrestReporter = false,
        showCades = true,
        showCadesLocal = false,
        showSpikes = true,
        showSpikesLocal = false,
        showFlares = true,
        showCones = true,
    },
    AutoVest = {
        autoGuard = true,
        guardFeatures = true,
        acceptFeatures = true,
        price = 200,
		everyone = false,
		useSkins = false,
        useNames = false,
		autoFetchSkins = true,
		autoFetchNames = false,
		donor = false,
		skins = {123},
		names = {"Cross_Lynch", "Allen_Lynch"},
		skinsUrl = Urls.skins,
		namesUrl = Urls.names,
        namesUrls = {}
	},
    Elements = {
        offeredTo = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 25},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr_WHITE, value = clr_LIGHTBLUE}
        },
        offeredFrom = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 50},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr_WHITE, value = clr_LIGHTBLUE}
        },
        PedsCount = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 75},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr_REALRED, value = clr_WHITE}
        },
        AutoFind = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 100},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr_REALRED, value = clr_WHITE}
        },
        LastBackup = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 125},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr_REALRED, value = clr_WHITE}
        },
        FactionBadge = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 150},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left"
        }
    },
    CurrentPlayer = {
        name = "",
        id = -1,
        welcomeMessage = false
    },
	WindowPos = {
		Settings = {x = resX / 2, y = resY / 2},
        VehicleStorage = {x = resX / 2, y = resY / 2},
        Skins = {x = resX / 2, y = resY / 2},
        Charges = {x = resX / 2, y = resY / 2},
        Names = {x = resX / 2, y = resY / 2},
        BlackMarket = {x = resX / 2, y = resY / 2},
        FactionLocker = {x = resX / 2, y = resY / 2},
        Changelog = {x = resX / 2, y = resY / 2}
	},
	BlackMarket = {
        Kit1 = {1, 4, 11},
        Kit2 = {1, 4, 13},
        Kit3 = {1, 4, 12},
        maxKits = 3,
		Locations = {}
    },
    FactionLocker = {
		Kit1 = {1, 2, 10, 11},
        Kit2 = {1, 2, 10, 11},
        Kit3 = {1, 2, 10, 11},
        maxKits = 3,
		Locations = {}
	},
    VehicleStorage = {
        Vehicles = {},
        enable = true,
        menu = false,
        chatInput = false,
        chatInputText = false,
        ShowBackground = true,
        BackgroundColor = colors.changeAlpha(clr_BLACK, 225),
        ShowBorder = true,
        BorderColor = colors.changeAlpha(clr_WHITE, 255),
        BorderSize = 2.0,
        Pivot = {x = 0.5, y = 0.0},
        Padding = {x = 8.0, y = 8.0},
        Rounding = 5.0
    },
    TimeAndWeather = {
        hour = 12,
        minute = 0,
        modifyTime = false,
        serverHour = 0,
        serverMinute = 0,
        weather = 2,
        modifyWeather = false,
        serverWeather = 0
    },
    Wanted = {
        Enabled = true,
        List = {},
        Pos = {x = 500, y = 500},
        BackgroundColor = colors.changeAlpha(clr_BLACK, 225),
        ShowBackground = true,
        BorderColor = colors.changeAlpha(clr_WHITE, 255),
        ShowBorder = true,
        RefreshColor = clr_TEAM_GROVE_COLOR,
        ShowRefresh = false,
        AFKTextColor = clr_TWRED,
        MostWantedColor = clr_TWRED,
        ShowAFK = false,
        BorderSize = 2.0,
        Pivot = {x = 0.5, y = 1.0},
        Padding = {x = 8.0, y = 8.0},
        Rounding = 5.0,
        Stars = false,
        Ping = false,
        Timer = 8.0,
        Expiry = {
            disconnected = 10.0,
            lawyer = 10.0,
            processed = 10.0,
            cleared = 10.0,
        }
    },
    Charges = {
        List = {}
    },
	Keybinds = {
        Accept = {Toggle = true, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}},
        Offer = {Toggle = true, Keys = {VK_MENU, VK_O}, Type = {'KeyDown', 'KeyPressed'}},
        BlackMarket1 = {Toggle = false, Keys = {VK_MENU, VK_1}, Type = {'KeyDown', 'KeyPressed'}},
        BlackMarket2 = {Toggle = false, Keys = {VK_MENU, VK_2}, Type = {'KeyDown', 'KeyPressed'}},
        BlackMarket3 = {Toggle = false, Keys = {VK_MENU, VK_3}, Type = {'KeyDown', 'KeyPressed'}},
        FactionLocker1 = {Toggle = false, Keys = {VK_MENU, VK_X}, Type = {'KeyDown', 'KeyPressed'}},
        FactionLocker2 = {Toggle = false, Keys = {VK_MENU, VK_C}, Type = {'KeyDown', 'KeyPressed'}},
        FactionLocker3 = {Toggle = false, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}},
        BikeBind = {Toggle = true, Keys = {VK_SHIFT, VK_W}, Type = {'KeyDown', 'KeyDown'}},
        SprintBind = {Toggle = true, Keys = {VK_F11}, Type = {'KeyPressed'}},
        Frisk = {Toggle = false, Keys = {VK_MENU, VK_F}, Type = {'KeyDown', 'KeyPressed'}},
        TakePills = {Toggle = true, Keys = {VK_F12}, Type = {'KeyPressed'}},
        AcceptDeath = {Toggle = true, Keys = {VK_OEM_PLUS}, Type = {'KeyPressed'}},
        RequestBackup = {Toggle = true, Keys = {VK_MENU, VK_B}, Type = {'KeyDown', 'KeyPressed'}},
        Reconnect = {Toggle = true, Keys = {VK_SHIFT, VK_0}, Type = {'KeyDown', 'KeyPressed'}},
        UsePot = {Toggle = true, Keys = {VK_F2}, Type = {'KeyPressed'}},
        UseCrack = {Toggle = true, Keys = {VK_F3}, Type = {'KeyPressed'}},
        ReloadWeapon = {Toggle = false, Keys = {VK_R}, Type = {'KeyPressed'}}
    }
}

local autobind = configs.deepCopy(autobind_defaultSettings)

-- Horizon Server Health
local hzrpHealth = 5000000

local guardTime = 12.0
local ddguardTime = 6.0

local timers = {
	Vest = {timer = guardTime, last = 0, sentTime = 0, timeOut = 5.0},
	Accept = {timer = 0.5, last = 0},
	Heal = {timer = 13.0, last = 0},
	Find = {timer = 20.0, last = 0, sentTime = 0, timeOut = 5.0},
	Muted = {timer = 13.0, last = 0},
	Binds = {timer = 0.5, last = {}},
    Capture = {timer = 1.5, last = 0, sentTime = 0, timeOut = 5.0},
    Sprunk = {timer = 0.2, last = 0},
    Point = {timer = 180.0, last = 0},
    AFK = {timer = 90.0, last = 0, sentTime = 0, timeOut = 5.0},
    Pause = {timer = 2.5, last = 0}
}

local lastKeybindTime = 0
local keyBindDelay = 1.5

local PausedLength = 0

local accepter = {
	enable = false,
	received = false,
	playerName = "",
	playerId = -1,
    distance = 0,
    price = 0,
    thread = nil
}

local bodyguard = {
    enable = true,
	received = false,
	playerName = "",
	playerId = -1,
    price = 0
}

local autofind ={
	enable = false,
    received = false,
	playerName = "",
	playerId = -1,
    counter = 0,
    location = ""
}

local backup = {
    enable = false,
    playerName = "",
    playerId = -1,
    location = ""
}

local farmer = {
    farming = false,
    harvesting = false,
    harvestingCount = 0
}

local wanted = {
    wantedTypes = {"disconnected", "lawyer", "processed", "cleared"},
    lawyer = true,
    received = false,
}

local wantedRefreshCount = 0
local last_wanted = 0

local autoCapture = false
local usingSprunk = false
local currentRadio = 0
local factionChargeReporter = nil
local factionArrestReporter = nil

local dialogs = {
    farmer = {
        id = 22272,
        id2 = 22273
    },
    radio = {
        id = 22274
    },
    weather = {
        id = 22275
    },
    time = {
        id = 22276
    }
}

local vehicles = {
    populating = false,
    spawning = false,
    currentIndex = -1,
    initialFetch = false
}

local statusVehicleColors = {
    Stored = imguiRGBA["REALRED"],
    Spawned = imguiRGBA["REALGREEN"],
    Occupied = imguiRGBA["YELLOW"],
    Damaged = imguiRGBA["ORANGE"],
    Disabled = imguiRGBA["RED"],
    Impounded = imguiRGBA["GREEN"]
}

local names = {}

local family = {
    turfColor = 0x8C0000FF, -- Active Turf Color (Flashing)
    skins = {},
    gzData = nil,
    enteredPoint = false,
    preventHealTimer = false
}

local factionData = {
    LSPD = {
        enabled = true,
        skins = {
            266, 267, 280, 281, 282, 283, 284, 285, 288, 300, 301, 302, 306, 307, 309, 310, 311
        },
        color = clr_TEAM_BLUE_COLOR,
        ranks = {
            [1] = "Cadet",
            [2] = "Officer",
            [3] = "Corporal",
            [4] = "Sergeant",
            [5] = "Lieutenant",
            [6] = "Captain",
            [7] = "Chief"
        }
    },
    ARES = {
        enabled = true,
        skins = {
            61, 71, 73, 163, 164, 165, 166, 179, 191, 206, 287
        },
        color = clr_ARES,
        ranks = {
            [1] = "Recruit",
            [2] = "Operative",
            [3] = "Specialist",
            [4] = "Staff Sergeant",
            [5] = "Major",
            [6] = "Vice Commander",
            [7] = "Commander"
        },
    },
    FBI = {
        enabled = true,
        skins = {
            120, 141, 253, 286, 294
        },
        color = clr_TEAM_FBI_COLOR,
        ranks = {
            [1] = "Intern",
            [2] = "Agent",
            [3] = "Special Agent",
            [4] = "Senior Agent",
            [5] = "Supervisory Agent",
            [6] = "Chief of Staff",
            [7] = "Director"
        }
    },
    GOV = {
        enabled = false,
        skins = {
            --120, 141, 253, 286, 294
        },
        color = clr_GOV,
        ranks = {
            [1] = "Chief Justice",
            [2] = "Staff",
            [3] = "Senior Staff",
            [4] = "Supervisor",
            [5] = "Judge",
            [6] = "Commissioner",
            [7] = "Senator"
        }
    },
    SASD = {
        enabled = false,
        skins = {
            265, 266, 267, 280, 281, 282, 283, 284, 285, 288, 300, 301, 302, 306, 307, 309, 310, 311
        },
        color = clr_SASD,
        ranks = {
            [1] = "Trainee",
            [2] = "Trooper",
            [3] = "Deputy",
            [4] = "Senior Deputy",
            [5] = "Chief Deputy",
            [6] = "Undersheriff",
            [7] = "Sheriff"
        }
    }
}

local factions = {
    colors = {},
    skins = {},
    names = {},
    ranks = {},
    badges = {}
}

local extraBadges = {
    [clr_WHITE] = "No Badge",
    [clr_TEAM_MED_COLOR] = "LSFMD",
    [clr_TEAM_NEWS_COLOR] = "SANEWS",
    [clr_DD] = "DD",
    [clr_YELLOW] = "PB",
    [clr_TWRED] = "MW",
    [clr_ORANGE] = "Prisoner"
}

for name, faction in pairs(factionData) do
    if faction.enabled then
        factions.colors[faction.color] = true

        for _, skinId in pairs(faction.skins) do
            factions.skins[skinId] = true
        end

        table.insert(factions.names, name)
        factions.ranks[name] = faction.ranks
        factions.badges[faction.color] = name
    end
end

local lockers = {
    maxKits = 6,
    BlackMarket = {
        name = "Black Market",
        command = "/bm",
        isBindActive = false,
        isProcessing = false,
        maxSelections = 6,
        getItemFrom = 0,
        gettingItem = false,
        currentKey = nil,
        obtainedItems = {},
        thread = nil,
        Items = {
            [1] = {label = 'Health/Armor', index = 2, weapon = nil, price = 350},
            [2] = {label = 'Silenced', index = 6, weapon = 23, price = 150, group = 2, priority = 1},
            [3] = {label = '9mm', index = 7, weapon = 22, price = 200, group = 2, priority = 2},
            [4] = {label = 'Deagle', index = 13, weapon = 24, price = 1000, group = 2, priority = 3},
            [5] = {label = 'Shotgun', index = 8, weapon = 25, price = 400, group = 3, priority = 1},
            [6] = {label = 'Spas-12', index = 16, weapon = 27, price = 2250, group = 3, priority = 2},
            [7] = {label = 'MP5', index = 9, weapon = 29, price = 550, group = 4, priority = 3},
            [8] = {label = 'UZI', index = 10, weapon = 28, price = 700, group = 4, priority = 2},
            [9] = {label = 'Tec-9', index = 11, weapon = 32, price = 700, group = 4, priority = 1},
            [10] = {label = 'Country Rifle', index = 12, weapon = 33, price = 850, group = 6, priority = 1},
            [11] = {label = 'Sniper Rifle', index = 17, weapon = 34, price = 3850, group = 6, priority = 2},
            [12] = {label = 'AK-47', index = 14, weapon = 30, price = 1400, group = 5, priority = 1},
            [13] = {label = 'M4', index = 15, weapon = 31, price = 1400, group = 5, priority = 2}
        },
        ExclusiveGroups = {
            [1] = {2, 3, 4},  -- Handguns: Silenced, 9mm, Deagle
            [2] = {5, 6},    -- Shotguns: Shotgun, Spas-12
            [3] = {7, 8, 9},  -- SMGs: MP5, UZI, Tec-9
            [4] = {10, 11},    -- Rifles: Country Rifle, Sniper Rifle
            [5] = {12, 13}    -- Assault Rifles: AK-47, M4
        },
        combineGroups = {
            {2, 3, 4},
            {5, 6},
            {7, 8, 9},
            {10, 11},
            {12, 13}
        }
    },
    FactionLocker = {
        name = "Faction Locker",
        command = "/locker",
        isBindActive = false,
        isProcessing = false,
        maxSelections = 6,
        getItemFrom = 0,
        gettingItem = false,
        currentKey = nil,
        obtainedItems = {},
        thread = nil,
        Items = {
            [1] = {label = 'Deagle', index = 0, weapon = 24, price = nil},
            [2] = {label = 'Shotgun', index = 1, weapon = 25, price = nil, group = 3, priority = 1},
            [3] = {label = 'SPAS-12', index = 2, weapon = 27, price = 2250, group = 3, priority = 2}, -- ARES: 3200
            [4] = {label = 'MP5', index = 3, weapon = 29, price = 150}, -- ARES: 250
            [5] = {label = 'M4', index = 4, weapon = 31, price = 1400, group = 5, priority = 2}, -- ARES: 2100
            [6] = {label = 'AK-47', index = 5, weapon = 30, price = 1400, group = 5, priority = 1}, -- ARES: 2100
            [7] = {label = 'Teargas', index = 6, weapon = 17, price = nil},
            [8] = {label = 'Camera', index = 7, weapon = 43, price = nil},
            [9] = {label = 'Sniper', index = 8, weapon = 34, price = 4550}, -- ARES: 5500
            [10] = {label = 'Armor', index = 9, weapon = nil, price = nil},
            [11] = {label = 'Health', index = 10, weapon = nil, price = nil},
            [12] = {label = 'Baton/Mace', index = 11, weapon = nil, price = nil}
        },
        ExclusiveGroups = {
            [1] = {2, 3},  -- Group 1: Shotgun, SPAS-12
            [2] = {5, 6},  -- Group 2: M4, AK-47
            [3] = {8, 12} -- Group 3: Camera, Baton/Mace
        },
        combineGroups = {
            {1, 4, 9}, -- Deagle, MP5, Sniper
            {2, 3}, -- Shotgun, SPAS-12
            {5, 6}, -- M4, AK-47
            {10, 11}, -- Health, Armor
            {7, 8} -- Teargas, Camera
        }
    }
}

local lockerVars = {}
for var, locker in pairs(lockers) do
    if var ~= "maxKits" then
        lockerVars[locker.name] = var
    end
end

local myFonts = {}
local dragState = {}
local flagValues = {
    BOLD = 0x1, 
    ITALICS = 0x2,
    BORDER = 0x4, 
    SHADOW = 0x8,
    UNDERLINE = 0x10,
    STRIKEOUT = 0x20
}

local updateStatus = "up_to_date"
local currentContent = nil
local isUpdateHovered = false

local menu = {
    Initialized = new.bool(false),
    Confirm = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function() return ("%s - Update %s"):format(shortName:upper(), currentContent.version or "Unknown") end,
        window = new.bool(false),
        size = {x = 300, y = 100},
        pivot = {x = 0.5, y = 0.5},
        update = new.bool(false)
    },
	Settings = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function() 
            return ("{%06x}%s{%06x} %s - v%s - Type '{%06x}/ab help{%06x}' for more info."):format(clr_GREEN, fa.ICON_FA_CANNABIS, clr_WHITE, shortName:upper(), scriptVersion, clr_GREY, clr_WHITE) 
        end,
		window = new.bool(false),
        size = {x = 588, y = 410},
        pivot = {x = 0.5, y = 0.5},
		pageId = 1,
        dragging = new.bool(true)
	},
    VehicleStorage = {
        title = function() 
            if autobind.CurrentPlayer.name ~= "" then
                local vehicles = autobind.VehicleStorage.Vehicles[autobind.CurrentPlayer.name]
                local spawnedVehicles = 0
                for _, vehicle in pairs(vehicles) do
                    if vehicle.status == "Spawned" or vehicle.status == "Occupied" or vehicle.status == "Damaged" then
                        spawnedVehicles = spawnedVehicles + 1
                    end
                end

                local freeSlots = 20 - #vehicles
                return ("%s - Vehicle Storage [%s/4] - (Slots Available: %s)"):format(shortName:upper(), spawnedVehicles, 20 - #vehicles) 
            else
                return ("%s - Vehicle Storage"):format(shortName:upper()) 
            end
        end,
        flags = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove,
		window = new.bool(false),
        size = {x = 338, y = 165},
        dragging = new.bool(false)
    },
    Charges = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function() return ("{%06x}%s{%06x} %s - Charges"):format(clr_GREEN, fa.ICON_FA_CANNABIS, clr_WHITE, shortName:upper()) end,
		window = new.bool(false),
        size = {x = 575, y = 420},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(true)
    },
	Names = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function() return ("{%06x}%s{%06x} %s - Name Settings"):format(clr_GREEN, fa.ICON_FA_CANNABIS, clr_WHITE, shortName:upper()) end,
		window = new.bool(false),
        size = {x = 494, y = 154},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(true)
	},
	Skins = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function() return ("{%06x}%s{%06x} %s - %s Skins"):format(clr_GREEN, fa.ICON_FA_CANNABIS, clr_WHITE, shortName:upper(), autobind.Settings.mode or "Unknown") end,
		window = new.bool(false),
        size = {x = 472, y = 395},
        pivot = {x = 0.5, y = 0.5},
		selected = -1,
        dragging = new.bool(true)
	},
	BlackMarket = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function(label, pageId, totalPrice) return string.format("%s - Kit: %d - $%s", label, pageId, formatNumber(totalPrice)) end,
		window = new.bool(false),
        size = {x = 226, y = 285},
        pivot = {x = 0.5, y = 0.5},
        pageId = 1,
        dragging = new.bool(true)
	},
	FactionLocker = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function(label, pageId, totalPrice) return string.format("%s - Kit: %d - $%s", label, pageId, formatNumber(totalPrice)) end,
		window = new.bool(false),
        size = {x = 226, y = 285},
        pivot = {x = 0.5, y = 0.5},
        pageId = 1,
        dragging = new.bool(true)
	},
	Changelog = {
        flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar,
        title = function() 
            return ("{%06x}%s{%06x} %s - Script: v%s - Latest: v%s - Last: v%s - Updated: %s - Updated By: %s"):format(clr_GREEN, fa.ICON_FA_CANNABIS, clr_WHITE, shortName:upper(), scriptVersion, currentContent.version or "Unknown", currentContent.lastversion or "Unknown", currentContent.date or "Unknown", currentContent.updatedBy or "Unknown")
        end,
		window = new.bool(false),
        size = {x = 650, y = 400},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(true)
	},
    Wanted = {
        flags = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove,
        title = "Wanted List",
        window = new.bool(true),
    }
}

local fontData = {
    x2large = {
        size = 18.0,
        font = nil
    },
    xlarge = {
        size = 16.0,
        font = nil
    },
    large = {
        size = 14.0,
        font = nil
    },
    medium = {
        size = 12.0,
        font = nil
    },
    small = {
        size = 10.0,
        font = nil
    },
    xsmall = {
        size = 8.0,
        font = nil
    }
}

local menuStates = {
    Settings = menu.Settings.window,
    Charges = menu.Charges.window,
    Names = menu.Names.window,
    Skins = menu.Skins.window,
    BlackMarket = menu.BlackMarket.window,
    FactionLocker = menu.FactionLocker.window,
    VehicleStorage = menu.VehicleStorage.window,
    Confirm = menu.Confirm.window,
    Changelog = menu.Changelog.window
}

local previousMenuStates = {
    Settings = false,
    Charges = false,
    Names = false,
    Skins = false,
    BlackMarket = false,
    FactionLocker = false,
    VehicleStorage = false,
    Confirm = false,
    Changelog = false
}

local escapePressed = false
local skinTextures = {}
local skinsUrls = {}

local changeKey = {}
local keyEditors = {
    {label = "Accept", key = "Accept", description = "Accepts a vest from someone. (Options are in Bodyguard Tab)"},
    {label = "Offer", key = "Offer", description = "Offers a vest to someone. (Options are in Bodyguard Tab)"},
    {label = "Request Backup", key = "RequestBackup", description = "Types the backup command depending on what mode is detected"},
    {label = "Use Crack", key = "UseCrack", description = "Types /usecrack."},
    {label = "Use Pot", key = "UsePot", description = "Types /usepot."},
    {label = "Accept-Death", key = "AcceptDeath", description = "Types /acceptdeath."},
    {label = "Bike-Bind", key = "BikeBind", description = "Makes bikes/motorcycles/quads faster by holding the bind key while riding."},
    {label = "Sprint-Bind", key = "SprintBind", description = "Makes you sprint faster by holding the bind key while sprinting. (This is only the toggle)"},
    {label = "Frisk", key = "Frisk", description = "Frisks a player. (Options are in Autobind Tab)"},
    {label = "Take-Pills", key = "TakePills", description = "Types /takepills."},
    {label = "Reload Weapon", key = "ReloadWeapon", description = "Reloads your weapon."}
}

local ignoreKeysMap = {
    AutoVest = {"skins", "names"},
    Keybinds = {"BikeBind", "SprintBind", "Frisk", "TakePills", "Accept", "Offer", "AcceptDeath", "RequestBackup", "UseCrack", "UsePot"},
    BlackMarket = {"Locations"},
    FactionLocker = {"Locations"},
    VehicleStorage = {"Vehicles"},
    Elements = {"OfferedTo", "OfferedFrom", "PedsCount", "AutoFind", "LastBackup", "FactionBadge"},
    --WindowPos = {"Settings", "VehicleStorage", "Skins", "Keybinds", "Names", "BlackMarket", "FactionLocker", "Changelog"},
    Wanted = {"List", "Pos", "Pivot", "Padding"},
    Charges = {"List"}
}

for kitId = 1, lockers.maxKits do
    table.insert(ignoreKeysMap.Keybinds, "BlackMarket" .. kitId)
    table.insert(ignoreKeysMap.BlackMarket, "Kit" .. kitId)
    table.insert(ignoreKeysMap.Keybinds, "FactionLocker" .. kitId)
    table.insert(ignoreKeysMap.FactionLocker, "Kit" .. kitId)
end

-- Dynamically create config paths
local sections = {}
for section, _ in pairs(autobind) do
    table.insert(sections, section)
end

for _, section in pairs(sections) do
    local name = section:lower()
    Files[name] = Paths.settings .. name .. '.json'
end

function loadAllConfigs()
    for _, section in ipairs(sections) do
        local ignoreKeys = ignoreKeysMap[section] or {}
        local success, config, err = configs.handleConfigFile(Files[section:lower()], autobind_defaultSettings[section], autobind[section], ignoreKeys)
        if not success then
            print("Failed to handle config file for " .. section .. ": " .. err)
            return
        end
        autobind[section] = configs.deepCopy(config)
    end
end

function saveAllConfigs()
    for _, section in ipairs(sections) do
        local success, err = configs.saveConfigWithErrorHandling(Files[section:lower()], autobind[section])
        if not success then
            print("Failed to save config file for " .. section .. ": " .. err)
        end
    end
end

-- C Definitions
ffi.cdef[[
	// Gangzone
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

function initializeComponents()
    -- Check if update is in progress and check update status
    if autobind.Settings.updateInProgress then
        formattedAddChatMessage(("You have successfully upgraded from Version: %s to %s"):format(autobind.Settings.lastVersion, scriptVersion))
        autobind.Settings.updateInProgress = false
        configs.saveConfigWithErrorHandling(Files.settings, autobind.Settings)
    end

    updateCheck()

    -- Set autovest timer based on donor status
    timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime

    -- Fetch Skins and Names
    if autobind.AutoVest.autoFetchSkins then
        fetchJsonDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
            debugMessage("Skins fetched successfully!", true, true)
            mimtoasts.Show("Skins fetched successfully!", 1, 4)
            if decodedData then
                autobind.AutoVest.skins = decodedData
                family.skins = table.listToSet(autobind.AutoVest.skins)
            end
        end)
    else
        family.skins = table.listToSet(autobind.AutoVest.skins)
    end

    if autobind.AutoVest.autoFetchNames then
        fetchJsonDataDirectlyFromURL(autobind.AutoVest.namesUrl, function(decodedData)
            debugMessage("Names fetched successfully!", true, true)
            mimtoasts.Show("Names fetched successfully!", 1, 4)
            if decodedData then
                autobind.AutoVest.names = decodedData
                names = table.listToSet(autobind.AutoVest.names)
            end
        end)
    else
        names = table.listToSet(autobind.AutoVest.names)
    end

    fetchJsonDataDirectlyFromURL(Urls.charges, function(decodedData)
        debugMessage("Charges fetched successfully!", true, true)
        mimtoasts.Show("Charges fetched successfully!", 1, 4)
        chargeList = decodedData or nil
    end)

    fetchJsonDataDirectlyFromURL(Urls.betatesters, function(decodedData)
        debugMessage("Betatesters fetched successfully!", true, false)
        mimtoasts.Show("Betatesters fetched successfully!", 1, 4)
        betatesters = decodedData or nil
    end)

    fetchJsonDataDirectlyFromURL(Urls.changelog, function(decodedData)
        debugMessage("Changelog fetched successfully!", true, false)
        mimtoasts.Show("Changelog fetched successfully!", 1, 4)
        changelog = decodedData or nil
    end)

    -- Startup Timers
    local currentTime = os.clock()
    for name, timer in pairs(timers) do

        if name == "Pause" then
            timer.last = currentTime
        end

        if timer.timer and type(timer.last) == "number" and name ~= "AFK" then
            timer.last = currentTime - timer.timer
        end
        if timer.sendTime and type(timer.sentTime) == "number" then
            timer.sentTime = currentTime - timer.timeOut
        end
    end

    -- Setup Skins
    skinsUrls = generateSkinsUrls()
    downloadSkins(skinsUrls)

    -- Turn radio on/off and set favorite radio
    lua_thread.create(function()
        if isCharInAnyCar(ped) and not autobind.Settings.noRadio then
            setRadioChannel(12)
            wait(1000)
        end

        toggleRadio(autobind.Settings.noRadio)

        if autobind.Settings.noRadio then
            wait(1000)
            setRadioChannel(autobind.Settings.favoriteRadio or 0)
        end
    end)

    -- Setup Locker Keybinds
    for _, name in pairs(lockerVars) do
        InitializeLockerKeyFunctions(name, lockers[name].name, lockers[name].command, autobind[name].maxKits)
    end

    if autobind.TimeAndWeather.modifyWeather then
        setWeather(autobind.TimeAndWeather.weather)
    end

    if autobind.TimeAndWeather.modifyTime then
        setTime(autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute)
    end

    if autobind.CurrentPlayer.welcomeMessage then
        initializeVehicleStorage()
    end

    -- Initialize Menu
    menu.Initialized[0] = true
end

function debugMessage(message, showChat, showPrint)
    if autobind.Settings.enableDebugMessages then
        if showChat then
            formattedAddChatMessage(message)
        end

        if showPrint then
            print(message)
        end
    end
end

local hasPlayerLoaded = false

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end

	-- Create Directories and load all configs
    for _, path in pairs({Paths.libraries, Paths.config, Paths.resource, Paths.settings, Paths.skins, Paths.fonts}) do
        createDirectory(path)
    end

	loadAllConfigs()

    while not isSampAvailable() do wait(100) end

    -- Create Chat Commands and Fonts
    registerAutobindCommands()
    registerClientCommands()
    createFonts()

    sampRegisterChatCommand("checkafk", function()
        formattedAddChatMessage(string.format("You were afk for %0.2f seconds.", PausedLength))
    end)

    sampRegisterChatCommand("spectest", function()
        if specData.id ~= -1 and specData.name ~= "" and specData.state then
            formattedAddChatMessage(string.format("Spectating %s (ID: %d)", specData.name, specData.id))
        else
            formattedAddChatMessage("Not spectating anyone.")
        end
    end)

    sampRegisterChatCommand("test", function()
        menu.Confirm.update[0] = true
        menu.Confirm.window[0] = true
    end)
    
    while true do wait(0)
        if sampGetGamestate() ~= 3 then
            if not hasPlayerLoaded then
                resetAccepterAndBodyguard()

                clearWantedList()

                autobind.CurrentPlayer.welcomeMessage = false
                print("Player has disconnected")

                hasPlayerLoaded = true
            end
        end

        if sampGetGamestate() == 3 and (isCharOnFoot(ped) or isCharInWater(ped) or isCharInAnyCar(ped)) then
            if hasPlayerLoaded then
                hasPlayerLoaded = false
                print("Player is on foot or in water and in game")
            end
        end

        -- Reset Locker Processing if player is not in location
        for _, name in pairs(lockerVars) do
            resetLockerProcessing(name, autobind[name].Locations)
        end

        -- Get Radio Channel if player is in a vehicle
        if isCharInAnyCar(ped) then
            currentRadio = getRadioChannel()
        end

        cursorActive = sampIsCursorActive()
        chatInputActive = sampIsChatInputActive()

        if autobind.VehicleStorage.enable and autobind.VehicleStorage.menu and (autobind.VehicleStorage.chatInputText or autobind.VehicleStorage.chatInput) then
            local showVehicleStorage = false
            
            if autobind.VehicleStorage.chatInputText and sampGetChatInputText():find("/v") then
                showVehicleStorage = true
            end
            
            if autobind.VehicleStorage.chatInput and chatInputActive then
                showVehicleStorage = true
            end
            
            menu.VehicleStorage.window[0] = showVehicleStorage
        end

        functionsLoop(function(success)
            initializeComponents()

            formattedAddChatMessage(("%s has loaded successfully! {%06x}Type /%s help for more information."):format(scriptVersion, clr_GREY, shortName))
            for name, success in pairs(success) do
                if not success then
                    formattedAddChatMessage(("Failed to load %s!"):format(name), clr_RED)
                end
            end
        end)
    end
end

function resetAccepterAndBodyguard()
    if accepter.playerName ~= "" and accepter.playerId ~= -1 then
        accepter.playerName = ""
        accepter.playerId = -1
    end
    if bodyguard.playerName ~= "" and bodyguard.playerId ~= -1 then
        bodyguard.playerName = ""
        bodyguard.playerId = -1
    end
end

local function checkAnimationCondition(playerId)
    local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
    local pAnimId2 = sampGetPlayerAnimationId(playerId)
    return not (invalidAnimsSet[pAnimId] or pAnimId2 == 746 or isButtonPressed(h, gkeys.player.LOCKTARGET))
end

local function vestModeConditions(playerId, playerName, playerColor, skinId)
    -- Check if vesting is allowed for everyone
    if autobind.AutoVest.everyone then
        return true
    end

    -- Check if the player's name is in the priority names list
    if autobind.AutoVest.useNames and names[playerName] then
        return true
    end

    -- Check conditions based on the current mode
    local mode = autobind.Settings.mode
    if mode == "Family" then
        return family.skins[skinId] ~= nil
    elseif mode == "Faction" then
        return factions.colors[colors.changeAlpha(playerColor, 0)] and (not autobind.AutoVest.useSkins or factions.skins[skinId]) ~= nil
    end

    return false
end

function checkAndSendVest(skipArmorCheck)
    local currentTime = os.clock()
    if not autobind.AutoVest.autoGuard and not autobind.AutoVest.guardFeatures and not skipArmorCheck then
        return false, nil
    end

    if isPlayerAFK then
        return false, "You cannot send a vest while AFK, move your character."
    end

    if checkAdminDuty() then
        return false, "You are on admin duty, you cannot send a vest."
    end

    if not isPlayerControlOn(h) then
        return false, "You cannot send a vest while frozen, please wait."
    end

    if not (bodyguard.enable or autobind.AutoVest.donor) then
        return false, "You cannot send a vest while not a bodyguard."
    end

    if checkMuted() then
        return false, "You cannot send a vest while muted, please wait."
    end

    if bodyguard.received then
        if currentTime - timers.Vest.sentTime > timers.Vest.timeOut then
            bodyguard.received = false
        else
            return false, "Vest has been sent, please wait."
        end
    end

    if (currentTime - timers.Vest.last) < timers.Vest.timer then
        local timeLeft = math.ceil(timers.Vest.timer - (currentTime - timers.Vest.last))
        return false, string.format("You must wait %d seconds before sending vest.", timeLeft > 1 and timeLeft or 1)
    end

    if not bodyguard.received then
        for _, player in ipairs(getVisiblePlayers(7, skipArmorCheck and "all" or "armor")) do
            if checkAnimationCondition(player.playerId) and vestModeConditions(player.playerId, player.playerName, player.playerColor, player.skinId) then
                debugMessage(string.format("Player: %s (ID: %d) - Color: 0x%X - Skin: %d", player.playerName, player.playerId, player.playerColor, player.skinId), true, true)
                sampSendChat(autobind.AutoVest.donor and '/guardnear' or string.format("/guard %d %d", player.playerId, autobind.AutoVest.price))
                bodyguard.received = true
                timers.Vest.sentTime = currentTime
                return true, nil
            end
        end
        return false, "No suitable players found to vest, please try again."
    end
end

function checkAndAcceptVest(allowAutoAccept)
	local currentTime = os.clock()
	if currentTime - timers.Accept.last < timers.Accept.timer then
		return false, nil
	end

    if not autobind.AutoVest.acceptFeatures then
        return false, nil
    end

    if isPlayerAFK then
        return false, "You cannot accept a vest while AFK, move your character."
    end

    if checkAdminDuty() then
        return false, "You are on admin duty, you cannot accept a vest."
    end

	if checkMuted() then
		return false, "You cannot accept a vest while muted, please wait."
	end

	if checkHeal() then
		local timeLeft = math.ceil(timers.Heal.timer - (currentTime - timers.Heal.last))
		return false, string.format("You must wait %d seconds before accepting a vest.", timeLeft > 1 and timeLeft or 1)
	end

	if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
		for _, player in ipairs(getVisiblePlayers(5, "all")) do
			if allowAutoAccept and accepter.received then
				if player.playerName == accepter.playerName then
					sampSendChat("/accept bodyguard")
					timers.Accept.last = currentTime
					return true
				end
			end
		end

        local message = "No one has offered you bodyguard."
        local sameZone = false
        if accepter.received and accepter.playerName and accepter.playerId then
            for _, player in ipairs(getVisiblePlayers(40.0, "all")) do
                if player.playerName == accepter.playerName then
                    accepter.distance = player.distance
                    sameZone = true
                    break
                end
            end
            local zoneMessage = sameZone and string.format(" - Dist: %d.", accepter.distance) or ""
            message = string.format("You are not close enough to %s (%d).%s", accepter.playerName:gsub("_", " "), accepter.playerId, zoneMessage)
        end

        return false, message
	else
		return false, "You are already have a vest."
	end
end

function isPlayerInLocation(locations)
    -- Adjustable Z axis limits
    local zTopLimit = 0.7 
    local zBottomLimit = -0.7 

    -- Get player coordinates
    local playerX, playerY, playerZ = getCharCoordinates(ped)

    -- Check if player is in any of the locations
    for _, location in pairs(locations) do
        local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, location.x, location.y, location.z)
        local zDifference = playerZ - location.z
        if distance <= location.radius and zDifference <= zTopLimit and zDifference >= zBottomLimit then
            return true
        end
    end
    return false
end

function playerHasItem(item)
    if item.weapon then -- Check if item is a weapon
        return hasCharGotWeapon(ped, item.weapon)
    elseif item.label == 'Baton/Mace' then -- Check if item is a baton and mace
        return hasCharGotWeapon(ped, 3) and hasCharGotWeapon(ped, 41)
    elseif item.label == 'Health' then -- Check full health
        return getCharHealth(ped) - hzrpHealth == 100
    elseif item.label == 'Armor' then -- Check full armor
        return getCharArmour(ped) == 100
    elseif item.label == 'Health/Armor' then -- Check full health and armor
        local health = getCharHealth(ped) - hzrpHealth
        local armor = getCharArmour(ped)
        return health == 100 and armor == 100
    end
    return false
end

function canObtainItem(item, items)
    -- Check if player already has item
    if playerHasItem(item) then
        return false
    end

    -- Check if item is a weapon and has a group and priority
    if item.weapon and item.group and item.priority then
        for _, value in pairs(items) do
            if item.group == value.group and item.priority <= value.priority then
                if hasCharGotWeapon(ped, value.weapon) then
                    return false
                end
            end
        end
    end

    return true
end

function resetLocker(name)
    lockers[name].getItemFrom = 0
    lockers[name].gettingItem = false
    lockers[name].currentKey = nil
    lockers[name].obtainedItems = {}
end

function resetLockerProcessing(name, locations)
    if lockers[name].isProcessing and not isPlayerInLocation(locations) then
        lockers[name].isProcessing = false
        formattedAddChatMessage(string.format("You left the %s area while getting items. Please retrieve items again.", lockers[name].name:lower()))

        if lockers[name].thread then
            lockers[name].thread:terminate()
        end

        lua_thread.create(function()
            wait(1000)
            lockers[name].isBindActive = false
        end)
    end
end

function handleLocker(kitNumber, name, label, command)
    if lockers[name].isBindActive then
        return false
    end

    lockers[name].isBindActive = true

    if lockers[name].isProcessing then
        formattedAddChatMessage(("You are already getting items from %s, please wait."):format(label), clr_YELLOW)
        lockers[name].isBindActive = false
        return false
    end

    if checkMuted() then
        formattedAddChatMessage("You have been muted for spamming, please wait.", clr_YELLOW)
        lockers[name].isBindActive = false
        return false
    end

    if not isPlayerInLocation(autobind[name].Locations) then
        formattedAddChatMessage(("You are not at the %s!"):format(label), clr_GREY)
        lockers[name].isBindActive = false
        return false
    end

    if not isPlayerControlOn(h) then
        formattedAddChatMessage("You cannot get items while frozen, please wait.", clr_YELLOW)
        lockers[name].isBindActive = false
        return false
    end

    if checkHeal() then
        local timeLeft = math.ceil(timers.Heal.timer - (os.clock() - timers.Heal.last))
        formattedAddChatMessage(string.format("You must wait %d seconds before getting items.", timeLeft > 1 and timeLeft or 1))
        lockers[name].isBindActive = false
        return false
    end

    -- Check if the player can afford the kit
    local kitItems = autobind[name]["Kit" .. kitNumber]
    local money = getPlayerMoney()
    local totalPrice = calculateTotalPrice(kitItems, lockers[name].Items)
    if totalPrice and money < totalPrice and totalPrice ~= 0 then
        formattedAddChatMessage(("You do not have enough money to buy this kit, you need $%s more. Total price: $%s."):format(
            formatNumber(totalPrice - money), 
            formatNumber(totalPrice)), 
        clr_YELLOW)
        lockers[name].isBindActive = false
        return false
    end

    resetLocker(name)

    if lockers[name].thread then
        lockers[name].thread:terminate()
    end

    lockers[name].isProcessing = true
    lockers[name].getItemFrom = kitNumber

    lockers[name].thread = lua_thread.create(function()
        -- Check for what items are needed
        local neededItems = {}
        local skippedItems = {}
        for _, itemIndex in ipairs(kitItems) do
            local item = lockers[name].Items[itemIndex]
            if item then
                if canObtainItem(item, lockers[name].Items) then
                    table.insert(neededItems, item)
                else
                    table.insert(skippedItems, item.label)
                end
            end
        end

        -- Start getting items
        for i, item in ipairs(neededItems) do
            if not lockers[name].isProcessing then
                return false
            end

            if i == 1 then
                formattedAddChatMessage(string.format(
                    "Getting items from %s (Kit #%d). {%06x}Please stop moving and do not use any other commands.",
                    label,
                    kitNumber,
                    clr_YELLOW
                ), clr_WHITE)
            end

            lockers[name].currentKey = item.index
            lockers[name].gettingItem = true
            sampSendChat(command)
            
            repeat wait(0) until not lockers[name].gettingItem
            
            table.insert(lockers[name].obtainedItems, item.label)

            if (i % 3 == 0) and (i < #neededItems) then
                local waitTime = math.random(1500, 1750)
                
                local stillNeeded = {}
                for j = i + 1, #neededItems do
                    table.insert(stillNeeded, neededItems[j].label)
                end

                formattedAddChatMessage(string.format(
                    "You are still getting %d items from %s, please wait %0.1f seconds.",
                    (#neededItems - i),
                    label:lower(),
                    waitTime / 1000
                ), clr_YELLOW)

                formattedAddChatMessage(string.format("Items left: {%06x}%s", clr_WHITE, table.concat(stillNeeded, ", ")), clr_YELLOW)
                
                wait(waitTime)
            end
            wait(200)
        end

        -- Check if items were obtained
        if #lockers[name].obtainedItems > 0 then
            formattedAddChatMessage(string.format("Obtained items: {%06x}%s.", clr_WHITE, table.concat(lockers[name].obtainedItems, ", ")), clr_YELLOW)
        end
        
        -- Check if items were skipped
        if #skippedItems > 0 then
            formattedAddChatMessage(string.format("Skipped items: {%06x}%s.", clr_WHITE, table.concat(skippedItems, ", ")), clr_REALRED)
        end

        -- Reset processing and locker
        lockers[name].isProcessing = false
        lockers[name].isBindActive = false
        resetLocker(name)

        wait(1500)

        -- Verify items are actually in the player's possession now
        local notObtained = {}
        for _, item in ipairs(neededItems) do
            if canObtainItem(item, lockers[name].Items) then
                table.insert(notObtained, item.label)
            end
        end

        -- If anything is still missing, notify the player
        if #notObtained > 0 then
            formattedAddChatMessage(("The following items were not successfully fetched (due to lag or other issues): {%06x}%s"):format(
                clr_REALRED,
                table.concat(notObtained, ", ")
            ), clr_YELLOW)
        end
    end)
end

local keyFunctions = {
    Accept = function()
        local success, message = checkAndAcceptVest(true)
        if message then
            formattedAddChatMessage(message)
        end
    end,
    Offer = function()
        local success, message = checkAndSendVest(true)
        if message then
            formattedAddChatMessage(message)
        end
    end,
    BikeBind = function()
        if not isCharOnAnyBike(ped) or not autobind.Keybinds.BikeBind.Toggle then
            goto skipBikeBind
        end

        local veh = storeCarCharIsInNoSave(ped)
        if isCarInAirProper(veh) or getCarSpeed(veh) < 0.1 then
            goto skipBikeBind
        end

        local model = getCarModel(veh)
        if bikeIds[model] then
            local vehKey = gkeys.vehicle.ACCELERATE
            setGameKeyState(vehKey, 255)
            wait(0)
            setGameKeyState(vehKey, 0)
        elseif motoIds[model] then
            local vehKey = gkeys.vehicle.STEERUP_STEERDOWN
            setGameKeyState(vehKey, -128)
            wait(0)
            setGameKeyState(vehKey, 0)
        end

        ::skipBikeBind::
    end,
    SprintBind = function()
        autobind.Keybinds.SprintBind.Toggle = toggleBind("SprintBind", autobind.Keybinds.SprintBind.Toggle)
        autobind.Settings.sprintBind = autobind.Keybinds.SprintBind.Toggle
    end,
    Frisk = function()
        if checkAdminDuty() or checkMuted() then
            goto skipFrisk
        end

        local targeting = getCharPlayerIsTargeting(h)
        for _, player in ipairs(getVisiblePlayers(5, "all")) do
            if (isButtonPressed(h, gkeys.player.LOCKTARGET) and autobind.Settings.mustAimToFrisk) or not autobind.Settings.mustAimToFrisk then
                if (targeting and autobind.Settings.mustTargetToFrisk) or not autobind.Settings.mustTargetToFrisk then
                    sampSendChat(string.format("/frisk %d", player.playerId))
                    break
                end
            end
        end

        ::skipFrisk::
    end,
    TakePills = function()
        if checkAdminDuty() or checkMuted() then
            goto skipTakePills
        end

        if checkHeal() then
            formattedAddChatMessage("You can't heal after being attacked recently. You cannot take pills.")
            goto skipTakePills
        end

        sampSendChat("/takepills")

        ::skipTakePills::
    end,
    AcceptDeath = function()
        sampSendChat("/accept death")
    end,
    RequestBackup = function()
        if checkAdminDuty() or checkMuted() then
            goto skipRequestBackup
        end

        if backup.enable then
            sampSendChat("/nobackup")
            goto skipRequestBackup
        end

        local backupPrimary = autobind.Settings.mode == "Faction" and "backup" or "fbackup"
        sampSendChat(string.format("/%s", backupPrimary))

        if autobind.Settings.callSecondaryBackup then
            local x, y, z = getCharCoordinates(ped)
            local zoneName = getZoneName(x, y, z)
            local subZoneName = getSubZoneName(x, y, z)

            local backupSecondary = autobind.Settings.mode == "Faction" and "d" or "pr"
            local checkForSubZone = subZoneName == nil and zoneName or string.format("%s in %s", subZoneName, zoneName)
            sampSendChat(string.format("/%s I need urgent backup! Currently at %s.", backupSecondary, checkForSubZone))
        end

        ::skipRequestBackup::
    end,
    Reconnect = function()
        GameModeRestart()
        sampSetGamestate(1)
    end,
    UseCrack = function()
        sampSendChat("/usecrack")
    end,
    UsePot = function()
        sampSendChat("/usepot")
    end,
    ReloadWeapon = function()
        reloadWeapon()
    end
}

function reloadWeapon()
	if not sampIsCursorActive() and isPlayerPlaying(h) then
		writeMemory(getCharPointer(ped) + 1440 + readMemory(getCharPointer(ped) + 1816, 1, false) * 28 + 4, 4, 2, true)
	end
end

function InitializeLockerKeyFunctions(name, label, command, maxKits)
    for kitId = 1, maxKits do
        if keyFunctions[name .. kitId] == nil then
            keyFunctions[name .. kitId] = function()
                handleLocker(kitId, name, label, command)
            end
        end
    end
end

function resetLockersKeyFunctions()
    for kitId = 1, lockers.maxKits do
        keyFunctions["BlackMarket" .. kitId] = nil
        keyFunctions["FactionLocker" .. kitId] = nil
    end

    autobind.BlackMarket.maxKits = 3
    autobind.FactionLocker.maxKits = 3
end

function createKeybinds()
    local currentTime = os.clock()
    for key, value in pairs(autobind.Keybinds) do
        local bind = {
            keys = value.Keys,
            type = value.Type
        }

        if (key:find("FactionLocker") and (lockers.FactionLocker.isProcessing)) or 
           (key:find("BlackMarket") and (lockers.BlackMarket.isProcessing)) then
            goto skipLockerProcessing
        end

        if keycheck(bind) and (value.Toggle or key == "BikeBind" or key == "SprintBind") then
            if activeCheck(true, true, true, true, true) and not menu.Settings.window[0] then
                if key == "BikeBind" or not timers.Binds.last[key] or (currentTime - timers.Binds.last[key]) >= timers.Binds.timer then
                    local success, errorMsg = pcall(keyFunctions[key])
                    if not success then
                        formattedAddChatMessage(string.format("Error in %s function: %s", key, errorMsg), clr_YELLOW)
                    end

                    timers.Binds.last[key] = currentTime
                    -- Record the last keybind activity
                    if key ~= "BikeBind" and key ~= "Reconnect" and key ~= "SprintBind" then
                        lastKeybindTime = currentTime
                    end
                end
            end
        end

        ::skipLockerProcessing::
    end
end

function getZoneName(x, y, z)
	return getGxtText(getNameOfZone(x, y, z))
end

local subZones = {
    GAN1 = 'Grove Street', GAN2 = "Apartments", IWD1 = 'Freeway', IWD2 = 'Drug Den', IWD3A = 'Gas Station', IWD3B = 'Maximus Club',
    IWD4 = 'Ghetto Area', IWD5 = 'Pizza', LMEX1A = "South", LMEX1B = "North", ELS1A = "Crack Lab", ELS1B = "Pig Pen", ELS2 = "Apartments", 
    ELS3A = "The Court", ELS3C = "Alleyway", ELS4 = "Carwash", ELCO1 = "Unity Station", ELCO2 = "Apartments", LIND1A = "West", LIND2A = "South", LIND2B = "South", LIND3 = "East"
}

function getSubZoneName(x, y, z)
    return subZones[getNameOfInfoZone(x, y, z)] or nil
end
 
function createAutoCapture()
    if not autoCapture or checkMuted() or checkAdminDuty() then
        goto skipAutoCapture
    end

	local currentTime = os.clock()
	if currentTime - timers.Capture.last >= timers.Capture.timer then
		sampSendChat("/capturf")
		timers.Capture.last = currentTime
	end

    ::skipAutoCapture::
end

function createPointBounds()
    -- Reset data if you are not connected to a server
    if sampGetGamestate() ~= 3 then
        family.gzData = nil
        goto skipPointBounds
    end

    if not family.gzData then
        family.gzData = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
        goto skipPointBounds
    end

    if autobind.Settings.mode ~= "Family" then
        goto skipPointBounds
    end

    for i = 0, 1023 do
        if family.gzData.iIsListed[i] ~= 0 and family.gzData.pGangzone[i] ~= nil then
            local pos = family.gzData.pGangzone[i].fPosition
            local color = family.gzData.pGangzone[i].dwColor
            local ped_pos = { getCharCoordinates(ped) }
            
            local min1, max1 = math.min(pos[0], pos[2]), math.max(pos[0], pos[2])
            local min2, max2 = math.min(pos[1], pos[3]), math.max(pos[1], pos[3])
            
            if i >= 34 and i <= 45 then
                if ped_pos[1] >= min1 and ped_pos[1] <= max1 and ped_pos[2] >= min2 and ped_pos[2] <= max2 and color == family.turfColor then
                    family.enteredPoint = true
                    break
                else
                    if family.enteredPoint then
                        timers.Point.last = os.clock()
                        family.preventHealTimer = true
                    end
                    family.enteredPoint = false
                end
            end
        end
    end

    ::skipPointBounds::
end

function createAutoFind()
    if not autobind.Settings.autoFind then
        goto skipAutoFind
    end

    if not autofind.enable or checkMuted() or isPlayerAFK then
        goto skipAutoFind
    end

    -- Check if the player is frozen
    if not isPlayerControlOn(h) then
        goto skipAutoFind
    end

    if not sampIsPlayerConnected(autofind.playerId) then
        formattedAddChatMessage("The player you were finding has disconnected, you are no longer finding anyone.")
        autofind.enable = false
        goto skipAutoFind
    end

    local currentTime = os.clock()
    if autofind.received then
        if currentTime - timers.Find.sentTime > timers.Find.timeOut then
            autofind.received = false
        end
    end

    if not autofind.received then
        if currentTime - timers.Find.last >= timers.Find.timer then
            sampSendChat(string.format("/find %d", autofind.playerId))
            timers.Find.sentTime = currentTime
            autofind.received = true
        end
    end

    ::skipAutoFind::
end

function createSprunkSpam()
    -- Return if not using sprunk
    if not usingSprunk then
        goto skipSprunkSpam
    end

    if isButtonPressed(h, 15) then
        usingSprunk = false
        goto skipSprunkSpam
    end

    -- Return if already full health and drop the sprunk
    local health = getCharHealth(ped) - hzrpHealth
    if health == 100 then
        local key = gkeys.player.ENTERVEHICLE
        setGameKeyState(key, 255)
        wait(0)
        setGameKeyState(key, 0)
        usingSprunk = false
        goto skipSprunkSpam
    end
    
    -- Return if not connected
    local result, playerId = sampGetPlayerIdByCharHandle(ped)
    if not result then
        goto skipSprunkSpam
    end

    -- Return if not enough time has passed
    local currentTime = os.clock()
    if currentTime - timers.Sprunk.last < timers.Sprunk.timer then
        goto skipSprunkSpam
    end

    -- Use the sprunk
    if sampGetPlayerSpecialAction(playerId) == 23 then
        local key = gkeys.player.FIREWEAPON
        setGameKeyState(key, 255)
        wait(0)
        setGameKeyState(key, 0)
        timers.Sprunk.last = currentTime
    end

    ::skipSprunkSpam::
end

local afkKeys = {
    gkeys.player.GOLEFT_GORIGHT,
    gkeys.player.GOFORWARD_GOBACK,
    gkeys.player.ENTERVEHICLE,
    gkeys.player.SPRINT,
    gkeys.player.FIREWEAPON,
    gkeys.player.CROUCH,
    gkeys.player.LOOKBEHIND,
    gkeys.player.WALK
}

local initialAFKStart = true

function createAFKCheck()
    local currentTime = os.clock()

    -- Check if the initial AFK start condition is true
    if initialAFKStart then
        setTimer(45.0, timers.AFK)  -- Reset the timer for the next AFK check
        initialAFKStart = false
        isPlayerAFK = false
        goto skipAFKCheck
    end

    -- Check if the AFK timer has expired (player is considered AFK)
    if currentTime - timers.AFK.last >= timers.AFK.timer then
        timers.AFK.last = currentTime
        isPlayerAFK = true
        goto skipAFKCheck
    end

    -- Check if the AFK timer reset timeout has passed.
    if currentTime - timers.AFK.sentTime <= timers.AFK.timeOut then
        goto skipAFKCheck
    end

    -- Check if the player is in a moving vehicle and only reset if enough time has passed
    if isCharInAnyCar(ped) then
        local vehid = storeCarCharIsInNoSave(ped)
        if getCarSpeed(vehid) > 1.0 then
            -- Only reset if the timeout has passed since the last reset
            if currentTime - timers.AFK.sentTime >= timers.AFK.timeOut then
                isPlayerAFK = false
                timers.AFK.last = currentTime
                timers.AFK.sentTime = currentTime
                goto skipAFKCheck
            end
        end
    end

    -- Check if any key is pressed to reset AFK status (only if allowed by the timeout)
    for _, key in ipairs(afkKeys) do
        if isButtonPressed(h, key) then
            if currentTime - timers.AFK.sentTime >= timers.AFK.timeOut then
                isPlayerAFK = false
                timers.AFK.last = currentTime
                timers.AFK.sentTime = currentTime
                goto skipAFKCheck
            end
        end
    end

    ::skipAFKCheck::
end

-- Define a table with dialog configurations
local dialogConfigs = {
    {
        id = dialogs.farmer.id,
        onButton1 = function()
            if isCharInAnyCar(ped) or isCharSittingInAnyCar(ped) then
                formattedAddChatMessage("You cannot close this dialog while in a vehicle.")
                createFarmerDialog()
            end
        end,
        onButton0 = function()
            formattedAddChatMessage("You have disabled auto farming.")
            autobind.Settings.autoFarm = false
            farmer.farming = false
            farmer.harvesting = false
            farmer.harvestingCount = 0
        end
    },
    {
        id = dialogs.farmer.id2,
        onButton1 = function()
            farmer.farming = false
            farmer.harvesting = false
            farmer.harvestingCount = 0
        end,
        onButton0 = function()
            farmer.farming = true
            autobind.Settings.autoFarm = true
            formattedAddChatMessage("You have enabled auto farming.")
        end
    },
    {
        id = dialogs.radio.id,
        onButton1 = function(list)
            if list ~= 12 then
                formattedAddChatMessage(("You have selected radio station %d: %s - %s."):format(list, getRadioStationName(list), getRadioStationDesc(list)))
                lua_thread.create(function()
                    if not autobind.Settings.noRadio then
                        autobind.Settings.noRadio = true
                        toggleRadio(true)
                        wait(500)
                    end

                    if list == 11 then 
                        list = 24
                    end

                    setRadioChannel(list)
                end)
            else
                formattedAddChatMessage("You have selected radio station 12: Radio Off.")
                lua_thread.create(function()
                    if autobind.Settings.noRadio then
                        autobind.Settings.noRadio = false
                        setRadioChannel(list)
                        wait(500)
                        toggleRadio(false)
                    end
                end)
            end
        end
    },
    {
        id = dialogs.weather.id,
        onButton1 = function(list)
            autobind.TimeAndWeather.weather = list
            if list >= 22 then
                formattedAddChatMessage("You have selected weather: Unknown.")
            else
                formattedAddChatMessage(("You have selected weather: %s (%d)."):format(getWeatherName(list), list))
            end
            setWeather(list)
        end
    }
}

function createDialogResponses()
    -- Iterate over the dialog configurations
    for _, config in ipairs(dialogConfigs) do
        local result, button, list, _ = sampHasDialogRespond(config.id)
        if result then
            if button == 1 and config.onButton1 then
                config.onButton1(list)
            elseif button == 0 and config.onButton0 then
                config.onButton0(list)
            end
        end
    end
end

function createWantedCommand()
    local currentTime = os.clock()

    for entryId = #autobind.Wanted.List, 1, -1 do
        local entry = autobind.Wanted.List[entryId]
        if entry then
            if not entry.updated then
                if not entry.active and entry.markedDeactivated then
                    if (currentTime - entry.timestamp >= getEntryExpiryTime(entry)) then
                        table.remove(autobind.Wanted.List, entryId)
                    elseif (currentTime - entry.timestamp <= -20) then
                        entry.timestamp = currentTime
                    end
                end
            end
        
            if (currentTime - entry.timestamp >= (getEntryExpiryTime(entry) + 15)) then
                entry.timestamp = currentTime
            end
        end
    end

    if PausedLength >= 600 and PausedLength ~= 0 then
        if PausedLength >= currentTime - (timers.Pause.last + timers.Pause.timer) then
            formattedAddChatMessage(string.format("Wanted list cleared. (You were paused for %s)", formatTimeSeconds(PausedLength)))
            PausedLength = 0
            clearWantedList()
            last_wanted = currentTime - autobind.Wanted.Timer + 1
        end
    end

    if isLoadingObjects then
        goto skipWantedCommand
    end

    if autobind.Wanted.Enabled and autobind.Wanted.Timer <= currentTime - last_wanted then
        if sampGetGamestate() ~= 3 then
            goto skipWantedTimer
        end

        if autoCapture then
            goto skipWantedTimer
        end

        if (isPlayerAFK or not isGameFocused) and not specData.state then
            print("Skipping wanted command due to AFK or not game focused or not spectating")
            goto skipWantedTimer
        end

        if not wanted.lawyer then
            goto skipWantedTimer
        end

        if checkMuted() then
            goto skipWantedTimer
        end

        if (lockers.FactionLocker.isProcessing or lockers.FactionLocker.isBindActive) or 
           (lockers.BlackMarket.isProcessing or lockers.BlackMarket.isBindActive) then
            goto skipWantedTimer
        end

        if currentTime - lastKeybindTime < keyBindDelay then
            goto skipWantedTimer
        end

        sampSendChat("/wanted")
        last_wanted = currentTime
        wantedRefreshCount = wantedRefreshCount + 1

        ::skipWantedTimer::
    end

    ::skipWantedCommand::
end

-- Functions Table
local functionsToRun = {
    {
        id = 1,
        name = "DownloadManager",
        func = function()
            if downloads --[[and (downloads.isDownloading or downloads.isFetching)]] then
                downloads:updateDownloads()
            end
        end,
        interval = 0.001,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 2,
        name = "AutoVest",
        func = function()
            checkAndSendVest(false)
        end,
        interval = 0.001,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 3,
        name = "AutoAccept",
        func = function() 
            local success, message = checkAndAcceptVest(accepter.enable)
            if success and message then
                formattedAddChatMessage(message)
            end
        end,
        interval = 0.001,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 4,
        name = "Keybinds",
        func = createKeybinds,
        interval = 0.001,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 5,
        name = "AutoCapture",
        func = createAutoCapture,
        interval = 0.1,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 6,
        name = "PointBounds",
        func = createPointBounds,
        interval = 1.5,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 7,
        name = "AutoFind",
        func = createAutoFind,
        interval = 0.1,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 8,
        name = "SprunkSpam",
        func = createSprunkSpam,
        interval = 0.1,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 9,
        name = "AFKCheck",
        func = createAFKCheck,
        interval = 0.001,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 10,
        name = "DialogResponses",
        func = createDialogResponses,
        interval = 0.5,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    },
    {
        id = 11,
        name = "WantedCommand",
        func = createWantedCommand,
        interval = 0.1,
        lastRun = os.clock(),
        enabled = true,
        status = "idle",
        statusError = "Nothing to report"
    }
}

local restartDelay = 5.0
function functionsLoop(onFunctionsStatus)
    if not isGameFocused then
        goto skipFunctionsLoop
    end

    local currentTime = os.clock()
    for _, item in ipairs(functionsToRun) do
        if item.enabled and (currentTime - item.lastRun >= item.interval) then
            local success, err = pcall(item.func)
            if not success then
                print(string.format("Error in %s function: %s", item.name, err))
                item.errorCount = (item.errorCount or 0) + 1
                item.status = "failed"
                item.statusError = err
                if item.errorCount >= 5 then
                    print(string.format("%s function disabled after repeated errors.", item.name))
                    item.enabled = false
                    item.status = "disabled"
                end
            else
                item.errorCount = 0
                if item.status == "idle" then
                    item.status = "running"
                end
            end
            item.lastRun = currentTime
        end
        if item.status == "restarted" and item.restartTimestamp and 
           (currentTime - item.restartTimestamp >= restartDelay) then
            item.status = "running"
        end
    end

    if onFunctionsStatus and not funcsLoop.callbackCalled then
        local success = {}
        for _, item in ipairs(functionsToRun) do
            if item.status == "running" or item.status == "idle" or item.status == "restarted" then
                success[item.name] = true
            else
                success[item.name] = false
            end
        end
        onFunctionsStatus(success)
        funcsLoop.callbackCalled = true
    end

    ::skipFunctionsLoop::
end

local functionManager = {}
functionManager.__index = functionManager

function functionManager.start(name, callback)
    for _, item in ipairs(functionsToRun) do
        if item.name:lower() == name:lower() then
            if item.enabled then
                if item.status == "restarted" then
                    item.status = "running"
                end

                if callback then
                    callback(item.name, "already started")
                end
            else
                item.enabled = true
                item.status = "idle"

                if callback then
                    callback(item.name, "started")
                end
            end
            return
        end
    end
    print("Function " .. name .. " not found.")
end

function functionManager.stop(name, callback)
    for _, item in ipairs(functionsToRun) do
        if item.name:lower() == name:lower() then
            if not item.enabled then
                if callback then
                    callback(item.name, "already stopped")
                end
            else
                item.enabled = false
                item.status = "stopped"

                if callback then
                    callback(item.name, "stopped")
                end
            end
            return
        end
    end
    print("Function " .. name .. " not found.")
end

function functionManager.restart(name, callback)
    local currentTime = os.clock()
    for _, item in ipairs(functionsToRun) do
        if item.name:lower() == name:lower() then
            item.enabled = false  -- temporarily disable
            item.errorCount = 0
            item.lastRun = currentTime
            item.enabled = true   -- then re-enable
            item.status = "restarted"
            item.restartTimestamp = currentTime

            if callback then
                callback(item.name, "restarted")
            end
            return
        end
    end
    print("Function " .. name .. " not found.")
end

function functionManager.getErrorStatus(name)
    for _, item in ipairs(functionsToRun) do
        if item.name:lower() == name:lower() then
            return item.statusError:gsub(workingDir .. "\\", "")
        end
    end
end

local clientCommands = {
	vestnear = {
        cmd = "vestnear",
        desc = "Sends a vest offer to the nearest player",
        id = 1,
        func = function(cmd)
            local message = checkAndSendVest(true)
		    if message then
                formattedAddChatMessage(message)
            end
        end
    },
	repairnear = {
        cmd = "repairnear",
        desc = "Sends a repair request to the nearest player that is in a vehicle",
        id = 2,
        func = function(cmd)
            local found = false
            for _, player in ipairs(getVisiblePlayers(5, "car")) do
                sampSendChat(string.format("/repair %d 1", player.playerId))
                found = true
                break
            end
            if not found then
                formattedAddChatMessage("No suitable vehicle found to repair.")
            end
        end
    },
	sprintbind = {
        cmd = "sprintbind", 
        desc = "Automatic sprinting, will run faster when you press the sprint key",
        id = 3,
        func = function(cmd)
            autobind.Keybinds.SprintBind.Toggle = toggleBind("SprintBind", autobind.Keybinds.SprintBind.Toggle)
            autobind.Settings.sprintBind = autobind.Keybinds.SprintBind.Toggle
        end
    },
	bikebind = {
        cmd = "bikebind", 
        desc = "Automatic pedalling for bikecycles, motorcycles will go faster",
        id = 4,
        func = function(cmd)
            autobind.Keybinds.BikeBind.Toggle = toggleBind("BikeBind", autobind.Keybinds.BikeBind.Toggle)
        end
    },
	find = {
        cmd = "find",
        alt = {"autofind", "af"},
        desc = "Repeativly finds a player every 20 seconds",
        id = 5,
        func = function(cmd, params)
            if not autobind.Settings.autoFind then
                local result, playerid, name = findPlayer(params, false)
                if not result then
                    sampAddChatMessage("Invalid player specified.", clr_WHITE)
                    return
                end

                sampSendChat(string.format("/find %d", playerid))
                return
            end

            if checkMuted() then
                formattedAddChatMessage(string.format("You are muted, you cannot use the /%s command.", cmd))
                return
            end
    
            if string.len(params) < 1 then
                if autofind.enable then
                    formattedAddChatMessage("You are no longer finding anyone.")
                    autofind.enable = false
                    autofind.playerName = ""
                    autofind.playerId = -1
                else
                    formattedAddChatMessage(string.format('USAGE: /%s [playerid/partofname]', cmd))
                end
                return
            end
    
            local result, playerid, name = findPlayer(params, false)
            if not result then
                formattedAddChatMessage("Invalid player specified.")
                return
            end
    
            if playerid == autofind.playerId then
                formattedAddChatMessage("You are already finding this player.")
                return
            end
    
            autofind.playerId = playerid
            autofind.playerName = name
            if autofind.enable then
                local displayName = name and name:gsub("_", " ") or "Unknown"
                formattedAddChatMessage(string.format("Now finding: {%06x}%s (ID %d).", clr_REALGREEN, displayName, playerid))
                autofind.location = ""
                return
            end
    
            autofind.enable = true
            formattedAddChatMessage(string.format("Finding: {%06x}%s (ID %d). {%06x}Type /%s again to toggle off.", clr_REALGREEN, autofind.playerName:gsub("_", " "), autofind.playerId, clr_WHITE, cmd))
        end
    },
	autocap = {
        cmd = "autocap",
        alt = {"tcap", "ac"},
        desc = "Automatically types /capturf every 1.5 seconds",
        id = 6,
        func = function(cmd)
            toggleAutoCapture()
        end
    },
    capcheck = {
        cmd = "capcheck", 
        desc = "Automatically types /capturf at signcheck time",
        id = 7,
        func = function(cmd)
            local mode = autobind.Settings.mode or "Family"
            autobind[mode].turf = toggleBind("Capture at Signcheck", autobind[mode].turf)
        end
    },
	autovest = {
        cmd = "autoguard", 
        alt = {"autog", "ag"},
        desc = "Toggles auto guarding to vest automatically",
        id = 8,
        func = function(cmd)
            autobind.AutoVest.autoGuard = toggleBind("Auto Send Guard", autobind.AutoVest.autoGuard)
        end
    },
	autoaccept = {
        cmd = "autovest",
        alt = {"avest", "av"},
        desc = "Automatically accepts vest offers from other players",
        id = 9,
        func = function(cmd)
            accepter.enable = toggleBind("Auto Accept Vest", accepter.enable)
        end
    },
	ddmode = {
        cmd = "ddmode", 
        desc = "Toggles between DD and non-DD vesting",
        id = 10,
        func = function(cmd)
            autobind.AutoVest.donor = toggleBind("DD Mode", autobind.AutoVest.donor)
            timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime
        end
    },
    vestall = {
        cmd = "vestall", 
        desc = "Allows you to offer vests to all players, bypasses any skin/color restrictions",
        id = 11,
        func = function(cmd)
            autobind.AutoVest.everyone = toggleBind("Allow Everyone", autobind.AutoVest.everyone)
        end
    },
    sprunkspam = {
        cmd = "sprunkspam", 
        desc = "Opens a can of sprunk and heals you until full health",
        id = 12,
        func = function(cmd)
            if checkMuted() then
                formattedAddChatMessage(string.format("You are muted, you cannot use the /%s command.", cmd))
                return
            end
    
            if checkHeal() then
                formattedAddChatMessage(string.format("You have been attacked recently, you cannot use the /%s command.", cmd))
                return
            end
    
            local health = getCharHealth(ped) - hzrpHealth
            if health == 100 then
                formattedAddChatMessage("You already have full health.")
                return
            end
    
            local result, playerId = sampGetPlayerIdByCharHandle(ped)
            if not result then
                return
            end
    
            if sampGetPlayerSpecialAction(playerId) == 23 then
                formattedAddChatMessage("You are already using a can of sprunk.")
                return
            end
    
            sampSendChat("/usesprunk")
        end
    },
    vst = {
        cmd = "vst",
        alt = {"vstorage", "v"},
        desc = "Opens or spawns from vehicle storage via slot ID or partial vehicle name",
        id = 13,
        func = function(cmd, params)
            if not autobind.VehicleStorage.enable then
                sampSendChat("/vst")
                return
            end

            -- If no params are provided, just display usage and open /vst dialog
            if not params or params == "" then
                if autobind.VehicleStorage.menu and (not autobind.VehicleStorage.chatInputText and not autobind.VehicleStorage.chatInput) then
                    menu.VehicleStorage.window[0] = not menu.VehicleStorage.window[0]
                else
                    sampSendChat("/vst")
                end
                formattedAddChatMessage(string.format("USAGE: /%s [slot ID or partial vehicle name]", cmd))
                return
            end
    
            local playerName = getCurrentPlayingPlayer()
            if not playerName then
                formattedAddChatMessage("Current playing player not found!")
                return
            end
    
            -- Ensure the table exists
            autobind.VehicleStorage.Vehicles[playerName] = autobind.VehicleStorage.Vehicles[playerName] or {}
            local vehsForPlayer = autobind.VehicleStorage.Vehicles[playerName]
    
            -- If no vehicles have been stored/fetched yet, re-populate
            if #vehsForPlayer == 0 then
                formattedAddChatMessage("Your vehicles are not yet populated! Spawning selected vehicle if valid...")
                vehicles.spawning = true
                -- The user might have typed a slot ID or name; we still attempt to spawn an index if it's numeric
                local possibleIndex = tonumber(params)
                vehicles.currentIndex = (possibleIndex and possibleIndex > 0) and (possibleIndex - 1) or -1
                sampSendChat("/vst")
                return
            end

            local parsedIndex = tonumber(params)
            if parsedIndex then
                -- Validate input range
                if parsedIndex < 1 or parsedIndex > 20 then
                    formattedAddChatMessage("Please pick a number between 1 and 20!")
                    return
                end
    
                -- Convert user-friendly index to the internal (server) index
                local serverIndex = parsedIndex - 1
    
                -- Check if that index is in the player's storage
                local foundNumeric = false
                for _, vehicleData in ipairs(vehsForPlayer) do
                    if vehicleData.id == serverIndex then
                        foundNumeric = true
                        vehicles.spawning = true
                        vehicles.currentIndex = serverIndex
                        sampSendChat("/vst")
                        break
                    end
                end
    
                if not foundNumeric then
                    formattedAddChatMessage("No vehicle found at that slot or invalid slot used!")
                end
                return
            end

            local nameMatches = findVehiclesByName(vehsForPlayer, params)
            local matchCount = #nameMatches
    
            if matchCount == 0 then
                formattedAddChatMessage(("No vehicles found matching '%s'!"):format(params))
                return
            elseif matchCount == 1 then
                -- Exactly one match, spawn directly
                local matchedVehicle = nameMatches[1]
                vehicles.spawning = true
                vehicles.currentIndex = matchedVehicle.id  -- This matches the server’s 0-based index
                sampSendChat("/vst")
            else
                formattedAddChatMessage(("Multiple matches for '%s' found:"):format(params))
                for _, vData in ipairs(nameMatches) do
                    local userSlot = (vData.id or 0) + 1
                    formattedAddChatMessage(
                        ("[Slot %d] Vehicle: %s, Status: %s, Location: %s"):format(
                            userSlot,
                            vData.vehicle,
                            vData.status or "N/A",
                            vData.location or "N/A"
                        )
                    )
                end
                formattedAddChatMessage(string.format("Use /%s [Slot ID] for the specific vehicle you want.", cmd))
            end
        end
    },
    resetvst = {
        cmd = "resetvst", 
        alt = {"rvst"},
        desc = "Resets your vehicle storage, will populate vehicles again for the menu",
        id = 14,
        func = function(cmd)
            resetVehicleStorage()
        end
    },
    autofarm = {
        cmd = "autofarm",
        desc = "Auto farm job, just type /farm while in harvest truck and drive!",
        id = 15,
        func = function(cmd)
            autobind.Settings.autoFarm = toggleBind("Auto Farm", autobind.Settings.autoFarm)
        end
    },
    autopicklock = {
        cmd = "autopicklock",
        desc = "Auto picklock on failure or success [Good for leveling up]",
        id = 16,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format("USAGE: /%s [success|fail]", cmd))
                formattedAddChatMessage(string.format("Success: {%06x}Locks personal vehicle and picks the lock again. (Good for leveling up)", clr_GREY))
                formattedAddChatMessage(string.format("Fail: {%06x}Keeps trying to pick the lock on failure.", clr_GREY))
            elseif params:match("^success$") then
                formattedAddChatMessage(string.format("Success: {%06x}Locks personal vehicle and picks the lock again. (Good for leveling up)", clr_GREY))
                autobind.Settings.autoPicklockOnSuccess = toggleBind("Auto Picklock On Success", autobind.Settings.autoPicklockOnSuccess)
            elseif params:match("^fail$") then
                formattedAddChatMessage(string.format("Fail: {%06x}Keeps trying to pick the lock on failure.", clr_GREY))
                autobind.Settings.autoPicklockOnFail = toggleBind("Auto Picklock On Fail", autobind.Settings.autoPicklockOnFail)
            else
                formattedAddChatMessage(string.format("USAGE: /%s [success|fail]", cmd))
            end
        end
    },
    autobadge = {
        cmd = "autobadge",
        desc = "Automatically types /badge upon spawning",
        id = 17,
        func = function(cmd)
            autobind.Faction.autoBadge = toggleBind("Auto Badge", autobind.Faction.autoBadge)
        end
    },
    reconnect = {
        cmd = "recon",
        desc = "Reconnects you to the server",
        id = 18,
        func = function(cmd)
            GameModeRestart()
            sampSetGamestate(1)
        end
    },
    autoreconnect = {
        cmd = "autorecon",
        desc = "Auto reconnect (rejection, closure, ban, or disconnection)",
        id = 19,
        func = function(cmd)
            autobind.Settings.autoReconnect = toggleBind("Auto Reconnect", autobind.Settings.autoReconnect)
        end
    },
    name = {
        cmd = "name",
        desc = "Change your name and reconnect to the server",
        id = 20,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format("USAGE: /%s [playername]", cmd))
                return
            end

            if not params:match("_") then
                formattedAddChatMessage("Your name must contain an underscore (_).")
                return
            end

            sampSetLocalPlayerName(params)
            formattedAddChatMessage(string.format("Your name has been changed to {%06x}%s.", clr_GREY, params))
            GameModeRestart()
            sampSetGamestate(1)
        end
    },
    changemode = {
        cmd = "changemode",
        alt = {"cm", "switchmode"},
        desc = "Switch between modes (faction, family)",
        id = 21,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format("Current Mode: {%06x}%s.", clr_GREY, autobind.Settings.mode or "N/A"))
                formattedAddChatMessage(string.format("USAGE: /%s [faction|family]", cmd))
            elseif params:match("^faction$") then
                formattedAddChatMessage(string.format("You have changed the mode to {%06x}Faction.", clr_GREY))
                autobind.Settings.mode = "Faction"
            elseif params:match("^family$") then
                formattedAddChatMessage(string.format("You have changed the mode to {%06x}Family.", clr_GREY))
                autobind.Settings.mode = "Family"
            else
                formattedAddChatMessage(string.format("USAGE: /%s [faction|family]", cmd))
            end
        end
    },
    weather = {
        cmd = "changeweather",
        alt = {"cw"},
        desc = "Weather settings (ID, toggle, list)",
        id = 22,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format(
                    "Status: {%06x}%s{%06x}, Weather: {%06x}%s (%d).",
                    autobind.TimeAndWeather.modifyWeather and clr_REALGREEN or clr_REALRED, 
                    autobind.TimeAndWeather.modifyWeather and "On" or "Off",
                    clr_WHITE,
                    clr_LIGHTBLUE, 
                    getWeatherName(autobind.TimeAndWeather.weather),
                    autobind.TimeAndWeather.weather
                ))
                formattedAddChatMessage(string.format("Server: {%06x}%s (%d).", clr_LIGHTBLUE, getWeatherName(autobind.TimeAndWeather.serverWeather), autobind.TimeAndWeather.serverWeather))
                formattedAddChatMessage(string.format("USAGE: /%s [weatherId|tgl|list]", cmd))
                return
            end

            if params:match("^tgl$") then
                autobind.TimeAndWeather.modifyWeather = toggleBind("Weather", autobind.TimeAndWeather.modifyWeather)

                if autobind.TimeAndWeather.modifyWeather then
                    setWeather(autobind.TimeAndWeather.weather)
                else
                    setWeather(autobind.TimeAndWeather.serverWeather or autobind_defaultSettings.TimeAndWeather.serverWeather)
                end
            elseif params:match("^list$") then
                local messages = ""
                for i = 0, 22 do
                    messages = messages .. string.format("Weather ID: {%06x}%d{%06x}, %s.\n", clr_LIGHTBLUE, i, clr_WHITE, getWeatherName(i))
                end

                local title = string.format("[%s] Weather List", shortName:upper())
                sampShowDialog(dialogs.weather.id, title, messages, "Select", "Close", 2)
            else
                local weatherId = tonumber(params)
                if weatherId and weatherId >= 0 and weatherId <= 50 then
                    autobind.TimeAndWeather.weather = weatherId
                    formattedAddChatMessage(string.format("Weather has been set to {%06x}%s (%d).", clr_LIGHTBLUE, getWeatherName(weatherId), weatherId))

                    if autobind.TimeAndWeather.modifyWeather then
                        setWeather(weatherId)
                    end
                else
                    formattedAddChatMessage(string.format("USAGE: /%s [weatherId|tgl|list]", cmd))
                end
            end
        end
    },
    settime = {
        cmd = "changetime",
        alt = {"ct"},
        desc = "Time settings (hour:minute, toggle, list)",
        id = 23,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format("Status: {%06x}%s{%06x}, Time: {%06x}%s (%02d:%02d).", autobind.TimeAndWeather.modifyTime and clr_REALGREEN or clr_REALRED, autobind.TimeAndWeather.modifyTime and "On" or "Off", clr_WHITE, clr_LIGHTBLUE, getTimeName(autobind.TimeAndWeather.hour), autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute))
                formattedAddChatMessage(string.format("Server: {%06x}%s (%02d:%02d).", clr_LIGHTBLUE, getTimeName(autobind.TimeAndWeather.serverHour), autobind.TimeAndWeather.serverHour, autobind.TimeAndWeather.serverMinute))
                formattedAddChatMessage(string.format("USAGE: /%s [hour(:minute)|tgl] e.g., '/%s 12:30'", cmd, cmd))
                return
            end
    
            if params:match("^tgl$") then
                autobind.TimeAndWeather.modifyTime = toggleBind("Time", autobind.TimeAndWeather.modifyTime)
                if autobind.TimeAndWeather.modifyTime then
                    setTime(autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute)
                else
                    setTime(autobind.TimeAndWeather.serverHour, autobind.TimeAndWeather.serverMinute)
                end
            else
                local hour, minute = params:match("^(%d+):?(%d*)$")
                hour = tonumber(hour)
                minute = tonumber(minute) or 0
    
                if hour and hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 then
                    autobind.TimeAndWeather.hour = hour
                    autobind.TimeAndWeather.minute = minute
                    formattedAddChatMessage(string.format("Time has been set to {%06x}%s (%02d:%02d).", clr_LIGHTBLUE, getTimeName(hour), hour, minute))
    
                    if autobind.TimeAndWeather.modifyTime then
                        setTime(hour, minute)
                    end
                else
                    formattedAddChatMessage(string.format("USAGE: /%s [hour(:minute)|tgl] e.g., '/%s 12:30'", cmd, cmd))
                end
            end
        end
    },
    radio = {
        cmd = "radio",
        desc = "Radio settings (channel, toggle, favorite, list)",
        id = 24,
        func = function(cmd, params)
            if not isCharInAnyCar(ped) then
                formattedAddChatMessage("You must be in a vehicle to use this command.")
                return
            end

            if isCharInAnyPoliceVehicle(ped) then
                formattedAddChatMessage("You cannot use this command while in a police vehicle.")
                return
            end

            if #params < 1 then
                formattedAddChatMessage(string.format(
                    "Status: {%06x}%s{%06x}, Current Radio: {%06x}%s.", 
                    autobind.Settings.noRadio and clr_GREEN or clr_RED, 
                    autobind.Settings.noRadio and "On" or "Off",
                    clr_WHITE,
                    clr_LIGHTBLUE, 
                    autobind.Settings.noRadio and getRadioStationName(currentRadio) or "Radio Off"
                ))
                formattedAddChatMessage(string.format("USAGE: /%s [channel|tgl|fav|list]", cmd))
                return
            end

            if params:match("^tgl$") then
                autobind.Settings.noRadio = toggleBind("Radio", autobind.Settings.noRadio)

                lua_thread.create(function()
                    if isCharInAnyCar(ped) and not autobind.Settings.noRadio then
                        setRadioChannel(12)
                        wait(500)
                    end
    
                    toggleRadio(autobind.Settings.noRadio)

                    if autobind.Settings.noRadio then
                        wait(500)
                        setRadioChannel(autobind.Settings.favoriteRadio)
                        formattedAddChatMessage(string.format("Radio has been turned on, favorite channel set to {%06x}%s.", clr_LIGHTBLUE, getRadioStationName(autobind.Settings.favoriteRadio)))
                        return
                    end
                end)
            elseif params:match("^fav%s*(%d*)") then
                local newParams = params:match("^fav%s*(%d*)")
                if #newParams < 1 then
                    setRadioChannel(autobind.Settings.favoriteRadio)
                    formattedAddChatMessage(string.format("Favorite radio channel has been set to {%06x}%s.", clr_LIGHTBLUE, getRadioStationName(autobind.Settings.favoriteRadio)))
                else
                    local channel = tonumber(newParams)
                    if channel and channel >= 0 and channel <= 11 then
                        formattedAddChatMessage(string.format("Favorite radio channel has been set to {%06x}%s.", clr_LIGHTBLUE, getRadioStationName(channel)))

                        -- Fix user tracks
                        if channel == 11 then channel = 24 end

                        autobind.Settings.favoriteRadio = channel

                        setRadioChannel(channel)
                    else
                        formattedAddChatMessage(string.format("USAGE: /%s [channel|tgl|fav|list]", cmd))
                    end
                end
            elseif params:match("^list$") then
                local messages = ""
                for i = 0, 12 do
                    messages = messages .. string.format("%d: {%06x}%s{%06x} - {%06x}%s\n", i, clr_LIGHTBLUE, getRadioStationName(i), clr_WHITE, clr_GREY, getRadioStationDesc(i))
                end

                local title = string.format("[%s] Radio List", shortName:upper())
                sampShowDialog(dialogs.radio.id, title, messages, "Select", "Close", 2)
            else
                local channel = tonumber(params)
                if channel and channel >= 0 and channel <= 11 then
                    formattedAddChatMessage(string.format("Radio channel has been set to {%06x}%s.", clr_LIGHTBLUE, getRadioStationName(channel)))
                    lua_thread.create(function()
                        if not autobind.Settings.noRadio then
                            autobind.Settings.noRadio = true
                            toggleRadio(true)
                            wait(500)
                        end

                        -- Fix user tracks
                        if channel == 11 then channel = 24 end

                        setRadioChannel(channel)
                    end)
                else
                    formattedAddChatMessage(string.format("USAGE: /%s [channel|tgl|fav|list]", cmd))
                end
            end
        end
    },
    secondarybackup = {
        cmd = "secondarybackup",
        alt = {"sb"},
        desc = "Calls secondary backup over department radio or portable radio",
        id = 25,
        func = function(cmd)
            autobind.Settings.callSecondaryBackup = toggleBind("Secondary Backup", autobind.Settings.callSecondaryBackup)
        end
    },
    hzradio = {
        cmd = "hzradio",
        alt = {"hzr"},
        desc = "Disable the horizon radio from being played",
        id = 26,
        func = function(cmd)
            autobind.Settings.HZRadio = toggleBind("Horizon Radio", autobind.Settings.HZRadio)
        end
    },
    loginmusic = {
        cmd = "loginmusic",
        alt = {"lm"},
        desc = "Disables the horizon login music",
        id = 27,
        func = function(cmd)
            autobind.Settings.LoginMusic = toggleBind("Login Music", autobind.Settings.LoginMusic)
        end
    },
    hidechargereporter = {
        cmd = "hidechargereporter",
        alt = {"hcr"},
        desc = "Hides the first part of the charge reporter",
        id = 28,
        func = function(cmd)
            autobind.Faction.hideChargeReporter = toggleBind("Combined Charge Reporter", autobind.Faction.hideChargeReporter)
        end
    },
    hidearrestreporter = {
        cmd = "hidearrestreporter",
        alt = {"har"},
        desc = "Hides the first part of the arrest reporter",
        id = 29,
        func = function(cmd)
            autobind.Faction.hideArrestReporter = toggleBind("Combined Arrest Reporter", autobind.Faction.hideArrestReporter)
        end
    },
    wanted = {
        cmd = "wanted",
        desc = "Displays the wanted list in the chat",
        id = 30,
        func = function(cmd)
            if not autobind.Wanted.Enabled then
                sampSendChat("/wanted")
                return
            end

            sampAddChatMessage("__________WANTED LIST__________", clr_ORANGE)
            if autobind.Wanted.List and #autobind.Wanted.List > 0 then
                for _, entry in ipairs(autobind.Wanted.List) do
                    local wantedString = formatWantedString(entry, false, false)

                    sampAddChatMessage(wantedString, clr_WHITE)
                end
            else
                sampAddChatMessage("No current wanted suspects.", clr_WHITE)
            end
            sampAddChatMessage("________________________________", clr_ORANGE)
        end
    },
    blankmessages = {
        cmd = "blankmessages",
        desc = "Removes the blank messages in the chat after you login",
        id = 31,
        func = function(cmd)
            autobind.Settings.blankMessagesAtConnection = toggleBind("Remove Blank Messages", autobind.Settings.blankMessagesAtConnection)
            formattedAddChatMessage("This only removes the blank messages after you have signed in to the server.", clr_YELLOW)
        end
    }
}

local autobindCommands = {
    [""] = function()
        menu.Settings.window[0] = not menu.Settings.window[0]
    end,
    ["help"] = function(newParams, cmd, alias)
        if #newParams < 1 then
            formattedAddChatMessage(string.format("%s | Type '/%s %s desc' to display the description of all commands.", cmd:upperFirst(), alias, cmd), clr_GREY)
            formattedAddChatMessage(string.format("/%s {%06x}cmds, showkeys, getskin, status, funcs, reload", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s {%06x}names, charges, skins, bms, locker", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s {%06x}changelog, betatesters", alias, clr_GREY))
        elseif newParams:match("^desc$") then
            formattedAddChatMessage(string.format("/%s {%06x}- Opens the autobind settings menu.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s cmds {%06x}- Lists all commands.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s showkeys {%06x}- Lists all keys for keybinds.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s getskin [playerid/partofname] {%06x}- Gets the skin ID of a player.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s status {%06x}- Displays the status of all scripts and the autobind menu.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s funcs {%06x}- Lists all functions and their status.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s reload {%06x}- Reloads the script.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s names {%06x}- Opens the names menu for customization.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s charges {%06x}- Opens the charges menu for customization.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s skins {%06x}- Opens the skins menu for customization.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s bms {%06x}- Opens the black market menu.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s locker {%06x}- Opens the faction locker menu.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s changelog {%06x}- Displays the changelog.", alias, clr_GREY))
            formattedAddChatMessage(string.format("/%s betatesters {%06x}- Displays the betatesters.", alias, clr_GREY))
        else
            formattedAddChatMessage(string.format("USAGE: '/%s %s desc' for more information.", alias, cmd))
        end
    end,
    ["cmds"] = function(newParams, cmd, alias)
        if #newParams < 1 then
            formattedAddChatMessage(string.format("%s | Type '/%s %s [desc|alts]' to display the description of all commands.", cmd:upperFirst(), alias, cmd), clr_GREY)
            local commandsList = {}
            local commandCount = 0
            for _, command in pairs(clientCommands) do
                table.insert(commandsList, string.format("/%s", command.cmd))
                commandCount = commandCount + 1
            end
            table.sort(commandsList)

            -- Set your maximum length (in characters) for each line.
            local maxLineLength = 80

            local currentLine = {}
            local currentLength = 0

            for i, cmd in ipairs(commandsList) do
                local cmdLength = #cmd
                local sepLength = (#currentLine > 0) and 2 or 0  -- ", " separator length if needed

                if currentLength + sepLength + cmdLength > maxLineLength then
                    formattedAddChatMessage(table.concat(currentLine, ", "))
                    currentLine = { cmd }
                    currentLength = cmdLength
                else
                    table.insert(currentLine, cmd)
                    currentLength = currentLength + sepLength + cmdLength
                end
            end

            -- Print any remaining commands.
            if #currentLine > 0 then
                formattedAddChatMessage(table.concat(currentLine, ", "))
            end

            formattedAddChatMessage(string.format("%d commands available.", commandCount), clr_GREY)
        elseif newParams:match("^desc$") then
            local sortedCommands = {}
            for _, command in pairs(clientCommands) do
                table.insert(sortedCommands, command)
            end
            table.sort(sortedCommands, function(a, b) return a.id < b.id end)

            local commandList = ""
            for index, command in pairs(sortedCommands) do
                commandList = commandList .. string.format("{%06x}/%s {%06x}- %s\n", clr_YELLOW, command.cmd, clr_GREY, command.desc)
            end

            sampShowDialog(
                4525, 
                string.format("[%s] Command Descriptions", shortName:upper()), 
                commandList, 
                "Close", 
                "", 
                0
            )
        elseif newParams:match("^alts$") then
            local sortedCommands = {}
            for _, command in pairs(clientCommands) do
                table.insert(sortedCommands, command)
            end
            table.sort(sortedCommands, function(a, b) return a.id < b.id end)

            for _, command in pairs(sortedCommands) do
                if command.alt then
                    local altList = {}
                    for _, alt in ipairs(command.alt) do
                        table.insert(altList, "/" .. alt)
                    end
                    formattedAddChatMessage(string.format("/%s {%06x}- %s.", command.cmd, clr_GREY, table.concat(altList, ", ")))
                end
            end
        else
            formattedAddChatMessage(string.format("USAGE: '/%s %s [desc|alts]' for more information.", alias, cmd))
        end
    end,
    ["showkeys"] = function()
        local keybindsList = {}
        for bind, _ in pairs(autobind.Keybinds) do
            table.insert(keybindsList, bind)
        end
        table.sort(keybindsList)
        for _, bind in ipairs(keybindsList) do
            local newName = bind
            if bind:find("BlackMarket") then
                newName = bind:gsub("BlackMarket", "BM")
            elseif bind:find("FactionLocker") then
                newName = bind:gsub("FactionLocker", "FLocker")
            end
            local keybindMessage = string.format(
                "Keybind: {%06x}%s{%06x}, Enabled: {%06x}%s{%06x}, Keys: {%06x}%s.",
                clr_YELLOW, 
                newName,
                clr_WHITE,
                autobind.Keybinds[bind].Toggle and clr_GREEN or clr_RED, 
                autobind.Keybinds[bind].Toggle and "Yes" or "No",
                clr_WHITE,
                clr_LIGHTBLUE, 
                getKeybindKeys(bind)
            )
            formattedAddChatMessage(keybindMessage)
        end
    end,
    ["getskin"] = function(newParams, cmd, alias)
        if #newParams < 1 then
            formattedAddChatMessage(string.format("USAGE: '/%s %s [playerid/partofname]'", alias, cmd))
            return
        end

        local result, playerId, name = findPlayer(newParams, true)
        if not result then
            formattedAddChatMessage("Invalid player specified.")
            return
        end

        local result, peds = sampGetCharHandleBySampPlayerId(playerId)
        local _, sampPlayerId = sampGetPlayerIdByCharHandle(ped)
        if sampPlayerId == playerId then
            peds = ped
            result = true
        end

        formattedAddChatMessage(result and string.format("Skin ID: %d", getCharModel(peds)) or "Player is not in your view.")
    end,
    ["status"] = function(newParams, cmd, alias)
        if #newParams < 1 then
            formattedAddChatMessage(string.format("%s {%06x}| Type '/%s %s timers' there are more options below.", cmd:upperFirst(), clr_WHITE, alias, cmd), clr_REALGREEN)
            formattedAddChatMessage("timers, bodyguard, accepter, autofind", clr_GREY)
            formattedAddChatMessage("backup, farmer, misc", clr_GREY)
        elseif newParams:match("^timers$") then
            displayTimers()
        elseif newParams:match("^bodyguard$") then
            local bodyguardId = bodyguard.playerId ~= -1 and bodyguard.playerId or ""
            local bodyguardName = bodyguard.playerName ~= "" and string.format("%s (%s)", bodyguard.playerName, bodyguard.playerId) or "N/A"
            local bodyguardEnableStatus = bodyguard.enable and "Yes" or "No"
            local bodyguardReceivedStatus = bodyguard.received and "Yes" or "No"

            formattedAddChatMessage(string.format(
                "Bodyguard: %s, Enabled: %s, Received: %s, Price: $%d.",
                bodyguardName,
                bodyguardEnableStatus,
                bodyguardReceivedStatus,
                bodyguard.price
            ))
        elseif newParams:match("^accepter$") then
            local accepterId = accepter.playerId ~= -1 and accepter.playerId or ""
            local accepterName = accepter.playerName ~= "" and string.format("%s (%s)", accepter.playerName, accepterId) or "N/A"
            local accepterEnableStatus = accepter.enable and "Yes" or "No"
            local accepterReceivedStatus = accepter.received and "Yes" or "No"
            local accepterThreadStatus = accepter.thread ~= nil and "On" or "Off"

            formattedAddChatMessage(string.format(
                "Accepter: %s, Enabled: %s, Received: %s, Price: $%d, Thread: %s.",
                accepterName,
                accepterEnableStatus,
                accepterReceivedStatus,
                accepter.price,
                accepterThreadStatus
            ))
        elseif newParams:match("^autofind$") then
            local autofindId = autofind.playerId ~= -1 and autofind.playerId or ""
            local autofindName = autofind.playerName ~= "" and string.format("%s (%s)", autofind.playerName, autofindId) or "N/A"
            local autofindEnableStatus = autofind.enable and "Yes" or "No"

            formattedAddChatMessage(string.format(
                "Autofind: {%06x}%s{%06x}, Enabled: {%06x}%s{%06x}, Counter: {%06x}%d.",
                autofind.playerName ~= "" and clr_REALGREEN or clr_RED, 
                autofindName,
                clr_WHITE,
                autofind.enable and clr_GREEN or clr_RED, 
                autofindEnableStatus,
                clr_WHITE,
                clr_LIGHTBLUE, 
                autofind.counter
            ))
        elseif newParams:match("^backup$") then
            local backupId = backup.playerId ~= -1 and backup.playerId or ""
            local backupName = backup.playerName ~= "" and string.format("%s (%s)", backup.playerName, backupId) or "N/A"
            local backupLocation = backup.location ~= "" and backup.location or "N/A"
            local backupEnableStatus = backup.enable and "Yes" or "No"

            formattedAddChatMessage(string.format(
                "Backup: {%06x}%s{%06x}, Location: {%06x}%s{%06x}, Enabled: {%06x}%s {%06x}(Self).",
                backup.playerName ~= "" and clr_TEAM_BLUE_COLOR or clr_RED, 
                backupName,
                clr_WHITE,
                backup.location ~= "" and clr_GREEN or clr_RED, 
                backupLocation,
                clr_WHITE,
                backup.enable and clr_GREEN or clr_RED, 
                backupEnableStatus,
                clr_WHITE
            ))
        elseif newParams:match("^farmer$") then
            local farmerEnableStatus = farmer.farming and "Yes" or "No"
            local farmerHarvestingStatus = farmer.harvesting and "Yes" or "No"

            formattedAddChatMessage(string.format(
                "Farming: {%06x}%s{%06x}, Harvesting: {%06x}%s{%06x}, Counter: {%06x}%d.",
                farmer.farming and clr_GREEN or clr_RED, 
                farmerEnableStatus,
                clr_WHITE,
                farmer.harvesting and clr_GREEN or clr_RED, 
                farmerHarvestingStatus,
                clr_WHITE,
                clr_LIGHTBLUE, 
                farmer.harvestingCount
            ))
        elseif newParams:match("^misc$") then
            local mode = autobind.Settings.mode or "N/A"
            local factionType = mode == "Faction" and autobind.Faction.type or "N/A"
            local autocapStatus = autoCapture and "Yes" or "No"
            local sprunkStatus = usingSprunk and "Yes" or "No"
            local pointStatus = family.enteredPoint and "Yes" or "No"
            local preventHealStatus = family.preventHealTimer and "Yes" or "No"

            formattedAddChatMessage(string.format("Mode: %s, Type: %s, Auto Capture: %s, Using Sprunk: %s.", mode, factionType, autocapStatus, sprunkStatus))
            formattedAddChatMessage(string.format("Point Bounds: %s, Prevent Heal Timer: %s.", pointStatus, preventHealStatus))
        else
            formattedAddChatMessage(string.format("USAGE: '/%s %s [bodyguard|accepter|autofind|backup|farmer|functions|timers]' for more information.", alias, cmd))
        end
    end,
    ["funcs"] = function(newParams, cmd, alias)
        local action, target = newParams:match("^(%S+)%s*(.*)$")
        action = action and action:lower() or ""
        target = target and target:trim() or ""

        if action == "" then
            formattedAddChatMessage(string.format("USAGE: '/%s %s [start|stop|restart|status] [function_name]'", alias, cmd), clr_GREY)

            table.sort(functionsToRun, function(a, b) return a.id < b.id end)

            for _, item in ipairs(functionsToRun) do
                local status = item.status or "unknown"
                local state = item.enabled and "started" or "idle"

                local statusColor
                if status == "running" then
                    statusColor = clr_GREEN
                elseif status == "idle" then
                    statusColor = clr_NEWS
                elseif status == "restarted" then
                    statusColor = clr_YELLOW
                elseif status == "failed" then
                    statusColor = clr_RED
                elseif status == "disabled" or state == "disabled" then
                    statusColor = clr_RED
                else
                    statusColor = clr_GREY
                end
                formattedAddChatMessage(string.format("%s - Status: {%06x}%s{%06x} (%s)", item.name, statusColor, status, clr_WHITE, state))
            end
            return
        elseif action == "start" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s start [function_name]'", alias, cmd), clr_GREY)
            else
                functionManager.start(target, function(name, status)
                    if status == "started" then
                        formattedAddChatMessage(string.format("Started function: {%06x}%s", clr_GREEN, name))
                    else
                        formattedAddChatMessage(string.format("Function %s is already started", name), clr_REALRED)
                    end
                end)
            end
            return
        elseif action == "stop" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s stop [function_name]'", alias, cmd), clr_GREY)
            else
                functionManager.stop(target, function(name, status)
                    if status == "stopped" then
                        formattedAddChatMessage(string.format("Stopped function: {%06x}%s", clr_RED, name))
                    else
                        formattedAddChatMessage(string.format("Function %s is already stopped", name), clr_REALRED)
                    end
                end)
            end
            return
        elseif action == "restart" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s restart [function_name]'", alias, cmd), clr_GREY)
            else
                functionManager.restart(target, function(name, status)
                    formattedAddChatMessage(string.format("Restarted function: {%06x}%s", clr_YELLOW, name))
                end)
            end
            return
        elseif action == "status" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s status [function_name]'", alias, cmd), clr_GREY)
            else
                formattedAddChatMessage(string.format("Status %s: {%06x}%s", target:upperFirst(), clr_GREY, functionManager.getErrorStatus(target)))
            end
            return
        else
                formattedAddChatMessage(string.format("USAGE: '/%s %s [start|stop|restart] [function_name]'", alias, cmd), clr_GREY)
            return
        end
    end,
    ["names"] = function()
        menu.Names.window[0] = not menu.Names.window[0]
    end,
    ["charges"] = function()
        menu.Charges.window[0] = not menu.Charges.window[0]
    end,
    ["skins"] = function()
        menu.Skins.window[0] = not menu.Skins.window[0]
    end,
    ["bms"] = function()
        menu.BlackMarket.window[0] = not menu.BlackMarket.window[0]
    end,
    ["locker"] = function()
        menu.FactionLocker.window[0] = not menu.FactionLocker.window[0]
    end,
    ["reload"] = function()
        saveAllConfigs()
        formattedAddChatMessage("Reloading script... please wait.")
        lua_thread.create(function()
            wait(0)
            thisScript():reload()
        end)
    end,
    ["betatesters"] = function()
        if not betatesters then
            formattedAddChatMessage("Failed to fetch betatesters data.", clr_RED)
            return
        end

        formattedAddChatMessage("__________________ Betatesters _________________")
        for _, tester in ipairs(betatesters) do
            formattedAddChatMessage(string.format("%s | Bugs Found: %s | Hours Wasted: %s | Discord: %s.", tester.nickName, tester.bugFinds, convertDecimalToHours(tester.hoursWasted), tester.discord))
        end
        formattedAddChatMessage("_______________________________________________")
    end,
    ["changelog"] = function()
        menu.Changelog.window[0] = not menu.Changelog.window[0]
    end,
    ["debug"] = function()
        autobind.Settings.enableDebugMessages = not autobind.Settings.enableDebugMessages
        formattedAddChatMessage(string.format("Debug messages are now %s.", autobind.Settings.enableDebugMessages and "enabled" or "disabled"))
    end
}

function registerAutobindCommands()
    local function handleChatCommand(alias, params)
        local command, newParams = params:match("^(%S*)%s*(.*)")
        if autobindCommands[command] then
            local success, err = pcall(autobindCommands[command], newParams, command, alias)
            if not success then
                formattedAddChatMessage(string.format("Error in command /%s: %s", command, err))
            end
        else
            formattedAddChatMessage(string.format("USAGE: '/%s help' for more information.", alias))
        end
    end

    for _, command in pairs({scriptName, shortName}) do
        if sampIsChatCommandDefined(command) then
            sampUnregisterChatCommand(command)
        end

        sampRegisterChatCommand(command, function(params)
            handleChatCommand(command, params)
        end)
    end
end

function registerClientCommands()
    for _, command in pairs(clientCommands) do
        if sampIsChatCommandDefined(command.cmd) then
            sampUnregisterChatCommand(command.cmd)
        end

        if command.alt then
            for _, alt in ipairs(command.alt) do
                if sampIsChatCommandDefined(alt) then
                    sampUnregisterChatCommand(alt)
                end

                sampRegisterChatCommand(alt, function(params)
                    local success, error = pcall(command.func, alt, params)
                    if not success then
                        print(string.format("Error in command /%s: %s", alt, error))
                    end
                end)
            end
        end

        sampRegisterChatCommand(command.cmd, function(params)
            local success, error = pcall(command.func, command.cmd, params)
            if not success then
                print(string.format("Error in command /%s: %s", command.cmd, error))
            end
        end)
    end
end

function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		for _, command in pairs(clientCommands) do
			sampUnregisterChatCommand(command.cmd)
		end
	end
end

local messageHandlers = {
    {   -- Time Change (Auto Capture)
        pattern = "^The time is now (%d+):(%d+)%.$", -- The time is now 22:00.
        color = clrRGBA["WHITE"],
        action = function(hour, minute)
            lua_thread.create(function()
                wait(0)
                handleCapture(autobind.Settings.mode)
            end)

            if hour and minute then
                return {clrRGBA["WHITE"], string.format("The time is now %s:%s.", hour, minute)}
            end
        end
    },
    {   -- Welcome to Horizon Roleplay, Firstname Lastname.
        pattern = "^Welcome to Horizon Roleplay, (.-)%.$",
        color = clrRGBA["NEWS"],
        action = function(name)
            if name then
                -- Set current player name and id
                autobind.CurrentPlayer.name = name:gsub("%s+", "_")
                autobind.CurrentPlayer.id = sampGetPlayerIdByNickname(autobind.CurrentPlayer.name)

                -- Reset vehicle storage status
                initializeVehicleStorage()

                if currentContent and autobind.Settings.checkForUpdates then
                    if updateStatus == "new_version" then
                        formattedAddChatMessage(string.format("A new version of %s %s is available, please update to the latest version %s.", scriptName, scriptVersion, currentContent.version), clr_NEWS)
                    elseif updateStatus == "outdated" then
                        formattedAddChatMessage(string.format("%s %s is outdated, please update to the latest version %s.", scriptName, scriptVersion, currentContent.version), clr_NEWS)
                    end
                end

                autobind.CurrentPlayer.welcomeMessage = true

                -- Save settings
                configs.saveConfigWithErrorHandling(Files.currentplayer, autobind.CurrentPlayer)
                configs.saveConfigWithErrorHandling(Files.vehiclestorage, autobind.VehicleStorage)

                return {clrRGBA["NEWS"], string.format("Welcome to Horizon Roleplay, {%06x}%s.", clr_GREY, name)}
            end
        end
    },
    {   -- Muted Message
        pattern = "^You have been muted automatically for spamming%. Please wait 10 seconds and try again%.$",
        color = clrRGBA["YELLOW"],
        action = function()
            timers.Muted.last = os.clock()
        end
    },
    {   -- Admin On-Duty
        pattern = '^You are now on%-duty as admin and have access to all your commands, see /ah.$',
        color = clrRGBA["YELLOW"],
        action = function()
            setSampfuncsGlobalVar("aduty", 1)
        end
    },
    {   -- Admin Off-Duty
        pattern = '^You are now off%-duty as admin, and only have access to /admins /check /jail /ban /sban /kick /skick /showflags /reports /nrn$',
        color = clrRGBA["YELLOW"],
        action = function()
            setSampfuncsGlobalVar("aduty", 0)
        end
    },
    {   -- ARES Radio
        pattern = "^%*%*%s*(.-):%s*(.-)%s*%*%*$",
        color = clrRGBA["TEAM_FBI_COLOR"],
        action = function(header, message)
            -- Check if settings and faction modifications are enabled
            if not (autobind.Settings and autobind.Faction and autobind.Faction.modifyRadioChat) then
                return
            end

            -- Check if faction type and ranks are valid
            local factionType = autobind.Faction.type
            local factionRanks = factions.ranks[factionType]
            if not (factionType and factionRanks) then
                return
            end

            -- Determine rank and player name from the header
            local rank, playerName, div
            local skipDiv = false

            for _, v in ipairs(factionRanks) do
                if header:match("^" .. v .. "%s*") then
                    rank = v
                    skipDiv = true
                    break
                elseif header:match("%s*" .. v .. "%s*") then
                    rank = v
                    break
                end
            end

            if not rank then
                return
            end

            -- Remove rank from header and extract player name and division
            local spaceOrStart = skipDiv and "^" or "%s*"
            local newHeader = header:gsub(spaceOrStart .. rank .. "%s*", " ")
            if skipDiv then
                playerName = newHeader:trim()
            else
                div, playerName = newHeader:match("^(.-)%s+(.-)$")
            end

            -- Format and return the modified radio chat message
            if playerName then
                local playerId = sampGetPlayerIdByNickname(playerName:gsub("%s+", "_"))
                local divOrRank = skipDiv and rank or string.format("%s %s", div, rank)
                return {
                    clrRGBA["TEAM_FBI_COLOR"],
                    string.format("** %s %s (%d): {%06x}%s", divOrRank, playerName, playerId, clr_GREY, message)
                }
            end
        end
    },
    {   -- Mode/Frequency
        pattern = "^([Family|" .. table.concat(factions.names, "|") .. "|LSFMD].+) MOTD: (.+)",
        color = clrRGBA["YELLOW"],
        action = function(type, motdMsg)
            if type:match("Family") then
                autobind.Settings.mode = type

                --[[local freq, allies = motdMsg:match("[Ff]req:?%s*(-?%d+)%s*[/%s]*[Aa]llies:?%s*([^,]+)")
                if freq and allies then
                    print("Frequency detected", freq)
                    currentFamilyFreq = freq

                    print("Allies detected", allies)

                    local newMessage = motdMsg:gsub("[Ff]req:?%s*(-?%d+)", "")
                    newMessage = newMessage:gsub("^%s*,%s*", "")
                    print("New message: " .. newMessage)

                    sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr_DEPTRADIO, type, newMessage), -1)
                    return false
                end

                -- Family MOTD: F: -3232 A: LS.
                -- Family MOTD: F: -3232 // A: TC // discord.gg/GYwedAXGzV // MASS RECRUIT!.

                local freq2, allies2 = motdMsg:match("F: -3232 // A: TC // discord.gg/GYwedAXGzV // MASS RECRUIT!.")
                if freq2 and allies2 then

                end]]

                configs.saveConfigWithErrorHandling(Files.settings, autobind.Settings)
                configs.saveConfigWithErrorHandling(Files.family, autobind.Family)

                return {clrRGBA["DEPTRADIO"], string.format("Family MOTD: %s", motdMsg)}
            elseif type:match("[LSPD|SASD|FBI|ARES|GOV]") then
                autobind.Settings.mode = "Faction"
                autobind.Faction.type = type

                -- Enable wanted list because you are now in faction mode.
                wanted.lawyer = true

                if accepter.enable then
                    formattedAddChatMessage("Auto Accept is now disabled because you are now in Faction Mode.")
                    accepter.enable = false
                end

                if type == "ARES" then
                    local aresPriceMapping = {
                        ["SPAS-12"] = 3200,
                        ["MP5"]    = 250,
                        ["M4"]     = 2100,
                        ["AK-47"]  = 2100,
                        ["Sniper"] = 5500
                    }

                    for i, item in ipairs(lockers.FactionLocker.Items) do
                        if aresPriceMapping[item.label] then
                            item.price = aresPriceMapping[item.label]
                        end
                    end
                end

                --[[local freqType, freq = motdMsg:match("[/|%s*]%s*([RL FREQ:|FREQ:].-)%s*(-?%d+)")
                if freqType and freq then
                    print("Faction frequency detected: " .. freq)
                    currentFactionFreq = freq

                    local newMessage = motdMsg:gsub(freqType .. "%s*" .. freq:gsub("%-", "%%%-") .. "%s*", "")
                    newMessage = newMessage:gsub("%s*/%s*/%s*", " / ")

                    sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr_DEPTRADIO, type, newMessage), -1)
                    return false
                end]]

                configs.saveConfigWithErrorHandling(Files.settings, autobind.Settings)
                configs.saveConfigWithErrorHandling(Files.faction, autobind.Faction)

                return {clrRGBA["DEPTRADIO"], string.format("%s MOTD: %s", type, motdMsg)}
            elseif type:match("LSFMD") then
                autobind.Settings.mode = "Faction"
                autobind.Faction.type = type

                -- Enable wanted list because you are now in faction mode.
                wanted.lawyer = true

                configs.saveConfigWithErrorHandling(Files.settings, autobind.Settings)
                configs.saveConfigWithErrorHandling(Files.faction, autobind.Faction)

                return {clrRGBA["DEPTRADIO"], string.format("%s MOTD: %s", type, motdMsg)}
            end
        end
    },
    {   -- Set Frequency Message
        pattern = "You have set the frequency of your portable radio to (-?%d+) kHz.",
        color = clrRGBA["WHITE"],
        action = function(freq)
            if tonumber(freq) == 0 then
                if autobind.Settings.mode == "Family" then
                    currentFamilyFreq = 0
                    autobind.Family.frequency = 0
                elseif autobind.Settings.mode == "Faction" then
                    currentFactionFreq = 0
                    autobind.Faction.frequency = 0
                end
            else
                formattedAddChatMessage(string.format("You have set the frequency to your {%06x}%s {%06x}portable radio.", clr_DEPTRADIO, autobind.Settings.mode, clr_WHITE))
                return false
            end
        end
    },
    {   -- Radio Message
        pattern = "%*%* Radio %((%-?%d+) kHz%) %*%* (.-): (.+)",
        color = clrRGBA["PUBLICRADIO_COLOR"],
        action = function(freq, playerName, message)
            local playerId = sampGetPlayerIdByNickname(playerName:gsub("%s+", "_"))
            if playerId then
                local playerColor = sampGetPlayerColor(playerId)
                return {clrRGBA["PUBLICRADIO_COLOR"], string.format("** %s Radio ** {%06x}%s (%d){%06x}: %s", autobind.Settings.mode, colors.changeAlpha(playerColor, 0), playerName, playerId, clr_PUBLICRADIO_COLOR, message)}
            end
        end
    },
    {   -- Autocap Disabled
        pattern = "^Your gang is already attempting to capture this turf%.$",
        color = clrRGBA["GRAD1"],
        action = function()
            if autoCapture then
                local mode = autobind.Settings.mode
                formattedAddChatMessage(string.format("Your %s is already attempting to capture this turf! Disabling Auto Capture.", mode:lower()), clr_GRAD1)
                autoCapture = false
                return false
            end
        end
    },
    {   -- Turf Not Ready
        pattern = "This turf is not ready for takeover yet.",
        color = clrRGBA["GRAD1"],
        action = function()
            if autoCapture then
                
            end
        end
    },
    {   -- You are not high rank enough to capture!
        pattern = "^You are not high rank enough to capture!$",
        color = clrRGBA["GRAD1"],
        action = function()
            local toggle = false
            if autoCapture then
                autoCapture = false
                formattedAddChatMessage("You are not high rank enough to capture! Disabling Auto Capture.", clr_GRAD1)
                toggle = true
            end

            if autobind.Faction.turf and autobind.Settings.mode == "Faction" then
                formattedAddChatMessage("You have capture at signcheck enabled, disabling that now.", clr_GRAD1)
                autobind.Faction.turf = false
                toggle = true
            end

            if toggle then
                return false
            end
        end
    },
    {   -- Bodyguard Not Near (Same as other commands not sure what i wanna do yet)
        pattern = "That player isn't near you%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autobind.AutoVest.guardFeatures then
                if bodyguard.received then
                    bodyguard.received = false
                    setTimer(1.0, timers.Vest)
                end

                return {clrRGBA["GREY"], "That player isn't near you."}
            end
        end
    },
    {   -- Can't Guard While Aiming
        pattern = "You can't /guard while aiming%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autobind.AutoVest.guardFeatures then
                if bodyguard.received then
                    bodyguard.received = false
                    setTimer(1.0, timers.Vest)

                    return {clrRGBA["GREY"], "You can't /guard while aiming."}
                end
            end
        end
    },
    {   -- Must Wait Before Selling Vest
        pattern = "You must wait (%d+) seconds? before selling another vest%.?",
        color = clrRGBA["GREY"],
        action = function(cooldown)
            if autobind.AutoVest.guardFeatures then
                cooldown = tonumber(cooldown)
                bodyguard.received = false
                setTimer(cooldown + 0.5, timers.Vest)

                if cooldown > 1 then
                    return {clrRGBA["GREY"], string.format("You must wait %s seconds before selling another vest.", cooldown)}
                end
                return false
            end
        end
    },
    {   -- Offered Protection
        pattern = "%* You offered protection to (.+) for %$([%d,]+)%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            if autobind.AutoVest.guardFeatures then
                bodyguard.playerName = nickname:gsub("%s+", "_")
                bodyguard.playerId = sampGetPlayerIdByNickname(bodyguard.playerName)

                -- Remove commas from the price string
                local cleanPrice = price:gsub(",", "")
                bodyguard.price = tonumber(cleanPrice)

                if bodyguard.received then
                    bodyguard.received = false
                    timers.Vest.last = os.clock()
                end

                if bodyguard.playerName ~= "" and bodyguard.playerId ~= -1 then
                    return {clrRGBA["LIGHTBLUE"], string.format("* You offered protection to %s (%d) for $%s.", nickname, bodyguard.playerId, price)}
                end
            end
        end
    },
    {   -- Not a Bodyguard
        pattern = "You are not a bodyguard%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autobind.AutoVest.guardFeatures then
                bodyguard.enable = false
                bodyguard.playerName = ""
                bodyguard.playerId = -1
                bodyguard.received = false

                return {clrRGBA["GREY"], "You are not a bodyguard, temporarily disabling autovest until you are a bodyguard again."}
            end
        end
    },
    {   -- Now a Bodyguard
        pattern = "%* You are now a Bodyguard, type %/help to see your new commands%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autobind.AutoVest.guardFeatures then
                bodyguard.enable = true
                bodyguard.received = false

                return {clrRGBA["LIGHTBLUE"], "You are now a bodyguard, enabling autovest."}
            end
        end
    },
    {   -- Accept Vest
        pattern = "You are not near the person offering you guard!",
        color = clrRGBA["GRAD2"],
        action = function()
            if autobind.AutoVest.acceptFeatures then
                if accepter.received and accepter.playerName ~= "" and accepter.playerId ~= -1 then
                    if accepter.enable then
                        accepter.received = false
                    end

                    return {clrRGBA["GRAD2"], string.format("You are not close enough to %s (%d).", accepter.playerName:gsub("_", " "), accepter.playerId)}
                end
            end
        end
    },
    {   -- Protection Offer
        pattern = "^%* Bodyguard (.+) wants to protect you for %$([%d,]+)%, type %/accept bodyguard to accept%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            if autobind.AutoVest.acceptFeatures then
                accepter.playerName = nickname:gsub("%s+", "_")
                accepter.playerId = sampGetPlayerIdByNickname(accepter.playerName)
                
                -- Remove commas from the price string
                local cleanPrice = price:gsub(",", "")
                accepter.price = tonumber(cleanPrice)

                accepter.thread = lua_thread.create(function()
                    wait(0)
                    if accepter.price ~= 200 then
                        accepter.received = true
                        accepter.thread = nil
                        return
                    end

                    if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 and ((accepter.enable and not checkHeal()) or (accepter.enable and enteredPoint)) and not checkMuted() then
                        sampSendChat("/accept bodyguard")
                        wait(1000)
                    end

                    accepter.received = true
                    accepter.thread = nil
                end)

                if accepter.playerName ~= "" and accepter.playerId ~= -1 then
                    local accept = autobind.Keybinds.Accept
                    local acceptType = accept.Toggle and string.format("press %s to accept", getKeybindKeys("Accept")) or "type /accept bodyguard to accept"
                    return {clrRGBA["LIGHTBLUE"], string.format("* %s (%d) wants to protect you for $%s, %s.", nickname, accepter.playerId, price, acceptType)}
                end
            end
        end
    },
    {   -- You Accepted Protection
        pattern = "^%* You accepted the protection for %$(%d+) from (.+)%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(price, nickname)
            if autobind.AutoVest.acceptFeatures then
                local playerId = accepter.playerId

                if accepter.thread and accepter.enable then
                    accepter.thread:terminate()
                    accepter.thread = nil
                end

                accepter.playerName = ""
                accepter.playerId = -1
                accepter.received = false
                accepter.price = 0
                return {clrRGBA["LIGHTBLUE"], string.format("* You accepted the protection for $%d from %s (%d).", price, nickname, playerId)}
            end
        end
    },
    {   -- They Accepted Protection
        pattern = "%* (.+) accepted your protection, and the %$(%d+) was added to your money.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            if autobind.AutoVest.acceptFeatures then
                local playerId = bodyguard.playerId
                    
                bodyguard.playerName = ""
                bodyguard.playerId = -1
                bodyguard.received = false
                return {clrRGBA["LIGHTBLUE"], string.format("* %s (%d) accepted your protection, and the $%d was added to your money.", nickname, playerId, price)}
            end
        end
    },
    {   -- Can't Afford Protection
        pattern = "You can't afford the Protection!",
        color = clrRGBA["GREY"],
        action = function()
            if autobind.AutoVest.acceptFeatures then
                accepter.received = false

                return {clrRGBA["GREY"], "You can't afford the protection!"}
            end
        end
    },
    {   -- Can't Use Locker Recently Shot
        pattern = "You can't use your lockers if you were recently shot.",
        color = clrRGBA["WHITE"],
        action = function()
            formattedAddChatMessage("You can't use your lockers if you were recently shot. Timer extended by 5 seconds.")
            setTimer(5, timers.Heal)

            lockers["FactionLocker"].isBindActive = false
            if lockers["FactionLocker"].thread then
                lockers["FactionLocker"].thread:terminate()
            end

            return false
        end
    },
    {   -- Heal Timer Extended
        pattern = "^You can't heal if you were recently shot, except within points, events, minigames, and paintball%.$",
        color = clrRGBA["WHITE"],
        action = function()
            formattedAddChatMessage("You can't heal after being attacked recently. Timer extended by 5 seconds.")
            setTimer(5, timers.Heal)
            return false
        end
    },
    {   -- Not Diamond Donator
        pattern = "^You are not a Diamond Donator%!",
        color = clrRGBA["GREY"],
        action = function()
            timers.Vest.timer = guardTime
            autobind.AutoVest.donor = false
        end
    },
    {   -- Not Sapphire or Diamond Donator
        pattern = "^You are not a Sapphire or Diamond Donator%!",
        color = clrRGBA["GREY"],
        action = function()
            if lockers.BlackMarket.getItemFrom > 0 then
                lockers.BlackMarket.getItemFrom = 0
                lockers.BlackMarket.gettingItem = false
            end
        end
    },
    {   -- Not at Black Market
        pattern = "^%s*You are not at the black market%!",
        color = clrRGBA["GRAD2"],
        action = function()
            if lockers.BlackMarket.getItemFrom > 0 then
                lockers.BlackMarket.getItemFrom = 0
                lockers.BlackMarket.gettingItem = false
            end
        end
    },
    {   -- Already Searched for Someone
        pattern = "^You have already searched for someone %- wait a little%.$",
        color = clrRGBA["GREY"],
        action = function()
            if not autobind.Settings.autoFind then
                return
            end

            if autofind.enable then
                autofind.received = false
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                setTimer(5.0, timers.Find)
            end
        end
    },
    {   -- Can't Find Person Hidden in Turf
        pattern = "^You can't find that person as they're hidden in one of their turfs%.$",
        color = clrRGBA["GREY"],
        action = function()
            if not autobind.Settings.autoFind then
                return
            end

            if autofind.enable and autofind.playerName ~= "" and autofind.playerId ~= -1 then
                autofind.received = false
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                formattedAddChatMessage(string.format("%s (ID: %d) is hidden in a turf. Autofind will try again in 5 seconds.", autofind.playerName:gsub("_", " "), autofind.playerId))
                setTimer(5.0, timers.Find)
                return false
            end
        end
    },
    {   -- Not a Detective
        pattern = "^You are not a detective%.$",
        color = clrRGBA["GREY"],
        action = function()
            if not autobind.Settings.autoFind then
                return
            end

            if autofind.enable then
                autofind.received = false
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                autofind.enable = false
                formattedAddChatMessage("You are no longer finding anyone because you are not a detective.")
                return false
            end
        end
    },
    {   -- Now a Detective
        pattern = "^%* You are now a Detective, type %/help to see your new commands%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if not autobind.Settings.autoFind then
                return
            end

            if autofind.playerName ~= "" and autofind.playerId ~= -1 then
                autofind.received = false
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                autofind.enable = true
                setTimer(0.1, timers.Find)
                formattedAddChatMessage(string.format("You are now a detective and re-enabling autofind on %s (ID: %d).", autofind.playerName:gsub("_", " "), autofind.playerId))
                return false
            end
        end
    },
    {   -- Unable to Find Person
        pattern = "^You are unable to find this person%.$",
        color = clrRGBA["GREY"],
        action = function()
            if not autobind.Settings.autoFind then
                return
            end

            if autofind.enable then
                autofind.received = false
                autofind.counter = autofind.counter + 1
                if autofind.counter >= 5 then
                    autofind.enable = false
                    autofind.playerId = -1
                    autofind.playerName = ""
                    autofind.counter = 0
                    formattedAddChatMessage("You are no longer finding anyone because you are unable to find this person.")
                    return false
                end
                setTimer(5, timers.Find)
            end
        end
    },
    {   -- Cross Devil has been last seen at <optional location>.
        pattern = "^(.+) has been last seen at%s*(.-)%.$",
        color = clrRGBA["GRAD2"],
        action = function(nickname, location)
            if not autobind.Settings.autoFind then
                return
            end

            local cleanLocation = location:match("^%s*(.-)%s*$") or ""

            if autofind.enable then
                timers.Find.last = os.clock()
                autofind.received = false
                if autofind.playerName:gsub("_", " "):match(nickname) then
                    autofind.location = cleanLocation
                end

                return {clrRGBA["GRAD2"], string.format("%s (%d) has been last seen %s.", nickname, autofind.playerId, (cleanLocation == "" and "out of the map or no location was provided" or string.format("at {%06x}%s", clr_YELLOW, cleanLocation)))}
            end
        end
    },
    {   -- SMS: I need the where-abouts of Player Name, Sender: Player Name (Phone Number)
        pattern = "^SMS: I need the where%-abouts of ([^,]+), Sender: ([^%(]+)%((%d+)%)$",
        color = clrRGBA["YELLOW"],
        action = function(nickname, sender, phonenumber)
            if not autobind.Settings.autoFind then
                return
            end

            if autofind.enable then
                timers.Find.last = os.clock()
                autofind.received = false
            end
        end
    },
    {   -- Your backup request has been cleared.
        pattern = "^Your backup request has been cleared%.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            return {clrRGBA["GRAD2"], "Your backup request has been cleared."}
        end
    },
    {   -- You already have an active backup request!
        pattern = "^You already have an active backup request!$",
        color = clrRGBA["GREY"],
        action = function()
            backup.enable = true
            return {clrRGBA["GRAD2"], "You already have an active backup request!"}
        end
    },
    {   -- You don't have an active backup request!
        pattern = "^You don't have an active backup request!$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            return {clrRGBA["GRAD2"], "You don't have an active backup request!"}
        end
    },
    {   -- Your backup request has been cleared automatically.
        pattern = "^Your backup request has been cleared automatically.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            return {clrRGBA["GRAD2"], "Your backup request has been cleared automatically."}
        end
    },
    {   -- Requesting immediate backup
        pattern = "^(.+) is requesting immediate backup at%s*(.-)%.$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(nickname, location)
            local cleanLocation = location:match("^%s*(.-)%s*$") or ""
            local playerId = sampGetPlayerIdByNickname(nickname:gsub("%s+", "_"))
            local playerColor = sampGetPlayerColor(playerId)
            if playerId and cleanLocation then
                local _, localPlayerId = sampGetPlayerIdByCharHandle(ped)
                if localPlayerId == playerId then
                    backup.enable = true
                else
                    backup.playerName = nickname
                    backup.playerId = playerId
                    backup.location = location
                end
                return {clrRGBA["WHITE"], string.format("{%06x}%s (%d) {%06x}is requesting immediate backup %s.", colors.changeAlpha(playerColor, 0), nickname, playerId, clr_GREY, (cleanLocation == "" and "out of the map or no location was provided" or string.format("at {%06x}%s", clr_YELLOW, cleanLocation)))}
            end
        end
    },
    {   -- You have cleared your beacon.
        pattern = "^You have cleared your beacon.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            return {clrRGBA["GRAD2"], "You have cleared your beacon."}
        end
    },
    {   -- Your beacon has been cleared automatically.
        pattern = "^Your beacon has been cleared automatically.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            return {clrRGBA["GRAD2"], "Your beacon has been cleared automatically."}
        end
    },
    {   -- Requesting help
        pattern = "^(.+) is requesting help at (.+).$",
        color = clrRGBA["YELLOW"],
        action = function(nickname, location)
            local playerId = sampGetPlayerIdByNickname(nickname:gsub("%s+", "_"))
            if playerId and location then
                local _, localPlayerId = sampGetPlayerIdByCharHandle(ped)
                if localPlayerId == playerId then
                    backup.enable = true
                else
                    backup.playerName = nickname
                    backup.playerId = playerId
                    backup.location = location
                end
                return {clrRGBA["YELLOW"], string.format("%s (%d) is requesting help at %s.", nickname, playerId, location)}
            end
        end
    },
    {   -- Accept Repair
        pattern = "^%* Car Mechanic (.+) wants to repair your car for %$1, %(type %/accept repair%) to accept%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autobind.Settings.autoRepair and not checkMuted() and not checkAdminDuty() then
                lua_thread.create(function()
                    wait(0)
                    sampSendChat("/accept repair")
                end)
            end
        end
    },
    {   -- Auto Badge (ARES)
        pattern = "^Your hospital bill [comes to %%$%%d+%%%. Have a nice day%!$|was paid for by your faction insurance%.$]",
        color = clrRGBA["TEAM_MED_COLOR"],
        action = function()
            if backup.enable then
                backup.enable = false
            end

            if autobind.Faction.autoBadge and not checkMuted() and not checkAdminDuty() then
                if autobind.Settings.mode == "Faction" then
                    lua_thread.create(function()
                        wait(0)
                        sampSendChat("/badge")
                    end)
                end
            end
        end
    },
    {   -- Help Command Additions
        pattern = "^%*%*%* OTHER %*%*%* /cellphonehelp /carhelp /househelp /toyhelp /renthelp /jobhelp /leaderhelp /animhelp /fishhelp /insurehelp /businesshelp /bankhelp",
        color = clrRGBA["WHITE"],
        action = function()
            lua_thread.create(function()
                wait(0)
                local cmds = clientCommands
                
                -- Collect all command names
                local allCommands = {}
                for cmdName, cmdData in pairs(cmds) do
                    if cmdData.cmd then
                        table.insert(allCommands, cmdData.cmd)
                    end
                end
                
                -- Add the main command and help command
                table.insert(allCommands, 1, shortName)
                table.insert(allCommands, 2, shortName .. " help")
                
                -- Maximum length for a chat message (leaving room for the prefix)
                local maxMessageLength = 128  -- Adjust this based on the actual limit
                local prefixFormat = "*** AUTOBIND *** "
                
                local messages = {}
                local currentMessage = {}
                local currentLength = 0
                
                -- Calculate how many commands we can fit per message
                for _, cmd in ipairs(allCommands) do
                    local cmdWithSlash = "/" .. cmd
                    local cmdLength = string.len(cmdWithSlash) + 1  -- +1 for the space
                    
                    -- If adding this command would exceed the limit, start a new message
                    if currentLength + cmdLength > maxMessageLength - string.len(prefixFormat) then
                        if #currentMessage > 0 then
                            table.insert(messages, currentMessage)
                            currentMessage = {}
                            currentLength = 0
                        end
                    end
                    
                    -- Add command to current message
                    table.insert(currentMessage, cmdWithSlash)
                    currentLength = currentLength + cmdLength
                end
                
                -- Add the last message if it has any commands
                if #currentMessage > 0 then
                    table.insert(messages, currentMessage)
                end
                
                -- Display all messages
                local totalMessages = #messages
                for i, msgCommands in ipairs(messages) do
                    local message = prefixFormat .. table.concat(msgCommands, " ")
                    sampAddChatMessage(message, clr_WHITE)
                end
            end)
        end
    },
    {   -- * (.+) opens a can of sprunk.
        pattern = "^%* (.+) opens a can of sprunk.$",
        color = clrRGBA["PURPLE"],
        action = function(nickname)
            usingSprunk = true
            return {clrRGBA["PURPLE"], string.format("%s opens a can of sprunk.", nickname)}
        end
    },
    {   -- Dropped Sprunk
        pattern = "^(.+) drops their sprunk onto the floor.$",
        color = clrRGBA["PURPLE"],
        action = function(nickname)
            usingSprunk = false
            return {clrRGBA["PURPLE"], string.format("%s drops their sprunk onto the floor.", nickname)}
        end
    },
    {   -- You already have full health.
        pattern = "^You already have full health.$",
        color = clrRGBA["GREY"],
        action = function()
            if usingSprunk then
                usingSprunk = false
            end
        end
    },
    {   -- "You have stored your (.-)%. The vehicle has been (.-)%."
        pattern = "You have stored your (.-)%. The vehicle has been despawned%.",
        color = clrRGBA["WHITE"],
        action = function(vehName)
            updateVehicleStorage("Stored", vehName)
            return {clrRGBA["WHITE"], string.format("* You have stored your %s. The vehicle has been despawned.", vehName)}
        end
    },
    {   -- "You have taken your (.-) out of storage%. The vehicle has been (.-) at the last parking location%."
        pattern = "You have taken your (.-) out of storage%. The vehicle has been spawned at the last parking location%.",
        color = clrRGBA["WHITE"],
        action = function(vehName)
            updateVehicleStorage("Spawned", vehName)
            return {clrRGBA["WHITE"], string.format("* You have taken your %s out of storage. The vehicle has been spawned at the last parking location.", vehName)}
        end
    },
    {   -- Your (.-) has been sent to the location at which you last parked it.
        pattern = "Your (.-) has been sent to the location at which you last parked it%.$",
        color = clrRGBA["GRAD1"],
        action = function(vehName)
            updateVehicleStorage("Spawned", vehName)
            return {clrRGBA["GRAD1"], string.format("* Your %s has been sent to the location at which you last parked it.", vehName)}
        end
    },
    {   -- You cannot store this vehicle as someone is currently occupying it.
        pattern = "You can not store this vehicle as someone is currently occupying it%.$",
        color = clrRGBA["GREY"],
        action = function()
            updateVehicleStorage("Occupied", nil)
            return {clrRGBA["GREY"], "* You cannot store this vehicle as someone is currently occupying it."}
        end
    },
    {   -- This vehicle is too damaged to be stored.
        pattern = "This vehicle is too damaged to be stored%.$",
        color = clrRGBA["GREY"],
        action = function()
            updateVehicleStorage("Damaged", nil)
            return {clrRGBA["GREY"], "* This vehicle is too damaged to be stored."}
        end
    },
    {   -- You can't spawn a disabled vehicle. It is disabled due to your Donator level (vehicle restrictions).
        pattern = "^You can't spawn a disabled vehicle. It is disabled due to your Donator level %(vehicle restrictions%)%.$",
        color = clrRGBA["WHITE"],
        action = function()
            updateVehicleStorage("Disabled", nil)
            return {clrRGBA["WHITE"], "* You can't spawn a disabled vehicle. It is disabled due to your Donator level (vehicle restrictions)."}
        end
    },
    {   -- You can't spawn an impounded vehicle. If you wish to reclaim it, do so at the DMV in Dillimore.
        pattern = "^You can't spawn an impounded vehicle. If you wish to reclaim it, do so at the DMV in Dillimore%.$",
        color = clrRGBA["WHITE"],
        action = function()
            updateVehicleStorage("Impounded", nil)
            return {clrRGBA["WHITE"], "* You can't spawn an impounded vehicle. If you wish to reclaim it, do so at the DMV in Dillimore."}
        end
    },
    {   -- You have failed to pick the lock!
        pattern = "^You have failed to pick the lock%!$",
        color = clrRGBA["WHITE"],
        action = function()
            if autobind.Settings.autoPicklockOnFail then
                lua_thread.create(function()
                    wait(0)
                    sampSendChat("/picklock")
                end)
            end
        end
    },
    {   -- You have successfully picked the lock of this vehicle.
        pattern = "^You have successfully picked the lock of this vehicle%.$",
        color = clrRGBA["WHITE"],
        action = function()
            if autobind.Settings.autoPicklockOnSuccess then
                lua_thread.create(function()
                    wait(0)
                    sampSendChat("/pvl")
                    wait(1000)
                    sampSendChat("/picklock")
                end)
            end
        end
    },
    {   -- * You have now started farming. You must load up this vehicle with the harvest.
        pattern = "^%* You have now started farming%. You must load up this vehicle with the harvest%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autobind.Settings.autoFarm then
                farmer.farming = true
            else
                sampShowDialog(dialogs.farmer.id2, string.format("[%s] Auto Farming", shortName:upper()), "Do you want to enable auto farming?\nThis will automatically type /farm and /harvest for you.", "Close", "Enable", 0)
            end
        end
    },
    {   -- * You received $225 for delivering the harvest.
        pattern = "^%* You received (.-) for delivering the harvest%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(amount)
            if autobind.Settings.autoFarm then
                lua_thread.create(function()
                    wait(0)

                    -- Start farming
                    farmer.farming = false

                    -- Send the /farm command
                    sampSendChat("/farm")

                    -- Reset the harvesting count
                    farmer.harvestingCount = 0
                end)
            end
        end
    },
    {   -- * You harvested X out of the 8 needed crops. Type /harvest to harvest some more crops.
        pattern = "^%* You harvested (.-) out of the 8 needed crops%. Type /harvest to harvest some more crops%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(cropsHarvested)
            if autobind.Settings.autoFarm then
                lua_thread.create(function()
                    wait(0)
                    sampSendChat("/harvest")

                    -- Set the harvesting count
                    farmer.harvestingCount = cropsHarvested
                end)
            end
        end
    },
    {   -- * You harvested 8 out of the 8 needed crops. Get inside your truck.
        pattern = "^%* You harvested 8 out of the 8 needed crops%. Get inside your truck%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autobind.Settings.autoFarm then
                lua_thread.create(function()
                    wait(0)
                    -- Enter the vehicle
                    local key = gkeys.player.ENTERVEHICLE
                    setGameKeyState(key, 255)
                    wait(0)
                    setGameKeyState(key, 0)

                    -- Stopped farming
                    farmer.harvesting = false

                    -- Harvested 8 crops
                    farmer.harvestingCount = 8

                    -- Close the dialog
                    if sampGetCurrentDialogId() == dialogs.farmer.id then
                        sampCloseCurrentDialogWithButton(1)
                    end
                end)
            end
        end
    },
    {   -- * You have arrived at your designated farming spot. Type /harvest to harvest some crops.
        pattern = "^%* You have arrived at your designated farming spot%. Type /harvest to harvest some crops%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autobind.Settings.autoFarm then
                lua_thread.create(function()
                    wait(0)

                    if not farmer.farming then
                        farmer.farming = true
                    end

                    -- Create the dialog
                    createFarmerDialog()

                    -- Stop the vehicle and exit
                    while isCharInAnyCar(ped) do
                        local vehid = storeCarCharIsInNoSave(ped)
                        if getCarSpeed(vehid) > 0.1 then
                            setGameKeyState(gkeys.vehicle.HANDBRAKE, 255)
                            wait(0)
                            setGameKeyState(gkeys.vehicle.HANDBRAKE, 0)
                        else
                            setGameKeyState(gkeys.vehicle.EXITVEHICLE, 255)
                            wait(100)
                            setGameKeyState(gkeys.vehicle.EXITVEHICLE, 0)
                        end
                    end

                    -- Start harvesting
                    farmer.harvesting = true
                    wait(500)
                    if isCharOnFoot(ped) then
                        sampSendChat("/harvest")
                    end
                end)
            end
        end
    },
    {   -- All current checkpoints, trackers and accepted fares have been reset.
        pattern = "^All current checkpoints, trackers and accepted fares have been reset%.$",
        color = clrRGBA["WHITE"],
        action = function()
            if farmer.farming then
                farmer.farming = false
                farmer.harvesting = false
                farmer.harvestingCount = 0
            end
        end
    },
    {   -- You have switched to faction ID %d+ ((.+))%.$
        pattern = "^You have switched to faction ID (%d+)%s*%((.+)%)%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(factionId, factionName)
            --[[if not autobind.Faction then
                return
            end]]

            print(factionId, factionName)
        end
    },
    {   -- * You sold your (.+) to (.+) for %$([%d,]+)%.$
        pattern = "^%* You sold your (.+) to (.+) for %$([%d,]+)%.$",
        color = clrRGBA["WHITE"],
        action = function(vehicle, buyer, price)
            print("You sold your " .. vehicle .. " to " .. buyer .. " for $" .. price .. ".")
        end
    },
    {   -- DIAMOND DONATOR: You have purchased an? (.-) for %$([%d,]+)%.
        pattern = "^DIAMOND DONATOR: You have purchased an? (.-) for %$([%d,]+)%.$",
        color = clrRGBA["BLUE"],
        action = function(item, price)
            if lockers.BlackMarket.isProcessing then
                return false
            end
        end
    },
    {   -- DIAMOND DONATOR: You have purchased full health and armor for %$350%.
        pattern = "^DIAMOND DONATOR: You have purchased full health and armor for %$350%.$",
        color = clrRGBA["BLUE"],
        action = function()
            if lockers.BlackMarket.isProcessing then
                return false
            end
        end
    },
    {   -- You have purchased an? (.+) for %$([%d,]+)%.$
        pattern = "^You have purchased an? (.-) for %$([%d,]+)%.$",
        color = clrRGBA["WHITE"],
        action = function(item, price)
            if lockers.FactionLocker.isProcessing then
                return false
            end
        end
    },
    {   -- HQ: All units APB - Reporter: Player Name
        pattern = "^HQ:%s*All%s*units%s*APB%s*-%s*Reporter:%s*%{%x+%}(.-)$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(reporter)
            factionChargeReporter = reporter
            if factionChargeReporter and autobind.Faction.hideChargeReporter then
                return false
            end
        end
    },
    {   -- HQ: Suspect: Player Name - Crime: Crime
        pattern = "^HQ:%s*Suspect:%s*%{%x+%}(.-)%{%x+%}%s*-%s*Crime:%s*%{%x+%}(.-)$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(suspect, crime)
            local id = sampGetPlayerIdByNickname(suspect:gsub(" ", "_"))
            updateWantedList("charged", "add", suspect, id, 1)

            if factionChargeReporter then
                autobind.Charges.List = autobind.Charges.List or {}
                autobind.Charges.List[suspect] = autobind.Charges.List[suspect] or {crimes = {}, totalCharges = 0, totalArrests = 0}
                
                local currentTime = os.time()
                table.insert(autobind.Charges.List[suspect].crimes, {
                    crime = crime,
                    reporter = factionChargeReporter,
                    timestamp = currentTime,
                    date = os.date("%Y-%m-%d %H:%M:%S", currentTime)
                })
                
                autobind.Charges.List[suspect].totalCharges = (autobind.Charges.List[suspect].totalCharges or 0) + 1

                if autobind.Faction.hideChargeReporter then
                    local reporter = factionChargeReporter
                    factionChargeReporter = nil
                    return {
                        clrRGBA["TEAM_BLUE_COLOR"], 
                        string.format("HQ: LEO: {%06x}%s{%06x} Suspect: {%06x}%s [%s]", clr_WHITE, reporter, clr_TEAM_BLUE_COLOR, clr_WHITE, suspect, crime)
                    }
                end
            end
        end
    },
    {   -- HQ: (.-) has returned to town and still has %d+ outstanding charge[s]?%.$
        pattern = "^HQ:%s*(.-)%s*has%s*returned%s*to%s*town%s*and%s*still%s*has%s*(%d+)%s*outstanding%s*charge[s]?%.$",
        color = clrRGBA["DEPTRADIO"],
        action = function(name, charges)
            charges = tonumber(charges)
            local id = sampGetPlayerIdByNickname(name:gsub(" ", "_"))
            updateWantedList("returned", "set", name, id, charges)
        end
    },
    {   -- HQ: (.-) has been reported for a robbery on a (.-) in (.-)%.$
        pattern = "^HQ:%s*(.-)%s*has been reported for a robbery on a%s*(.-)%s*in%s*(.-)%.$",
        color = clrRGBA["DEPTRADIO"],
        action = function(name, store, location)
            local id = sampGetPlayerIdByNickname(name:gsub(" ", "_"))
            updateWantedList("robbery", "add", name, id, 1)

            autobind.Charges.List = autobind.Charges.List or {}
            autobind.Charges.List[name] = autobind.Charges.List[name] or {crimes = {}, totalCharges = 0, totalArrests = 0}
            
            local currentTime = os.time()
            table.insert(autobind.Charges.List[name].crimes, {
                crime = "Robbery",
                reporter = "Store Clerk",
                timestamp = currentTime,
                date = os.date("%Y-%m-%d %H:%M:%S", currentTime)
            })
            
            autobind.Charges.List[name].totalCharges = (autobind.Charges.List[name].totalCharges or 0) + 1
        end
    },
    {   -- HQ: All units, officer Wajahat Bukhari has completed their assignment.
        pattern = "^HQ:%s*All%s*units,%s*officer%s*(.-)%s*has completed their assignment%.$",
        color = clrRGBA["ARRESTED"],
        action = function(name)
            factionArrestReporter = name
            if factionArrestReporter and autobind.Faction.hideArrestReporter then
                return false
            end
        end
    },
    {   -- HQ: Greg Ross has been processed, was arrested.
        pattern = "^HQ:%s*(.-)%s*has been processed, was arrested%.$",
        color = clrRGBA["ARRESTED"],
        action = function(name)
            checkWantedList("processed", name, nil)

            if factionArrestReporter then
                autobind.Charges.List = autobind.Charges.List or {}
                autobind.Charges.List[name] = autobind.Charges.List[name] or {crimes = {}, totalArrests = 0, totalCharges = 0}
                
                local currentTime = os.time()
                table.insert(autobind.Charges.List[name].crimes, {
                    crime = "Arrested",
                    reporter = factionArrestReporter,
                    timestamp = currentTime,
                    date = os.date("%Y-%m-%d %H:%M:%S", currentTime)
                })

                autobind.Charges.List[name].totalArrests = (autobind.Charges.List[name].totalArrests or 0) + 1

                configs.saveConfigWithErrorHandling(Files.charges, autobind.Charges)

                if autobind.Faction.hideArrestReporter then
                    local reporter = factionArrestReporter
                    factionArrestReporter = nil
                    return {
                        clrRGBA["TEAM_BLUE_COLOR"], 
                        string.format("HQ: %s has arrested %s.", reporter, name)
                    }
                end
            end
        end
    },
    {   -- * LEO (.-) has cleared (.+)'s records and outstanding charges%.$
        pattern = "^%*%s*LEO%s*(.+)%s*has%s*cleared%s*(.+)'s%s*records%s*and%s*outstanding%s*charges%.$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(name, suspect)
            checkWantedList("cleared", suspect, nil)
        end
    },
    {   -- Beginning of wanted list
        pattern = "^__________WANTED LIST__________$",
        color = clrRGBA["ORANGE"],
        action = function()
            checkWantedList("update", nil, nil)

            if not autobind.Wanted.Enabled then
                return
            end
            return false
        end
    },
    {   -- No current wanted suspects.
        pattern = "^No current wanted suspects%.$",
        color = clrRGBA["WHITE"],
        action = function()
            if not autobind.Wanted.Enabled then
                return
            end
            return false
        end
    },
    {   -- Charged Players
        pattern = "^(.+) %((%d+)%): %{%x+%}(%d+) outstanding charge[s]?%.$",
        color = clrRGBA["WHITE"],
        action = function(name, id, charges)
            updateWantedList("command", "set", name, tonumber(id), tonumber(charges))

            if not autobind.Wanted.Enabled then
                return
            end
            return false
        end
    },
    {   -- End of wanted list
        pattern = "^________________________________$",
        color = clrRGBA["ORANGE"],
        action = function()
            if not autobind.Wanted.Enabled then
                return
            end

            if wantedRefreshCount >= 10 then
                wantedRefreshCount = 0
                configs.saveConfigWithErrorHandling(Files.wanted, autobind.Wanted)
            end
            return false
        end
    },
    {   -- You are now a Lawyer, type /help to see your new commands.
        pattern = "^You are now a Lawyer, type /help to see your new commands%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            print("Lawyer enabled")
            wanted.lawyer = true
            clearWantedList()
        end
    },
    {   -- You're not a Lawyer / Cop / FBI!
        pattern = "^%s*You're not a Lawyer / Cop / FBI!$",
        color = clrRGBA["GREY"],
        action = function()
            print("Lawyer disabled")
            wanted.lawyer = false
            clearWantedList()
        end
    },
    {   -- Your first aid kit has been stopped, because you were damaged by another player.
        pattern = "^Your first aid kit has been stopped, because you were damaged by another player%.$",
        color = clrRGBA["WHITE"],
        action = function()
            print("First aid kit stopped")
            setTimer(10.0, timers.Heal)
        end
    },
    {   -- HQ: A barricade has been deployed by Player Name at Location (Cade: X).
        pattern = "^HQ:%s*A barricade has been deployed by%s*(.-)%s*at%s*(.-)%s*%(Cade:%s*(%d+)%)%.$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(name, location, cade)
            if getCurrentPlayingPlayer() == name:gsub(" ", "_") then
                sampAddChatMessage(string.format("HQ: A cade has been deployed by %s at %s (Cade: %s)", name, location, cade), clr_TEAM_BLUE_COLOR)
                sampAddChatMessage("You can remove a cade by typing /destroycade.", clr_YELLOW)
                return false
            end

            if autobind.Faction.showCadesLocal then
                for _, player in ipairs(getVisiblePlayers(150.0, "all")) do
                    if player.playerName == name:gsub(" ", "_") then
                        sampAddChatMessage(string.format("HQ: A cade has been deployed by %s at %s (Cade: %s)", name, location, cade), clr_TEAM_BLUE_COLOR)
                        sampAddChatMessage("You can remove a cade by typing /destroycade.", clr_YELLOW)
                        debugMessage(string.format("Cade deployed by %s (Dist: %d)", name, player.distance), true, true)
                        break
                    end
                end
                return false
            end

            if autobind.Faction.showCades then
                return
            end
            return false
        end
    },
    {   -- HQ: A barricade has been destroyed by Player Name at Location.
        pattern = "^HQ:%s*A barricade has been destroyed by%s*(.-)%s*at%s*(.-)%.$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(name, location)
            if getCurrentPlayingPlayer() == name:gsub(" ", "_") then
                sampAddChatMessage(string.format("HQ: A cade has been destroyed by %s at %s", name, location), clr_TEAM_BLUE_COLOR)
                return false
            end

            if autobind.Faction.showCadesLocal then
                for _, player in ipairs(getVisiblePlayers(150.0, "all")) do
                    if player.playerName == name:gsub(" ", "_") then
                        sampAddChatMessage(string.format("HQ: A cade has been destroyed by %s at %s", name, location), clr_TEAM_BLUE_COLOR)
                        debugMessage(string.format("Cade destroyed by %s (Dist: %d)", name, player.distance), true, true)
                        break
                    end
                end
                return false
            end

            if autobind.Faction.showCades then
                return
            end
            return false
        end
    },
    {   -- HQ: A spike has been (deployed, destroyed) by Player Name at Location.
        pattern = "^HQ:%s*A spike has been%s*(.-)%s*by%s*(.-)%s*at%s*(.-)%.$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(type, name, location)
            if getCurrentPlayingPlayer() == name:gsub(" ", "_") then
                sampAddChatMessage(string.format("HQ: A spike has been %s by %s at %s", type, name, location), clr_TEAM_BLUE_COLOR)
                if type == "deployed" then
                    sampAddChatMessage("You can remove a spike by typing /destroyspike.", clr_YELLOW)
                end
                return false
            end

            if autobind.Faction.showSpikesLocal then
                for _, player in ipairs(getVisiblePlayers(150.0, "all")) do
                    if player.playerName == name:gsub(" ", "_") then
                        sampAddChatMessage(string.format("HQ: A spike has been %s by %s at %s", type, name, location), clr_TEAM_BLUE_COLOR)
                        if type == "deployed" then
                            sampAddChatMessage("You can remove a spike by typing /destroyspike.", clr_YELLOW)
                            debugMessage(string.format("Spike deployed by %s (Dist: %d)", name, player.distance), true, true)
                        end
                        break
                    end
                end
                return false
            end

            if autobind.Faction.showSpikes then
                return
            end
            return false
        end
    },
    {   -- HQ: All (barricades, spikes, flares, cones, sirens) have been destroyed by Player Name.
        pattern = "^HQ:%s*All%s*(.-)%s*have been destroyed by%s*(.-)%.$",
        color = clrRGBA["DEPTRADIO"],
        altColor = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(type, name)
            if getCurrentPlayingPlayer() == name:gsub(" ", "_") then
                return
            end

            if type == "barricades" then
                if autobind.Faction.showCades then
                    return
                end
                return false
            end

            if type == "spikes" then
                if autobind.Faction.showSpikes then
                    return
                end
                return false
            end

            if type == "flares" then
                if autobind.Faction.showFlares then
                    return
                end
                return false
            end

            if type == "cones" then
                if autobind.Faction.showCones then
                    return
                end
                return false
            end
        end
    },
    {   -- You can remove a (barricade, spike) by typing (/destroycade, /destroyspike).
        pattern = "^You can remove a%s*(.-)%s*by typing%s*(.-)%.$",
        color = clrRGBA["YELLOW"],
        action = function(type, command)
            if type == "barricade" then
                if autobind.Faction.showCades or autobind.Faction.showCadesLocal then
                    return false
                end
            end

            if type == "spike" then
                if autobind.Faction.showSpikes or autobind.Faction.showSpikesLocal then
                    return false
                end
            end
        end
    },
    {   -- (.+) is attempting to take over of the (.+) for (.+), they'll own it in 10 minutes.
        pattern = "^(.-)%s*is attempting to take over of the%s*(.-)%s*for%s*(.-)%, they'll own it in 10 minutes%.$",
        color = clrRGBA["YELLOW"],
        action = function(name, location, captureBy)
            debugMessage("Point Started", true, true)
        end
    },
    {   -- (.+) is attempting to take control of (.+) for (.+) %(15 minutes remaining%).
        pattern = "^(.-)%s*is attempting to take control of%s*(.-)%s*for%s*(.-)%s*%(15 minutes remaining%)%.$",
        color = clrRGBA["YELLOW"],
        action = function(name, location, captureBy)
            if captureBy:match("^Law Enforcement$") then
                debugMessage("Turf Started by LEO", true, true)
            else
                debugMessage("Turf Started by " .. captureBy, true, true)
            end
        end
    },
    {   -- Player Name has taken control of (the) Location for (Law Enforcement, Family Name).
        pattern = "^(.-)%s*has taken control of%s*(.-)%s*for%s*(.-)%.$",
        color = clrRGBA["YELLOW"],
        action = function(name, location, captureBy)
            location = location:gsub("the ", "")
            local locationType = locationTypes[location]
            if locationType then
                if locationType == "turf" then
                    if captureBy:match("^Law Enforcement$") then
                        debugMessage("Turf Ended by LEO", true, true)
                    else
                        debugMessage("Turf Ended by " .. captureBy, true, true)
                    end
                    
                    if autoCapture and autobind.Settings.mode == "Family" and 
                    autobind.Family.turf and autobind.Family.disableAfterCapturing then
                        autoCapture = false
                        formattedAddChatMessage("Auto-capture has been disabled after failed turf capture.")
                    end
                elseif locationType == "point" then
                    debugMessage("Point Ended", true, true)
                    
                    if autoCapture and autobind.Settings.mode == "Family" and 
                    autobind.Family.point and autobind.Family.disableAfterCapturing then
                        autoCapture = false
                        formattedAddChatMessage("Auto-capture has been disabled after failed point capture.")
                    end
                end
            else
                debugMessage("Unknown location type: " .. location, true, true)
                return
            end
        end
    },
    {   -- Disable Blank Messages
        pattern = "^%s*$",
        color = clrRGBA["BLACK"],
        action = function()
            if not autobind.CurrentPlayer.welcomeMessage and autobind.Settings.blankMessagesAtConnection then
                return false
            end
        end
    }
}

function listSuspectCharges(suspect)
    if not autobind.Charges.List or not autobind.Charges.List[suspect] then
        formattedAddChatMessage(string.format("No charges found for %s", suspect))
        return
    end
    
    local charges = autobind.Charges.List[suspect]
    formattedAddChatMessage(string.format("%s has %d total charges:", suspect, charges.totalCharges or #charges.crimes))
    
    for i, crimeData in ipairs(charges.crimes) do
        formattedAddChatMessage(string.format("  %d. Crime: %s | Reported by: %s | Date: %s", 
            i, crimeData.crime, crimeData.reporter, crimeData.date or "Unknown"))
    end
end

--[[function listOfficerCharges(officer)
    if not autobind.ReporterIndex or not autobind.ReporterIndex[officer] then
        formattedAddChatMessage(string.format("No charges filed by %s", officer))
        return
    end
    
    local reports = autobind.ReporterIndex[officer]
    formattedAddChatMessage(string.format("%s has filed %d total charges:", officer, #reports))
    
    for i, reportData in ipairs(reports) do
        formattedAddChatMessage(string.format("  %d. Suspect: %s | Crime: %s | Date: %s", 
            i, reportData.suspect, reportData.crime, os.date("%Y-%m-%d %H:%M:%S", reportData.timestamp) or "Unknown"))
    end
end]]

function sampev.onServerMessage(color, text)
    if not isGameFocused then
        goto skipServerMessage
    end

    for _, handler in ipairs(messageHandlers) do
        if color == handler.color or (color == handler.altColor and handler.altColor) then
            local captures = {text:match(handler.pattern)}
            if #captures > 0 then
                local result = handler.action(table.unpack(captures))
                if result ~= nil then
                    return result
                end
                break
            end
        end
    end

    ::skipServerMessage::
end

function sampev.onSendTakeDamage(senderID, damage, weapon, Bodypart)
	if damage < 1 then
		goto skipHealTimer
	end

    if (weapon >= 49 and weapon <= 54) or weapon == 255 then
        goto skipHealTimer
    end


    local currentTime = os.clock()
	if autobind.Settings.mode == "Family" then
		if family.preventHealTimer then
			if currentTime - timers.Point.last >= timers.Point.timer then
				family.preventHealTimer = false
			else
				print("Heal timer is prevented for 3 minutes after leaving the pointbounds.")
				goto skipHealTimer
			end
		end
	end

    timers.Heal.last = currentTime

    ::skipHealTimer::
end

function sampev.onSendCommand(command)
    if checkMuted() then
        print("Muted, skipping command", command)
        return false
    end

    if isLoadingObjects then
        print("Objects are loading, skipping command", command)
        return false
    end

    if isPlayerAFK then
        formattedAddChatMessage("You are currently AFK, please move around to use commands.")
        debugMessage(string.format("Skipping '%s' due to player being AFK", command), true, true)
        return false
    end

    if command:match("^/wanted$") then
        local currentTime = os.clock()
        if currentTime - lastKeybindTime < keyBindDelay then
            print("preventing wanted command, keybind delay")
            return false
        end
    end

    if autoCapture and command:match("^/reports$") then
        print("Auto-capture is enabled skipping reports command")
        return false
    end

    local id = command:match("^/spec%s*(.-)$")
    if id then
        local res, id, name = findPlayer(id)
        if res then
            specData.id = id
            specData.name = name
        end
    end
end

function sampev.onTogglePlayerSpectating(state)
    specData.id = state and specData.id or -1
    specData.name = state and specData.name or ""
    specData.state = state
end

-- Dynamically update the locations of the black market and faction locker
function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
    if text:match("Type /blackmarket to purchase items") or text:match("Type /dlocker to purchase items") then
        autobind.BlackMarket.Locations = autobind.BlackMarket.Locations or {}
        
        autobind.BlackMarket.Locations[tostring(id)] = {
            x = position.x,
            y = position.y,
            z = position.z,
            radius = 13.0
        }
    end

    if text:match("/locker") and text:match("To open your locker.") then
        autobind.FactionLocker.Locations = autobind.FactionLocker.Locations or {}

        autobind.FactionLocker.Locations[tostring(id)] = {
            x = position.x,
            y = position.y,
            z = position.z,
            radius = 3.5
        }
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if title:find("Vehicle storage") and style == 2 then
        if not vehicles.initialFetch then
            local playerName = getCurrentPlayingPlayer()
            if not playerName then
                formattedAddChatMessage("Current playing player not found!")
                return
            end

            -- Ensure the playerName key exists as a table in vehicles
            autobind.VehicleStorage.Vehicles[playerName] = autobind.VehicleStorage.Vehicles[playerName] or {}

            -- Function to check if the vehicle already exists and update it
            local function updateOrAddVehicle(playerVehicles, indexId, newVehicle, newStatus, newLocation)
                for _, entry in ipairs(playerVehicles) do
                    if entry.vehicle and entry.vehicle == newVehicle and entry.id and entry.id == indexId then
                        -- Update existing entry
                        entry.status = newStatus
                        entry.location = newLocation
                        return
                    end
                end
                -- Add new entry if no match is found
                table.insert(playerVehicles, {
                    id = indexId, -- Add index ID
                    vehicle = newVehicle,
                    status = newStatus,
                    location = newLocation
                })
            end

            -- Parse the data
            local currentId = 0 -- Start with an initial ID (or fetch from server if needed)
            for line in text:gmatch("[^\n]+") do
                local adjustedMessage = removeHexBrackets(line)
                local vehicle, status, location = adjustedMessage:match("Vehicle:%s*(.-)%s*|%s*Status:%s*(.-)%s*|%s*Location:%s*(.+)")
                if vehicle and status and location then
                    -- Shorten the location names
                    location = location:gsub("^Los Santos International", "LS International")

                    -- Update or add the vehicle, including the index ID
                    updateOrAddVehicle(autobind.VehicleStorage.Vehicles[playerName], currentId, vehicle, status, location)
                    currentId = currentId + 1 -- Increment the ID for the next vehicle
                end
            end

            vehicles.initialFetch = true
        end

        if vehicles.populating then
            sampSendDialogResponse(id, 0, nil, nil)
            vehicles.populating = false
            return false
        end

        if vehicles.spawning and vehicles.currentIndex ~= -1 then
            sampSendDialogResponse(id, 1, vehicles.currentIndex, nil)
            vehicles.spawning = false
            return false
        end

        local indexId = 1
        local newText = ""
        for line in text:gmatch("[^\n]+") do
            newText = newText .. string.format("%d: %s\n", indexId, line)
            indexId = indexId + 1
        end

        return {id, style, title, button1, button2, newText}
    end
    
    -- Black Market
    if lockers.BlackMarket.getItemFrom > 0 then
        if not title:find("Black Market") then 
            lockers.BlackMarket.getItemFrom = 0 
            lockers.BlackMarket.gettingItem = false
            lockers.BlackMarket.currentKey = nil
            return false 
        end
        sampSendDialogResponse(id, 1, lockers.BlackMarket.currentKey, nil)
        lockers.BlackMarket.gettingItem = false
        return false
    end

    -- Faction Locker
    if lockers.FactionLocker.getItemFrom > 0 then
        if title:find('[LSPD|FBI|ARES] Menu') then
            sampSendDialogResponse(id, 1, 1, nil)
            return false
        end

        if not title:find("[LSPD|FBI|ARES] [Equipment|Weapons]") then
            lockers.FactionLocker.getItemFrom = 0 
            lockers.FactionLocker.gettingItem = false
            lockers.FactionLocker.currentKey = nil
            return false
        end
        sampSendDialogResponse(id, 1, lockers.FactionLocker.currentKey, nil)
        lockers.FactionLocker.gettingItem = false
        return false
    end
end

function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
    local vehicle, status, location = input:match("Vehicle: ([^|]+) | Status: ([^|]+) | Location: (.+)")
    if vehicle and status and location and button == 1 then
        vehicles.currentIndex = listboxId
    end
end

function sampev.onSendClientJoin()
	setSampfuncsGlobalVar("aduty", 0)
    backup.enable = false
end

function sampev.onPlayerQuit(playerId, reason)
    if playerId == accepter.playerId then
        accepter.playerName = ""
        accepter.playerId = -1
    end

    if playerId == bodyguard.playerId then
        bodyguard.playerName = ""
        bodyguard.playerId = -1
    end

    if playerId == autofind.playerId and autobind.Settings.autoFind then
        formattedAddChatMessage("The player you were finding has disconnected, you are no longer finding anyone.")
        autofind.enable = false
        autofind.playerName = ""
        autofind.playerId = -1
    end

    if playerId == backup.playerId then
        backup.playerName = ""
        backup.playerId = -1
        backup.location = ""
    end

    checkWantedList("disconnected", nil, playerId)
end

function sampev.onConnectionRejected(reason)
    if autobind.Settings and autobind.Settings.autoReconnect then
        autoConnect()
    end
end

function sampev.onConnectionClosed()
    if autobind.Settings and autobind.Settings.autoReconnect then
        autoConnect()
    end
end

function sampev.onConnectionBanned()
    if autobind.Settings and autobind.Settings.autoReconnect then
        autoConnect()
    end
end

function sampev.onConnectionLost()
    if autobind.Settings and autobind.Settings.autoReconnect then
        autoConnect()
    end
end

function sampev.onSetPlayerTime(hour, minute)
    if autobind.TimeAndWeather then
        autobind.TimeAndWeather.serverHour = hour
        autobind.TimeAndWeather.serverMinute = minute
        if autobind.TimeAndWeather.modifyTime then
            return {autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute}
        end
    end
end

function sampev.onSetWeather(weatherId)
    if autobind.TimeAndWeather then
        autobind.TimeAndWeather.serverWeather = weatherId
        if autobind.TimeAndWeather.modifyWeather then
            return {autobind.TimeAndWeather.weather}
        end
    end
end

function sampev.onPlayAudioStream(url, position, radius, usePosition)
    if url:match("^https://hzgaming.net/horizonfm/radio.pls$") and not autobind.Settings.HZRadio then
        return false
    elseif url:match("^https://hzgaming.net/zhao/sounds%/%w+.mp3$") and not autobind.Settings.LoginMusic then
        formattedAddChatMessage("You have login music disabled, type /loginmusic to enable it.")
        return false
    end
end

function sampev.onShowTextDraw(id, data)
    if data.text:match("~r~Objects loading...") then
        isLoadingObjects = true
    end

    if data.text:match("~g~Objects loaded!") then
        isLoadingObjects = false
    end
end

local elements = {
    OfferedTo = {
        enable = function() return autobind.Elements.offeredTo.enable end,
        pos = function() return autobind.Elements.offeredTo.Pos end,
        colors = function() return autobind.Elements.offeredTo.colors end,
        align = function() return autobind.Elements.offeredTo.align end,
        fontName = function() return autobind.Elements.offeredTo.font end,
        fontSize = function() return autobind.Elements.offeredTo.size end,
        flags = function() return autobind.Elements.offeredTo.flags end,
        textFunc = function(self)
            local offeredTo = string.format("%s (%d)", bodyguard.playerName:gsub("_", " "), bodyguard.playerId)
            return string.format("{%06x}Offered To: {%06x}%s; $%s", self.colors().text, self.colors().value, menu.Settings.window[0] and "Player_Name (ID)" or offeredTo, formatNumber(bodyguard.price))
        end,
        isVisible = function()
            return (bodyguard.playerName and bodyguard.playerName ~= "" and bodyguard.playerId and bodyguard.playerId ~= -1) or menu.Settings.window[0]
        end,
    },
    OfferedFrom = {
        enable = function() return autobind.Elements.offeredFrom.enable end,
        pos = function() return autobind.Elements.offeredFrom.Pos end,
        colors = function() return autobind.Elements.offeredFrom.colors end,
        align = function() return autobind.Elements.offeredFrom.align end,
        fontName = function() return autobind.Elements.offeredFrom.font end,
        fontSize = function() return autobind.Elements.offeredFrom.size end,
        flags = function() return autobind.Elements.offeredFrom.flags end,
        textFunc = function(self)
            local offeredFrom = string.format("%s (%d)", accepter.playerName:gsub("_", " "), accepter.playerId)
            return string.format("{%06x}Offered From: {%06x}%s; $%s", self.colors().text, self.colors().value, menu.Settings.window[0] and "Player_Name (ID)" or offeredFrom, formatNumber(accepter.price))
        end,
        isVisible = function()
            return (accepter.playerName and accepter.playerName ~= "" and accepter.playerId and accepter.playerId ~= -1) or menu.Settings.window[0]
        end,
    },
    PedsCount = {
        enable = function() return autobind.Elements.PedsCount.enable end,
        pos = function() return autobind.Elements.PedsCount.Pos end,
        colors = function() return autobind.Elements.PedsCount.colors end,
        align = function() return autobind.Elements.PedsCount.align end,
        fontName = function() return autobind.Elements.PedsCount.font end,
        fontSize = function() return autobind.Elements.PedsCount.size end,
        flags = function() return autobind.Elements.PedsCount.flags end,
        textFunc = function(self)
            local pedCount = sampGetPlayerCount(true) - 1
            return string.format("{%06x}Peds: {%06x}%d", self.colors().text, self.colors().value, pedCount)
        end,
        isVisible = function()
            return true
        end,
    },
    AutoFind = {
        enable = function() return autobind.Elements.AutoFind.enable end,
        pos = function() return autobind.Elements.AutoFind.Pos end,
        colors = function() return autobind.Elements.AutoFind.colors end,
        align = function() return autobind.Elements.AutoFind.align end,
        fontName = function() return autobind.Elements.AutoFind.font end,
        fontSize = function() return autobind.Elements.AutoFind.size end,
        flags = function() return autobind.Elements.AutoFind.flags end,
        textFunc = function(self)
            local playerName = string.format("%s (%d)", autofind.playerName:gsub("_", " "), autofind.playerId)
            local timeLeft = math.ceil(timers.Find.timer - (os.clock() - timers.Find.last))
            local locationText = menu.Settings.window[0] and "; Location" or (autofind.location == "" and "" or ("; " .. autofind.location))
            return string.format("{%06x}Auto Find: {%06x}%s; Next: %02ds%s", self.colors().text, self.colors().value, menu.Settings.window[0] and "Player_Name (ID)" or playerName, timeLeft < 0 and 0 or timeLeft, locationText)
        end,
        isVisible = function()
            return (autofind.playerName and autofind.playerName ~= "" and autofind.playerId and autofind.playerId ~= -1 and autobind.Settings.autoFind) or menu.Settings.window[0]
        end,
    },
    LastBackup = {
        enable = function() return autobind.Elements.LastBackup.enable end,
        pos = function() return autobind.Elements.LastBackup.Pos end,
        colors = function() return autobind.Elements.LastBackup.colors end,
        align = function() return autobind.Elements.LastBackup.align end,
        fontName = function() return autobind.Elements.LastBackup.font end,
        fontSize = function() return autobind.Elements.LastBackup.size end,
        flags = function() return autobind.Elements.LastBackup.flags end,
        textFunc = function(self)
            local lastBackup = string.format("%s (%d)", backup.playerName:gsub("_", " "), backup.playerId)
            return string.format("{%06x}Last Backup: {%06x}%s; %s", self.colors().text, self.colors().value, menu.Settings.window[0] and "Player_Name (ID)" or lastBackup, menu.Settings.window[0] and "Location" or backup.location)
        end,
        isVisible = function()
            return (backup.playerName and backup.playerName ~= "" and backup.playerId and backup.playerId ~= -1) or menu.Settings.window[0]
        end,
    },
    FactionBadge = {
        enable = function() return autobind.Elements.FactionBadge.enable end,
        pos = function() return autobind.Elements.FactionBadge.Pos end,
        colors = function()
            local _, playerId = sampGetPlayerIdByCharHandle(ped)
            local playerColor = sampGetPlayerColor(playerId)
            return {text = colors.changeAlpha(playerColor, 0)}
        end,
        align = function() return autobind.Elements.FactionBadge.align end,
        fontName = function() return autobind.Elements.FactionBadge.font end,
        fontSize = function() return autobind.Elements.FactionBadge.size end,
        flags = function() return autobind.Elements.FactionBadge.flags end,
        textFunc = function(self)
            local playerColor = self.colors().text
            local badges = factions.badges[playerColor] or extraBadges[playerColor]
            return badges and string.format("{%06x}%s", playerColor, badges) or ""
        end,
        isVisible = function()
            return true
        end,
    }
}

function createFonts()
    for name, element in pairs(elements) do
        local flags = element.flags() or {}
        local flag_sum = 0

        -- Calculate the flag sum
        for flagName, flagValue in pairs(flagValues) do
            if flags[flagName] then
                flag_sum = flag_sum + flagValue
            end
        end

        -- Create all fonts with the calculated flags
        myFonts[name] = renderCreateFont(element.fontName(), element.fontSize(), flag_sum)
    end
end

function createFont(name, element)
    local flag_sum = 0

    -- Calculate the flag sum
    for flagName, flagValue in pairs(flagValues) do
        if element.flags[flagName] then
            flag_sum = flag_sum + flagValue
        end
    end

    -- Create the font with the calculated flags
    myFonts[name] = renderCreateFont(element.font, element.size, flag_sum)
end

local function drawElements()
    for name, element in pairs(elements) do
        if element.enable() and element.isVisible() then
            local font = myFonts[name]
            if font then
                local text = element.textFunc(element)
                local processedText = removeHexBrackets(text)
                local width = renderGetFontDrawTextLength(font, processedText)

                -- Alignment
                local alignX = 0
                if element.align() == "center" then
                    alignX = width / 2
                elseif element.align() == "right" then
                    alignX = width
                end

                -- Draw the text
                local pos = element.pos()
                renderFontDrawText(font, text, pos.x - alignX, pos.y, -1)
            end
        end
    end
end

local function dragElements()
    if not isCursorActive() then return end
    local cursorX, cursorY = getCursorPos()

    for name, element in pairs(elements) do
        if element.enable() and menu.Settings.window[0] then
            local font = myFonts[name]
            if font then
                local text = element.textFunc(element)
                local processedText = removeHexBrackets(text)
                local width = renderGetFontDrawTextLength(font, processedText)
                local height = renderGetFontDrawHeight(font)

                -- Alignment
                local alignX = 0
                if element.align() == "center" then
                    alignX = width / 2
                elseif element.align() == "right" then
                    alignX = width
                end

                local pos = element.pos()

                -- Initialize drag state for the element
                dragState[name] = dragState[name] or { dragging = false, offsetX = 0, offsetY = 0 }

                -- Check if the left mouse button is just pressed
                if isKeyJustPressed(VK_LBUTTON) then
                    if cursorX >= pos.x - alignX and cursorX <= (pos.x - alignX + width) and
                       cursorY >= pos.y and cursorY <= (pos.y + height) then
                        dragState[name].dragging = true
                        dragState[name].offsetX = cursorX - (pos.x - alignX)
                        dragState[name].offsetY = cursorY - pos.y
                    end
                end

                -- If dragging, update the item's position based on cursor movement
                if dragState[name].dragging then
                    pos.x = cursorX - dragState[name].offsetX + alignX
                    pos.y = cursorY - dragState[name].offsetY
                end

                -- Stop dragging when the left mouse button is released
                if wasKeyReleased(VK_LBUTTON) then
                    if dragState[name].dragging then
                        dragState[name].dragging = false
                    end
                end
            end
        end
    end
end

function onD3DPresent()
    if not autobind.Settings.sprintBind then
        goto sprintBindSkip
    end

	if isButtonPressed(h, gkeys.player.SPRINT) and (isCharOnFoot(ped) or isCharInWater(ped)) then
		setGameKeyState(gkeys.player.SPRINT, 0)
	end

    ::sprintBindSkip::

    if isPauseMenuActive() or sampIsScoreboardOpen() or sampGetChatDisplayMode() == 0 or isKeyDown(VK_F10) then
        goto elementsSkip
    end

    drawElements()
    dragElements()

    ::elementsSkip::
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil

	-- Check if the font exists
	assert(doesFileExist(Files.trebucbd), string.format('[%s] Font "%s" doesn\'t exist!', shortName:upper(), Files.trebucbd))

    -- Setup Font and Icons (Large, Medium, Small)
    --[[imgui_funcs.loadFontIcons(false, 14.0, ti.min_range, ti.max_range, ti.get_font_data_base85())
    for _, font in pairs(fontData) do
        font.font = imgui.GetIO().Fonts:AddFontFromFileTTF(Files.trebucbd, font.size)
        imgui_funcs.loadFontIcons(false, font.size, ti.min_range, ti.max_range, ti.get_font_data_base85())
    end]]

    -- Setup Font and Icons (Large, Medium, Small)
    imgui_funcs.loadFontIcons(true, 14.0, fa.min_range, fa.max_range, Files.fawesome5)
    for _, font in pairs(fontData) do
        font.font = imgui.GetIO().Fonts:AddFontFromFileTTF(Files.trebucbd, font.size)
        imgui_funcs.loadFontIcons(true, font.size, fa.min_range, fa.max_range, Files.fawesome5)
    end

	-- Load skin images
	for i = 0, 311 do
		if skinTextures[i] == nil then
			local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, i)
			if doesFileExist(skinPath) then
				skinTextures[i] = imgui.CreateTextureFromFile(skinPath)
			end
		end
	end

    apply_custom_style(colors.convertColor(clr_ARES, true, false, false))
end)

function apply_custom_style(color)
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
    colors[clr.FrameBg]                = ImVec4(color.r, color.g, color.b, 0.7)
	colors[clr.FrameBgHovered]         = ImVec4(color.r, color.g, color.b, 0.4)
	colors[clr.FrameBgActive]          = ImVec4(color.r, color.g, color.b, 0.9)
	colors[clr.TitleBg]                = ImVec4(color.r, color.g, color.b, 1.0)
	colors[clr.TitleBgActive]          = ImVec4(color.r, color.g, color.b, 1.0)
	colors[clr.TitleBgCollapsed]       = ImVec4(color.r, color.g, color.b, 0.79)
    colors[clr.CheckMark]              = ImVec4(color.r + 0.13, color.g + 0.13, color.b + 0.13, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Button]                 = ImVec4(color.r, color.g, color.b, 0.8)
	colors[clr.ButtonHovered]          = ImVec4(color.r, color.g, color.b, 0.63)
	colors[clr.ButtonActive]           = ImVec4(color.r, color.g, color.b, 1.0)
	colors[clr.Header]                 = ImVec4(color.r, color.g, color.b, 0.6)
	colors[clr.HeaderHovered]          = ImVec4(color.r, color.g, color.b, 0.43)
	colors[clr.HeaderActive]           = ImVec4(color.r, color.g, color.b, 0.8)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(color.r, color.g, color.b, 0.8)
	colors[clr.ResizeGripHovered]      = ImVec4(color.r, color.g, color.b, 0.63)
	colors[clr.ResizeGripActive]       = ImVec4(color.r, color.g, color.b, 1.0)
    colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]                 = ImVec4(color.r, color.g, color.b, 0.4)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(color.r, color.g, color.b, 0.8)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
end

local button_size_small = imgui.ImVec2(75, 75)
local button_size_large = imgui.ImVec2(165, 75)
local child_size1 = imgui.ImVec2(85, 380)
local child_size2 = imgui.ImVec2(515, 88)
local child_size_pages = imgui.ImVec2(513, 278)
local child_size_bottom = imgui.ImVec2(400, 20)
local button_size_small2 = imgui.ImVec2(15, 15)

local updateStatusIcons = {
    up_to_date = fa.ICON_FA_CHECK .. ' Up to date',
    new_version = fa.ICON_FA_RETWEET .. ' Update\nNew Version',
    outdated = fa.ICON_FA_EXCLAMATION_TRIANGLE .. ' Update\n Outdated',
    failed = fa.ICON_FA_EXCLAMATION_TRIANGLE .. ' Update\n    Failed',
    beta_version = fa.ICON_FA_RETWEET .. ' Update\nBeta Version'
}

local recentMessages = {} -- Track recently used messages
local recentLimit = 3 -- Number of recent messages to avoid repeating

function getRandomMessage(messages)
    local availableMessages = {}
    for _, msg in ipairs(messages) do
        if not table.contains(recentMessages, msg) then
            table.insert(availableMessages, msg)
        end
    end

    -- Reset recent messages if all messages have been used
    if #availableMessages == 0 then
        recentMessages = {}
        availableMessages = messages
    end

    local randomMessage = availableMessages[math.random(#availableMessages)]
    table.insert(recentMessages, randomMessage)

    -- Keep recentMessages within the limit
    if #recentMessages > recentLimit then
        table.remove(recentMessages, 1)
    end

    return randomMessage
end

local buttons1 = {
    {   -- Logo Button
        id = 1,
        icon = function() return fa.ICON_FA_CANNABIS end,
        tooltip = function() 
            return "Click me!"
        end,
        action = function()
            local weedMessages = {
                "Smoke weed every day!",
                "420 blaze it!",
                "Pass the joint!",
                "High times ahead!",
                "Green is good!",
                "Puff puff pass!",
                "Let's roll!",
                "Time to chill!",
                "Going green!",
                "Light it up!"
            }
            local randomMessage = getRandomMessage(weedMessages)
            mimtoasts.Show(randomMessage, 1, 5)
        end,
        color = function()
            return imguiRGBA["ARESALT"]
        end,
        hoveredColor = function()
            return imguiRGBA["ARESALT2"]
        end,
        activeColor = function()
            return imguiRGBA["ARESALT3"]
        end,
        textColor = function()
            return imguiRGBA["GREEN"]
        end,
        font = "x2large"
    },
    {   -- Save Button
        id = 2,
        icon = function() return fa.ICON_FA_SAVE end,
        tooltip = function() return 'Save configuration' end,
        action = function()
            saveAllConfigs()
            mimtoasts.Show("All configurations saved successfully!", 1, 4)
        end,
        color = function()
            return imguiRGBA["DARKGREY"]
        end,
        hoveredColor = function()
            return imguiRGBA["ALTRED"]
        end,
        activeColor = function()
            return imguiRGBA["RED"]
        end,
        textColor = function()
            return imguiRGBA["WHITE"]
        end,
        font = "medium"
    },
    {   -- Reload Button
        id = 3,
        icon = function() return fa.ICON_FA_SYNC end,
        tooltip = function() return 'Reload configuration' end,
        action = function()
            loadAllConfigs()
            mimtoasts.Show("All configurations reloaded successfully!", 1, 4)
        end,
        color = function()
            return imguiRGBA["DARKGREY"]
        end,
        hoveredColor = function()
            return imguiRGBA["ALTRED"]
        end,
        activeColor = function()
            return imguiRGBA["RED"]
        end,
        textColor = function()
            return imguiRGBA["WHITE"]
        end,
        font = "medium"
    },
    {   -- Reset Button
        id = 4,
        icon = function() return fa.ICON_FA_ERASER end,
        tooltip = function() return 'Load default configuration' end,
        action = function()
            local ignoreKeys = {
                {"Settings", "mode"},
                {"WindowPos", "Settings"},
                {"WindowPos", "Names"},
                {"WindowPos", "Skins"},
                {"WindowPos", "Charges"},
                {"WindowPos", "BlackMarket"},
                {"WindowPos", "FactionLocker"},
                {"CurrentPlayer", "name"},
                {"CurrentPlayer", "id"}
            }

            configs.ensureDefaults(autobind, autobind_defaultSettings, true, ignoreKeys)

            createFonts()

            resetLockersKeyFunctions()

            for _, name in pairs(lockerVars) do
                InitializeLockerKeyFunctions(name, lockers[name].name, lockers[name].command, autobind[name].maxKits)
            end

            vehicles.initialFetch = false
            vehicles.populating = true
            sampSendChat("/vst")

            if autobind.AutoVest.autoFetchSkins then
                fetchJsonDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
                    if decodedData then
                        autobind.AutoVest.skins = decodedData
                        family.skins = table.listToSet(autobind.AutoVest.skins)
                    end
                end)
            else
                family.skins = table.listToSet(autobind.AutoVest.skins)
            end

            if autobind.AutoVest.autoFetchNames then
                fetchJsonDataDirectlyFromURL(autobind.AutoVest.namesUrl, function(decodedData)
                    if decodedData then
                        autobind.AutoVest.names = decodedData
                        names = table.listToSet(autobind.AutoVest.names)
                    end
                end)
            else
                names = table.listToSet(autobind.AutoVest.names)
            end

            mimtoasts.Show("All configurations reset successfully!", 1, 4)
        end,
        color = function()
            return imguiRGBA["DARKGREY"]
        end,
        hoveredColor = function()
            return imguiRGBA["ALTRED"]
        end,
        activeColor = function()
            return imguiRGBA["RED"]
        end,
        textColor = function()
            return imguiRGBA["WHITE"]
        end,
        font = "medium"
    },
    {   -- Update Button
        id = 5,
        icon = function() 
            return updateStatusIcons[updateStatus] or "Update"
        end,
        tooltip = function() return 'Check for update' end,
        action = function()
            updateCheck()

            if updateStatus == "new_version" or updateStatus == "beta_version" or updateStatus == "outdated" then
                local autoRebootScript = script.find("ML-AutoReboot")
                if autoRebootScript then
                    autoRebootScript:unload()
                    autoReboot = true
                else
                    autoReboot = false
                end

                menu.Confirm.update[0] = true
                menu.Confirm.window[0] = true
            end

            local updateType = {
                up_to_date = 0,
                new_version = 1,
                outdated = 3,
                failed = 2,
                beta_version = 1
            }

            mimtoasts.Show(updateStatusIcons[updateStatus] or "Update", updateType[updateStatus] or 0, 4)
        end,
        color = function()
            return (updateStatus == "new_version" or updateStatus == "beta_version" or updateStatus == "outdated") and imguiRGBA["GREEN"] or imguiRGBA["DARKGREY"]
        end,
        hoveredColor = function()
            return imguiRGBA["ALTRED"]
        end,
        activeColor = function()
            return imguiRGBA["RED"]
        end,
        textColor = function()
            return imguiRGBA["WHITE"]
        end,
        font = "small"
    }
}

local buttons2 = {
    {
        id = 1,
        icon = function()
            return fa.ICON_FA_COGS .. " Autobind"
        end,
        tooltip = "Open Autobind",
        render = function() renderAutoBind() end
    },
    {
        id = 2,
        icon = function()
            return fa.ICON_FA_SHIELD_ALT .. " Bodyguard"
        end,
        tooltip = "Open Bodyguard",
        render = function() renderGuard(autobind.Settings.mode) end
    },
    {
        id = 3,
        icon = function()
            return fa.ICON_FA_SEARCH_LOCATION .. " Autofind"
        end,
        tooltip = "Open Autofind",
        render = function() renderAutoFind() end
    },
    {
        id = 4,
        icon = function()
            return fa.ICON_FA_KEYBOARD .. " Keybinds"
        end,
        tooltip = "Open Keybinds",
        render = function() renderKeybinds() end
    },
    {
        id = 5,
        icon = function()
            return fa.ICON_FA_USER_SHIELD .. " Factions"
        end,
        tooltip = "Open Factions",
        render = function() renderFactions() end
    },
    {
        id = 6,
        icon = function()
            return fa.ICON_FA_USER_COG .. " Families"
        end,
        tooltip = "Open Families",
        render = function() renderFamilies() end
    },
    {
        id = 7,
        icon = function()
            return fa.ICON_FA_STAR .. " Wanted"
        end,
        tooltip = "Open Wanted",
        render = function() renderWanted() end
    },
    {
        id = 8,
        icon = function()
            return fa.ICON_FA_CAR .. " VStorage"
        end,
        tooltip = "Open Vehicle Storage",
        render = function() renderVehicleStorage() end
    }
}

local cursor_positions_y_buttons1 = {}
for i, _ in ipairs(buttons1) do
    cursor_positions_y_buttons1[i] = (i - 1) * 76
end

function onWindowMessage(msg, wparam, lparam)
    -- Check if the player is paused and set AFK upon setting focus
    if msg == wm.WM_SETFOCUS then
        PausedLength = os.clock() - timers.Pause.last -- store the current pause time
        timers.Pause.last = os.clock() -- reset the last pause time
        isGameFocused = true
    elseif msg == wm.WM_KILLFOCUS then
        isGameFocused = false
        timers.Pause.last = os.clock() -- reset the last pause time
    end

    -- Auto Close Samp Help Dialog
    if wparam == VK_F1 then
        if msg == wm.WM_KEYUP then
            sampCloseCurrentDialogWithButton(0)
        end
    end

    if wparam == VK_ESCAPE then
        -- Check if any menu is open
        local anyMenuOpen = false
        for _, state in pairs(menuStates) do
            if state[0] then
                anyMenuOpen = true
                break
            end
        end

        if anyMenuOpen then
            if msg == wm.WM_KEYDOWN then
                -- Consume the message to prevent further processing
                consumeWindowMessage(true, false)
            end
            if msg == wm.WM_KEYUP then
                -- Set the flag to indicate Escape was pressed
                escapePressed = true
            end
        end
    end
end

imgui.OnFrame(
    function()
        return menu.Initialized[0]
           and menu.Wanted.window[0]
           and autobind.Wanted.Enabled
           and wanted.lawyer
           and activeCheck(false, false, true, false, true)
           and sampGetChatDisplayMode() > 0 
           and not isKeyDown(VK_F10)
    end,
    function()
        local textLines = {}
        if autobind.Wanted.List and #autobind.Wanted.List > 0 then
            for _, entry in ipairs(autobind.Wanted.List) do
                table.insert(textLines, formatWantedString(entry, true, true))
            end
        else
            textLines = {"No current wanted suspects."}
        end

        local windowSize = imgui_funcs.calculateWindowSize(textLines, autobind.Wanted.Padding)
        local newPos, isDragging = imgui_funcs.handleWindowDragging("WantedList", autobind.Wanted.Pos, windowSize, autobind.Wanted.Pivot, true)
        if isDragging and menu.Settings.window[0] then
            autobind.Wanted.Pos = newPos
        end
        imgui.SetNextWindowPos(autobind.Wanted.Pos, imgui.Cond.Always, autobind.Wanted.Pivot)
        imgui.SetNextWindowSize(windowSize, imgui.Cond.Always)

        local bgColor = colors.convertColor(autobind.Wanted.BackgroundColor, true, true, false)
        local borderColor = colors.convertColor(autobind.Wanted.BorderColor, true, true, false)
        local borderSize = autobind.Wanted.BorderSize
        local padding = autobind.Wanted.Padding
        local rounding = autobind.Wanted.Rounding

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(bgColor.r, bgColor.g, bgColor.b, autobind.Wanted.ShowBackground and bgColor.a or 0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(borderColor.r, borderColor.g, borderColor.b, autobind.Wanted.ShowBorder and borderColor.a or 0))
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, padding)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, borderSize)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, rounding)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowMinSize, imgui.ImVec2(0, 0))

        local wantedKey = "Wanted"
        if imgui.Begin(wantedKey, menu[wantedKey].window, menu[wantedKey].flags) then
            local lineHeight = imgui.GetTextLineHeightWithSpacing()
            local totalTextHeight = #textLines * lineHeight
            local startY = (windowSize.y - totalTextHeight) / 2
            local offsetX = padding.x + borderSize * 0.25

            if not isPlayerAFK or not autobind.Wanted.ShowAFK then
                for i, text in ipairs(textLines) do
                    local textPosY = startY + (i - 1) * lineHeight + 1
                    imgui.SetCursorPos(imgui.ImVec2(offsetX, textPosY))
                    imgui_funcs.TextColoredRGB(text)
                end
            else
                if not specData.state then
                    local afkText = string.format("{%06x}You are currently AFK.", autobind.Wanted.AFKTextColor)
                    local textSize = imgui_funcs.calcTextSize(afkText)
                    local windowWidth = imgui.GetWindowWidth()
                    local windowHeight = imgui.GetWindowHeight()
                    local iconPosX = (windowWidth - textSize.x) / 2
                    local iconPosY = (windowHeight - textSize.y) / 2.2
                    imgui.SetCursorPos(imgui.ImVec2(iconPosX, iconPosY))
                    imgui_funcs.TextColoredRGB(afkText)
                end
            end

            if autobind.Wanted.ShowRefresh then
                local timeRemaining = autobind.Wanted.Timer - (os.clock() - last_wanted)
                if timeRemaining >= (autobind.Wanted.Timer - 1) and timeRemaining <= autobind.Wanted.Timer + 1 then
                    local icon = string.format("{%06x}%s", autobind.Wanted.RefreshColor, fa.ICON_FA_CHECK)
                    local iconSize = imgui_funcs.calcTextSize(icon)
                    local iconPosX = windowSize.x - iconSize.x - (borderSize * 0.25 - 2)
                    local iconPosY = borderSize * 0.25 + 2
                    imgui.SetCursorPos(imgui.ImVec2(iconPosX, iconPosY))
                    imgui.PushFont(fontData.xsmall.font)
                    imgui_funcs.TextColoredRGB(icon)
                    imgui.PopFont()
                end
            end
        end
        imgui.End()
        imgui.PopStyleVar(4)
        imgui.PopStyleColor(2)
    end
).HideCursor = true

imgui.OnFrame(function() return menu.Initialized[0] end,
function(self)
    if not isSampLoaded() or not isSampAvailable() then return end

    -- Check if any menu window is open to control cursor visibility
    local anyMenuOpen = false
    for key, state in pairs(menuStates) do
        if state[0] then
            anyMenuOpen = true
            break
        end
    end

    -- Show/hide cursor based on menu state
    self.HideCursor = not anyMenuOpen or cursorActive

    if escapePressed then
        for key, state in pairs(menuStates) do
            if state[0] and key ~= "Confirm" then
                state[0] = false

                if key == "Names" then
                    autobind.AutoVest.names = table.setToList(names)
                end

                if key == "Skins" then
                    autobind.AutoVest.skins = table.setToList(family.skins)
                end

                if key == "VehicleStorage" then
                    menu[key].dragging[0] = false
                end
            end
            -- Update previous state to reflect that the menu is now closed
            previousMenuStates[key] = false
        end
        escapePressed = false

        saveAllConfigs()
    else
        for key, state in pairs(menuStates) do
            -- Check if the menu has just been closed
            if previousMenuStates[key] and not state[0] then
                if key == "Settings" then
                    saveAllConfigs()
                end

                if key == "BlackMarket" then
                    InitializeLockerKeyFunctions(key, lockers[key].name, lockers[key].command, autobind[key].maxKits)

                    configs.saveConfigWithErrorHandling(Files[key:lower()], autobind[key])
                end

                if key == "FactionLocker" then
                    InitializeLockerKeyFunctions(key, lockers[key].name, lockers[key].command, autobind[key].maxKits)

                    configs.saveConfigWithErrorHandling(Files[key:lower()], autobind[key])
                end

                if key == "Charges" then

                end

                if key == "Names" then
                    autobind.AutoVest.names = table.setToList(names)
                end

                if key == "Skins" then
                    autobind.AutoVest.skins = table.setToList(family.skins)
                end

                if key == "Confirm" then
                    menu[key].update[0] = false
                end

                if key == "VehicleStorage" then
                    menu[key].dragging[0] = false
                end
            end

            -- Detect if the menu has just been opened
            if not previousMenuStates[key] and state[0] then
                if key == "Settings" then
                    updateCheck()
                end
            end

            -- Update previous state
            previousMenuStates[key] = state[0]
        end
    end

    local settingsKey = "Settings"
    if menu[settingsKey].window[0] then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        setupWindowDraggingAndSize(settingsKey)
        if imgui.Begin(settingsKey, menu[settingsKey].window, menu[settingsKey].flags) then
            customTitleBar(settingsKey, menu[settingsKey].title())

            imgui.SetCursorPos(imgui.ImVec2(252, 9))
            imgui.PushFont(fontData.medium.font)
            imgui.BeginGroup()
            imgui_funcs.TextColoredRGB(string.format("{%06x}({%06x}?{%06x})", clr_GREY, clr_GREEN, clr_GREY))
            imgui.EndGroup()
            imgui_funcs.CustomTooltip(string.format('%s', scriptDesc))
            imgui.PopFont()

            imgui.SetCursorPosY(30)
            imgui.PushFont(fontData.medium.font)
            if imgui.BeginChild("##SideButtons", child_size1, false) then
                for i, button in ipairs(buttons1) do
                    imgui.SetCursorPosY(cursor_positions_y_buttons1[i])

                    -- Push custom font if specified
                    if button.font then
                        imgui.PushFont(fontData[button.font].font)
                        if imgui_funcs.CustomButton(button.icon(), button.color(), button.hoveredColor(), button.activeColor(), button.textColor(), button_size_small) then
                            button.action()
                        end
                        imgui.PopFont()
                    end
    
                    
                    if not isUpdateHovered then
                        imgui_funcs.CustomTooltip(button.tooltip())
                    end

                    if button.id == 5 then
                        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5)

                        imgui.SetCursorPos(imgui.ImVec2(15, cursor_positions_y_buttons1[i] + 50))
                        imgui.BeginChild("##checkbox", imgui.ImVec2(55, 20), false)
                        imgui.SetCursorPos(imgui.ImVec2(0, 2))
                        if imgui.Checkbox('Beta', new.bool(autobind[settingsKey].fetchBeta)) then
                            autobind[settingsKey].fetchBeta = toggleBind("Beta Updates", autobind[settingsKey].fetchBeta)
                            updateCheck()
                        end
                        imgui_funcs.CustomTooltip('Fetch the latest version from the beta branch')
                        isUpdateHovered = imgui.IsItemHovered()
                        imgui.EndChild()
                        imgui.PopStyleVar(1)
                    end
                end
            end
            imgui.EndChild()
            imgui.PopFont()

            imgui.SetCursorPos(imgui.ImVec2(76, 30))
            imgui.PushFont(fontData.medium.font)

            local widthSpacing = 1
            local heightSpacing = 1
            local numColumns = 4
            local numRows = 2

            local buttonWidth = ((child_size2.x - (numColumns - 1) * widthSpacing) / numColumns) - 1
            local buttonHeight = ((child_size2.y - (numRows - 1) * heightSpacing) / numRows) - 6.5
            local buttonSize = imgui.ImVec2(buttonWidth, buttonHeight)

            if imgui.BeginChild("##Pages", child_size2, false) then
                for i, button in ipairs(buttons2) do
                    if button.id == 1 then
                        imgui.BeginGroup()
                    elseif button.id == numColumns + 1 then
                        imgui.SetCursorPosY(buttonSize.y + heightSpacing)
                        imgui.BeginGroup()
                    elseif button.id == numColumns * 2 + 1 then
                        imgui.SetCursorPosY(buttonSize.y * 2 + heightSpacing * 2)
                        imgui.BeginGroup()
                    end

                    local isActive = menu[settingsKey].pageId == button.id
                    local color = isActive and imguiRGBA["RED"] or imguiRGBA["DARKGREY"]
                    
                    if imgui_funcs.CustomButton(button.icon(), color, imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], buttonSize) then
                        menu[settingsKey].pageId = button.id
                    end
                    
                    if not isActive then
                        imgui_funcs.CustomTooltip(button.tooltip)
                    end

                    if (button.id == numColumns or button.id == numColumns * 2) or button.id == #buttons2 then
                        imgui.EndGroup()
                    end

                    if (i % numColumns) ~= 0 then
                        imgui.SameLine(nil, widthSpacing)
                    end
                end
            end
            imgui.EndChild()
            imgui.PopFont()

            imgui.SetCursorPos(imgui.ImVec2(75, 105))
            if imgui.BeginChild("##PageRenders", child_size_pages, false) then
                for _, button in ipairs(buttons2) do
                    if button.id == menu[settingsKey].pageId and button.render then
                        button.render()
                        break
                    end
                end
            end
            imgui.EndChild()

            imgui.SetCursorPos(imgui.ImVec2(80, 385))
            imgui.PushFont(fontData.medium.font)
            if imgui.BeginChild("##BottomSettings", child_size_bottom, false) then
                imgui.SetCursorPos(imgui.ImVec2(0, 2))
                if imgui.Button(fa.ICON_FA_KEYBOARD .. " Charges [WIP]") then
                    menu.Charges.window[0] = not menu.Charges.window[0]
                end
                imgui_funcs.CustomTooltip("Opens charges settings.")
                imgui_funcs.CustomTooltip(string.format("You can also use {%06x}'/%s charges'{%06x} to open this menu.", clr_GREY, shortName, clr_WHITE))

                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " BMS") then
                    menu.BlackMarket.window[0] = not menu.BlackMarket.window[0]
                end
                imgui_funcs.CustomTooltip("Opens black market settings.")
                imgui_funcs.CustomTooltip(string.format("You can also use {%06x}'/%s bms'{%06x} to open this menu.", clr_GREY, shortName, clr_WHITE))

                if autobind[settingsKey].mode == "Faction" then
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Locker") then
                        menu.FactionLocker.window[0] = not menu.FactionLocker.window[0]
                    end
                    imgui_funcs.CustomTooltip("Opens faction locker settings.")
                    imgui_funcs.CustomTooltip(string.format("You can also use {%06x}'/%s locker'{%06x} to open this menu.", clr_GREY, shortName, clr_WHITE))
                end
            end
            imgui.EndChild()
            imgui.PopFont()
        end
        imgui.End()
        imgui.PopStyleVar(1)
    end

    local vsKey = "VehicleStorage"
    if menu[vsKey].window[0] then
        local bgColor = colors.convertColor(autobind[vsKey].BackgroundColor, true, true, false)
        local borderColor = colors.convertColor(autobind[vsKey].BorderColor, true, true, false)
        local borderSize = autobind[vsKey].BorderSize
        local rounding = autobind[vsKey].Rounding

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(bgColor.r, bgColor.g, bgColor.b, autobind[vsKey].ShowBackground and bgColor.a or 0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(borderColor.r, borderColor.g, borderColor.b, autobind[vsKey].ShowBorder and borderColor.a or 0))
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, borderSize)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, rounding)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, rounding)
        imgui.PushStyleVarFloat(imgui.StyleVar.ScrollbarSize, 10)
        setupWindowDraggingAndSize(vsKey)

        local vehText = {vehicle = {[0] = "Vehicle:"}, location = {[0] = "Location:"}, status = {[0] = "Status:"}, id = {[0] = "ID:"}}

        local playerName = getCurrentPlayingPlayer()
        if not playerName then
            formattedAddChatMessage("Current playing player not found!")
            menu[vsKey].window[0] = false
            goto skipVehicleStorage
        end

        autobind[vsKey].Vehicles[playerName] = autobind[vsKey].Vehicles[playerName] or {}

        for _, value in pairs(autobind[vsKey].Vehicles[playerName]) do
            if value.id and value.status and value.vehicle and value.location then
                table.insert(vehText.id, string.format("%s", value.id and value.id + 1 or "N/A"))
                table.insert(vehText.status, string.format("%s", value.status or "Unknown"))
                table.insert(vehText.vehicle, string.format("%s", value.vehicle or "Unknown"))
                table.insert(vehText.location, string.format("%s", value.location or "Unknown"))
            end
        end

        if imgui.Begin(vsKey, menu[vsKey].window, menu[vsKey].flags) then
            imgui.SetCursorPosX(imgui.GetWindowWidth() - 20)
            imgui.SetCursorPosY(5)
            imgui.PushFont(fontData.xsmall.font)
            local textColor = menu[vsKey].dragging[0] and imguiRGBA["REALGREEN"] or imguiRGBA["REALRED"]
            if imgui_funcs.CustomButton(fa.ICON_FA_MAP_PIN, imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], textColor, button_size_small2) then
                menu[vsKey].dragging[0] = not menu[vsKey].dragging[0]
            end
            imgui.PopFont()
            if imgui.IsItemHovered() then
                local draggingTooltip = menu[vsKey].dragging[0] and "Click the pin again to disable dragging." or "Click the pin to allow dragging of the window."
                imgui_funcs.CustomTooltip(draggingTooltip)
            end

            local textSize = imgui_funcs.calcTextSize(menu[vsKey].title())
            imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - textSize.x / 2)
            imgui.SetCursorPosY(5)
            imgui.PushFont(fontData.medium.font)
            imgui_funcs.TextColoredRGB(menu[vsKey].title())

            imgui.SetCursorPosX(10)
            imgui.SetCursorPosY(25)
            if imgui.BeginChild("##vehicles", imgui.ImVec2(325, 133.5), false) then
                for i = 0, #vehText.id do
                    imgui_funcs.TextColoredRGB(vehText.id[i])

                    imgui.SameLine(30)
                    if vehText.status[i] == "Status:" then
                        imgui_funcs.TextColoredRGB(vehText.status[i])
                    else
                        imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(4, 1))
                        local vehStatus = removeHexBrackets(vehText.status[i])
                        if imgui_funcs.CustomButton(vehStatus .. "##" .. i, imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], statusVehicleColors[vehText.status[i]]) then
                            vehicles.spawning = true
                            vehicles.currentIndex = i - 1
                            sampSendChat("/vst")
                        end
                        imgui.PopStyleVar()
                    end

                    imgui.SameLine(95)
                    imgui_funcs.TextColoredRGB(vehText.vehicle[i])

                    imgui.SameLine(180)
                    imgui_funcs.TextColoredRGB(vehText.location[i])
                    imgui.SetCursorPosY(imgui.GetCursorPosY() - (i == 0 and 2.5 or 1))
                end
            end
            imgui.EndChild()
            imgui.PopFont()
        end
        imgui.PopStyleVar(5)
        imgui.PopStyleColor(2)
        imgui.End()
    end

    ::skipVehicleStorage::

    local chargesKey = "Charges"
    if menu[chargesKey].window[0] then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        setupWindowDraggingAndSize(chargesKey)
        if imgui.Begin(chargesKey, menu[chargesKey].window, menu[chargesKey].flags) then
            customTitleBar(chargesKey, menu[chargesKey].title())

            renderChargeMenu()
        end
        imgui.End()
        imgui.PopStyleVar(1)
    end

    local skinsKey = "Skins"
    if menu[skinsKey].window[0] then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.PushStyleVarFloat(imgui.StyleVar.ScrollbarSize, 10)
        setupWindowDraggingAndSize(skinsKey)

        if imgui.Begin(skinsKey, menu[skinsKey].window, menu[skinsKey].flags) then
            customTitleBar(skinsKey, menu[skinsKey].title())

            imgui.SetCursorPos(imgui.ImVec2(8, 38))

            local columns = 8
            local imageSize = imgui.ImVec2(50, 80)
            local spacing = 10.0

            if autobind.Settings.mode == "Family" then
                imgui.PushFont(fontData.medium.font)
    
                imgui.PushItemWidth(326)
                local url = new.char[128](autobind.AutoVest.skinsUrl)
                if imgui.InputText('##skins_url', url, sizeof(url)) then
                    autobind.AutoVest.skinsUrl = u8:decode(str(url))
                end
                imgui_funcs.CustomTooltip(string.format('URL to fetch skins from, must be a JSON array of skin IDs,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.skinsUrl))
                imgui.SameLine()
                imgui.PopItemWidth()
                if imgui.Button("Fetch") then
                    fetchJsonDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
                        autobind.AutoVest.skins = decodedData
    
                        -- Convert list to set
                        family.skins = table.listToSet(autobind.AutoVest.skins)
                    end)
                end
                imgui_funcs.CustomTooltip("Fetches skins from provided URL")
                imgui.SameLine()
                if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchSkins)) then
                    autobind.AutoVest.autoFetchSkins = not autobind.AutoVest.autoFetchSkins
                end
                imgui_funcs.CustomTooltip("Fetch skins at startup")
    
                imgui.PopFont()
    
                local startPos = imgui.GetCursorPos()
                local index = drawSkinImages(family.skins, columns, imageSize, spacing, startPos)
    
                local column = index % columns
                local row = math.floor(index / columns)
                local posX = startPos.x + column * (imageSize.x + spacing)
                local posY = startPos.y + row * (imageSize.y + spacing / 4)
    
                imgui.SetCursorPos(imgui.ImVec2(posX, posY))
                if imgui.Button(" Edit\nSkins", imageSize) then
                    menu.Skins.window[0] = not menu.Skins.window[0]
                end

                local storedSkins = {}
                for skinId, _ in pairs(family.skins) do
                    table.insert(storedSkins, skinId)
                end

                table.sort(storedSkins)

                -- Create a string of selected skin IDs
                local selectedSkinsText = table.concat(storedSkins, ",")

                imgui.PushFont(fontData.medium.font)

                -- Display read-only input field with selected skins
                imgui.PushItemWidth(500)
                local buffer = new.char[256](selectedSkinsText)
                imgui.InputText("##selected_skins", buffer, sizeof(buffer), imgui.InputTextFlags.ReadOnly)
                imgui.PopItemWidth()
                imgui_funcs.CustomTooltip("Select skins to use for your family")

                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_COPY) then
                    setClipboardText(selectedSkinsText)
                end
                imgui_funcs.CustomTooltip("Copy selected skin IDs to clipboard")

                imgui.PopFont()

                -- Begin a child window for scrolling
                if imgui.BeginChild("SkinList", imgui.ImVec2(538, 358), false) then
                    imgui.SetCursorPos(imgui.ImVec2(8, 2))
                    imgui.BeginGroup()
                    for skinId = 0, 311 do
                        if (skinId % 8) ~= 0 then
                            imgui.SameLine()
                        end

                        -- Check if the skin is selected
                        local isSelected = family.skins[skinId] == true

                        -- Highlight the selected skin
                        if isSelected then
                            imgui.PushStyleColor(imgui.Col.Button, imguiRGBA["REALGREEN"]) -- Green highlight
                        end

                        if skinTextures[skinId] == nil then
                            local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, skinId)
                            if doesFileExist(skinPath) then
                                skinTextures[skinId] = imgui.CreateTextureFromFile(skinPath)
                            end
                        end

                        if imgui.ImageButton(skinTextures[skinId], imgui.ImVec2(50, 80)) then
                            if isSelected then
                                family.skins[skinId] = nil -- Remove entry if deselected
                            else
                                family.skins[skinId] = true -- Add entry if selected
                            end
                        end

                        if isSelected then
                            imgui.PopStyleColor()
                        end

                        imgui_funcs.CustomTooltip("Skin " .. skinId)
                    end
                    imgui.EndGroup()
                end
                imgui.EndChild()
            elseif autobind.Settings.mode == "Faction" then
                local storedSkins = {}
                for skinId, _ in pairs(factions.skins) do
                    table.insert(storedSkins, skinId)
                end

                table.sort(storedSkins)

                imgui.SetCursorPos(imgui.ImVec2(0, 30))
                if imgui.BeginChild("SkinList", imgui.ImVec2(menu[skinsKey].size.x, menu[skinsKey].size.y - 30), true) then
                    imgui.SetCursorPos(imgui.ImVec2(5, 5))
                    imgui.BeginGroup()
                    for index, skinId in ipairs(storedSkins) do
                        local isSelected = factions.skins[skinId] == true
                        if isSelected then
                            if index % 7 ~= 1 then
                                imgui.SameLine()
                            end

                            if skinTextures[skinId] == nil then
                                local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, skinId)
                                if doesFileExist(skinPath) then
                                    skinTextures[skinId] = imgui.CreateTextureFromFile(skinPath)
                                end
                            end

                            imgui.ImageButton(skinTextures[skinId], imgui.ImVec2(50, 80))
                            imgui_funcs.CustomTooltip("Skin " .. skinId)
                        end
                    end
                    imgui.EndGroup()
                end
                imgui.EndChild()
            end
        end
        imgui.End()
        imgui.PopStyleVar(2)
    end

    --[[function renderSkins()
        imgui.SetCursorPos(imgui.ImVec2(10, 1))
        imgui.BeginGroup()
        local columns = 8
        local imageSize = imgui.ImVec2(50, 80)
        local spacing = 10.0
        
        if autobind.Settings.mode == "Family" then
            imgui.PushFont(fontData.medium.font)
    
            imgui.PushItemWidth(326)
            local url = new.char[128](autobind.AutoVest.skinsUrl)
            if imgui.InputText('##skins_url', url, sizeof(url)) then
                autobind.AutoVest.skinsUrl = u8:decode(str(url))
            end
            imgui_funcs.CustomTooltip(string.format('URL to fetch skins from, must be a JSON array of skin IDs,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.skinsUrl))
            imgui.SameLine()
            imgui.PopItemWidth()
            if imgui.Button("Fetch") then
                fetchJsonDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
                    autobind.AutoVest.skins = decodedData
    
                    -- Convert list to set
                    family.skins = table.listToSet(autobind.AutoVest.skins)
                end)
            end
            imgui_funcs.CustomTooltip("Fetches skins from provided URL")
            imgui.SameLine()
            if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchSkins)) then
                autobind.AutoVest.autoFetchSkins = not autobind.AutoVest.autoFetchSkins
            end
            imgui_funcs.CustomTooltip("Fetch skins at startup")
    
            imgui.PopFont()
    
            local startPos = imgui.GetCursorPos()
            local index = drawSkinImages(family.skins, columns, imageSize, spacing, startPos)
    
            local column = index % columns
            local row = math.floor(index / columns)
            local posX = startPos.x + column * (imageSize.x + spacing)
            local posY = startPos.y + row * (imageSize.y + spacing / 4)
    
            imgui.SetCursorPos(imgui.ImVec2(posX, posY))
            if imgui.Button(" Edit\nSkins", imageSize) then
                menu.Skins.window[0] = not menu.Skins.window[0]
            end
        end
        imgui.EndGroup()
    end]]

    local namesKey = "Names"
    if menu[namesKey].window[0] then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        setupWindowDraggingAndSize(namesKey)

        if imgui.Begin(namesKey, menu[namesKey].window, menu[namesKey].flags) then
            customTitleBar(namesKey, menu[namesKey].title())
            imgui.SetCursorPos(imgui.ImVec2(10, 38))
            if imgui.BeginChild("##names", imgui.ImVec2(menu[namesKey].size.x - 10, menu[namesKey].size.y - 38), false) then

                imgui.PushItemWidth(326)
                local url = new.char[128](autobind.AutoVest.namesUrl)
                if imgui.InputText('##names_url', url, sizeof(url)) then
                    autobind.AutoVest.namesUrl = u8:decode(str(url))
                end
                imgui_funcs.CustomTooltip(string.format('%s (%s)', fa.ICON_FA_LINK, autobind.AutoVest.namesUrl))
                imgui.SameLine()
                imgui.PopItemWidth()
                if imgui.Button("Fetch") then
                    fetchJsonDataDirectlyFromURL(autobind.AutoVest.namesUrl, function(decodedData)
                        if decodedData then
                            autobind.AutoVest.names = decodedData

                            -- Convert list to set
                            names = table.listToSet(autobind.AutoVest.names)
                        end
                    end)
                end
                imgui_funcs.CustomTooltip("URL to fetch names must be a JSON formatted array of names.")
                imgui.SameLine()
                if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchNames)) then
                    autobind.AutoVest.autoFetchNames = not autobind.AutoVest.autoFetchNames
                end
                imgui_funcs.CustomTooltip("Fetch names at startup")

                imgui.PushFont(fontData.medium.font)
                        
                local itemsPerRow = 3  -- Number of items per row
                local itemCount = 0

                local sortedNames = {}
                for name, _ in pairs(names) do
                    table.insert(sortedNames, name)
                end

                table.sort(sortedNames)
                
                for _, name in ipairs(sortedNames) do

                    imgui.PushItemWidth(138)  -- Adjust the width of the input field
                    local nick = new.char[128](name)
                    if imgui.InputText('##Nickname'..name, nick, sizeof(nick), imgui.InputTextFlags.EnterReturnsTrue) then
                        names[name] = nil
                        names[u8:decode(str(nick))] = true
                    end
                    imgui.PopItemWidth()
                    imgui.SameLine()
                    imgui.SetCursorPosX(imgui.GetCursorPosX() - 7)
                    if imgui.Button("x##"..name) then
                        names[name] = nil
                    end
                        
                    itemCount = itemCount + 1
                    if itemCount % itemsPerRow ~= 0 then
                        imgui.SameLine()
                    end
                end

                if imgui.Button("Add Name", imgui.ImVec2(154, 18)) then
                    local baseName = "Name"
                    local newName = baseName
                    local counter = 1

                    -- Check if the name already exists and append a number if necessary
                    while names[newName] do
                        newName = baseName .. tostring(counter)
                        counter = counter + 1
                    end

                    -- Add the new name to the set
                    names[newName] = true
                end

                imgui.PopFont()
            end
            imgui.EndChild()
        end
        imgui.End()
        imgui.PopStyleVar(1)
    end

    local confirmKey = "Confirm"
    if menu[confirmKey].window[0] then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, menu[confirmKey].pivot)
        imgui.SetNextWindowFocus()

        if imgui.Begin(confirmKey, menu[confirmKey].window, menu[confirmKey].flags) then
            if menu[confirmKey].update[0] then
                customTitleBar(confirmKey, menu[confirmKey].title())

                imgui.SetCursorPos(imgui.ImVec2(10, 38))
                imgui.Text('Do you want to update this script?')

                -- Get available space and divide it for the buttons
                local availableWidth = imgui.GetContentRegionAvail().x
                local buttonWidth = (availableWidth - imgui.GetStyle().ItemSpacing.x) / 2
                local buttonSize = imgui.ImVec2(buttonWidth, 45)

                if imgui_funcs.CustomButton(fa.ICON_FA_CHECK .. ' Update', imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], buttonSize) then
                    updateScript()
                    menu[confirmKey].update[0] = false
                    menu[confirmKey].window[0] = false
                end
                imgui.SameLine()
                if imgui_funcs.CustomButton(fa.ICON_FA_TIMES .. ' Cancel', imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], buttonSize) then
                    menu[confirmKey].update[0] = false
                    menu[confirmKey].window[0] = false

                    if autoReboot then
                        script.load(workingDir .. "\\AutoReboot.lua")
                    end
                end
            end
        end
        imgui.End()
        imgui.PopStyleVar(1)
    end

    for label, name in pairs(lockerVars) do
        if menu[name].window[0] then
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            renderLockerWindow(label, name)
            imgui.PopStyleVar(1)
        end
    end

    local changeLogKey = "Changelog"
    if menu[changeLogKey].window[0] then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        renderChangelogWindow(changeLogKey)
        imgui.PopStyleVar(1)
    end
end).HideCursor = true

function renderAutoBind()
    imgui.SetCursorPos(imgui.ImVec2(10, 10))
    imgui.PushFont(fontData.medium.font)
    imgui.BeginGroup()

    imgui.Text(string.format('%s:', scriptName:upperFirst()))
    imgui.Indent()
    if imgui.Checkbox(string.format('Auto Repair (/%s)', clientCommands.repairnear.cmd), new.bool(autobind.Settings.autoRepair)) then
        autobind.Settings.autoRepair = toggleBind("Accept Repair", autobind.Settings.autoRepair)
    end
    imgui_funcs.CustomTooltip('Auto Repair will automatically accept repair requests.')

    imgui.Unindent()

    imgui.Text("Frisk:")
    imgui.Indent()
    if imgui.Checkbox('Target', new.bool(autobind.Settings.mustTargetToFrisk)) then
        autobind.Settings.mustTargetToFrisk = toggleBind("Targeting", autobind.Settings.mustTargetToFrisk)
    end
    imgui_funcs.CustomTooltip('Must be targeting a player to frisk. (Green Blip above the player)')
    imgui.SameLine()
    if imgui.Checkbox('Must Aim', new.bool(autobind.Settings.mustAimToFrisk)) then
        autobind.Settings.mustAimToFrisk = toggleBind("Must Aim", autobind.Settings.mustAimToFrisk)
    end
    imgui_funcs.CustomTooltip('Must be aiming to frisk.')
    imgui.Unindent()

    imgui.Text("Peds:")
    imgui.Indent()
    createFontMenuElement("PedsCount", "Peds", autobind.Elements.PedsCount, false)
    imgui.Unindent()

    imgui.PopFont()
    imgui.EndGroup()
end

function renderGuard(mode)
    if mode == "Family" then
        imgui.SetCursorPos(imgui.ImVec2(10, 10))
        imgui.BeginGroup()
        imgui.PushFont(fontData.medium.font)
        
        imgui.Text("Guard Families:")
        imgui.Indent()
        imgui.Text("Hello")
        imgui.Unindent()
        imgui.PopFont()
        imgui.EndGroup()
    elseif mode == "Faction" then
        imgui.SetCursorPos(imgui.ImVec2(10, 10))

        imgui.BeginGroup()
        imgui.PushFont(fontData.medium.font)

        if imgui.Checkbox(string.format("Guard %s", autobind.AutoVest.guardFeatures and "Enabled" or "Disabled"), new.bool(autobind.AutoVest.guardFeatures)) then
            autobind.AutoVest.guardFeatures = not autobind.AutoVest.guardFeatures
        end
        imgui_funcs.CustomTooltip("When this is disabled all features related to sending guard requests will be disabled.")
        imgui.SameLine()
        if imgui.Checkbox(string.format("Accept %s", autobind.AutoVest.acceptFeatures and "Enabled" or "Disabled"), new.bool(autobind.AutoVest.acceptFeatures)) then
            autobind.AutoVest.acceptFeatures = not autobind.AutoVest.acceptFeatures
        end
        imgui_funcs.CustomTooltip("When this is disabled all features related to accepting vest requests will be disabled.")

        imgui.Text(string.format("Current Mode: %s", mode))
        imgui_funcs.CustomTooltip(string.format("Mode is automatically detected but you can use /%s to switch the current mode.", clientCommands.changemode.cmd))
        imgui.SameLine()
            
        local factionColors = {}
        for color, factionName in pairs(factions.badges) do
            table.insert(factionColors, string.format("{%06x}%s", color, factionName))
        end
        imgui.BeginGroup()
        imgui_funcs.TextColoredRGB(string.format("(%s{FFFFFF})", table.concat(factionColors, "{FFFFFF}, ")))
        imgui.EndGroup()
        imgui_funcs.CustomTooltip("Colors you are currently guarding [Factions].")

        imgui.Indent()

        if imgui.Button("Skin List") then
            menu.Skins.window[0] = not menu.Skins.window[0]
        end
        imgui.SameLine()
        if imgui.Checkbox("Use Skins", new.bool(autobind.AutoVest.useSkins)) then
            autobind.AutoVest.useSkins = not autobind.AutoVest.useSkins
        end
        imgui_funcs.CustomTooltip("Checks if the player has the skins listed below, otherwise it relies on color.")
        imgui.SameLine() 
        if imgui.Button("Name List") then
            menu.Names.window[0] = not menu.Names.window[0]
        end
        imgui.SameLine()
        imgui.BeginGroup()
        if imgui.Checkbox("Use Names", new.bool(autobind.AutoVest.useNames)) then
            autobind.AutoVest.useNames = not autobind.AutoVest.useNames
        end
        imgui_funcs.CustomTooltip("Checks if the player has the names listed below, otherwise it relies on skins.")
        imgui.SameLine()
        imgui.SetCursorPos(imgui.ImVec2(imgui.GetCursorPosX() - 7, imgui.GetCursorPosY() - 1))
        imgui.Text("(?)")
        imgui_funcs.CustomTooltip("Names are prioritized over colors and skins.")
        imgui.EndGroup()
        if imgui.Checkbox(string.format("Auto Send Guard (/%s)", clientCommands.autovest.cmd), new.bool(autobind.AutoVest.autoGuard)) then
            autobind.AutoVest.autoGuard = not autobind.AutoVest.autoGuard
        end
        imgui_funcs.CustomTooltip("Auto Send Guard will automatically send a guard request to the nearest player.")

        imgui.SameLine()
        
        if imgui.Checkbox(string.format("Auto Accept Vest (/%s)", clientCommands.autoaccept.cmd), new.bool(accepter.enable)) then
            accepter.enable = not accepter.enable
        end
        imgui_funcs.CustomTooltip("Accept Vest will automatically accept vest requests.")

        if imgui.Checkbox(string.format("Diamond Donator (/%s)", clientCommands.ddmode.cmd), new.bool(autobind.AutoVest.donor)) then
            autobind.AutoVest.donor = not autobind.AutoVest.donor
            timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime
        end
        imgui_funcs.CustomTooltip("Enable for Diamond Donators. Uses /guardnear does not have armor/paused checks.")

        imgui.SameLine()

        if imgui.Checkbox(string.format("Allow Everyone (/%s)", clientCommands.vestall.cmd), new.bool(autobind.AutoVest.everyone)) then
            autobind.AutoVest.everyone = not autobind.AutoVest.everyone
        end
        imgui_funcs.CustomTooltip("With this enabled, the vest will be applied to everyone on the server.")

        imgui.Unindent()

        imgui.NewLine()

        imgui.Text("Offered To:")
        imgui.Indent()
        createFontMenuElement("OfferedTo", "Vest To", autobind.Elements.offeredTo, false)
        imgui.Unindent()
        imgui.Text("Offered From:")
        imgui.Indent()
        createFontMenuElement("OfferedFrom", "Vest From", autobind.Elements.offeredFrom, false)
        imgui.Unindent()

        imgui.PopFont()
        imgui.EndGroup()
    else
        imgui.Text("Mode not found.")
    end
end

function renderAutoFind()
    imgui.SetCursorPos(imgui.ImVec2(10, 10))
    imgui.BeginGroup()
    imgui.PushFont(fontData.medium.font)

    imgui.Text("Auto Find:")
    imgui.Indent()
    createFontMenuElement("AutoFind", "Auto Find", autobind.Elements.AutoFind, false)
    imgui.Unindent()

    imgui.PopFont()
    imgui.EndGroup()
end

function renderKeybinds()
    imgui.SetCursorPos(imgui.ImVec2(10, 5))
    imgui.BeginGroup()
    
    -- Number of columns
    local numColumns = 3
    imgui.Columns(numColumns, "##keybinds", false)
    
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))
    imgui.PushFont(fontData.medium.font)
    for index, editor in ipairs(keyEditors) do
        keyEditor(editor.label, editor.key, editor.description, function(action, name)
            if action == "toggle" and name == "SprintBind" then
                autobind.Settings.sprintBind = autobind.Keybinds[name].Toggle
            end
        end)
        
        -- Move to next column after each item, but wrap to new row when needed
        if index % numColumns ~= 0 then
            imgui.NextColumn()
        else
            -- Last column of the row, reset back to first column
            imgui.Columns(1) -- Reset columns
            imgui.Columns(numColumns, "##keybinds"..index, false) -- Create new row of columns
        end
    end
    
    imgui.PopFont()
    imgui.PopStyleVar()
    imgui.Columns(1)
    imgui.EndGroup()
end

function renderFactions()
    imgui.SetCursorPos(imgui.ImVec2(10, 10))
    imgui.BeginGroup()
    imgui.PushFont(fontData.medium.font)

    imgui.Text("Settings:")
    imgui.Indent()

    if imgui.Checkbox(string.format("Auto Capture (/%s)", clientCommands.autocap.cmd), new.bool(autoCapture)) then
        toggleAutoCapture()
    end
    imgui_funcs.CustomTooltip("Auto Capture will automatically type /capturf every 1.5 seconds.")
    imgui.SameLine()
    if imgui.Checkbox(string.format('Capturf at Signcheck (/%s)', clientCommands.capcheck.cmd), new.bool(autobind.Faction.turf)) then
        autobind.Faction.turf = not autobind.Faction.turf
    end
    imgui_funcs.CustomTooltip("Capture (Turfs) will automatically type /capturf at signcheck time.")

    if imgui.Checkbox(string.format('Auto Badge (/%s)', clientCommands.autobadge.cmd), new.bool(autobind.Faction.autoBadge)) then
        autobind.Faction.autoBadge = not autobind.Faction.autoBadge
    end
    imgui_funcs.CustomTooltip("Automatically types /badge after spawning from the hospital.")

    if imgui.Checkbox("Show Cades", new.bool(autobind.Faction.showCades)) then
        autobind.Faction.showCades = not autobind.Faction.showCades
    end
    imgui_funcs.CustomTooltip("?")
    imgui.SameLine()
    if imgui.Checkbox("Show Cades Locally", new.bool(autobind.Faction.showCadesLocal)) then
        autobind.Faction.showCadesLocal = not autobind.Faction.showCadesLocal
    end
    imgui_funcs.CustomTooltip("?")

    if imgui.Checkbox("Show Spikes", new.bool(autobind.Faction.showSpikes)) then
        autobind.Faction.showSpikes = not autobind.Faction.showSpikes
    end
    imgui_funcs.CustomTooltip("?")
    imgui.SameLine()
    if imgui.Checkbox("Show Spikes Locally", new.bool(autobind.Faction.showSpikesLocal)) then
        autobind.Faction.showSpikesLocal = not autobind.Faction.showSpikesLocal
    end
    imgui_funcs.CustomTooltip("?")

    if imgui.Checkbox("Show Cones", new.bool(autobind.Faction.showCones)) then
        autobind.Faction.showCones = not autobind.Faction.showCones
    end
    imgui_funcs.CustomTooltip("?")
    imgui.SameLine()
    if imgui.Checkbox("Show Flares", new.bool(autobind.Faction.showFlares)) then
        autobind.Faction.showFlares = not autobind.Faction.showFlares
    end
    imgui_funcs.CustomTooltip("?")

    imgui.Unindent()

    imgui.Text('Radio Chat:')
    imgui.Indent()
    if imgui.Checkbox('Modify [WIP]', new.bool(autobind.Faction.modifyRadioChat)) then
        autobind.Faction.modifyRadioChat = not autobind.Faction.modifyRadioChat
    end
    imgui_funcs.CustomTooltip("Modify the radio chat to your liking.")
    imgui.Unindent()

    imgui.Text("Last Backup:")
    imgui.Indent()
    createFontMenuElement("LastBackup", "Last Backup", autobind.Elements.LastBackup, false)
    imgui.Unindent()

    imgui.Text("Badge:")
    imgui.Indent()
    createFontMenuElement("FactionBadge", "Badge", autobind.Elements.FactionBadge, true)
    imgui.Unindent()

    imgui.PopFont()
    imgui.EndGroup()
end

function renderFamilies()
    imgui.SetCursorPos(imgui.ImVec2(10, 10))
    imgui.BeginGroup()
    imgui.PushFont(fontData.medium.font)

    imgui.Text("Families:")
    imgui.Indent()
    imgui.Text("Hello")
    imgui.Unindent()

    imgui.PopFont()
    imgui.EndGroup()
end

--[[

createRow(string.format('Auto Cap (/%s)', clientCommands.autocap.cmd), 'Auto Capture will automatically type /capturf every 1.5 seconds.', autoCapture, toggleAutoCapture, true)

    local mode = autobind.Settings.mode
    createRow(string.format('Capturf at Signcheck (/%s)', clientCommands.capcheck.cmd), 'Capture (Turfs) will automatically type /capturf at signcheck time.', autobind[mode].turf, function()
        autobind[mode].turf = toggleBind("Capture (Turfs)", autobind[mode].turf)
        if mode == "Family" then
            autobind[mode].point = false
        end
    end, false)
    
    if mode == "Family" then
        createRow('Disable capturing', 'Disable capturing after capturing: turns off auto capturing after the point/turf has been secured.', autobind.Family.disableAfterCapturing, function()
            autobind.Family.disableAfterCapturing = toggleBind("Disable Capturing", autobind.Family.disableAfterCapturing)
        end, true)
        
        createRow('Capture (Points)', 'Capture (Points) will automatically type /capturf at signcheck time.', autobind.Family.point, function()
            autobind.Family.point = toggleBind("Capture Point", autobind.Family.point)
            if autobind.Family.point then
                autobind.Family.turf = false
            end
        end, false)
    end

]]

function renderWanted()
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))

    imgui.SetCursorPos(imgui.ImVec2(10, 10))
    imgui.BeginGroup()
    imgui.PushFont(fontData.medium.font)

    -- Enabled
    if imgui.Checkbox('Show Wanted List', new.bool(autobind.Wanted.Enabled)) then
        autobind.Wanted.Enabled = not autobind.Wanted.Enabled
    end
    imgui.SameLine()
    if imgui.Button("Defaults") then
        autobind.Wanted = configs.deepCopy(autobind_defaultSettings.Wanted)
    end

    -- Refresh Settings
    imgui.Text("Refresh Settings")
    imgui.Indent()
    if imgui.Checkbox('Show Refresh', new.bool(autobind.Wanted.ShowRefresh)) then
        autobind.Wanted.ShowRefresh = not autobind.Wanted.ShowRefresh
    end
    imgui.SameLine()
    local refreshClr = colors.convertColor(autobind.Wanted.RefreshColor, true, false)
    local refreshColor = new.float[3](refreshClr.r, refreshClr.g, refreshClr.b)
    if imgui.ColorEdit3('##Refresh Color Wanted', refreshColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
        autobind.Wanted.RefreshColor = colors.joinARGB(0, refreshColor[0], refreshColor[1], refreshColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("Refresh Color")
    imgui.SameLine()
    imgui.PushItemWidth(25)
    local timer = new.float[1](autobind.Wanted.Timer)
    if imgui.DragFloat('Refresh Rate', timer, 1, 8, 15, "%.f") then
        if timer[0] >= 8 and timer[0] <= 15 then
            autobind.Wanted.Timer = timer[0]
        end
    end
    imgui.PopItemWidth()
    imgui.Unindent()

    -- Expiry Settings
    imgui.Text("Expiry Times")
    imgui.SameLine(imgui.GetCursorPosX() + 55)
    imgui.PushFont(fontData.small.font)
    imgui.Text("(seconds)")
    imgui.PopFont()
    imgui.Indent()
    imgui.PushItemWidth(25)
    for name, expiry in pairs(autobind.Wanted.Expiry) do
        local expiryValue = new.float[1](expiry)
        if imgui.DragFloat(name:upperFirst(), expiryValue, 1, 5, 60, "%.f") then
            if expiryValue[0] >= 5 and expiryValue[0] <= 60 then
                autobind.Wanted.Expiry[name] = expiryValue[0]
            end
        end
        if name ~= "disconnected" then
            imgui.SameLine()
        end
    end
    imgui.PopItemWidth()
    imgui.Unindent()

    -- Border/Padding and Alignment
    imgui.PushItemWidth(20)
    imgui.Text("Appearance")
    imgui.Indent()
    local border = new.float[1](autobind.Wanted.BorderSize)
    if imgui.DragFloat('Border Size', border, 1, 1, 5, "%.f") then
        if border[0] >= 1 and border[0] <= 5 then
            autobind.Wanted.BorderSize = border[0]
        end
    end
    imgui.PopItemWidth()
    imgui.SameLine()
    -- Rounding
    imgui.PushItemWidth(20)
    local rounding = new.float[1](autobind.Wanted.Rounding)
    if imgui.DragFloat('Rounding', rounding, 1, 1, 5, "%.f") then
        if rounding[0] >= 1 and rounding[0] <= 5 then
            autobind.Wanted.Rounding = rounding[0]
        end
    end
    imgui.PopItemWidth()
    imgui.SameLine()
    imgui.PushItemWidth(35)
    local padding = new.float[1](autobind.Wanted.Padding.x)
    if imgui.DragFloat('Padding', padding, 0.1, 1, 10, "%.1f") then
        if padding[0] >= 1 and padding[0] <= 10 then
            autobind.Wanted.Padding = {x = padding[0], y = padding[0]}
        end
    end
    imgui.PopItemWidth()
    imgui.SameLine()
    imgui.PushItemWidth(125)
    if imgui.BeginCombo("Align", findPivotIndex(autobind.Wanted.Pivot)) then
        for i = 1, #pivots do
            local pivot = pivots[i]
            if imgui.Selectable(pivot.name .. " " .. pivot.icon, comparePivots(autobind.Wanted.Pivot, pivot.value)) then
                autobind.Wanted.Pivot = pivot.value
            end
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()

    -- Ping and Stars
    if imgui.Checkbox("Show Ping", new.bool(autobind.Wanted.Ping)) then
        autobind.Wanted.Ping = not autobind.Wanted.Ping
    end
    imgui.SameLine()
    if imgui.Checkbox("Show Stars", new.bool(autobind.Wanted.Stars)) then
        autobind.Wanted.Stars = not autobind.Wanted.Stars
    end

    imgui.SameLine()
    
    -- AFK Settings
    if imgui.Checkbox('Show AFK', new.bool(autobind.Wanted.ShowAFK)) then
        autobind.Wanted.ShowAFK = not autobind.Wanted.ShowAFK
    end
    imgui.SameLine()
    local afkClr = colors.convertColor(autobind.Wanted.AFKTextColor, true, false)
    local afkColor = new.float[3](afkClr.r, afkClr.g, afkClr.b)
    if imgui.ColorEdit3('##AFK Text Color Wanted', afkColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
        autobind.Wanted.AFKTextColor = colors.joinARGB(0, afkColor[0], afkColor[1], afkColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("AFK Text Color")

    imgui.Unindent()

    -- Background and Border Color
    imgui.Text("Colors")
    imgui.Indent()

    -- Background Color
    if imgui.Checkbox(string.format('%s##WantedBackground', autobind.Wanted.ShowBackground and "On" or "Off"), new.bool(autobind.Wanted.ShowBackground)) then
        autobind.Wanted.ShowBackground = not autobind.Wanted.ShowBackground
    end
    imgui.SameLine()
    local bgClr = colors.convertColor(autobind.Wanted.BackgroundColor, true, true)
    local bgColor = new.float[4](bgClr.r, bgClr.g, bgClr.b, bgClr.a)
    if imgui.ColorEdit4('##Background Color Wanted', bgColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
        autobind.Wanted.BackgroundColor = colors.joinARGB(bgColor[3], bgColor[0], bgColor[1], bgColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("Background")
    imgui.SameLine()
    -- Background Alpha Slider
    imgui.PushItemWidth(70)
    local bgAlpha = new.float[1](bgColor[3] * 100)  -- Convert alpha to percentage
    if imgui.SliderFloat('##Background Alpha', bgAlpha, 1, 100, "Alpha: %.0f%%") then
        bgColor[3] = bgAlpha[0] / 100  -- Convert back to 0-1 range
        autobind.Wanted.BackgroundColor = colors.joinARGB(bgColor[3], bgColor[0], bgColor[1], bgColor[2], true)
    end
    imgui.PopItemWidth()

    -- Border Color
    if imgui.Checkbox(string.format('%s##WantedBorder', autobind.Wanted.ShowBorder and "On" or "Off"), new.bool(autobind.Wanted.ShowBorder)) then
        autobind.Wanted.ShowBorder = not autobind.Wanted.ShowBorder
    end
    imgui.SameLine()
    local borderClr = colors.convertColor(autobind.Wanted.BorderColor, true, true)
    local borderColor = new.float[4](borderClr.r, borderClr.g, borderClr.b, borderClr.a)
    if imgui.ColorEdit4('##Border Color Wanted', borderColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
        autobind.Wanted.BorderColor = colors.joinARGB(borderColor[3], borderColor[0], borderColor[1], borderColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("Border")
    imgui.SameLine()
    -- Border Alpha Slider
    imgui.PushItemWidth(70)
    local borderAlpha = new.float[1](borderColor[3] * 100)  -- Convert alpha to percentage
    if imgui.SliderFloat('##Border Alpha', borderAlpha, 1, 100, "Alpha: %.0f%%") then
        borderColor[3] = borderAlpha[0] / 100  -- Convert back to 0-1 range
        autobind.Wanted.BorderColor = colors.joinARGB(borderColor[3], borderColor[0], borderColor[1], borderColor[2], true)
    end
    imgui.PopItemWidth()
    --imgui.SameLine()
    local mostWantedClr = colors.convertColor(autobind.Wanted.MostWantedColor, true, false)
    local mostWantedColor = new.float[3](mostWantedClr.r, mostWantedClr.g, mostWantedClr.b)
    if imgui.ColorEdit3('##Most Wanted Color Wanted', mostWantedColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
        autobind.Wanted.MostWantedColor = colors.joinARGB(0, mostWantedColor[0], mostWantedColor[1], mostWantedColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("Most Wanted Color")

    imgui.Unindent()

    imgui.PopFont()

    -- Preview
    local displayWanted = {}
    local baseTimestamp = os.clock() + 0.5

    local states = {
        {charges = 0, active = false, disconnected = true},
        {charges = 0, active = false, processed = true},
        {charges = 0, active = false, cleared = true},
        {charges = 0, active = false, lawyer = true},
        {charges = 6, active = true, cleared = false},
        {charges = 4, active = true, cleared = false}
    }

    for _, state in ipairs(states) do
        table.insert(displayWanted, {
            name = "Player Name",
            id = 27,
            charges = state.charges,
            timestamp = state.active and 0 or baseTimestamp,
            active = state.active,
            lawyer = state.lawyer or false,
            disconnected = state.disconnected or false,
            processed = state.processed or false,
            cleared = state.cleared or false,
            updated = state.active,
            markedDeactivated = not state.active
        })
    end

    imgui.SetCursorPos(imgui.ImVec2((child_size_pages.x / 2) + 20, (child_size_pages.y / 2) + 45))
    imgui.PushFont(fontData.small.font)

    local bgColor = colors.convertColor(autobind.Wanted.BackgroundColor, true, true, false)
    local borderColor = colors.convertColor(autobind.Wanted.BorderColor, true, true, false)
    local borderSize = autobind.Wanted.BorderSize
    local padding = autobind.Wanted.Padding
    local rounding = autobind.Wanted.Rounding

    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(bgColor.r, bgColor.g, bgColor.b, autobind.Wanted.ShowBackground and bgColor.a or 0))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(borderColor.r, borderColor.g, borderColor.b, autobind.Wanted.ShowBorder and borderColor.a or 0))
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, padding)
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildBorderSize, borderSize)
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, rounding)

    if imgui.BeginChild("##prewviewwanted", imgui.ImVec2(225, 90), true) then
        for _, wanted in pairs(displayWanted) do
            local formattedWanted = formatWantedString(wanted, true, true, true)
            imgui_funcs.TextColoredRGB(formattedWanted)
        end
    end
    imgui.EndChild()

    imgui.PopStyleVar(3)
    imgui.PopStyleColor(2)

    imgui.PopFont()

    imgui.EndGroup()
    imgui.PopStyleVar(1)
end

function renderVehicleStorage()
    imgui.SetCursorPos(imgui.ImVec2(10, 10))
    imgui.BeginGroup()
    imgui.PushFont(fontData.medium.font)

    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))

    -- Enabled
    if imgui.Checkbox(string.format('Vehicle Storage %s', autobind.VehicleStorage.enable and "Enabled" or "Disabled"), new.bool(autobind.VehicleStorage.enable)) then
        autobind.VehicleStorage.enable = not autobind.VehicleStorage.enable
        if not autobind.VehicleStorage.enable then
            menu.VehicleStorage.window[0] = false
        end
    end
    imgui.SameLine()
    if imgui.Button("Defaults") then
        autobind.VehicleStorage = configs.deepCopy(autobind_defaultSettings.VehicleStorage)
    end
    imgui.SameLine()
    if imgui.Button("Reset Vehicle Storage") then
        resetVehicleStorage()
    end

    -- Refresh Settings
    imgui.Text("Menu Settings")
    imgui.Indent()
    if imgui.Checkbox('Show Menu', new.bool(autobind.VehicleStorage.menu)) then
        autobind.VehicleStorage.menu = not autobind.VehicleStorage.menu
        if not autobind.VehicleStorage.menu then
            menu.VehicleStorage.window[0] = false
        end
    end

    imgui.SameLine()
    if imgui.Checkbox('Chat Open', new.bool(autobind.VehicleStorage.chatInput)) then
        autobind.VehicleStorage.chatInput = not autobind.VehicleStorage.chatInput
    end
    imgui.SameLine()
    if imgui.Checkbox('Chat Text', new.bool(autobind.VehicleStorage.chatInputText)) then
        autobind.VehicleStorage.chatInputText = not autobind.VehicleStorage.chatInputText
    end
    imgui.Unindent()

    -- Border/Padding and Alignment
    imgui.PushItemWidth(20)
    imgui.Text("Appearance")
    imgui.Indent()
    local border = new.float[1](autobind.VehicleStorage.BorderSize)
    if imgui.DragFloat('Border Size##Vstorage', border, 1, 1, 5, "%.f") then
        if border[0] >= 1 and border[0] <= 5 then
            autobind.VehicleStorage.BorderSize = border[0]
        end
    end
    imgui.PopItemWidth()
    imgui.SameLine()
    -- Rounding
    imgui.PushItemWidth(20)
    local rounding = new.float[1](autobind.VehicleStorage.Rounding)
    if imgui.DragFloat('Rounding##Vstorage', rounding, 1, 1, 5, "%.f") then
        if rounding[0] >= 1 and rounding[0] <= 5 then
            autobind.VehicleStorage.Rounding = rounding[0]
        end
    end
    imgui.PopItemWidth()
    --[[imgui.SameLine()
    imgui.PushItemWidth(35)
    local padding = new.float[1](autobind.VehicleStorage.Padding.x)
    if imgui.DragFloat('Padding##Vstorage', padding, 0.1, 1, 10, "%.1f") then
        if padding[0] >= 1 and padding[0] <= 10 then
            autobind.VehicleStorage.Padding = {x = padding[0], y = padding[0]}
        end
    end
    imgui.PopItemWidth()]]
    imgui.SameLine()
    imgui.PushItemWidth(125)
    if imgui.BeginCombo("Align##Vstorage", findPivotIndex(autobind.VehicleStorage.Pivot)) then
        for i = 1, #pivots do
            local pivot = pivots[i]
            if imgui.Selectable(pivot.name .. " " .. pivot.icon, comparePivots(autobind.VehicleStorage.Pivot, pivot.value)) then
                autobind.VehicleStorage.Pivot = pivot.value
            end
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()

    imgui.Unindent()

    -- Background and Border Color
    imgui.Text("Colors")
    imgui.Indent()

    -- Background Color
    if imgui.Checkbox(string.format('%s##VehicleStorageBackground', autobind.VehicleStorage.ShowBackground and "On" or "Off"), new.bool(autobind.VehicleStorage.ShowBackground)) then
        autobind.VehicleStorage.ShowBackground = not autobind.VehicleStorage.ShowBackground
    end
    imgui.SameLine()
    local bgClr = colors.convertColor(autobind.VehicleStorage.BackgroundColor, true, true)
    local bgColor = new.float[4](bgClr.r, bgClr.g, bgClr.b, bgClr.a)
    if imgui.ColorEdit4('##Background Color Vehicle Storage', bgColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
        autobind.VehicleStorage.BackgroundColor = colors.joinARGB(bgColor[3], bgColor[0], bgColor[1], bgColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("Background")
    imgui.SameLine()
    -- Background Alpha Slider
    imgui.PushItemWidth(70)
    local bgAlpha = new.float[1](bgColor[3] * 100)  -- Convert alpha to percentage
    if imgui.SliderFloat('##Background Alpha', bgAlpha, 1, 100, "Alpha: %.0f%%") then
        bgColor[3] = bgAlpha[0] / 100  -- Convert back to 0-1 range
        autobind.VehicleStorage.BackgroundColor = colors.joinARGB(bgColor[3], bgColor[0], bgColor[1], bgColor[2], true)
    end
    imgui.PopItemWidth()

    -- Border Color
    if imgui.Checkbox(string.format('%s##VehicleStorageBorder', autobind.VehicleStorage.ShowBorder and "On" or "Off"), new.bool(autobind.VehicleStorage.ShowBorder)) then
        autobind.VehicleStorage.ShowBorder = not autobind.VehicleStorage.ShowBorder
    end
    imgui.SameLine()
    local borderClr = colors.convertColor(autobind.VehicleStorage.BorderColor, true, true)
    local borderColor = new.float[4](borderClr.r, borderClr.g, borderClr.b, borderClr.a)
    if imgui.ColorEdit4('##Border Color Vehicle Storage', borderColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
        autobind.VehicleStorage.BorderColor = colors.joinARGB(borderColor[3], borderColor[0], borderColor[1], borderColor[2], true)
    end
    imgui.SameLine()
    imgui.Text("Border")
    imgui.SameLine()
    -- Border Alpha Slider
    imgui.PushItemWidth(70)
    local borderAlpha = new.float[1](borderColor[3] * 100)  -- Convert alpha to percentage
    if imgui.SliderFloat('##Border Alpha', borderAlpha, 1, 100, "Alpha: %.0f%%") then
        borderColor[3] = borderAlpha[0] / 100  -- Convert back to 0-1 range
        autobind.VehicleStorage.BorderColor = colors.joinARGB(borderColor[3], borderColor[0], borderColor[1], borderColor[2], true)
    end
    imgui.PopItemWidth()

    imgui.Unindent()

    imgui.PopFont()
    imgui.PopStyleVar(1)
    imgui.EndGroup()
end

-- Helper function to check if a given charge conflicts with any other active charge
local function isChargeConflicting(currentCharge)
    for _, otherCharge in ipairs(chargeList.Charges) do
        if otherCharge ~= currentCharge and otherCharge.active then
            -- Check if the current charge’s name is listed in the active other charge’s conflicts…
            for _, conflict in ipairs(otherCharge.stacks) do
                if conflict == currentCharge.name then
                    return true, otherCharge.name
                end
            end
            -- ...or if the other charge’s name is in the current charge’s stack list.
            for _, conflict in ipairs(currentCharge.stacks) do
                if conflict == otherCharge.name then
                    return true, otherCharge.name
                end
            end
        end
    end
    return false
end

local charges = {
    count = 0,
    fine = 0,
    time = 0
}

function renderChargeMenu()
    imgui.PushFont(fontData.medium.font)
    imgui.SetCursorPosY(30)
    if imgui.BeginChild("charges", imgui.ImVec2(500, 240), false) then
        local columns = 2
        local columnWidth = 240

        if chargeList then

            -- Setup two columns
            imgui.Columns(columns, "ChargesColumns", false)
            for i = 0, columns - 1 do
                imgui.SetColumnWidth(i, columnWidth)
            end

            for index, value in ipairs(chargeList.Charges) do
                -- Determine if this charge should be disabled.
                -- We only disable it visually if it is not already active and activating it would conflict.
                local conflict, conflictName = isChargeConflicting(value)
                local disabled = conflict and (not value.active)

                -- Prepare the current active state.
                local isActive = new.bool(value.active)

                -- If disabled, wrap the checkbox in a disabled block.
                if disabled then
                    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.200, 0.216, 0.259, 1.00))
                    imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(0.200, 0.216, 0.259, 1.00))
                    imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(0.200, 0.216, 0.259, 1.00))
                    imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(0.200, 0.216, 0.259, 1.00))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.85, 0.85, 0.85, 0.25))
                    imgui.Checkbox(value.name, new.bool(false))
                    imgui.PopStyleColor(5)
                else
                    if imgui.Checkbox(value.name, isActive) then
                        if isActive[0] then
                            -- User is trying to activate this charge.
                            local conflictLater, conflictNameLater = isChargeConflicting(value)
                            if conflictLater then
                                -- A conflicting active charge is found; do not allow activation.
                                isActive[0] = false
                                print("Cannot select " .. value.name .. " because it conflicts with active charge: " .. conflictNameLater)
                            elseif charges.count < 6 then
                                charges.count = charges.count + 1
                                if value.fine then
                                    charges.fine = charges.fine + value.fine
                                end
                                if value.time then
                                    charges.time = charges.time + value.time
                                end
                                value.active = true
                            else
                                isActive[0] = false
                            end
                        else
                            -- User is deactivating this charge.
                            charges.count = charges.count - 1
                            if value.fine then
                                charges.fine = charges.fine - value.fine
                            end
                            if value.time then
                                charges.time = charges.time - value.time
                            end
                            value.active = false
                        end
                    end
                end

                if imgui.IsItemHovered() and value.description then
                    local conflictForTooltip, conflictNameForTooltip = isChargeConflicting(value)
                    local tooltipText = string.format("%s\n\n$%d - %d minutes", value.description, value.fine, value.time)
                    if conflictForTooltip then
                        tooltipText = tooltipText .. string.format("\n\n[Conflict with: %s]", conflictNameForTooltip)
                    end
                    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))
                    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 5)
                    imgui.SetTooltip(tooltipText)
                    imgui.PopStyleVar(2)
                end

                -- Advance to the next column.
                imgui.NextColumn()
            end
        else
            imgui.Text("No charges found.")
        end

        imgui.Columns(1)
    end
    imgui.EndChild()
    imgui.PopFont()
end

function renderLockerWindow(label, name)
    setupWindowDraggingAndSize(name)

    local pageId = menu[name].pageId
    local totalPrice = calculateTotalPrice(autobind[name]["Kit" .. pageId], lockers[name].Items)
    local kits = {}
    for i = 1, autobind[name].maxKits do
        kits[i] = {key = name .. i, menu = autobind[name]["Kit" .. i]}
    end

    if imgui.Begin(name, menu[name].window, menu[name].flags) then
        customTitleBar(name, menu[name].title(label, pageId, totalPrice))

        imgui.PushFont(fontData.medium.font)
        imgui.SetCursorPosX(7)
        if imgui.BeginChild("##locker"..name, imgui.ImVec2(menu[name].size.x , menu[name].size.y - 35), false) then
            imgui.SetCursorPosY(4)

            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))
            for id, kit in pairs(kits) do
                if pageId == id then
                    keyEditor("Keybind", kit.key, nil, function(action, index)
                        
                    end)

                    -- Preview Kit
                    imgui.SameLine(imgui.GetWindowWidth() - 96)
                    imgui.BeginGroup()
                    imgui.PushItemWidth(82)
                    if imgui.BeginCombo("##" .. name .. "_preview", fa.ICON_FA_SHOPPING_CART .. " Kit " .. id) then
                        for i = 1, autobind[name].maxKits do
                            if imgui.Selectable(fa.ICON_FA_SHOPPING_CART .. " Kit " .. i .. (i == id and ' [x]' or ''), pageId == i) then
                                menu[name].pageId = i
                            end
                        end
                        imgui.EndCombo()
                    end
                    imgui.PopItemWidth()

                    -- Create new kit
                    if imgui.Button("Add New Kit", imgui.ImVec2(82, 20)) then
                        if autobind[name].maxKits < lockers.maxKits then
                            autobind[name].maxKits = autobind[name].maxKits + 1
                            autobind[name]["Kit" .. autobind[name].maxKits] = {1, 2, 10, 11}

                            menu[name].pageId = autobind[name].maxKits

                            autobind.Keybinds[name .. autobind[name].maxKits] = {Toggle = false, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}}
                        end
                    end
                    imgui.EndGroup()

                    local selectionTitle = string.format("Selection: [%d/%d]", #autobind[name]["Kit" .. pageId], lockers[name].maxSelections)

                    -- Create selection menu
                    createMenu(selectionTitle, lockers[name].Items, kit.menu, lockers[name].ExclusiveGroups, lockers[name].maxSelections, {combineGroups = lockers[name].combineGroups})
                end
            end
            imgui.PopStyleVar()
        end
        imgui.EndChild()
        imgui.PopFont()
    end
    imgui.End()
end

function renderChangelogWindow(label)
    setupWindowDraggingAndSize(label)

    if imgui.Begin(label, menu[label].window, menu[label].flags) then
        customTitleBar(label, menu[label].title())

        imgui.SetCursorPos(imgui.ImVec2(0, 35))
        imgui.BeginChild("##changelog", imgui.ImVec2(menu[label].size.x, menu[label].size.y - 35), false)
        if changelog then
            -- Build an array of version keys from the changelog table.
            local sortedVersions = {}
            for version, _ in pairs(changelog) do
                table.insert(sortedVersions, version)
            end
        
            -- Sort the versions in descending order.
            table.sort(sortedVersions, function(a, b)
                return compareVersions(a, b) > 0
            end)
        
            -- Iterate over the sorted versions and display them.
            imgui.SetCursorPos(imgui.ImVec2(15, 0))
            imgui.BeginGroup()
            imgui.PushFont(fontData.medium.font)
            for index, version in ipairs(sortedVersions) do
                local changes = #changelog[version]
                imgui_funcs.TextColoredRGB(string.format("Version: {%06x}%s {%06x}- Changes: %d", clr_BLUE, version, clr_GREY, changes))
                
                local padding = 10
                local found = {}
                for i, change in ipairs(changelog[version]) do
                    local textSize = imgui_funcs.calcTextSize(change)
                    if textSize.x > menu[label].size.x - 55 then
                        changes = changes + 1
                        found[index] = true
                    end
                end

                if found[index] and changes < 5 then
                    padding = 5
                end

                -- Add some padding to the calculated size
                local childSize = imgui.ImVec2(menu[label].size.x - 45, changes * 15 + padding)
                
                -- Push padding style
                imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
                if imgui.BeginChild(string.format("##changelog_content_%s_%d", version, index), childSize, true, imgui.WindowFlags.AlwaysAutoResize) then
                    --imgui.PushTextWrapPos(menu[label].size.x - 45)  -- Set wrap position
                    for i, change in ipairs(changelog[version]) do
                        local textColor = (i % 2 == 1) and imguiRGBA["WHITE"] or imguiRGBA["GREY"]
                        imgui.PushStyleColor(imgui.Col.Text, textColor)
                        imgui.TextWrapped(change)
                        imgui.PopStyleColor()
                    end
                   -- imgui.PopTextWrapPos()  -- Reset wrap position
                end
                imgui.EndChild()
                imgui.PopStyleVar()  -- Pop padding style
                imgui.NewLine()
            end
            imgui.PopFont()
            imgui.EndGroup()
        else
            imgui_funcs.TextColoredRGB(string.format("Changelog failed to fetch. {%06x}%s", clr_RED, Urls.changelog))
        end
        imgui.EndChild()
    end
    imgui.End()
end

function customTitleBar(key, title)
    -- Custom title bar
    imgui.SetCursorPos(imgui.ImVec2(0, 0))
    imgui.PushStyleColor(imgui.Col.ChildBg, imguiRGBA["ARES"])
    imgui.BeginChild("##titlebar", imgui.ImVec2(menu[key].size.x, 30), false)
    
    -- Title text
    imgui.PushFont(fontData.medium.font)
    imgui.SetCursorPos(imgui.ImVec2(10, 9))
    imgui_funcs.TextColoredRGB(title)
    imgui.PopFont()

    -- Close button
    imgui.SetCursorPos(imgui.ImVec2(menu[key].size.x - 30, 0))
    local closeButton = string.format("%s", fa.ICON_FA_WINDOW_CLOSE)
    if imgui_funcs.CustomButton(closeButton, imguiRGBA["ARES"], imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], imgui.ImVec2(30, 30)) then
        menu[key].window[0] = false
    end
    imgui.PushFont(fontData.small.font)
    imgui_funcs.CustomTooltip("Close")
    imgui.PopFont()

    imgui.EndChild()
    imgui.PopStyleColor(1)
end

function setupWindowDraggingAndSize(label)
    local Pivot = menu[label].pivot and menu[label].pivot or autobind[label].Pivot
    local newPos, isDragging = imgui_funcs.handleWindowDragging(label, autobind.WindowPos[label], menu[label].size, Pivot, menu[label].dragging[0])
    if isDragging then
        autobind.WindowPos[label] = newPos
        imgui.SetNextWindowPos(autobind.WindowPos[label], imgui.Cond.Always, Pivot)
    else
        imgui.SetNextWindowPos(autobind.WindowPos[label], imgui.Cond.Always, Pivot)
    end

    imgui.SetNextWindowSize(menu[label].size, imgui.Cond.Always)
end

function drawSkinImages(skins, columns, imageSize, spacing, startPos)
    local index = 0
    for skinId, _ in pairs(skins) do
        local column = index % columns
        local row = math.floor(index / columns)
        local posX = startPos.x + column * (imageSize.x + spacing)
        local posY = startPos.y + row * (imageSize.y + spacing / 4)

        imgui.SetCursorPos(imgui.ImVec2(posX, posY))
        if skinTextures[skinId] then
            imgui.Image(skinTextures[skinId], imageSize)
        else
            imgui.Button("No\nImage", imageSize)
            local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, skinId)
            if doesFileExist(skinPath) then
                skinTextures[skinId] = imgui.CreateTextureFromFile(skinPath)
            end
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Skin " .. skinId)
        end

        index = index + 1
    end
    return index
end

function createFontMenuElement(name, title, element, disableColor)
    if element.enable == nil then
        return
    end

    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))

    imgui.Columns(7, title .. "_columns_row1", false)
    
    imgui.SetColumnWidth(0, 40)  -- Toggle checkbox
    imgui.SetColumnWidth(1, 78)  -- Alignment options
    imgui.SetColumnWidth(2, 78) -- Font flags options
    imgui.SetColumnWidth(3, 85) -- Font name input
    imgui.SetColumnWidth(4, 50)  -- Font size adjustment
    imgui.SetColumnWidth(5, 60) -- Text color picker
    imgui.SetColumnWidth(6, 60) -- Value color picker

    imgui.SetCursorPosX(imgui.GetCursorPosX() - 8)
    if imgui.Checkbox(string.format("%s##%s_toggle", element.enable and "On" or "Off", title), new.bool(element.enable)) then
        element.enable = not element.enable
    end
    imgui.NextColumn()

    imgui.PushItemWidth(68)
    local alignments = {"Left", "Center", "Right"}
    local currentAlignment = element.align == "left" and 1 or element.align == "center" and 2 or 3
    if imgui.BeginCombo("##align_" .. title, alignments[currentAlignment]) then
        for i = 1, #alignments do
            if imgui.Selectable(alignments[i], currentAlignment == i) then
                element.align = alignments[i]:lower()
            end
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()
    imgui.NextColumn()

    imgui.PushItemWidth(68)
    if imgui.BeginCombo("##flags_" .. title, "Flags") then
        local flagNames = {'BOLD', 'ITALICS', 'BORDER', 'SHADOW', 'UNDERLINE', 'STRIKEOUT'}
        for _, flagName in ipairs(flagNames) do
            imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 2))
            local flagValue = element.flags[flagName]
            if imgui.Checkbox(flagName:lower():upperFirst(), new.bool(flagValue)) then
                element.flags[flagName] = not flagValue
                createFont(name, element)
            end
            imgui.PopStyleVar()
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()
    imgui.NextColumn()

    imgui.PushItemWidth(80)
    local fontName = new.char[30](element.font)
    if imgui.InputText("##font_" .. title, fontName, sizeof(fontName), imgui.InputTextFlags.EnterReturnsTrue) then
        element.font = ffi.string(fontName)
        createFont(name, element)
    end
    imgui.PopItemWidth()
    imgui.NextColumn()

    imgui.PushItemWidth(40)
    if imgui.BeginCombo("##size_" .. title, tostring(element.size)) then
        local commonSizes = {}
        for i = 4, 72 do
            if not table.contains(commonSizes, i) then
                table.insert(commonSizes, i)
            end
        end
        table.sort(commonSizes)

        local customSize = new.int(element.size)
        imgui.PushItemWidth(imgui.GetWindowWidth() * 0.65)
        if imgui.InputInt("Size##custom_size_" .. title, customSize, 1) then
            if customSize[0] >= 4 and customSize[0] <= 72 then
                element.size = customSize[0]
                createFont(name, element)
            end
        end
        imgui.PopItemWidth()

        -- Add a separator
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 2)
        imgui.Separator()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)

        -- Show common sizes first
        for _, size in ipairs(commonSizes) do
            if imgui.Selectable(tostring(size), element.size == size) then
                element.size = size
                createFont(name, element)
            end
        end
        
        imgui.EndCombo()
    end
    imgui.PopItemWidth()
    imgui.NextColumn()

    if not disableColor then
        imgui.BeginGroup()
        imgui.PushItemWidth(95)
        local clrText = colors.convertColor(element.colors.text, true, false, false)
        local clrEdit1 = new.float[3](clrText.r, clrText.g, clrText.b)
        if imgui.ColorEdit3("##text_color_" .. title, clrEdit1, 
                            imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
            element.colors.text = colors.joinARGB(0, clrEdit1[0], clrEdit1[1], clrEdit1[2], true)
        end
        imgui.PopItemWidth()
        imgui.SameLine(25)
        imgui.Text("Text")
        imgui.EndGroup()
        imgui.NextColumn()

        imgui.BeginGroup()
        imgui.PushItemWidth(95)
        local clrValue = colors.convertColor(element.colors.value, true, false, false)
        local clrEdit2 = new.float[3](clrValue.r, clrValue.g, clrValue.b)
        if imgui.ColorEdit3("##value_color_" .. title, clrEdit2, 
                            imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
            element.colors.value = colors.joinARGB(0, clrEdit2[0], clrEdit2[1], clrEdit2[2], true)
        end
        imgui.PopItemWidth()
        imgui.SameLine(25)
        imgui.Text("Value")
        imgui.EndGroup()

        imgui.Columns(1)
    end
    imgui.PopStyleVar()
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

function createRow(label, tooltip, setting, toggleFunction, sameLine)
    if imgui.Checkbox(label, new.bool(setting)) then
        toggleFunction()
    end
    imgui_funcs.CustomTooltip(tooltip)

    if sameLine then
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetWindowWidth() / 2.0)
    end
end

function createCheckbox(label, index, tbl, exclusiveGroups, maxSelections)
    local isChecked = table.contains(tbl, index)
    if imgui.Checkbox(label, new.bool(isChecked)) then
        if isChecked then
            -- Uncheck the item
            for i, v in ipairs(tbl) do
                if v == index then
                    table.remove(tbl, i)
                    break
                end
            end
        else
            -- Check the item
            if #tbl < maxSelections then
                -- Remove items from the same exclusive group
                if exclusiveGroups then
                    for _, group in pairs(exclusiveGroups) do
                        if table.contains(group, index) then
                            for i = #tbl, 1, -1 do
                                if table.contains(group, tbl[i]) and tbl[i] ~= index then
                                    table.remove(tbl, i)
                                end
                            end
                            break
                        end
                    end
                end
                table.insert(tbl, index)
            else
                -- Exceeded max selections
                formattedAddChatMessage("Maximum selection limit reached.", clr_RED)
            end
        end
    end
end

function createMenu(title, items, tbl, exclusiveGroups, maxSelections, options)
    options = options or {}
    local combineGroups = options.combineGroups or {}

    imgui.Text(title)
    local handledIndices = {}
    
    -- Handle combined groups (e.g., for grouping items visually)
    for _, group in ipairs(combineGroups) do
        for i, index in ipairs(group) do
            local item = items[index]
            if item then
                createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
                imgui_funcs.CustomTooltip(string.format("Price: %s", item.price and "$" .. formatNumber(item.price) or "Free"))
                if i < #group then
                    imgui.SameLine()
                end
                table.insert(handledIndices, index)
            end
        end
    end

    -- Handle the rest of the items
    for index, item in ipairs(items) do
        if not table.contains(handledIndices, index) then
            createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
            imgui_funcs.CustomTooltip(string.format("Price: %s", item.price and "$" .. formatNumber(item.price) or "Free"))
        end
    end
end

local function showKeyTypeTooltip(keyType)
    local tooltips = {
        KeyDown = "Triggers when the key is held down. (Repeats until the key is released)",
        KeyPressed = "Triggers when the key is just pressed down. (Does not repeat until the key is released and pressed again)."
    }
    imgui_funcs.CustomTooltip(tooltips[keyType] or "Unknown key type.")
end

function keyEditor(title, index, description, callback)
    local keyBinds = autobind.Keybinds[index]

    -- Check if the Keybinds table exists, if not, copy the default settings
    if not keyBinds then
        autobind.Keybinds[index] = autobind_defaultSettings.Keybinds[index]
        return
    end

    -- Check if the Keys table exists, if not create it
    if not keyBinds.Keys then
        autobind.Keybinds[index].Keys = {}
    end

    -- Check if the Type table exists, if not create it
    if not keyBinds.Type then
        autobind.Keybinds[index].Type = {}
    end

    -- Adjustable parameters
    local padding = imgui.ImVec2(8, 6)  -- Padding around buttons
    local comboWidth = 50  -- Width of the combo box
    local verticalSpacing = 2  -- Vertical spacing after the last key entry

    --imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 4))

    -- Begin Group
    imgui.BeginGroup()

    local checkBoxColor = keyBinds.Toggle and clr_REALGREEN or clr_RED
    local checkBoxText = keyBinds.Toggle and "On" or "Off"
    if imgui.Checkbox(checkBoxText .. "##" .. index, new.bool(keyBinds.Toggle)) then
        keyBinds.Toggle = not keyBinds.Toggle
        if callback then
            callback("toggle", index)
        end
    end
    imgui_funcs.CustomTooltip(string.format("Toggle this key binding. {%06x}(%s)", checkBoxColor, checkBoxText))

    imgui.SameLine(42)

    -- Title and description
    imgui.AlignTextToFramePadding()
    imgui.Text(string.format("[%s]", title))
    if description then
        imgui_funcs.CustomTooltip(description)
    end

    -- Display existing key bindings and empty slots for new ones (up to 3 total)
    for i = 1, 3 do
        local isExistingKey = i <= #keyBinds.Keys
        
        if isExistingKey then
            local key = keyBinds.Keys[i]
            local buttonText = changeKey[index] and changeKey[index] == i and fa.ICON_FA_KEYBOARD or (key ~= 0 and correctKeyName(vk.id_to_name(key)) or fa.ICON_FA_KEYBOARD)
            local buttonSize = imgui_funcs.calcTextSize(buttonText) + padding

            -- Button to change key
            imgui.AlignTextToFramePadding()
            if imgui.Button(buttonText .. '##' .. index .. i, buttonSize) then
                changeKey[index] = i
                lua_thread.create(function()
                    while changeKey[index] == i do 
                        wait(0)
                        local keydown, result = getDownKeys()
                        if result then
                            keyBinds.Keys[i] = keydown
                            changeKey[index] = false
                        end
                    end
                end)
            end
            imgui_funcs.CustomTooltip(("Press to change, Key: %d"):format(i))

            -- Combo box for key type selection
            imgui.SameLine()
            local keyTypes = {"KeyDown", "KeyPressed"}
            
            local currentType = keyBinds.Type
            if type(currentType) == "table" then
                currentType = currentType[i] or "KeyDown"
            elseif type(currentType) ~= "string" then
                currentType = "KeyDown"
            end
            
            imgui.PushItemWidth(comboWidth)
            if imgui.BeginCombo("##KeyType"..index..i, currentType:gsub("KeyPressed", "Tap"):gsub("KeyDown", "Hold")) then
                for _, keyType in ipairs(keyTypes) do
                    if imgui.Selectable(keyType:gsub("KeyPressed", "Tap"):gsub("KeyDown", "Hold"), currentType == keyType) then
                        if type(keyBinds.Type) ~= "table" then
                            keyBinds.Type = {keyBinds.Type or "KeyDown"}
                        end
                        keyBinds.Type[i] = keyType
                    end
                    showKeyTypeTooltip(keyType)
                end
                imgui.EndCombo()
            end
            imgui.PopItemWidth()
            showKeyTypeTooltip(currentType)

            -- Remove button
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local minusButtonSize = {x = 14, y = 18.5}
            if imgui.Button("-##remove" .. index .. i, minusButtonSize) then
                table.remove(keyBinds.Keys, i)
                if type(keyBinds.Type) == "table" then
                    table.remove(keyBinds.Type, i)
                end

                if callback then
                    callback("remove", index)
                end
            end
            imgui_funcs.CustomTooltip("Remove this key binding.")
        else
            -- Empty slot with "+" button for adding a new key
            imgui.AlignTextToFramePadding()
            local addButtonText = string.format("Add Key #%d", i)
            local addButtonSize = imgui_funcs.calcTextSize(addButtonText) + padding + imgui.ImVec2(35, 0)
            
            if imgui.Button(addButtonText .. "##add" .. index .. i, addButtonSize) then
                table.insert(keyBinds.Keys, 0)
                if type(keyBinds.Type) ~= "table" then
                    keyBinds.Type = {keyBinds.Type or "KeyDown"}
                end
                table.insert(keyBinds.Type, "KeyDown")
                
                if callback then
                    callback("add", index)
                end
            end
            imgui_funcs.CustomTooltip("Add a new key binding.")
            
            -- Add placeholder for combo box width to maintain alignment
            imgui.SameLine()
            imgui.Dummy(imgui.ImVec2(comboWidth + imgui.GetStyle().ItemSpacing.x, 0))
            
            -- Add placeholder for remove button width to maintain alignment
            imgui.SameLine()
            imgui.Dummy(imgui.ImVec2(14 + imgui.GetStyle().ItemSpacing.x, 0))
        end
    end

    -- Add vertical spacing after the last key entry
    imgui.Dummy(imgui.ImVec2(0, verticalSpacing))

    imgui.EndGroup()

    --imgui.PopStyleVar()
end

function updateCheck()
    fetchJsonDataDirectlyFromURL(Urls.update(autobind.Settings.fetchBeta), function(content)
        if content and content.version and content.lastversion then
            local compareNew = compareVersions(content.version, scriptVersion)
            local compareOld = compareVersions(content.lastversion, scriptVersion)
            if compareNew == 0 or compareNew == -1 then
                updateStatus = "up_to_date"
            elseif compareNew == 1 and compareOld ~= 1 then
                updateStatus = "new_version"
            elseif compareNew == 1 and compareOld == 1 and autobind.Settings.fetchBeta then
                updateStatus = "beta_version"
            elseif compareOld == 1 then
                updateStatus = "outdated"
            end
            currentContent = content
        else
            updateStatus = "failed"
            currentContent = nil
        end
    end)
end

function updateScript()
    autobind.Settings.updateInProgress = true
    autobind.Settings.lastVersion = scriptVersion

    downloadFilesFromURL({{url = Urls.script(autobind.Settings.fetchBeta), path = Files.script, replace = true}}, false, function(success)
        if success then
            lua_thread.create(function()
                formattedAddChatMessage("Update downloaded successfully! Validating correct version before you can reload.")

                wait(1000)

                local remove, error = pcall(os.remove, scriptPath)
                if not remove then
                    print("Error removing file: " .. error)
                    return
                end

                local move, error = os.rename(Files.script, scriptPath)
                if not move then
                    print("Error moving file: " .. error)
                    return
                end

                wait(1000)

                local file = io.open(scriptPath, "r")
                if file then
                    local content = file:read("*a")
                    file:close()

                    if autoReboot then
                        script.load(workingDir .. "\\AutoReboot.lua")
                    end

                    if content:find(currentContent.version) then
                        formattedAddChatMessage(string.format("Update has been validated! Please type '/%s reload' to finish the update.", shortName))
                    else
                        formattedAddChatMessage("Update was not validated! Please try again later.")
                    end
                end
            end)
        else
            formattedAddChatMessage("Update download failed! Please try again later.")
            autobind.Settings.updateInProgress = false
        end
    end)
end

function generateSkinsUrls()
    local files = {}
    for i = 0, 311 do
        table.insert(files, {
            url = string.format("%sSkin_%d.png", Urls.skinsPath, i),
            path = string.format("%sSkin_%d.png", Paths.skins, i),
            replace = false,
            index = i
        })
    end

    -- Sort the files by index
    table.sort(files, function(a, b) return tonumber(a.index) < tonumber(b.index) end)

    return files
end

function downloadSkins(urls)
    downloadFilesFromURL(urls, true, function(downloadsFinished)
        if downloadsFinished then
            formattedAddChatMessage("All skins files were downloaded successfully!")
            autobind.Settings.notifySkins = false
        else
            if not autobind.Settings.notifySkins then
                formattedAddChatMessage("No skins files were needed to be downloaded.")
                autobind.Settings.notifySkins = true
            end
        end
    end)
end

function toggleAutoCapture()
	if not checkAdminDuty() then
		autoCapture = not autoCapture

		formattedAddChatMessage(autoCapture and  ("Starting capture attempt... {%06x}(type /%s to toggle)"):format(clr_YELLOW, clientCommands.autocap.cmd) or "Auto Capture ended.")
	end
end

function toggleBind(name, bool)
    bool = not bool
    local color = bool and clr_REALGREEN or clr_RED
    formattedAddChatMessage(("%s: {%06x}%s"):format(name, color, bool and 'on' or 'off'))
    return bool
end

function createFarmerDialog()
    local dialogText = "You have arrived at your designated farming spot.\nAuto-Typing /harvest to harvest some crops.\n\nWarning: Pressing disable will turn off auto farming."
    sampShowDialog(dialogs.farmer.id, ("[%s] Auto Farming"):format(shortName:upper()), dialogText, "Close", "Disable", 0)
end

function formatWantedString(entry, allowPing, allowStars, fakePing)
    fakePing = fakePing or false
    if entry.charges > 0 then
        local pingInfo = (allowPing and autobind.Wanted.Ping) and string.format(" (Ping: %d):", fakePing and 55 or sampGetPlayerPing(entry.id)) or ""
        local chargeColor = entry.charges == 6 and autobind.Wanted.MostWantedColor or clr_LIGHTGREY
        local chargeInfo = (allowStars and autobind.Wanted.Stars) and string.rep(fa.ICON_FA_STAR, entry.charges) or string.format("%d outstanding %s.", entry.charges, entry.charges == 1 and "charge" or "charges")
    
        return string.format("%s (%d):%s {%06x}%s", 
            entry.name, 
            entry.id, 
            pingInfo,
            chargeColor, 
            chargeInfo
        )
    else
        local currentTime = os.clock()
        local timeRemaining = (entry.timestamp + getEntryExpiryTime(entry)) - currentTime

        local entryId = not entry.disconnected and string.format(" (%d)", entry.id or -1) or ""
        return string.format("%s%s - %s (%ds)", entry.name, entryId, getEntryRemovalTitle(entry), timeRemaining)
    end
end

function getEntryRemovalTitle(entry)
    for _, name in ipairs(wanted.wantedTypes) do
        if entry[name] then
            return name:upper()
        end
    end
    return "Unknown"
end

function getEntryExpiryTime(entry)
    for name, expiry in pairs(autobind.Wanted.Expiry) do
        if entry[name] then
            return expiry
        end
    end
    return 0.1
end

function correctKeyName(keyName)
	return keyName:gsub("Left ", ""):gsub("Right ", ""):gsub("Context ", ""):gsub("Numpad", "Num")
end

function clearWantedList()
    if autobind.Wanted.List and #autobind.Wanted.List > 0 then
        autobind.Wanted.List = {}
    end
end

function updateWantedList(updateId, updateType, playerName, playerId, playerCharges)
    local currentTime = os.clock()
    local found = false
    for entryId, entry in ipairs(autobind.Wanted.List) do
        if entry.name == playerName then
            entry.id = playerId
            if updateType == "add" then
                if entry.charges < 6 then
                    entry.charges = entry.charges + 1
                end
            elseif updateType == "set" then
                if entry.charges ~= playerCharges then
                    entry.charges = playerCharges
                end
            end
            entry.timestamp = currentTime
            entry.active = true
            entry.lawyer = false
            entry.disconnected = false
            entry.processed = false
            entry.cleared = false
            entry.markedDeactivated = false
            entry.updated = true
            found = true
            --debugMessage(string.format("updateWantedList: ID: %s, Type: %s, Name: %s, ID: %s, Charges: %s, Found: %s", updateId, updateType, playerName, playerId, playerCharges, found), false, true)
            break
        end
    end
    if not found then
        table.insert(autobind.Wanted.List, {
            name = playerName,
            id = playerId,
            charges = playerCharges,
            timestamp = currentTime,
            active = true,
            lawyer = false,
            disconnected = false,
            processed = false,
            cleared = false,
            markedDeactivated = false,
            updated = true
        })

        table.sort(autobind.Wanted.List, function(a, b)
            return a.id > b.id
        end)

        debugMessage(string.format("updateWantedList: ID: %s, Type: %s, Name: %s, ID: %s, Charges: %s, Found: %s", updateId, updateType, playerName, playerId, playerCharges, found), false, true)
    end
end

function checkWantedList(updateType, playerName, playerId)
    local currentTime = os.clock()
    for entryId, entry in ipairs(autobind.Wanted.List) do
        if not sampIsPlayerConnected(entry.id) and updateType ~= "disconnected" then
            debugMessage(string.format("checkWantedList: %s (%d) is not connected, changing update type to disconnected (%s)", entry.name, entry.id, updateType), false, true)
            updateType = "disconnected"
        end

        if updateType == "cleared" or updateType == "processed" then
            if entry.name == playerName then
                entry.active = false
                entry.lawyer = false
                entry.disconnected = false
                if updateType == "processed" then
                    entry.processed = true
                    entry.cleared = false
                elseif updateType == "cleared" then
                    entry.processed = false
                    entry.cleared = true
                end
                entry.charges = 0
                entry.timestamp = currentTime
                entry.markedDeactivated = true
                entry.updated = false
                debugMessage(string.format("checkWantedList: Type: %s, Name: %s", updateType, playerName), false, true)
                break
            end
        elseif updateType == "disconnected" then
            if entry.id == playerId then
                if entry.active and not entry.markedDeactivated then
                    entry.active = false
                    entry.lawyer = false
                    entry.disconnected = true
                    entry.processed = false
                    entry.cleared = false
                    entry.charges = 0
                    entry.timestamp = currentTime
                    entry.markedDeactivated = true
                    entry.updated = false
                    debugMessage(string.format("checkWantedList: Type: %s, ID: %s", updateType, playerId), false, true)
                    break
                end
            end
        elseif updateType == "update" then
            if not entry.updated then
                if entry.active and not entry.markedDeactivated then
                    entry.active = false
                    if not entry.processed and not entry.cleared and not entry.disconnected then
                        entry.lawyer = true
                    end
                    entry.charges = 0
                    entry.timestamp = currentTime
                    entry.markedDeactivated = true
                elseif entry.active and entry.markedDeactivated then
                    entry.active = false
                end
            end

            if entry.active then
                entry.updated = false
            end

            --debugMessage(string.format("checkWantedList: Type: %s", updateType), false, true)
        end
    end
end

function getCurrentPlayingPlayer()
    local playerName = autobind.CurrentPlayer.name
    if not playerName or playerName == "" then
        local _, playerId = sampGetPlayerIdByCharHandle(ped)
        if not playerId then
            return nil
        end
        playerName = sampGetPlayerNickname(playerId)
    end

    return playerName
end

local function fetchVehicleStorage()
    formattedAddChatMessage("Your vehicle storage has been reset, populating vehicles...")
    vehicles.initialFetch = false
    vehicles.populating = true
    sampSendChat("/vst")
end

function initializeVehicleStorage()
    local playerName = getCurrentPlayingPlayer()
    if not playerName then
        formattedAddChatMessage("Current playing player not found!")
        return
    end

    autobind.VehicleStorage.Vehicles = autobind.VehicleStorage.Vehicles or {}
    autobind.VehicleStorage.Vehicles[playerName] = autobind.VehicleStorage.Vehicles[playerName] or {}

    if autobind.VehicleStorage.Vehicles[playerName] and #autobind.VehicleStorage.Vehicles[playerName] < 1 then
        fetchVehicleStorage()
    end

    if not autobind.CurrentPlayer.welcomeMessage then
        for _, vehicle in pairs(autobind.VehicleStorage.Vehicles[playerName]) do
            if vehicle.status and vehicle.status ~= "Stored" and vehicle.status ~= "Disabled" and vehicle.status ~= "Impounded" then
                vehicle.status = "Stored"
            end
        end
    end
end

function resetVehicleStorage()
    local playerName = getCurrentPlayingPlayer()
    if not playerName then
        formattedAddChatMessage("Current playing player not found!")
        return
    end

    autobind.VehicleStorage.Vehicles[playerName] = {}
    fetchVehicleStorage()
end

function updateVehicleStorage(status, vehName)
    local playerName = autobind.CurrentPlayer.name
    if vehicles.currentIndex ~= -1 then
        if playerName and playerName ~= "" then
            local currentIndex = vehicles.currentIndex + 1
            autobind.VehicleStorage.Vehicles[playerName] = autobind.VehicleStorage.Vehicles[playerName] or {}

            if autobind.VehicleStorage.Vehicles[playerName][currentIndex] ~= nil then
                autobind.VehicleStorage.Vehicles[playerName][currentIndex].status = status
            else
                print("Vehicle not found", playerName, currentIndex, status)
            end
        else
            print("Current player not found")
        end
    else
        if vehName then
            print("Vehicles.currentIndex not found", vehName)
        else
            print("Vehicles.currentIndex not found")
        end
    end
end

-- Search for vehicles that contain "partialName" (case-insensitive) in their 'vehicle' field.
function findVehiclesByName(vehList, partialName)
    local results = {}
    partialName = partialName:lower()
    for _, vehData in ipairs(vehList) do
        if vehData.vehicle and vehData.vehicle:lower():find(partialName, 1, true) then
            table.insert(results, vehData)
        end
    end
    return results
end

function getKeybindKeys(bind)
    local keybind = autobind.Keybinds[bind]
    if not keybind then
        return ""
    end

    if #keybind.Keys == 0 then
        return ""
    end

    local keys = {}
    for _, key in ipairs(keybind.Keys) do
        local keyName = vk.id_to_name(key)
        if keyName then
            table.insert(keys, keyName)
        else
            -- Handle the case where id_to_name might fail
            table.insert(keys, "Unknown Key")
        end
    end
    return table.concat(keys, " + ")
end

function getVisiblePlayers(maxDist, type)
    local visiblePlayers = {}
    local myX, myY, myZ = getCharCoordinates(ped)

    for _, peds in pairs(getAllChars()) do
        -- Skip the local player
        if peds == ped then
            goto continue
        end

        -- Get player coordinates and distance
        local playerX, playerY, playerZ = getCharCoordinates(peds)
        local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, myX, myY, myZ)

        -- Check if the player is too far away
        if distance >= maxDist then
            goto continue
        end

        -- Convert handle to playerid and check if the player is paused
        local result, playerId = sampGetPlayerIdByCharHandle(peds)
        if not result or sampIsPlayerPaused(playerId) then
            goto continue
        end

        -- Find _ to prevent admins from being detected
        local playerName = sampGetPlayerNickname(playerId)
        if not playerName:find("_") then
            goto continue
        end
        
        -- Type checks
        if (type == "armor" and sampGetPlayerArmor(playerId) >= 49) or -- armor check
           (type == "car" and (isCharInAnyCar(ped) or not isCharInAnyCar(peds))) or -- car check
           (type ~= "all" and type ~= "armor" and type ~= "car") then -- all check
            goto continue
        end

        -- Insert player info
        local playerInfo = {
            playerId = playerId,
            playerName = playerName,
            playerColor = sampGetPlayerColor(playerId),
            skinId = getCharModel(peds),
            distance = distance,
        }
        table.insert(visiblePlayers, playerInfo)

        ::continue::
    end

    -- Sort players by distance and return
    table.sort(visiblePlayers, function(a, b) return a.distance < b.distance end)
    return visiblePlayers
end

function handleCapture(mode)
    local currentTime = os.clock()
    if currentTime - timers.Capture.sentTime <= timers.Capture.timeOut then
        return
    end

    if checkMuted() or checkAdminDuty() then
        return
    end

    if autobind[mode].point and mode ~= "Faction" then
        sampSendChat("/capture")
        timers.Capture.sentTime = currentTime
        if autobind[mode].disableAfterCapturing and mode == "Family" then
            autobind[mode].point = false
        end
        return
    end

    if autobind[mode].turf then
        sampSendChat("/capturf")
        timers.Capture.sentTime = currentTime
        if autobind[mode].disableAfterCapturing and mode == "Family" then
            autobind[mode].turf = false
        end
        return
    end
end

-- Check if admin duty is active
function checkAdminDuty()
    local _, aduty = getSampfuncsGlobalVar("aduty")
    return aduty == 1
end

-- Check if the muted timer has been triggered
function checkMuted()
	if os.clock() - timers.Muted.last < timers.Muted.timer then
		return true
	end
	return false
end

-- Check if you if the heal timer has expired or not
function checkHeal()
	if os.clock() - timers.Heal.last < timers.Heal.timer then
		return true
	end
	return false
end

function setTimer(additionalTime, timer)
	timer.last = os.clock() - (timer.timer - 0.2) + (additionalTime or 0)
end

function formattedAddChatMessage(message, color)
    color = color or clr_WHITE
    sampAddChatMessage(("[%s] {%06x}%s"):format(shortName:upper(), color, message), clr_ARES)
end

function removeHexBrackets(text)
    return text:gsub("{%x+}", "")
end

function string:upperFirst()
    return (self:gsub("^%l", string.upper))
end

function string:trim()
    return self:match("^%s*(.-)%s*$")
end

function activeCheck(chat, dialog, scoreboard, console, pause)
	return (not chat or not sampIsChatInputActive()) and 
	       (not dialog or not sampIsDialogActive()) and 
	       (not scoreboard or not sampIsScoreboardOpen()) and 
	       (not console or not isSampfuncsConsoleActive()) and 
	       (not pause or not isPauseMenuActive())
end

function toggleRadio(bool)
	mem.write(0x4EB9A0, bool and 0x8BE98B55 or 0x8B0004C2, 4, false)
end

function table.listToSet(list)
    local set = {}
    for _, value in pairs(list) do
        set[value] = true
    end
    return set
end

function table.setToList(set)
    local list = {}
    for key, value in pairs(set) do
        if value then
            table.insert(list, key)
        end
    end
    return list
end

function table.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function findPlayer(target, includeLocalPlayer)
    if not target then return false end

    local result, playerId = sampGetPlayerIdByCharHandle(ped)
    if not result then
        return false
    end

    local targetId = tonumber(target)
    if targetId and (sampIsPlayerConnected(targetId) or (includeLocalPlayer and playerId == targetId)) then
        return true, targetId, sampGetPlayerNickname(targetId)
    end

    -- Escape special characters in the target string
    local escapedTarget = target:gsub("([^%w])", "%%%1")

    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) or (includeLocalPlayer and playerId == i) then
            local name = sampGetPlayerNickname(i)
            if name:lower():find("^" .. escapedTarget:lower()) then
                return true, i, name
            end
        end
    end

    return false
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
    return -1
end

function setTime(hour, minute)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, hour)
    raknetBitStreamWriteInt8(bs, minute)
    raknetEmulRpcReceiveBitStream(29, bs)
    raknetDeleteBitStream(bs)
end

function setWeather(weatherId)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, weatherId)
    raknetEmulRpcReceiveBitStream(152, bs)
    raknetDeleteBitStream(bs)
end

function convertSpeed(speed, isMPHOrKMH)
    return math.ceil(speed * (isMPHOrKMH and 2.98 or 4.80))
end

function downloadFilesFromURL(urls, progress, callback)
    local function onComplete(downloadsFinished)
        callback(downloadsFinished)
    end

    local function onProgress(progressData, file)
        -- Individual file progress
        if progressData.fileProgress ~= nil then
            print(string.format("Downloading '%s': %.2f%% complete", file.url, progressData.fileProgress))
        end

        -- Overall progress
        if progressData.overallProgress ~= nil then
            print(string.format("Overall Progress: %.2f%% complete", progressData.overallProgress))
        end
    end

    downloads:queueDownloads(urls, onComplete, progress and onProgress or nil)
end

function fetchJsonDataDirectlyFromURL(url, callback)
    local function onComplete(decodedData)
        if decodedData and next(decodedData) ~= nil then
            callback(decodedData)
        else
            print("JSON format is empty or invalid URL:", url)
        end
    end

    downloads:queueFetches({{url = url, callback = onComplete}})
end

function formatNumber(num)
    local isNegative = num < 0
    num = tostring(math.abs(num))

    local formatted = num:reverse():gsub("...","%0,",math.floor((#num-1)/3)):reverse()

    return isNegative and "-" .. formatted or formatted
end

function calculateTotalPrice(kit, items)
    local totalPrice = 0
    for _, index in ipairs(kit) do
        local item = items[index]
        if item and item.price then
            totalPrice = totalPrice + item.price
        end
    end
    return totalPrice
end

function convertDecimalToHours(decimalHours)
    local months = math.floor(decimalHours / 720)
    decimalHours = decimalHours % 720

    local days = math.floor(decimalHours / 24)
    decimalHours = decimalHours % 24

    local hours = math.floor(decimalHours)
    local minutes = math.floor((decimalHours - hours) * 60 + 0.5)

    local parts = {}

    if months > 0 then
        table.insert(parts, string.format("%d month%s", months, months ~= 1 and "s" or ""))
    end

    if days > 0 then
        table.insert(parts, string.format("%d day%s", days, days ~= 1 and "s" or ""))
    end

    if hours > 0 then
        table.insert(parts, string.format("%d hour%s", hours, hours ~= 1 and "s" or ""))
    end

    if minutes > 0 then
        if minutes == 30 then
            table.insert(parts, "a half")
        else
            table.insert(parts, string.format("%d minute%s", minutes, minutes ~= 1 and "s" or ""))
        end
    end

    if #parts == 0 then
        return "0 minutes"
    end

    if #parts == 1 then
        return parts[1]
    else
        local last = table.remove(parts)
        return table.concat(parts, ", ") .. " and " .. last
    end
end

function formatTimeSeconds(seconds)
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local timeString = ""
    if hours > 0 then
        timeString = timeString .. ("%d hr%s, "):format(hours, hours > 1 and "s" or "")
    end
    if minutes > 0 then
        timeString = timeString .. ("%d min%s, "):format(minutes, minutes > 1 and "s" or "")
    end
    timeString = timeString .. ("%.1f sec%s"):format(seconds, seconds ~= 1 and "s" or "")

    return timeString
end

function displayTimers()
    local currentTime = os.clock()
    for name, timer in pairs(timers) do
        local timerInfo = ""
        for fieldName, fieldValue in pairs(timer) do
            if fieldName == 'last' then
                if type(fieldValue) == "number" then
                    local elapsedTime = currentTime - fieldValue
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr_GREY, formatTimeSeconds(elapsedTime), clr_WHITE)
                elseif type(fieldValue) == "table" then
                    local subTimerInfo = ""
                    for bindName, bindTime in pairs(fieldValue) do
                        if type(bindTime) == 'number' then
                            local elapsedTime = currentTime - bindTime
                            subTimerInfo = subTimerInfo .. string.format("%s: {%06x}%s{%06x}, ", bindName, clr_GREY, formatTimeSeconds(elapsedTime), clr_WHITE)
                        end
                    end
                    if #subTimerInfo > 0 then
                        subTimerInfo = subTimerInfo:sub(1, -3)
                    end
                    timerInfo = timerInfo .. string.format("%s: {%s}, ", fieldName:upperFirst(), subTimerInfo)
                end
            elseif fieldName == 'sentTime' then
                if type(fieldValue) == "number" then
                    local elapsedTime = currentTime - fieldValue
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr_GREY, formatTimeSeconds(elapsedTime), clr_WHITE)
                end
            elseif fieldName == 'timer' then
                if type(fieldValue) == 'number' then
                    if type(timer.last) == 'number' then
                        local timeElapsed = currentTime - timer.last
                        local timeLeft = fieldValue - timeElapsed
                        timeLeft = math.max(timeLeft, 0)
                        timerInfo = timerInfo .. string.format("TimeLeft: {%06x}%s{%06x}, ", clr_GREY, formatTimeSeconds(timeLeft), clr_WHITE)
                    else
                        timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr_GREY, formatTimeSeconds(fieldValue), clr_WHITE)
                    end
                end
            else
                if type(fieldValue) == 'number' then
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr_GREY, formatTimeSeconds(fieldValue), clr_WHITE)
                end
            end
        end
        if #timerInfo > 0 then
            timerInfo = timerInfo:sub(1, -3)
        end
        formattedAddChatMessage(string.format("%s: %s.", name, timerInfo))
    end
end

function compareVersions(version1, version2)
    local letterWeights = {
        A = 1, B = 2, C = 3, D = 4, E = 5,
        a = 1, b = 2, c = 3, d = 4, e = 5,
        alpha = 1, beta = 2, rc = 3, p = 4, h = 5
    }

    local function parseVersion(version)
        local parts = {}
        for numPart, letterPart in version:gmatch("(%d+)(%a*)") do
            table.insert(parts, {num = tonumber(numPart), letter = letterPart:lower()})
        end
        return parts
    end

    local function getLetterWeight(letter)
        return letterWeights[letter] or 0
    end

    local v1 = parseVersion(version1)
    local v2 = parseVersion(version2)

    local maxLength = math.max(#v1, #v2)
    for i = 1, maxLength do
        local part1 = v1[i] or {num = 0, letter = ""}
        local part2 = v2[i] or {num = 0, letter = ""}
        
        if part1.num ~= part2.num then
            return (part1.num > part2.num) and 1 or -1
        end
        
        local weight1 = getLetterWeight(part1.letter)
        local weight2 = getLetterWeight(part2.letter)
        if weight1 ~= weight2 then
            return (weight1 > weight2) and 1 or -1
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

local PressType = {KeyDown = isKeyDown, KeyPressed = wasKeyPressed}
function keycheck(bind)
    local r = true

    if not bind.type then
        return false
    end

    if not bind.keys then
        return false
    end
    
    for i = 1, #bind.keys do
        r = r and PressType[bind.type[i]](bind.keys[i])
    end
    return r
end

function GameModeRestart()
    local bs = raknetNewBitStream()
    raknetEmulRpcReceiveBitStream(40, bs)
    raknetDeleteBitStream(bs)
end

function autoConnect()
    GameModeRestart()
    sampSetGamestate(1)
end

end) -- End of checkAndDownloadDependencies

if scriptError then
    print("scriptError:")
    print(scriptError)
end

print(("%s %s %s."):format(scriptName, scriptVersion, mainScript and "loaded successfully" or "failed to load"))
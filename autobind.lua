script_name("autobind")
script_description("Autobind Menu")
script_version("1.8.19a")
script_authors("akacross")
script_url("https://akacross.net/")

local betaTesters = { -- WIP
    {nickName = "Kenny", bugFinds = 14, hoursWasted = 3.0, discord = "ubergnomeage"},
    {nickName = "Wolly", bugFinds = 9, hoursWasted = 1.0, discord = "xwollyx"},
    {nickName = "Allen", bugFinds = 5, hoursWasted = 0.7, discord = "allen_7"},
    {nickName = "Moorice", bugFinds = 2, hoursWasted = 0.3, discord = "moorice"},
    {nickName = "Dwayne", bugFinds = -1, hoursWasted = 0.8, discord = "dickshaft"}
}

local changelog = {
    ["1.8.18"] = {
        "Improved: Rewrote autofind to make it more efficient and reliable, it is now apart of the main functions loop.",
        "Improved: ARES radio chat colored ARES badge, player-colored names, white message text, and player ID."
    },
    ["1.8.17"] = {
        "Fixed: There was an issue with accepters playerId because nil, now the nickname to ID function returns -1 if the player is not found."
    },
    ["1.8.16a"] = {
        "Fixed: Black Market and Faction Locker not showing keybinds."
    },
    ["1.8.15a"] = {
        "Release to The Commission Family"
    },
    ["1.8.15"] = {
        "Improved: Completely redesigned the menus interface to make it more user-friendly and visually appealing.",
        "New: Added a new menu for the Black Market and Faction Locker with kits. (Faction Locker is WIP)",
        "New: Built a custom download manager using Lua Lanes and requests for downloading files and updating the script.",
        "Added: The project now requires the following dependencies: lanes, requests (with sockets and SSL), and LFS.",
        "Lanes: Utilized for parallel processing, allowing the download manager to run concurrently with the main game thread.",
        "Requests (with Sockets and SSL): Essential for the custom-built download manager to handle secure HTTP/S operations.",
        "LuaFileSystem (LFS): Used for managing file system operations, it is only used for the download manager.",
        "Fixed: Resolved the issue causing the main looping functions to crash the mod, ensuring stability.",
        "Improved: The script now has a more efficient and streamlined structure, making it easier to maintain and update.",
        "Changed: Completely overhauled the script to improve performance, stability, and readability.",
        "Changed: There is no longer a need to check your VestMode, it is automatically fetched via MOTD, There is an option to allow everyone."
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
    {name = 'fAwesome5', var = 'fa'},
    {name = 'encoding', var = 'encoding'},
    {name = 'lanes', var = 'lanes', callback = function(module) return module.configure() end}
}

-- Load modules
local loadedModules, statusMessages = {}, {success = {}, failed = {}}
for _, dep in ipairs(dependencies) do
    local loadedModule, errorMsg = safeRequire(dep.name)
    if loadedModule and dep.callback then
        loadedModule = dep.callback(loadedModule) -- Call the callback function if needed
    end
    loadedModules[dep.var] = loadedModule
    table.insert(statusMessages[loadedModule and "success" or "failed"], loadedModule and dep.name or ("%s (%s)"):format(dep.name, errorMsg))
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

local clr = {
    GRAD1 = 'B4B5B7', -- #B4B5B7
    GRAD2 = 'BFC0C2', -- #BFC0C2
    GRAD3 = 'CBCCCE', -- #CBCCCE
    GRAD4 = 'D8D8D8', -- #D8D8D8
    GRAD5 = 'E3E3E3', -- #E3E3E3
    GRAD6 = 'F0F0F0', -- #F0F0F0
    GREY = 'AFAFAF', -- #AFAFAF
    RED = 'AA3333', -- #AA3333
    ORANGE = 'FF8000', -- #FF8000
    YELLOW = 'FFFF00', -- #FFFF00
    FORSTATS = 'FFFF91', -- #FFFF91
    HOUSEGREEN = '00E605', -- #00E605
    GREEN = '33AA33', -- #33AA33
    LIGHTGREEN = '9ACD32', -- #9ACD32
    CYAN = '40FFFF', -- #40FFFF
    PURPLE = 'C2A2DA', -- #C2A2DA
    BLACK = '000000', -- #000000
    WHITE = 'FFFFFF', -- #FFFFFF
    FADE1 = 'E6E6E6', -- #E6E6E6
    FADE2 = 'C8C8C8', -- #C8C8C8
    FADE3 = 'AAAAAA', -- #AAAAAA
    FADE4 = '8C8C8C', -- #8C8C8C
    FADE5 = '6E6E6E', -- #6E6E6E
    LIGHTRED = 'FF6347', -- #FF6347
    NEWS = 'FFA500', -- #FFA500
    TEAM_NEWS_COLOR = '049C71', -- #049C71
    TWPINK = 'E75480', -- #E75480
    TWRED = 'FF0000', -- #FF0000
    TWBROWN = '654321', -- #654321
    TWGRAY = '808080', -- #808080
    TWOLIVE = '808000', -- #808000
    TWPURPLE = '800080', -- #800080
    TWTAN = 'D2B48C', -- #D2B48C
    TWAQUA = '00FFFF', -- #00FFFF
    TWORANGE = 'FF8C00', -- #FF8C00
    TWAZURE = '007FFF', -- #007FFF
    TWGREEN = '008000', -- #008000
    TWBLUE = '0000FF', -- #0000FF
    LIGHTBLUE = '33CCFF', -- #33CCFF
    FIND_COLOR = 'B90000', -- #B90000
    TEAM_AZTECAS_COLOR = '01FCFF', -- #01FCFF
    TEAM_TAXI_COLOR = 'F2FF00', -- #F2FF00
    DEPTRADIO = 'FFD700', -- #FFD700
    RADIO = '8D8DFF', -- #8D8DFF
    TEAM_BLUE_COLOR = '2641FE', -- #2641FE
    TEAM_FBI_COLOR = '8D8DFF', -- #8D8DFF
    TEAM_MED_COLOR = 'FF8282', -- #FF8282
    TEAM_APRISON_COLOR = '9C7912', -- #9C7912
    NEWBIE = '7DAEFF', -- #7DAEFF
    PINK = 'FF66FF', -- #FF66FF
    OOC = 'E0FFFF', -- #E0FFFF
    PUBLICRADIO_COLOR = '6DFB6D', -- #6DFB6D
    TEAM_GROVE_COLOR = '00D900', -- #00D900
    REALRED = 'FF0606', -- #FF0606
    REALGREEN = '00FF00', -- #00FF00
    WANTED_COLOR = 'FF0000', -- #FF0000
    MONEY = '2F5A26', -- #2F5A26
    MONEY_NEGATIVE = '9C1619', -- #9C1619
	GOV = 'E8E79B', -- #E8E79B
    BETA = '5D8AA8', -- #5D8AA8
    DEV = 'C27C0E', -- #C27C0E
    ARES = '1C77B3', -- #1C77B3
}

-- Ensure Global `lanes.download_manager` Exists with `lane` and `linda`
if not _G['lanes.download_manager'] then
    -- Create a new linda for communication
    local linda = lanes.linda()

    -- Define the lane generator for handling downloads
    local download_lane_gen = lanes.gen('*', {
        package = {
            path = package.path,
            cpath = package.cpath,
        },
    },
    function(linda, fileUrl, filePath, identifier)
        local lanes = require('lanes')
        local ltn12 = require('ltn12')
        local http = require('socket.http')
        local https = require('ssl.https')  -- For HTTPS requests
        local lfs = require('lfs')          -- LuaFileSystem
        local url = require('socket.url')   -- URL parsing

        linda:send('debug_' .. identifier, { message = "Starting download for URL: " .. fileUrl .. " Identifier: " .. identifier })

        -- Ensure the output directory exists
        local dir = filePath:match("^(.*[/\\])")
        if dir and dir ~= "" then
            local attrs = lfs.attributes(dir)
            if not attrs then
                local path = ""
                for folder in string.gmatch(dir, "[^/\\]+[/\\]?") do
                    path = path .. folder
                    local attr = lfs.attributes(path)
                    if not attr then
                        local success, err = lfs.mkdir(path)
                        if not success then
                            linda:send('error_' .. identifier, { error = "Directory Creation Error: " .. tostring(err) })
                            linda:send('debug_' .. identifier, { message = "Directory creation error: " .. tostring(err) })
                            return
                        end
                    end
                end
            end
        end

        -- Prepare variables for progress tracking
        local progressData = {
            downloaded = 0,
            total = 0,
        }

        -- Create a sink that writes to the file and updates progress
        local outputFile, err = io.open(filePath, "wb")
        if not outputFile then
            linda:send('error_' .. identifier, { error = "File Open Error: " .. tostring(err) })
            return
        end

        -- Determine whether to use HTTP or HTTPS
        local parsed_url = url.parse(fileUrl)
        local http_request = http.request
        if parsed_url.scheme == "https" then
            http_request = https.request
        end

        -- Perform a HEAD request to get the total size
        local _, code, headers = http_request{
            url = fileUrl,
            method = "HEAD",
        }

        if code == 200 then
            local contentLength = headers["content-length"] or headers["Content-Length"]
            if contentLength then
                progressData.total = tonumber(contentLength)
                linda:send('debug_' .. identifier, { message = "Total size for URL: " .. fileUrl .. " is " .. progressData.total })
            else
                linda:send('debug_' .. identifier, { message = "Content-Length header not found for URL: " .. fileUrl })
            end
        else
            linda:send('debug_' .. identifier, { message = "HEAD request failed with code: " .. code .. " for URL: " .. fileUrl })
        end

        -- Create a custom sink function
        local stopDownload = false  -- Control variable
        local function progressSink(chunk, sinkErr)
            if stopDownload then
                -- Do nothing if download should stop
                return nil  -- Return nil to stop the sink
            end

            if chunk then
                -- Write the chunk to the file
                local success, writeErr = outputFile:write(chunk)
                if not success then
                    linda:send('error_' .. identifier, { error = "File Write Error: " .. tostring(writeErr) })
                    linda:send('debug_' .. identifier, { message = "File write error: " .. tostring(writeErr) })
                    stopDownload = true  -- Signal to stop further processing
                    -- Close the file to release resources
                    outputFile:close()
                    return nil  -- Return nil to stop the sink
                else
                    -- Update progress
                    progressData.downloaded = progressData.downloaded + #chunk
                    linda:send('progress_' .. identifier, {
                        downloaded = progressData.downloaded,
                        total = progressData.total,
                    })
                    linda:send('debug_' .. identifier, { message = "Progress update for identifier: " .. identifier .. " Downloaded: " .. progressData.downloaded .. " Total: " .. progressData.total })
                end
            else
                -- No more data; close the file
                outputFile:close()
                linda:send('completed_' .. identifier, {})
                linda:send('debug_' .. identifier, { message = "Download completed for identifier: " .. identifier })
            end
            return 1  -- Continue processing
        end

        -- Use the custom sink in the HTTP request
        local requestSuccess, requestCode, requestHeaders, requestStatus = http_request{
            url = fileUrl,
            method = "GET",
            sink = progressSink,
            headers = {
                ["Accept-Encoding"] = "identity",  -- Disable compression
            },
            redirect = false,
        }

        -- Handle unsuccessful requests
        if not requestSuccess or not (requestCode == 200 or requestCode == 206) then
            os.remove(filePath)  -- Remove incomplete file
            local errorMsg = "HTTP Error: " .. tostring(requestCode)
            linda:send('error_' .. identifier, { error = errorMsg })
            linda:send('debug_' .. identifier, { message = "HTTP request error for identifier: " .. identifier .. " Error: " .. errorMsg })
        end
    end)

    -- Define the main lane generator for handling requests
    local main_lane_gen = lanes.gen('*', {
        package = {
            path = package.path,
            cpath = package.cpath,
        },
    },
    function(linda)
        local lanes = require('lanes')

        while true do
            -- Wait for a 'request' with a timeout of 10 ms
            local key, val = linda:receive(0, 'request')
            if key == 'request' and val then
                local fileUrl = val.url
                local filePath = val.filePath
                local identifier = val.identifier

                -- Start a new lane for the download
                local success, laneOrErr = pcall(download_lane_gen, linda, fileUrl, filePath, identifier)
                if not success then
                    linda:send('error_' .. identifier, { error = "Failed to start download lane: " .. tostring(laneOrErr) })
                end
            else
                -- No request received, sleep briefly to prevent CPU hogging
                lanes.sleep(0.0001)
            end
        end
    end)

    -- Start the main lane, passing `linda` as an argument
    local success, laneOrErr = pcall(main_lane_gen, linda)
    if success then
        -- Assign the lane and linda to the global table
        _G['lanes.download_manager'] = { lane = laneOrErr, linda = linda }
        print("Main lane started successfully")
    else
        print("Failed to start main lane:", laneOrErr)  -- Print the error message
    end
end

-- DownloadManager Class
local DownloadManager = {}
DownloadManager.__index = DownloadManager

function DownloadManager:new(maxConcurrentDownloads)
    local manager = {
        downloadQueue = {},
        downloadsInProgress = {},
        activeDownloads = 0,
        maxConcurrentDownloads = maxConcurrentDownloads or 5,
        isDownloading = false,
        onCompleteCallback = nil,
        onProgressCallback = nil,
        totalFiles = 0,
        completedFiles = 0,
        lanesHttp = _G['lanes.download_manager'].linda, -- Reference to the global linda
        hasCompleted = false,  -- Initialize the hasCompleted flag
    }
    setmetatable(manager, DownloadManager)
    return manager
end

-- Queue Downloads
function DownloadManager:queueDownloads(fileTable, onComplete, onProgress)
    self.onCompleteCallback = onComplete
    self.onProgressCallback = onProgress

    self.hasCompleted = false   -- Reset the hasCompleted flag for new batch
    self.totalFiles = 0
    self.completedFiles = 0
    self.downloadQueue = {}     -- Reset the downloadQueue for new batch
    self.downloadsInProgress = {}  -- Reset active downloads
    self.activeDownloads = self.activeDownloads or 0  -- Ensure activeDownloads is initialized

    for index, file in ipairs(fileTable) do
        if not doesFileExist(file.path) or file.replace then
            file.index = index  -- Assign an index if not already set
            table.insert(self.downloadQueue, file)
            self.totalFiles = self.totalFiles + 1
        end
    end

    print(self.isDownloading)
    if not self.isDownloading then
        self.isDownloading = true
        self:processQueue()
    end
end

-- Process Queue
function DownloadManager:processQueue()
    -- Debugging statements
    print("ProcessQueue called")
    print("self.activeDownloads:", self.activeDownloads)
    print("self.maxConcurrentDownloads:", self.maxConcurrentDownloads)
    print("self.downloadQueue:", self.downloadQueue)
    print("#self.downloadQueue:", #self.downloadQueue)

    -- Ensure variables are not nil
    self.activeDownloads = self.activeDownloads or 0
    self.maxConcurrentDownloads = self.maxConcurrentDownloads or 5
    self.downloadQueue = self.downloadQueue or {}

    while self.activeDownloads < self.maxConcurrentDownloads and #self.downloadQueue > 0 do
        local file = table.remove(self.downloadQueue, 1)
        self.activeDownloads = self.activeDownloads + 1
        self:downloadFile(file)
    end
end

-- Download File
function DownloadManager:downloadFile(file)
    local identifier = file.index or tostring(file.url)
    local linda = self.lanesHttp

    -- Send the download request to the lane
    linda:send('request', {
        url = file.url,
        filePath = file.path,
        identifier = identifier
    })

    -- Add to downloadsInProgress
    self.downloadsInProgress[identifier] = file
    -- No longer calling monitorLane here
end

-- Update Downloads
function DownloadManager:updateDownloads()
    local linda = self.lanesHttp
    local downloadsToRemove = {}
    for identifier, file in pairs(self.downloadsInProgress) do
        local progressKey = 'progress_' .. identifier
        local completedKey = 'completed_' .. identifier
        local errorKey = 'error_' .. identifier
        local debugKey = 'debug_' .. identifier

        local key, val = linda:receive(0, completedKey, errorKey, progressKey, debugKey)
        if key and val then
            if key == completedKey then
                self.completedFiles = self.completedFiles + 1
                self.activeDownloads = self.activeDownloads - 1
                downloadsToRemove[identifier] = true
                self:processQueue()

            elseif key == errorKey then
                -- Handle error
                self.completedFiles = self.completedFiles + 1
                self.activeDownloads = self.activeDownloads - 1
                downloadsToRemove[identifier] = true
                self:processQueue()

            elseif key == progressKey then
                -- Update progress
                local fileProgress = 0
                if val.total > 0 then
                    fileProgress = (val.downloaded / val.total) * 100
                else
                    fileProgress = 0
                end
                -- Calculate overall progress
                local overallProgress = ((self.completedFiles + (val.downloaded / val.total)) / self.totalFiles) * 100

                if self.onProgressCallback then
                    self.onProgressCallback({
                        identifier = identifier,
                        downloaded = val.downloaded,
                        total = val.total,
                        fileProgress = fileProgress,
                        overallProgress = overallProgress,
                    }, file)
                end
            elseif key == debugKey then
                -- Handle debug messages if needed
                print("Debug:", val.message)
            end
        end
    end

    -- Remove completed downloads
    for identifier in pairs(downloadsToRemove) do
        self.downloadsInProgress[identifier] = nil
    end

    -- Check if all downloads are complete and the callback hasn't been called yet
    if self.activeDownloads == 0 and #self.downloadQueue == 0 and not self.hasCompleted then
        self.hasCompleted = true
        self.isDownloading = false
        if self.onCompleteCallback then
            self.onCompleteCallback(self.completedFiles > 0)
        end
    end
end

-- Initialize the DownloadManager instance at the top level
local downloadManager = DownloadManager:new(5)  -- max 5 concurrent downloads

-- Global Variables to Store Download Progress
local downloadProgress = {
    currentFile = "",
    fileProgress = 0,
    overallProgress = 0,
    downloadedSize = 0,
    totalSize = 0,
    totalFiles = 0,
    completedFiles = 0
}

-- Capitalize First Letter
function string:capitalizeFirst()
    return (self:gsub("^%l", string.upper))
end

-- Global Variables
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle

-- Key Press Type
local PressType = {KeyDown = isKeyDown, KeyPressed = wasKeyPressed}

-- Function Status Table
local funcsLoop = {
    functionStatus = {},
    callbackCalled = false,
}

-- Screen Resolution
local resX, resY = getScreenResolution()

-- Autobind Config
local autobind = {
	Settings = {Family = {}, Faction = {}},
	AutoBind = {},
	AutoVest = {skins = {}, names = {}},
    Frisk = {},
	Window = {Pos = {}},
	BlackMarket = {Pos = {}, Kit1 = {}, Kit2 = {}, Kit3 = {}, Locations = {}},
	FactionLocker = {Pos = {}, Kit1 = {}, Kit2 = {}, Kit3 = {}, Locations = {}},
	Keybinds = {}
}

-- Default Settings
local autobind_defaultSettings = {
	Settings = {
		enable = true,
		autoSave = true,
		mode = "Family",
        Family = {
            frequency = 0,
            turf = false,
            point = false,
            disableAfterCapturing = true
        },
        Faction = {
            type = "",
            frequency = 0,
            turf = false,
            modifyRadioChat = false
        }
	},
	AutoBind = {
		enable = true,
		autoRepair = true,
		autoBadge = true
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
		namesUrl = "https://raw.githubusercontent.com/akacross/autobind/main/names.json"
	},
    Frisk = {
        enable = true,
        target = false,
        mustAim = true
    },
	Window = {
		Pos = {x = resX / 2, y = resY / 2}
	},
	BlackMarket = {
		Pos = {x = resX / 3.5, y = resY / 2},
        Kit1 = {1, 9, 13},
        Kit2 = {1, 9, 12},
        Kit3 = {1, 9, 4},
		Locations = {}
    },
    FactionLocker = {
		Pos = {x = resX / 1.4, y = resY / 2},
		Kit1 = {1, 2, 10, 11},
        Kit2 = {1, 2, 10, 11},
        Kit3 = {1, 2, 10, 11},
		Locations = {}
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
	find = "find",
	tcap = "capspam",
	autovest = "autovest",
	autoaccept = "autoaccept",
	ddmode = "donormode"
}

-- Timers
local timers = {
	Vest = {timer = 13.0, last = 0, sentTime = 0, timeOut = 2.5},
	Accept = {timer = 0.5, last = 0},
	Heal = {timer = 12.0, last = 0},
	Find = {timer = 20.0, last = 0},
	Muted = {timer = 13.0, last = 0},
	Binds = {timer = 0.5, last = {}},
    Capture = {timer = 1.5, last = 0, sentTime = 0, timeOut = 10.0}
}

-- Guard
local guardTime = 13.0
local ddguardTime = 6.5

-- Accept Bodyguard
local accepter = {
	enable = false,
	received = false,
	playerName = "",
	playerId = -1
}

-- Offer Bodyguard
local bodyguard = {
    enable = true,
	received = false,
	playerName = "",
	playerId = -1
}

-- Auto Find
local autofind ={
	enable = false,
	playerName = "",
	playerId = -1,
    counter = 0
}

-- Factions
local factions = {
	skins = {
		61, 71, 73, 163, 164, 165, 166, 179, 191, 206, 285, 287, -- ARES
        120, 141, 253, 286, 294, -- FBI
        71, 265, 266, 267, 280, 281, 282, 283, 284, 285, 288, 300, 301, 302, 306, 307, 309, 310, 311 -- SASD/LSPD
	},
	colors = {
		-14269954, -7500289, -14911565, -3368653
	},
    ranks = {
        ARES = {
            "Commander",
            "Vice Commander",
            "Major",
            "Staff Sergeant",
            "Specialist",
            "Operative",
            "Recruit"
        }
    }
}

-- Capture Spam
local captureSpam = false

-- Menu Variables
local menu = {
	settings = {
        title = ("%s %s - v%s"):format(fa.ICON_FA_SHIELD_ALT, scriptName:capitalizeFirst(), scriptVersion),
		window = new.bool(false),
        size = {x = 588, y = 420},
        pivot = {x = 0.5, y = 0.5},
		pageId = 1
	},
	skins = {
		window = new.bool(false),
		pageId = 1,
		selected = -1
	},
	blackmarket = {
		window = new.bool(false), 
		pageId = 1
	},
	factionlocker = {
		window = new.bool(false), 
		pageId = 1
	}
}

local mainc = imgui.ImVec4(0.92, 0.27, 0.92, 1.0)
local imgui_color_red = imgui.ImVec4(1, 0.19, 0.19, 0.5)
local imgui_color_green = imgui.ImVec4(0.15, 0.59, 0.18, 0.7)

-- Font Data
local fontData = {
	fontSize = 12,
	font = nil
}

-- Currently Dragging
local currentlyDragging = nil

-- Change Key
local changeKey = {}

-- Skin Editor
local skinTexture = {}

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
	{label = 'Deagle', index = 0, weapon = 24, price = nil}, -- 1
	{label = 'Shotgun', index = 1, weapon = 25, price = nil}, -- 2
	{label = 'SPAS-12', index = 2, weapon = 27, price = 3200}, -- 3
	{label = 'MP5', index = 3, weapon = 29, price = 250}, -- 4
	{label = 'M4', index = 4, weapon = 31, price = 2100}, -- 5
	{label = 'AK-47', index = 5, weapon = 30, price = 2100}, -- 6
	{label = 'Teargas', index = 6, weapon = 17, price = nil}, -- 7
	{label = 'Camera', index = 7, weapon = 43, price = nil}, -- 8
	{label = 'Sniper', index = 8, weapon = 34, price = 5500}, -- 9
	{label = 'Armor', index = 9, weapon = nil, price = nil}, -- 10
	{label = 'Health', index = 10, weapon = nil, price = nil}, -- 11
	{label = 'Baton/Mace', index = 11, weapon = nil, price = nil}, -- 12
}

local lockerExclusiveGroups = {
	{2, 3}, -- Shotgun, SPAS-12
	{5, 6} -- M4, AK-47
}

-- Point Bounds
local gzData = nil
local enteredPoint = false
local leaveTime = 0
local preventHeal = false

-- Black Market
local maxSelections = 6
local getItemFromBM = 0
local gettingItem = false
local currentKey = nil

-- Locker
local maxSelectionsLocker = 6
local getItemFromLocker = 0
local gettingItemLocker = false
local currentKeyLocker = nil

-- Create a Lookup Table for Faction Locker Items
local lockerMenuItemsByIndex = {}
for tblIndex, item in ipairs(lockerMenuItems) do
    lockerMenuItemsByIndex[item.index] = item
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

-- Load Configs
function loadConfigs()
	-- Ignore Keys
	local ignoreKeys = {
		{"AutoVest", "skins"}, {"AutoVest", "names"}, 
		{"Keybinds", "BlackMarket1"}, {"Keybinds", "BlackMarket2"}, {"Keybinds", "BlackMarket3"},
		{"Keybinds", "FactionLocker1"}, {"Keybinds", "FactionLocker2"}, {"Keybinds", "FactionLocker3"},
		{"Keybinds", "BikeBind"},
		{"Keybinds", "SprintBind"},
		{"Keybinds", "Frisk"},
		{"Keybinds", "TakePills"},
		{"Keybinds", "Accept"},
		{"Keybinds", "Offer"},
		{"BlackMarket", "Kit1"},
		{"BlackMarket", "Kit2"},
		{"BlackMarket", "Kit3"},
		{"BlackMarket", "Locations"},
		{"FactionLocker", "Kit1"},
		{"FactionLocker", "Kit2"},
		{"FactionLocker", "Kit3"},
		{"FactionLocker", "Locations"}
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

	-- Wait for SAMP
    while not isSampAvailable() do wait(100) end

    local autoVest = autobind.AutoVest
    -- Fetch Skins
    if autoVest.autoFetchSkins then
		fetchDataFromURL(autoVest.skinsUrl, getFile("skins"), function(decodedData)
			autoVest.skins = decodedData
		end)
	end

	-- Fetch Names
	if autoVest.autoFetchNames then
		fetchDataFromURL(autoVest.namesUrl, getFile("names"), function(decodedData)
			autoVest.names = decodedData
		end)
	end

	-- Download Skins
	downloadSkins()

	-- Register Menu Command
	sampRegisterChatCommand(scriptName, function()
		menu.settings.pageId = 1
		menu.settings.window[0] = not menu.settings.window[0]
    end)

    -- Status Command
    sampRegisterChatCommand(scriptName .. ".status", function()
        local started = {}
        local failed = {}

        -- Iterate through the functionStatus table to collect running and failed functions
        for name, status in pairs(funcsLoop.functionStatus) do
            if status == "running" then
                table.insert(started, name)
            elseif status == "failed" then
                table.insert(failed, name)
            end
        end

        if #started > 0 then
            formattedAddChatMessage(string.format("{%s}Running Functions: {%s}%s{%s}.", clr.WHITE, clr.REALGREEN, table.concat(started, ", "), clr.WHITE))
            
            if #failed > 0 then
                formattedAddChatMessage(string.format("{%s}Failed Functions: {%s}%s{%s}.", clr.WHITE, clr.RED, table.concat(failed, ", "), clr.WHITE))
            end
        else
            formattedAddChatMessage("None of the functions are running.")
        end
    end)

	-- Black Market Command
	sampRegisterChatCommand("bms", function()
		menu.blackmarket.pageId = 1
		menu.blackmarket.window[0] = not menu.blackmarket.window[0]
	end)

	-- Register Chat Commands
	if autobind.Settings.enable then
		registerChatCommands()
	end

    -- Set Vest Timer
    timers.Vest.timer = autoVest.Donor and ddguardTime or guardTime

    -- Initial Menu Update
    updateButton1Tooltips()
    updateButton2Labels()

    -- Main Loop
    while true do wait(0)
        -- Start Functions Loop
        functionsLoop(function(started, failed)
            -- Success/Failed Messages
            formattedAddChatMessage(string.format("{%s}v%s has loaded successfully! {%s}Running: {%s}%s{%s}.", clr.WHITE, scriptVersion, clr.GREY, clr.REALGREEN, table.concat(started, ", "), clr.GREY))
            if #failed > 0 then
                formattedAddChatMessage(string.format("{%s}Failed Functions: {%s}%s{%s}.", clr.WHITE, clr.RED, table.concat(failed, ", "), clr.WHITE))
            end
        end)
    end
end

--local myFont = renderCreateFont("Arial", 9, 13)

-- onD3DPresent
function onD3DPresent()
	if not autobind.Settings or not autobind.Keybinds then
		return
	end

	-- Sprint Bind
	if autobind.Settings.enable and autobind.Keybinds.SprintBind.Toggle and (isButtonPressed(h, gkeys.player.SPRINT) and (isCharOnFoot(ped) or isCharInWater(ped))) then
		setGameKeyState(gkeys.player.SPRINT, 0)
	end

    -- Draw Download Progress
    --[[f downloadProgress.currentFile ~= "" then
        local x, y = 700, 500 -- Position on the screen
        local text = string.format(
            "Downloading: %s\nFile Progress: %.2f%%\nOverall Progress: %.2f%%\nDownloaded: %d of %d bytes (%d of %d files)",
            downloadProgress.currentFile,         -- %s
            downloadProgress.fileProgress,        -- %.2f
            downloadProgress.overallProgress,     -- %.2f
            downloadProgress.downloadedSize,      -- %d
            downloadProgress.totalSize or 1,      -- %d
            downloadProgress.completedFiles,      -- %d
            downloadProgress.totalFiles           -- %d
        )
        renderFontDrawText(myFont, text, x, y, 0xFFFFFFFF)

        if downloadProgress.overallProgress >= 100 then
            lua_thread.create(function()
                wait(5000)
                downloadProgress.currentFile = ""
                downloadProgress.fileProgress = 0
                downloadProgress.overallProgress = 0
                downloadProgress.downloadedSize = 0
                downloadProgress.totalSize = 0
                downloadProgress.completedFiles = 0
                downloadProgress.totalFiles = 0
            end)
        end
    end]]
end

-- Auto Vest
local function checkBodyguardCondition()
    return bodyguard.enable or autobind.AutoVest.donor
end

-- Check Animation
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

-- Check and send vest
function checkAndSendVest(skipArmorCheck)
    -- Current Time
    local currentTime = localClock()
    
    -- Check if autobind and AutoVest are enabled, and not in admin duty
    if not autobind.AutoVest.enable and not skipArmorCheck then
        return
    end

    -- Check if admin duty is active
    if checkAdminDuty() then
        return "You are on admin duty, you cannot send a vest."
    end

    -- Check if the player is frozen
    if not isPlayerControlOn(h) then
        return "You cannot send a vest while frozen, please wait."
    end

    -- Verify bodyguard condition
    if not checkBodyguardCondition() then
        return "You cannot send a vest while not a bodyguard."
    end

    -- Check if the user is muted
    if checkMuted() then
        return "You cannot send a vest while muted, please wait."
    end

    -- Reset bodyguard.received if timeout has elapsed
    if bodyguard.received then
        if currentTime - timers.Vest.sentTime > timers.Vest.timer / 2 then
            print("Vesting timed out. Resetting bodyguard. received.")
            bodyguard.received = false
        else
            return "Vest has been sent, please wait."
        end
    end

    -- Check if under vest cooldown
    if (currentTime - timers.Vest.last) < timers.Vest.timer then
        local timeLeft = math.ceil(timers.Vest.timer - (currentTime - timers.Vest.last))
        return string.format("You must wait %d seconds before sending vest.", timeLeft > 1 and timeLeft or 1)
    end

    -- Proceed to send vest if not received
    if not bodyguard.received then
        for _, player in ipairs(getVisiblePlayers(7, skipArmorCheck and "all" or "armor")) do
            if checkAnimationCondition(player.playerId) then
                if vestModeConditions(player.playerId) then
                    sampSendChat(autobind.AutoVest.donor and '/guardnear' or string.format("/guard %d 200", player.playerId))
                    bodyguard.received = true
                    timers.Vest.sentTime = currentTime
                    return
                end
            end
        end
        return "No suitable players found to vest, please try again."
    end
end

-- Check and accept vest
function checkAndAcceptVest(autoaccept)
    -- Current Time
	local currentTime = localClock()

    -- Check if under vest cooldown
	if currentTime - timers.Accept.last < timers.Accept.timer then
		return
	end
    
    -- Check if admin duty is active
    if checkAdminDuty() then
        return "You are on admin duty, you cannot accept a vest."
    end

    -- Check if the player is frozen
    if not isPlayerControlOn(h) then
        return "You cannot accept a vest while frozen, please wait."
    end

    -- Check if the user is muted
	if checkMuted() then
		return "You cannot accept a vest while muted, please wait."
	end

    -- Check if the user can heal
	if checkHeal() then
		local timeLeft = math.ceil(timers.Heal.timer - (currentTime - timers.Heal.last))
		return string.format("You must wait %d seconds before accepting a vest.", timeLeft > 1 and timeLeft or 1)
	end

	if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
		for _, player in ipairs(getVisiblePlayers(5, "all")) do
			if autoaccept and accepter.received then
				if sampGetPlayerNickname(player.playerId) == accepter.playerName then
					sampSendChat("/accept bodyguard")
					timers.Accept.last = currentTime
					return
				end
			end
		end

        local message
        if accepter.received and accepter.playerName and accepter.playerId then
            message = string.format("You are not close enough to %s (ID: %d).", accepter.playerName:gsub("_", " "), accepter.playerId)
        end

        return message or "No one has offered you bodyguard."
	else
		return "You are already have a vest."
	end
end

-- Function to check if the player is within any black market location
function isInBlackMarketLocation()
    -- Adjustable Z axis limits
    local zTopLimit = 0.7  -- Top limit of the Z axis
    local zBottomLimit = -0.7  -- Bottom limit of the Z axis

    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    for _, location in pairs(autobind.BlackMarket.Locations) do
        local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, location.x, location.y, location.z)
        local zDifference = playerZ - location.z
        if distance <= location.radius and zDifference <= zTopLimit and zDifference >= zBottomLimit then
            return true
        end
    end
    return false
end

function isInFactionLockerLocation()
    -- Adjustable Z axis limits
    local zTopLimit = 0.7  -- Top limit of the Z axis
    local zBottomLimit = -0.7  -- Bottom limit of the Z axis

    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    for _, location in pairs(autobind.FactionLocker.Locations) do
        local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, location.x, location.y, location.z)
        local zDifference = playerZ - location.z
        if distance <= location.radius and zDifference <= zTopLimit and zDifference >= zBottomLimit then
            return true
        end
    end
    return false
end

-- Function to check if the player already has the item
function playerHasItemBM(item)
    if item.weapon then
        return hasCharGotWeapon(ped, item.weapon)
    elseif item.label == 'Health/Armor' then
        local health = getCharHealth(ped) - 5000000
        local armor = getCharArmour(ped)
        return health == 100 and armor == 100
    end
    return false
end

function playerHasItemLocker(item)
    if item.weapon then
        return hasCharGotWeapon(ped, item.weapon)
    elseif item.label == 'Baton/Mace' then
        return hasCharGotWeapon(ped, 3) or hasCharGotWeapon(ped, 41)
    elseif item.label == 'Health' then
        return getCharHealth(ped) - 5000000 == 100
    elseif item.label == 'Armor' then
        return getCharArmour(ped) == 100
    end
    return false
end

-- Handle Black Market
function handleBlackMarket(kitNumber)
    local function resetBlackMarket()
        getItemFromBM = 0
        gettingItem = false
        currentKey = nil
    end

    if checkMuted() then
        formattedAddChatMessage(("{%s}You have been muted for spamming, please wait."):format(clr.WANTED_COLOR))
        resetBlackMarket()
        return
    end

    if not isInBlackMarketLocation() then
        formattedAddChatMessage(("{%s}You are not at the black market!"):format(clr.WANTED_COLOR))
        resetBlackMarket()
        return
    end

    if not isPlayerControlOn(h) then
        formattedAddChatMessage(("{%s}You cannot get items while frozen, please wait."):format(clr.WANTED_COLOR))
        resetBlackMarket()
        return
    end

    getItemFromBM = kitNumber

    -- Start a coroutine to process the items with delays
    lua_thread.create(function()
        local items = autobind.BlackMarket["Kit" .. kitNumber]
        local itemCount = 0
        local skippedItems = {}
        for index, itemIndex in ipairs(items) do
            local item = blackMarketItems[itemIndex]
            if item then
                if not playerHasItemBM(item) then
                    currentKey = item.index
                    gettingItem = true
                    sampSendChat("/bm")
                    repeat wait(0) until not gettingItem
                    itemCount = itemCount + 1
                    if itemCount % 3 == 0 then
                        wait(math.random(1500, 1750))
                    end
                else
                    table.insert(skippedItems, item.label)
                end
            end
        end
        if #skippedItems > 0 then
            wait(200)
            formattedAddChatMessage(string.format("{%s}Skipped items: {%s}%s.", clr.YELLOW, clr.WHITE, table.concat(skippedItems, ", ")))
        end
        resetBlackMarket()
    end)
end

-- Handle Faction Locker
function handleFactionLocker(kitNumber)
    local function resetFactionLocker()
        getItemFromLocker = 0
        gettingItemLocker = false
        currentKeyLocker = nil
    end

    if checkMuted() then
        formattedAddChatMessage(("{%s}You have been muted for spamming, please wait."):format(clr.WANTED_COLOR))
        resetFactionLocker()
        return
    end

    if not isInFactionLockerLocation() then
        formattedAddChatMessage(("{%s}You are not at the faction locker!"):format(clr.WANTED_COLOR))
        resetFactionLocker()
        return
    end

    if not isPlayerControlOn(h) then
        formattedAddChatMessage(("{%s}You cannot get items while frozen, please wait."):format(clr.WANTED_COLOR))
        resetFactionLocker()
        return
    end

    getItemFromLocker = kitNumber

    lua_thread.create(function()
        local items = autobind.FactionLocker["Kit" .. kitNumber]
        local itemCount = 0
        local skippedItems = {}
        for index, itemIndex in ipairs(items) do
            local item = lockerMenuItems[itemIndex]
            if item then
                if not playerHasItemLocker(item) then
                    currentKeyLocker = item.index
                    gettingItemLocker = true
                    sampSendChat("/locker")
                    repeat wait(0) until not gettingItemLocker
                    itemCount = itemCount + 1
                    if itemCount % 3 == 0 then
                        wait(math.random(1500, 1750))
                    end
                else
                    table.insert(skippedItems, item.label)
                end
            end
        end
        if #skippedItems > 0 then
            formattedAddChatMessage(string.format("{%s}Skipped items: {%s}%s.", clr.YELLOW, clr.WHITE, table.concat(skippedItems, ", ")))
        end
        resetFactionLocker()
    end)
end

-- Keybinds
function createKeybinds()
    -- Keybinds
    local keybinds = autobind.Keybinds
    local currentTime = localClock()
    local keyFunctions = {
        Accept = function()
            local message = checkAndAcceptVest(true)
            if message then
                formattedAddChatMessage(message)
            end
        end,
        Offer = function()
            local message = checkAndSendVest(true)
            if message then
                formattedAddChatMessage(message)
            end
        end,
        BlackMarket1 = function()
            handleBlackMarket(1)
        end,
        BlackMarket2 = function()
            handleBlackMarket(2)
        end,
        BlackMarket3 = function()
            handleBlackMarket(3)
        end,
        FactionLocker1 = function()
            handleFactionLocker(1)
        end,
        FactionLocker2 = function()
            handleFactionLocker(2)
        end,
        FactionLocker3 = function()
            handleFactionLocker(3)
        end,
        BikeBind = function()
            if not isCharOnAnyBike(ped) or not keybinds.BikeBind.Toggle then
                return
            end

            local veh = storeCarCharIsInNoSave(ped)
            if isCarInAirProper(veh) or getCarSpeed(veh) < 0.1 then
                return
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
        end,
        SprintBind = function()
            keybinds.SprintBind.Toggle = toggleBind("SprintBind", keybinds.SprintBind.Toggle)
        end,
        Frisk = function()
            if checkAdminDuty() or checkMuted() then
                return
            end

            local frisk = autobind.Frisk
            local targeting = getCharPlayerIsTargeting(h)
            for _, player in ipairs(getVisiblePlayers(5, "all")) do
                if (isButtonPressed(h, gkeys.player.LOCKTARGET) and frisk.mustAim) or not frisk.mustAim then
                    if (targeting and frisk.target) or not frisk.target then
                        sampSendChat(string.format("/frisk %d", player.playerId))
                        break
                    end
                end
            end
        end,
        TakePills = function()
            if checkAdminDuty() or checkMuted() then
                return
            end

            if checkHeal() then
                formattedAddChatMessage("You can't heal after being attacked recently. You cannot take pills.")
                return
            end

            sampSendChat("/takepills")
        end,
    }

    for key, value in pairs(keybinds) do
        local bind = {
            keys = value.Keys,
            type = value.Type
        }

        if keycheck(bind) and (value.Toggle or key == "BikeBind" or key == "SprintBind") then
            if activeCheck(true, true, true, true, true) and not menu.settings.window[0] then
                if key == "BikeBind" or not timers.Binds.last[key] or (currentTime - timers.Binds.last[key]) >= timers.Binds.timer then
                    local success, errorMsg = pcall(keyFunctions[key])
                    if not success then
                        print(string.format("Error in %s function: %s", key, errorMsg))
                    end
                    timers.Binds.last[key] = currentTime
                end
            end
        end
    end
end

-- Toggle Capture Spam
function toggleCaptureSpam()
	if not checkAdminDuty() then
		captureSpam = not captureSpam

        local strBegin = string.format("{%s}Starting capture attempt... (type /%s to toggle)", clr.YELLOW, commands.tcap)
        local strEnd = string.format("{%s}Capture spam ended.", clr.YELLOW)
		formattedAddChatMessage(captureSpam and strBegin or strEnd)
	end
end

-- Capture Spam
function createCaptureSpam()
    if not captureSpam or checkMuted() or checkAdminDuty() then
        return
    end

	local currentTime = localClock()
	if currentTime - timers.Capture.last >= timers.Capture.timer then
		sampSendChat("/capturf")
		timers.Capture.last = currentTime
	end
end

-- Pointbounds
function createPointBounds()
    -- Get Gangzone Pool
    if not gzData then
        gzData = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
        print("created gzData")
    end

    if autobind.Settings.mode ~= "Family" then
        return
    end

    -- Loop through all gangzones
    for i = 0, 1023 do
        if gzData.iIsListed[i] ~= 0 and gzData.pGangzone[i] ~= nil then
            local pos = gzData.pGangzone[i].fPosition
            local color = gzData.pGangzone[i].dwColor
            local ped_pos = { getCharCoordinates(PLAYER_PED) }
            
            local min1, max1 = math.min(pos[0], pos[2]), math.max(pos[0], pos[2])
            local min2, max2 = math.min(pos[1], pos[3]), math.max(pos[1], pos[3])
            
            if i >= 34 and i <= 45 then
                if ped_pos[1] >= min1 and ped_pos[1] <= max1 and ped_pos[2] >= min2 and ped_pos[2] <= max2 and color == 2348810495 then
                    enteredPoint = true
                    break
                else
                    if enteredPoint then
                        leaveTime = localClock()
                        preventHeal = true
                    end
                    enteredPoint = false
                end
            end
        end
    end
end

function createAutoFind()
    if not autofind.enable or checkMuted() then
        return
    end

    if not sampIsPlayerConnected(autofind.playerId) then
        formattedAddChatMessage("The player you were finding has disconnected, you are no longer finding anyone.")
        autofind.enable = false
        return
    end

    local currentTime = localClock()
    if currentTime - timers.Find.last >= timers.Find.timer then
        sampSendChat(string.format("/find %d", autofind.playerId))
        timers.Find.last = currentTime
    end
end

--- Functions (AutoVest, AutoAccept, Keybinds, CaptureSpam, PointBounds, AutoFind)
-- Functions Table
local functionsToRun = {
    {
        name = "DownloadManager",
        func = function()
            if downloadManager and downloadManager.isDownloading then
                downloadManager:updateDownloads()
            end
        end,
        interval = 0,
        lastRun = localClock(),
        enabled = true,
    },
    {
        name = "AutoVest",
        func = function()
            checkAndSendVest(false)
        end,
        interval = 0,
        lastRun = localClock(),
        enabled = true,
    },
    {
        name = "AutoAccept",
        func = function() 
            checkAndAcceptVest(accepter.enable)
        end,
        interval = 0,
        lastRun = localClock(),
        enabled = true,
    },
    {
        name = "Keybinds",
        func = createKeybinds,
        interval = 0,
        lastRun = localClock(),
        enabled = true,
    },
    {
        name = "CaptureSpam",
        func = createCaptureSpam,
        interval = 0,
        lastRun = localClock(),
        enabled = true,
    },
    {
        name = "PointBounds",
        func = createPointBounds,
        interval = 1.5,
        lastRun = localClock(),
        enabled = true,
    },
    {
        name = "AutoFind",
        func = createAutoFind,
        interval = 0,
        lastRun = localClock(),
        enabled = true,
    },
}

-- Initialize Function Status
local function initializeFunctionStatus()
    funcsLoop.functionStatus = {}
    for _, func in ipairs(functionsToRun) do
        funcsLoop.functionStatus[func.name] = "idle"
    end
end

-- Reset Function Status
local function resetFunctionStatus()
    initializeFunctionStatus()
end

-- Initialize Function Status at Start
initializeFunctionStatus()

-- Functions Loop
function functionsLoop(onFunctionsStatus)
    if sampGetGamestate() ~= 3 then
        resetFunctionStatus()
        gzData = nil
        return
    end

    if not autobind.Settings.enable then
        resetFunctionStatus()
        return
    end

    local currentTime = localClock()
    for _, item in ipairs(functionsToRun) do
        if item.enabled and (currentTime - item.lastRun >= item.interval) then
            local success, err = xpcall(item.func, debug.traceback)
            if not success then
                print(string.format("Error in %s function: %s", item.name, err))
                item.errorCount = (item.errorCount or 0) + 1
                funcsLoop.functionStatus[item.name] = "failed"

                if item.errorCount >= 5 then
                    print(string.format("%s function disabled after repeated errors.", item.name))
                    item.enabled = false
                    funcsLoop.functionStatus[item.name] = "disabled"
                end
            else
                item.errorCount = 0
                funcsLoop.functionStatus[item.name] = "running"
            end
            item.lastRun = currentTime
        end
    end

    if onFunctionsStatus and not funcsLoop.callbackCalled then
        local started = {}
        local failed = {}
        for name, status in pairs(funcsLoop.functionStatus) do
            if status == "running" then
                table.insert(started, name)
            elseif status == "failed" then
                table.insert(failed, name)
            end
        end
        onFunctionsStatus(started, failed)
        funcsLoop.callbackCalled = true
    end
end

--- Register Chat Commands
function registerChatCommands()
    local CMD = sampRegisterChatCommand
    local config = autobind.Settings
    local autoVest = autobind.AutoVest
    local keyBinds = autobind.Keybinds

	CMD(commands.vestnear, function()
        if not config.enable then
            return
        end

		local message = checkAndSendVest(true)
		if message then
			formattedAddChatMessage(message)
		end
	end)

	CMD(commands.repairnear, function()
		if not config.enable or checkMuted() or checkAdminDuty() then
            return
        end

        local found = false
		for _, player in ipairs(getVisiblePlayers(5, "car")) do
			sampSendChat(string.format("/repair %d 1", player.playerId))
			found = true
			break
		end
        if not found then
            formattedAddChatMessage("No suitable vehicle found to repair.")
        end
	end)
	
	CMD(commands.find, function(params)
        if not config.enable then
            return
        end

		if checkMuted() then
            formattedAddChatMessage(string.format("You are muted, you cannot use the /%s command.", commands.find))
            return
        end

		if string.len(params) < 1 then
            if autofind.enable then
                formattedAddChatMessage("You are no longer finding anyone.")
                autofind.enable = false
            else
				formattedAddChatMessage(string.format('USAGE: /%s [playerid/partofname]', commands.find))
			end
            return
        end

		local result, playerid, name = findPlayer(params)
		if not result then
			formattedAddChatMessage("Invalid player specified.")
			return
		end

		autofind.playerId = playerid
		autofind.playerName = name
		if autofind.enable then
			formattedAddChatMessage(string.format("Now finding: {%s}%s.", clr.LIGHTBLUE, name:gsub("_", " ")))
            return
		end

		autofind.enable = true
		formattedAddChatMessage(string.format("Finding: {%s}%s. {%s}Type /%s again to toggle off.", clr.LIGHTBLUE, autofind.playerName:gsub("_", " "), clr.WHITE, commands.find))
	end)

	CMD(commands.tcap, function()
        if not config.enable then
            return
        end

		toggleCaptureSpam()
	end)

	CMD(commands.sprintbind, function()
        if not config.enable then
            return
        end

		keyBinds.SprintBind.Toggle = toggleBind("SprintBind", keyBinds.SprintBind.Toggle)
	end)

	CMD(commands.bikebind, function()
        if not config.enable then
            return
        end

		keyBinds.BikeBind.Toggle = toggleBind("BikeBind", keyBinds.BikeBind.Toggle)
	end)

	CMD(commands.autovest, function()
        if not config.enable then
            return
        end

        autoVest.enable = toggleBind("Automatic Vest", autoVest.enable)
	end)

	CMD(commands.autoaccept, function()
        if not config.enable then
            return
        end

        accepter.enable = toggleBind("Auto Accept", accepter.enable)
	end)

	CMD(commands.ddmode, function()
        if not config.enable then
            return
        end

        autoVest.donor = toggleBind("DD Vest Mode", autoVest.donor)

		timers.Vest.timer = autoVest.donor and ddguardTime or guardTime
	end)
end

function toggleBind(name, bool)
    bool = not bool
    local color = bool and clr.REALGREEN or clr.RED
    formattedAddChatMessage(string.format("%s: {%s}%s", name, color, bool and 'on' or 'off'))
    return bool
end

-- OnScriptTerminate
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

-- OnWindowMessage
function onWindowMessage(msg, wparam, lparam)
	if wparam == VK_ESCAPE and (menu.settings.window[0] or menu.skins.window[0] or menu.blackmarket.window[0] or menu.factionlocker.window[0]) then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            menu.settings.window[0] = false
			menu.skins.window[0] = false
			menu.blackmarket.window[0] = false
			menu.factionlocker.window[0] = false
        end
    end
end

-- You can't use your lockers if you were recently shot.
-- Message Handlers (OnServerMessage)
local messageHandlers = {
    -- Muted Message
    {
        pattern = "^You have been muted automatically for spamming%. Please wait 10 seconds and try again%.",
        color = clr.YELLOW,
        action = function()
            timers.Muted.last = localClock()
        end
    },
    -- Admin On-Duty
    {
        pattern = '^You are now on%-duty as admin and have access to all your commands, see /ah.$',
        color = clr.YELLOW,
        action = function()
            setSampfuncsGlobalVar("aduty", 1)
        end
    },
    -- Admin Off-Duty
    {
        pattern = '^You are now off%-duty as admin, and only have access to /admins /check /jail /ban /sban /kick /skick /showflags /reports /nrn$',
        color = clr.YELLOW,
        action = function()
            setSampfuncsGlobalVar("aduty", 0)
        end
    },
    -- ARES Radio
    {
        pattern = "^%*%*%s*(.-):%s*(.-)%s*%*%*$",
        color = clr.RADIO,
        action = function(header, message)
            local config = autobind.Settings
            if not config.Faction.modifyRadioChat then
                return
            end

            local ranks = factions.ranks.ARES
            local skipDiv = false
            for _, v in ipairs(ranks) do
                if header:match("^(.-)%s+") == v then
                    skipDiv = true
                    break
                end
            end

            local div, rank, playerName
            if skipDiv then
                rank, playerName = header:match("^([" .. table.concat(ranks, "|") .. "].-)%s+(.-)$")
            else
                div, rank, playerName = header:match("^(.-)%s+([" .. table.concat(ranks, "|") .. "].-)%s+(.-)$")
            end

            if rank and playerName then
                local playerId = sampGetPlayerIdByNickname(playerName:gsub("%s+", "_"))
                local playerColor = convertColor(sampGetPlayerColor(playerId), false, false, true)
                local divOrRank = skipDiv and rank or string.format("%s %s", div, rank)
                sampAddChatMessage(string.format("{%s}** %s %s (%d): {%s}%s", clr.RADIO, divOrRank, playerName, playerId, clr.WHITE, message), -1)
                return false
            end
        end
    },
    -- Mode/Frequency
    {
        pattern = "^([Family|LSPD|SASD|FBI|ARES|GOV|LSFMD].+) MOTD: (.+)",
        color = clr.YELLOW,
        action = function(type, motdMsg)
            local config = autobind.Settings
            if type:match("Family") then
                config.mode = type
                updateButton2Labels()
                saveConfigWithErrorHandling(getFile("settings"), autobind)

                local freq, allies = motdMsg:match("[Ff]req:?%s*(-?%d+)%s*[/%s]*[Aa]llies:?%s*([^,]+)")
                if freq and allies then
                    print("Frequency detected", freq)
                    currentFamilyFreq = freq

                    print("Allies detected", allies)

                    local newMessage = motdMsg:gsub("[Ff]req:?%s*(-?%d+)", "")
                    newMessage = newMessage:gsub("^%s*,%s*", "")
                    print("New message: " .. newMessage)

                    sampAddChatMessage(string.format("{%s}%s MOTD: %s", clr.DEPTRADIO, type, newMessage), -1)
                    return false
                end
            elseif type:match("[LSPD|SASD|FBI|ARES|GOV]") then
                config.mode = "Faction"
                config.Faction.type = type
                updateButton2Labels()
                saveConfigWithErrorHandling(getFile("settings"), autobind)
                if accepter.enable then
                    formattedAddChatMessage("Auto Accept is now disabled because you are now in Faction Mode.")
                    accepter.enable = false
                end

                local freqType, freq = motdMsg:match("[/|%s*]%s*([RL FREQ:|FREQ:].-)%s*(-?%d+)")
                if freqType and freq then
                    print("Faction frequency detected: " .. freq)
                    currentFactionFreq = freq

                    local newMessage = motdMsg:gsub(freqType .. "%s*" .. freq:gsub("%-", "%%%-") .. "%s*", "")
                    newMessage = newMessage:gsub("%s*/%s*/%s*", " / ")

                    sampAddChatMessage(string.format("{%s}%s MOTD: %s", clr.DEPTRADIO, type, newMessage), -1)
                    return false
                end
            elseif type:match("LSFMD") then
                config.mode = "Faction"
                config.Faction.type = type
                updateButton2Labels()
                saveConfigWithErrorHandling(getFile("settings"), autobind)
            end
        end
    },
    -- Set Frequency Message
    {
        pattern = "You have set the frequency of your portable radio to (-?%d+) kHz.",
        color = clr.WHITE,
        action = function(freq)
            local config = autobind.Settings
            if tonumber(freq) == 0 then
                if config.mode == "Family" then
                    currentFamilyFreq = 0
                    config.Family.frequency = 0
                elseif config.mode == "Faction" then
                    currentFactionFreq = 0
                    config.Faction.frequency = 0
                end
            else
                formattedAddChatMessage(string.format("You have set the frequency to your {%s}%s {%s}portable radio.", clr.DEPTRADIO, config.mode, clr.WHITE))
                return false
            end
        end
    },
    -- Radio Message
    {
        pattern = "%*%* Radio %((%-?%d+) kHz%) %*%* (.-): (.+)",
        color = clr.PUBLICRADIO_COLOR,
        action = function(freq, playerName, message)
            local playerId = sampGetPlayerIdByNickname(playerName:gsub("%s+", "_"))
            local playerColor = convertColor(sampGetPlayerColor(playerId), false, false, true)
            sampAddChatMessage(string.format("{%s}** %s Radio ** {%s}%s (%d): {%s}%s", clr.PUBLICRADIO_COLOR, autobind.Settings.mode, playerColor, playerName, playerId, clr.WHITE, message), -1)
            return false
        end
    },
    -- Time Change (Auto Capture)
    {
        pattern = "^The time is now %d+:%d+%.$",
        color = clr.WHITE,
        action = function()
            lua_thread.create(function()
                wait(0)
                local currentTime = localClock()
                local timer = timers.Capture
                local config = autobind.Settings
                if currentTime - timer.sentTime > timer.timeOut then
                    if not checkMuted() and not checkAdminDuty() then
                        if (config.Faction.turf and config.mode == "Faction") or (config.Family.turf and config.mode == "Family") then
                            sampSendChat("/capturf")
                            timer.sentTime = currentTime
                            if config.Family.disableAfterCapturing and config.mode == "Family" then
                                config.Family.turf = false
                            end
                        end
                        if config.Family.point and config.mode == "Family" then
                            sampSendChat("/capture")
                            timer.sentTime = currentTime
                            if config.Family.disableAfterCapturing then
                                config.Family.point = false
                            end
                        end
                    end
                end
            end)
        end
    },
    -- Capture Spam Disabled
    {
        pattern = "^Your gang is already attempting to capture this turf%.$",
        color = clr.GRAD1,
        action = function()
            if captureSpam then
                local mode = autobind.Settings.mode
                formattedAddChatMessage(string.format("Your %s is already attempting to capture this turf, disabling capture spam.", mode:lower()))
                captureSpam = false
                return false
            end
        end
    },
    -- Bodyguard Not Near
    {
        pattern = "That player isn't near you%.$",
        color = clr.GREY,
        action = function()
            bodyguard.received = false
            resetTimer(2, timers.Vest)
        end
    },
    -- Can't Guard While Aiming
    {
        pattern = "You can't /guard while aiming%.$",
        color = clr.GREY,
        action = function()
            bodyguard.received = false
            resetTimer(1.0, timers.Vest)
        end
    },
    -- Must Wait Before Selling Vest
    {
        pattern = "You must wait (%d+) seconds? before selling another vest%.?",
        color = clr.GREY,
        action = function(cooldown)
            bodyguard.received = false
            resetTimer(tonumber(cooldown) + 0.5, timers.Vest)
        end
    },
    -- Offered Protection
    {
        pattern = "%* You offered protection to (.+) for %$200%.$",
        color = clr.LIGHTBLUE,
        action = function(nickname)
            bodyguard.playerName = nickname:gsub("%s+", "_")
            bodyguard.playerId = sampGetPlayerIdByNickname(bodyguard.playerName)
            bodyguard.received = false
            timers.Vest.last = localClock()
        end
    },
    -- Not a Bodyguard
    {
        pattern = "You are not a bodyguard%.$",
        color = clr.GREY,
        action = function()
            formattedAddChatMessage("You are not a bodyguard, disabling bodyguard related features.")
            bodyguard.enable = false
            bodyguard.playerName = ""
            bodyguard.playerId = -1
            bodyguard.received = false
            return false
        end
    },
    -- Now a Bodyguard
    {
        pattern = "%* You are now a Bodyguard, type %/help to see your new commands%.$",
        color = clr.LIGHTBLUE,
        action = function()
            formattedAddChatMessage("You are now a bodyguard, enabling bodyguard related features.")
            bodyguard.enable = true
            bodyguard.received = false
            return false
        end
    },
    -- Accept Vest
    {
        pattern = "You are not near the person offering you guard!",
        color = clr.GRAD2,
        action = function()
            if accepter.received and accepter.playerName ~= "" and accepter.playerId ~= -1 then
                formattedAddChatMessage(string.format("You are not close enough to %s (ID: %d).", accepter.playerName:gsub("_", " "), accepter.playerId))
                accepter.received = false
                return false
            end
        end
    },
    -- Protection Offer
    {
        pattern = "%* Bodyguard (.+) wants to protect you for %$200, type %/accept bodyguard to accept%.$",
        color = clr.LIGHTBLUE,
        action = function(nickname)
            lua_thread.create(function()
                wait(0)
                if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 and ((accepter.enable and not checkHeal()) or (accepter.enable and enteredPoint)) and not checkMuted() then
                    accepter.playerName = nickname:gsub("%s+", "_")
                    accepter.playerId = sampGetPlayerIdByNickname(accepter.playerName)
                    sampSendChat("/accept bodyguard")
                    accepter.received = false
                    wait(1000)
                end

                if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 then
                    accepter.playerName = nickname:gsub("%s+", "_")
                    accepter.playerId = sampGetPlayerIdByNickname(accepter.playerName)
                    accepter.received = true
                end
            end)
        end
    },
    -- Accepted Protection
    {
        pattern = "%* You accepted the protection for %$200 from (.+)%.$",
        color = clr.LIGHTBLUE,
        action = function()
            accepter.playerName = ""
            accepter.playerId = -1
            accepter.received = false
        end
    },
    -- Can't Afford Protection
    {
        pattern = "You can't afford the Protection!",
        color = clr.GREY,
        action = function()
            accepter.received = false
        end
    },
    -- Heal Timer Extended
    {
        pattern = "^You can't heal if you were recently shot, except within points, events, minigames, and paintball%.$",
        color = clr.WHITE,
        action = function()
            formattedAddChatMessage("You can't heal after being attacked recently. Timer extended by 5 seconds.")
            resetTimer(5, timers.Heal)
            return false
        end
    },
    -- Not Diamond Donator
    {
        pattern = "^You are not a Diamond Donator%!",
        color = clr.GREY,
        action = function()
            timers.Vest.timer = guardTime
            autobind.AutoVest.donor = false
        end
    },
    -- Not Sapphire or Diamond Donator
    {
        pattern = "^You are not a Sapphire or Diamond Donator%!",
        color = clr.GREY,
        action = function()
            if getItemFromBM > 0 then
                getItemFromBM = 0
                gettingItem = false
            end
        end
    },
    -- Not at Black Market
    {
        pattern = "^%s*You are not at the black market%!",
        color = clr.GRAD2,
        action = function()
            if getItemFromBM > 0 then
                getItemFromBM = 0
                gettingItem = false
            end
        end
    },
    -- Already Searched for Someone
    {
        pattern = "^You have already searched for someone %- wait a little%.$",
        color = clr.GREY,
        action = function()
            if autofind.enable then
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                resetTimer(5, timers.Find)
            end
        end
    },
    -- Can't Find Person Hidden in Turf
    {
        pattern = "^You can't find that person as they're hidden in one of their turfs%.$",
        action = function()
            if autofind.enable and autofind.playerName ~= "" and autofind.playerId ~= -1 then
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                formattedAddChatMessage(string.format("%s (ID: %d) is hidden in a turf. Autofind will try again in 5 seconds.", autofind.playerName:gsub("_", " "), autofind.playerId))
                resetTimer(5, timers.Find)
                return false
            end
        end
    },
    -- Not a Detective
    {
        pattern = "^You are not a detective%.$",
        color = clr.GREY,
        action = function()
            if autofind.enable then
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                autofind.enable = false
                formattedAddChatMessage("You are no longer finding anyone because you are not a detective.")
                return false
            end
        end
    },
    -- Now a Detective
    {
        pattern = "^%* You are now a Detective, type %/help to see your new commands %*$",
        color = clr.LIGHTBLUE,
        action = function()
            if autofind.playerName ~= "" and autofind.playerId ~= -1 then
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                autofind.enable = true
                formattedAddChatMessage(string.format("You are now a detective and re-enabling autofind on %s (ID: %d).", autofind.playerName:gsub("_", " "), autofind.playerId))
                return false
            end
        end
    },
    -- Unable to Find Person
    {
        pattern = "^You are unable to find this person%.$",
        color = clr.GREY,
        action = function()
            if autofind.enable then
                autofind.counter = autofind.counter + 1
                if autofind.counter >= 5 then
                    autofind.enable = false
                    autofind.playerId = -1
                    autofind.playerName = ""
                    autofind.counter = 0
                    formattedAddChatMessage("You are no longer finding anyone because you are unable to find this person.")
                    return false
                end
                resetTimer(5, timers.Find)
            end
        end
    },
    -- Accept Repair
    {
        pattern = "^%* Car Mechanic (.+) wants to repair your car for %$1, %(type %/accept repair%) to accept%.$",
        color = clr.LIGHTBLUE,
        action = function()
            if autobind.AutoBind.autoRepair and not checkMuted() and not checkAdminDuty() then
                lua_thread.create(function()
                    wait(0)
                    sampSendChat("/accept repair")
                end)
            end
        end
    },
    -- Auto Badge
    {
        pattern = "^Your hospital bill comes to %$%d+%. Have a nice day%!",
        color = clr.TEAM_MED_COLOR,
        action = function()
            if autobind.AutoBind.autoBadge and not checkMuted() and not checkAdminDuty() then
                if autobind.Settings.mode == "Faction" then
                    lua_thread.create(function()
                        wait(0)
                        sampSendChat("/badge")
                    end)
                end
            end
        end
    },
    -- Muted Notification
    {
        pattern = "^You have been muted automatically for spamming%. Please wait 10 seconds and try again%.$",
        color = clr.YELLOW,
        action = function()
            timers.Muted.last = localClock()
        end
    },
    -- Help Command Additions
    {
        pattern = "^%*%*%* OTHER %*%*%* /cellphonehelp /carhelp /househelp /toyhelp /renthelp /jobhelp /leaderhelp /animhelp /fishhelp /insurehelp /businesshelp /bankhelp",
        color = clr.WHITE,
        action = function()
            lua_thread.create(function()
                wait(0)
                sampAddChatMessage(string.format("*** AUTOBIND *** /%s /%s /%s /%s /%s /%s", scriptName, commands.repairnear, commands.find, commands.tcap, commands.sprintbind, commands.bikebind), -1)
                sampAddChatMessage(string.format("*** AUTOVEST *** /%s /%s /%s /%s", commands.autovest, commands.ddmode, commands.autoaccept, commands.vestnear), -1)
            end)
        end
    }
}

-- OnServerMessage
function sampev.onServerMessage(color, text)
    if not autobind.Settings.enable then
        return
    end

    for _, handler in ipairs(messageHandlers) do
        if (not handler.color or handler.color == convertColor(color, false, true, true):sub(1, -3)) then
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
end

-- OnSendTakeDamage
function sampev.onSendTakeDamage(senderID, damage, weapon, Bodypart)
	if damage < 1 then
		return
	end

	if autobind.Settings.mode == "Family" then
		if preventHeal then
			local currentTime = localClock()
			if currentTime - leaveTime >= 180 then
				preventHeal = false
			else
				print("Heal timer is prevented for 3 minutes after leaving the pointbounds.")
				return
			end
		end
	end

	timers.Heal.last = localClock()
end

-- OnCreate3DText
function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
    -- Dynamic Black Market Locations (From the server)
    if text:match("Type /blackmarket to purchase items") or text:match("Type /dlocker to purchase items") then
        -- Ensure the Locations table is initialized
        autobind.BlackMarket.Locations = autobind.BlackMarket.Locations or {}
        
        -- Store the location data
        autobind.BlackMarket.Locations[tostring(id)] = {
            x = position.x,
            y = position.y,
            z = position.z,
            radius = 13.0
        }
    end

    if text:match("/locker") and text:match("To open your locker.") then
        -- Ensure the Locations table is initialized
        autobind.FactionLocker.Locations = autobind.FactionLocker.Locations or {}

        -- Store the location data
        autobind.FactionLocker.Locations[tostring(id)] = {
            x = position.x,
            y = position.y,
            z = position.z,
            radius = 3.5
        }
    end
end

-- OnShowDialog
function sampev.onShowDialog(id, style, title, button1, button2, text)
    -- Black Market
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

    -- Faction Locker
    if getItemFromLocker > 0 then
        if title:find('[LSPD|FBI|ARES] Menu') then
            sampSendDialogResponse(id, 1, 1, nil)
            return false
        end

        if not title:find("[LSPD|FBI|ARES] Equipment") then 
            getItemFromLocker = 0 
            gettingItemLocker = false
            currentKeyLocker = nil
            return false 
        end
        sampSendDialogResponse(id, 1, currentKeyLocker, nil)

        local item = lockerMenuItemsByIndex[currentKeyLocker]
        if item then
            lua_thread.create(function()
                if not item.price then
                    local itemLabel
                    if item.label == "Health" or item.label == "Armor" then
                        itemLabel = string.format("%s kit", item.label:lower())
                    else
                        itemLabel = string.format("a %s", item.label:lower())
                    end
                    sampAddChatMessage(string.format("{%s}You have received %s from your faction locker.", clr.WHITE, itemLabel), -1)
                end
            end)
        else
            print("Error: Item not found for currentKeyLocker:", currentKeyLocker)
        end

        gettingItemLocker = false
        return false
    end
end

-- ImGUI Initialize
imgui.OnInitialize(function()
	-- Disable ini file
    imgui.GetIO().IniFilename = nil

    -- Load FontAwesome5 Icons
    loadFontIcons(true, 14.0, fa.min_range, fa.max_range, 'moonloader/resource/fonts/fa-solid-900.ttf')

	-- Load the font with the desired size
	local fontFile = getFolderPath(0x14) .. '\\trebucbd.ttf'
	assert(doesFileExist(fontFile), '[autobind] Font "' .. fontFile .. '" doesn\'t exist!')
	fontData.font = imgui.GetIO().Fonts:AddFontFromFileTTF(fontFile, fontData.fontSize)

	-- Load FontAwesome5 Icons (Again for the font above)
	loadFontIcons(true, fontData.fontSize, fa.min_range, fa.max_range, 'moonloader/resource/fonts/fa-solid-900.ttf')

	-- Load Skins
	for i = 0, 311 do
		if skinTexture[i] == nil then
			skinTexture[i] = imgui.CreateTextureFromFile(string.format("%s\\Skin_%d.png", getPath("skins"), i))
		end
	end

    --SoftBlackTheme()
end)

-- Define constants and static objects at the top
local color_default = imgui.ImVec4(0.16, 0.16, 0.16, 0.9)
local color_hover = imgui.ImVec4(0.40, 0.12, 0.12, 1)
local color_active = imgui.ImVec4(0.30, 0.08, 0.08, 1)
local button_size = imgui.ImVec2(75, 75)
local child_size1 = imgui.ImVec2(85, 382)

-- Predefined Colors
local color_default = imgui.ImVec4(0.16, 0.16, 0.16, 0.9)
local color_hover = imgui.ImVec4(0.40, 0.12, 0.12, 1)
local color_active = imgui.ImVec4(0.30, 0.08, 0.08, 1)
local imgui_color_green = imgui.ImVec4(0.00, 1.00, 0.00, 1.00)
local imgui_color_red = imgui.ImVec4(1.00, 0.00, 0.00, 1.00)

-- Predefined Sizes
local button_size_small = imgui.ImVec2(75, 75)
local button_size_large = imgui.ImVec2(165, 75)
local child_size1 = imgui.ImVec2(85, 382)
local child_size2 = imgui.ImVec2(500, 88)
local child_size_pages = imgui.ImVec2(500, 276)
local child_size_bottom = imgui.ImVec2(500, 20)

-- Button Tables
local buttons1 = {
    {
        id = 1,
        icon = fa.ICON_FA_POWER_OFF,
        tooltip = '', -- To be updated dynamically
        action = function()
            autobind.Settings.enable = not autobind.Settings.enable
            if autobind.Settings.enable then
                registerChatCommands()
            else
                for _, command in pairs(commands) do
                    sampUnregisterChatCommand(command)
                end
            end
            updateButton1Tooltips() -- Update tooltips after state change
        end,
        color = function()
            return autobind.Settings.enable and imgui_color_green or imgui_color_red
        end
    },
    {
        id = 2,
        icon = fa.ICON_FA_SAVE,
        tooltip = 'Save configuration',
        action = function()
            saveConfigWithErrorHandling(getFile("settings"), autobind)
        end,
        color = function()
            return color_default
        end
    },
    {
        id = 3,
        icon = fa.ICON_FA_SYNC,
        tooltip = 'Reload configuration',
        action = function()
            loadConfigs()
        end,
        color = function()
            return color_default
        end
    },
    {
        id = 4,
        icon = fa.ICON_FA_ERASER,
        tooltip = 'Load default configuration',
        action = function()
            ensureDefaults(autobind, autobind_defaultSettings, true, {{"Settings", "mode"}, {"Settings", "freq"}})
        end,
        color = function()
            return color_default
        end
    },
    {
        id = 5,
        icon = fa.ICON_FA_RETWEET .. ' Update',
        tooltip = 'Check for update [Disabled]',
        action = function()
            -- do something? (soon)
        end,
        color = function()
            return color_default
        end
    }
}

local buttons2 = {
    {
        id = 1,
        icon = fa.ICON_FA_COG,
        label = "Settings",
        pageId = 1,
        tooltip = "Open Settings"
    },
    {
        id = 2,
        icon = fa.ICON_FA_LIST,
        label = "", -- To be updated dynamically
        pageId = 2,
        tooltip = "Open Skins"
    },
    {
        id = 3,
        icon = fa.ICON_FA_LIST,
        label = "Names",
        pageId = 3,
        tooltip = "Open Names"
    }
}

-- Define the key editor table
local keyEditors = {
    {label = "Accept", key = "Accept", description = "Accepts a vest from someone. (Options are to the left)"},
    {label = "Offer", key = "Offer", description = "Offers a vest to someone. (Options are to the left)"},
    {label = "Take-Pills", key = "TakePills", description = "Types /takepills."},
    {label = "Frisk", key = "Frisk", description = "Frisks a player. (Options are to the left)"},
    {label = "Bike-Bind", key = "BikeBind", description = "Makes bikes/motorcycles/quads faster by holding the bind key while riding."},
    {label = "Sprint-Bind", key = "SprintBind", description = "Makes you sprint faster by holding the bind key while sprinting. (This is only the toggle)"},
}

-- Function to update tooltips and labels for buttons1
function updateButton1Tooltips()
    local btn = buttons1[1] -- Assuming first button is the toggle
    btn.tooltip = string.format('%s Toggles all functionalities. ({%s}%s{%s})',
        btn.icon,
        autobind.Settings.enable and clr.GREEN or clr.RED,
        autobind.Settings.enable and 'ON' or 'OFF',
        clr.WHITE)
end

-- Function to update labels for buttons2
function updateButton2Labels()
    buttons2[2].label = string.format("%s Skins", autobind.Settings.mode)
end

-- Precompute cursor positions for buttons1
local cursor_positions_y_buttons1 = {}
for i, _ in ipairs(buttons1) do
    cursor_positions_y_buttons1[i] = (i - 1) * 76
end

-- Predefine bools
local bool_autosave = new.bool(false)

-- Function to handle the Autosave checkbox
local function handleAutosaveCheckbox()
    bool_autosave[0] = autobind.Settings.autoSave
    if imgui.Checkbox('Autosave', bool_autosave) then
        autobind.Settings.autoSave = bool_autosave[0]
    end
    imgui.CustomTooltip('Automatically saves your settings when you exit the game')
end

-- Settings Window
local settingsFrameDrawer = imgui.OnFrame(function() return menu.settings.window[0] end,
function(self)
    -- Returns if Samp is not loaded
    if not isSampLoaded() or not isSampAvailable() then return end

    local settings = menu.settings
    local config = autobind.Settings

    -- Handle Window Dragging And Position
    local newPos, status = imgui.handleWindowDragging("Settings", autobind.Window.Pos, settings.size, settings.pivot)
    if status then
        autobind.Window.Pos = newPos
        imgui.SetNextWindowPos(autobind.Window.Pos, imgui.Cond.Always, settings.pivot)
    else
        imgui.SetNextWindowPos(autobind.Window.Pos, imgui.Cond.FirstUseEver, settings.pivot)
    end

    -- Set Window Size
    imgui.SetNextWindowSize(settings.size, imgui.Cond.FirstUseEver)

    -- Settings Window
    imgui.Begin(settings.title, settings.window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove)
        -- First child (Side Buttons)
        imgui.BeginChild("##1", child_size1, false)
        for i, button in ipairs(buttons1) do
            imgui.SetCursorPosY(cursor_positions_y_buttons1[i])
            local color = button.color() -- Directly call the color function
            if imgui.CustomButton(button.icon, color, color_hover, color_active, button_size_small) then
                button.action()
            end
            imgui.CustomTooltip(button.tooltip)
        end
        imgui.EndChild()

        imgui.SetCursorPos(imgui.ImVec2(85, 28))

        -- Second child (Page Buttons)
        imgui.BeginChild("##2", imgui.ImVec2(500, 88), false)
        for i, button in ipairs(buttons2) do
            imgui.SetCursorPosX((i - 1) * 165)
            imgui.SetCursorPosY(0)
            local isActive = settings.pageId == button.pageId
            local color = isActive and imgui.ImVec4(0.56, 0.16, 0.16, 1) or color_default
            if imgui.CustomButton(string.format("%s  %s", button.icon, button.label), color, color_hover, color_active, button_size_large) then
                settings.pageId = button.pageId
            end
            if not isActive then
                imgui.CustomTooltip(button.tooltip)
            end
        end
        imgui.EndChild()

        -- Third child (Pages)
        imgui.SetCursorPos(imgui.ImVec2(85, 110))
        imgui.BeginChild("##pages", child_size_pages, false)
        if settings.pageId == 1 then
            renderSettings()
        elseif settings.pageId == 2 then
            renderSkins()
        elseif settings.pageId == 3 then
            renderNames()
        end
        imgui.EndChild()

        -- Fourth child (Bottom Settings)
        imgui.SetCursorPos(imgui.ImVec2(92, 386.5))
        imgui.BeginChild("##4", child_size_bottom, false)
        handleAutosaveCheckbox()

        imgui.SameLine(config.mode == "Faction" and 270 or 388)
        if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " BM Settings") then
            local blackmarket = menu.blackmarket
            blackmarket.window[0] = not blackmarket.window[0]
        end
        imgui.CustomTooltip('Open the Black Market settings')

        if config.mode == "Faction" then
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Faction Locker") then
                local faction = menu.factionlocker
                faction.window[0] = not faction.window[0]
            end
            imgui.CustomTooltip('Open the Faction Locker settings')
        end
        imgui.EndChild()
    imgui.End()
end)

-- Skin Menu
--[[imgui.OnFrame(function() return menu.settings.window[0] and menu.skins.window[0] end,
function()
	-- Returns if Samp is not loaded
    assert(isSampLoaded(), "Samp not loaded")

	-- Returns if Samp is not available
    if not isSampAvailable() then return end

	-- Set the window position and size
    imgui.SetNextWindowPos(autobind.Window.Pos, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(505, 390), imgui.Cond.Always)

	-- Skin Window
    if imgui.Begin(u8("Skin Menu"), menu.skins.window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
        imgui.SetWindowFocus()

        local startIdx = 21 + 21 * (menu.skins.pageId - 2)
        local endIdx = (menu.skins.pageId == 15) and 299 or (41 + 21 * (menu.skins.pageId - 2))

        for i = startIdx, endIdx do
            if (i - startIdx) % 7 ~= 0 then
                imgui.SameLine()
            end

            if imgui.ImageButton(skinTexture[i], imgui.ImVec2(55, 100)) then
                autobind.AutoVest.skins[menu.skins.selected] = i
                menu.skins.window[0] = false
            end
            imgui.CustomTooltip("Skin " .. i)
        end

        imgui.SetCursorPos(imgui.ImVec2(555, 360))
        imgui.Indent(210)

        if imgui.Button(u8"Previous", new.bool) and menu.skins.pageId > 0 then
            menu.skins.pageId = (menu.skins.pageId == 1) and 15 or (menu.skins.pageId - 1)
        end
        imgui.SameLine()
        if imgui.Button(u8"Next", new.bool) and menu.skins.pageId < 16 then
            menu.skins.pageId = (menu.skins.pageId == 15) and 1 or (menu.skins.pageId + 1)
        end
        imgui.SameLine()
        imgui.Text("Page " .. menu.skins.pageId .. "/15")
    end
    imgui.End()
end)]]

-- Blackmarket Menu
imgui.OnFrame(function() return menu.blackmarket.window[0] end,
function()
	-- Returns if Samp is not loaded
    assert(isSampLoaded(), "Samp not loaded")

	-- Returns if Samp is not available
    if not isSampAvailable() then return end

	-- Handle Window Dragging
	local newPos, status = imgui.handleWindowDragging("BlackMarket", autobind.BlackMarket.Pos, imgui.ImVec2(226, 290), imgui.ImVec2(0.5, 0.5))
    if status and menu.blackmarket.window[0] then autobind.BlackMarket.Pos = newPos end

    if not autobind.Keybinds.BlackMarket1 then
        autobind.Keybinds.BlackMarket1 = {Toggle = false, Keys = {VK_MENU, VK_1}, Type = {'KeyDown', 'KeyPressed'}}
    end

    if not autobind.Keybinds.BlackMarket2 then
        autobind.Keybinds.BlackMarket2 = {Toggle = false, Keys = {VK_MENU, VK_2}, Type = {'KeyDown', 'KeyPressed'}}
    end

    if not autobind.Keybinds.BlackMarket3 then
        autobind.Keybinds.BlackMarket3 = {Toggle = false, Keys = {VK_MENU, VK_3}, Type = {'KeyDown', 'KeyPressed'}}
    end

    -- Initialize Blackmarket Kits
    if not autobind.BlackMarket.Kit1 then
        autobind.BlackMarket.Kit1 = {1, 9, 13}
    end

    if not autobind.BlackMarket.Kit2 then
        autobind.BlackMarket.Kit2 = {1, 9, 12}
    end

    if not autobind.BlackMarket.Kit3 then
        autobind.BlackMarket.Kit3 = {1, 9, 4}
    end
    
	-- Calculate total price
	local totalPrice = 0
	for _, index in ipairs(autobind.BlackMarket[string.format("Kit%d", menu.blackmarket.pageId)]) do
		local item = blackMarketItems[index]
		if item and item.price then
			totalPrice = totalPrice + item.price
		end
	end

	-- Set the window position and size
    imgui.SetNextWindowPos(autobind.BlackMarket.Pos, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(226, 290), imgui.Cond.Always)

	-- Blackmarket Window
	local title = string.format("BM - Kit: %d - $%s", menu.blackmarket.pageId, formatNumber(totalPrice))
    if imgui.Begin(u8(title), menu.blackmarket.window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
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
			if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Kit " .. kit.id, imgui.ImVec2(buttonWidth, 0)) then
				menu.blackmarket.pageId = kit.id
			end
			imgui.SameLine()
		end

		-- Remove the last SameLine to avoid layout issues
		imgui.NewLine()

		-- Display the key editor and menu based on the selected kitId
		for _, kit in ipairs(kits) do
			if menu.blackmarket.pageId == kit.id then
				keyEditor("Keybind", kit.key)
				createMenu('Selection', blackMarketItems, kit.menu, blackMarketExclusiveGroups, maxSelections)
			end
		end
    end
    imgui.End()
end)

-- Faction Locker Menu
imgui.OnFrame(function() return menu.factionlocker.window[0] end,
function()
    -- Returns if Samp is not loaded
    assert(isSampLoaded(), "Samp not loaded")

    -- Returns if Samp is not available
    if not isSampAvailable() then return end

    -- Handle Window Dragging
    local newPos, status = imgui.handleWindowDragging("FactionLocker", autobind.FactionLocker.Pos, imgui.ImVec2(226, 290), imgui.ImVec2(0.5, 0.5))
    if newPos and status then 
        autobind.FactionLocker.Pos = newPos 
    end

    if not autobind.Keybinds.FactionLocker1 then
        autobind.Keybinds.FactionLocker1 = {Toggle = false, Keys = {VK_MENU, VK_X}, Type = {'KeyDown', 'KeyPressed'}}
    end

    if not autobind.Keybinds.FactionLocker2 then
        autobind.Keybinds.FactionLocker2 = {Toggle = false, Keys = {VK_MENU, VK_C}, Type = {'KeyDown', 'KeyPressed'}}
    end

    if not autobind.Keybinds.FactionLocker3 then
        autobind.Keybinds.FactionLocker3 = {Toggle = false, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}}
    end

    -- Initialize Faction Locker Kits
    if not autobind.FactionLocker.Kit1 then
        autobind.FactionLocker.Kit1 = {1, 2, 10, 11}
    end

    if not autobind.FactionLocker.Kit2 then
        autobind.FactionLocker.Kit2 = {1, 2, 10, 11}
    end

    if not autobind.FactionLocker.Kit3 then
        autobind.FactionLocker.Kit3 = {1, 2, 10, 11}
    end

    -- Calculate total price
    local totalPrice = 0
    for _, index in ipairs(autobind.FactionLocker[string.format("Kit%d", menu.factionlocker.pageId)]) do
        local item = lockerMenuItems[index]
        if item and item.price then
            totalPrice = totalPrice + item.price
        end
    end

    -- Set the window position and size
    imgui.SetNextWindowPos(autobind.FactionLocker.Pos, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(226, 290), imgui.Cond.Always)

    -- Faction Locker Window
    local title = string.format("Locker - Kit: %d - $%s", menu.factionlocker.pageId, formatNumber(totalPrice))
    if imgui.Begin(u8(title), menu.factionlocker.window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
        local availWidth = imgui.GetContentRegionAvail().x
        local buttonWidth = availWidth / 3 - 5

        -- Define a table to map kitId to key and menu data
        local kits = {
            {id = 1, key = 'FactionLocker1', menu = autobind.FactionLocker.Kit1},
            {id = 2, key = 'FactionLocker2', menu = autobind.FactionLocker.Kit2},
            {id = 3, key = 'FactionLocker3', menu = autobind.FactionLocker.Kit3}
        }

        -- Create buttons for each kit
        for _, kit in ipairs(kits) do
            if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Kit " .. kit.id, imgui.ImVec2(buttonWidth, 0)) then
                menu.factionlocker.pageId = kit.id
            end
            imgui.SameLine()
        end

        -- Remove the last SameLine to avoid layout issues
        imgui.NewLine()

        -- Display the key editor and menu based on the selected kitId
        for _, kit in ipairs(kits) do
            if menu.factionlocker.pageId == kit.id then
                keyEditor("Keybind", kit.key)
                createMenu('Selection', lockerMenuItems, kit.menu, lockerExclusiveGroups, maxSelectionsLocker, {combineGroups = {{1, 4, 9}, {10, 11}, {7, 8}}})
            end
        end
    end
    imgui.End()
end)

-- Render Settings
function renderSettings()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##config", imgui.ImVec2(300, 255), false) then
        -- Autobind/Capture
        imgui.Text('Auto Bind:')
        createRow('Capture Spam', 'Capture spam will automatically type /capturf every 1.5 seconds.', captureSpam, toggleCaptureSpam, true)
        
        local config = autobind.Settings
        local autoBind = autobind.AutoBind
        local autoVest = autobind.AutoVest
        local frisk = autobind.Frisk

        createRow('Capture (Turfs)', 'Capture (Turfs) will automatically type /capturf at signcheck time.', config[config.mode].turf, function()
            config[config.mode].turf = toggleBind("Capture (Turfs)", config[config.mode].turf)
            if config.mode == "Family" then
                config[config.mode].point = false
            end
        end, false)
        
        if config.mode == "Family" then
            createRow('Disable capturing', 'Disable capturing after capturing: turns off auto capturing after the point/turf has been secured.', config.Family.disableAfterCapturing, function()
                config.Family.disableAfterCapturing = toggleBind("Disable Capturing", config.Family.disableAfterCapturing)
            end, true)
            
            createRow('Capture (Points)', 'Capture (Points) will automatically type /capturf at signcheck time.', config.Family.point, function()
                config.Family.point = toggleBind("Capture Point", config.Family.point)
                if config.Family.point then
                    config.Family.turf = false
                end
            end, false)
        end
        
        createRow('Accept Repair', 'Accept Repair will automatically accept repair requests.', autoBind.autoRepair, function()
            autoBind.autoRepair = toggleBind("Accept Repair", autoBind.autoRepair)
        end, true)
        
        if config.mode == "Faction" then
            createRow('Auto Badge', 'Automatically types /badge after spawning from the hospital.', autoBind.autoBadge, function()
                autoBind.autoBadge = toggleBind("Auto Badge", autoBind.autoBadge)
            end, false)
        end
        
        -- Auto Vest
        imgui.NewLine()
        imgui.Text('Auto Vest:')
        createRow('Enable', 'Enable for automatic vesting.', autoVest.enable, function()
            autoVest.enable = toggleBind("Auto Vest", autoVest.enable)
        end, true)
        
        createRow('Diamond Donator', 'Enable for Diamond Donators. Uses /guardnear does not have armor/paused checks.', autoVest.donor, function()
            autoVest.donor = toggleBind("DD Vest Mode", autoVest.donor)
            timers.Vest.timer = autoVest.donor and ddguardTime or guardTime
        end, false)
        
        -- Accept
        createRow('Auto Accept', 'Accept Vest will automatically accept vest requests.', accepter.enable, function()
            accepter.enable = toggleBind("Auto Accept", accepter.enable)
        end, true)
    
        createRow('Allow Everyone', 'With this enabled, the vest will be applied to everyone on the server.', autoVest.everyone, function()
            autoVest.everyone = toggleBind("Allow Everyone", autoVest.everyone)
        end, false)
        
        imgui.NewLine()
        imgui.Text('Frisk:')
        createRow('Targeting', 'Must be targeting a player to frisk. (Green Blip above the player)', frisk.target, function()
            frisk.target = toggleBind("Targeting", frisk.target)
        end, true)
        
        createRow('Must Aim', 'Must be aiming to frisk.', frisk.mustAim, function()
            frisk.mustAim = toggleBind("Must Aim", frisk.mustAim)
        end, false)
        
        if config.mode == "Faction" then
            imgui.NewLine()
            imgui.Text('Radio Chat:')
            createRow('Modify', 'Modify the radio chat to your liking.', config.Faction.modifyRadioChat, function()
                config.Faction.modifyRadioChat = toggleBind("Modify Radio Chat", config.Faction.modifyRadioChat)
            end, false)
        end
    end
    imgui.EndChild()
    
    imgui.SetCursorPos(imgui.ImVec2(322, 1))
    imgui.BeginChild("##keybinds", imgui.ImVec2(175, 270), false)
    -- Use the key editor table to call keyEditor for each entry
    imgui.SetCursorPosY(6)
    for _, editor in ipairs(keyEditors) do
        keyEditor(editor.label, editor.key, editor.description)
    end
    imgui.EndChild()
end

-- Render Skins
function renderSkins()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##skins", imgui.ImVec2(487, 270), false) then
        if autobind.Settings.mode == "Family" then
            imgui.PushItemWidth(326)
            local url = new.char[128](autobind.AutoVest.skinsUrl)
            if imgui.InputText('##skins_url', url, sizeof(url)) then
                autobind.AutoVest.skinsUrl = u8:decode(str(url))
            end
            imgui.CustomTooltip(string.format('URL to fetch skins from, must be a JSON array of skin IDs,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.skinsUrl))
            imgui.SameLine()
            imgui.PopItemWidth()
            if imgui.Button("Fetch") then
                --lua_thread.create(function()
                    fetchDataFromURL(autobind.AutoVest.skinsUrl, getFile("skins"), function(decodedData)
                        autobind.AutoVest.skins = decodedData
                    end)
                --end)
            end
            imgui.CustomTooltip("Fetches skins from provided URL")
            imgui.SameLine()
            if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchSkins)) then
                autobind.AutoVest.autoFetchSkins = not autobind.AutoVest.autoFetchSkins
            end
            imgui.CustomTooltip("Fetch skins at startup")
    
            -- Optimization: Precompute values outside the loop
            local columns = 8  -- Number of columns in the grid
            local imageSize = imgui.ImVec2(50, 80)  -- Size of each image
            local spacing = 10.0  -- Spacing between images
            local startPos = imgui.GetCursorPos()  -- Starting position
            local skinsCount = #autobind.AutoVest.skins
    
            for i = 1, skinsCount do
                local skinId = autobind.AutoVest.skins[i]
                -- Calculate position
                local column = (i - 1) % columns
                local row = math.floor((i - 1) / columns)
                local posX = startPos.x + column * (imageSize.x + spacing)
                local posY = startPos.y + row * (imageSize.y + spacing / 4)
            
                -- Set position and draw the image
                imgui.SetCursorPos(imgui.ImVec2(posX, posY))
                if skinTexture[skinId] then
                    imgui.Image(skinTexture[skinId], imageSize)
                else
                    -- Handle missing texture
                    imgui.Button("No Texture", imageSize)
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Skin " .. skinId)
                end
    
                -- Draw the "X" button on top of the image
                imgui.SetCursorPos(imgui.ImVec2(posX + imageSize.x - 20, posY))
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))  -- Transparent background
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1, 0, 0, 0.5))  -- Red when hovered
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1, 0, 0, 0.5))  -- Red when active
                if imgui.Button("x##"..i, imgui.ImVec2(20, 20)) then
                    table.remove(autobind.AutoVest.skins, i)
                    skinsCount = skinsCount - 1  -- Update the count
                    i = i - 1  -- Adjust the index after removal
                end
                imgui.PopStyleColor(3)
            end
        
            -- Add the "Add Skin" button in the next available slot
            local addButtonIndex = skinsCount + 1
            local column = (addButtonIndex - 1) % columns
            local row = math.floor((addButtonIndex - 1) / columns)
            local posX = startPos.x + column * (imageSize.x + spacing)
            local posY = startPos.y + row * (imageSize.y + spacing / 4)
        
            imgui.SetCursorPos(imgui.ImVec2(posX, posY))
            if imgui.Button("Add\nSkin", imageSize) then
                table.insert(autobind.AutoVest.skins, 0)
                menu.skins.window[0] = not menu.skins.window[0]
                menu.skins.selected = #autobind.AutoVest.skins
                skinsCount = skinsCount + 1
            end
        elseif autobind.Settings.mode == "Faction" then
            if imgui.Checkbox("Use Skins", new.bool(autobind.AutoVest.useSkins)) then
                autobind.AutoVest.useSkins = not autobind.AutoVest.useSkins
            end

            -- Optimization: Precompute values outside the loop
            local columns = 8  -- Number of columns in the grid
            local imageSize = imgui.ImVec2(50, 80)  -- Size of each image
            local spacing = 10.0  -- Spacing between images
            local startPos = imgui.GetCursorPos()  -- Starting position
            local skinsCount = #factions.skins

            for i = 1, skinsCount do
                local skinId = factions.skins[i]
                -- Calculate position
                local column = (i - 1) % columns
                local row = math.floor((i - 1) / columns)
                local posX = startPos.x + column * (imageSize.x + spacing)
                local posY = startPos.y + row * (imageSize.y + spacing / 4)
                
                -- Set position and draw the image
                imgui.SetCursorPos(imgui.ImVec2(posX, posY))
                if skinTexture[skinId] then
                    imgui.Image(skinTexture[skinId], imageSize)
                else
                    -- Handle missing texture
                    imgui.Button("No Texture", imageSize)
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Skin " .. skinId)
                end
            end
        end
    end
    imgui.EndChild()
end

-- Render Names
function renderNames()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##names", imgui.ImVec2(487, 263), false) then
        imgui.PushItemWidth(326)
        local url = new.char[128](autobind.AutoVest.namesUrl)
        if imgui.InputText('##names_url', url, sizeof(url)) then
            autobind.AutoVest.namesUrl = u8:decode(str(url))
        end
        imgui.CustomTooltip(string.format('URL to fetch names from, must be a JSON array of names,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.namesUrl))
        imgui.SameLine()
        imgui.PopItemWidth()
        if imgui.Button("Fetch") then
            --lua_thread.create(function()
                fetchDataFromURL(autobind.AutoVest.namesUrl, getFile("names"), function(decodedData)
                    autobind.AutoVest.names = decodedData
                end)
            --end)
        end
        imgui.CustomTooltip("Fetches names from provided URL")
        imgui.SameLine()
        if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchNames)) then
            autobind.AutoVest.autoFetchNames = not autobind.AutoVest.autoFetchNames
        end
        imgui.CustomTooltip("Fetch names at startup")
                
        local itemsPerRow = 3  -- Number of items per row
        local itemCount = 0
        local namesToRemove = {}
        
        for key, value in ipairs(autobind.AutoVest.names) do
            imgui.PushItemWidth(130)  -- Adjust the width of the input field
            local nick = new.char[128](value)
            if imgui.InputText('##Nickname'..key, nick, sizeof(nick)) then
                autobind.AutoVest.names[key] = u8:decode(str(nick))
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button("x##"..key) then
                table.insert(namesToRemove, key)
            end
                
            itemCount = itemCount + 1
            if itemCount % itemsPerRow ~= 0 then
                imgui.SameLine()
            end
        end

        -- Remove names outside the loop to avoid issues
        for _, key in ipairs(namesToRemove) do
            table.remove(autobind.AutoVest.names, key)
        end

        if imgui.Button("Add Name", imgui.ImVec2(130, 20)) then
            table.insert(autobind.AutoVest.names, "Name")
        end
    end
    imgui.EndChild()
end

--- Custom Functions
-- Table Contains
function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Create Row (Settings)
function createRow(label, tooltip, setting, toggleFunction, sameLine)
    if imgui.Checkbox(label, new.bool(setting)) then
        toggleFunction()
    end
    imgui.CustomTooltip(tooltip)

    if sameLine then
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetWindowWidth() / 2.0)
    end
end

-- Create Checkbox (Blackmarket & Faction Locker)
function createCheckbox(label, index, tbl, exclusiveGroups, maxSelections)
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
                            break
                        end
                    end
                end
            end
        end
    end
end

-- Create Menu (Blackmarket & Faction Locker)
function createMenu(title, items, tbl, exclusiveGroups, maxSelections, options)
    options = options or {}
    local combineGroups = options.combineGroups or {}

    imgui.Text(title.. ":")
    local handledIndices = {}
    
    -- Handle exclusive groups first
    for _, group in ipairs(exclusiveGroups) do
        for _, index in ipairs(group) do
            local item = items[index]
            if item then
                createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
                imgui.CustomTooltip(string.format("Price: %s", item.price and formatNumber("$" .. item.price) or "Free"))
                imgui.SameLine()
                table.insert(handledIndices, index)
            end
        end
        imgui.NewLine()
    end
    
    -- Handle combined groups
    for _, group in ipairs(combineGroups) do
        for i, index in ipairs(group) do
            local item = items[index]
            if item then
                createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
                imgui.CustomTooltip(string.format("Price: %s", item.price and formatNumber("$" .. item.price) or "Free"))
                if i < #group then
                    imgui.SameLine()
                end
                table.insert(handledIndices, index)
            end
        end
        --imgui.NewLine()
    end

    -- Handle remaining items
    for index, item in ipairs(items) do
        if not tableContains(handledIndices, index) then
            createCheckbox(item.label, index, tbl, exclusiveGroups, maxSelections)
            imgui.CustomTooltip(string.format("Price: %s", item.price and formatNumber("$" .. item.price) or "Free"))
        end
    end
end

-- Custom function to display tooltips based on key type
local function showKeyTypeTooltip(keyType)
    local tooltips = {
        KeyDown = "Triggers when the key is held down. (Repeats until the key is released)",
        KeyPressed = "Triggers when the key is just pressed down. (Does not repeat until the key is released and pressed again)."
    }
    imgui.CustomTooltip(tooltips[keyType] or "Unknown key type.")
end

-- Key Name Shortener
local function correctKeyName(keyName)
	return keyName:gsub("Left ", ""):gsub("Right ", ""):gsub("Context ", ""):gsub("Numpad", "Num")
end

-- Key Editor
function keyEditor(title, index, description)
    local keyBinds = autobind.Keybinds[index]

	-- Error Handling
    if not keyBinds then
        print("Warning: autobind.Keybinds[" .. index .. "] is nil")
        return
    end

	-- Check if the Keys table exists, if not, create it
    if not keyBinds.Keys then
        keyBinds.Keys = {}
    end

    -- Adjustable parameters
    local padding = imgui.ImVec2(8, 6)  -- Padding around buttons
    local comboWidth = 70  -- Width of the combo box
    local verticalSpacing = 2  -- Vertical spacing after the last key entry

    -- Load the font with the desired size
    imgui.PushFont(fontData.font)

    -- Begin Group
    imgui.BeginGroup()

    -- Title and description
    imgui.AlignTextToFramePadding()
    imgui.Text(title .. ":")
    if description then
        imgui.CustomTooltip(description)
    end

    imgui.SameLine()
    local checkBoxColor = keyBinds.Toggle and clr.REALGREEN or clr.RED
    local checkBoxText = keyBinds.Toggle and "Enabled" or "Disabled"
    if imgui.Checkbox(checkBoxText .. "##" .. index, new.bool(keyBinds.Toggle)) then
        keyBinds.Toggle = not keyBinds.Toggle
    end
    imgui.CustomTooltip(string.format("Toggle this key binding. {%s}(%s)", checkBoxColor, checkBoxText))

    for i, key in ipairs(keyBinds.Keys) do
        local buttonText = changeKey[index] and changeKey[index] == i and fa.ICON_FA_KEYBOARD or (key ~= 0 and correctKeyName(vk.id_to_name(key)) or fa.ICON_FA_KEYBOARD)
        local buttonSize = imgui.CalcTextSize(buttonText) + padding

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
        imgui.CustomTooltip(string.format("Press to change, Key: %d", i))

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
        if imgui.BeginCombo("##KeyType"..index..i, currentType:gsub("Key", "")) then
            for _, keyType in ipairs(keyTypes) do
                if imgui.Selectable(keyType:gsub("Key", ""), currentType == keyType) then
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

        -- Add the "-" button next to the first key slot if there are multiple keys
        if i == 1 and #keyBinds.Keys > 1 then
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local minusButtonSize = imgui.CalcTextSize("-") + padding
            if imgui.Button("-##remove" .. index, minusButtonSize) then
                table.remove(keyBinds.Keys)
                if type(keyBinds.Type) == "table" then
                    table.remove(keyBinds.Type)
                end
            end
            imgui.CustomTooltip("Remove this key binding.")
        end

        -- Add the "+" button next to the last key slot
        if i == #keyBinds.Keys then
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local plusButtonSize = imgui.CalcTextSize("+") + padding
            if imgui.Button("+##add" .. index, plusButtonSize) then
                local nextIndex = #keyBinds.Keys + 1
                if nextIndex <= 3 then
                    table.insert(keyBinds.Keys, 0)
                    if type(keyBinds.Type) ~= "table" then
                        keyBinds.Type = {keyBinds.Type or "KeyDown"}
                    end
                    table.insert(keyBinds.Type, "KeyDown")
                end
            end
            imgui.CustomTooltip("Add a new key binding.")
        end
    end

    -- If there are no keys, show the "+" button
    if #keyBinds.Keys == 0 then
        imgui.AlignTextToFramePadding()
        local plusButtonSize = imgui.CalcTextSize("+") + padding
        if imgui.Button("+##add" .. index, plusButtonSize) then
            table.insert(keyBinds.Keys, 0)
            if type(keyBinds.Type) ~= "table" then
                keyBinds.Type = {keyBinds.Type or "KeyDown"}
            end
            table.insert(keyBinds.Type, "KeyDown")
        end
        imgui.CustomTooltip("Add a new key binding.")
    end

    -- Add vertical spacing after the last key entry
    imgui.Dummy(imgui.ImVec2(0, verticalSpacing))

    imgui.EndGroup()
    imgui.PopFont()
end

-- Function to Fetch Data From URL
function fetchDataFromURL(url, path, callback)
    local function onComplete(downloadsFinished)
        if downloadsFinished then
            local file = io.open(path, "r")
            if file then
                local content = file:read("*all")
                file:close()

                local success, decoded = pcall(decodeJson, content)
                if success then
                    if decoded and next(decoded) ~= nil then
                        callback(decoded)
                    else
                        print("JSON format is empty or invalid. URL:", url)
                    end
                else
                    print("Failed to decode JSON:", decoded, "URL:", url)
                end
            else
                print("Error opening file:", path)
            end
        end
    end

    local function onProgress(progressData, file)
        -- Individual file progress
        print(string.format("Downloading '%s': %.2f%% complete", file.url, progressData.fileProgress))

        -- Overall progress
        print(string.format("Overall Progress: %.2f%% complete", progressData.overallProgress))
    end

    print("Downloading from URL:", url)
    downloadManager:queueDownloads({{url = url, path = path, replace = true}}, onComplete, onProgress)
end

-- Function to Generate Skins URLs
function generateSkinsUrls()
    local files = {}
    for i = 0, 311 do
        table.insert(files, {
            url = string.format("%sSkin_%d.png", fetchUrls("skins"), i),
            path = string.format("%sSkin_%d.png", getPath("skins"), i),
            replace = false,
            index = i
        })
    end

    -- Sort the files by index
    table.sort(files, function(a, b) return tonumber(a.index) < tonumber(b.index) end)

    return files
end

-- Function to Initiate the Skin Download Process
function downloadSkins()
    local function onComplete(downloadsFinished)
        if downloadsFinished then
            print("All files downloaded successfully.")
            formattedAddChatMessage("All skins downloaded successfully!")
        else
            print("No files needed to be downloaded.")
        end
    end

    local function onProgress(progressData, file)
        -- Individual file progress
        print(string.format("Downloading '%s': %.2f%% complete", file.url, progressData.fileProgress))

        -- Overall progress
        print(string.format("Overall Progress: %.2f%% complete", progressData.overallProgress))
    end

    downloadManager:queueDownloads(generateSkinsUrls(), onComplete, onProgress)
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
    return aduty == 1
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

-- Function to check if a table is a sparse array
local function isSparseArray(tbl)
    local count = 0
    for k, v in pairs(tbl) do
        if type(k) == "number" then
            count = count + 1
        end
    end
    return count ~= #tbl
end

-- Function to check for sparse arrays and nil values before saving
local function checkForIssues(tbl, path)
    path = path or ""
    for k, v in pairs(tbl) do
        local currentPath = path .. "." .. k
        if v == nil then
            print("Nil value found at key: " .. currentPath)
            return false, "Nil value found at key: " .. currentPath
        elseif type(v) == "table" then
            if isSparseArray(v) then
                print("Sparse array found at key: " .. currentPath)
                return false, "Sparse array found at key: " .. currentPath
            end
            local success, err = checkForIssues(v, currentPath)
            if not success then
                return false, err
            end
        end
    end
    return true
end

-- Handle Config File
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

-- Ensure Defaults
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

-- Load Config
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

-- Save Config
function saveConfig(filePath, config)
    local success, err = checkForIssues(config)
    if not success then
        return false, err
    end

    local file = io.open(filePath, "w")
    if not file then
        return false, "Could not save file."
    end
    file:write(encodeJson(config, false))
    file:close()
    return true
end

-- Save Config With Error Handling
function saveConfigWithErrorHandling(path, config)
    local success, err = saveConfig(path, config)
    if not success then
        print("Error saving config to " .. path .. ": " .. err)
    end
    return success
end

-- Convert Color
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

-- Join ARGB
function joinARGB(a, r, g, b, normalized)
    if normalized then
        a, r, g, b = math.floor(a * 255), math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    end

    local function clamp(value)
        return math.max(0, math.min(255, value))
    end

    return bit.bor(bit.lshift(clamp(a), 24), bit.lshift(clamp(r), 16), bit.lshift(clamp(g), 8), clamp(b))
end

-- Formatted Add Chat Message
function formattedAddChatMessage(string)
    sampAddChatMessage(string.format("{%s}[%s] {%s}%s", clr.LIGHTBLUE, scriptName:capitalizeFirst(), clr.WHITE, string), -1)
end

-- Split String
function string:split(delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    self:gsub(pattern, function(c)
        table.insert(result, c)
    end)
    return result
end

-- Remove Hex Brackets
function removeHexBrackets(text)
    return string.gsub(text, "{%x+}", "")
end

-- Format Number
function formatNumber(n)
    n = tostring(n)
    return n:reverse():gsub("...","%0,",math.floor((#n-1)/3)):reverse()
end

-- Compare Versions
function compareVersions(version1, version2)
    local letterWeights = {
        A = 1, B = 2, C = 3, D = 4, E = 5, -- Add more as needed
        alpha = 1, beta = 2, rc = 3, p = 4, h = 5 -- Common suffixes
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

-- Get Down Keys
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

-- Key Check
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

-- Has Number
function has_number(tab, val)
    for index, value in ipairs(tab) do
        if tonumber(value) == val then
            return true
        end
    end
    return false
end

-- Custom Button
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

-- Find Player
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

-- Get Player Id By Nickname
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

-- Calculate Window Size
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

-- Handle Window Dragging
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

-- Text Colored RGB
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

-- Custom Button With Tooltip
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

-- Custom Tooltip
function imgui.CustomTooltip(tooltip)
    if imgui.IsItemHovered() and tooltip then
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
        imgui.BeginTooltip()
        imgui.TextColoredRGB(tooltip)
        imgui.EndTooltip()
        imgui.PopStyleVar()
    end
end

-- Load Font Icons (File or Memory)
function loadFontIcons(fileOrMemory, fontSize, min, max, fontdata)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = new.ImWchar[3](min, max, 0)
	if fileOrMemory then
		imgui.GetIO().Fonts:AddFontFromFileTTF(fontdata, fontSize, config, iconRanges)
	else
		imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fontdata, fontSize, config, iconRanges)
	end
end

function SoftBlackTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.80, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.60, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.66, 0.66, 0.66, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.66, 0.66, 0.66, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.95, 0.95, 0.70, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.95, 0.95, 0.70, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.25, 0.25, 0.15, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.10, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
end
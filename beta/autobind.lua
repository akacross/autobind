script_name("autobind")
script_description("Autobind Menu")
script_version("1.8.21d")
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

-- Extra Modules (Used with Download Manager using lanes)
local extraModules = {"ltn12", "socket.http", "ssl.https", "lfs", "socket.url"}
for _, module in ipairs(extraModules) do
    table.insert(statusMessages.success, module)
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

-- Working Directory
local workingDir = getWorkingDirectory()

-- Paths Table
local Paths = {
    config = workingDir .. '\\config\\',
    resource = workingDir .. '\\resource\\',
}

-- Adding dependent paths after initial definitions
Paths.settings = Paths.config .. scriptName .. '\\'
Paths.skins = Paths.resource .. 'skins\\'

-- Files Table
local Files = {
    settings = Paths.settings .. 'autobind.json'
}

-- Helper Function to Construct Base URL
local function getBaseUrl(beta)
    local branch = beta and "beta/" or ""
    return "https://raw.githubusercontent.com/akacross/" .. scriptName .. "/main/" .. branch
end

-- URLs Table
local Urls = {
    script = function(beta)
        return getBaseUrl(beta) .. scriptName .. ".lua"
    end,
    update = function(beta)
        return getBaseUrl(beta) .. "update.json"
    end,
    skins = getBaseUrl(false) .. "resource/skins/"
}

-- Ensure Global `lanes.download_manager` Exists with `lane` and `linda`
if not _G['lanes.download_manager'] then
    -- Create a new linda for communication
    local linda = lanes.linda()

    -- Define the lane generator for handling downloads and data fetching
    local download_lane_gen = lanes.gen('*', {
        package = {
            path = package.path,
            cpath = package.cpath,
        },
    },
    function(linda, taskType, fileUrl, filePath, identifier)
        local lanes = require('lanes')
        local ltn12 = require('ltn12')
        local http = require('socket.http')
        local https = require('ssl.https')  -- For HTTPS requests
        local lfs = require('lfs')          -- LuaFileSystem
        local url = require('socket.url')   -- URL parsing

        if taskType == "download" then
            -- Existing download logic
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
                    linda:send('completed_' .. identifier, {
                        downloaded = progressData.downloaded,
                        total = progressData.total,
                    })
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

        elseif taskType == "fetch" then
            -- New logic for fetching data directly
            linda:send('debug_' .. identifier, { message = "Starting fetch for URL: " .. fileUrl .. " Identifier: " .. identifier })

            -- Determine whether to use HTTP or HTTPS
            local parsed_url = url.parse(fileUrl)
            local http_request = http.request
            if parsed_url.scheme == "https" then
                http_request = https.request
            end

            -- Perform the request
            local response_body = {}
            local res, code, response_headers, status = http_request{
                url = fileUrl,
                sink = ltn12.sink.table(response_body),
                headers = {
                    ["Accept-Encoding"] = "identity",  -- Disable compression
                }
            }

            if code == 200 then
                local content = table.concat(response_body)
                linda:send('completed_' .. identifier, { content = content })
                linda:send('debug_' .. identifier, { message = "Fetch completed for identifier: " .. identifier })
            else
                local errorMsg = "HTTP Error: " .. tostring(code)
                linda:send('error_' .. identifier, { error = errorMsg })
                linda:send('debug_' .. identifier, { message = "HTTP request error for identifier: " .. identifier .. " Error: " .. errorMsg })
            end
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
                local taskType = val.taskType
                local fileUrl = val.url
                local filePath = val.filePath
                local identifier = val.identifier

                -- Start a new lane for the task
                local success, laneOrErr = pcall(download_lane_gen, linda, taskType, fileUrl, filePath, identifier)
                if not success then
                    linda:send('error_' .. identifier, { error = "Failed to start lane: " .. tostring(laneOrErr) })
                end
            else
                -- No request received, sleep briefly to prevent CPU hogging
                lanes.sleep(0.001)
            end
        end
    end)

    -- Start the main lane, passing `linda` as an argument
    local success, laneOrErr = pcall(main_lane_gen, linda)
    if success then
        -- Assign the lane and linda to the global table
        _G['lanes.download_manager'] = { lane = laneOrErr, linda = linda }
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
        fetchQueue = {},
        downloadsInProgress = {},
        fetchesInProgress = {},
        activeDownloads = 0,
        activeFetches = 0,
        maxConcurrentDownloads = maxConcurrentDownloads or 5,
        isDownloading = false,
        isFetching = false,
        onCompleteCallback = nil,
        onProgressCallback = nil,
        totalFiles = 0,
        completedFiles = 0,
        lanesHttp = _G['lanes.download_manager'].linda,
        hasCompleted = false,
        pendingBatches = {},
        pendingFetchBatches = {},  -- Queue for pending fetch batches
    }
    setmetatable(manager, self)
    return manager
end

-- Queue Downloads
function DownloadManager:queueDownloads(fileTable, onComplete, onProgress)
    table.insert(self.pendingBatches, {files = fileTable, onComplete = onComplete, onProgress = onProgress})

    if not self.isDownloading then
        self:processNextBatch()
    end
end

-- Process the next batch of downloads
function DownloadManager:processNextBatch()
    if #self.pendingBatches == 0 then
        return
    end

    local batch = table.remove(self.pendingBatches, 1)
    self.onCompleteCallback = batch.onComplete
    self.onProgressCallback = batch.onProgress

    self.hasCompleted = false  -- Reset for the new batch
    self.totalFiles = 0
    self.completedFiles = 0
    self.downloadQueue = {}
    self.downloadsInProgress = {}
    self.activeDownloads = 0

    for index, file in ipairs(batch.files) do
        if not doesFileExist(file.path) or file.replace then
            file.index = index
            table.insert(self.downloadQueue, file)
            self.totalFiles = self.totalFiles + 1
        end
    end

    if self.totalFiles > 0 then
        self.isDownloading = true
        self:processQueue()
    else
        -- Do not set self.hasCompleted here
        self:completeBatch()  -- This will set self.hasCompleted
    end
end

-- Complete the current batch and start the next one
function DownloadManager:completeBatch()
    if self.hasCompleted then
        return  -- Prevent multiple calls
    end
    self.hasCompleted = true  -- Set it here
    self.isDownloading = false
    if self.onCompleteCallback then
        self.onCompleteCallback(self.completedFiles > 0)
    end
    self:processNextBatch()
end

-- Process Queue
function DownloadManager:processQueue()
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
        taskType = "download",
        url = file.url,
        filePath = file.path,
        identifier = identifier
    })

    -- Add to downloadsInProgress
    self.downloadsInProgress[identifier] = file
end

-- Queue Fetches
function DownloadManager:queueFetches(fetchTable, onComplete)
    table.insert(self.pendingFetchBatches, {fetches = fetchTable, onComplete = onComplete})

    if not self.isFetching then
        self:processNextFetchBatch()
    end
end

-- Process the next batch of fetches
function DownloadManager:processNextFetchBatch()
    if #self.pendingFetchBatches == 0 then
        self.isFetching = false
        return
    end

    local batch = table.remove(self.pendingFetchBatches, 1)
    self.currentFetchOnCompleteCallback = batch.onComplete  -- Store onComplete per batch

    self.isFetching = true
    self.hasCompletedFetch = false  -- Reset for the new batch
    self.activeFetches = 0
    self.fetchQueue = {}
    self.fetchesInProgress = {}

    for _, fetch in ipairs(batch.fetches) do
        fetch.identifier = fetch.identifier or tostring(fetch.url)
        table.insert(self.fetchQueue, fetch)
    end

    if #self.fetchQueue > 0 then
        self:processFetchQueue()
    else
        -- Do not set self.hasCompletedFetch here
        self:completeFetchBatch()  -- This will set self.hasCompletedFetch
    end
end

-- Process Fetch Queue
function DownloadManager:processFetchQueue()
    while self.activeFetches < self.maxConcurrentDownloads and #self.fetchQueue > 0 do
        local fetch = table.remove(self.fetchQueue, 1)
        self.activeFetches = self.activeFetches + 1
        self:fetchData(fetch, function(decodedData)
            -- Handle the completion of a fetch
            if fetch.callback then
                fetch.callback(decodedData)
            end

            -- Decrement active fetches
            self.activeFetches = self.activeFetches - 1

            -- Check if more fetches can be processed
            if #self.fetchQueue > 0 then
                self:processFetchQueue()
            else
                -- Complete the current fetch batch if all fetches are done
                if self.activeFetches == 0 then
                    self:completeFetchBatch()
                end
            end
        end)
    end
end

-- Complete the current fetch batch and start the next one
function DownloadManager:completeFetchBatch()
    if self.hasCompletedFetch then
        return  -- Prevent multiple calls
    end
    self.hasCompletedFetch = true  -- Set it here
    if self.currentFetchOnCompleteCallback then
        self.currentFetchOnCompleteCallback()
    end
    self:processNextFetchBatch()
end

-- Fetch Data
function DownloadManager:fetchData(fetch, onComplete)
    local identifier = fetch.identifier or tostring(fetch.url)
    local linda = self.lanesHttp

    -- Send the fetch request to the lane
    linda:send('request', {
        taskType = "fetch",
        url = fetch.url,
        identifier = identifier
    })

    -- Add to fetchesInProgress
    self.fetchesInProgress[identifier] = fetch

    -- Store the onComplete callback
    fetch.onComplete = onComplete
end

-- Update Downloads and Fetches
function DownloadManager:updateDownloads()
    local linda = self.lanesHttp
    local downloadsToRemove = {}
    local fetchesToRemove = {}

    -- Process downloads
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
            --[[elseif key == debugKey then
                -- Handle debug messages if needed
                print("Debug:", val.message)]]
            end
        end
    end

    -- Process fetches
    for identifier, fetch in pairs(self.fetchesInProgress) do
        local completedKey = 'completed_' .. identifier
        local errorKey = 'error_' .. identifier

        local key, val = linda:receive(0, completedKey, errorKey)
        if key and val then
            if key == completedKey then
                local content = val.content
                local success, decoded = pcall(decodeJson, content)
                if success then
                    fetch.onComplete(decoded)  -- Use fetch.onComplete instead of fetch.callback
                else
                    print("Failed to decode JSON:", decoded)
                end
                fetchesToRemove[identifier] = true
            elseif key == errorKey then
                print("Error fetching data:", val.error)
                fetchesToRemove[identifier] = true
            end
        end
    end

    -- Remove completed downloads
    for identifier in pairs(downloadsToRemove) do
        self.downloadsInProgress[identifier] = nil
    end

    -- Remove completed fetches
    for identifier in pairs(fetchesToRemove) do
        self.fetchesInProgress[identifier] = nil
    end

    -- Check if all downloads are complete
    if self.activeDownloads == 0 and #self.downloadQueue == 0 and not self.hasCompleted then
        self:completeBatch()
    end

    -- Check if all fetches are complete
    if self.activeFetches == 0 and #self.fetchQueue == 0 and not self.isFetching then
        self.isFetching = false
    end
end

-- Initialize the DownloadManager instance at the top level
local downloadManager = DownloadManager:new(10)  -- max 10 concurrent downloads

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

-- Helper function for rounding to the nearest integer
local function round(value)
    return math.floor(value + 0.5)
end

-- Convert Color with optional HSVA output
function convertColor(color, normalize, includeAlpha, outputHSVA)
    if type(color) ~= "number" then
        error("Invalid color value. Expected a number.")
    end

    local a = includeAlpha and bit.band(bit.rshift(color, 24), 0xFF) or 255
    local r = bit.band(bit.rshift(color, 16), 0xFF)
    local g = bit.band(bit.rshift(color, 8), 0xFF)
    local b = bit.band(color, 0xFF)

    if normalize then
        a, r, g, b = a / 255, r / 255, g / 255, b / 255
    end

    if outputHSVA then
        local h, s, v = RGBtoHSV(r, g, b)
        if includeAlpha then
            return {h = h, s = s, v = v, a = a}
        else
            return {h = h, s = s, v = v}
        end
    end

    if includeAlpha then
        return {r = r, g = g, b = b, a = a}
    else
        return {r = r, g = g, b = b}
    end
end

-- Join ARGB with proper rounding
function joinARGB(a, r, g, b, normalized)
    if normalized then
        a, r, g, b = round(a * 255), round(r * 255), round(g * 255), round(b * 255)
    end

    local function clamp(value)
        return math.max(0, math.min(255, value))
    end

    a, r, g, b = clamp(a), clamp(r), clamp(g), clamp(b)

    local color = bit.bor(
        bit.lshift(a, 24), 
        bit.lshift(r, 16), 
        bit.lshift(g, 8), 
        b
    )

    return color
end

-- Convert normalized RGB to HSV
function RGBtoHSV(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    local h, s, v = 0, 0, max

    if delta > 0 then
        if max == r then
            h = (g - b) / delta % 6
        elseif max == g then
            h = (b - r) / delta + 2
        else -- max == b
            h = (r - g) / delta + 4
        end
        h = h * 60
        if h < 0 then h = h + 360 end

        s = delta / max
    else
        h = 0
        s = 0
    end

    -- Handle edge cases for white and black
    if max == 0 then
        s = 0
    end

    return h, s, v
end

-- Convert HSV to normalized RGB
function HSVtoRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    local r1, g1, b1 = 0, 0, 0

    if h >= 0 and h < 60 then
        r1, g1, b1 = c, x, 0
    elseif h >= 60 and h < 120 then
        r1, g1, b1 = x, c, 0
    elseif h >= 120 and h < 180 then
        r1, g1, b1 = 0, c, x
    elseif h >= 180 and h < 240 then
        r1, g1, b1 = 0, x, c
    elseif h >= 240 and h < 300 then
        r1, g1, b1 = x, 0, c
    else -- h >= 300 and h < 360
        r1, g1, b1 = c, 0, x
    end

    local r = r1 + m
    local g = g1 + m
    local b = b1 + m

    return r, g, b
end

local clr = {
    GRAD1 = 0xB4B5B7, -- #B4B5B7
    GRAD2 = 0xBFC0C2, -- #BFC0C2
    GRAD3 = 0xCBCCCE, -- #CBCCCE
    GRAD4 = 0xD8D8D8, -- #D8D8D8
    GRAD5 = 0xE3E3E3, -- #E3E3E3
    GRAD6 = 0xF0F0F0, -- #F0F0F0
    GREY = 0xAFAFAF, -- #AFAFAF
    RED = 0xAA3333, -- #AA3333
    ORANGE = 0xFF8000, -- #FF8000
    YELLOW = 0xFFFF00, -- #FFFF00
    FORSTATS = 0xFFFF91, -- #FFFF91
    HOUSEGREEN = 0x00E605, -- #00E605
    GREEN = 0x33AA33, -- #33AA33
    LIGHTGREEN = 0x9ACD32, -- #9ACD32
    CYAN = 0x40FFFF, -- #40FFFF
    PURPLE = 0xC2A2DA, -- #C2A2DA
    BLACK = 0x000000, -- #000000
    WHITE = 0xFFFFFF, -- #FFFFFF
    FADE1 = 0xE6E6E6, -- #E6E6E6
    FADE2 = 0xC8C8C8, -- #C8C8C8
    FADE3 = 0xAAAAAA, -- #AAAAAA
    FADE4 = 0x8C8C8C, -- #8C8C8C
    FADE5 = 0x6E6E6E, -- #6E6E6E
    LIGHTRED = 0xFF6347, -- #FF6347
    NEWS = 0xFFA500, -- #FFA500
    TEAM_NEWS_COLOR = 0x049C71, -- #049C71
    TWPINK = 0xE75480, -- #E75480
    TWRED = 0xFF0000, -- #FF0000
    TWBROWN = 0x654321, -- #654321
    TWGRAY = 0x808080, -- #808080
    TWOLIVE = 0x808000, -- #808000
    TWPURPLE = 0x800080, -- #800080
    TWTAN = 0xD2B48C, -- #D2B48C
    TWAQUA = 0x00FFFF, -- #00FFFF
    TWORANGE = 0xFF8C00, -- #FF8C00
    TWAZURE = 0x007FFF, -- #007FFF
    TWGREEN = 0x008000, -- #008000
    TWBLUE = 0x0000FF, -- #0000FF
    LIGHTBLUE = 0x33CCFF, -- #33CCFF
    FIND_COLOR = 0xB90000, -- #B90000
    TEAM_AZTECAS_COLOR = 0x01FCFF, -- #01FCFF
    TEAM_TAXI_COLOR = 0xF2FF00, -- #F2FF00
    DEPTRADIO = 0xFFD700, -- #FFD700
    RADIO = 0x8D8DFF, -- #8D8DFF
    TEAM_BLUE_COLOR = 0x2641FE, -- #2641FE
    TEAM_FBI_COLOR = 0x8D8DFF, -- #8D8DFF
    TEAM_MED_COLOR = 0xFF8282, -- #FF8282
    TEAM_APRISON_COLOR = 0x9C7912, -- #9C7912
    NEWBIE = 0x7DAEFF, -- #7DAEFF
    PINK = 0xFF66FF, -- #FF66FF
    OOC = 0xE0FFFF, -- #E0FFFF
    PUBLICRADIO_COLOR = 0x6DFB6D, -- #6DFB6D
    TEAM_GROVE_COLOR = 0x00D900, -- #00D900
    REALRED = 0xFF0606, -- #FF0606
    REALGREEN = 0x00FF00, -- #00FF00
    WANTED_COLOR = 0xFF0000, -- #FF0000
    MONEY = 0x2F5A26, -- #2F5A26
    MONEY_NEGATIVE = 0x9C1619, -- #9C1619
	GOV = 0xE8E79B, -- #E8E79B
    BETA = 0x5D8AA8, -- #5D8AA8
    DEV = 0xC27C0E, -- #C27C0E
    ARES = 0x1C77B3 -- #1C77B3
}

local clrRGBA = {}
for name, color in pairs(clr) do
    -- Extract color components using ABGR format
    local clrs = convertColor(color, false, true, false)

    -- Adjust alpha value based on color
    if name == "WHITE" or 
       name == "GREY" or 
       name == "PURPLE" or 
       name == "YELLOW" or 
       name == "LIGHTBLUE" or 
       name == "TEAM_MED_COLOR" then
        clrs.a = 170
    else
        if name ~= "TEAM_BLUE_COLOR" then
            clrs.a = 255
        end
    end

    clrRGBA[name] = joinARGB(clrs.r, clrs.g, clrs.b, clrs.a, false)
end

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
	Settings = {Frisk = {}, Family = {}, Faction = {}},
	AutoVest = {skins = {}, names = {}, offeredTo = {}, offeredFrom = {}},
    PedsCount = {},
    AutoFind = {},
    LastBackup = {},
	WindowPos = {Settings = {}, Skins = {}, Keybinds = {}, Fonts = {}, BlackMarket = {}, FactionLocker = {}},
	BlackMarket = {Kit1 = {}, Kit2 = {}, Kit3 = {}, Kit4 = {}, Kit5 = {}, Kit6 = {}, Locations = {}},
	FactionLocker = {Kit1 = {}, Kit2 = {}, Kit3 = {}, Kit4 = {}, Kit5 = {}, Kit6 = {}, Locations = {}},
	Keybinds = {}
}

-- Default Settings
local autobind_defaultSettings = {
	Settings = {
		enable = true,
        CheckForUpdates = false,
        updateInProgress = false,
        lastVersion = "",
        fetchBeta = false,
		autoSave = true,
        autoRepair = true,
        currentBlackMarketKits = 3,
        currentFactionLockerKits = 3,
        callSecondaryBackup = false,
		mode = "Family",
        Frisk = {
            mustTarget = false,
            mustAim = true
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
            autoBadge = true
        }
	},
	AutoVest = {
		enable = true,
        price = 200,
		everyone = false,
		useSkins = false,
		autoFetchSkins = true,
		autoFetchNames = false,
		donor = false,
		skins = {123},
		names = {"Cross_Lynch", "Allen_Lynch"},
		skinsUrl = getBaseUrl(false) .. "skins.json",
		namesUrl = getBaseUrl(false) .. "names.json",
        offeredTo = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 25},
            font = "Arial",
            size = 9,
            flags = {
                BOLD = true,
                ITALICS = false,
                BORDER = true,
                SHADOW = true,
                UNDERLINE = false,
                STRIKEOUT = false
            },
            align = "left",
            colors = {text = clr.WHITE, value = clr.LIGHTBLUE}
        },
        offeredFrom = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 50},
            font = "Arial",
            size = 9,
            flags = {
                BOLD = true,
                ITALICS = false,
                BORDER = true,
                SHADOW = true,
                UNDERLINE = false,
                STRIKEOUT = false

            },
            align = "left",
            colors = {text = clr.WHITE, value = clr.LIGHTBLUE}
        }
	},
    PedsCount = {
        enable = true,
        Pos = {x = resX / 6.0, y = resY / 2 + 75},
        font = "Arial",
        size = 9,
        flags = {
            BOLD = true,
            ITALICS = false,
            BORDER = true,
            SHADOW = true,
            UNDERLINE = false,
            STRIKEOUT = false
        },
        align = "left",
        colors = {text = clr.RED, value = clr.GREY}
    },
    AutoFind = {
        enable = true,
        Pos = {x = resX / 6.0, y = resY / 2 + 100},
        font = "Arial",
        size = 9,
        flags = {
            BOLD = true,
            ITALICS = false,
            BORDER = true,
            SHADOW = true,
            UNDERLINE = false,
            STRIKEOUT = false
        },
        align = "left",
        colors = {text = clr.RED, value = clr.GREY}
    },
    LastBackup = {
        enable = true,
        Pos = {x = resX / 6.0, y = resY / 2 + 125},
        font = "Arial",
        size = 9,
        flags = {
            BOLD = true,
            ITALICS = false,
            BORDER = true,
            SHADOW = true,
            UNDERLINE = false,
            STRIKEOUT = false
        },
        align = "left",
        colors = {text = clr.RED, value = clr.GREY}
    },
	WindowPos = {
		Settings = {x = resX / 2, y = resY / 2},
        Skins = {x = resX / 2, y = resY / 2},
        Keybinds = {x = resX / 2, y = resY / 2},
        Fonts = {x = resX / 2, y = resY / 2},
        BlackMarket = {x = resX / 2, y = resY / 2},
        FactionLocker = {x = resX / 2, y = resY / 2}
	},
	BlackMarket = {
        Kit1 = {1, 4, 11},
        Kit2 = {1, 4, 13},
        Kit3 = {1, 4, 12},
		Locations = {}
    },
    FactionLocker = {
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
        BikeBind = {Toggle = true, Keys = {VK_SHIFT}, Type = {'KeyDown', 'KeyDown'}},
        SprintBind = {Toggle = true, Keys = {VK_F11}, Type = {'KeyPressed'}},
        Frisk = {Toggle = false, Keys = {VK_MENU, VK_F}, Type = {'KeyDown', 'KeyPressed'}},
        TakePills = {Toggle = true, Keys = {VK_F3}, Type = {'KeyPressed'}},
        AcceptDeath = {Toggle = true, Keys = {VK_OEM_PLUS}, Type = {'KeyPressed'}},
        RequestBackup = {Toggle = true, Keys = {VK_MENU, VK_B}, Type = {'KeyDown', 'KeyPressed'}}
    }
}

-- Commands
local cmds = {
	vestnear = {cmd = "vestnear", desc = "Sends a vest offer to the nearest player"},
	repairnear = {cmd = "repairnear", desc = "Sends a repair request to the nearest player"},
	sprintbind = {cmd = "sprintbind", desc = "Toggles fast sprinting"},
	bikebind = {cmd = "bikebind", desc = "Toggles bike binding (bikes/motorbikes)"},
	find = {cmd = "find", desc = "Repeativly finds a player every 20 seconds"},
	tcap = {cmd = "capspam", desc = "Spams capture turf command every 1.5 seconds"},
	autovest = {cmd = "autovest", desc = "Automatically offers to vest to other players"},
	autoaccept = {cmd = "autoaccept", desc = "Automatically accepts offers from other players"},
	ddmode = {cmd = "donormode", desc = "Toggles diamond donator mode"},
    sprunkspam = {cmd = "sprunkspam", desc = "Opens a can of sprunk and heals you until full health"}
}

-- Timers
local timers = {
	Vest = {timer = 13.0, last = 0, sentTime = 0, timeOut = 3.0},
	Accept = {timer = 0.5, last = 0},
	Heal = {timer = 12.0, last = 0},
	Find = {timer = 20.0, last = 0},
	Muted = {timer = 13.0, last = 0},
	Binds = {timer = 0.5, last = {}},
    Capture = {timer = 1.5, last = 0, sentTime = 0, timeOut = 10.0},
    Sprunk = {timer = 0.2, last = 0},
    Point = {timer = 180.0, last = 0}
}

-- Guard
local guardTime = 13.0
local ddguardTime = 6.5

-- Accept Bodyguard
local accepter = {
	enable = false,
	received = false,
	playerName = "",
	playerId = -1,
    price = 0
}

-- Accepter Thread
local accepterThread = nil

-- Offer Bodyguard
local bodyguard = {
    enable = true,
	received = false,
	playerName = "",
	playerId = -1,
    price = 0
}

-- Auto Find
local autofind ={
	enable = false,
	playerName = "",
	playerId = -1,
    counter = 0
}

-- Backup
local backup = {
    enable = false,
    playerName = "",
    playerId = -1,
    location = ""
}

-- Sprunk
local usingSprunk = false

-- Capture Spam
local captureSpam = false

-- Point Data
local gzData = nil
local enteredPoint = false
local preventHeal = false

-- Names List
local names = {}

-- Family
local family = {
    turfColor = 0x8C0000FF, -- Active Turf Color (Flashing)
    skins = {}
}

-- Factions
local factions = {
	skins = {
		[61] = true, [71] = true, [73] = true, [163] = true, [164] = true, [165] = true, [166] = true, [179] = true, [191] = true, [206] = true, [285] = true, [287] = true, -- ARES
        [120] = true, [141] = true, [253] = true, [286] = true, [294] = true, -- FBI
        [71] = true, [265] = true, [266] = true, [267] = true, [280] = true, [281] = true, [282] = true, [283] = true, [284] = true, [285] = true, [288] = true, [300] = true, [301] = true, [302] = true, [306] = true, [307] = true, [309] = true, [310] = true, [311] = true, -- SASD/LSPD
	},
	colors = {
		[0x2641FE] = true, [0x8D8DFF] = true, [0xBEBEBE] = true, [0xCC9933] = true, [0x1C77B3] = true, -- No Alpha (LSPD, FBI, GOV, SASD, ARES) [Badge]
        [0x8C2641FE] = true, [0x8C8D8DFF] = true, [0x8CBEBEBE] = true, [0x8CCC9933] = true, [0x8C1C77B3] = true -- With Alpha (LSPD, FBI, GOV, SASD, ARES) [Turf]
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

-- Menu Variables
local menu = {
    initialized = new.bool(false),
    confirm = {
        window = new.bool(false),
        size = {x = 300, y = 100},
        pivot = {x = 0.5, y = 0.5},
        update = new.bool(false)
    },
	settings = {
        title = ("%s %s - v%s"):format(fa.ICON_FA_SHIELD_ALT, scriptName:capitalizeFirst(), scriptVersion),
		window = new.bool(false),
        size = {x = 588, y = 420},
        pivot = {x = 0.5, y = 0.5},
		pageId = 1
	},
    keybinds = {
        title = "Keybind Settings",
		window = new.bool(false),
        size = {x = 350, y = 400},
        pivot = {x = 0.5, y = 0.5}
    },
	fonts = {
        title = "Font Settings",
		window = new.bool(false),
        size = {x = 473, y = 288},
        pivot = {x = 0.5, y = 0.5}
	},
	skins = {
        title = "Family Skin Selection",
		window = new.bool(false),
        size = {x = 545, y = 420},
        pivot = {x = 0.5, y = 0.5},
		selected = -1
	},
	blackmarket = {
		window = new.bool(false),
        size = {x = 226, y = 290},
        pivot = {x = 0.5, y = 0.5},
        pageId = 1
	},
	factionlocker = {
		window = new.bool(false),
        size = {x = 226, y = 290},
        pivot = {x = 0.5, y = 0.5},
        pageId = 1
	}
}

local imgui_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove

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

-- Skins URLs
local skinsUrls = {}

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

-- Max Kits
local maxKits = 6

-- Black Market
local blackMarket = {
    maxSelections = 6,
    getItemFrom = 0,
    gettingItem = false,
    currentKey = nil,
    obtainedItems = {},
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
    }
}

local factionLocker = {
    maxSelections = 6,
    getItemFrom = 0,
    gettingItem = false,
    currentKey = nil,
    obtainedItems = {},  -- To collect items obtained
    Items = {
        [1] = {label = 'Deagle', index = 0, weapon = 24, price = nil},
        [2] = {label = 'Shotgun', index = 1, weapon = 25, price = nil, group = 3, priority = 1},
        [3] = {label = 'SPAS-12', index = 2, weapon = 27, price = 3200, group = 3, priority = 2},
        [4] = {label = 'MP5', index = 3, weapon = 29, price = 250},
        [5] = {label = 'M4', index = 4, weapon = 31, price = 2100, group = 5, priority = 2},
        [6] = {label = 'AK-47', index = 5, weapon = 30, price = 2100, group = 5, priority = 1},
        [7] = {label = 'Teargas', index = 6, weapon = 17, price = nil},
        [8] = {label = 'Camera', index = 7, weapon = 43, price = nil},
        [9] = {label = 'Sniper', index = 8, weapon = 34, price = 5500},
        [10] = {label = 'Armor', index = 9, weapon = nil, price = nil},
        [11] = {label = 'Health', index = 10, weapon = nil, price = nil},
        [12] = {label = 'Baton/Mace', index = 11, weapon = nil, price = nil}
    },
    ExclusiveGroups = {
        [1] = {2, 3},  -- Group 1: Shotgun, SPAS-12
        [2] = {5, 6},  -- Group 2: M4, AK-47
    },
    combineGroups = {
        {1, 4, 9}, -- Deagle, MP5, Sniper
        {2, 3}, -- Shotgun, SPAS-12
        {5, 6}, -- M4, AK-47
        {10, 11}, -- Health, Armor
        {7, 8} -- Teargas, Camera
    }
}

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
		{"Keybinds", "BikeBind"},
		{"Keybinds", "SprintBind"},
		{"Keybinds", "Frisk"},
		{"Keybinds", "TakePills"},
		{"Keybinds", "Accept"},
		{"Keybinds", "Offer"},
		{"Keybinds", "AcceptDeath"},
		{"Keybinds", "RequestBackup"},
		{"BlackMarket", "Locations"},
		{"FactionLocker", "Locations"}
	}

    for i = 1, maxKits do
        ignoreKeys[#ignoreKeys + 1] = {"Keybinds", "BlackMarket" .. i}
        ignoreKeys[#ignoreKeys + 1] = {"BlackMarket", "Kit" .. i}
        ignoreKeys[#ignoreKeys + 1] = {"Keybinds", "FactionLocker" .. i}
        ignoreKeys[#ignoreKeys + 1] = {"FactionLocker", "Kit" .. i}
    end

	-- Handle Config File
    local success, config, err = handleConfigFile(Files.settings, autobind_defaultSettings, autobind, ignoreKeys)
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
    for _, path in pairs({Paths.config, Paths.resource, Paths.settings, Paths.skins}) do
        createDirectory(path)
    end

	-- Load Configs
	loadConfigs()

	-- Wait for SAMP
    while not isSampAvailable() do wait(100) end

    -- Autobind Help
    sampRegisterChatCommand(scriptName .. ".help", function()
        formattedAddChatMessage("Autobind Help:")
        formattedAddChatMessage("/autobind - Opens the Autobind menu for configuration and settings.")
        formattedAddChatMessage("/autobind.font - Opens the Font menu for configuration and settings.")
        formattedAddChatMessage("/autobind.commands - Provides a list of available Autobind commands and their descriptions.")
        formattedAddChatMessage("/autobind.keybinds - Opens the Keybinds menu for configuration and settings.")
        formattedAddChatMessage("/autobind.listbinds - Lists all configured keybinds and their associated keys.")
        formattedAddChatMessage("/autobind.skins - Opens the Skins menu for selecting skins.")
        formattedAddChatMessage("/autobind.status - Displays the current status of all Autobind functions.")
    end)

    -- Register Menu Command
	sampRegisterChatCommand(scriptName, function()
		menu.settings.pageId = 1
		menu.settings.window[0] = not menu.settings.window[0]
    end)

    -- Keybinds Command
    sampRegisterChatCommand(scriptName .. ".keybinds", function()
        menu.keybinds.window[0] = not menu.keybinds.window[0]
    end)

    -- Font Command
    sampRegisterChatCommand(scriptName .. ".font", function()
        menu.fonts.window[0] = not menu.fonts.window[0]
    end)

    -- Commands
    sampRegisterChatCommand(scriptName .. ".commands", function()
        formattedAddChatMessage("Commands:")
        for _, command in pairs(cmds) do
            formattedAddChatMessage(string.format("/%s - {%06x}%s.", command.cmd, clr.GREY, command.desc))
        end
    end)

    -- List Keybinds
    sampRegisterChatCommand(scriptName .. ".listbinds", function()
        -- Collect keybinds into a sortable table
        local keybindsList = {}
        for bind, _ in pairs(autobind.Keybinds) do
            table.insert(keybindsList, bind)
        end

        -- Sort the keybinds alphabetically
        table.sort(keybindsList)

        -- Display sorted keybinds
        for _, bind in ipairs(keybindsList) do
            local keybindMessage = string.format(
                "{%06x}Keybind: {%06x}%s{%06x}, Enabled: {%06x}%s{%06x}, Keys: {%06x}%s.", 
                clr.WHITE, 
                clr.YELLOW, 
                bind, 
                clr.WHITE, 
                autobind.Keybinds[bind].Toggle and clr.GREEN or clr.RED, 
                autobind.Keybinds[bind].Toggle and "Yes" or "No", 
                clr.WHITE, 
                clr.LIGHTBLUE, 
                getKeybindKeys(bind)
            )
            formattedAddChatMessage(keybindMessage)
        end
    end)

    -- Skins Editor
    sampRegisterChatCommand(scriptName .. ".skins", function()
        menu.skins.window[0] = not menu.skins.window[0]
    end)

    -- Status Command
    sampRegisterChatCommand(scriptName .. ".status", statusCommand)

	-- Black Market Command
	sampRegisterChatCommand("bms", function()
		menu.blackmarket.pageId = 1
		menu.blackmarket.window[0] = not menu.blackmarket.window[0]
	end)

    sampRegisterChatCommand("getskin", function(params)
        local playerId = tonumber(params)
        local result, peds = sampGetCharHandleBySampPlayerId(playerId)
        if result then
            formattedAddChatMessage(string.format("Skin ID: %d", getCharModel(peds)))
        end
    end)

	-- Register Chat Commands
	if autobind.Settings.enable then
		registerChatCommands()
	end

    -- Set Vest Timer
    timers.Vest.timer =  autobind.AutoVest.Donor and ddguardTime or guardTime

    -- Initial Menu Update
    updateButton1Tooltips()
    updateButton2Labels()

    -- Create Fonts
    createFonts()

    -- Initialize Timers
    for _, timer in pairs(timers) do
        if type(timer.last) == "number" then
            timer.last = localClock() - timer.timer
        end
        if type(timer.sentTime) == "number" then
            timer.sentTime = localClock() - timer.timeOut
        end
    end

    -- Initialize Key Functions (Black Market)
    InitializeBlackMarketKeyFunctions()

    -- Initialize Key Functions (Faction Locker)
    InitializeFactionLockerKeyFunctions()

    -- Main Loop
    while true do wait(0)
        -- Check if not connected to the server
        if sampGetGamestate() ~= 3 then
            -- Reset accepter and bodyguard if not in game
            if accepter.playerName ~= "" and accepter.playerId ~= -1 then
                accepter.playerName = ""
                accepter.playerId = -1
            end
            if bodyguard.playerName ~= "" and bodyguard.playerId ~= -1 then
                bodyguard.playerName = ""
                bodyguard.playerId = -1
            end
        end

        -- Start Functions Loop
        functionsLoop(function(started, failed)
            -- Success/Failed Messages
            formattedAddChatMessage(string.format("{%06x}%s has loaded successfully! {%06x}Type /%s.help for more information.", clr.WHITE, scriptVersion, clr.GREY, scriptName))

            if autobind.Settings.updateInProgress then
                formattedAddChatMessage(string.format("You have successfully upgraded from Version: %s to %s", autobind.Settings.lastVersion, scriptVersion))
                autobind.Settings.updateInProgress = false
                saveConfigWithErrorHandling(Files.settings, autobind)
            end

            if autobind.Settings.CheckForUpdates then 
                checkForUpdate() 
            end

            -- Fetch Skins
            if autobind.AutoVest.autoFetchSkins then
                fetchDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
                    if decodedData then
                        autobind.AutoVest.skins = decodedData
                        family.skins = listToSet(autobind.AutoVest.skins)
                    end
                end)
            else
                family.skins = listToSet(autobind.AutoVest.skins)
            end

            -- Fetch Names
            if autobind.AutoVest.autoFetchNames then
                fetchDataDirectlyFromURL(autobind.AutoVest.namesUrl, function(decodedData)
                    if decodedData then
                        autobind.AutoVest.names = decodedData
                        names = listToSet(autobind.AutoVest.names)
                    end
                end)
            else
                names = listToSet(autobind.AutoVest.names)
            end

            -- Generate Skins URLs
            skinsUrls = generateSkinsUrls()

            -- Download Skins
            downloadSkins(skinsUrls)

            -- Set Initialised to true
            menu.initialized[0] = true
        end)
    end
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
local function vestModeConditions(playerId, skinId)
    -- Check if vesting is allowed for everyone
    if autobind.AutoVest.everyone then
        return true
    end

    -- Check if the player's name is in the priority names list
    if names[sampGetPlayerNickname(playerId)] then
        return true
    end

    -- Check conditions based on the current mode
    local mode = autobind.Settings.mode
    if mode == "Family" then
        return family.skins[skinId] ~= nil
    elseif mode == "Faction" then
        local playerColor = sampGetPlayerColor(playerId)
        return factions.colors[playerColor] and (not autobind.AutoVest.useSkins or factions.skins[skinId]) ~= nil
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
        if currentTime - timers.Vest.sentTime > timers.Vest.timeOut then
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
            if checkAnimationCondition(player.playerId) and vestModeConditions(player.playerId, player.skinId) then
                sampSendChat(autobind.AutoVest.donor and '/guardnear' or string.format("/guard %d %d", player.playerId, autobind.AutoVest.price))
                bodyguard.received = true
                timers.Vest.sentTime = currentTime
                return
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

-- Check if player is in location
function isPlayerInLocation(locations)
    -- Adjustable Z axis limits
    local zTopLimit = 0.7  -- Top limit of the Z axis
    local zBottomLimit = -0.7  -- Bottom limit of the Z axis

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

-- Check if player has item
function playerHasItem(item)
    if item.weapon then -- Check if item is a weapon
        return hasCharGotWeapon(ped, item.weapon)
    elseif item.label == 'Baton/Mace' then -- Check if item is a baton or mace
        return hasCharGotWeapon(ped, 3) or hasCharGotWeapon(ped, 41)
    elseif item.label == 'Health' then -- Check full health
        return getCharHealth(ped) - 5000000 == 100
    elseif item.label == 'Armor' then -- Check full armor
        return getCharArmour(ped) == 100
    elseif item.label == 'Health/Armor' then -- Check full health and armor
        local health = getCharHealth(ped) - 5000000
        local armor = getCharArmour(ped)
        return health == 100 and armor == 100
    end
    return false
end

-- Check if player can obtain item
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

    -- Obtain item
    return true
end

-- Reset Locker
function resetLocker(locker)
    locker.getItemFrom = 0
    locker.gettingItem = false
    locker.currentKey = nil
end

-- Handle Black Market
function handleBlackMarket(kitNumber)
    if checkMuted() then
        formattedAddChatMessage(("{%06x}You have been muted for spamming, please wait."):format(clr.YELLOW))
        resetLocker(blackMarket)
        return
    end

    if not isPlayerInLocation(autobind.BlackMarket.Locations) then
        formattedAddChatMessage(("{%06x}You are not at the black market!"):format(clr.GREY))
        resetLocker(blackMarket)
        return
    end

    if not isPlayerControlOn(h) then
        formattedAddChatMessage(("{%x}You cannot get items while frozen, please wait."):format(clr.YELLOW))
        resetLocker(blackMarket)
        return
    end

    -- Check if the user can heal
	if checkHeal() then
		local timeLeft = math.ceil(timers.Heal.timer - (currentTime - timers.Heal.last))
		return string.format("You must wait %d seconds before getting items.", timeLeft > 1 and timeLeft or 1)
	end

    blackMarket.getItemFrom = kitNumber
    blackMarket.obtainedItems = {} -- Reset obtained items

    lua_thread.create(function()
        local items = autobind.BlackMarket["Kit" .. kitNumber]
        local itemCount = 0
        local skippedItems = {}
        for _, itemIndex in ipairs(items) do
            local item = blackMarket.Items[itemIndex]
            if item then
                if canObtainItem(item, blackMarket.Items) then
                    blackMarket.currentKey = item.index
                    blackMarket.gettingItem = true
                    sampSendChat("/bm")
                    repeat wait(0) until not blackMarket.gettingItem
                    table.insert(blackMarket.obtainedItems, item.label)
                    itemCount = itemCount + 1
                    if itemCount % 3 == 0 then
                        wait(math.random(1500, 1750))
                    end
                else
                    table.insert(skippedItems, item.label)
                end
            end
        end
        -- Send consolidated message at the end
        if #blackMarket.obtainedItems > 0 then
            formattedAddChatMessage(string.format("{%06x}Obtained items: {%06x}%s.", clr.YELLOW, clr.WHITE, table.concat(blackMarket.obtainedItems, ", ")))
        end
        if #skippedItems > 0 then
            formattedAddChatMessage(string.format("{%06x}Skipped items: {%06x}%s.", clr.YELLOW, clr.WHITE, table.concat(skippedItems, ", ")))
        end
        resetLocker(blackMarket)
    end)
end

-- Handle Faction Locker
function handleFactionLocker(kitNumber)
    if checkMuted() then
        formattedAddChatMessage(("{%06x}You have been muted for spamming, please wait."):format(clr.YELLOW))
        resetLocker(factionLocker)
        return
    end

    if not isPlayerInLocation(autobind.FactionLocker.Locations) then
        formattedAddChatMessage(("{%06x}You are not at the faction locker!"):format(clr.GREY))
        resetLocker(factionLocker)
        return
    end

    if not isPlayerControlOn(h) then
        formattedAddChatMessage(("{%06x}You cannot get items while frozen, please wait."):format(clr.YELLOW))
        resetLocker(factionLocker)
        return
    end

    -- Check if the user can heal
	if checkHeal() then
		local timeLeft = math.ceil(timers.Heal.timer - (currentTime - timers.Heal.last))
		return string.format("You must wait %d seconds before getting items.", timeLeft > 1 and timeLeft or 1)
	end

    factionLocker.getItemFrom = kitNumber
    factionLocker.obtainedItems = {} -- Reset obtained items

    lua_thread.create(function()
        local items = autobind.FactionLocker["Kit" .. kitNumber]
        local itemCount = 0
        local skippedItems = {}
        for _, itemIndex in ipairs(items) do
            local item = factionLocker.Items[itemIndex]
            if item then
                if canObtainItem(item, factionLocker.Items) then
                    factionLocker.currentKey = item.index
                    factionLocker.gettingItem = true
                    sampSendChat("/locker")
                    repeat wait(0) until not factionLocker.gettingItem
                    table.insert(factionLocker.obtainedItems, item.label)
                    itemCount = itemCount + 1
                    if itemCount % 3 == 0 then
                        wait(math.random(1500, 1750))
                    end
                else
                    table.insert(skippedItems, item.label)
                end
            end
        end
        -- Send consolidated message at the end
        if #factionLocker.obtainedItems > 0 then
            formattedAddChatMessage(string.format("{%06x}Obtained items: {%06x}%s.", clr.YELLOW, clr.WHITE, table.concat(factionLocker.obtainedItems, ", ")))
        end
        if #skippedItems > 0 then
            formattedAddChatMessage(string.format("{%06x}Skipped items: {%06x}%s.", clr.YELLOW, clr.WHITE, table.concat(skippedItems, ", ")))
        end
        resetLocker(factionLocker)
    end)
end

-- Key Functions
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
    BikeBind = function()
        if not isCharOnAnyBike(ped) or not autobind.Keybinds.BikeBind.Toggle then
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
        autobind.Keybinds.SprintBind.Toggle = toggleBind("SprintBind", autobind.Keybinds.SprintBind.Toggle)
    end,
    Frisk = function()
        if checkAdminDuty() or checkMuted() then
            return
        end

        local frisk = autobind.Settings.Frisk
        local targeting = getCharPlayerIsTargeting(h)
        for _, player in ipairs(getVisiblePlayers(5, "all")) do
            if (isButtonPressed(h, gkeys.player.LOCKTARGET) and frisk.mustAim) or not frisk.mustAim then
                if (targeting and frisk.mustTarget) or not frisk.mustTarget then
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
    AcceptDeath = function()
        sampSendChat("/accept death")
    end,
    RequestBackup = function()
        if checkAdminDuty() or checkMuted() then
            return
        end

        if backup.enable then
            sampSendChat("/nobackup")
            return
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
    end
}

-- Initialize Key Functions (Black Market)
function InitializeBlackMarketKeyFunctions()
    for i = 1, autobind.Settings.currentBlackMarketKits do
        if keyFunctions["BlackMarket" .. i] == nil then
            keyFunctions["BlackMarket" .. i] = function() handleBlackMarket(i) end
        end
    end
end

-- Initialize Key Functions (Faction Locker)
function InitializeFactionLockerKeyFunctions()
    for i = 1, autobind.Settings.currentFactionLockerKits do
        if keyFunctions["FactionLocker" .. i] == nil then
            keyFunctions["FactionLocker" .. i] = function() handleFactionLocker(i) end
        end
    end
end

-- Reset Key Functions
function resetLockersKeyFunctions()
    for i = 1, maxKits do
        keyFunctions["BlackMarket" .. i] = nil
        keyFunctions["FactionLocker" .. i] = nil
    end

    -- Reset Max Kits
    autobind.Settings.currentBlackMarketKits = 3
    autobind.Settings.currentFactionLockerKits = 3
end

-- Keybinds
function createKeybinds()
    local currentTime = localClock()
    for key, value in pairs(autobind.Keybinds) do
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

function getZoneName(x, y, z)
	return getGxtText(getNameOfZone(x, y, z))
end

local subZones = {
    GAN1 = 'Grove Street', GAN2 = "Apartments", IWD1 = 'Freeway', IWD2 = 'Drug Den', IWD3A = 'Gas Station', IWD3B = 'Maximus Club',
    IWD4 = 'Ghetto Area', IWD5 = 'Pizza', LMEX1A = "South", LMEX1B = "North", ELS1A = "Crack Lab", ELS1B = "Pig Pen", ELS2 = "Apartments", 
    ELS3A = "The Court", ELS3C = "Alleyway", ELS4 = "Carwash", ELCO1 = "Unity Station", ELCO2 = "Apartments", ELCO1 = "Unity Station", 
    ELCO2 = "Apartments", UNITY = "Traintracks", LIND1A = "West", LIND2B = "South", LIND1A = "North", LIND2A = "South", LIND3 = "East"
}

function getSubZoneName(x, y, z)
    return subZones[getNameOfInfoZone(x, y, z)] or nil
end

-- Toggle Capture Spam
function toggleCaptureSpam()
	if not checkAdminDuty() then
		captureSpam = not captureSpam

        local strBegin = string.format("{%06x}Starting capture attempt... {%06x}(type /%s to toggle)", clr.WHITE, clr.YELLOW, cmds.tcap.cmd)
        local strEnd = string.format("{%06x}Capture spam ended.", clr.WHITE)
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
    -- Check if the autobind is enabled
    if not autobind.Settings.enable then
        return
    end

    -- Check if the game is in the correct state
    if sampGetGamestate() ~= 3 then
        gzData = nil
        return
    end

    -- Get Gangzone Pool
    if not gzData then
        gzData = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
        return
    end

    -- Check if the mode is Family
    if autobind.Settings.mode ~= "Family" then
        return
    end

    -- Loop through all gangzones
    for i = 0, 1023 do
        if gzData.iIsListed[i] ~= 0 and gzData.pGangzone[i] ~= nil then
            local pos = gzData.pGangzone[i].fPosition
            local color = gzData.pGangzone[i].dwColor
            local ped_pos = { getCharCoordinates(ped) }
            
            local min1, max1 = math.min(pos[0], pos[2]), math.max(pos[0], pos[2])
            local min2, max2 = math.min(pos[1], pos[3]), math.max(pos[1], pos[3])
            
            if i >= 34 and i <= 45 then
                if ped_pos[1] >= min1 and ped_pos[1] <= max1 and ped_pos[2] >= min2 and ped_pos[2] <= max2 and color == family.turfColor then
                    enteredPoint = true
                    break
                else
                    if enteredPoint then
                        timers.Point.last = localClock()
                        preventHeal = true
                    end
                    enteredPoint = false
                end
            end
        end
    end
end

function createAutoFind()
    if not autobind.Settings.enable then
        return
    end

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

function createSprunkSpam()
    -- Return if not using sprunk
    if not usingSprunk then
        return
    end

    if isButtonPressed(h, 15) then
        usingSprunk = false
        return
    end

    -- Return if already full health and drop the sprunk
    local health = getCharHealth(ped) - 5000000
    if health == 100 then
        local key = gkeys.player.ENTERVEHICLE
        setGameKeyState(key, 255)
        wait(0)
        setGameKeyState(key, 0)
        usingSprunk = false
        return
    end
    
    -- Return if not connected
    local result, playerId = sampGetPlayerIdByCharHandle(ped)
    if not result then
        return
    end

    -- Return if not enough time has passed
    local currentTime = localClock()
    if currentTime - timers.Sprunk.last < timers.Sprunk.timer then
        return
    end

    -- Use the sprunk
    if sampGetPlayerSpecialAction(playerId) == 23 then
        local key = gkeys.player.FIREWEAPON
        setGameKeyState(key, 255)
        wait(0)
        setGameKeyState(key, 0)
        timers.Sprunk.last = currentTime
    end
end

--- Functions (DownloadManager, AutoVest, AutoAccept, Keybinds, CaptureSpam, PointBounds, AutoFind, SprunkSpam)
-- Functions Table
local functionsToRun = {
    {
        name = "DownloadManager",
        func = function()
            if downloadManager and (downloadManager.isDownloading or downloadManager.isFetching) then
                downloadManager:updateDownloads()
            end
        end,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "AutoVest",
        func = function()
            checkAndSendVest(false)
        end,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "AutoAccept",
        func = function() 
            checkAndAcceptVest(accepter.enable)
        end,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "Keybinds",
        func = createKeybinds,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "CaptureSpam",
        func = createCaptureSpam,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "PointBounds",
        func = createPointBounds,
        interval = 1.5,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "AutoFind",
        func = createAutoFind,
        interval = 0,
        lastRun = localClock(),
        enabled = true
    },
    {
        name = "SprunkSpam",
        func = createSprunkSpam,
        interval = 0.01,
        lastRun = localClock(),
        enabled = true
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

-- Status Command
function statusCommand()
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

    -- Running Functions
    if #started > 0 then
        formattedAddChatMessage(string.format("{%06x}Running Functions: {%06x}%s.", clr.WHITE, clr.GREEN, table.concat(started, ", ")))
        
        if #failed > 0 then
            formattedAddChatMessage(string.format("{%06x}Failed Functions: {%06x}%s.", clr.WHITE, clr.RED, table.concat(failed, ", ")))
        end
    else
        formattedAddChatMessage("None of the functions are running.")
    end

    -- Autobind Status
    local mode = autobind.Settings.mode
    local typeMessage = string.format("{%06x}, Type: {%06x}%s", clr.WHITE, clr.YELLOW, autobind.Settings.Faction.type)
    local captureMessage = string.format("{%06x}, Capture Spam: {%06x}%s", clr.WHITE, captureSpam and clr.GREEN or clr.RED, captureSpam and "Yes" or "No")
    local sprunkMessage = string.format("{%06x}, Using Sprunk: {%06x}%s", clr.WHITE, usingSprunk and clr.GREEN or clr.RED, usingSprunk and "Yes" or "No")
    local pointMessage = string.format("{%06x}, Point Bounds: {%06x}%s", clr.WHITE, enteredPoint and clr.GREEN or clr.RED, enteredPoint and "Yes" or "No")
    local preventHealMessage = string.format("{%06x}, Prevent Heal Timer: {%06x}%s", clr.WHITE, preventHeal and clr.GREEN or clr.RED, preventHeal and "Yes" or "No")
    formattedAddChatMessage(string.format("{%06x}Mode: {%06x}%s %s%s%s%s{%06x}.", clr.WHITE, clr.YELLOW, mode, mode == "Faction" and typeMessage or pointMessage, captureMessage, sprunkMessage, preventHealMessage, clr.WHITE))

    -- Bodyguard Status
    local bodyguardName = string.format("{%06x}%s (%d)", bodyguard.playerName == "" and clr.RED or clr.GREEN, bodyguard.playerName == "" and "N/A" or bodyguard.playerName, bodyguard.playerId)
    local bodyguardMessage = string.format(
        "{%06x}Bodyguard: {%06x}%s{%06x}, AutoVest: {%06x}%s{%06x}, Job: {%06x}%s{%06x} (If Donor is 'Yes' this is ignored), Donor Mode: {%06x}%s{%06x}, Received: {%06x}%s{%06x}, Price: {%06x}$%d{%06x}.",
        clr.WHITE, 
        clr.GREY,
        bodyguardName,
        clr.WHITE,
        autobind.AutoVest.enable and clr.GREEN or clr.RED,  -- Use GREEN for "Yes", RED for "No"
        autobind.AutoVest.enable and "Yes" or "No",
        clr.WHITE,  -- Reapply original color
        bodyguard.enable and clr.GREEN or clr.RED,  -- Use GREEN for "Yes", RED for "No"
        bodyguard.enable and "Yes" or "No",
        clr.WHITE,  -- Reapply original color
        autobind.AutoVest.Donor and clr.GREEN or clr.RED,  -- Use GREEN for "Yes", RED for "No"
        autobind.AutoVest.Donor and "Yes" or "No",
        clr.WHITE,   -- Reapply original color
        bodyguard.received and clr.GREEN or clr.RED,  -- Use GREEN for "Yes", RED for "No"
        bodyguard.received and "Yes" or "No",
        clr.WHITE,
        clr.LIGHTBLUE,
        bodyguard.price,
        clr.WHITE
    )
    formattedAddChatMessage(bodyguardMessage)

    -- Accepter Status
    local accepterName = string.format("{%06x}%s (%d)", accepter.playerName == "" and clr.RED or clr.GREEN, accepter.playerName == "" and "N/A" or accepter.playerName, accepter.playerId)
    local accepterMessage = string.format(
        "{%06x}Accepter: {%06x}%s{%06x}, Auto Accepter: {%06x}%s{%06x}, Received: {%06x}%s{%06x}, Price: {%06x}$%d{%06x}, accepterThread: {%06x}%s{%06x}.",
        clr.WHITE, 
        clr.GREY, 
        accepterName,
        clr.WHITE,
        accepter.enable and clr.GREEN or clr.RED, 
        accepter.enable and "Yes" or "No",
        clr.WHITE,
        accepter.received and clr.GREEN or clr.RED,
        accepter.received and "Yes" or "No",
        clr.WHITE,
        clr.LIGHTBLUE,
        accepter.price,
        clr.WHITE,
        accepterThread ~= nil and clr.GREEN or clr.RED,
        accepterThread ~= nil and "Yes" or "No",
        clr.WHITE
    )
    formattedAddChatMessage(accepterMessage)

    -- Autofind Status
    local autofindName = string.format("{%06x}%s (%d)", autofind.playerName == "" and clr.RED or clr.GREEN, autofind.playerName == "" and "N/A" or autofind.playerName, autofind.playerId)
    local autofindMessage = string.format(
        "{%06x}Autofind: {%06x}%s{%06x}, Enabled: {%06x}%s{%06x}, Counter: {%06x}%d{%06x}.",
        clr.WHITE,
        clr.GREY, 
        autofindName,
        clr.WHITE,
        autofind.enable and clr.GREEN or clr.RED, 
        autofind.enable and "Yes" or "No",
        clr.WHITE,
        clr.LIGHTBLUE,
        autofind.counter,
        clr.WHITE
    )
    formattedAddChatMessage(autofindMessage)

    -- Backup Status
    local backupName = string.format("{%06x}%s (%d)", backup.playerName == "" and clr.RED or clr.GREEN, backup.playerName == "" and "N/A" or backup.playerName, backup.playerId)
    local backupMessage = string.format(
        "{%06x}Backup: {%06x}%s{%06x}, Location: {%06x}%s{%06x}, [Enabled: {%06x}%s{%06x} (This is only for yourself)].",
        clr.WHITE, 
        clr.GREY, 
        backupName,
        clr.WHITE,
        backup.location ~= "" and clr.GREEN or clr.RED,
        backup.location ~= "" and backup.location or "N/A",
        clr.WHITE,
        backup.enable and clr.GREEN or clr.RED, 
        backup.enable and "Yes" or "No",
        clr.WHITE
    )
    formattedAddChatMessage(backupMessage)

    -- Timers
    local currentTime = localClock()
    for name, timer in pairs(timers) do
        local timerInfo = ""
        for fieldName, fieldValue in pairs(timer) do
            if fieldName == 'last' then
                if type(fieldValue) == "number" then
                    -- 'last' is a number; calculate elapsed time
                    local elapsedTime = currentTime - fieldValue
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:capitalizeFirst(), clr.GREY, formatTime(elapsedTime), clr.WHITE)
                elseif type(fieldValue) == "table" then
                    -- 'last' is a table; process each bind entry
                    local subTimerInfo = ""
                    for bindName, bindTime in pairs(fieldValue) do
                        if type(bindTime) == 'number' then
                            -- Calculate elapsed time for each bind
                            local elapsedTime = currentTime - bindTime
                            subTimerInfo = subTimerInfo .. string.format("%s: {%06x}%s{%06x}, ", bindName, clr.GREY, formatTime(elapsedTime), clr.WHITE)
                        end
                    end
                    -- Remove trailing comma and space
                    if #subTimerInfo > 0 then
                        subTimerInfo = subTimerInfo:sub(1, -3)
                    end
                    -- Include the subTimerInfo in the main timerInfo
                    timerInfo = timerInfo .. string.format("%s: {%s}, ", fieldName:capitalizeFirst(), subTimerInfo)
                end
            elseif fieldName == 'sentTime' then
                -- 'sentTime' processing
                if type(fieldValue) == "number" then
                    local elapsedTime = currentTime - fieldValue
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:capitalizeFirst(), clr.GREY, formatTime(elapsedTime), clr.WHITE)
                end
            elseif fieldName == 'timer' then
                -- 'timer' field
                if type(fieldValue) == 'number' then
                    -- If 'last' is a number, calculate time left
                    if type(timer.last) == 'number' then
                        local timeElapsed = currentTime - timer.last
                        local timeLeft = fieldValue - timeElapsed
                        timeLeft = math.max(timeLeft, 0)
                        timerInfo = timerInfo .. string.format("TimeLeft: {%06x}%s{%06x}, ", clr.GREY, formatTime(timeLeft), clr.WHITE)
                    else
                        -- 'last' is not a number; can't calculate time left
                        timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:capitalizeFirst(), clr.GREY, formatTime(fieldValue), clr.WHITE)
                    end
                end
            else
                -- Other fields
                if type(fieldValue) == 'number' then
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:capitalizeFirst(), clr.GREY, formatTime(fieldValue), clr.WHITE)
                end
            end
        end
        -- Remove trailing comma and space
        if #timerInfo > 0 then
            timerInfo = timerInfo:sub(1, -3)
        end
        formattedAddChatMessage(string.format("{%06x}%s: {%06x}%s{%06x}.", clr.WHITE, name, clr.WHITE, timerInfo, clr.WHITE))
    end
end

--- Register Chat Commands
function registerChatCommands()
    local CMD = sampRegisterChatCommand
    local config = autobind.Settings
    local autoVest = autobind.AutoVest
    local keyBinds = autobind.Keybinds

	CMD(cmds.vestnear.cmd, function()
        if not config.enable then
            return
        end

		local message = checkAndSendVest(true)
		if message then
			formattedAddChatMessage(message)
		end
	end)

	CMD(cmds.repairnear.cmd, function()
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
	
	CMD(cmds.find.cmd, function(params)
        if not config.enable then
            return
        end

		if checkMuted() then
            formattedAddChatMessage(string.format("You are muted, you cannot use the /%s command.", cmds.find.cmd))
            return
        end

		if string.len(params) < 1 then
            if autofind.enable then
                formattedAddChatMessage("You are no longer finding anyone.")
                autofind.enable = false
                autofind.playerName = ""
                autofind.playerId = -1
            else
				formattedAddChatMessage(string.format('USAGE: /%s [playerid/partofname]', cmds.find.cmd))
			end
            return
        end

		local result, playerid, name = findPlayer(params)
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
			formattedAddChatMessage(string.format("Now finding: {%06x}%s (ID %d).", clr.REALGREEN, name:gsub("_", " "), playerid))
            return
		end

		autofind.enable = true
		formattedAddChatMessage(string.format("Finding: {%06x}%s (ID %d). {%06x}Type /%s again to toggle off.", clr.REALGREEN, autofind.playerName:gsub("_", " "), autofind.playerId, clr.WHITE, cmds.find.cmd))
	end)

	CMD(cmds.tcap.cmd, function()
        if not config.enable then
            return
        end

		toggleCaptureSpam()
	end)

	CMD(cmds.sprintbind.cmd, function()
        if not config.enable then
            return
        end

		keyBinds.SprintBind.Toggle = toggleBind("SprintBind", keyBinds.SprintBind.Toggle)
	end)

	CMD(cmds.bikebind.cmd, function()
        if not config.enable then
            return
        end

		keyBinds.BikeBind.Toggle = toggleBind("BikeBind", keyBinds.BikeBind.Toggle)
	end)

	CMD(cmds.autovest.cmd, function()
        if not config.enable then
            return
        end

        autoVest.enable = toggleBind("Automatic Vest", autoVest.enable)
	end)

	CMD(cmds.autoaccept.cmd, function()
        if not config.enable then
            return
        end

        accepter.enable = toggleBind("Auto Accept", accepter.enable)
	end)

	CMD(cmds.ddmode.cmd, function()
        if not config.enable then
            return
        end

        autoVest.donor = toggleBind("DD Vest Mode", autoVest.donor)

		timers.Vest.timer = autoVest.donor and ddguardTime or guardTime
	end)

    CMD(cmds.sprunkspam.cmd, function()
        if not config.enable then
            return
        end

        if checkMuted() then
            formattedAddChatMessage(string.format("You are muted, you cannot use the /%s command.", cmds.sprunkspam.cmd))
            return
        end

        if checkHeal() then
            formattedAddChatMessage(string.format("You have been attacked recently, you cannot use the /%s command.", cmds.sprunkspam.cmd))
            return
        end

        local health = getCharHealth(ped) - 5000000
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
    end)
end

function toggleBind(name, bool)
    bool = not bool
    local color = bool and clr.REALGREEN or clr.RED
    formattedAddChatMessage(string.format("%s: {%06x}%s", name, color, bool and 'on' or 'off'))
    return bool
end

-- OnScriptTerminate
function onScriptTerminate(scr, quitGame)
	if scr == script.this then
        if autobind.Settings.autoSave then
            saveConfigWithErrorHandling(Files.settings, autobind)
        end

		-- Unregister chat commands
		for _, command in pairs(cmds) do
			sampUnregisterChatCommand(command)
		end
	end
end

-- Message Handlers (OnServerMessage)
local messageHandlers = {
    -- Time Change (Auto Capture)
    {
        pattern = "^The time is now (%d+):(%d+)%.$", -- The time is now 22:00.
        color = clrRGBA["WHITE"],
        action = function(hour, minute)
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
            
            if hour and minute then
                sampAddChatMessage(string.format("The time is now %s:%s.", hour, minute), -1)
                return false
            end
        end
    },
    -- Muted Message
    {
        pattern = "^You have been muted automatically for spamming%. Please wait 10 seconds and try again%.",
        color = clrRGBA["YELLOW"],
        action = function()
            timers.Muted.last = localClock()
        end
    },
    -- Admin On-Duty
    {
        pattern = '^You are now on%-duty as admin and have access to all your commands, see /ah.$',
        color = clrRGBA["YELLOW"],
        action = function()
            setSampfuncsGlobalVar("aduty", 1)
        end
    },
    -- Admin Off-Duty
    {
        pattern = '^You are now off%-duty as admin, and only have access to /admins /check /jail /ban /sban /kick /skick /showflags /reports /nrn$',
        color = clrRGBA["YELLOW"],
        action = function()
            setSampfuncsGlobalVar("aduty", 0)
        end
    },
    -- ARES Radio
    {
        pattern = "^%*%*%s*(.-):%s*(.-)%s*%*%*$",
        color = clrRGBA["RADIO"],
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
                local divOrRank = skipDiv and rank or string.format("%s %s", div, rank)
                sampAddChatMessage(string.format("{%06x}** %s %s (%d): {%06x}%s", clr.ARES, divOrRank, playerName, playerId, clr.WHITE, message), -1)
                return false
            end
        end
    },
    -- Mode/Frequency
    {
        pattern = "^([Family|LSPD|SASD|FBI|ARES|GOV|LSFMD].+) MOTD: (.+)",
        color = clrRGBA["YELLOW"],
        action = function(type, motdMsg)
            local config = autobind.Settings
            if type:match("Family") then
                config.mode = type
                updateButton2Labels()
                saveConfigWithErrorHandling(Files.settings, autobind)

                --[[local freq, allies = motdMsg:match("[Ff]req:?%s*(-?%d+)%s*[/%s]*[Aa]llies:?%s*([^,]+)")
                if freq and allies then
                    print("Frequency detected", freq)
                    currentFamilyFreq = freq

                    print("Allies detected", allies)

                    local newMessage = motdMsg:gsub("[Ff]req:?%s*(-?%d+)", "")
                    newMessage = newMessage:gsub("^%s*,%s*", "")
                    print("New message: " .. newMessage)

                    sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr.DEPTRADIO, type, newMessage), -1)
                    return false
                end

                -- Family MOTD: F: -3232 A: LS.
                -- Family MOTD: F: -3232 // A: TC // discord.gg/GYwedAXGzV // MASS RECRUIT!.

                local freq2, allies2 = motdMsg:match("F: -3232 // A: TC // discord.gg/GYwedAXGzV // MASS RECRUIT!.")
                if freq2 and allies2 then

                end]]

                sampAddChatMessage(string.format("{%06x}Family MOTD: %s", clr.DEPTRADIO, motdMsg), -1)
                return false
            elseif type:match("[LSPD|SASD|FBI|ARES|GOV]") then
                config.mode = "Faction"
                config.Faction.type = type
                updateButton2Labels()
                saveConfigWithErrorHandling(Files.settings, autobind)
                if accepter.enable then
                    formattedAddChatMessage("Auto Accept is now disabled because you are now in Faction Mode.")
                    accepter.enable = false
                end

                --[[local freqType, freq = motdMsg:match("[/|%s*]%s*([RL FREQ:|FREQ:].-)%s*(-?%d+)")
                if freqType and freq then
                    print("Faction frequency detected: " .. freq)
                    currentFactionFreq = freq

                    local newMessage = motdMsg:gsub(freqType .. "%s*" .. freq:gsub("%-", "%%%-") .. "%s*", "")
                    newMessage = newMessage:gsub("%s*/%s*/%s*", " / ")

                    sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr.DEPTRADIO, type, newMessage), -1)
                    return false
                end]]

                sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr.DEPTRADIO, type, motdMsg), -1)
                return false
            elseif type:match("LSFMD") then
                config.mode = "Faction"
                config.Faction.type = type
                updateButton2Labels()
                saveConfigWithErrorHandling(Files.settings, autobind)

                sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr.DEPTRADIO, type, motdMsg), -1)
                return false
            end
        end
    },
    -- Set Frequency Message
    {
        pattern = "You have set the frequency of your portable radio to (-?%d+) kHz.",
        color = clrRGBA["WHITE"],
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
                formattedAddChatMessage(string.format("You have set the frequency to your {%06x}%s {%06x}portable radio.", clr.DEPTRADIO, config.mode, clr.WHITE))
                return false
            end
        end
    },
    -- Radio Message
    {
        pattern = "%*%* Radio %((%-?%d+) kHz%) %*%* (.-): (.+)",
        color = clrRGBA["PUBLICRADIO_COLOR"],
        action = function(freq, playerName, message)
            local playerId = sampGetPlayerIdByNickname(playerName:gsub("%s+", "_"))
            sampAddChatMessage(string.format("{%06x}** %s Radio ** {%06x}%s (%d){%06x}: %s", clr.PUBLICRADIO_COLOR, autobind.Settings.mode, sampGetPlayerColor(playerId), playerName, playerId, clr.PUBLICRADIO_COLOR, message), -1)
            return false
        end
    },
    -- Capture Spam Disabled
    {
        pattern = "^Your gang is already attempting to capture this turf%.$",
        color = clrRGBA["GRAD1"],
        action = function()
            if captureSpam then
                local mode = autobind.Settings.mode
                formattedAddChatMessage(string.format("{%06x}Your %s is already attempting to capture this turf, disabling capture spam.", clr.GRAD1, mode:lower()))
                captureSpam = false
                return false
            end
        end
    },
    -- Turf Not Ready
    {
        pattern = "This turf is not ready for takeover yet.",
        color = clrRGBA["GRAD1"],
        action = function()
            if captureSpam then
                captureSpam = false

                formattedAddChatMessage(string.format("{%06x}This turf is not ready for takeover yet, disabling capture spam.", clr.GRAD1))
                return false
            end
        end
    },
    -- Bodyguard Not Near (Same as other commands not sure what i wanna do yet)
    {
        pattern = "That player isn't near you%.$",
        color = clrRGBA["GREY"],
        action = function()
            if bodyguard.received then
                bodyguard.received = false
                resetTimer(1.0, timers.Vest)
            end

            sampAddChatMessage(string.format("{%06x}That player isn't near you.", clr.GREY), -1)
            return false
        end
    },
    -- Can't Guard While Aiming
    {
        pattern = "You can't /guard while aiming%.$",
        color = clrRGBA["GREY"],
        action = function()
            if bodyguard.received then
                bodyguard.received = false
                resetTimer(1.0, timers.Vest)

                sampAddChatMessage(string.format("{%06x}You can't /guard while aiming.", clr.GREY), -1)
                return false
            end
        end
    },
    -- Must Wait Before Selling Vest
    {
        pattern = "You must wait (%d+) seconds? before selling another vest%.?",
        color = clrRGBA["GREY"],
        action = function(cooldown)
            if autobind.AutoVest.enable then
                cooldown = tonumber(cooldown)
                bodyguard.received = false
                resetTimer(cooldown + 0.5, timers.Vest)

                if cooldown > 1 then
                    sampAddChatMessage(string.format("{%06x}You must wait %s seconds before selling another vest.", clr.GREY, cooldown), -1)
                end
                return false
            end
        end
    },
    -- Offered Protection
    {
        pattern = "%* You offered protection to (.+) for %$([%d,]+)%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            bodyguard.playerName = nickname:gsub("%s+", "_")
            bodyguard.playerId = sampGetPlayerIdByNickname(bodyguard.playerName)

            -- Remove commas from the price string
            local cleanPrice = price:gsub(",", "")
            bodyguard.price = tonumber(cleanPrice)

            if bodyguard.received then
                bodyguard.received = false
                timers.Vest.last = localClock()
            end

            if bodyguard.playerName ~= "" and bodyguard.playerId ~= -1 then
                sampAddChatMessage(string.format("{%06x}* You offered protection to %s (%d) for $%s.", clr.LIGHTBLUE, nickname, bodyguard.playerId, price), -1)
                return false
            end
        end
    },
    -- Not a Bodyguard
    {
        pattern = "You are not a bodyguard%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autobind.AutoVest.enable then
                bodyguard.enable = false
                bodyguard.playerName = ""
                bodyguard.playerId = -1
                bodyguard.received = false

                sampAddChatMessage(string.format("{%06x}You are not a bodyguard, disabling autovest.", clr.GREY), -1)
                return false
            end
        end
    },
    -- Now a Bodyguard
    {
        pattern = "%* You are now a Bodyguard, type %/help to see your new commands%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autobind.AutoVest.enable then
                bodyguard.enable = true
                bodyguard.received = false

                sampAddChatMessage(string.format("{%06x}You are now a bodyguard, enabling autovest.", clr.LIGHTBLUE), -1)
                return false
            end
        end
    },
    -- Accept Vest
    {
        pattern = "You are not near the person offering you guard!",
        color = clrRGBA["GRAD2"],
        action = function()
            if accepter.received and accepter.playerName ~= "" and accepter.playerId ~= -1 then
                if accepter.enable then
                    accepter.received = false
                end

                sampAddChatMessage(string.format("{%06x}You are not close enough to %s (%d).", clr.GRAD2, accepter.playerName:gsub("_", " "), accepter.playerId), -1)
                return false
            end
        end
    },
    -- Protection Offer
    {
        pattern = "^%* Bodyguard (.+) wants to protect you for %$([%d,]+)%, type %/accept bodyguard to accept%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            accepter.playerName = nickname:gsub("%s+", "_")
            accepter.playerId = sampGetPlayerIdByNickname(accepter.playerName)
            
            -- Remove commas from the price string
            local cleanPrice = price:gsub(",", "")
            accepter.price = tonumber(cleanPrice)

            accepterThread = lua_thread.create(function()
                wait(0)
                if accepter.price ~= 200 then
                    return
                end

                if getCharArmour(ped) < 49 and sampGetPlayerAnimationId(ped) ~= 746 and ((accepter.enable and not checkHeal()) or (accepter.enable and enteredPoint)) and not checkMuted() then
                    sampSendChat("/accept bodyguard")
                    wait(1000)
                end

                accepter.received = true
                accepterThread = nil
            end)

            if accepter.playerName ~= "" and accepter.playerId ~= -1 then
                local accept = autobind.Keybinds.Accept
                local acceptType = accept.Toggle and string.format("press %s to accept", getKeybindKeys("Accept")) or "type /accept bodyguard to accept"
                sampAddChatMessage(string.format("{%06x}* %s (%d) wants to protect you for $%s, %s.", clr.LIGHTBLUE, nickname, accepter.playerId, price, acceptType), -1)
                return false
            end
        end
    },
    -- You Accepted Protection
    {
        pattern = "^%* You accepted the protection for %$(%d+) from (.+)%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(price, nickname)

            if accepterThread and accepter.enable then
                accepterThread:terminate()
                accepterThread = nil
            end

            sampAddChatMessage(string.format("{%06x}* You accepted the protection for $%d from %s (%d).", clr.LIGHTBLUE, price, nickname, accepter.playerId), -1)
            accepter.playerName = ""
            accepter.playerId = -1
            accepter.received = false
            accepter.price = 0
            return false
        end
    },
    -- They Accepted Protection
    {
        pattern = "%* (.+) accepted your protection, and the %$(%d+) was added to your money.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            sampAddChatMessage(string.format("{%06x}* %s (%d) accepted your protection, and the $%d was added to your money.", clr.LIGHTBLUE, nickname, bodyguard.playerId, price), -1)
            bodyguard.playerName = ""
            bodyguard.playerId = -1
            bodyguard.received = false
            return false
        end
    },
    -- Can't Afford Protection
    {
        pattern = "You can't afford the Protection!",
        color = clrRGBA["GREY"],
        action = function()
            accepter.received = false

            sampAddChatMessage(string.format("{%06x}You can't afford the protection!", clr.GREY), -1)
            return false
        end
    },
    -- Can't Use Locker Recently Shot
    {
        pattern = "You can't use your lockers if you were recently shot.",
        color = clrRGBA["WHITE"],
        action = function()
            formattedAddChatMessage("You can't use your lockers if you were recently shot. Timer extended by 5 seconds.")
            resetTimer(5, timers.Heal)

            resetLocker(locker)
            return false
        end
    },
    -- Heal Timer Extended
    {
        pattern = "^You can't heal if you were recently shot, except within points, events, minigames, and paintball%.$",
        color = clrRGBA["WHITE"],
        action = function()
            formattedAddChatMessage("You can't heal after being attacked recently. Timer extended by 5 seconds.")
            resetTimer(5, timers.Heal)
            return false
        end
    },
    -- Not Diamond Donator
    {
        pattern = "^You are not a Diamond Donator%!",
        color = clrRGBA["GREY"],
        action = function()
            timers.Vest.timer = guardTime
            autobind.AutoVest.donor = false
        end
    },
    -- Not Sapphire or Diamond Donator
    {
        pattern = "^You are not a Sapphire or Diamond Donator%!",
        color = clrRGBA["GREY"],
        action = function()
            if blackMarket.getItemFrom > 0 then
                blackMarket.getItemFrom = 0
                blackMarket.gettingItem = false
            end
        end
    },
    -- Not at Black Market
    {
        pattern = "^%s*You are not at the black market%!",
        color = clrRGBA["GRAD2"],
        action = function()
            if blackMarket.getItemFrom > 0 then
                blackMarket.getItemFrom = 0
                blackMarket.gettingItem = false
            end
        end
    },
    -- Already Searched for Someone
    {
        pattern = "^You have already searched for someone %- wait a little%.$",
        color = clrRGBA["GREY"],
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
        color = clrRGBA["GREY"],
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
        color = clrRGBA["GREY"],
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
        pattern = "^%* You are now a Detective, type %/help to see your new commands%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function()
            if autofind.playerName ~= "" and autofind.playerId ~= -1 then
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                autofind.enable = true
                resetTimer(0.1, timers.Find)
                formattedAddChatMessage(string.format("You are now a detective and re-enabling autofind on %s (ID: %d).", autofind.playerName:gsub("_", " "), autofind.playerId))
                return false
            end
        end
    },
    -- Unable to Find Person
    {
        pattern = "^You are unable to find this person%.$",
        color = clrRGBA["GREY"],
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
    -- Your backup request has been cleared.
    {
        pattern = "^Your backup request has been cleared%.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            sampAddChatMessage(string.format("{%06x}Your backup request has been cleared.", clr.GRAD2), -1)
            return false
        end
    },
    -- You already have an active backup request!
    {
        pattern = "^You already have an active backup request!$",
        color = clrRGBA["GREY"],
        action = function()
            backup.enable = true
            sampAddChatMessage(string.format("{%06x}You already have an active backup request!", clr.GRAD2), -1)
            return false
        end
    },
    -- You don't have an active backup request!
    {
        pattern = "^You don't have an active backup request!$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            sampAddChatMessage(string.format("{%06x}You don't have an active backup request!", clr.GRAD2), -1)
            return false
        end
    },
    -- Your backup request has been cleared automatically.
    {
        pattern = "^Your backup request has been cleared automatically.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            sampAddChatMessage(string.format("{%06x}Your backup request has been cleared automatically.", clr.GRAD2), -1)
            return false
        end
    },
    -- Requesting immediate backup
    {
        pattern = "^(.+) is requesting immediate backup at (.+).$",
        color = clrRGBA["TEAM_BLUE_COLOR"],
        action = function(nickname, location)
            local playerId = sampGetPlayerIdByNickname(nickname:gsub("%s+", "_"))
            if playerId ~= -1 and location then
                sampAddChatMessage(string.format("{%06x}%s (%d) is requesting immediate backup at %s.", clr.TEAM_BLUE_COLOR, nickname, playerId, location), -1)

                local _, localPlayerId = sampGetPlayerIdByCharHandle(ped)
                if localPlayerId == playerId then
                    backup.enable = true
                else
                    backup.playerName = nickname
                    backup.playerId = playerId
                    backup.location = location
                end
                return false
            end
        end
    },
    -- You have cleared your beacon.
    {
        pattern = "^You have cleared your beacon.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            sampAddChatMessage(string.format("{%06x}You have cleared your beacon.", clr.GRAD2), -1)
            return false
        end
    },
    -- Your beacon has been cleared automatically.
    {
        pattern = "^Your beacon has been cleared automatically.$",
        color = clrRGBA["GRAD2"],
        action = function()
            backup.enable = false
            sampAddChatMessage(string.format("{%06x}Your beacon has been cleared automatically.", clr.GRAD2), -1)
            return false
        end
    },
    -- Requesting help
    {
        pattern = "^(.+) is requesting help at (.+).$",
        color = clrRGBA["YELLOW"],
        action = function(nickname, location)
            local playerId = sampGetPlayerIdByNickname(nickname:gsub("%s+", "_"))
            if playerId ~= -1 and location then
                sampAddChatMessage(string.format("{%06x}%s (%d) is requesting help at %s.", clr.YELLOW, nickname, playerId, location), -1)

                local _, localPlayerId = sampGetPlayerIdByCharHandle(ped)
                if localPlayerId == playerId then
                    backup.enable = true
                else
                    backup.playerName = nickname
                    backup.playerId = playerId
                    backup.location = location
                end
                return false
            end
        end
    },
    -- Accept Repair
    {
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
    -- Auto Badge
    {
        pattern = "^Your hospital bill comes to %$%d+%. Have a nice day%!",
        color = clrRGBA["TEAM_MED_COLOR"],
        action = function()
            if backup.enable then
                backup.enable = false
            end

            if autobind.Settings.Faction.autoBadge and not checkMuted() and not checkAdminDuty() then
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
        color = clrRGBA["YELLOW"],
        action = function()
            timers.Muted.last = localClock()
        end
    },
    -- Help Command Additions
    {
        pattern = "^%*%*%* OTHER %*%*%* /cellphonehelp /carhelp /househelp /toyhelp /renthelp /jobhelp /leaderhelp /animhelp /fishhelp /insurehelp /businesshelp /bankhelp",
        color = clrRGBA["WHITE"],
        action = function()
            lua_thread.create(function()
                wait(0)
                sampAddChatMessage(string.format("*** AUTOBIND *** /%s /%s /%s /%s /%s /%s /%s", scriptName, cmds.repairnear.cmd, cmds.find.cmd, cmds.tcap.cmd, cmds.sprintbind.cmd, cmds.bikebind.cmd, cmds.sprunkspam.cmd), -1)
                sampAddChatMessage(string.format("*** AUTOVEST *** /%s /%s /%s /%s", cmds.autovest.cmd, cmds.ddmode.cmd, cmds.autoaccept.cmd, cmds.vestnear.cmd), -1)
            end)
        end
    },
    -- * (.+) opens a can of sprunk.
    {
        pattern = "^%* (.+) opens a can of sprunk.$",
        color = clrRGBA["PURPLE"],
        action = function(nickname)
            sampAddChatMessage(string.format("{%06x}%s opens a can of sprunk.", clr.PURPLE, nickname), -1)
            usingSprunk = true
            return false
        end
    },
    -- Dropped Sprunk
    {
        pattern = "^(.+) drops their sprunk onto the floor.$",
        color = clrRGBA["PURPLE"],
        action = function(nickname)
            sampAddChatMessage(string.format("{%06x}%s drops their sprunk onto the floor.", clr.PURPLE, nickname), -1)
            usingSprunk = false
            return false
        end
    },
    -- You already have full health.
    {
        pattern = "^You already have full health.$",
        color = clrRGBA["GREY"],
        action = function()
            if usingSprunk then
                usingSprunk = false
            end
        end
    }
}

-- OnServerMessage
function sampev.onServerMessage(color, text)
    if not autobind.Settings.enable then
        return
    end

    for _, handler in ipairs(messageHandlers) do
        if color == handler.color then
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

    if (weapon >= 49 and weapon <= 54) or weapon == 255 then
        return
    end

	if autobind.Settings.mode == "Family" then
		if preventHeal then
			local currentTime = localClock()
			if currentTime - timers.Point.last >= timers.Point.timer then
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
    if blackMarket.getItemFrom > 0 then
        if not title:find("Black Market") then 
            blackMarket.getItemFrom = 0 
            blackMarket.gettingItem = false
            blackMarket.currentKey = nil
            return false 
        end
        sampSendDialogResponse(id, 1, blackMarket.currentKey, nil)
        blackMarket.gettingItem = false
        return false
    end

    -- Faction Locker
    if factionLocker.getItemFrom > 0 then
        if title:find('[LSPD|FBI|ARES] Menu') then
            sampSendDialogResponse(id, 1, 1, nil)
            return false
        end

        if not title:find("[LSPD|FBI|ARES] Equipment") then 
            factionLocker.getItemFrom = 0 
            factionLocker.gettingItem = false
            factionLocker.currentKey = nil
            return false
        end
        sampSendDialogResponse(id, 1, factionLocker.currentKey, nil)
        factionLocker.gettingItem = false
        return false
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

    if playerId == autofind.playerId then
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
end

-- Elements Data (Renders)
local elements = {
    OfferedTo = {
        enable = function() return autobind.AutoVest.offeredTo.enable end,
        pos = function() return autobind.AutoVest.offeredTo.Pos end,
        colors = function() return autobind.AutoVest.offeredTo.colors end,
        align = function() return autobind.AutoVest.offeredTo.align end,
        fontName = function() return autobind.AutoVest.offeredTo.font end,
        fontSize = function() return autobind.AutoVest.offeredTo.size end,
        flags = function() return autobind.AutoVest.offeredTo.flags end,
        textFunc = function(self)
            local offeredTo = string.format("%s (%d)", bodyguard.playerName:gsub("_", " "), bodyguard.playerId)
            return string.format("{%06x}Offered To: {%06x}%s; $%s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or offeredTo, formatNumber(bodyguard.price))
        end,
        isVisible = function()
            return (bodyguard.playerName and bodyguard.playerName ~= "" and bodyguard.playerId and bodyguard.playerId ~= -1) or menu.fonts.window[0]
        end,
    },
    OfferedFrom = {
        enable = function() return autobind.AutoVest.offeredFrom.enable end,
        pos = function() return autobind.AutoVest.offeredFrom.Pos end,
        colors = function() return autobind.AutoVest.offeredFrom.colors end,
        align = function() return autobind.AutoVest.offeredFrom.align end,
        fontName = function() return autobind.AutoVest.offeredFrom.font end,
        fontSize = function() return autobind.AutoVest.offeredFrom.size end,
        flags = function() return autobind.AutoVest.offeredFrom.flags end,
        textFunc = function(self)
            local offeredFrom = string.format("%s (%d)", accepter.playerName:gsub("_", " "), accepter.playerId)
            return string.format("{%06x}Offered From: {%06x}%s; $%s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or offeredFrom, formatNumber(accepter.price))
        end,
        isVisible = function()
            return (accepter.playerName and accepter.playerName ~= "" and accepter.playerId and accepter.playerId ~= -1) or menu.fonts.window[0]
        end,
    },
    PedsCount = {
        enable = function() return autobind.PedsCount.enable end,
        pos = function() return autobind.PedsCount.Pos end,
        colors = function() return autobind.PedsCount.colors end,
        align = function() return autobind.PedsCount.align end,
        fontName = function() return autobind.PedsCount.font end,
        fontSize = function() return autobind.PedsCount.size end,
        flags = function() return autobind.PedsCount.flags end,
        textFunc = function(self)
            local pedCount = sampGetPlayerCount(true) - 1
            return string.format("{%06x}Peds: {%06x}%d", self.colors().text, self.colors().value, pedCount)
        end,
        isVisible = function()
            return true
        end,
    },
    AutoFind = {
        enable = function() return autobind.AutoFind.enable end,
        pos = function() return autobind.AutoFind.Pos end,
        colors = function() return autobind.AutoFind.colors end,
        align = function() return autobind.AutoFind.align end,
        fontName = function() return autobind.AutoFind.font end,
        fontSize = function() return autobind.AutoFind.size end,
        flags = function() return autobind.AutoFind.flags end,
        textFunc = function(self)
            local autoFind = string.format("%s (%d)", autofind.playerName:gsub("_", " "), autofind.playerId)
            local timeLeft = math.ceil(timers.Find.timer - (localClock() - timers.Find.last))
            return string.format("{%06x}Auto Find: {%06x}%s; Next: %ds", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or autoFind, timeLeft < 0 and 0 or timeLeft)
        end,
        isVisible = function()
            return (autofind.playerName and autofind.playerName ~= "" and autofind.playerId and autofind.playerId ~= -1) or menu.fonts.window[0]
        end,
    },
    LastBackup = {
        enable = function() return autobind.LastBackup.enable end,
        pos = function() return autobind.LastBackup.Pos end,
        colors = function() return autobind.LastBackup.colors end,
        align = function() return autobind.LastBackup.align end,
        fontName = function() return autobind.LastBackup.font end,
        fontSize = function() return autobind.LastBackup.size end,
        flags = function() return autobind.LastBackup.flags end,
        textFunc = function(self)
            local lastBackup = string.format("%s (%d)", backup.playerName:gsub("_", " "), backup.playerId)
            return string.format("{%06x}Last Backup: {%06x}%s; %s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or lastBackup, menu.fonts.window[0] and "Location" or backup.location)
        end,
        isVisible = function()
            return (backup.playerName and backup.playerName ~= "" and backup.playerId and backup.playerId ~= -1) or menu.fonts.window[0]
        end,
    }
}

-- Initialize 'myFonts' table
local myFonts = {}

-- Table to store drag state for each element
local dragState = {}

-- Flag Values
local flagValues = {
    BOLD = 0x1, 
    ITALICS = 0x2,
    BORDER = 0x4, 
    SHADOW = 0x8,
    UNDERLINE = 0x10,
    STRIKEOUT = 0x20
}

-- Function to create fonts for all elements
function createFonts()
    for name, element in pairs(elements) do
        -- Get the flags table from 'autobind'
        local flags = element.flags() or {}

        -- Calculate the flag sum
        local flag_sum = 0
        for flagName, flagValue in pairs(flagValues) do
            if flags[flagName] then
                flag_sum = flag_sum + flagValue
            end
        end

        -- Create the font with the calculated flags
        local fontName = element.fontName()
        local fontSize = element.fontSize()
        myFonts[name] = renderCreateFont(fontName, fontSize, flag_sum)
    end
end

-- Function to create or update font based on element settings
function createFont(name, element)
    local flag_sum = 0
    for flagName, flagValue in pairs(flagValues) do
        if element.flags[flagName] then
            flag_sum = flag_sum + flagValue
        end
    end

    myFonts[name] = renderCreateFont(element.font, element.size, flag_sum)
end

-- Function to draw all elements
local function drawElements()
    for name, element in pairs(elements) do
        if element.enable() and element.isVisible() then
            local font = myFonts[name]
            if font then
                local text = element.textFunc(element)  -- Pass 'element' as 'self'
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

-- Function to handle moving elements
local function moveElements()
    if not isCursorActive() then return end  -- Ensure the cursor is active
    local cursorX, cursorY = getCursorPos()

    for name, element in pairs(elements) do
        if element.enable() and menu.fonts.window[0] then  -- Only allow moving when menu is open
            local font = myFonts[name]
            if font then
                local text = element.textFunc(element)  -- Pass 'element' as 'self'
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

-- onD3DPresent
function onD3DPresent()
	if not autobind.Settings or not autobind.Keybinds then
		return
	end

	-- Sprint Bind
	if autobind.Settings.enable and autobind.Keybinds.SprintBind.Toggle and (isButtonPressed(h, gkeys.player.SPRINT) and (isCharOnFoot(ped) or isCharInWater(ped))) then
		setGameKeyState(gkeys.player.SPRINT, 0)
	end

    -- Check if the pause/scoreboard/chat is active or if the F10 key is pressed or if the autobind is disabled
    if isPauseMenuActive() or sampIsScoreboardOpen() or sampGetChatDisplayMode() == 0 or isKeyDown(VK_F10) or not autobind.Settings.enable then
        return
    end

    -- Draw all elements
    drawElements()

    -- Move elements
    moveElements()
end

-- ImGUI Initialize
imgui.OnInitialize(function()
	-- Disable ini file
    imgui.GetIO().IniFilename = nil

    -- Load FontAwesome5 Icons
    loadFontIcons(true, 14.0, fa.min_range, fa.max_range, string.format("%sfonts\\fa-solid-900.ttf", Paths.resource))

	-- Load the font with the desired size
	local fontFile = getFolderPath(0x14) .. '\\trebucbd.ttf'
	assert(doesFileExist(fontFile), '[autobind] Font "' .. fontFile .. '" doesn\'t exist!')
	fontData.font = imgui.GetIO().Fonts:AddFontFromFileTTF(fontFile, fontData.fontSize)

	-- Load FontAwesome5 Icons (Again for the font above)
	loadFontIcons(true, fontData.fontSize, fa.min_range, fa.max_range, string.format("%sfonts\\fa-solid-900.ttf", Paths.resource))

	-- Load Skins
	for i = 0, 311 do
		if skinTexture[i] == nil then
			local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, i)
			if doesFileExist(skinPath) then
				skinTexture[i] = imgui.CreateTextureFromFile(skinPath)
			end
		end
	end
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
local imgui_color_red = imgui.ImVec4(1, 0.19, 0.19, 0.5)
local imgui_color_green = imgui.ImVec4(0.15, 0.59, 0.18, 0.7)

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
                for _, command in pairs(cmds) do
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
            saveConfigWithErrorHandling(Files.settings, autobind)
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
            local ignoreKeys = {
                {"Settings", "mode"},
                {"WindowPos", "Settings"},
                {"WindowPos", "Fonts"},
                {"WindowPos", "Skins"},
                {"WindowPos", "Keybinds"},
                {"WindowPos", "BlackMarket"},
                {"WindowPos", "FactionLocker"}
            }

            -- Ensure Defaults
            ensureDefaults(autobind, autobind_defaultSettings, true, ignoreKeys)

            -- Create Fonts
            createFonts()

            -- Reset Key Functions
            resetLockersKeyFunctions()

            -- Initialize Key Functions
            InitializeBlackMarketKeyFunctions()
            InitializeFactionLockerKeyFunctions()
        end,
        color = function()
            return color_default
        end
    },
    {
        id = 5,
        icon = fa.ICON_FA_RETWEET .. ' Update',
        tooltip = 'Check for update',
        action = function()
            checkForUpdate()
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
    {label = "Accept-Death", key = "AcceptDeath", description = "Types /acceptdeath."},
    {label = "Frisk", key = "Frisk", description = "Frisks a player. (Options are to the left)"},
    {label = "Bike-Bind", key = "BikeBind", description = "Makes bikes/motorcycles/quads faster by holding the bind key while riding."},
    {label = "Sprint-Bind", key = "SprintBind", description = "Makes you sprint faster by holding the bind key while sprinting. (This is only the toggle)"},
    {label = "Request Backup", key = "RequestBackup", description = "Types the backup command depending on what mode is detected"}
}

-- Function to update tooltips and labels for buttons1
function updateButton1Tooltips()
    local btn = buttons1[1] -- Assuming first button is the toggle
    btn.tooltip = string.format('%s Toggles all functionalities. ({%06x}%s{%06x})',
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

-- Define a table to hold all menu states
local menuStates = {
    settings = menu.settings.window,
    keybinds = menu.keybinds.window,
    fonts = menu.fonts.window,
    skins = menu.skins.window,
    blackmarket = menu.blackmarket.window,
    factionlocker = menu.factionlocker.window,
}

-- Table to track the previous state of each menu
local previousMenuStates = {
    settings = false,
    keybinds = false,
    fonts = false,
    skins = false,
    blackmarket = false,
    factionlocker = false,
}

-- Flag to indicate that the Escape key was pressed
local escapePressed = false

-- OnWindowMessage
function onWindowMessage(msg, wparam, lparam)
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

local isUpdateHovered = false

-- Settings Window
imgui.OnFrame(function() return menu.initialized[0] end,
function(self)
    -- Returns if Samp is not loaded
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
    self.HideCursor = not anyMenuOpen

    -- Handle Escape key press to close all menus
    if escapePressed then
        for key, state in pairs(menuStates) do
            if state[0] then
                state[0] = false
                print(key .. " menu closed")
            end
            -- Update previous state to reflect that the menu is now closed
            previousMenuStates[key] = false
        end
        escapePressed = false
        print("All menus closed")

        if autobind.Settings.autoSave then
            saveConfigWithErrorHandling(Files.settings, autobind)
            print("Settings saved")
        end
    else
        for key, state in pairs(menuStates) do
            if previousMenuStates[key] and not state[0] then
                print(key .. " menu closed")

                if key == "settings" then
                    if autobind.Settings.autoSave then
                        autobind.AutoVest.names = setToList(names)
                        saveConfigWithErrorHandling(Files.settings, autobind)
                    end
                end

                if key == "blackmarket" then
                    InitializeBlackMarketKeyFunctions()
                end

                if key == "factionlocker" then
                    InitializeFactionLockerKeyFunctions()
                end

                if key == "skins" then
                    autobind.AutoVest.skins = setToList(family.skins)
                end
            end

            -- Detect if the menu has just been opened
            if not previousMenuStates[key] and state[0] then
                print(key .. " menu opened")
                if key == "settings" then
                    fetchDataDirectlyFromURL(Urls.update(autobind.Settings.fetchBeta), function(content)
                        if content and content.version and content.lastversion then
                            local compareNew = compareVersions(content.version, scriptVersion)
                            local compareOld = compareVersions(content.lastversion, scriptVersion)
                            if compareNew == 0 then
                                -- Current version is the same as the new version
                                buttons1[5].icon = fa.ICON_FA_CHECK .. ' Up to date'
                            elseif compareNew == 1 and compareOld ~= 1 then
                                -- Current version is older than the new version
                                buttons1[5].icon = fa.ICON_FA_RETWEET .. ' Update\nNew Version'
                            elseif compareOld == 1 then
                                -- Current version is older than the last version but not the new version
                                buttons1[5].icon = fa.ICON_FA_RETWEET .. ' Update\n Outdated'
                            end
                        end
                    end)
                end
            end

            -- Update previous state
            previousMenuStates[key] = state[0]
        end
    end

    if menu.settings.window[0] then
        local settings = menu.settings
        local config = autobind.Settings

        -- Handle Window Dragging And Position
        local newPos, status = imgui.handleWindowDragging("Settings", autobind.WindowPos.Settings, settings.size, settings.pivot)
        if status then
            autobind.WindowPos.Settings = newPos
            imgui.SetNextWindowPos(autobind.WindowPos.Settings, imgui.Cond.Always, settings.pivot)
        else
            imgui.SetNextWindowPos(autobind.WindowPos.Settings, imgui.Cond.FirstUseEver, settings.pivot)
        end

        -- Set Window Size
        imgui.SetNextWindowSize(settings.size, imgui.Cond.FirstUseEver)

        -- Settings Window
        if imgui.Begin(settings.title, settings.window, imgui_flags) then
            -- First child (Side Buttons)
            imgui.PushFont(fontData.font)
            imgui.BeginChild("##1", child_size1, false)
            for i, button in ipairs(buttons1) do
                imgui.SetCursorPosY(cursor_positions_y_buttons1[i])
                local color = button.color() -- Directly call the color function
                if imgui.CustomButton(button.icon, color, color_hover, color_active, button_size_small) then
                    button.action()
                end
                if not isUpdateHovered then
                    imgui.CustomTooltip(button.tooltip)
                end

                if button.id == 5 then
                    imgui.SetCursorPosY(cursor_positions_y_buttons1[i] + 57)
                    imgui.BeginChild("##checkbox", imgui.ImVec2(0, 20), false)  -- Create a new child for the checkbox
                    if imgui.Checkbox('Beta', new.bool(autobind.Settings.fetchBeta)) then
                        autobind.Settings.fetchBeta = toggleBind("Beta", autobind.Settings.fetchBeta)
                    end
                    imgui.CustomTooltip('Fetch the latest version from the beta branch')
                    isUpdateHovered = imgui.IsItemHovered()
                    imgui.EndChild()
                end
            end
            imgui.EndChild()
            imgui.PopFont()
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
        end
        imgui.End()
    end

    if menu.keybinds.window[0] then
        local frisk = autobind.Settings.Frisk

        -- Handle Window Dragging
        local newPos, status = imgui.handleWindowDragging("Keybinds", autobind.WindowPos.Keybinds, menu.keybinds.size, menu.keybinds.pivot)
        if status then 
            autobind.WindowPos.Keybinds = newPos
            imgui.SetNextWindowPos(autobind.WindowPos.Keybinds, imgui.Cond.Always, menu.keybinds.pivot)
        else
            imgui.SetNextWindowPos(autobind.WindowPos.Keybinds, imgui.Cond.FirstUseEver, menu.keybinds.pivot)
        end

        -- Set the window size
        imgui.SetNextWindowSize(menu.keybinds.size, imgui.Cond.FirstUseEver)

        if imgui.Begin(menu.keybinds.title, menu.keybinds.window, imgui_flags) then

            imgui.SetCursorPosX(20)

            imgui.BeginGroup()
            -- Begin two columns
            imgui.Columns(2, nil, false)

            for index, editor in ipairs(keyEditors) do
                keyEditor(editor.label, editor.key, editor.description)

                if editor.key == "Frisk" then
                    imgui.PushFont(fontData.font)
                    
                    imgui.SetCursorPosY(imgui.GetCursorPosY() - 5)

                    if imgui.Checkbox('Targeting', new.bool(frisk.mustTarget)) then
                        frisk.mustTarget = toggleBind("Targeting", frisk.mustTarget)
                    end
                    imgui.CustomTooltip('Must be targeting a player to frisk. (Green Blip above the player)')
                    imgui.SameLine()
                    if imgui.Checkbox('Must Aim', new.bool(frisk.mustAim)) then
                        frisk.mustAim = toggleBind("Must Aim", frisk.mustAim)
                    end
                    imgui.CustomTooltip('Must be aiming to frisk.')

                    imgui.PopFont()

                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
                end

                -- Move to the next column after half of the editors
                if index == math.ceil(#keyEditors / 2) then
                    imgui.NextColumn()
                end
            end

            -- End columns
            imgui.Columns(1)
            imgui.EndGroup()
        end
        imgui.End()
    end

    if menu.skins.window[0] then
        -- Handle Window Dragging And Position
        local newPos, status = imgui.handleWindowDragging("Skins", autobind.WindowPos.Skins, menu.skins.size, menu.skins.pivot)
        if status then
            autobind.WindowPos.Skins = newPos
            imgui.SetNextWindowPos(autobind.WindowPos.Skins, imgui.Cond.Always, menu.skins.pivot)
        else
            imgui.SetNextWindowPos(autobind.WindowPos.Skins, imgui.Cond.FirstUseEver, menu.skins.pivot)
        end

        -- Set Window Size
        imgui.SetNextWindowSize(menu.skins.size, imgui.Cond.FirstUseEver)

        -- Skin Window
        if imgui.Begin(menu.skins.title, menu.skins.window, imgui_flags) then
            local storedSkins = {}
            for skinId, _ in pairs(family.skins) do
                table.insert(storedSkins, skinId)
            end

            table.sort(storedSkins)

            -- Create a string of selected skin IDs
            local selectedSkinsText = table.concat(storedSkins, ",")

            imgui.PushFont(fontData.font)

            -- Display read-only input field with selected skins
            imgui.PushItemWidth(500)
            local buffer = new.char[256](selectedSkinsText)
            imgui.InputText("##selected_skins", buffer, sizeof(buffer), imgui.InputTextFlags.ReadOnly)
            imgui.PopItemWidth()
            imgui.CustomTooltip("Select skins to use for your family")

            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_COPY) then
                setClipboardText(selectedSkinsText)
            end
            imgui.CustomTooltip("Copy selected skin IDs to clipboard")

            imgui.PopFont()

            -- Begin a child window for scrolling
            if imgui.BeginChild("SkinList", imgui.ImVec2(535, 355), false) then
                for skinId = 0, 311 do
                    if (skinId % 8) ~= 0 then
                        imgui.SameLine()
                    end

                    -- Check if the skin is selected
                    local isSelected = family.skins[skinId] == true

                    -- Highlight the selected skin
                    if isSelected then
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 0.0, 1.0)) -- Green highlight
                    end

                    if skinTexture[skinId] == nil then
                        local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, skinId)
                        if doesFileExist(skinPath) then
                            skinTexture[skinId] = imgui.CreateTextureFromFile(skinPath)
                        end
                    end

                    if imgui.ImageButton(skinTexture[skinId], imgui.ImVec2(50, 80)) then
                        if isSelected then
                            family.skins[skinId] = nil -- Remove entry if deselected
                        else
                            family.skins[skinId] = true -- Add entry if selected
                        end
                    end

                    if isSelected then
                        imgui.PopStyleColor()
                    end

                    imgui.CustomTooltip("Skin " .. skinId)
                end
            end
            imgui.EndChild()
        end
        imgui.End()
    end

    if menu.fonts.window[0] then
        -- Handle Window Dragging
        local newPos, status = imgui.handleWindowDragging("FontSettings", autobind.WindowPos.Fonts, menu.fonts.size, menu.fonts.pivot)
        if status then 
            autobind.WindowPos.Fonts = newPos
            imgui.SetNextWindowPos(autobind.WindowPos.Fonts, imgui.Cond.Always, menu.fonts.pivot)
        else
            imgui.SetNextWindowPos(autobind.WindowPos.Fonts, imgui.Cond.FirstUseEver, menu.fonts.pivot)
        end

        -- Set the window size
        imgui.SetNextWindowSize(menu.fonts.size, imgui.Cond.FirstUseEver)

        local fontElements = {
            {label = "OfferedTo", value = autobind.AutoVest.offeredTo},
            {label = "OfferedFrom", value = autobind.AutoVest.offeredFrom},
            {label = "PedsCount", value = autobind.PedsCount},
            {label = "AutoFind", value = autobind.AutoFind},
            {label = "LastBackup", value = autobind.LastBackup}
        }        

        if imgui.Begin(menu.fonts.title, menu.fonts.window, imgui_flags) then
            for index, value in pairs(fontElements) do
                createFontMenuElement(value.label, value.value)
                if index ~= #fontElements then
                    imgui.Separator()
                end
            end
        end
        imgui.End()
    end

    if menu.blackmarket.window[0] then
        -- Handle Window Dragging
        local newPos, status = imgui.handleWindowDragging("BlackMarket", autobind.WindowPos.BlackMarket, menu.blackmarket.size, menu.blackmarket.pivot)
        if status then 
            autobind.WindowPos.BlackMarket = newPos
            imgui.SetNextWindowPos(autobind.WindowPos.BlackMarket, imgui.Cond.Always, menu.blackmarket.pivot)
        else
            imgui.SetNextWindowPos(autobind.WindowPos.BlackMarket, imgui.Cond.FirstUseEver, menu.blackmarket.pivot)
        end

        -- Set the window size
        imgui.SetNextWindowSize(menu.blackmarket.size, imgui.Cond.FirstUseEver)
        
        -- Calculate total price
        local totalPrice = calculateTotalPrice(autobind.BlackMarket[string.format("Kit%d", menu.blackmarket.pageId)], blackMarket.Items)

        -- Define a table to map kitId to key and menu data
        local kits = {}
        for i = 1, autobind.Settings.currentBlackMarketKits do
            kits[i] = {key = string.format('BlackMarket%d', i), menu = autobind.BlackMarket[string.format("Kit%d", i)]}
        end

        -- Blackmarket Window
        local title = string.format("Black Market - Kit: %d - $%s", menu.blackmarket.pageId, formatNumber(totalPrice))
        if imgui.Begin(title, menu.blackmarket.window, imgui_flags) then
            -- Display the key editor and menu based on the selected kitId
            for id, kit in pairs(kits) do
                if menu.blackmarket.pageId == id then
                    -- Keybind
                    keyEditor("Keybind", kit.key)

                    -- Preview Kit
                    imgui.SameLine()
                    imgui.BeginGroup()
                    imgui.PushItemWidth(82)
                    if imgui.BeginCombo("##blackmarket_preview", fa.ICON_FA_SHOPPING_CART .. " Kit " .. id) then
                        for i = 1, autobind.Settings.currentBlackMarketKits do
                            if imgui.Selectable(fa.ICON_FA_SHOPPING_CART .. " Kit " .. i .. (i == id and ' [x]' or ''), menu.blackmarket.pageId == i) then
                                menu.blackmarket.pageId = i
                            end
                        end
                        imgui.EndCombo()
                    end
                    imgui.PopItemWidth()

                    -- Create new kit
                    if imgui.Button("Add New Kit", imgui.ImVec2(82, 20)) then
                        if autobind.Settings.currentBlackMarketKits < maxKits then
                            autobind.Settings.currentBlackMarketKits = autobind.Settings.currentBlackMarketKits + 1
                            autobind.BlackMarket[string.format("Kit%d", autobind.Settings.currentBlackMarketKits)] = {1, 2, 10, 11}

                            menu.blackmarket.pageId = autobind.Settings.currentBlackMarketKits

                            autobind.Keybinds[string.format("BlackMarket%d", autobind.Settings.currentBlackMarketKits)] = {Toggle = false, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}}
                        end
                    end
                    imgui.EndGroup()

                    -- Create selection menu
                    createMenu('Selection', blackMarket.Items, kit.menu, blackMarket.ExclusiveGroups, blackMarket.maxSelections, {combineGroups = blackMarket.ExclusiveGroups})
                end
            end
        end
        imgui.End()
    end

    if menu.factionlocker.window[0] then
        -- Handle Window Dragging
        local newPos, status = imgui.handleWindowDragging("FactionLocker", autobind.WindowPos.FactionLocker, menu.factionlocker.size, menu.factionlocker.pivot)
        if status then 
            autobind.WindowPos.FactionLocker = newPos
            imgui.SetNextWindowPos(autobind.WindowPos.FactionLocker, imgui.Cond.Always, menu.factionlocker.pivot)
        else
            imgui.SetNextWindowPos(autobind.WindowPos.FactionLocker, imgui.Cond.FirstUseEver, menu.factionlocker.pivot)
        end

        -- Set the window size
        imgui.SetNextWindowSize(menu.factionlocker.size, imgui.Cond.FirstUseEver)

        -- Calculate total price
        local totalPrice = calculateTotalPrice(autobind.FactionLocker[string.format("Kit%d", menu.factionlocker.pageId)], factionLocker.Items)

        -- Define a table to map kitId to key and menu data
        local kits = {}
        for i = 1, autobind.Settings.currentFactionLockerKits do
            kits[i] = {key = string.format('FactionLocker%d', i), menu = autobind.FactionLocker[string.format("Kit%d", i)]}
        end

        -- Faction Locker Window
        local title = string.format("Faction Locker - Kit: %d - $%s", menu.factionlocker.pageId, formatNumber(totalPrice))
        if imgui.Begin(title, menu.factionlocker.window, imgui_flags) then
            -- Display the key editor and menu based on the selected kitId
            for id, kit in pairs(kits) do
                if menu.factionlocker.pageId == id then
                    -- Keybind
                    keyEditor("Keybind", kit.key)

                    -- Preview Kit
                    imgui.SameLine()
                    imgui.BeginGroup()
                    imgui.PushItemWidth(82)
                    if imgui.BeginCombo("##locker_preview", fa.ICON_FA_SHOPPING_CART .. " Kit " .. id) then
                        for i = 1, autobind.Settings.currentFactionLockerKits do
                            if imgui.Selectable(fa.ICON_FA_SHOPPING_CART .. " Kit " .. i .. (i == id and ' [x]' or ''), menu.factionlocker.pageId == i) then
                                menu.factionlocker.pageId = i
                            end
                        end
                        imgui.EndCombo()
                    end
                    imgui.PopItemWidth()

                    -- Create new kit
                    if imgui.Button("Add New Kit", imgui.ImVec2(82, 20)) then
                        if autobind.Settings.currentFactionLockerKits < maxKits then
                            autobind.Settings.currentFactionLockerKits = autobind.Settings.currentFactionLockerKits + 1
                            autobind.FactionLocker[string.format("Kit%d", autobind.Settings.currentFactionLockerKits)] = {1, 2, 10, 11}

                            menu.factionlocker.pageId = autobind.Settings.currentFactionLockerKits

                            autobind.Keybinds[string.format("FactionLocker%d", autobind.Settings.currentFactionLockerKits)] = {Toggle = false, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}}
                        end
                    end
                    imgui.EndGroup()
                    
                    -- Create selection menu
                    createMenu('Selection', factionLocker.Items, kit.menu, factionLocker.ExclusiveGroups, factionLocker.maxSelections, {combineGroups = factionLocker.combineGroups})
                end
            end
        end
        imgui.End()
    end

    if menu.confirm.window[0] then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, menu.confirm.pivot)

        if imgui.Begin(menu.settings.title .. ' - Update', menu.confirm.window, imgui_flags) then
            if not imgui.IsWindowFocused() then 
                imgui.SetNextWindowFocus() 
            end

            if menu.confirm.update[0] then
                imgui.Text('Do you want to update this script?')
                local buttonSize = imgui.ImVec2(85, 45)
                if imgui.CustomButton(fa.ICON_FA_CHECK .. ' Update', color_default, color_hover, color_active, buttonSize) then
                    updateScript()
                    menu.confirm.update[0] = false
                    menu.confirm.window[0] = false
                end
                imgui.SameLine()
                if imgui.CustomButton(fa.ICON_FA_TIMES .. ' Cancel', color_default, color_hover, color_active, buttonSize) then
                    menu.confirm.update[0] = false
                    menu.confirm.window[0] = false
                end
            end
        end
        imgui.End()
    end
end).HideCursor = true

-- Function to calculate total price for a given kit
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

-- Render Settings
function renderSettings()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##config", imgui.ImVec2(485, 255), false) then
        -- Autobind/Capture
        imgui.Text('Auto Bind:')
        createRow(string.format('Capture Spam (/%s)', cmds.tcap.cmd), 'Capture spam will automatically type /capturf every 1.5 seconds.', captureSpam, toggleCaptureSpam, true)
        
        local config = autobind.Settings
        local autoVest = autobind.AutoVest
        local frisk = autobind.Settings.Frisk

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
        
        createRow(string.format('Auto Repair (/%s)', cmds.repairnear.cmd), 'Auto Repair will automatically accept repair requests.', config.autoRepair, function()
            config.autoRepair = toggleBind("Accept Repair", config.autoRepair)
        end, true)
        
        if config.mode == "Faction" then
            createRow('Auto Badge', 'Automatically types /badge after spawning from the hospital.', config.Faction.autoBadge, function()
                config.Faction.autoBadge = toggleBind("Auto Badge", config.Faction.autoBadge)
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
        
        if config.mode == "Faction" then
            imgui.NewLine()
            imgui.Text('Radio Chat:')
            createRow('Modify', 'Modify the radio chat to your liking.', config.Faction.modifyRadioChat, function()
                config.Faction.modifyRadioChat = toggleBind("Modify Radio Chat", config.Faction.modifyRadioChat)
            end, false)
        end
    end
    imgui.EndChild()
end

-- Helper function to draw skin images
local function drawSkinImages(skins, columns, imageSize, spacing, startPos)
    local index = 0
    for skinId, _ in pairs(skins) do
        local column = index % columns
        local row = math.floor(index / columns)
        local posX = startPos.x + column * (imageSize.x + spacing)
        local posY = startPos.y + row * (imageSize.y + spacing / 4)

        imgui.SetCursorPos(imgui.ImVec2(posX, posY))
        if skinTexture[skinId] then
            imgui.Image(skinTexture[skinId], imageSize)
        else
            imgui.Button("No\nImage", imageSize)
            local skinPath = string.format("%s\\Skin_%d.png", Paths.skins, skinId)
            if doesFileExist(skinPath) then
                skinTexture[skinId] = imgui.CreateTextureFromFile(skinPath)
            end
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Skin " .. skinId)
        end

        index = index + 1
    end
    return index
end

-- Render Skins
function renderSkins()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##skins", imgui.ImVec2(487, 270), false) then
        local columns = 8
        local imageSize = imgui.ImVec2(50, 80)
        local spacing = 10.0
        
        if autobind.Settings.mode == "Family" then
            imgui.PushFont(fontData.font)

            imgui.PushItemWidth(326)
            local url = new.char[128](autobind.AutoVest.skinsUrl)
            if imgui.InputText('##skins_url', url, sizeof(url)) then
                autobind.AutoVest.skinsUrl = u8:decode(str(url))
            end
            imgui.CustomTooltip(string.format('URL to fetch skins from, must be a JSON array of skin IDs,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.skinsUrl))
            imgui.SameLine()
            imgui.PopItemWidth()
            if imgui.Button("Fetch") then
                fetchDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
                    autobind.AutoVest.skins = decodedData

                    -- Convert list to set
                    family.skins = listToSet(autobind.AutoVest.skins)
                end)
            end
            imgui.CustomTooltip("Fetches skins from provided URL")
            imgui.SameLine()
            if imgui.Checkbox("Auto Fetch", new.bool(autobind.AutoVest.autoFetchSkins)) then
                autobind.AutoVest.autoFetchSkins = not autobind.AutoVest.autoFetchSkins
            end
            imgui.CustomTooltip("Fetch skins at startup")

            imgui.PopFont()

            local startPos = imgui.GetCursorPos()
            local index = drawSkinImages(family.skins, columns, imageSize, spacing, startPos)

            local column = index % columns
            local row = math.floor(index / columns)
            local posX = startPos.x + column * (imageSize.x + spacing)
            local posY = startPos.y + row * (imageSize.y + spacing / 4)

            imgui.SetCursorPos(imgui.ImVec2(posX, posY))
            if imgui.Button(" Edit\nSkins", imageSize) then
                menu.skins.window[0] = not menu.skins.window[0]
            end
        elseif autobind.Settings.mode == "Faction" then
            if imgui.Checkbox("Use Skins", new.bool(autobind.AutoVest.useSkins)) then
                autobind.AutoVest.useSkins = not autobind.AutoVest.useSkins
            end

            local startPos = imgui.GetCursorPos()
            drawSkinImages(factions.skins, columns, imageSize, spacing, startPos)
        end
    end
    imgui.EndChild()
end

-- Render Names
function renderNames()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##names", imgui.ImVec2(487, 263), false) then

        imgui.PushFont(fontData.font)

        imgui.PushItemWidth(326)
        local url = new.char[128](autobind.AutoVest.namesUrl)
        if imgui.InputText('##names_url', url, sizeof(url)) then
            autobind.AutoVest.namesUrl = u8:decode(str(url))
        end
        imgui.CustomTooltip(string.format('URL to fetch names from, must be a JSON array of names,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.namesUrl))
        imgui.SameLine()
        imgui.PopItemWidth()
        if imgui.Button("Fetch") then
            fetchDataDirectlyFromURL(autobind.AutoVest.namesUrl, function(decodedData)
                if decodedData then
                    autobind.AutoVest.names = decodedData

                    -- Convert list to set
                    names = listToSet(autobind.AutoVest.names)
                end
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
        
        for name, _ in pairs(names) do

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

        if imgui.Button("Add Name", imgui.ImVec2(154, 20)) then
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

-- Function to create ImGui font menu for elements
function createFontMenuElement(title, element)
    -- Check if the element exists
    if element.enable == nil then
        return
    end

    -- Title
    imgui.AlignTextToFramePadding()
    imgui.Text(title..":")

    imgui.SameLine()
    if imgui.Checkbox(string.format("%s##%s", element.enable and "Enabled" or "Disabled", title), new.bool(element.enable)) then
        element.enable = not element.enable
    end

    imgui.SameLine()
    -- Position adjustment
    imgui.PushItemWidth(170)
    local pos = new.float[2](element.Pos.x, element.Pos.y)
    if imgui.DragFloat2('##position_' .. title, pos, 0.1, 0, 2000, "%.1f") then
        element.Pos.x, element.Pos.y = pos[0], pos[1]
    end
    imgui.PopItemWidth()

    imgui.SameLine()
    -- Text color picker
    imgui.BeginGroup()
    imgui.PushItemWidth(95)
    local clrText = convertColor(element.colors.text, true, false, false)
    local clrEdit1 = new.float[3](clrText.r, clrText.g, clrText.b)
    if imgui.ColorEdit3('##text_color_' .. title, clrEdit1, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
        element.colors.text = joinARGB(0, clrEdit1[0], clrEdit1[1], clrEdit1[2], true)
    end
    imgui.PopItemWidth()
    imgui.SameLine(25)
    imgui.Text('Text')
    imgui.EndGroup()

    imgui.SameLine()
    -- Value color picker
    imgui.BeginGroup()
    imgui.PushItemWidth(95)
    local clrValue = convertColor(element.colors.value, true, false, false)
    local clrEdit2 = new.float[3](clrValue.r, clrValue.g, clrValue.b)
    if imgui.ColorEdit3('##value_color_' .. title, clrEdit2, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
        element.colors.value = joinARGB(0, clrEdit2[0], clrEdit2[1], clrEdit2[2], true)
    end
    imgui.PopItemWidth()
    imgui.SameLine(25)
    imgui.Text('Value')
    imgui.EndGroup()

    -- Alignment options
    local alignments = {'Left', 'Center', 'Right'}
    imgui.PushItemWidth(68)
    local currentAlignment = element.align == 'left' and 1 or element.align == 'center' and 2 or 3
    if imgui.BeginCombo("##align_" .. title, alignments[currentAlignment]) then
        for i = 1, #alignments do
            if imgui.Selectable(alignments[i], currentAlignment == i) then
                currentAlignment = i
                element.align = alignments[i]:lower()
            end
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()

    imgui.SameLine()
    -- Font flags options
    local flagNames = {'BOLD', 'ITALICS', 'BORDER', 'SHADOW', 'UNDERLINE', 'STRIKEOUT'}
    imgui.PushItemWidth(75)
    if imgui.BeginCombo("##flags_" .. title, 'Flags') then
        for _, flagName in ipairs(flagNames) do
            local flagValue = element.flags[flagName]
            if imgui.Checkbox(flagName:lower():capitalizeFirst(), new.bool(flagValue)) then
                element.flags[flagName] = not flagValue
                -- Recreate the font with new flags if necessary
                createFont(title, element)
            end
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth()

    imgui.SameLine()
    -- Font name input
    imgui.PushItemWidth(95)
    local fontName = new.char[30](element.font)
    if imgui.InputText("##font_" .. title, fontName, sizeof(fontName), imgui.InputTextFlags.EnterReturnsTrue) then
        element.font = ffi.string(fontName)
        createFont(title, element)
    end
    imgui.PopItemWidth()

    imgui.SameLine()
    -- Font size adjustment
    imgui.PushItemWidth(75)
    local fontSize = new.int(element.size)
    if imgui.InputInt("##size_" .. title, fontSize, 1, 1, imgui.InputTextFlags.EnterReturnsTrue) then
        if fontSize[0] >= 1 and fontSize[0] <= 72 then
            element.size = fontSize[0]
            createFont(title, element)
        end
    end
    imgui.PopItemWidth()
end

-- Function to Download Files From URL
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

    downloadManager:queueDownloads(urls, onComplete, progress and onProgress or nil)
end

-- Function to Fetch Data Directly From URL
function fetchDataDirectlyFromURL(url, callback)
    local function onComplete(decodedData)
        if decodedData and next(decodedData) ~= nil then
            callback(decodedData)
        else
            print("JSON format is empty or invalid URL:", url)
        end
    end

    downloadManager:queueFetches({{url = url, callback = onComplete}})
end

-- Check for Update
function checkForUpdate()
    fetchDataDirectlyFromURL(Urls.update(autobind.Settings.fetchBeta), function(content)
        if not content then
            return
        end

        if content.version and compareVersions(scriptVersion, content.version) == -1 then
            menu.confirm.update[0] = true
            menu.confirm.window[0] = true
        end
    end)
end

-- Update Script
function updateScript()
    autobind.Settings.updateInProgress = true
    autobind.Settings.lastVersion = scriptVersion

    downloadFilesFromURL({{url = Urls.script(autobind.Settings.fetchBeta), path = scriptPath, replace = true}}, false, function(downloadsFinished)
        if downloadsFinished then
            lua_thread.create(function()
                wait(1000)
                formattedAddChatMessage("Update downloaded successfully! Reloading the script now.")
                thisScript():reload()
            end)
        else
            formattedAddChatMessage("Update download failed! Please try again later.")
        end
    end)
end

-- Function to Generate Skins URLs
function generateSkinsUrls()
    local files = {}
    for i = 0, 311 do
        table.insert(files, {
            url = string.format("%sSkin_%d.png", Urls.skins, i),
            path = string.format("%sSkin_%d.png", Paths.skins, i),
            replace = false,
            index = i
        })
    end

    -- Sort the files by index
    table.sort(files, function(a, b) return tonumber(a.index) < tonumber(b.index) end)

    return files
end

-- Function to Initiate the Skin Download Process
function downloadSkins(urls)
    downloadFilesFromURL(urls, true, function(downloadsFinished)
        if downloadsFinished then
            print("All files downloaded successfully.")
            formattedAddChatMessage("All skins downloaded successfully!")
        else
            print("No files needed to be downloaded.")
        end
    end)
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
                        if tableContains(group, index) then
                            for i = #tbl, 1, -1 do
                                if tableContains(group, tbl[i]) and tbl[i] ~= index then
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
                formattedAddChatMessage("{FF0000}Maximum selection limit reached.")
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
    
    -- Handle combined groups (e.g., for grouping items visually)
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
    end

    -- Handle the rest of the items
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
    imgui.CustomTooltip(string.format("Toggle this key binding. {%06x}(%s)", checkBoxColor, checkBoxText))

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

-- Get Keybind Keys
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

-- Get visible players
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
        if not sampGetPlayerNickname(playerId):find("_") then
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
            distance = distance,
            skinId = getCharModel(peds)
        }
        table.insert(visiblePlayers, playerInfo)

        ::continue::
    end

    -- Sort players by distance and return
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

-- Function to convert seconds into a human-readable format
function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local timeString = ""
    if hours > 0 then
        timeString = timeString .. string.format("%d hour%s, ", hours, hours > 1 and "s" or "")
    end
    if minutes > 0 then
        timeString = timeString .. string.format("%d minute%s, ", minutes, minutes > 1 and "s" or "")
    end
    timeString = timeString .. string.format("%.1f second%s", seconds, seconds ~= 1 and "s" or "")

    return timeString
end

-- List to Set
function listToSet(list)
    local set = {}
    for _, value in pairs(list) do
        set[value] = true
    end
    return set
end

-- Set to List
function setToList(set)
    local list = {}
    for key, value in pairs(set) do
        if value then
            table.insert(list, key)
        end
    end
    return list
end

-- Function to remove color codes from text
function removeHexBrackets(text)
    return string.gsub(text, "{%x+}", "")
end

-- Formatted Add Chat Message
function formattedAddChatMessage(string)
    sampAddChatMessage(string.format("{%06x}[%s] {%06x}%s", clr.LIGHTBLUE, scriptName:capitalizeFirst(), clr.WHITE, string), -1)
end

-- Format Number
function formatNumber(n)
    n = tostring(n)
    return n:reverse():gsub("...","%0,",math.floor((#n-1)/3)):reverse()
end

-- Compare Versions
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

-- Table Contains
function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
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
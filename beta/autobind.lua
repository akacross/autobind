script_name("autobind")
script_description("Autobind is a collection of useful features and modifications")
script_version("1.8.24b3")
script_authors("akacross")
script_url("https://akacross.net/")

local shortName = "ab"

local scriptPath = thisScript().path
local scriptName = thisScript().name
local scriptVersion = thisScript().version

local workingDir = getWorkingDirectory()

local Paths = {
    libraries = workingDir .. '\\lib\\',
    config = workingDir .. '\\config\\',
    resource = workingDir .. '\\resource\\'
}

Paths.settings = Paths.config .. scriptName .. '\\'
Paths.skins = Paths.resource .. 'skins\\'
Paths.fonts = Paths.resource .. 'fonts\\'

local Files = {
    script = Paths.settings .. scriptName .. '.lua',
    fawesome5 = Paths.fonts .. 'fa-solid-900.ttf',
    trebucbd = getFolderPath(0x14) .. '\\trebucbd.ttf'
}

local function getBaseUrl(beta, scriptname)
    local branch = beta and "beta/" or ""
    return "https://raw.githubusercontent.com/akacross/" .. scriptname .. "/main/" .. branch
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
    changelog = getBaseUrl(false, scriptName) .. "changelog.json",
    betatesters = getBaseUrl(true, scriptName) .. "betatesters.json"
}

local function safeRequire(moduleName)
    local ok, result = pcall(require, moduleName)
    return ok and result or nil, result
end

local dependencies = {
    {name = 'ltn12', var = 'ltn12', localFile = "ltn12.lua"},
    {name = 'ssl.https', var = 'https', 
        localFiles = {
            "ssl.dll",
            "ssl.lua", 
            "ssl/https.lua"
        }
    },
    {name = 'socket.http', var = 'http', 
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
    {name = 'socket.url', var = 'url', localFile = "socket/url.lua"},
    {name = 'lfs', var = 'lfs', localFile = "lfs.dll"},
    {name = 'lanes', var = 'lanes', 
        localFiles = {
            "lanes.lua",
            "lanes/core.dll"
        }, 
        callback = function(module) return module.configure() end
    },
    {name = 'moonloader', var = 'moonloader', localFile = "moonloader.lua"}, 
    {name = 'ffi', var = 'ffi'},
    {name = 'memory', var = 'mem'},
    {name = 'vkeys', var = 'vk', localFile = "vkeys.lua"},
    {name = 'game.keys', var = 'gkeys',
        localFiles = {
            "game/globals.lua", 
            "game/keys.lua", 
            "game/models.lua", 
            "game/weapons.lua"
        }
    },
    {name = 'windows.message', var = 'wm',
        localFiles = {
            "windows/init.lua", 
            "windows/message.lua"
        }
    },
    {name = 'mimgui', var = 'imgui',
        localFiles = {
            "mimgui/cdefs.lua",
            "mimgui/cimguidx9.dll",
            "mimgui/dx9.lua",
            "mimgui/imgui.lua",
            "mimgui/init.lua"
        }
    },
    {name = 'encoding', var = 'encoding',
        localFiles = {
            "encoding.lua",
            "iconv.dll"
        }
    },
    {name = 'fAwesome5', var = 'fa', localFile = "fAwesome5.lua", resourceFile = "fonts/fa-solid-900.ttf"},
    {name = 'samp.events', var = 'sampev',
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
    }
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
            local mod = safeRequire(dep.name)
            if not mod then
                print("Missing dependency and no download info provided: " .. dep.name)
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
    BETA = 0x5D8AA8, -- #5D8AA8
    DEV = 0xC27C0E, -- #C27C0E
    ARES = 0x1C77B3, -- #1C77B3
    DARKGREY = 0x1A1A1A, -- #1A1A1A
    ALTRED = 0x661F1F, -- #661F1F
    BLUE = 0xB7D1EB, -- #B7D1EB
    DD = 0x8ABFF5, -- #8ABFF5
    OOC = 0x6F570E, -- #6F570E
    GOV = 0xBEBEBE, -- #BEBEBE
    SASD = 0xCC9933, -- #CC9933
}

local function formattedAddChatMessage(message, color)
    color = color or clr.WHITE
    sampAddChatMessage(("[%s] {%06x}%s"):format(shortName:upper(), color, message), clr.LIGHTBLUE)
end

function main()
    while not isSampAvailable() do wait(100) end

    if #missingFiles > 0 then
        local missingFileText = #missingFiles == 1 and "file" or "files"
        formattedAddChatMessage(("Some dependencies are missing, downloading now... (Missing: %d %s)"):format(#missingFiles, missingFileText))
    end

    -- Wait Indefinitely
    wait(-1)
end

-- Start checking (and, if needed, downloading) missing dependencies.
local mainScript, scriptError = xpcall(checkAndDownloadDependencies, debug.traceback, function()

local loadedModules = {}
local statusMessages = {success = {}, failed = {}}

for _, dep in ipairs(dependencies) do
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

    loadedModules[dep.var] = mod

    if mod then
        table.insert(statusMessages.success, dep.name)
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

print("Loaded modules: " .. table.concat(statusMessages.success, ", "))
if #statusMessages.failed > 0 then
    print("Failed to load modules: " .. table.concat(statusMessages.failed, ", "))
end

-- Dynamically set script dependencies if needed.
script_dependencies(table.unpack(statusMessages.success))

encoding.default = 'CP1251'
local u8 = encoding.UTF8

if not _G['lanes.download_manager'] then
    local linda = lanes.linda()

    local download_lane_gen = lanes.gen('*', {
        package = {
            path = package.path,
            cpath = package.cpath,
        },
    },
    function(linda, taskType, fileUrl, filePath, identifier)
        local ltn12 = require('ltn12')       -- For HTTP progress sink
        local http = require('socket.http')  -- For HTTP requests
        local https = require('ssl.https')   -- For HTTPS requests
        local lfs = require('lfs')           -- LuaFileSystem
        local url = require('socket.url')    -- URL parsing

        if taskType == "download" then
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
            if parsed_url and parsed_url.scheme == "https" then
                http_request = https.request
            end

            -- Perform a HEAD request to get the total size
            local _, code, headers = http_request{
                url = fileUrl,
                method = "HEAD",
            }

            if code == 200 and headers then
                local contentLength = headers["content-length"] or headers["Content-Length"]
                if contentLength then
                    progressData.total = tonumber(contentLength)
                else
                    linda:send('error_' .. identifier, { error = "Content-Length header not found for URL: " .. fileUrl })
                end
            else
                linda:send('error_' .. identifier, { error = "HEAD request failed with code: " .. code .. " for URL: " .. fileUrl })
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
                    end
                else
                    -- No more data; close the file
                    outputFile:close()
                    linda:send('completed_' .. identifier, {
                        downloaded = progressData.downloaded,
                        total = progressData.total,
                    })
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
            end

        elseif taskType == "fetch" then
            -- Determine whether to use HTTP or HTTPS
            local parsed_url = url.parse(fileUrl)
            local http_request = http.request
            if parsed_url and parsed_url.scheme == "https" then
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
            else
                local errorMsg = "HTTP Error: " .. tostring(code)
                linda:send('error_' .. identifier, { error = errorMsg })
            end
        end
    end)

    local main_lane_gen = lanes.gen('*', {
        package = {
            path = package.path,
            cpath = package.cpath,
        },
    },
    function(linda)
        while true do
            local key, val = linda:receive(0, 'request')
            if key == 'request' and val then
                local taskType = val.taskType
                local fileUrl = val.url
                local filePath = val.filePath
                local identifier = val.identifier

                local success, laneOrErr = pcall(download_lane_gen, linda, taskType, fileUrl, filePath, identifier)
                if not success then
                    linda:send('error_' .. identifier, { error = "Failed to start lane: " .. tostring(laneOrErr) })
                end
            end
        end
    end)

    local success, laneOrErr = pcall(main_lane_gen, linda)
    if success then
        _G['lanes.download_manager'] = { lane = laneOrErr, linda = linda }
    else
        print("Failed to start main lane:", laneOrErr)
    end
end
 
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
        pendingFetchBatches = {},
    }
    setmetatable(manager, self)
    return manager
end

function DownloadManager:queueDownloads(fileTable, onComplete, onProgress)
    table.insert(self.pendingBatches, {files = fileTable, onComplete = onComplete, onProgress = onProgress})

    if not self.isDownloading then
        self:processNextBatch()
    end
end

function DownloadManager:processNextBatch()
    if #self.pendingBatches == 0 then
        return
    end

    local batch = table.remove(self.pendingBatches, 1)
    self.onCompleteCallback = batch.onComplete
    self.onProgressCallback = batch.onProgress

    self.hasCompleted = false
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
        self:completeBatch()
    end
end

function DownloadManager:completeBatch()
    if self.hasCompleted then
        return
    end
    self.hasCompleted = true
    self.isDownloading = false
    if self.onCompleteCallback then
        self.onCompleteCallback(self.completedFiles > 0)
    end
    self:processNextBatch()
end

function DownloadManager:processQueue()
    while self.activeDownloads < self.maxConcurrentDownloads and #self.downloadQueue > 0 do
        local file = table.remove(self.downloadQueue, 1)
        self.activeDownloads = self.activeDownloads + 1
        self:downloadFile(file)
    end
end

function DownloadManager:downloadFile(file)
    local identifier = file.index or tostring(file.url)
    local linda = self.lanesHttp

    linda:send('request', {
        taskType = "download",
        url = file.url,
        filePath = file.path,
        identifier = identifier
    })

    self.downloadsInProgress[identifier] = file
end

function DownloadManager:queueFetches(fetchTable, onComplete)
    table.insert(self.pendingFetchBatches, {fetches = fetchTable, onComplete = onComplete})

    if not self.isFetching then
        self:processNextFetchBatch()
    end
end

function DownloadManager:processNextFetchBatch()
    if #self.pendingFetchBatches == 0 then
        self.isFetching = false
        return
    end

    local batch = table.remove(self.pendingFetchBatches, 1)
    self.currentFetchOnCompleteCallback = batch.onComplete

    self.isFetching = true
    self.hasCompletedFetch = false
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
        self:completeFetchBatch() 
    end
end

function DownloadManager:processFetchQueue()
    while self.activeFetches < self.maxConcurrentDownloads and #self.fetchQueue > 0 do
        local fetch = table.remove(self.fetchQueue, 1)
        self.activeFetches = self.activeFetches + 1
        self:fetchData(fetch, function(decodedData)
            if fetch.callback then
                fetch.callback(decodedData)
            end

            self.activeFetches = self.activeFetches - 1

            if #self.fetchQueue > 0 then
                self:processFetchQueue()
            else
                if self.activeFetches == 0 then
                    self:completeFetchBatch()
                end
            end
        end)
    end
end

function DownloadManager:completeFetchBatch()
    if self.hasCompletedFetch then
        return
    end
    self.hasCompletedFetch = true
    if self.currentFetchOnCompleteCallback then
        self.currentFetchOnCompleteCallback()
    end
    self:processNextFetchBatch()
end

function DownloadManager:fetchData(fetch, onComplete)
    local identifier = fetch.identifier or tostring(fetch.url)
    local linda = self.lanesHttp

    linda:send('request', {
        taskType = "fetch",
        url = fetch.url,
        identifier = identifier
    })

    self.fetchesInProgress[identifier] = fetch

    fetch.onComplete = onComplete
end

function DownloadManager:updateDownloads()
    local linda = self.lanesHttp
    local downloadsToRemove = {}
    local fetchesToRemove = {}

    for identifier, file in pairs(self.downloadsInProgress) do
        local progressKey = 'progress_' .. identifier
        local completedKey = 'completed_' .. identifier
        local errorKey = 'error_' .. identifier

        local key, val = linda:receive(0, completedKey, errorKey, progressKey)
        if key and val then
            if key == completedKey then
                self.completedFiles = self.completedFiles + 1
                self.activeDownloads = self.activeDownloads - 1
                downloadsToRemove[identifier] = true
                self:processQueue()
            elseif key == errorKey then
                self.completedFiles = self.completedFiles + 1
                self.activeDownloads = self.activeDownloads - 1
                downloadsToRemove[identifier] = true
                self:processQueue()
            elseif key == progressKey then
                local fileProgress = 0
                if val.total > 0 then
                    fileProgress = (val.downloaded / val.total) * 100
                else
                    fileProgress = 0
                end

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
            end
        end
    end

    for identifier, fetch in pairs(self.fetchesInProgress) do
        local completedKey = 'completed_' .. identifier
        local errorKey = 'error_' .. identifier

        local key, val = linda:receive(0, completedKey, errorKey)
        if key and val then
            if key == completedKey then
                local content = val.content
                local success, decoded = pcall(decodeJson, content)
                if success then
                    fetch.onComplete(decoded)
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

    for identifier in pairs(downloadsToRemove) do
        self.downloadsInProgress[identifier] = nil
    end

    for identifier in pairs(fetchesToRemove) do
        self.fetchesInProgress[identifier] = nil
    end

    if self.activeDownloads == 0 and #self.downloadQueue == 0 and not self.hasCompleted then
        self:completeBatch()
    end

    if self.activeFetches == 0 and #self.fetchQueue == 0 and not self.isFetching then
        self.isFetching = false
    end
end

local downloadManager = DownloadManager:new(10)

local downloadProgress = {
    currentFile = "",
    fileProgress = 0,
    overallProgress = 0,
    downloadedSize = 0,
    totalSize = 0,
    totalFiles = 0,
    completedFiles = 0
}

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

function toggleRadio(bool)
	mem.write(0x4EB9A0, bool and 0x8BE98B55 or 0x8B0004C2, 4, false)
end

function getTimeName(hour)
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
    
    return timeNames[hour] or "Invalid hour"
end

local function getWeatherName(weatherId)
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

local function round(value)
    return math.floor(value + 0.5)
end

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

function changeAlpha(color, newAlpha)
    newAlpha = math.max(0, math.min(255, newAlpha))
    local rgb = bit.band(color, 0x00FFFFFF)
    return bit.bor(bit.lshift(newAlpha, 24), rgb)
end

function toUnsignedColor(color)
    return color % (2^32)
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

-- onServerMessage color table
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
       name == "TEAM_MED_COLOR" or
       name == "NEWS" then
        clrs.a = 170
    else
        if name ~= "TEAM_BLUE_COLOR" then
            clrs.a = 255
        end
    end

    clrRGBA[name] = joinARGB(clrs.r, clrs.g, clrs.b, clrs.a, false)
end

local imguiRGBA = {}
for name, color in pairs(clr) do
    -- Extract color components using ABGR format
    local clrs = convertColor(color, true, true, false)

    if name == "REALRED" or 
       name == "REALGREEN" or
       name == "RED" or
       name == "GREEN" or
       name == "FADE5" or
       name == "DARKGREY" then
        clrs.a = 0.8
    else
        clrs.a = 1.0 -- Default alpha value
    end

    imguiRGBA[name] = imgui.ImVec4(clrs.r, clrs.g, clrs.b, clrs.a)
end

function string:upperFirst()
    return (self:gsub("^%l", string.upper))
end

function string:trim()
    return self:match("^%s*(.-)%s*$")
end


-- Global Variables
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle

local autoReboot = false

local PressType = {KeyDown = isKeyDown, KeyPressed = wasKeyPressed}

local changelog = nil
local betatesters = nil

local funcsLoop = {
    callbackCalled = false
}

local resX, resY = getScreenResolution()

local cursorActive = false
local isPlayerPaused = false
local isPlayerAFK = false

local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local autobind_defaultSettings = {
	Settings = {
		enable = true,
        checkForUpdates = true,
        updateInProgress = false,
        lastVersion = "",
        fetchBeta = false,
		autoSave = true,
        autoReconnect = true,
        autoRepair = true,
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
        mustAimToFrisk = true
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
		skinsUrl = Urls.skins,
		namesUrl = Urls.names
	},
    Elements = {
        offeredTo = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 25},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr.WHITE, value = clr.LIGHTBLUE}
        },
        offeredFrom = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 50},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr.WHITE, value = clr.LIGHTBLUE}
        },
        PedsCount = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 75},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr.REALRED, value = clr.WHITE}
        },
        AutoFind = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 100},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr.REALRED, value = clr.WHITE}
        },
        LastBackup = {
            enable = true,
            Pos = {x = resX / 6.0, y = resY / 2 + 125},
            font = "Arial",
            size = 9,
            flags = {BOLD = true, ITALICS = false, BORDER = true, SHADOW = true, UNDERLINE = false, STRIKEOUT = false},
            align = "left",
            colors = {text = clr.REALRED, value = clr.WHITE}
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
        id = -1
    },
	WindowPos = {
		Settings = {x = resX / 2, y = resY / 2},
        VehicleStorage = {x = resX / 2, y = resY / 2},
        Skins = {x = resX / 2, y = resY / 2},
        Keybinds = {x = resX / 2, y = resY / 2},
        Fonts = {x = resX / 2, y = resY / 2},
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
        enable = false
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
        TakePills = {Toggle = true, Keys = {VK_F12}, Type = {'KeyPressed'}},
        AcceptDeath = {Toggle = true, Keys = {VK_OEM_PLUS}, Type = {'KeyPressed'}},
        RequestBackup = {Toggle = true, Keys = {VK_MENU, VK_B}, Type = {'KeyDown', 'KeyPressed'}},
        Reconnect = {Toggle = true, Keys = {VK_SHIFT, VK_0}, Type = {'KeyDown', 'KeyPressed'}},
        UsePot = {Toggle = true, Keys = {VK_F2}, Type = {'KeyPressed'}},
        UseCrack = {Toggle = true, Keys = {VK_F3}, Type = {'KeyPressed'}}
    }
}

local autobind = deepCopy(autobind_defaultSettings)

-- Horizon Server Health
local hzrpHealth = 5000000

local timers = {
	Vest = {timer = 13.0, last = 0, sentTime = 0, timeOut = 3.0},
	Accept = {timer = 0.5, last = 0},
	Heal = {timer = 13.0, last = 0},
	Find = {timer = 20.0, last = 0, sentTime = 0, timeOut = 5.0},
	Muted = {timer = 13.0, last = 0},
	Binds = {timer = 0.5, last = {}},
    Capture = {timer = 1.5, last = 0, sentTime = 0, timeOut = 5.0},
    Sprunk = {timer = 0.2, last = 0},
    Point = {timer = 180.0, last = 0},
    AFK = {timer = 45.0, last = 0, sentTime = 0, timeOut = 5.0}
}

local guardTime = 13.0
local ddguardTime = 6.5

local accepter = {
	enable = false,
	received = false,
	playerName = "",
	playerId = -1,
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
    dialogId = 22272,
    dialogId2 = 22273,
    farming = false,
    harvesting = false,
    harvestingCount = 0
}

local radio = {
    dialogId = 22274,
    current = 0
}

local vehicles = {
    populating = false,
    spawning = false,
    currentIndex = -1,
    initialFetch = false
}

local statusVehicleColors = {
    Stored = clr.REALRED,
    Spawned = clr.REALGREEN,
    Respawned = clr.REALGREEN,
    Occupied = clr.YELLOW,
    Damaged = clr.ORANGE,
    Disabled = clr.REALRED,
    Impounded = clr.REALRED
}

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

local usingSprunk = false

local autocap = false

local gzData = nil
local enteredPoint = false
local preventHeal = false

local names = {}

local family = {
    turfColor = 0x8C0000FF, -- Active Turf Color (Flashing)
    skins = {}
}

local factionData = {
    LSPD = {
        skins = {
            256, 266, 267, 280, 281, 282, 283, 284, 285, 288, 300, 301, 302, 306, 307, 309, 310, 311
        },
        color = clr.TEAM_BLUE_COLOR,
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
        skins = {
            61, 71, 73, 163, 164, 165, 166, 179, 191, 206, 287
        },
        color = clr.ARES,
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
        skins = {
            120, 141, 253, 286, 294
        },
        color = clr.TEAM_FBI_COLOR,
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
        skins = {
            --120, 141, 253, 286, 294
        },
        color = clr.GOV,
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
        skins = {
            265, 266, 267, 280, 281, 282, 283, 284, 285, 288, 300, 301, 302, 306, 307, 309, 310, 311
        },
        color = clr.SASD,
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
    [clr.WHITE] = "No Badge",
    [clr.TEAM_MED_COLOR] = "LSFMD",
    [clr.TEAM_NEWS_COLOR] = "SANEWS",
    [clr.DD] = "DD",
    [clr.YELLOW] = "PB",
    [clr.TWRED] = "MW",
    [clr.ORANGE] = "Prisoner"
}

-- Add Extra Badges to Factions Table
for color, name in pairs(extraBadges) do
    factions.badges[color] = name
end

-- Build Factions Table
for name, faction in pairs(factionData) do
    factions.colors[faction.color] = true

    for _, skinId in pairs(faction.skins) do
        factions.skins[skinId] = true
    end

    table.insert(factions.names, name)
    factions.ranks[name] = faction.ranks
    factions.badges[faction.color] = name
end

local lockers = {
    maxKits = 6,
    blackmarket = {
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
    factionlocker = {
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

local menu = {
    initialized = new.bool(false),
    confirm = {
        window = new.bool(false),
        size = {x = 300, y = 100},
        pivot = {x = 0.5, y = 0.5},
        update = new.bool(false)
    },
	settings = {
        title = ("%s %s - v%s"):format(fa.ICON_FA_SHIELD_ALT, scriptName:upperFirst(), scriptVersion),
		window = new.bool(false),
        size = {x = 588, y = 420},
        pivot = {x = 0.5, y = 0.5},
		pageId = 1,
        dragging = new.bool(true)
	},
    vehiclestorage = {
        title = "Vehicle Storage:",
		window = new.bool(false),
        size = {x = 338, y = 165},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(false)
    },
    keybinds = {
        title = "Keybind Settings",
		window = new.bool(false),
        size = {x = 350, y = 400},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(true)
    },
	fonts = {
        title = "Font Settings",
		window = new.bool(false),
        size = {x = 570, y = 185},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(true)
	},
	skins = {
        title = "Family Skin Selection",
		window = new.bool(false),
        size = {x = 545, y = 420},
        pivot = {x = 0.5, y = 0.5},
		selected = -1,
        dragging = new.bool(true)
	},
	blackmarket = {
		window = new.bool(false),
        size = {x = 226, y = 290},
        pivot = {x = 0.5, y = 0.5},
        pageId = 1,
        dragging = new.bool(true)
	},
	factionlocker = {
		window = new.bool(false),
        size = {x = 226, y = 290},
        pivot = {x = 0.5, y = 0.5},
        pageId = 1,
        dragging = new.bool(true)
	},
	changelog = {
		window = new.bool(false),
        size = {x = 650, y = 400},
        pivot = {x = 0.5, y = 0.5},
        dragging = new.bool(true)
	}
}

local imgui_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove

local fontData = {
    large = {
        size = 14.0,
        font = nil
    },
    medium = {
        size = 12.0,
        font = nil
    },
    small = {
        size = 8.0,
        font = nil
    }
}

local menuStates = {
    settings = menu.settings.window,
    keybinds = menu.keybinds.window,
    fonts = menu.fonts.window,
    skins = menu.skins.window,
    blackmarket = menu.blackmarket.window,
    factionlocker = menu.factionlocker.window,
    vehiclestorage = menu.vehiclestorage.window,
    confirm = menu.confirm.window,
    changelog = menu.changelog.window
}

local previousMenuStates = {
    settings = false,
    keybinds = false,
    fonts = false,
    skins = false,
    blackmarket = false,
    factionlocker = false,
    vehiclestorage = false,
    confirm = false,
    changelog = false
}

local tempOffset = {x = 0, y = 0}
local currentlyDragging = nil

local escapePressed = false

local skinTextures = {}
local skinsUrls = {}

local updateStatus = "up_to_date"
local currentContent = nil
local isUpdateHovered = false

local changeKey = {}
local keyEditors = {
    {label = "Accept", key = "Accept", description = "Accepts a vest from someone. (Options are to the left)"},
    {label = "Offer", key = "Offer", description = "Offers a vest to someone. (Options are to the left)"},
    {label = "Take-Pills", key = "TakePills", description = "Types /takepills."},
    {label = "Accept-Death", key = "AcceptDeath", description = "Types /acceptdeath."},
    {label = "Frisk", key = "Frisk", description = "Frisks a player. (Options are to the left)"},
    {label = "Bike-Bind", key = "BikeBind", description = "Makes bikes/motorcycles/quads faster by holding the bind key while riding."},
    {label = "Sprint-Bind", key = "SprintBind", description = "Makes you sprint faster by holding the bind key while sprinting. (This is only the toggle)"},
    {label = "Request Backup", key = "RequestBackup", description = "Types the backup command depending on what mode is detected"},
    {label = "Use Crack", key = "UseCrack", description = "Types /usecrack."},
    {label = "Use Pot", key = "UsePot", description = "Types /usepot."}
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

-- Dynamically add ignore keys for BlackMarket and FactionLocker
local ignoreKeysMap = {
    AutoVest = {"skins", "names"},
    Keybinds = {"BikeBind", "SprintBind", "Frisk", "TakePills", "Accept", "Offer", "AcceptDeath", "RequestBackup", "UseCrack", "UsePot"},
    BlackMarket = {"Locations"},
    FactionLocker = {"Locations"},
    VehicleStorage = {"Vehicles"}
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
        local success, config, err = handleConfigFile(Files[section:lower()], autobind_defaultSettings[section], autobind[section], ignoreKeys)
        if not success then
            print("Failed to handle config file for " .. section .. ": " .. err)
            return
        end
        autobind[section] = deepCopy(config)
    end
end

function saveAllConfigs()
    for _, section in ipairs(sections) do
        local success, err = saveConfigWithErrorHandling(Files[section:lower()], autobind[section])
        if not success then
            print("Failed to save config file for " .. section .. ": " .. err)
        end
    end
end

function initializeComponents()
    -- Check if update is in progress and check update status
    if autobind.Settings.updateInProgress then
        formattedAddChatMessage(("You have successfully upgraded from Version: %s to %s"):format(autobind.Settings.lastVersion, scriptVersion))
        autobind.Settings.updateInProgress = false
        saveConfigWithErrorHandling(Files.settings, autobind.Settings)
    end

    updateCheck()

    -- Set autovest timer based on donor status
    timers.Vest.timer = autobind.AutoVest.Donor and ddguardTime or guardTime

    -- Fetch Skins and Names
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

    -- Fetch Betatesters and Changelog
    fetchJsonDataDirectlyFromURL(Urls.betatesters, function(decodedData)
        betatesters = decodedData or nil
    end)

    fetchJsonDataDirectlyFromURL(Urls.changelog, function(decodedData)
        changelog = decodedData or nil
    end)

    -- Startup Timers
    for name, timer in pairs(timers) do
        if type(timer.last) == "number" and name ~= "AFK" then
            timer.last = localClock() - timer.timer
        end
        if type(timer.sentTime) == "number" then
            timer.sentTime = localClock() - timer.timeOut
        end
    end

    -- Setup Skins
    skinsUrls = generateSkinsUrls()
    downloadSkins(skinsUrls)

    -- Setup Locker Keybinds
    InitializeLockerKeyFunctions(autobind.BlackMarket.maxKits, "Black Market", "/bm")
    InitializeLockerKeyFunctions(autobind.FactionLocker.maxKits, "Faction Locker", "/locker")

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

    -- Initialize Menu
    menu.initialized[0] = true
end

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

    while true do wait(0)
        -- Check if not connected to the server
        if sampGetGamestate() ~= 3 then
            resetAccepterAndBodyguard()

            if autobind.CurrentPlayer.name ~= "" and autobind.CurrentPlayer.id ~= -1 then
                autobind.CurrentPlayer.name = ""
                autobind.CurrentPlayer.id = -1
            end
        end
        
        -- Check if dialog is active
        local result, button, _, _ = sampHasDialogRespond(farmer.dialogId)
        if result then
            if button == 1 then
                if isCharInAnyCar(ped) or isCharSittingInAnyCar(ped) then
                    formattedAddChatMessage("You cannot close this dialog while in a vehicle.")
                    createFarmerDialog()
                end
            elseif button == 0 then
                -- Disable auto farming
                formattedAddChatMessage("You have disabled auto farming.")
                autobind.Settings.autoFarm = false
            
                -- Reset farming
                farmer.farming = false
                farmer.harvesting = false
                farmer.harvestingCount = 0
            end
        end

        -- Check if dialog is active
        local result2, button2, _, _ = sampHasDialogRespond(farmer.dialogId2)
        if result2 then
            if button2 == 1 then
                -- Reset farming
                farmer.farming = false
                farmer.harvesting = false
                farmer.harvestingCount = 0
            elseif button2 == 0 then
                -- Enable farming
                farmer.farming = true
                autobind.Settings.autoFarm = true
                formattedAddChatMessage("You have enabled auto farming.")
            end
        end

        -- Radio
        local result3, button3, list3, _ = sampHasDialogRespond(radio.dialogId)
        if result3 then
            if button3 == 1 then
                if list3 ~= 12 then
                    formattedAddChatMessage(("You have selected radio station %d: %s - %s."):format(list3, radioStations[list3].name, radioStations[list3].desc))
                    lua_thread.create(function()
                        if not autobind.Settings.noRadio then
                            autobind.Settings.noRadio = true
                            toggleRadio(true)
                            wait(500)
                        end

                        -- Fix user tracks
                        if list3 == 11 then 
                            list3 = 24
                        end

                        setRadioChannel(list3)
                    end)
                else
                    formattedAddChatMessage("You have selected radio station 12: Radio Off.")
                    lua_thread.create(function()
                        if autobind.Settings.noRadio then
                            autobind.Settings.noRadio = false
                            setRadioChannel(list3)
                            wait(500)
                            toggleRadio(false)
                        end
                    end)
                end
            end
        end

        -- Reset Locker Processing if player is not in location
        resetLockerProcessing("factionlocker", autobind.FactionLocker.Locations)
        resetLockerProcessing("blackmarket", autobind.BlackMarket.Locations)

        -- Get Radio Channel if player is in a vehicle
        if isCharInAnyCar(ped) then
            radio.current = getRadioChannel()
        end

        -- Get the status of samps cursor
        cursorActive = sampIsCursorActive()

        -- Vehicle Storage
        if autobind.VehicleStorage.enable then
            menu.vehiclestorage.window[0] = (--[[sampGetChatInputText():find("/v") and ]]sampIsChatInputActive()) and true or false
        end

        -- Initialize Components and send success message
        functionsLoop(function(started, failed)
            initializeComponents()

            formattedAddChatMessage(("%s has loaded successfully! {%06x}Type /%s help for more information."):format(scriptVersion, clr.GREY, shortName))
        end)
    end
end

function resetLockerProcessing(name, locations)
    if lockers[name].isProcessing and not isPlayerInLocation(locations) then
        lockers[name].isProcessing = false
        lockers[name].isBindActive = false
        lockers[name].thread = nil
        formattedAddChatMessage("You left the locker room area while getting items. Please retrieve items again.")
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

local function checkBodyguardCondition()
    return bodyguard.enable or autobind.AutoVest.donor
end

local function checkAnimationCondition(playerId)
    local pAnimId = sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(ped)))
    local pAnimId2 = sampGetPlayerAnimationId(playerId)
    return not (invalidAnimsSet[pAnimId] or pAnimId2 == 746 or isButtonPressed(h, gkeys.player.LOCKTARGET))
end

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
        return factions.colors[changeAlpha(playerColor, 0)] and (not autobind.AutoVest.useSkins or factions.skins[skinId]) ~= nil
    end

    return false
end

function checkAndSendVest(skipArmorCheck)
    local currentTime = localClock()
    if not autobind.AutoVest.enable and not skipArmorCheck then
        return
    end

    if isPlayerAFK then
        return "You cannot send a vest while AFK, move your character."
    end

    if checkAdminDuty() then
        return "You are on admin duty, you cannot send a vest."
    end

    if not isPlayerControlOn(h) then
        return "You cannot send a vest while frozen, please wait."
    end

    if not checkBodyguardCondition() then
        return "You cannot send a vest while not a bodyguard."
    end

    if checkMuted() then
        return "You cannot send a vest while muted, please wait."
    end

    if bodyguard.received then
        if currentTime - timers.Vest.sentTime > timers.Vest.timeOut then
            bodyguard.received = false
        else
            return "Vest has been sent, please wait."
        end
    end

    if (currentTime - timers.Vest.last) < timers.Vest.timer then
        local timeLeft = math.ceil(timers.Vest.timer - (currentTime - timers.Vest.last))
        return string.format("You must wait %d seconds before sending vest.", timeLeft > 1 and timeLeft or 1)
    end

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

function checkAndAcceptVest(autoaccept)
	local currentTime = localClock()
	if currentTime - timers.Accept.last < timers.Accept.timer then
		return
	end

    if isPlayerAFK then
        return "You cannot accept a vest while AFK, move your character."
    end

    if checkAdminDuty() then
        return "You are on admin duty, you cannot accept a vest."
    end

	if checkMuted() then
		return "You cannot accept a vest while muted, please wait."
	end

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

function handleLocker(kitNumber, name, command)
    local fullName = name:gsub(" ", "")
    local lowerName = fullName:lower()

    if lockers[lowerName].isBindActive then
        print("isBindActive")
        return
    end

    lockers[lowerName].isBindActive = true

    if lockers[lowerName].isProcessing then
        formattedAddChatMessage(("You are already getting items from %s, please wait."):format(name), clr.YELLOW)
        lockers[lowerName].isBindActive = false
        return
    end

    if checkMuted() then
        formattedAddChatMessage("You have been muted for spamming, please wait.", clr.YELLOW)
        lockers[lowerName].isBindActive = false
        return
    end

    if not isPlayerInLocation(autobind[fullName].Locations) then
        formattedAddChatMessage(("You are not at the %s!"):format(name), clr.GREY)
        lockers[lowerName].isBindActive = false
        return
    end

    if not isPlayerControlOn(h) then
        formattedAddChatMessage("You cannot get items while frozen, please wait.", clr.YELLOW)
        lockers[lowerName].isBindActive = false
        return
    end

    if checkHeal() then
        local timeLeft = math.ceil(timers.Heal.timer - (localClock() - timers.Heal.last))
        formattedAddChatMessage(string.format("You must wait %d seconds before getting items.", timeLeft > 1 and timeLeft or 1))
        lockers[lowerName].isBindActive = false
        return
    end

    -- Check if the player can afford the kit
    local money = getPlayerMoney()
    local totalPrice = calculateTotalPrice(autobind[fullName]["Kit" .. kitNumber], lockers[lowerName].Items)
    if totalPrice and money < totalPrice and totalPrice ~= 0 then
        formattedAddChatMessage(("You do not have enough money to buy this kit, you need $%s more. Total price: $%s."):format(
            formatNumber(totalPrice - money), 
            formatNumber(totalPrice)), 
        clr.YELLOW)
        lockers[lowerName].isBindActive = false
        return
    end

    -- Start processing and reset bind
    lockers[lowerName].isProcessing = true
    lockers[lowerName].isBindActive = false

    -- Start fresh
    resetLocker(lowerName)
    lockers[lowerName].getItemFrom = kitNumber
    lockers[lowerName].thread = nil

    lockers[lowerName].thread = lua_thread.create(function()
        local kitItems = autobind[fullName]["Kit" .. kitNumber]

        -- Check for what items are needed
        local neededItems = {}
        local skippedItems = {}
        for _, itemIndex in ipairs(kitItems) do
            local item = lockers[lowerName].Items[itemIndex]
            if item then
                if canObtainItem(item, lockers[lowerName].Items) then
                    table.insert(neededItems, item)
                else
                    table.insert(skippedItems, item.label)
                end
            end
        end

        -- Start getting items
        for i, item in ipairs(neededItems) do
            if not lockers[lowerName].isProcessing --[[or lockers[lowerName].isBindActive]] then
                return
            end

            lockers[lowerName].currentKey = item.index
            lockers[lowerName].gettingItem = true
            sampSendChat(command)
            
            repeat wait(0) until not lockers[lowerName].gettingItem
            
            table.insert(lockers[lowerName].obtainedItems, item.label)

            if (i % 3 == 0) and (i < #neededItems) then
                local waitTime = math.random(1500, 1750)
                
                local stillNeeded = {}
                for j = i + 1, #neededItems do
                    table.insert(stillNeeded, neededItems[j].label)
                end

                formattedAddChatMessage(string.format(
                    "You are still getting %d items from %s, please wait %0.1f seconds.",
                    (#neededItems - i),
                    name:lower(),
                    waitTime / 1000
                ), clr.YELLOW)

                formattedAddChatMessage(string.format("Items left: {%06x}%s", clr.WHITE, table.concat(stillNeeded, ", ")), clr.YELLOW)
                
                wait(waitTime)
            end
            wait(200)
        end

        -- Check if items were obtained
        if #lockers[lowerName].obtainedItems > 0 then
            formattedAddChatMessage(string.format("Obtained items: {%06x}%s.", clr.WHITE, table.concat(lockers[lowerName].obtainedItems, ", ")), clr.YELLOW)
        end
        
        -- Check if items were skipped
        if #skippedItems > 0 then
            formattedAddChatMessage(string.format("Skipped items: {%06x}%s.", clr.WHITE, table.concat(skippedItems, ", ")), clr.REALRED)
        end

        wait(1500)

        -- Verify items are actually in the player's possession now
        local notObtained = {}
        for _, item in ipairs(neededItems) do
            if canObtainItem(item, lockers[lowerName].Items) then
                table.insert(notObtained, item.label)
            end
        end

        -- If anything is still missing, notify the player
        if #notObtained > 0 then
            formattedAddChatMessage(("The following items were not successfully fetched (due to lag or other issues): {%06x}%s"):format(
                clr.REALRED,
                table.concat(notObtained, ", ")
            ), clr.YELLOW)
        end
        
        -- Reset processing and locker
        lockers[lowerName].isProcessing = false
        resetLocker(lowerName)
    end)
end

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

        local targeting = getCharPlayerIsTargeting(h)
        for _, player in ipairs(getVisiblePlayers(5, "all")) do
            if (isButtonPressed(h, gkeys.player.LOCKTARGET) and autobind.Settings.mustAimToFrisk) or not autobind.Settings.mustAimToFrisk then
                if (targeting and autobind.Settings.mustTargetToFrisk) or not autobind.Settings.mustTargetToFrisk then
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
    end
}

function InitializeLockerKeyFunctions(maxKits, name, command)
    local fullName = name:gsub(" ", "")

    for kitId = 1, maxKits do
        if keyFunctions[fullName .. kitId] == nil then
            keyFunctions[fullName .. kitId] = function()
                handleLocker(kitId, name, command)
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
    local currentTime = localClock()
    for key, value in pairs(autobind.Keybinds) do
        local bind = {
            keys = value.Keys,
            type = value.Type
        }

        -- Check if the player is processing a locker and return if so
        if (key:find("FactionLocker") and lockers.factionlocker.isProcessing) or (key:find("BlackMarket") and lockers.blackmarket.isProcessing) then
            return
        end

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
    ELS3A = "The Court", ELS3C = "Alleyway", ELS4 = "Carwash", ELCO1 = "Unity Station", ELCO2 = "Apartments", LIND1A = "West", LIND2A = "South", LIND2B = "South", LIND3 = "East"
}

function getSubZoneName(x, y, z)
    return subZones[getNameOfInfoZone(x, y, z)] or nil
end
 
function createAutoCapture()
    if not autocap or checkMuted() or checkAdminDuty() then
        return
    end

	local currentTime = localClock()
	if currentTime - timers.Capture.last >= timers.Capture.timer then
		sampSendChat("/capturf")
		timers.Capture.last = currentTime
	end
end

function createPointBounds()
    -- Reset data if you are not connected to a server
    if sampGetGamestate() ~= 3 then
        gzData = nil
        return
    end

    if not gzData then
        gzData = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
        return
    end

    if autobind.Settings.mode ~= "Family" then
        return
    end

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
    if not autofind.enable or checkMuted() or isPlayerAFK then
        return
    end

    -- Check if the player is frozen
    if not isPlayerControlOn(h) then
        return
    end

    if not sampIsPlayerConnected(autofind.playerId) then
        formattedAddChatMessage("The player you were finding has disconnected, you are no longer finding anyone.")
        autofind.enable = false
        return
    end

    local currentTime = localClock()
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
    local health = getCharHealth(ped) - hzrpHealth
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
    local currentTime = localClock()

    -- Check if the initial AFK start condition is true
    if initialAFKStart then
        setTimer(45.0, timers.AFK)  -- Reset the timer for the next AFK check
        initialAFKStart = false
        isPlayerAFK = false
        return
    end

    -- Check if the AFK timer has expired (player is considered AFK)
    if currentTime - timers.AFK.last >= timers.AFK.timer then
        timers.AFK.last = currentTime
        isPlayerAFK = true
        return
    end

    -- Check if the AFK timer reset timeout has passed.
    if currentTime - timers.AFK.sentTime <= timers.AFK.timeOut then
        return
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
                return
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
                return
            end
        end
    end
end

-- Functions Table
local functionsToRun = {
    {
        id = 1,
        name = "DownloadManager",
        func = function()
            if downloadManager and (downloadManager.isDownloading or downloadManager.isFetching) then
                downloadManager:updateDownloads()
            end
        end,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 2,
        name = "AutoVest",
        func = function()
            checkAndSendVest(false)
        end,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 3,
        name = "AutoAccept",
        func = function() 
            checkAndAcceptVest(accepter.enable)
        end,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 4,
        name = "Keybinds",
        func = createKeybinds,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 5,
        name = "AutoCapture",
        func = createAutoCapture,
        interval = 0.001,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 6,
        name = "PointBounds",
        func = createPointBounds,
        interval = 1.5,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 7,
        name = "AutoFind",
        func = createAutoFind,
        interval = 0.0,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 8,
        name = "SprunkSpam",
        func = createSprunkSpam,
        interval = 0.01,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    },
    {
        id = 9,
        name = "AFKCheck",
        func = createAFKCheck,
        interval = 0.5,
        lastRun = localClock(),
        enabled = true,
        status = "idle"
    }
}

-- Define the delay before a restarted function becomes "running" (in seconds)
local restartDelay = 5.0

-- Functions Loop now stores status in each functionsToRun entry.
function functionsLoop(onFunctionsStatus)
    -- Check if the autobind is enabled
    if isPlayerPaused then
        return
    end

    local currentTime = localClock()
    for _, item in ipairs(functionsToRun) do
        if item.enabled and (currentTime - item.lastRun >= item.interval) then
            local success, err = xpcall(item.func, debug.traceback)
            if not success then
                print(string.format("Error in %s function: %s", item.name, err))
                item.errorCount = (item.errorCount or 0) + 1
                item.status = "failed"

                if item.errorCount >= 5 then
                    print(string.format("%s function disabled after repeated errors.", item.name))
                    item.enabled = false
                    item.status = "disabled"
                end
            else
                item.errorCount = 0
                -- If the function was idle, simply update to running.
                if item.status == "idle" then
                    item.status = "running"
                end
            end
            item.lastRun = currentTime
        end

        -- Update functions that are in the "restarted" state.
        if item.status == "restarted" and item.restartTimestamp and 
           (currentTime - item.restartTimestamp >= restartDelay) then
            item.status = "running"
        end
    end

    -- Use status from functionsToRun for the callback.
    if onFunctionsStatus and not funcsLoop.callbackCalled then
        local started = {}
        local failed = {}
        for _, item in ipairs(functionsToRun) do
            local status = item.status or "unknown"
            if status == "running" or status == "idle" or status == "restarted" then
                table.insert(started, item.name)
            elseif status == "failed" then
                table.insert(failed, item.name)
            end
        end
        onFunctionsStatus(started, failed)
        funcsLoop.callbackCalled = true
    end
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
    for _, item in ipairs(functionsToRun) do
        if item.name:lower() == name:lower() then
            item.enabled = false  -- temporarily disable
            item.errorCount = 0
            item.lastRun = localClock()
            item.enabled = true   -- then re-enable
            item.status = "restarted"
            item.restartTimestamp = localClock()

            if callback then
                callback(item.name, "restarted")
            end
            return
        end
    end
    print("Function " .. name .. " not found.")
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
                formattedAddChatMessage(string.format("Now finding: {%06x}%s (ID %d).", clr.REALGREEN, displayName, playerid))
                autofind.location = ""
                return
            end
    
            autofind.enable = true
            formattedAddChatMessage(string.format("Finding: {%06x}%s (ID %d). {%06x}Type /%s again to toggle off.", clr.REALGREEN, autofind.playerName:gsub("_", " "), autofind.playerId, clr.WHITE, cmd))
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
            autobind.AutoVest.enable = toggleBind("Auto Guard", autobind.AutoVest.enable)
        end
    },
	autoaccept = {
        cmd = "autovest",
        alt = {"avest", "av"},
        desc = "Automatically accepts vest offers from other players",
        id = 9,
        func = function(cmd)
            accepter.enable = toggleBind("Auto Vest", accepter.enable)
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
        desc = "Allows you to offer vests to all players, byasses any armor/skin/color restrictions",
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
            -- If no params are provided, just display usage and open /vst dialog
            if not params or params == "" then
                sampSendChat("/vst")
                formattedAddChatMessage(string.format("USAGE: /%s [slot ID or partial vehicle name]", cmd))
                return
            end
    
            if not autobind.Settings.enable then
                formattedAddChatMessage("Autobind is currently disabled!")
                return
            end
    
            local playerName = autobind.CurrentPlayer.name
            if not playerName or playerName == "" then
                local _, playerId = sampGetPlayerIdByCharHandle(ped)
                if not playerId then
                    formattedAddChatMessage("Current player not found!")
                    return
                end
                playerName = sampGetPlayerNickname(playerId)
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
                        (" • Slot %d => Vehicle: %s, Status: %s, Location: %s"):format(
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
            local playerName = autobind.CurrentPlayer.name
            if not playerName or playerName == "" then
                local _, playerId = sampGetPlayerIdByCharHandle(ped)
                if not playerId then
                    formattedAddChatMessage("Current player not found!")
                    return
                end

                playerName = sampGetPlayerNickname(playerId)
            end

            autobind.VehicleStorage.Vehicles[playerName] = {}
            formattedAddChatMessage("Your vehicle storage has been reset, populating vehicles...")
            vehicles.initialFetch = false
            vehicles.populating = true
            sampSendChat("/vst")
        end
    },
    autofarm = {
        cmd = "autofarm",
        desc = "Toggles auto farming to manage crops automatically",
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
                formattedAddChatMessage(string.format("Success: {%06x}Locks personal vehicle and picks the lock again. (Good for leveling up)", clr.GREY))
                formattedAddChatMessage(string.format("Fail: {%06x}Keeps trying to pick the lock on failure.", clr.GREY))
            elseif params:match("^success$") then
                formattedAddChatMessage(string.format("Success: {%06x}Locks personal vehicle and picks the lock again. (Good for leveling up)", clr.GREY))
                autobind.Settings.autoPicklockOnSuccess = toggleBind("Auto Picklock On Success", autobind.Settings.autoPicklockOnSuccess)
            elseif params:match("^fail$") then
                formattedAddChatMessage(string.format("Fail: {%06x}Keeps trying to pick the lock on failure.", clr.GREY))
                autobind.Settings.autoPicklockOnFail = toggleBind("Auto Picklock On Fail", autobind.Settings.autoPicklockOnFail)
            else
                formattedAddChatMessage(string.format("USAGE: /%s [success|fail]", cmd))
            end
        end
    },
    autobadge = {
        cmd = "autobadge",
        desc = "Types /badge when you spawn",
        id = 17,
        func = function(cmd)
            autobind.Faction.autoBadge = toggleBind("Auto Badge", autobind.Faction.autoBadge)
        end
    },
    reconnect = {
        cmd = "recon",
        desc = "Reconnects to the server",
        id = 18,
        func = function(cmd)
            GameModeRestart()
            sampSetGamestate(1)
        end
    },
    autoreconnect = {
        cmd = "autorecon",
        desc = "Auto reconnects on rejection, closure, ban, or disconnection",
        id = 19,
        func = function(cmd)
            autobind.Settings.autoReconnect = toggleBind("Auto Reconnect", autobind.Settings.autoReconnect)
        end
    },
    name = {
        cmd = "name",
        desc = "Changes your name and reconnects you to the server",
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
            formattedAddChatMessage(string.format("Your name has been changed to {%06x}%s.", clr.GREY, params))
            GameModeRestart()
            sampSetGamestate(1)
        end
    },
    changemode = {
        cmd = "changemode",
        alt = {"switchmode"},
        desc = "Switches between Faction and Family mode",
        id = 21,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format("Current Mode: {%06x}%s.", clr.GREY, autobind.Settings.mode or "N/A"))
                formattedAddChatMessage(string.format("USAGE: /%s [faction|family]", cmd))
            elseif params:match("^faction$") then
                formattedAddChatMessage(string.format("You have changed the mode to {%06x}Faction.", clr.GREY))
                autobind.Settings.mode = "Faction"
            elseif params:match("^family$") then
                formattedAddChatMessage(string.format("You have changed the mode to {%06x}Family.", clr.GREY))
                autobind.Settings.mode = "Family"
            else
                formattedAddChatMessage(string.format("USAGE: /%s [faction|family]", cmd))
            end
        end
    },
    weather = {
        cmd = "changeweather",
        alt = {"cw"},
        desc = "Manage weather settings or set by ID",
        id = 22,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format(
                    "Status: {%06x}%s{%06x}, Current Weather: {%06x}%s (%d).",
                    autobind.TimeAndWeather.modifyWeather and clr.REALGREEN or clr.REALRED, 
                    autobind.TimeAndWeather.modifyWeather and "Enabled" or "Disabled",
                    clr.WHITE,
                    clr.LIGHTBLUE, 
                    getWeatherName(autobind.TimeAndWeather.weather),
                    autobind.TimeAndWeather.weather
                ))
                formattedAddChatMessage(string.format("Server Weather: {%06x}%s (%d).", clr.LIGHTBLUE, getWeatherName(autobind.TimeAndWeather.serverWeather), autobind.TimeAndWeather.serverWeather))
                formattedAddChatMessage(string.format("USAGE: /%s [weatherId|help|toggle|reset]", cmd))
                return
            end

            if params:match("^help$") then
                formattedAddChatMessage(string.format("USAGE: /%s [weatherId|toggle|reset]", cmd))
                formattedAddChatMessage(string.format("Toggle: {%06x}Toggles weather on or off.", clr.GREY))
                formattedAddChatMessage(string.format("Reset: {%06x}Resets weather to default.", clr.GREY))
                formattedAddChatMessage(string.format("WeatherId: {%06x}Sets the weather to the specified ID.", clr.GREY))
            elseif params:match("^toggle$") then
                autobind.TimeAndWeather.modifyWeather = toggleBind("Weather", autobind.TimeAndWeather.modifyWeather)

                if autobind.TimeAndWeather.modifyWeather then
                    setWeather(autobind.TimeAndWeather.weather)
                else
                    setWeather(autobind.TimeAndWeather.serverWeather or autobind_defaultSettings.TimeAndWeather.serverWeather)
                end
            elseif params:match("^reset$") then
                autobind.TimeAndWeather.weather = autobind_defaultSettings.TimeAndWeather.weather
                formattedAddChatMessage("Weather has been reset to default.")
                if autobind.TimeAndWeather.modifyWeather then
                    setWeather(autobind.TimeAndWeather.weather)
                end
            else
                local weatherId = tonumber(params)
                if weatherId and weatherId >= 0 and weatherId <= 50 then
                    autobind.TimeAndWeather.weather = weatherId
                    formattedAddChatMessage(string.format("Weather has been set to {%06x}%s (%d).", clr.LIGHTBLUE, getWeatherName(weatherId), weatherId))

                    if autobind.TimeAndWeather.modifyWeather then
                        setWeather(weatherId)
                    end
                else
                    formattedAddChatMessage(string.format("USAGE: /%s [weatherId|help|toggle|reset]", cmd))
                end
            end
        end
    },
    settime = {
        cmd = "changetime",
        alt = {"ct"},
        desc = "Sets the hour and minute.",
        id = 23,
        func = function(cmd, params)
            if #params < 1 then
                formattedAddChatMessage(string.format("Status: {%06x}%s{%06x}, Current Time: {%06x}%s (%02d:%02d).", autobind.TimeAndWeather.modifyTime and clr.REALGREEN or clr.REALRED, autobind.TimeAndWeather.modifyTime and "Enabled" or "Disabled", clr.WHITE, clr.LIGHTBLUE, getTimeName(autobind.TimeAndWeather.hour), autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute))
                formattedAddChatMessage(string.format("Server Time: {%06x}%s (%02d:%02d).", clr.LIGHTBLUE, getTimeName(autobind.TimeAndWeather.serverHour), autobind.TimeAndWeather.serverHour, autobind.TimeAndWeather.serverMinute))
                formattedAddChatMessage(string.format("USAGE: /%s [hour (minute)|help|toggle|reset]", cmd))
                return
            end
    
            if params:match("^help$") then
                formattedAddChatMessage(string.format("USAGE: /%s [hour (minute)|help|toggle|reset]", cmd))
                formattedAddChatMessage(string.format("Toggle: {%06x}Toggles time on or off.", clr.GREY))
                formattedAddChatMessage(string.format("Reset: {%06x}Resets time to default.", clr.GREY))
                formattedAddChatMessage(string.format("Hour: {%06x}Sets the time to the specified hour.", clr.GREY))
                formattedAddChatMessage(string.format("Minute: {%06x}Optional, sets the time to the specified minute.", clr.GREY))
            elseif params:match("^toggle$") then
                autobind.TimeAndWeather.modifyTime = toggleBind("Time", autobind.TimeAndWeather.modifyTime)
                if autobind.TimeAndWeather.modifyTime then
                    setTime(autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute)
                else
                    setTime(autobind.TimeAndWeather.serverHour, autobind.TimeAndWeather.serverMinute)
                end
            elseif params:match("^reset$") then
                autobind.TimeAndWeather.hour = autobind_defaultSettings.TimeAndWeather.hour
                autobind.TimeAndWeather.minute = autobind_defaultSettings.TimeAndWeather.minute
                formattedAddChatMessage("Time has been reset to default.")
                if autobind.TimeAndWeather.modifyTime then
                    setTime(autobind.TimeAndWeather.hour, autobind.TimeAndWeather.minute)
                end
            else
                local hour, minute = params:match("^(%d+)%s*(%d*)$")
                hour = tonumber(hour)
                minute = tonumber(minute) or 0
    
                if hour and hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 then
                    autobind.TimeAndWeather.hour = hour
                    autobind.TimeAndWeather.minute = minute
                    formattedAddChatMessage(string.format("Time has been set to {%06x}%s (%02d:%02d).", clr.LIGHTBLUE, getTimeName(hour), hour, minute))
    
                    if autobind.TimeAndWeather.modifyTime then
                        setTime(hour, minute)
                    end
                else
                    formattedAddChatMessage(string.format("USAGE: /%s [hour (minute)|help|toggle|reset]", cmd))
                end
            end
        end
    },
    radio = {
        cmd = "radio",
        desc = "Toggles radio on or off, or sets a favorite radio channel",
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
                local radioInfo = radioStations[radio.current]
                if not radioInfo then
                    radioInfo = radioStations[12]
                end

                formattedAddChatMessage(string.format(
                    "Status: {%06x}%s{%06x}, Current Radio: {%06x}%s.", 
                    autobind.Settings.noRadio and clr.GREEN or clr.RED, 
                    autobind.Settings.noRadio and "On" or "Off",
                    clr.WHITE,
                    clr.LIGHTBLUE, 
                    autobind.Settings.noRadio and radioInfo.name or "Radio Off"
                ))
                formattedAddChatMessage(string.format("USAGE: /%s [channel number|toggle|fav|list]", cmd))
                return
            end

            if params:match("^toggle$") then
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
                        formattedAddChatMessage(string.format("Radio has been turned on, favorite channel set to {%06x}%s.", clr.LIGHTBLUE, radioStations[autobind.Settings.favoriteRadio].name))
                        return
                    end
                end)
            elseif params:match("^fav%s*(%d*)") then
                local newParams = params:match("^fav%s*(%d*)")
                if #newParams < 1 then
                    setRadioChannel(autobind.Settings.favoriteRadio)
                    formattedAddChatMessage(string.format("Favorite radio channel has been set to {%06x}%s.", clr.LIGHTBLUE, radioStations[autobind.Settings.favoriteRadio].name))
                else
                    local channel = tonumber(newParams)
                    if channel and channel >= 0 and channel <= 11 then
                        formattedAddChatMessage(string.format("Favorite radio channel has been set to {%06x}%s.", clr.LIGHTBLUE, radioStations[channel].name))

                        -- Fix user tracks
                        if channel == 11 then channel = 24 end

                        autobind.Settings.favoriteRadio = channel

                        setRadioChannel(channel)
                    else
                        formattedAddChatMessage(string.format("USAGE: /%s [channel number|toggle|fav|list]", cmd))
                    end
                end
            elseif params:match("^list$") then
                local messages = ""
                for i = 0, 12 do
                    messages = messages .. string.format("%d: {%06x}%s{%06x} - {%06x}%s\n", i, clr.LIGHTBLUE, radioStations[i].name, clr.WHITE, clr.GREY, radioStations[i].desc)
                end

                local title = string.format("[%s] Radio List", shortName:upper())
                sampShowDialog(radio.dialogId, title, messages, "Select", "Close", 2)
            else
                local channel = tonumber(params)
                if channel and channel >= 0 and channel <= 11 then
                    formattedAddChatMessage(string.format("Radio channel has been set to {%06x}%s.", clr.LIGHTBLUE, radioStations[channel].name))
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
                    formattedAddChatMessage(string.format("USAGE: /%s [channel number|toggle|fav|list]", cmd))
                end
            end
        end
    },
    secondarybackup = {
        cmd = "secondarybackup",
        alt = {"sb"},
        desc = "Toggles secondary backup call on or off",
        id = 25,
        func = function(cmd)
            autobind.Settings.callSecondaryBackup = toggleBind("Secondary Backup", autobind.Settings.callSecondaryBackup)
        end
    },
    hzradio = {
        cmd = "hzradio",
        desc = "Toggles Hz Radio on or off",
        id = 26,
        func = function(cmd)
            autobind.Settings.HZRadio = toggleBind("Horizon Radio", autobind.Settings.HZRadio)
        end
    },
    loginmusic = {
        cmd = "loginmusic",
        desc = "Toggles login music on or off",
        id = 27,
        func = function(cmd)
            autobind.Settings.LoginMusic = toggleBind("Login Music", autobind.Settings.LoginMusic)
        end
    }
}

local autobindCommands = {
    [""] = function()
        menu.settings.pageId = 1
        menu.settings.window[0] = not menu.settings.window[0]
    end,
    ["help"] = function(newParams, cmd, alias)
        if #newParams < 1 then
            formattedAddChatMessage(string.format("%s {%06x}| Type '/%s %s desc' to display the description of all commands.", cmd:upperFirst(), clr.WHITE, alias, cmd), clr.REALGREEN)
            formattedAddChatMessage(string.format("/%s {%06x}cmds, showkeys, getskin, status, funcs, reload", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s {%06x}fonts, keybinds, skins, bms, locker", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s {%06x}changelog, betatesters", alias, clr.GREY))
        elseif newParams:match("^desc$") then
            formattedAddChatMessage(string.format("/%s {%06x}- Opens the autobind settings menu.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s cmds {%06x}- Lists all commands.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s fonts {%06x}- Opens the font menu for customization.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s keybinds {%06x}- Opens the keybinds menu for customization.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s showkeys {%06x}- Lists all keys for keybinds.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s skins {%06x}- Opens the skins menu for customization.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s getskin [playerid/partofname] {%06x}- Gets the skin ID of a player.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s bms {%06x}- Opens the black market menu.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s locker {%06x}- Opens the faction locker menu.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s status {%06x}- Displays the status of all scripts and the autobind menu.", alias, clr.GREY))
            formattedAddChatMessage(string.format("/%s reload {%06x}- Reloads the script.", alias, clr.GREY))
        else
            formattedAddChatMessage(string.format("USAGE: '/%s %s desc' for more information.", alias, cmd))
        end
    end,
    ["cmds"] = function(newParams, cmd, alias)
        if #newParams < 1 then
            formattedAddChatMessage(string.format("Commands{%06x} | Type '/%s %s [desc|alts]' to display the description of all commands.", clr.WHITE, alias, cmd), clr.REALGREEN)
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

            formattedAddChatMessage(string.format("%d commands available.", commandCount), clr.GREY)
        elseif newParams:match("^desc$") then
            local sortedCommands = {}
            for _, command in pairs(clientCommands) do
                table.insert(sortedCommands, command)
            end
            table.sort(sortedCommands, function(a, b) return a.id < b.id end)

            for _, command in pairs(sortedCommands) do
                formattedAddChatMessage(string.format("/%s {%06x}- %s. ID: %d", command.cmd, clr.GREY, command.desc, command.id))
            end
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
                    formattedAddChatMessage(string.format("/%s {%06x}- %s.", command.cmd, clr.GREY, table.concat(altList, ", ")))
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
                clr.YELLOW, 
                newName,
                clr.WHITE,
                autobind.Keybinds[bind].Toggle and clr.GREEN or clr.RED, 
                autobind.Keybinds[bind].Toggle and "Yes" or "No",
                clr.WHITE,
                clr.LIGHTBLUE, 
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
            formattedAddChatMessage(string.format("%s {%06x}| Type '/%s %s timers' there are more options below.", cmd:upperFirst(), clr.WHITE, alias, cmd), clr.REALGREEN)
            formattedAddChatMessage("timers, bodyguard, accepter, autofind", clr.GREY)
            formattedAddChatMessage("backup, farmer, misc", clr.GREY)
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
                autofind.playerName ~= "" and clr.REALGREEN or clr.RED, 
                autofindName,
                clr.WHITE,
                autofind.enable and clr.GREEN or clr.RED, 
                autofindEnableStatus,
                clr.WHITE,
                clr.LIGHTBLUE, 
                autofind.counter
            ))
        elseif newParams:match("^backup$") then
            local backupId = backup.playerId ~= -1 and backup.playerId or ""
            local backupName = backup.playerName ~= "" and string.format("%s (%s)", backup.playerName, backupId) or "N/A"
            local backupLocation = backup.location ~= "" and backup.location or "N/A"
            local backupEnableStatus = backup.enable and "Yes" or "No"

            formattedAddChatMessage(string.format(
                "Backup: {%06x}%s{%06x}, Location: {%06x}%s{%06x}, Enabled: {%06x}%s {%06x}(Self).",
                backup.playerName ~= "" and clr.TEAM_BLUE_COLOR or clr.RED, 
                backupName,
                clr.WHITE,
                backup.location ~= "" and clr.GREEN or clr.RED, 
                backupLocation,
                clr.WHITE,
                backup.enable and clr.GREEN or clr.RED, 
                backupEnableStatus,
                clr.WHITE
            ))
        elseif newParams:match("^farmer$") then
            local farmerEnableStatus = farmer.farming and "Yes" or "No"
            local farmerHarvestingStatus = farmer.harvesting and "Yes" or "No"

            formattedAddChatMessage(string.format(
                "Farming: {%06x}%s{%06x}, Harvesting: {%06x}%s{%06x}, Counter: {%06x}%d.",
                farmer.farming and clr.GREEN or clr.RED, 
                farmerEnableStatus,
                clr.WHITE,
                farmer.harvesting and clr.GREEN or clr.RED, 
                farmerHarvestingStatus,
                clr.WHITE,
                clr.LIGHTBLUE, 
                farmer.harvestingCount
            ))
        elseif newParams:match("^misc$") then
            local mode = autobind.Settings.mode or "N/A"
            local factionType = mode == "Faction" and autobind.Faction.type or "N/A"
            local autocapStatus = autocap and "Yes" or "No"
            local sprunkStatus = usingSprunk and "Yes" or "No"
            local pointStatus = enteredPoint and "Yes" or "No"
            local preventHealStatus = preventHeal and "Yes" or "No"

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
            formattedAddChatMessage(string.format("USAGE: '/%s %s [start|stop|restart] [function_name]'", alias, cmd), clr.GREY)

            table.sort(functionsToRun, function(a, b) return a.id < b.id end)

            for _, item in ipairs(functionsToRun) do
                local status = item.status or "unknown"
                local state = item.enabled and "enabled" or "disabled"

                local statusColor
                if status == "running" then
                    statusColor = clr.GREEN
                elseif status == "idle" then
                    statusColor = clr.NEWS
                elseif status == "restarted" then
                    statusColor = clr.YELLOW
                elseif status == "failed" then
                    statusColor = clr.RED
                elseif status == "disabled" or state == "disabled" then
                    statusColor = clr.RED
                else
                    statusColor = clr.GREY
                end
                formattedAddChatMessage(string.format("%s - Status: {%06x}%s{%06x} (%s)", item.name, statusColor, status, clr.WHITE, state))
            end
            return
        elseif action == "start" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s start [function_name]'", alias, cmd), clr.GREY)
            else
                functionManager.start(target, function(name, status)
                    if status == "started" then
                        formattedAddChatMessage(string.format("Started function: {%06x}%s", clr.GREEN, name))
                    else
                        formattedAddChatMessage(string.format("Function %s is already started", name), clr.REALRED)
                    end
                end)
            end
            return
        elseif action == "stop" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s stop [function_name]'", alias, cmd), clr.GREY)
            else
                functionManager.stop(target, function(name, status)
                    if status == "stopped" then
                        formattedAddChatMessage(string.format("Stopped function: {%06x}%s", clr.RED, name))
                    else
                        formattedAddChatMessage(string.format("Function %s is already stopped", name), clr.REALRED)
                    end
                end)
            end
            return
        elseif action == "restart" then
            if target == "" then
                formattedAddChatMessage(string.format("USAGE: '/%s %s restart [function_name]'", alias, cmd), clr.GREY)
            else
                functionManager.restart(target, function(name, status)
                    formattedAddChatMessage(string.format("Restarted function: {%06x}%s", clr.YELLOW, name))
                end)
            end
            return
        else
            formattedAddChatMessage(string.format("USAGE: '/%s %s [start|stop|restart] [function_name]'", alias, cmd), clr.GREY)
            return
        end
    end,
    ["fonts"] = function()
        menu.fonts.window[0] = not menu.fonts.window[0]
    end,
    ["keybinds"] = function()
        menu.keybinds.window[0] = not menu.keybinds.window[0]
    end,
    ["skins"] = function()
        menu.skins.window[0] = not menu.skins.window[0]
    end,
    ["bms"] = function()
        menu.blackmarket.pageId = 1
        menu.blackmarket.window[0] = not menu.blackmarket.window[0]
    end,
    ["locker"] = function()
        menu.factionlocker.pageId = 1
        menu.factionlocker.window[0] = not menu.factionlocker.window[0]
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
            formattedAddChatMessage("Failed to fetch betatesters data.", clr.RED)
            return
        end

        formattedAddChatMessage("__________________ Betatesters _________________")
        for _, tester in ipairs(betatesters) do
            formattedAddChatMessage(string.format("%s | Bugs Found: %s | Hours Wasted: %s | Discord: %s.", tester.nickName, tester.bugFinds, convertDecimalToHours(tester.hoursWasted), tester.discord))
        end
        formattedAddChatMessage("_______________________________________________")
    end,
    ["changelog"] = function()
        menu.changelog.window[0] = not menu.changelog.window[0]
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
                    if not autobind.Settings.enable then
                        return
                    end
        
                    local success, error = pcall(command.func, alt, params)
                    if not success then
                        print(string.format("Error in command /%s: %s", alt, error))
                    end
                end)
            end
        end

        sampRegisterChatCommand(command.cmd, function(params)
            if not autobind.Settings.enable then
                return
            end

            local success, error = pcall(command.func, command.cmd, params)
            if not success then
                print(string.format("Error in command /%s: %s", command.cmd, error))
            end
        end)
    end
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

function displayTimers()
    local currentTime = localClock()
    for name, timer in pairs(timers) do
        local timerInfo = ""
        for fieldName, fieldValue in pairs(timer) do
            if fieldName == 'last' then
                if type(fieldValue) == "number" then
                    local elapsedTime = currentTime - fieldValue
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr.GREY, formatTime(elapsedTime), clr.WHITE)
                elseif type(fieldValue) == "table" then
                    local subTimerInfo = ""
                    for bindName, bindTime in pairs(fieldValue) do
                        if type(bindTime) == 'number' then
                            local elapsedTime = currentTime - bindTime
                            subTimerInfo = subTimerInfo .. string.format("%s: {%06x}%s{%06x}, ", bindName, clr.GREY, formatTime(elapsedTime), clr.WHITE)
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
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr.GREY, formatTime(elapsedTime), clr.WHITE)
                end
            elseif fieldName == 'timer' then
                if type(fieldValue) == 'number' then
                    if type(timer.last) == 'number' then
                        local timeElapsed = currentTime - timer.last
                        local timeLeft = fieldValue - timeElapsed
                        timeLeft = math.max(timeLeft, 0)
                        timerInfo = timerInfo .. string.format("TimeLeft: {%06x}%s{%06x}, ", clr.GREY, formatTime(timeLeft), clr.WHITE)
                    else
                        timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr.GREY, formatTime(fieldValue), clr.WHITE)
                    end
                end
            else
                if type(fieldValue) == 'number' then
                    timerInfo = timerInfo .. string.format("%s: {%06x}%s{%06x}, ", fieldName:upperFirst(), clr.GREY, formatTime(fieldValue), clr.WHITE)
                end
            end
        end
        if #timerInfo > 0 then
            timerInfo = timerInfo:sub(1, -3)
        end
        formattedAddChatMessage(string.format("%s: %s.", name, timerInfo))
    end
end

function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		for _, command in pairs(clientCommands) do
			sampUnregisterChatCommand(command.cmd)
		end
	end
end

function handleCapture(mode)
    local currentTime = localClock()
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

local messageHandlers = {
    {   -- Time Change (Auto Capture)
        pattern = "^The time is now (%d+):(%d+)%.$", -- The time is now 22:00.
        color = clrRGBA["WHITE"],
        action = function(hour, minute)
            -- Check if the player is AFK
            if isPlayerAFK then
                return
            end

            -- Main logic
            lua_thread.create(function()
                wait(0)
                handleCapture(autobind.Settings.mode)
            end)

            -- Return the current time message if hour and minute are available
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
                local playerName = autobind.CurrentPlayer.name
                if playerName and playerName ~= "" then
                    if autobind.VehicleStorage.Vehicles == nil then
                        autobind.VehicleStorage.Vehicles = {}
                    end
                    autobind.VehicleStorage.Vehicles[playerName] = autobind.VehicleStorage.Vehicles[playerName] or {}

                    for _, vehicle in pairs(autobind.VehicleStorage.Vehicles[playerName]) do
                        if vehicle.status and vehicle.status ~= "Stored" and vehicle.status ~= "Disabled" and vehicle.status ~= "Impounded" then
                            vehicle.status = "Stored"
                        end
                    end
                end

                lua_thread.create(function()
                    wait(0)
                    if autobind.VehicleStorage.Vehicles[playerName] and #autobind.VehicleStorage.Vehicles[playerName] < 1 then
                        formattedAddChatMessage("Populating vehicle storage list.")
                        -- Reset vehicle initial fetch
                        vehicles.initialFetch = false
                        vehicles.populating = true
                        sampSendChat("/vst")
                    end

                    if currentContent and autobind.Settings.checkForUpdates then
                        if updateStatus == "new_version" then
                            formattedAddChatMessage(string.format("A new version of %s %s is available, please update to the latest version %s.", scriptName, scriptVersion, currentContent.version), clr.NEWS)
                        elseif updateStatus == "outdated" then
                            formattedAddChatMessage(string.format("%s %s is outdated, please update to the latest version %s.", scriptName, scriptVersion, currentContent.version), clr.NEWS)
                        end
                    end
                end)

                -- Save settings
                saveConfigWithErrorHandling(Files.currentplayer, autobind.CurrentPlayer)
                saveConfigWithErrorHandling(Files.vehiclestorage, autobind.VehicleStorage)

                registerClientCommands()

                return {clrRGBA["NEWS"], string.format("Welcome to Horizon Roleplay, %s.", name)}
            end
        end
    },
    {   -- Muted Message
        pattern = "^You have been muted automatically for spamming%. Please wait 10 seconds and try again%.$",
        color = clrRGBA["YELLOW"],
        action = function()
            timers.Muted.last = localClock()
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
                    string.format("** %s %s (%d): {%06x}%s", divOrRank, playerName, playerId, clr.GREY, message)
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
                saveConfigWithErrorHandling(Files.settings, autobind.Settings)

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

                return {clrRGBA["DEPTRADIO"], string.format("Family MOTD: %s", motdMsg)}
            elseif type:match("[LSPD|SASD|FBI|ARES|GOV]") then
                autobind.Settings.mode = "Faction"
                autobind.Faction.type = type
                saveConfigWithErrorHandling(Files.settings, autobind.Settings)
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

                    for i, item in ipairs(lockers.factionlocker.Items) do
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

                    sampAddChatMessage(string.format("{%06x}%s MOTD: %s", clr.DEPTRADIO, type, newMessage), -1)
                    return false
                end]]

                return {clrRGBA["DEPTRADIO"], string.format("%s MOTD: %s", type, motdMsg)}
            elseif type:match("LSFMD") then
                autobind.Settings.mode = "Faction"
                autobind.Faction.type = type
                saveConfigWithErrorHandling(Files.settings, autobind.Settings)

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
                formattedAddChatMessage(string.format("You have set the frequency to your {%06x}%s {%06x}portable radio.", clr.DEPTRADIO, autobind.Settings.mode, clr.WHITE))
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
                return {clrRGBA["PUBLICRADIO_COLOR"], string.format("** %s Radio ** {%06x}%s (%d){%06x}: %s", autobind.Settings.mode, changeAlpha(playerColor, 0), playerName, playerId, clr.PUBLICRADIO_COLOR, message)}
            end
        end
    },
    {   -- Autocap Disabled
        pattern = "^Your gang is already attempting to capture this turf%.$",
        color = clrRGBA["GRAD1"],
        action = function()
            if autocap then
                local mode = autobind.Settings.mode
                formattedAddChatMessage(string.format("Your %s is already attempting to capture this turf! Disabling Auto Capture.", mode:lower()), clr.GRAD1)
                autocap = false
                return false
            end
        end
    },
    {   -- Turf Not Ready
        pattern = "This turf is not ready for takeover yet.",
        color = clrRGBA["GRAD1"],
        action = function()
            if autocap then
                autocap = false

                formattedAddChatMessage("This turf is not ready for takeover yet! Disabling Auto Capture.", clr.GRAD1)
                return false
            end
        end
    },
    {   -- You are not high rank enough to capture!
        pattern = "^You are not high rank enough to capture!$",
        color = clrRGBA["GRAD1"],
        action = function()
            local toggle = false
            if autocap then
                autocap = false
                formattedAddChatMessage("You are not high rank enough to capture! Disabling Auto Capture.", clr.GRAD1)
                toggle = true
            end

            if autobind.Faction.turf and autobind.Settings.mode == "Faction" then
                formattedAddChatMessage("You have capture at signcheck enabled, disabling that now.", clr.GRAD1)
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
            if bodyguard.received then
                bodyguard.received = false
                setTimer(1.0, timers.Vest)
            end

            return {clrRGBA["GREY"], "That player isn't near you."}
        end
    },
    {   -- Can't Guard While Aiming
        pattern = "You can't /guard while aiming%.$",
        color = clrRGBA["GREY"],
        action = function()
            if bodyguard.received then
                bodyguard.received = false
                setTimer(1.0, timers.Vest)

                return {clrRGBA["GREY"], "You can't /guard while aiming."}
            end
        end
    },
    {   -- Must Wait Before Selling Vest
        pattern = "You must wait (%d+) seconds? before selling another vest%.?",
        color = clrRGBA["GREY"],
        action = function(cooldown)
            if autobind.AutoVest.enable then
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
                return {clrRGBA["LIGHTBLUE"], string.format("* You offered protection to %s (%d) for $%s.", nickname, bodyguard.playerId, price)}
            end
        end
    },
    {   -- Not a Bodyguard
        pattern = "You are not a bodyguard%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autobind.AutoVest.enable then
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
            if autobind.AutoVest.enable then
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
            if accepter.received and accepter.playerName ~= "" and accepter.playerId ~= -1 then
                if accepter.enable then
                    accepter.received = false
                end

                return {clrRGBA["GRAD2"], string.format("You are not close enough to %s (%d).", accepter.playerName:gsub("_", " "), accepter.playerId)}
            end
        end
    },
    {   -- Protection Offer
        pattern = "^%* Bodyguard (.+) wants to protect you for %$([%d,]+)%, type %/accept bodyguard to accept%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
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
    },
    {   -- You Accepted Protection
        pattern = "^%* You accepted the protection for %$(%d+) from (.+)%.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(price, nickname)
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
    },
    {   -- They Accepted Protection
        pattern = "%* (.+) accepted your protection, and the %$(%d+) was added to your money.$",
        color = clrRGBA["LIGHTBLUE"],
        action = function(nickname, price)
            local playerId = bodyguard.playerId
            
            bodyguard.playerName = ""
            bodyguard.playerId = -1
            bodyguard.received = false
            return {clrRGBA["LIGHTBLUE"], string.format("* %s (%d) accepted your protection, and the $%d was added to your money.", nickname, playerId, price)}
        end
    },
    {   -- Can't Afford Protection
        pattern = "You can't afford the Protection!",
        color = clrRGBA["GREY"],
        action = function()
            accepter.received = false

            return {clrRGBA["GREY"], "You can't afford the protection!"}
        end
    },
    {   -- Can't Use Locker Recently Shot
        pattern = "You can't use your lockers if you were recently shot.",
        color = clrRGBA["WHITE"],
        action = function()
            formattedAddChatMessage("You can't use your lockers if you were recently shot. Timer extended by 5 seconds.")
            setTimer(5, timers.Heal)

            lockers.factionlocker.isProcessing = false
            lockers.factionlocker.thread = nil
            resetLocker("factionlocker")
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
            if lockers.blackmarket.getItemFrom > 0 then
                lockers.blackmarket.getItemFrom = 0
                lockers.blackmarket.gettingItem = false
            end
        end
    },
    {   -- Not at Black Market
        pattern = "^%s*You are not at the black market%!",
        color = clrRGBA["GRAD2"],
        action = function()
            if lockers.blackmarket.getItemFrom > 0 then
                lockers.blackmarket.getItemFrom = 0
                lockers.blackmarket.gettingItem = false
            end
        end
    },
    {   -- Already Searched for Someone
        pattern = "^You have already searched for someone %- wait a little%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autofind.enable then
                autofind.received = false
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                setTimer(5, timers.Find)
            end
        end
    },
    {   -- Can't Find Person Hidden in Turf
        pattern = "^You can't find that person as they're hidden in one of their turfs%.$",
        color = clrRGBA["GREY"],
        action = function()
            if autofind.enable and autofind.playerName ~= "" and autofind.playerId ~= -1 then
                autofind.received = false
                if autofind.counter > 0 then
                    autofind.counter = 0
                end
                formattedAddChatMessage(string.format("%s (ID: %d) is hidden in a turf. Autofind will try again in 5 seconds.", autofind.playerName:gsub("_", " "), autofind.playerId))
                setTimer(5, timers.Find)
                return false
            end
        end
    },
    {   -- Not a Detective
        pattern = "^You are not a detective%.$",
        color = clrRGBA["GREY"],
        action = function()
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
            local cleanLocation = location:match("^%s*(.-)%s*$") or ""

            if autofind.enable then
                timers.Find.last = localClock()
                autofind.received = false
                if autofind.playerName:gsub("_", " "):match(nickname) then
                    autofind.location = cleanLocation
                end

                return {clrRGBA["GRAD2"], string.format("%s (%d) has been last seen %s.", nickname, autofind.playerId, (cleanLocation == "" and "out of the map or no location was provided" or string.format("at {%06x}%s", clr.YELLOW, cleanLocation)))}
            end
        end
    },
    {   -- SMS: I need the where-abouts of Player Name, Sender: Player Name (Phone Number)
        pattern = "^SMS: I need the where%-abouts of ([^,]+), Sender: ([^%(]+)%((%d+)%)$",
        color = clrRGBA["YELLOW"],
        action = function(nickname, sender, phonenumber)
            if autofind.enable then
                timers.Find.last = localClock()
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
                return {clrRGBA["WHITE"], string.format("{%06x}%s (%d) {%06x}is requesting immediate backup %s.", changeAlpha(playerColor, 0), nickname, playerId, clr.GREY, (cleanLocation == "" and "out of the map or no location was provided" or string.format("at {%06x}%s", clr.YELLOW, cleanLocation)))}
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
    {   -- Muted Notification
        pattern = "^You have been muted automatically for spamming%. Please wait 10 seconds and try again%.$",
        color = clrRGBA["YELLOW"],
        action = function()
            timers.Muted.last = localClock()
        end
    },
    {   -- Help Command Additions
        pattern = "^%*%*%* OTHER %*%*%* /cellphonehelp /carhelp /househelp /toyhelp /renthelp /jobhelp /leaderhelp /animhelp /fishhelp /insurehelp /businesshelp /bankhelp",
        color = clrRGBA["WHITE"],
        action = function()
            lua_thread.create(function()
                wait(0)
                local cmds = clientCommands
                sampAddChatMessage(string.format("*** AUTOBIND *** /%s /%s /%s /%s /%s /%s /%s /%s /%s /%s /%s", shortName, shortName .. " help", cmds.repairnear.cmd, cmds.autocap.cmd, cmds.capcheck.cmd, cmds.sprintbind.cmd, cmds.bikebind.cmd, cmds.sprunkspam.cmd, cmds.autofarm.cmd, cmds.resetvst.cmd, cmds.autopicklock.cmd), -1)
                sampAddChatMessage(string.format("*** AUTOVEST *** /%s /%s /%s /%s /%s", cmds.autovest.cmd, cmds.ddmode.cmd, cmds.autoaccept.cmd, cmds.vestnear.cmd, cmds.vestall.cmd), -1)
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
            updateVehicleStorage("Respawned", vehName)
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
                sampShowDialog(farmer.dialogId2, string.format("[%s] Auto Farming", shortName:upper()), "Do you want to enable auto farming?\nThis will automatically type /farm and /harvest for you.", "Close", "Enable", 0)
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
                    if sampGetCurrentDialogId() == farmer.dialogId then
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
            if lockers.blackmarket.isProcessing then
                return false
            end
        end
    },
    {   -- DIAMOND DONATOR: You have purchased full health and armor for %$350%.
        pattern = "^DIAMOND DONATOR: You have purchased full health and armor for %$350%.$",
        color = clrRGBA["BLUE"],
        action = function()
            if lockers.blackmarket.isProcessing then
                return false
            end
        end
    },
    {   -- You have purchased an? (.+) for %$([%d,]+)%.$
        pattern = "^You have purchased an? (.-) for %$([%d,]+)%.$",
        color = clrRGBA["WHITE"],
        action = function(item, price)
            if lockers.factionlocker.isProcessing then
                return false
            end
        end
    }
}

function sampev.onServerMessage(color, text)
    if not autobind.Settings.enable then
        return
    end

    if isPlayerPaused then
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
            local playerName = autobind.CurrentPlayer.name
            if not playerName or playerName == "" then
                local _, playerId = sampGetPlayerIdByCharHandle(ped)
                if not playerId then
                    formattedAddChatMessage("Current player not found!")
                    return
                end
    
                playerName = sampGetPlayerNickname(playerId)
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
                local vehicle, status, location = adjustedMessage:match("Vehicle: ([^|]+)%s*|%s*Status: ([^|]+)%s*|%s*Location: (.+)")
                if vehicle and status and location then
                    -- Trim the strings
                    vehicle = vehicle:trim()
                    status = status:trim()
                    location = location:trim()

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
    if lockers.blackmarket.getItemFrom > 0 then
        if not title:find("Black Market") then 
            lockers.blackmarket.getItemFrom = 0 
            lockers.blackmarket.gettingItem = false
            lockers.blackmarket.currentKey = nil
            return false 
        end
        sampSendDialogResponse(id, 1, lockers.blackmarket.currentKey, nil)
        lockers.blackmarket.gettingItem = false
        return false
    end

    -- Faction Locker
    if lockers.factionlocker.getItemFrom > 0 then
        if title:find('[LSPD|FBI|ARES] Menu') then
            sampSendDialogResponse(id, 1, 1, nil)
            return false
        end

        if not title:find("[LSPD|FBI|ARES] Equipment") then 
            lockers.factionlocker.getItemFrom = 0 
            lockers.factionlocker.gettingItem = false
            lockers.factionlocker.currentKey = nil
            return false
        end
        sampSendDialogResponse(id, 1, lockers.factionlocker.currentKey, nil)
        lockers.factionlocker.gettingItem = false
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

function sampev.onConnectionRejected(reason)
    autoConnect()
end

function sampev.onConnectionClosed()
    autoConnect()
end

function sampev.onConnectionBanned()
    autoConnect()
end

function sampev.onConnectionLost()
    autoConnect()
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
            return string.format("{%06x}Offered To: {%06x}%s; $%s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or offeredTo, formatNumber(bodyguard.price))
        end,
        isVisible = function()
            return (bodyguard.playerName and bodyguard.playerName ~= "" and bodyguard.playerId and bodyguard.playerId ~= -1) or menu.fonts.window[0]
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
            return string.format("{%06x}Offered From: {%06x}%s; $%s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or offeredFrom, formatNumber(accepter.price))
        end,
        isVisible = function()
            return (accepter.playerName and accepter.playerName ~= "" and accepter.playerId and accepter.playerId ~= -1) or menu.fonts.window[0]
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
            local timeLeft = math.ceil(timers.Find.timer - (localClock() - timers.Find.last))
            local locationText = menu.fonts.window[0] and "; Location" or (autofind.location == "" and "" or ("; " .. autofind.location))
            return string.format("{%06x}Auto Find: {%06x}%s; Next: %02ds%s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or playerName, timeLeft < 0 and 0 or timeLeft, locationText)
        end,
        isVisible = function()
            return (autofind.playerName and autofind.playerName ~= "" and autofind.playerId and autofind.playerId ~= -1) or menu.fonts.window[0]
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
            return string.format("{%06x}Last Backup: {%06x}%s; %s", self.colors().text, self.colors().value, menu.fonts.window[0] and "Player_Name (ID)" or lastBackup, menu.fonts.window[0] and "Location" or backup.location)
        end,
        isVisible = function()
            return (backup.playerName and backup.playerName ~= "" and backup.playerId and backup.playerId ~= -1) or menu.fonts.window[0]
        end,
    },
    FactionBadge = {
        enable = function() return autobind.Elements.FactionBadge.enable end,
        pos = function() return autobind.Elements.FactionBadge.Pos end,
        colors = function()
            local _, playerId = sampGetPlayerIdByCharHandle(ped)
            local playerColor = sampGetPlayerColor(playerId)
            return {text = changeAlpha(playerColor, 0)}
        end,
        align = function() return autobind.Elements.FactionBadge.align end,
        fontName = function() return autobind.Elements.FactionBadge.font end,
        fontSize = function() return autobind.Elements.FactionBadge.size end,
        flags = function() return autobind.Elements.FactionBadge.flags end,
        textFunc = function(self)
            if factions.badges[self.colors().text] then
                local faction = factions.badges[self.colors().text]
                if faction then
                    return string.format("{%06x}%s", self.colors().text, faction)
                end
            end
            return ""
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
        if element.enable() and menu.fonts.window[0] then
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

    -- Draw all elements and listen for drag events
    drawElements()
    dragElements()
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil

	-- Check if the font exists
	assert(doesFileExist(Files.trebucbd), '[AB] Font "' .. Files.trebucbd .. '" doesn\'t exist!')

    -- Setup Font and Icons (Large, Medium, Small)
    loadFontIcons(true, 14.0, fa.min_range, fa.max_range, Files.fawesome5)
    for _, font in pairs(fontData) do
        font.font = imgui.GetIO().Fonts:AddFontFromFileTTF(Files.trebucbd, font.size)
        loadFontIcons(true, font.size, fa.min_range, fa.max_range, Files.fawesome5)
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
end)

local button_size_small = imgui.ImVec2(75, 75)
local button_size_large = imgui.ImVec2(165, 75)
local child_size1 = imgui.ImVec2(85, 382)
local child_size2 = imgui.ImVec2(500, 88)
local child_size_pages = imgui.ImVec2(500, 276)
local child_size_bottom = imgui.ImVec2(500, 20)
local button_size_small2 = imgui.ImVec2(15, 15)

local updateStatusIcons = {
    up_to_date = fa.ICON_FA_CHECK .. ' Up to date',
    new_version = fa.ICON_FA_RETWEET .. ' Update\nNew Version',
    outdated = fa.ICON_FA_EXCLAMATION_TRIANGLE .. ' Update\n Outdated',
    failed = fa.ICON_FA_EXCLAMATION_TRIANGLE .. ' Update\n    Failed',
    beta_version = fa.ICON_FA_RETWEET .. ' Update\nBeta Version'
}

local buttons1 = {
    {
        id = 1,
        icon = function() return fa.ICON_FA_POWER_OFF end,
        tooltip = function() 
            return string.format('%s Toggles all functionalities. ({%06x}%s{%06x})',
                fa.ICON_FA_POWER_OFF,
                autobind.Settings.enable and clr.GREEN or clr.RED,
                autobind.Settings.enable and 'ON' or 'OFF',
                clr.WHITE)
        end,
        action = function()
            autobind.Settings.enable = not autobind.Settings.enable
            if autobind.Settings.enable then
                registerClientCommands()
            else
                for _, command in pairs(clientCommands) do
                    sampUnregisterChatCommand(command.cmd)
                    if command.alt then
                        for _, altCommand in pairs(command.alt) do
                            sampUnregisterChatCommand(altCommand)
                        end
                    end
                end
            end
        end,
        color = function()
            return autobind.Settings.enable and imguiRGBA["GREEN"] or imguiRGBA["RED"]
        end
    },
    {
        id = 2,
        icon = function() return fa.ICON_FA_SAVE end,
        tooltip = function() return 'Save configuration' end,
        action = function()
            saveAllConfigs()
        end,
        color = function()
            return imguiRGBA["DARKGREY"]
        end
    },
    {
        id = 3,
        icon = function() return fa.ICON_FA_SYNC end,
        tooltip = function() return 'Reload configuration' end,
        action = function()
            loadAllConfigs()
        end,
        color = function()
            return imguiRGBA["DARKGREY"]
        end
    },
    {
        id = 4,
        icon = function() return fa.ICON_FA_ERASER end,
        tooltip = function() return 'Load default configuration' end,
        action = function()
            local ignoreKeys = {
                {"Settings", "mode"},
                {"WindowPos", "Settings"},
                {"WindowPos", "Fonts"},
                {"WindowPos", "Skins"},
                {"WindowPos", "Keybinds"},
                {"WindowPos", "BlackMarket"},
                {"WindowPos", "FactionLocker"},
                {"CurrentPlayer", "name"},
                {"CurrentPlayer", "id"}
            }

            ensureDefaults(autobind, autobind_defaultSettings, true, ignoreKeys)

            createFonts()

            resetLockersKeyFunctions()

            InitializeLockerKeyFunctions(autobind.BlackMarket.maxKits, "Black Market", "/bm")
            InitializeLockerKeyFunctions(autobind.FactionLocker.maxKits, "Faction Locker", "/locker")

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
        end,
        color = function()
            return imguiRGBA["DARKGREY"]
        end
    },
    {
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

                menu.confirm.update[0] = true
                menu.confirm.window[0] = true
            end
        end,
        color = function()
            return (updateStatus == "new_version" or updateStatus == "beta_version" or updateStatus == "outdated") and imguiRGBA["GREEN"] or imguiRGBA["DARKGREY"]
        end
    }
}

local buttons2 = {
    {
        id = 1,
        icon = function()
            return fa.ICON_FA_COG .. " Settings"
        end,
        tooltip = "Open Settings"
    },
    {
        id = 2,
        icon = function()
            return string.format("%s %s Skins", fa.ICON_FA_LIST, autobind.Settings.mode)
        end,
        tooltip = "Open Skins"
    },
    {
        id = 3,
        icon = function()
            return fa.ICON_FA_LIST .. " Names"
        end,
        tooltip = "Open Names"
    }
}

local cursor_positions_y_buttons1 = {}
for i, _ in ipairs(buttons1) do
    cursor_positions_y_buttons1[i] = (i - 1) * 76
end

local bool_autosave = new.bool(false)

local function handleAutosaveCheckbox()
    bool_autosave[0] = autobind.Settings.autoSave
    if imgui.Checkbox('Autosave', bool_autosave) then
        autobind.Settings.autoSave = bool_autosave[0]
    end
    imgui.CustomTooltip('Automatically saves your settings when you exit the game')
end

function onWindowMessage(msg, wparam, lparam)
    -- Check if the player is paused and set AFK upon setting focus
    if msg == wm.WM_SETFOCUS then
        isPlayerPaused = false
        isPlayerAFK = true
    elseif msg == wm.WM_KILLFOCUS then
        isPlayerPaused = true
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

imgui.OnFrame(function() return menu.initialized[0] end,
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

    -- Handle Escape key press to close all menus
    if escapePressed then
        for key, state in pairs(menuStates) do
            if state[0] then
                state[0] = false
            end
            -- Update previous state to reflect that the menu is now closed
            previousMenuStates[key] = false
        end
        escapePressed = false

        if autobind.Settings.autoSave then
            saveAllConfigs()
        end
    else
        for key, state in pairs(menuStates) do
            -- Check if the menu has just been closed
            if previousMenuStates[key] and not state[0] then
                if key == "settings" then
                    if autobind.Settings.autoSave then
                        autobind.AutoVest.names = table.setToList(names)
                        saveAllConfigs()
                    end
                end

                if key == "blackmarket" then
                    InitializeLockerKeyFunctions(autobind.BlackMarket.maxKits, "Black Market", "/bm")

                    saveConfigWithErrorHandling(Files.blackmarket, autobind.BlackMarket)
                end

                if key == "factionlocker" then
                    InitializeLockerKeyFunctions(autobind.FactionLocker.maxKits, "Faction Locker", "/locker")

                    saveConfigWithErrorHandling(Files.factionlocker, autobind.FactionLocker)
                end

                if key == "keybinds" then
                    saveConfigWithErrorHandling(Files.keybinds, autobind.Keybinds)
                end

                if key == "fonts" then
                    saveConfigWithErrorHandling(Files.elements, autobind.Elements)
                end

                if key == "skins" then
                    autobind.AutoVest.skins = table.setToList(family.skins)
                end

                if key == "confirm" then
                    menu.confirm.update[0] = false
                end

                if key == "vehiclestorage" then
                    menu.vehiclestorage.dragging[0] = false
                end
            end

            -- Detect if the menu has just been opened
            if not previousMenuStates[key] and state[0] then
                if key == "settings" then
                    updateCheck()
                end
            end

            -- Update previous state
            previousMenuStates[key] = state[0]
        end
    end

    if menu.settings.window[0] then
        setupWindowDraggingAndSize("Settings")

        -- Settings Window
        if imgui.Begin(menu.settings.title, menu.settings.window, imgui_flags) then
            -- First child (Side Buttons)
            imgui.PushFont(fontData.medium.font)
            imgui.BeginChild("##1", child_size1, false)
            for i, button in ipairs(buttons1) do
                imgui.SetCursorPosY(cursor_positions_y_buttons1[i])
                local color = button.color() -- Directly call the color function
                if imgui.CustomButton(button.icon(), color, imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], button_size_small) then
                    button.action()
                end
                if not isUpdateHovered then
                    imgui.CustomTooltip(button.tooltip())
                end

                if button.id == 5 then
                    imgui.SetCursorPosY(cursor_positions_y_buttons1[i] + 57)
                    imgui.BeginChild("##checkbox", imgui.ImVec2(0, 20), false)  -- Create a new child for the checkbox
                    if imgui.Checkbox('Beta', new.bool(autobind.Settings.fetchBeta)) then
                        autobind.Settings.fetchBeta = toggleBind("Beta", autobind.Settings.fetchBeta)
                        updateCheck()
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
            imgui.BeginChild("##2", child_size2, false)
            for i, button in ipairs(buttons2) do
                imgui.SetCursorPosX((i - 1) * 165)
                imgui.SetCursorPosY(0)
                local isActive = menu.settings.pageId == button.id
                local color = isActive and imguiRGBA["RED"] or imguiRGBA["DARKGREY"]
                if imgui.CustomButton(button.icon(), color, imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], button_size_large) then
                    menu.settings.pageId = button.id
                end
                if not isActive then
                    imgui.CustomTooltip(button.tooltip)
                end
            end
            imgui.EndChild()

            -- Third child (Pages)
            imgui.SetCursorPos(imgui.ImVec2(85, 110))
            imgui.BeginChild("##pages", child_size_pages, false)
            if menu.settings.pageId == 1 then
                renderSettings()
            elseif menu.settings.pageId == 2 then
                renderSkins()
            elseif menu.settings.pageId == 3 then
                renderNames()
            end
            imgui.EndChild()

            -- Fourth child (Bottom Settings)
            imgui.SetCursorPos(imgui.ImVec2(92, 390))

            imgui.PushFont(fontData.medium.font)
            imgui.BeginChild("##4", child_size_bottom, false)
            handleAutosaveCheckbox()

            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_KEYBOARD .. " Keybinds") then
                local keybinds = menu.keybinds
                keybinds.window[0] = not keybinds.window[0]
            end
            imgui.CustomTooltip("Opens keybinds settings.")
            imgui.CustomTooltip(string.format("You can also use {%06x}'/%s keybinds'{%06x} to open this menu.", clr.GREY, shortName, clr.WHITE))

            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_FONT .. " Fonts") then
                local fonts = menu.fonts
                fonts.window[0] = not fonts.window[0]
            end
            imgui.CustomTooltip("Opens fonts settings.")
            imgui.CustomTooltip(string.format("You can also use {%06x}'/%s fonts'{%06x} to open this menu.", clr.GREY, shortName, clr.WHITE))

            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " BMS") then
                local blackmarket = menu.blackmarket
                blackmarket.window[0] = not blackmarket.window[0]
            end
            imgui.CustomTooltip("Opens black market settings.")
            imgui.CustomTooltip(string.format("You can also use {%06x}'/%s bms'{%06x} to open this menu.", clr.GREY, shortName, clr.WHITE))

            if autobind.Settings.mode == "Faction" then
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Locker") then
                    local faction = menu.factionlocker
                    faction.window[0] = not faction.window[0]
                end
                imgui.CustomTooltip("Opens faction locker settings.")
                imgui.CustomTooltip(string.format("You can also use {%06x}'/%s locker'{%06x} to open this menu.", clr.GREY, shortName, clr.WHITE))
            elseif autobind.Settings.mode == "Family" then
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_SHOPPING_CART .. " Skins") then
                    local skins = menu.skins
                    skins.window[0] = not skins.window[0]
                end
                imgui.CustomTooltip("Opens family skins settings.")
                imgui.CustomTooltip(string.format("You can also use {%06x}'/%s skins'{%06x} to open this menu.", clr.GREY, shortName, clr.WHITE))
            end
            imgui.EndChild()
            imgui.PopFont()
        end
        imgui.End()
    end

    if menu.vehiclestorage.window[0] then
        setupWindowDraggingAndSize("VehicleStorage")

        -- Set window rounding
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 5)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
        imgui.PushStyleVarFloat(imgui.StyleVar.ScrollbarSize, 10)

        local vehText = {vehicle = {[0] = "Vehicle:"}, location = {[0] = "Location:"}, status = {[0] = "Status:"}, id = {[0] = "ID:"}}

        local playerName = autobind.CurrentPlayer.name
        if not playerName or playerName == "" then
            local _, playerId = sampGetPlayerIdByCharHandle(ped)
            if not playerId then
                formattedAddChatMessage("Current player not found!")
                menu.vehiclestorage.window[0] = false
                goto skipVehicleStorage
            end

            playerName = sampGetPlayerNickname(playerId)
        end

        autobind.VehicleStorage.Vehicles[playerName] = autobind.VehicleStorage.Vehicles[playerName] or {}

        for _, value in pairs(autobind.VehicleStorage.Vehicles[playerName]) do
            if value.id and value.status and value.vehicle and value.location then
                local statusColor = statusVehicleColors[value.status] or clr.WHITE
                table.insert(vehText.id, string.format("%s", value.id and value.id + 1 or "N/A"))
                table.insert(vehText.status, string.format("{%06X}%s", statusColor, value.status or "Unknown"))
                table.insert(vehText.vehicle, string.format("%s", value.vehicle or "Unknown"))
                table.insert(vehText.location, string.format("%s", value.location or "Unknown"))
            end
        end

        if imgui.Begin(menu.vehiclestorage.title, menu.vehiclestorage.window, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove) then
            imgui.SetCursorPosX(imgui.GetWindowWidth() - 20)
            imgui.SetCursorPosY(5)
            imgui.PushFont(fontData.small.font)
            local textColor = menu.vehiclestorage.dragging[0] and imguiRGBA["REALGREEN"] or imguiRGBA["REALRED"]
            if imgui.CustomButton(fa.ICON_FA_MAP_PIN, imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], textColor, button_size_small2) then
                menu.vehiclestorage.dragging[0] = not menu.vehiclestorage.dragging[0]
            end
            imgui.PopFont()
            if imgui.IsItemHovered() then
                imgui.CustomTooltip(string.format("{%06X}Red{%06X} is pinned, {%06X}Green{%06X} is unpinned", clr["REALRED"], clr["WHITE"], clr["REALGREEN"], clr["WHITE"]))
            end

            local textSize = imgui.CalcTextSize(menu.vehiclestorage.title)
            imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - textSize.x / 2)
            imgui.SetCursorPosY(5)
            imgui.PushFont(fontData.medium.font)
            imgui.TextColoredRGB(menu.vehiclestorage.title)

            imgui.SetCursorPosX(10)
            imgui.SetCursorPosY(25)
            if imgui.BeginChild("##vehicles", imgui.ImVec2(325, 133.5), false) then
                for i = 0, #vehText.id do
                    imgui.TextColoredRGB(vehText.id[i])
                    imgui.SameLine(30)
                    imgui.TextColoredRGB(vehText.status[i])
                    imgui.SameLine(95)
                    imgui.TextColoredRGB(vehText.vehicle[i])
                    imgui.SameLine(180)
                    imgui.TextColoredRGB(vehText.location[i])
                    imgui.SetCursorPosY(imgui.GetCursorPosY() - (i == 0 and 2.5 or 4))
                end
            end
            imgui.PopFont()
            imgui.EndChild()
        end
        imgui.PopStyleVar(3)
        imgui.End()
    end

    ::skipVehicleStorage::

    if menu.keybinds.window[0] then
        setupWindowDraggingAndSize("Keybinds")

        if imgui.Begin(menu.keybinds.title, menu.keybinds.window, imgui_flags) then

            imgui.SetCursorPosX(20)

            imgui.BeginGroup()
            -- Begin two columns
            imgui.Columns(2, nil, false)

            for index, editor in ipairs(keyEditors) do
                keyEditor(editor.label, editor.key, editor.description, nil)

                if editor.key == "Frisk" then
                    imgui.PushFont(fontData.medium.font)
                    
                    imgui.SetCursorPosY(imgui.GetCursorPosY() - 5)

                    if imgui.Checkbox('Targeting', new.bool(autobind.Settings.mustTargetToFrisk)) then
                        autobind.Settings.mustTargetToFrisk = toggleBind("Targeting", autobind.Settings.mustTargetToFrisk)
                    end
                    imgui.CustomTooltip('Must be targeting a player to frisk. (Green Blip above the player)')
                    imgui.SameLine()
                    if imgui.Checkbox('Must Aim', new.bool(autobind.Settings.mustAimToFrisk)) then
                        autobind.Settings.mustAimToFrisk = toggleBind("Must Aim", autobind.Settings.mustAimToFrisk)
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
        setupWindowDraggingAndSize("Skins")

        -- Skin Window
        if imgui.Begin(menu.skins.title, menu.skins.window, imgui_flags) then
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

                    imgui.CustomTooltip("Skin " .. skinId)
                end
            end
            imgui.EndChild()
        end
        imgui.End()
    end

    if menu.fonts.window[0] then
        setupWindowDraggingAndSize("Fonts")

        local fontElements = {
            {name = "OfferedTo", label = "Vest To", value = autobind.Elements.offeredTo, disableColor = false},
            {name = "OfferedFrom", label = "Vest From", value = autobind.Elements.offeredFrom, disableColor = false},
            {name = "PedsCount", label = "Peds", value = autobind.Elements.PedsCount, disableColor = false},
            {name = "AutoFind", label = "Auto Find", value = autobind.Elements.AutoFind, disableColor = false},
            {name = "LastBackup", label = "Last Backup", value = autobind.Elements.LastBackup, disableColor = false},
            {name = "FactionBadge", label = "Badge", value = autobind.Elements.FactionBadge, disableColor = true}
        }        

        if imgui.Begin(menu.fonts.title, menu.fonts.window, imgui_flags) then
            for index, value in pairs(fontElements) do
                createFontMenuElement(value.name, value.label, value.value, value.disableColor)
                if index ~= #fontElements then
                    imgui.Separator()
                end
            end
        end
        imgui.End()
    end

    if menu.confirm.window[0] then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, menu.confirm.pivot)
        imgui.SetNextWindowFocus()

        if imgui.Begin(menu.settings.title .. ' - Update', menu.confirm.window, imgui_flags) then
            if menu.confirm.update[0] then
                imgui.Text('Do you want to update this script?')

                -- Get available space and divide it for the buttons
                local availableWidth = imgui.GetContentRegionAvail().x
                local buttonWidth = (availableWidth - imgui.GetStyle().ItemSpacing.x) / 2
                local buttonSize = imgui.ImVec2(buttonWidth, 45)

                if imgui.CustomButton(fa.ICON_FA_CHECK .. ' Update', imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], buttonSize) then
                    updateScript()
                    menu.confirm.update[0] = false
                    menu.confirm.window[0] = false
                end
                imgui.SameLine()
                if imgui.CustomButton(fa.ICON_FA_TIMES .. ' Cancel', imguiRGBA["DARKGREY"], imguiRGBA["ALTRED"], imguiRGBA["RED"], imguiRGBA["WHITE"], buttonSize) then
                    menu.confirm.update[0] = false
                    menu.confirm.window[0] = false

                    if autoReboot then
                        script.load(workingDir .. "\\AutoReboot.lua")
                    end
                end
            end
        end
        imgui.End()
    end

    if menu.blackmarket.window[0] then
        renderLockerWindow("Black Market", "BlackMarket")
    end

    if menu.factionlocker.window[0] then
        renderLockerWindow("Faction Locker", "FactionLocker")
    end

    if menu.changelog.window[0] then
        renderChangelogWindow()
    end

end).HideCursor = true

function renderChangelogWindow()
    setupWindowDraggingAndSize("Changelog")

    if imgui.Begin(string.format("%s - %s", scriptName:upperFirst(), scriptVersion), menu.changelog.window, imgui_flags) then
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
            for index, version in ipairs(sortedVersions) do
                if index == 1 then
                    imgui.Separator()
                end
                imgui.TextColoredRGB(string.format("Version: {%06x}%s", clr.BLUE, version))
                imgui.NewLine()

                for i, change in ipairs(changelog[version]) do
                    local textColor = (i % 2 == 1) and imguiRGBA["WHITE"] or imguiRGBA["GREY"]
                    imgui.PushStyleColor(imgui.Col.Text, textColor)
                    imgui.PushFont(fontData.medium.font)
                    imgui.TextWrapped(change)
                    imgui.PopFont()
                    imgui.PopStyleColor()
                end
                imgui.NewLine()
                imgui.Separator()
            end
        else
            imgui.TextColoredRGB(string.format("Changelog failed to fetch. {%06x}%s", clr.RED, Urls.changelog))
        end
    end
    imgui.End()
end

function setupWindowDraggingAndSize(label, allowSize)
    allowSize = allowSize or true

    local lowerLabel = label:lower()

    local newPos, status = imgui.handleWindowDragging(label, autobind.WindowPos[label], menu[lowerLabel].size, menu[lowerLabel].pivot, menu[lowerLabel].dragging[0])
    if status then
        autobind.WindowPos[label] = newPos
        imgui.SetNextWindowPos(autobind.WindowPos[label], imgui.Cond.Always, menu[lowerLabel].pivot)
    else
        imgui.SetNextWindowPos(autobind.WindowPos[label], imgui.Cond.FirstUseEver, menu[lowerLabel].pivot)
    end

    if allowSize then
        imgui.SetNextWindowSize(menu[lowerLabel].size, imgui.Cond.FirstUseEver)
    end
end

local hasRunForThirdKey = false

function renderLockerWindow(label, name)
    local lowerName = name:lower()
    local pageId = menu[lowerName].pageId

    if #autobind.Keybinds[name .. pageId].Keys == 1 then
        menu[lowerName].size.y = 250
    elseif #autobind.Keybinds[name .. pageId].Keys == 2 then
        menu[lowerName].size.y = 270
    elseif #autobind.Keybinds[name .. pageId].Keys == 3 then
        menu[lowerName].size.y = 290
    end

    setupWindowDraggingAndSize(name, false)

    -- Calculate total price
    local totalPrice = calculateTotalPrice(autobind[name]["Kit" .. pageId], lockers[lowerName].Items)

    -- Define a table to map kitId to key and menu data
    local kits = {}
    for i = 1, autobind[name].maxKits do
        kits[i] = {key = name .. i, menu = autobind[name]["Kit" .. i]}
    end

    -- Locker Window
    local title = string.format("%s - Kit: %d - $%s", label, pageId, formatNumber(totalPrice))
    if imgui.Begin(title, menu[lowerName].window, imgui_flags) then

        -- Display the key editor and menu based on the selected kitId
        for id, kit in pairs(kits) do
            if pageId == id then
                -- Keybind
                keyEditor("Keybind", kit.key, nil, function(action, index, id)
                    local keyCount = #autobind.Keybinds[name .. pageId].Keys
                    if keyCount >= 1 and keyCount <= 3 then
                        local sizeY = 250 + (keyCount - 1) * 20
                        local yOffset = action == "add" and -10 or 10
                
                        imgui.SetWindowSizeVec2(imgui.ImVec2(226, sizeY), imgui.Cond.Always)
                
                        local x = imgui.GetWindowPos().x
                        local y = imgui.GetWindowPos().y
                        imgui.SetWindowPosVec2(imgui.ImVec2(x, y + yOffset), imgui.Cond.Always, menu[lowerName].pivot)
                    end
                end)

                -- Preview Kit
                imgui.SameLine()
                imgui.BeginGroup()
                imgui.PushItemWidth(82)
                if imgui.BeginCombo("##" .. name .. "_preview", fa.ICON_FA_SHOPPING_CART .. " Kit " .. id) then
                    for i = 1, autobind[name].maxKits do
                        if imgui.Selectable(fa.ICON_FA_SHOPPING_CART .. " Kit " .. i .. (i == id and ' [x]' or ''), pageId == i) then
                            menu[lowerName].pageId = i
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

                        menu[lowerName].pageId = autobind[name].maxKits

                        autobind.Keybinds[name .. autobind[name].maxKits] = {Toggle = false, Keys = {VK_MENU, VK_V}, Type = {'KeyDown', 'KeyPressed'}}
                    end
                end
                imgui.EndGroup()

                local selectionTitle = string.format("Selection: [%d/%d]", #autobind[name]["Kit" .. pageId], lockers[lowerName].maxSelections)

                -- Create selection menu
                createMenu(selectionTitle, lockers[lowerName].Items, kit.menu, lockers[lowerName].ExclusiveGroups, lockers[lowerName].maxSelections, {combineGroups = lockers[lowerName].combineGroups})
            end
        end
    end
    imgui.End()
end

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

function renderSettings()
    imgui.SetCursorPos(imgui.ImVec2(20, 5))
    if imgui.BeginChild("##config", imgui.ImVec2(485, 255), false) then
        -- Autobind/Capture
        imgui.Text('Auto Bind:')
        createRow(string.format('Auto Cap (/%s)', clientCommands.autocap.cmd), 'Auto Capture will automatically type /capturf every 1.5 seconds.', autocap, toggleAutoCapture, true)

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
        
        createRow(string.format('Auto Repair (/%s)', clientCommands.repairnear.cmd), 'Auto Repair will automatically accept repair requests.', autobind.Settings.autoRepair, function()
            autobind.Settings.autoRepair = toggleBind("Accept Repair", autobind.Settings.autoRepair)
        end, true)
        
        if mode == "Faction" then
            createRow(string.format('Auto Badge (/%s)', clientCommands.autobadge.cmd), 'Automatically types /badge after spawning from the hospital.', autobind.Faction.autoBadge, function()
                autobind.Faction.autoBadge = toggleBind("Auto Badge", autobind.Faction.autoBadge)
            end, false)
        end
        
        -- Auto Vest
        imgui.NewLine()
        imgui.Text('Auto Vest:')
        createRow(string.format('Enable (/%s)', clientCommands.autovest.cmd), 'Enable for automatic vesting.', autobind.AutoVest.enable, function()
            autobind.AutoVest.enable = toggleBind("Auto Vest", autobind.AutoVest.enable)
        end, true)
        
        createRow(string.format('Diamond Donator (/%s)', clientCommands.ddmode.cmd), 'Enable for Diamond Donators. Uses /guardnear does not have armor/paused checks.', autobind.AutoVest.donor, function()
            autobind.AutoVest.donor = toggleBind("DD Mode", autobind.AutoVest.donor)
            timers.Vest.timer = autobind.AutoVest.donor and ddguardTime or guardTime
        end, false)
        
        -- Accept
        createRow(string.format('Auto Accept (/%s)', clientCommands.autoaccept.cmd), 'Accept Vest will automatically accept vest requests.', accepter.enable, function()
            accepter.enable = toggleBind("Auto Accept", accepter.enable)
        end, true)
    
        createRow(string.format('Allow Everyone (/%s)', clientCommands.vestall.cmd), 'With this enabled, the vest will be applied to everyone on the server.', autobind.AutoVest.everyone, function()
            autobind.AutoVest.everyone = toggleBind("Allow Everyone", autobind.AutoVest.everyone)
        end, false)
        
        if mode == "Faction" then
            imgui.NewLine()
            imgui.Text('Radio Chat:')
            createRow('Modify [WIP]', 'Modify the radio chat to your liking.', autobind.Faction.modifyRadioChat, function()
                autobind.Faction.modifyRadioChat = toggleBind("Modify Radio Chat", autobind.Faction.modifyRadioChat)
            end, false)
        end
    end
    imgui.EndChild()
end

local function drawSkinImages(skins, columns, imageSize, spacing, startPos)
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

function renderSkins()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##skins", imgui.ImVec2(487, 270), false) then
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
            imgui.CustomTooltip(string.format('URL to fetch skins from, must be a JSON array of skin IDs,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.skinsUrl))
            imgui.SameLine()
            imgui.PopItemWidth()
            if imgui.Button("Fetch") then
                fetchJsonDataDirectlyFromURL(autobind.AutoVest.skinsUrl, function(decodedData)
                    autobind.AutoVest.skins = decodedData

                    -- Convert list to set
                    family.skins = table.listToSet(autobind.AutoVest.skins)
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
            imgui.CustomTooltip("Checks if the player has the skins listed below, otherwise it relies on color.")

            imgui.SameLine()

            local disabled = { LSPD = false, ARES = false, FBI = false, SASD = true, GOV = true }
            local desiredFactionsOrder = {"LSPD", "ARES", "FBI", "SASD", "GOV"}

            local factionColors = {}
            for color, factionName in pairs(factions.badges) do
                factionColors[factionName] = color
            end

            imgui.SetCursorPosY(3.5)
            imgui.BeginGroup()
            local firstDisplayed = true
            for _, factionName in ipairs(desiredFactionsOrder) do
                local color = factionColors[factionName]
                if color and not disabled[factionName] then
                    if not firstDisplayed then
                        imgui.SameLine()
                    else
                        firstDisplayed = false
                    end
                    imgui.TextColoredRGB(string.format("{%06x}%s", color, factionName))
                    imgui.CustomTooltip(string.format("{%06x}#%06X", color, color))
                end
            end
            imgui.EndGroup()
            local startPos = imgui.GetCursorPos()
            drawSkinImages(factions.skins, columns, imageSize, spacing, startPos)
        end
    end
    imgui.EndChild()
end

function renderNames()
    imgui.SetCursorPos(imgui.ImVec2(10, 1))
    if imgui.BeginChild("##names", imgui.ImVec2(487, 263), false) then

        imgui.PushFont(fontData.medium.font)

        imgui.PushItemWidth(326)
        local url = new.char[128](autobind.AutoVest.namesUrl)
        if imgui.InputText('##names_url', url, sizeof(url)) then
            autobind.AutoVest.namesUrl = u8:decode(str(url))
        end
        imgui.CustomTooltip(string.format('URL to fetch names from, must be a JSON array of names,\n%s "%s"', fa.ICON_FA_LINK, autobind.AutoVest.namesUrl))
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

function createFontMenuElement(name, title, element, disableColor)
    if element.enable == nil then
        return
    end

    -- First row: Use 6 columns for Title, Toggle, Alignment, Flags, Font Name, and Font Size
    imgui.Columns(8, title .. "_columns_row1", false)
    
    -- Set column widths for the first row (adjust these as needed)
    imgui.SetColumnWidth(0, 70) -- Title
    imgui.SetColumnWidth(1, 45)  -- Toggle checkbox
    imgui.SetColumnWidth(2, 80)  -- Alignment options
    imgui.SetColumnWidth(3, 85) -- Font flags options
    imgui.SetColumnWidth(4, 90) -- Font name input
    imgui.SetColumnWidth(5, 60)  -- Font size adjustment
    imgui.SetColumnWidth(6, 60) -- Text color picker
    imgui.SetColumnWidth(7, 100) -- Value color picker

    imgui.PushFont(fontData.medium.font)
    imgui.AlignTextToFramePadding()
    imgui.Text(title .. ":")
    imgui.NextColumn()

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

    imgui.PushItemWidth(75)
    if imgui.BeginCombo("##flags_" .. title, "Flags") then
        local flagNames = {'BOLD', 'ITALICS', 'BORDER', 'SHADOW', 'UNDERLINE', 'STRIKEOUT'}
        for _, flagName in ipairs(flagNames) do
            local flagValue = element.flags[flagName]
            if imgui.Checkbox(flagName:lower():upperFirst(), new.bool(flagValue)) then
                element.flags[flagName] = not flagValue
                createFont(name, element)
            end
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

    imgui.PushItemWidth(50)
    if imgui.BeginCombo("##size_" .. title, tostring(element.size)) then
        for i = 1, 72 do
            if imgui.Selectable(tostring(i), element.size == i) then
                element.size = i
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
        local clrText = convertColor(element.colors.text, true, false, false)
        local clrEdit1 = new.float[3](clrText.r, clrText.g, clrText.b)
        if imgui.ColorEdit3("##text_color_" .. title, clrEdit1, 
                            imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
            element.colors.text = joinARGB(0, clrEdit1[0], clrEdit1[1], clrEdit1[2], true)
        end
        imgui.PopItemWidth()
        imgui.SameLine(25)
        imgui.Text("Text")
        imgui.EndGroup()
        imgui.NextColumn()

        imgui.BeginGroup()
        imgui.PushItemWidth(95)
        local clrValue = convertColor(element.colors.value, true, false, false)
        local clrEdit2 = new.float[3](clrValue.r, clrValue.g, clrValue.b)
        if imgui.ColorEdit3("##value_color_" .. title, clrEdit2, 
                            imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
            element.colors.value = joinARGB(0, clrEdit2[0], clrEdit2[1], clrEdit2[2], true)
        end
        imgui.PopItemWidth()
        imgui.SameLine(25)
        imgui.Text("Value")
        imgui.EndGroup()

        imgui.Columns(1)
    end

    imgui.PopFont()
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

    downloadManager:queueDownloads(urls, onComplete, progress and onProgress or nil)
end

function fetchJsonDataDirectlyFromURL(url, callback)
    local function onComplete(decodedData)
        if decodedData and next(decodedData) ~= nil then
            callback(decodedData)
        else
            print("JSON format is empty or invalid URL:", url)
        end
    end

    downloadManager:queueFetches({{url = url, callback = onComplete}})
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
                formattedAddChatMessage("Maximum selection limit reached.", clr.RED)
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
                imgui.CustomTooltip(string.format("Price: %s", item.price and "$" .. formatNumber(item.price) or "Free"))
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
            imgui.CustomTooltip(string.format("Price: %s", item.price and "$" .. formatNumber(item.price) or "Free"))
        end
    end
end

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
    local comboWidth = 70  -- Width of the combo box
    local verticalSpacing = 2  -- Vertical spacing after the last key entry

    -- Load the font with the desired size
    imgui.PushFont(fontData.medium.font)

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
        imgui.CustomTooltip(("Press to change, Key: %d"):format(i))

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
        if i == 1 then
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local minusButtonSize = {x = 14, y = 18.5}
            if imgui.Button("+##add" .. index, minusButtonSize) then
                local nextIndex = #keyBinds.Keys + 1
                if nextIndex <= 3 then
                    table.insert(keyBinds.Keys, 0)
                    if type(keyBinds.Type) ~= "table" then
                        keyBinds.Type = {keyBinds.Type or "KeyDown"}
                    end
                    table.insert(keyBinds.Type, "KeyDown")

                    if callback then
                        callback(
                            "add",
                            index,
                            i
                        )
                    end
                end
            end
            imgui.CustomTooltip("Add a new key binding.")
        elseif i ~= 1 then
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            local minusButtonSize = {x = 14, y = 18.5}
            if imgui.Button("-##remove" .. index .. i, minusButtonSize) then
                table.remove(keyBinds.Keys, i)
                if type(keyBinds.Type) == "table" then
                    table.remove(keyBinds.Type, i)
                end

                if callback then
                    callback(
                        "remove",
                        index,
                        i
                    )
                end
            end
            imgui.CustomTooltip("Remove this key binding.")
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

function GameModeRestart()
    local bs = raknetNewBitStream()
    raknetEmulRpcReceiveBitStream(40, bs)
    raknetDeleteBitStream(bs)
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

function autoConnect()
    if autobind.Settings and autobind.Settings.autoReconnect then
        GameModeRestart()
        sampSetGamestate(1)
    end
end

function toggleAutoCapture()
	if not checkAdminDuty() then
		autocap = not autocap

		formattedAddChatMessage(autocap and  ("Starting capture attempt... {%06x}(type /%s to toggle)"):format(clr.YELLOW, clientCommands.autocap.cmd) or "Auto Capture ended.")
	end
end

function toggleBind(name, bool)
    bool = not bool
    local color = bool and clr.REALGREEN or clr.RED
    formattedAddChatMessage(("%s: {%06x}%s"):format(name, color, bool and 'on' or 'off'))
    return bool
end

function createFarmerDialog()
    local dialogText = "You have arrived at your designated farming spot.\nAuto-Typing /harvest to harvest some crops.\n\nWarning: Pressing disable will turn off auto farming."
    sampShowDialog(farmer.dialogId, ("[%s] Auto Farming"):format(shortName:upper()), dialogText, "Close", "Disable", 0)
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

-- Check if the muted timer has been triggered
function checkMuted()
	if localClock() - timers.Muted.last < timers.Muted.timer then
		return true
	end
	return false
end

-- Check if you if the heal timer has expired or not
function checkHeal()
	if localClock() - timers.Heal.last < timers.Heal.timer then
		return true
	end
	return false
end

function setTimer(additionalTime, timer)
	timer.last = localClock() - (timer.timer - 0.2) + (additionalTime or 0)
end

-- Convert Speed (MPH or KMH)
function convertSpeed(speed, isMPHOrKMH)
    return math.ceil(speed * (isMPHOrKMH and 2.98 or 4.80))
end

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
            local newPath = {table.unpack(path)}
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
            local newPath = {table.unpack(p)}
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
    local success, err = checkForIssues(config)
    if not success then
        return false, err
    end

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

-- Function to convert seconds into a human-readable format
function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local timeString = ""
    if hours > 0 then
        timeString = timeString .. ("%d hour%s, "):format(hours, hours > 1 and "s" or "")
    end
    if minutes > 0 then
        timeString = timeString .. ("%d minute%s, "):format(minutes, minutes > 1 and "s" or "")
    end
    timeString = timeString .. ("%.1f second%s"):format(seconds, seconds ~= 1 and "s" or "")

    return timeString
end

-- Function to remove color codes from text
function removeHexBrackets(text)
    return string.gsub(text, "{%x+}", "")
end

function formatNumber(num)
    -- Convert to string and handle negative numbers
    local isNegative = num < 0
    num = tostring(math.abs(num))
    
    -- Add commas
    local formatted = num:reverse():gsub("...","%0,",math.floor((#num-1)/3)):reverse()
    
    -- Add negative sign if needed
    return isNegative and "-" .. formatted or formatted
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

function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function imgui.handleWindowDragging(menuId, pos, size, pivot, dragging)
    if not dragging then
        return {x = pos.x, y = pos.y}, false
    end

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

function imgui.CustomButton(name, color, colorHovered, colorActive, textColor, size)
    local clr = imgui.Col
    imgui.PushStyleColor(clr.Button, color)
    imgui.PushStyleColor(clr.ButtonHovered, colorHovered)
    imgui.PushStyleColor(clr.ButtonActive, colorActive)
    imgui.PushStyleColor(clr.Text, textColor)
    if not size then size = imgui.ImVec2(0, 0) end
    local result = imgui.Button(name, size)
    imgui.PopStyleColor(4)
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

end) -- End of checkAndDownloadDependencies

if scriptError then
    print("scriptError:")
    print(scriptError)
end

if mainScript then
    print(("%s %s loaded successfully."):format(scriptName, scriptVersion))
else
    print(("%s %s failed to load."):format(scriptName, scriptVersion))
end
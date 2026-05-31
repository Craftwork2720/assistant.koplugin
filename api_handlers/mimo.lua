local BaseHandler = require("api_handlers.base")
local json = require("json")
local koutil = require("util")
local logger = require("logger")

local MiMoHandler = BaseHandler:new()

function MiMoHandler:query(message_history, mimo_settings)
    local additional = mimo_settings.additional_parameters or {}

    local requestBodyTable = {
        model = mimo_settings.model,
        messages = message_history,
        max_tokens = mimo_settings.max_tokens,
        stream = additional.stream or false,
    }

    -- Merge additional parameters (temperature, top_p, thinking, max_completion_tokens, etc.)
    for k, v in pairs(additional) do
        if k ~= "stream" then
            requestBodyTable[k] = v
        end
    end

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["api-key"] = mimo_settings.api_key,
    }

    if requestBodyTable.stream then
        headers["Accept"] = "text/event-stream"
        return self:backgroundRequest(mimo_settings.base_url, headers, requestBody)
    end

    local status, code, response = self:makeRequest(mimo_settings.base_url, headers, requestBody)

    if status then
        local success, responseData = pcall(json.decode, response)
        if success then
            local content = koutil.tableGetValue(responseData, "choices", 1, "message", "content")
            if content then return content end
        end

        logger.warn("API Error", code, response)
        if success then
            local err_msg = koutil.tableGetValue(responseData, "error", "message")
            if err_msg then return nil, err_msg end
        end
    end

    if code == BaseHandler.CODE_CANCELLED then
        return nil, response
    end

    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return MiMoHandler

local ipairs, pairs, type = ipairs, pairs, type
local log, CRIT = ngx.log, ngx.CRIT
local fmt_util = require "trochilus.common.util.fmt"

local const = require "trochilus.gateway.const"
local HTTP_METHODS = const.HTTP_METHODS
local PHASES = const.PHASES

local exports = {}

--[[
{
    id = id,
    plugins = {
        [plugin_name] = {
            src_conf = {}
        }
    },
    funcs = {
        [phase] = {
            [plugin_name] = f
        }
    }
}
]]
exports.new = function()
    local self = {
        plugins = {},
        funcs = {}
    }
    for _, phase in ipairs(PHASES) do self.funcs[phase] = {} end
    return self
end

local parse_plugin_conf = function(self, name, conf)
    if ("string" ~= type(name)) or ("table" ~= type(conf)) then return end
    log(CRIT, "parse plugin: ", name)
    local ok, plugin_context = pcall(require, "trochilus.gateway.plugin." .. name .. ".context")
    if not ok then return end

    local ctx = plugin_context.on_parse_conf(conf)
    if not ctx then return end
    log(CRIT, "parsed: ", fmt_util.sprint(ctx))
    ctx.src_conf = conf
    self.plugins[name] = ctx

    local plugin_service = require("trochilus.gateway.plugin." .. name .. ".service")
    for _, phase in ipairs(PHASES) do
        local func_name = "on_" .. phase
        if plugin_service[func_name] then
            self.funcs[phase][name] = plugin_service[func_name]
        end
    end
end

exports.parse_conf = function(self, conf)
    local path, method, id = conf.path, conf.method or "ALL", conf.id
    if (not HTTP_METHODS[method]) and (method ~= "ALL") then return nil end
    if "string" ~= type(path) then return nil end

    self.id = id
    for plugin_name, plugin_conf in pairs(conf.plugins or {}) do
        plugin_conf.location_id = id
        parse_plugin_conf(self, plugin_name, plugin_conf)
    end
    return path, method
end

return exports

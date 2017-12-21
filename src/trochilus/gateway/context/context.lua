local type, ipairs = type, ipairs
local string_format = string.format
local ngx = ngx
local log, CRIT = ngx.log, ngx.CRIT

local location = require "trochilus.gateway.context.location"
local kafka = require "trochilus.gateway.context.kafka"
local consul = require "trochilus.gateway.context.consul"
local sys_util = require "trochilus.common.util.sys"

local exports = {}

-- package fields

--[[
{
    [location] = {
        [method] = location
    }
}
]]
local locations = {}
exports.locations = locations

--[[
{
    group_id = "",
    mpid = 100,
    hostname = "",
}
]]
local instance = {}
exports.instance = instance


exports.init_context = function()
    instance.mpid = sys_util.master_pid()
    instance.hostname = sys_util.hostname()
end

exports.parse_conf = function(conf)
    instance.group_id = conf.group_id

    if "table" == type(conf.kafka) then
        log(CRIT, "parsing kafka conf")
        local ok = kafka.parse_conf(conf.kafka)
        if not ok then
            log(CRIT, "failed to parse kafka conf")
            return nil
        end
    end
    if "table" == type(conf.consul) then
        log(CRIT, "parsing consul conf")
        local ok = consul.parse_conf(conf.consul)
        if not ok then
            log(CRIT, "failed to parse consul conf")
            return nil
        end
    end

    for _, location_conf in ipairs(conf.locations or {}) do
        if ("table" == type(location_conf)) and location_conf.id then
            log(CRIT, "init location id: ", location_conf.id)
            local loc = location.new()
            local path, method = location.parse_conf(loc, location_conf)

            if path then
                log(CRIT, "success to init location id: ", location_conf.id)
                local methods = locations[path]
                if not methods then
                    methods = {}
                    locations[path] = methods
                end
                methods[method] = loc
            end
        end
    end
    return true
end

exports.instance_info = function(ngx)
    return {
        group_id = instance.group_id,
        instance_id = string_format("%s:%s", instance.hostname, instance.mpid),
        worker_id = ngx.worker.id(),
        worker_pid = ngx.worker.pid()
    }
end

return exports

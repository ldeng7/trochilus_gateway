local shared, ngx_time = ngx.shared, ngx.time
local string_format = string.format
local math_floor = math.floor

local args_util = require "trochilus.gateway.util.args"
local args_get_multi = args_util.get_multi
local SHM_KEY = require("trochilus.gateway.const").SHM_KEY
local context = require "trochilus.gateway.context.context"
local kafka = require "trochilus.gateway.context.kafka"
local kafka_send_obj = kafka.send_obj

local check_access = function(ngx, ctx, key)
    local now = ngx_time()
    key = string_format("lr:%s", key)
    local interval = ctx.interval
    if interval < 0 then
        if -1 == interval then
            interval = (math_floor(now / 60) + 1) * 60 - now
        elseif -2 == interval then
            interval = (math_floor(now / 3600) + 1) * 3600 - now
        end
    end

    local cnt
    local dict = shared[SHM_KEY]
    local ok, err = dict:add(key, 1, interval)
    if ok then
        cnt = 1
    elseif err == "exists" then
        cnt = dict:incr(key, 1)
    end

    if cnt < ctx.threshold then return true end
    if cnt == ctx.threshold then
        local t = {
            topic = ctx.kafka_topic,
            type = "limit_req",
            timestamp = ngx_time(),
            instance = context.instance_info(ngx),
            location_id = ctx.location_id
        }
        kafka_send_obj(ctx.kafka_instance, ctx.kafka_topic, t)
    end
    return false
end

local exports = {}

exports.on_rewrite = function(ngx, ctx)
    return nil
end

exports.on_access = function(ngx, ctx, req_ctx)
    local key = ctx.key
    if ctx.args then key = args_get_multi(ctx, ngx.req) end
    local res = check_access(ngx, ctx, key)
    if false ~= res then return true end

    ngx.status = ctx.limit_code
    ngx.say(ctx.limit_body)
    return false, ctx.limit_code
end

return exports

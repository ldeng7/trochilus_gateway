local tostring, tonumber = tostring, tonumber
local context = require "trochilus.gateway.context.context"
local kafka = require "trochilus.gateway.context.kafka"
local kafka_send_obj = kafka.send_obj
local consul = require "trochilus.gateway.context.consul"

local aggregate = function(ngx, stat)
    local var = ngx.var

    local cnt_prev = stat.cnt
    stat.cnt = cnt_prev + 1

    local cnt_status = stat.cnt_status
    local status = tostring(ngx.status)
    cnt_status[status] = (cnt_status[status] or 0) + 1

    local dur_sum = stat.dur_sum
    local dur = tonumber(var.request_time) or ((cnt_prev > 0) and (dur_sum / cnt_prev)) or 0
    stat.dur_sum = dur_sum + dur
end

local exports = {}

local new_stat = function()
    return {
        cnt = 0,
        cnt_status = {},
        dur_sum = 0
    }
end
exports.new_stat = new_stat

exports.on_rewrite = function(ngx, ctx)
    return nil
end

exports.on_log = function(ngx, ctx, req_ctx)
    aggregate(ngx, ctx.stat)
end

exports.report = function(ngx, ctx)
    local t = {
        topic = ctx.topic,
        type = "stat",
        timestamp = ngx.time(),
        instance = context.instance_info(ngx),
        location_id = ctx.location_id
    }

    local stat = ctx.stat
    ctx.stat = new_stat()
    stat.dur_avg = ((stat.cnt > 0) and (stat.dur_sum / stat.cnt)) or 0
    stat.dur_sum = nil
    t.stat = stat

    if ctx.consul_instance then
        t.consul = consul.serv_info(ctx.consul_instance, ctx.consul_serv_name)
    end

    kafka_send_obj(ctx.instance, ctx.topic, t)
end

return exports

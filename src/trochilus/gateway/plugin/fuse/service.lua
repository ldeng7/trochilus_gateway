local ngx_time = ngx.time
local SHM_KEY = require("trochilus.gateway.const").SHM_KEY
local context = require "trochilus.gateway.context.context"
local kafka = require "trochilus.gateway.context.kafka"
local kafka_send_obj = kafka.send_obj
local baffle = require "trochilus.common.frame.baffle"

local STATES_NAME = {
    [baffle.STATE_NORMAL]  = "normal",
    [baffle.STATE_FLOP]    = "open",
    [baffle.STATE_RECOVER] = "half-open"
}

local kafka_report_state = function(ngx, ctx, state)
    local t = {
        topic = ctx.kafka_topic,
        type = "consul",
        timestamp = ngx_time(),
        instance = context.instance_info(ngx),
        location_id = ctx.location_id,
        state = STATES_NAME[state]
    }
    kafka_send_obj(ctx.kafka_instance, ctx.kafka_topic, t)
end

local exports = {}

exports.on_rewrite = function(ngx, ctx)
    local baf = baffle.new(SHM_KEY, ctx.key,
        ctx.interval, ctx.threshold, ctx.fuse_dur, ctx.rc_thres, ctx.rc_thres_suc)
    return {baf = baf}
end

exports.on_access = function(ngx, ctx, req_ctx)
    local allowed, state, state_prev = baffle.check_in(req_ctx.baf)
    req_ctx.allowed, req_ctx.state = allowed, state
    if state ~= state_prev then kafka_report_state(ngx, ctx, state) end
    if allowed then return true end

    ngx.status = ctx.fuse_code
    ngx.say(ctx.fuse_body)
    return false, ctx.fuse_code
end

exports.on_log = function(ngx, ctx, req_ctx)
    if not req_ctx.allowed then return end
    local state, state_prev = baffle.check_out(req_ctx.baf, not ctx.codes[ngx.status], req_ctx.state)
    if state ~= state_prev then kafka_report_state(ngx, ctx, state) end
end

return exports

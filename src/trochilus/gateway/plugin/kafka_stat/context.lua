local tonumber = tonumber
local ngx = ngx
local timer_at = ngx.timer.at
local service = require "trochilus.gateway.plugin.kafka_stat.service"

local exports = {}

local gen_timer_cb = function(ctx)
    local cb
    cb = function(_)
        timer_at(ctx.period, cb)
        service.report(ngx, ctx)
    end
    return cb
end

exports.on_parse_conf = function(conf)
    local period = tonumber(conf.period) or 60
    if period < 1 then period = 60 end
    local ctx = {
        instance = conf.instance,
        location_id = conf.location_id,
        topic = conf.topic,
        period = period,
        consul_instance = conf.consul_instance,
        consul_serv_name = conf.consul_serv_name,
        stat = service.new_stat()
    }
    timer_at(period, gen_timer_cb(ctx))
    return ctx
end

return exports

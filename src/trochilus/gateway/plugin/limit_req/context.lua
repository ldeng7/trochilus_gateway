local tonumber, type = tonumber, type
local args_util = require "trochilus.gateway.util.args"

local exports = {}

exports.on_parse_conf = function(conf)
    local interval = tonumber(conf.interval) or 10
    if (interval < 1) and (interval ~= -1) and (interval ~= -2) then interval = 10 end
    local threshold = tonumber(conf.threshold) or 10
    if threshold < 1 then threshold = 10 end

    return {
        key = (("string" == type(conf.key)) and conf.key) or "",
        args = args_util.parse(conf.args),
        args_delim = (("string" == type(conf.args_delim)) and conf.args_delim) or ":",
        interval = interval,
        threshold = threshold,
        limit_code = tonumber(conf.limit_code) or 503,
        limit_body = (("string" == type(conf.limit_body)) and conf.limit_body) or "{}",
        kafka_instance = conf.kafka_instance,
        kafka_topic = conf.kafka_topic
    }
end

return exports

local tonumber, type = tonumber, type
local args_util = require "trochilus.gateway.util.args"

local exports = {}

exports.on_parse_conf = function(conf)
    return {
        key = (("string" == type(conf.key)) and conf.key) or "",
        args = args_util.parse(conf.args),
        args_delim = (("string" == type(conf.args_delim)) and conf.args_delim) or ":",
        rate = tonumber(conf.rate) or 100,
        burst = tonumber(conf.burst) or 200,
        limit_code = tonumber(conf.limit_code) or 503,
        limit_body = (("string" == type(conf.limit_body)) and conf.limit_body) or "{}",
    }
end

return exports

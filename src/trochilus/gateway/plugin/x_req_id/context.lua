local math_randomseed = math.randomseed
local ngx = ngx

local exports = {}

exports.on_parse_conf = function(conf)
    math_randomseed(ngx.now() + ngx.worker.id())
    return {}
end

return exports

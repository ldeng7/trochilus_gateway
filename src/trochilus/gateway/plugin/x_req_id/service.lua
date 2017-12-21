local string_format, math_random = string.format, math.random

local RMAX = 4294967295

local exports = {}

exports.on_rewrite = function(ngx, ctx)
    local req_id = ngx.req.get_headers()["X-Request-ID"]
    if not req_id then
        req_id = string_format("%08x%08x%08x%08x",
            math_random(0, RMAX), math_random(0, RMAX), math_random(0, RMAX), math_random(0, RMAX))
        ngx.req.set_header("X-Request-ID", req_id)
    end
    return nil
end

return exports

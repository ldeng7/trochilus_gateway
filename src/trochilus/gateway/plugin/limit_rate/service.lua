local args_util = require "trochilus.gateway.util.args"
local args_get_multi = args_util.get_multi
local SHM_KEY = require("trochilus.gateway.const").SHM_KEY
local bucket = require "trochilus.common.frame.bucket"

local exports = {}

exports.on_rewrite = function(ngx, ctx)
    return nil
end

exports.on_access = function(ngx, ctx, req_ctx)
    local key = ctx.key
    if ctx.args then key = args_get_multi(ctx, ngx.req) end
    local buc = bucket.new(SHM_KEY, key, ctx.rate, ctx.burst)
    local delay = bucket.check_in(buc)
    if delay then
        if delay >= 0.001 then ngx.sleep(delay) end
        return true
    end

    ngx.status = ctx.limit_code
    ngx.say(ctx.limit_body)
    return false, ctx.limit_code
end

return exports

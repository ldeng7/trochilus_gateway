local balancer = require "ngx.balancer"
local set_timeouts = balancer.set_timeouts

local exports = {}

exports.on_balancer = function(ngx, ctx)
    set_timeouts(ctx.ct, ctx.st, ctx.rt)
end

return exports

local balancer = require "ngx.balancer"
local consul = require "trochilus.gateway.context.consul"
local consul_peek_peer = consul.peek_peer

local exports = {}

exports.on_rewrite = function(ngx, ctx)
    return {}
end

exports.on_access = function(ngx, ctx, req_ctx)
    local peers, idx = consul_peek_peer(ctx.instance, ctx.serv_name, false)
    if not peers then return false, 502 end
    req_ctx.peers, req_ctx.idx, req_ctx.round = peers, idx, 0
end

exports.on_balancer = function(ngx, ctx, req_ctx)
    req_ctx.round = req_ctx.round + 1
    local peers, idx = req_ctx.peers, req_ctx.idx
    if req_ctx.round > 1 then
        local peers_new, _ = consul_peek_peer(ctx.instance, ctx.serv_name, true)
        if peers_new then
            req_ctx.peers = peers_new
            peers = peers_new
        end
    end

    if idx > #peers then idx = 1 end
    local peer = peers[idx]
    req_ctx.idx = idx + 1

    local ok, err = balancer.set_current_peer(peer[1], peer[2])
    if not ok then
        ngx.log(ngx.ERR, err)
        return false, 500
    end
end

return exports

local tonumber, ipairs, type = tonumber, ipairs, type
local ngx_time = ngx.time
local log, CRIT = ngx.log, ngx.CRIT
local consul_util = require "trochilus.common.net.tool.consul"

-- package fields
--[[
{
    [key] = {
        key = key,
        src_conf = {},
        dns_period = 60,
        dns = {
            [serv_name] = {
                peers = {
                    {"127.0.0.1", 8080}
                },
                idx = 1,
                ttl = 1388888888
            }
        },
        cs = cs
    }
}
]]
local instances = {}

local exports = {}
exports.instances = instances

local parse_instance_conf = function(conf)
    local cs = consul_util.new(conf.host or "127.0.0.1", {
        dns_port = tonumber(conf.dns_port) or 8600,
        dns_timeout = conf.dns_timeout or 500,
        dns_retrans = 2,
        api_port = tonumber(conf.api_port) or 8500,
        api_timeout = tonumber(conf.api_timeout) or 500
    })
    instances[conf.key] = {
        key = conf.key,
        src_conf = conf,
        dns_period = tonumber(conf.dns_period) or 60,
        dns = {},
        cs = cs
    }
end

exports.parse_conf = function(conf)
    if ("table" ~= type(conf.instances)) or (0 == #conf.instances) then
        log(CRIT, "empty consul instances")
        return nil
    end
    for _, c in ipairs(conf.instances) do
        parse_instance_conf(c)
    end
    return true
end

exports.peek_peer = function(instance, serv_name, force_update)
    local now = ngx_time()
    local ins = instances[instance]
    if not ins then return nil end

    local dns = ins.dns
    local serv = dns[serv_name]
    if not serv then
        serv = {
            peers = {},
            idx = 1,
            ttl = now + ins.dns_period
        }
        dns[serv_name] = serv
    end

    local peers = serv.peers
    if (not peers[1]) or (serv.ttl <= now) or force_update then
        peers = consul_util.query_dns(ins.cs, serv_name)
        if peers and peers[1] then
            serv.peers = peers
            serv.ttl = now + ins.dns_period
        end
    end

    peers = serv.peers
    if not peers[1] then return nil end
    local idx = serv.idx
    if idx > #peers then idx = 1 end
    serv.idx = idx + 1
    return peers, idx
end

exports.serv_info = function(instance, serv_name)
    local ins = instances[instance]
    if not ins then return nil end

    local out = {}
    out.nodes = consul_util.api_list_nodes(ins.cs)
    local serv = ins.dns[serv_name]
    if serv then
        out.peers = serv.peers
    end
    return out
end

return exports

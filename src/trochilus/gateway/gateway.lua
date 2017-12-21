local type, pairs, ipairs = type, pairs, ipairs
local log, CRIT = ngx.log, ngx.CRIT

local const = require "trochilus.gateway.const"
local NGX_VAR_KEY_PATH = const.NGX_VAR_KEY_PATH
local NGX_CTX_KEY_LOC = const.NGX_CTX_KEY_LOC
local NGX_CTX_KEY_REQ_PLUGIN = const.NGX_CTX_KEY_REQ_PLUGIN
local PHASES = const.PHASES
local context = require "trochilus.gateway.context.context"
local locations = context.locations
local sys_util = require "trochilus.common.util.sys"
local yaml = require "trochilus.common.util.codec.yaml"

local exports = {}

local read_conf = function(args)
    if args.yaml then
        log(CRIT, "using yaml conf")
        return yaml.decode_file(args.yaml)
    end

    local ok, conf = pcall(require, "config.gateway")
    if ok then
        log(CRIT, "using lua conf")
        return conf
    end

    return nil
end

exports.on_init_worker = function(ngx, args)
    log(CRIT, "init worker")
    context.init_context()
    if "table" ~= type(args) then args = {} end

    local conf = read_conf(args)
    if "table" == type(conf) then
        local ok = context.parse_conf(conf)
        if ok then return end
        log(CRIT, "failed to parse conf")
    else
        log(CRIT, "no valid conf found!")
    end
    log(CRIT, "failed to init worker, quiting the nginx master process")
    return sys_util.send_quit(context.instance.mpid)
end

for _, phase in ipairs(PHASES) do
    exports["on_" .. phase] = function(ngx)
        local location = ngx.ctx[NGX_CTX_KEY_LOC]
        if not location then return end

        local plugins = location.plugins
        local funcs = location.funcs[phase]
        local req_plugin_ctx = ngx.ctx[NGX_CTX_KEY_REQ_PLUGIN]
        for plugin_name, func in pairs(funcs) do
            local ok, status = func(ngx, plugins[plugin_name], req_plugin_ctx[plugin_name])
            if false == ok then return ngx.exit(status or 400) end
        end
    end
end

exports.on_rewrite = function(ngx)
    local methods = locations[ngx.var[NGX_VAR_KEY_PATH] or ""]
    if not methods then return end
    local location = methods[ngx.req.get_method()] or methods.ALL
    if not location then return end
    ngx.ctx[NGX_CTX_KEY_LOC] = location

    local plugins = location.plugins
    local funcs = location.funcs.rewrite
    local req_plugin_ctx = {}
    for plugin_name, func in pairs(funcs) do
        req_plugin_ctx[plugin_name] = func(ngx, plugins[plugin_name])
    end
    ngx.ctx[NGX_CTX_KEY_REQ_PLUGIN] = req_plugin_ctx
end

return exports

local unescape_uri = ngx.unescape_uri
local os_date = os.date
local table_concat = table.concat
local kafka = require "trochilus.gateway.context.kafka"
local kafka_send_obj = kafka.send_obj

local exports = {}

local collect = function(ngx, ctx, req_ctx)
    local req, var = ngx.req, ngx.var
    local req_headers = req.get_headers()
    local out = {}

    out.topic = ctx.topic
    out.type = "req"
    out.datetime = os_date("%Y-%m-%d %H:%M:%S")
    out.node_name = ctx.node_name
    out.hostname = var.hostname

    out.req_remote_addr = var.remote_addr
    out.req_method = var.request_method
    out.req_uri = var.uri
    out.req_uri_query = unescape_uri(var.args)
    out.req_forwarded_for = req_headers["X-Forwarded-For"]
    out.req_ua = req_headers["User-Agent"]
    out.req_id = req_headers["X-Request-ID"]
    out.req_body = req.get_body_data()

    out.upstream_addr = var.upstream_addr
    out.upstream_dur = var.upstream_responce_time
    out.upstream_status = var.upstream_status

    out.resp_status = ngx.status
    out.resp_dur = var.request_time
    out.resp_body_bytes = var.body_bytes_sent
    out.resp_body = req_ctx.resp_body

    return out
end

exports.on_rewrite = function(ngx, ctx)
    ngx.req.read_body()
    local req_ctx = {
        rbt = {}
    }
    if ctx.crb_is_codes then
        req_ctx.crb = ctx.crb[ngx.status]
    else
        req_ctx.crb = ctx.crb
    end
    return req_ctx
end

exports.on_body_filter = function(ngx, ctx, req_ctx)
    local t = req_ctx.rbt
    t[#t + 1] = ngx.arg[1]
    if ngx.arg[2] then
        req_ctx.resp_body = table_concat(t)
    end
end

exports.on_log = function(ngx, ctx, req_ctx)
    local o = collect(ngx, ctx, req_ctx)
    kafka_send_obj(ctx.instance, ctx.topic, o)
end

return exports

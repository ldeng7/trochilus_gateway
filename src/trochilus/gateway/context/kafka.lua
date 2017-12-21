local ipairs, type = ipairs, type
local table_concat = table.concat
local ngx_time = ngx.time
local log, CRIT = ngx.log, ngx.CRIT
local cjson = require "cjson.safe"
local json_encode = cjson.encode

local kafka_producer = require "ext.github.doujiang24.lua-resty-kafka.producer"
local kafka_producer_send = kafka_producer.send
local logger_socket = require "ext.github.cloudflare.lua-resty-logger-socket.socket"

-- package fields
local instances = {}
local ali_t = {}

local exports = {}

local partitioner = function(_, num_partition, _)
    return ngx_time() % num_partition
end

local send_err_fallback = function(_, _, queue, n, _, _)
    ali_t[3] = ngx_time()
    for i = 2, n, 2 do
        ali_t[5] = queue[i]
        logger_socket.log(table_concat(ali_t, " "))
        --log(CRIT, table_concat(ali_t, " "))
    end
end

local parse_fallback_conf = function(conf)
    log(CRIT, "parsing fallback conf")
    logger_socket.init({
        host = conf.host,
        port = conf.port,
        sock_type = conf.sock_type,
        max_retry_times = 2
    })
    ali_t[1] = conf.ali_ver
    ali_t[2] = conf.ali_tag
    ali_t[4] = "127.0.0.1"
    ali_t[5] = true
end

local parse_instance_conf = function(conf, do_fallback)
    log(CRIT, "parsing key: ", conf.key)
    local pd_conf = {
        producer_type = "async",
        refresh_interval = conf.refresh_interval,
        max_retry = 2,
        partitioner = partitioner
    }
    if do_fallback then
        pd_conf.error_handle = send_err_fallback
    end
    instances[conf.key] = {
        src_conf = conf,
        pd = kafka_producer.new(nil, conf.broker_list, pd_conf)
    }
end

exports.parse_conf = function(conf)
    if ("table" ~= type(conf.instances)) or (0 == #conf.instances) then
        log(CRIT, "empty kafka instances")
        return nil
    end

    local do_fallback
    if conf.fallback then
        do_fallback = true
        parse_fallback_conf(conf.fallback)
    end

    for _, c in ipairs(conf.instances) do
        parse_instance_conf(c, do_fallback)
    end
    return true
end

exports.send_obj = function(instance, topic, obj)
    local ins = instances[instance]
    if not ins then return end
    kafka_producer_send(ins.pd, topic, nil, json_encode(obj))
end

return exports

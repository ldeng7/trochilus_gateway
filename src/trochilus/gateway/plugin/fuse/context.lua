local tonumber, tostring, type, ipairs = tonumber, tostring, type, ipairs
local exports = {}

exports.on_parse_conf = function(conf)
    local codes, empty = {}, true
    if "table" == type(conf.codes) then
        for _, c in ipairs(conf.codes) do
            c = tonumber(c)
            if c then
                codes[c] = true
                empty = false
            end
        end
    end
    if empty then
        codes = {[502] = true, [504] = true}
    end

    return {
        key = (("string" == type(conf.key)) and conf.key) or "",
        interval = tonumber(conf.interval) or 10,
        codes = codes,
        threshold = tonumber(conf.threshold) or 100,
        fuse_dur = tonumber(conf.fuse_dur) or 10,
        fuse_code = tonumber(conf.fuse_code) or 503,
        fuse_body = (("string" == type(conf.fuse_body)) and conf.fuse_body) or "{}",
        rc_thres = tonumber(conf.recover_threshold) or 5,
        rc_thres_suc = tonumber(conf.recover_success) or 4,
        kafka_instance = conf.kafka_instance,
        kafka_topic = conf.kafka_topic
    }
end

return exports

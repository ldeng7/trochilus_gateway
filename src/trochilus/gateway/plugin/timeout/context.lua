local tonumber = tonumber

local exports = {}

exports.on_parse_conf = function(conf)
    return {
        ct = tonumber(conf.connect_timeout),
        st = tonumber(conf.send_timeout),
        rt = tonumber(conf.read_timeout)
    }
end

return exports

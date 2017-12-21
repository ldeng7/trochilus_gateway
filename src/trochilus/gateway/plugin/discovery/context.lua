local exports = {}

exports.on_parse_conf = function(conf)
    return {
        instance = conf.instance,
        serv_name = conf.serv_name
    }
end

return exports

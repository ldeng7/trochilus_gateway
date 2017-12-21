local tonumber, type, ipairs = tonumber, type, ipairs

local exports = {}

exports.on_parse_conf = function(conf)
    local crb, crb_is_codes = conf.collect_resp_body, nil
    if "table" == type(crb) then
        local crb_keys = {}
        for _, s in ipairs(crb) do
            s = tonumber(s)
            if s then crb_keys[s] = true end
        end
        crb = crb_keys
        crb_is_codes = true
    elseif "boolean" ~= type(crb) then
        crb = false
    end

    return {
        instance = conf.instance,
        topic = conf.topic,
        node_name = conf.node_name,
        crb = crb,
        crb_is_codes = crb_is_codes
    }
end

return exports

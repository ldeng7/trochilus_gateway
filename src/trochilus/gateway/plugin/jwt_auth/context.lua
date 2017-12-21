local tonumber, type, ipairs = tonumber, type, ipairs
local jwt_verify = require "trochilus.common.util.codec.jwt_lite.verify"

local exports = {}

exports.on_parse_conf = function(conf)
    local token_ref = conf.token_ref
    if "string" ~= type(token_ref) then return nil end
    local algo = conf.algo
    if not jwt_verify.ALGOS[algo] then return nil end

    local secret, secret_ref = conf.secret, nil
    if "table" == type(secret) then
        secret_ref = conf.secret_ref
        if "string" ~= type(secret_ref) then return nil end

        local arr = {}
        for _, e in ipairs(secret) do
            if ("table" == type(e)) and (#e >= 2) then
                arr[#arr + 1] = {e[1], e[2]}
            end
        end
        if 0 == #arr then return nil end
        secret = arr
    elseif "string" == type(secret) then
        secret = secret
    else
        return nil
    end

    return {
        verifiers = {},
        token_ref = token_ref,
        algo = algo,
        secret = secret,
        secret_ref = secret_ref,
        fail_code = tonumber(conf.fail_code) or 401,
        fail_body = (("string" == type(conf.fail_body)) and conf.fail_body) or "{}"
    }
end

return exports

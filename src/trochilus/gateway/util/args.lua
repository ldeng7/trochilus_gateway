local type, ipairs, pairs = type, ipairs, pairs
local table_concat = table.concat
local cjson = require "cjson.safe"
local json_decode = cjson.decode

local exports = {}

local reg_checkers = {
    header = function(ref)
        return (("string" == type(ref)) and ref) or nil
    end,
    uri_arg = function(ref)
        return (("string" == type(ref)) and ref) or nil
    end,
    body_arg = function(ref)
        return (("string" == type(ref)) and ref) or nil
    end,
    body_json = function(ref)
        if "table" ~= type(ref) then return nil end
        local out = {}
        for i, e in ipairs(ref) do
            if "string" ~= type(e) then return nil end
            out[i] = e
        end
        return out
    end
}

local getters = {
    header = function(req, ref)
        return req.get_headers()[ref]
    end,
    uri_arg = function(req, ref)
        return req.get_uri_args()[ref]
    end,
    body_arg = function(req, ref)
        req.read_body()
        return req.get_post_args()[ref]
    end,
    body_json = function(req, ref)
        req.read_body()
        local body = req.get_body_data()
        local o = json_decode(body)
        for _, r in ipairs(ref) do
            if "table" ~= type(o) then return nil end
            o = o[r]
        end
        return o
    end
}

exports.parse = function(args)
    if "table" ~= type(args) then return nil end
    local out, i = {}, 1
    for _, e in ipairs(args) do
        for k, f in pairs(reg_checkers) do
            if e[k] then
                local ref = f(e[k])
                if ref then
                    out[i] = {
                        ref = ref,
                        getter = getters[k]
                    }
                    i = i + 1
                    break
                end
            end
        end
    end
    if #out == 0 then return nil end
    return out
end

exports.get_multi = function(ctx, req)
    local t, i = {ctx.key}, 2
    for _, e in ipairs(ctx.args) do
        local arg = e.getter(req, e.ref)
        local typ = type(arg)
        if ("string" == typ) or ("number" == typ) then
            t[i] = arg
        else
            t[i] = "nil"
        end
        i = i + 1
    end
    return table_concat(t, ctx.args_delim)
end

return exports

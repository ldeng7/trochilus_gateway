local type, ipairs = type, ipairs
local re_match = ngx.re.match
local jwt_verify = require "trochilus.common.util.codec.jwt_lite.verify"

local exports = {}

exports.on_rewrite = function(ngx, ctx)
    return nil
end

local verify = function(ngx, ctx)
    local headers = ngx.req.get_headers()
    local secret_ref, secret = ctx.secret_ref, nil
    if secret_ref then
        local ref = headers[secret_ref]
        if "string" ~= type(ref) then return nil end
        for _, s in ipairs(ctx.secret) do
            local m = re_match(ref, s[1], "jo")
            if m then secret = s[2]; break end
        end
        if not secret then return nil end
    else
        secret = ctx.secret
    end

    local verifier = ctx.verifiers[secret]
    if not verifier then
        verifier = jwt_verify.new(ctx.algo, secret)
        ctx.verifiers[secret] = verifier
    end
    local jwt_str = headers[ctx.token_ref]
    if "string" ~= type(jwt_str) then return nil end
    return jwt_verify.verify(verifier, jwt_str)
end

exports.on_access = function(ngx, ctx, req_ctx)
    if verify(ngx, ctx) then return true end

    ngx.status = ctx.fail_code
    ngx.say(ctx.fail_body)
    return false, ctx.fail_code
end

return exports

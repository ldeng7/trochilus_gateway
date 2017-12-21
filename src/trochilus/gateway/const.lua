local exports = {}

exports.SHM_KEY = "gateway"
exports.NGX_VAR_KEY_PATH = "gateway_path"
exports.NGX_CTX_KEY_LOC = "gateway:loc"
exports.NGX_CTX_KEY_REQ_PLUGIN = "gateway:rp"

exports.HTTP_METHODS = {
    GET    = true,
    POST   = true,
    PUT    = true,
    DELETE = true,
    HEAD   = true
}

exports.PHASES = {"rewrite", "access", "balancer", "body_filter", "log"}

return exports

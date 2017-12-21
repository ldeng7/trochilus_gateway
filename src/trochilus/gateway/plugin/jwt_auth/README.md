Name
====

jwt_auth

JWT验签插件

Description
===========

在 `access` 阶段，读取请求头中的某个字段，对比其中的 HS256 或 HS512 签名和计算出的签名是否一致，不一致则中止请求。

只检查签名，暂不检查其中包含的用户信息；只支持 HS256 和 HS512

Synopsis
========

```yaml
locations:
  - plugins:
      jwt_auth:
        token_ref: Authorization
        algo: HS256
        secret:
          - ["Android", "111"]
          - ["[\\S]+", "222"]
        secret_ref: "User-Agent"
        fail_code: 401
```

Configuration
=============

* `token_ref` string: JWT token 的请求头 key

* `algo` string: 验签算法，`HS256` 或 `HS512`

* `secret` 验签密钥

  * string: 固定的验签密钥

  * array \[ \[ string, string \] \]: 列表的每一项为一个长度为 2 的列表，第 1 项为一个正则表达式，第 2 项为验签密钥。根据请求头中某个的值，该值能正则匹配第 1 项时，则使用对应的第 2 项作为验签密钥，都不匹配则验签失败。优先级为出现在列表中的顺序。

* `secret_ref` string: 当 `secret` 为一个 array 时，用于正则匹配的值的请求头 key

* `fail_code` int: 验签失败状态码，默认 `401`

* `fail_body` string: 验签失败响应体，默认 `{}`

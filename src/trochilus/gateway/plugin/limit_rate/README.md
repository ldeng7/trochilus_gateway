Name
====

limit_rate

限流插件

Description
===========

使用漏筒算法的流量限制。

在 `access` 阶段：计算流量并决定是否限流。

Synopsis
========

```yaml
locations:
  - plugins:
      limit_req:
        key: kk
        rate: 100
        burst: 200
        limit_code: 503
        limit_body: "{}"
```

Configuration
=============

* `key` string: 计数器的 key

* `rate` int: rate of the leaky bucket algorithm, per second, default 100

* `burst` int: burst of the leaky bucket algorithm, per second, default 200

* `limit_code` int: 限流输出状态码，默认 `503`

* `limit_body` string: 熔断输出响应体，默认 `{}`

* `args`, `args_delim` string: 参见 [limit_req](../limit_req#configuration)

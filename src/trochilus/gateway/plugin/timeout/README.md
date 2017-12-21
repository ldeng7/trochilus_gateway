Name
====

timeout

上游超时设置插件

Description
===========

在 `balancer` 阶段：设置超时，如果超时 nginx 会返回 `504`

Synopsis
========

```yaml
locations:
  - plugins:
      timeout:
        connect_timeout: 0.5
        send_timeout: 0.4
        read_timeout: 1
```

Configuration
=============

* `connect_timeout` int/float: 连接超时，单位秒，最小粒度 `0.001`，默认 `nil`，即使用 nginx 配置中 `proxy_connect_timeout` 指令设置的超时

* `send_timeout` int/float: 发送超时，单位秒，最小粒度 `0.001`，默认 `nil`，即使用 nginx 配置中 `proxy_send_timeout` 指令设置的超时

* `read_timeout` int/float: 接收超时，单位秒，最小粒度 `0.001`，默认 `nil`，即使用 nginx 配置中 `proxy_read_timeout` 指令设置的超时

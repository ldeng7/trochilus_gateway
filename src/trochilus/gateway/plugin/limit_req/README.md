Name
====

limit_req

限流插件

Description
===========

使用时间窗口的流量限制。

在 `access` 阶段：计数器不存在则开启一个时间窗口，在时间窗口内计数器加 1，达到阀值则开始限流，直到时间窗口结束，取消计数器。

Synopsis
========

```yaml
locations:
  - plugins:
      limit_req:
        key: kk
        interval: 10
        threshold: 5
        limit_code: 503
        limit_body: "{}"
        kafka_instance: k1
        kafka_topic: tt
```

Configuration
=============

* `key` string: 计数器的 key

* `interval` int: 时间窗口长度，单位秒，默认 `10`。特别的，`-1`：直到下一个自然分钟为止，`-2`：直到下一个自然小时为止

* `threshold` int: 请求数阀值，默认 `10`

* `limit_code` int: 限流输出状态码，默认 `503`

* `limit_body` string: 熔断输出响应体，默认 `{}`

* `kafka_instance` string: 发送事件消息，在总体配置的 `kafka.instances` 下配置的 Kafka 实例名称，默认 `nil`，即不发送

* `kafka_topic` string: 发往的 Kafka topic

发送的消息为一个 json 字符串，json decode 后为如下形式：

```javascript
{
    topic: "tt", // kafka topic
    type: "limit_req",
    timestamp: 1388888888,
    instance: {
        group_id: "gg",
        instance_id: "biz01:24800", // hostname:nginx master process id
        worker_id: 0, // nginx worker id
        worker_pid: 24801, // nginx worker process id
    }

    location_id: "tt", // 路由项中配置的 id
}
```

* `args` array \[ map \]: 计数器的 key 附带某些参数的值，实际使用的 key 除了 `key` 参数外同时还加上一或多个值，取值的顺序与出现在配置中的顺序一致，如果其中一项找不到则取值 `nil`

  * `header` string: 选取请求头的某个值

  * `uri_arg` string: 选取 uri 参数的某个值

  * `body_arg` string: 选取 uri 编码的请求体的某个值

  * `body_json` array \[ string \]: 选取 json 编码的请求体的某个值，必须是数值或字符串类型，否则视为找不到，如 `[ "user", "id" ]` 则选取 `decoded_body.user.id`

* `args_delim` string: 默认 `:`，key 的取值之间的分隔符，如对于请求：

```shell
curl -H "User-Agent: ua" "http://some_uri?a=1" -d "{user: {id: 3}}"
```

配置为：

```yaml
key: kk
args:
  - header: "User-Agent"
  - uri_arg: a
  - uri_arg: b
  - body_json: ["user", "id"]
args_delim: ":"
```

则最终使用的 key 为 `kk:a:1:nil:3`

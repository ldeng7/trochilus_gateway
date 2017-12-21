Name
====

kafka_log

发往 Kafka 的请求日志插件

Description
===========

在 `body_filter` 阶段：收集响应体

在 `log` 阶段：收集其它信息，异步累计的发往 Kafka

发送的消息为一个 json 字符串，json decode 后为如下形式：

```javascript
{
    topic: "tt", // kafka topic
    type: "req",
    datetime: "2017-07-07 22:40:07",
    node_name: "proj01",
    hostname: "biz01",

    req_remote_addr: "222.222.222.222",
    req_method: "POST",
    req_uri: "\/user",
    req_uri_query: "arg1=aa&arg2=bb",
    req_forwarded_for: "223.223.223.223",
    req_ua: "Shanzhai browser",
    req_id: "9a8ea32e3847fe28bfba3425a2225168",
    req_body: "param1=aa&param2=bb",

    upstream_addr: "10.10.10.10",
    upstream_dur: "0.001",
    upstream_status: "200",

    resp_status: 200,
    resp_dur: "0.001",
    resp_body_bytes: "14",
    resp_body: "{}\n"
}
```

Synopsis
========

```yaml
locations:
  - plugins:
      kafka_log:
        instance: k1
        topic: tt
        node_name: "test:test"
        collect_resp_body: true # true | false | [403, 502, 503]
```

Configuration
=============

* `instance` string: 在总体配置的 `kafka.instances` 下配置的 Kafka 实例名称

* `topic` string: 发往的 Kafka topic

* `node_name` string: 用户自定义的一个字符串，会包含在每条日志中，可将项目名称等放置其中

* `collect_resp_body` 是否在日志中包含响应体

  * boolean:

  * array \[ int \]: 当 status code 在集合中时才包含响应体

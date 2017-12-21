Name
====

kafka_stat

发往 Kafka 的统计日志插件

Description
===========

在 `log` 阶段：累计统计信息

在 `timer` 中：发往 Kafka

发送的消息为一个 json 字符串，json decode 后为如下形式：

```javascript
{
    topic: "tt", // kafka topic
    type: "stat",
    timestamp: 1388888888,
    instance: {
        group_id: "gg",
        instance_id: "biz01:24800", // hostname:nginx master process id
        worker_id: 0, // nginx worker id
        worker_pid: 24801, // nginx worker process id
    },

    location_id: "tt", // 路由项中配置的 id
    stat: {
        cnt: 3, // 请求数
        cnt_status: { // 分 status code 的请求数
            "200": 2,
            "500": 1,
        },
        dur_avg: 0.007 // 平均耗时，单位秒
    },
    consul: { // 如果使用服务发现
        peers: [ // 该服务当前使用的上游地址
            ["10.10.10.10", 8082],
            ["10.11.11.11", 8083]
        ],
        nodes: [ // 当前 consul 集群的节点地址
            "10.10.10.10",
            "10.11.11.11"
        ]
    }
}
```

Synopsis
========

```yaml
locations:
  - plugins:
      kafka_stat:
        instance: k1
        topic: tt
        period: 60
        consul_instance: d1
        consul_serv_name: proj01
```

Configuration
=============

* `instance` string: 在总体配置的 `kafka.instances` 下配置的 Kafka 实例名称

* `topic` string: 发往的 Kafka topic

* `period` int: 发送频率，单位秒，默认 `60`

* `consul_instance` string: 如果使用服务发现，在总体配置的 `consul.instances` 下配置的 Consul 实例名称

* `consul_serv_name` string: 如果使用服务发现，Consul 注册的服务名

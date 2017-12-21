Name
====

discovery

上游服务发现插件

Description
===========

基于 [Consul](https://www.consul.io/docs/index.html) 的服务发现，本地必须加入一个 Consul 集群并使用 Consul 提供本地 DNS 服务的默认端口。

在 `balancer` 阶段，周期性读取本地 DNS 提供的服务发现数据，即一个 IP 和 端口的二元组的集合，并轮询地使用该集合中的一项作为 Nginx proxy pass 的上游 IP 和 端口。

Synopsis
========

```nginx
http {
    upstream ups {
        balancer_by_lua_block {
            gateway.on_balancer(ngx)
        }
        server 0.0.0.1;
    }
}
```

```yaml
locations:
  - plugins:
      discovery:
        instance: d1
        serv_name: proj01
```

Configuration
=============

### Nginx 配置

* `server` 不应再将 `server` 指令的地址写死，而是使用一条占位指令 `server 0.0.0.1;`

### Lua 配置

注意：对于同一个 Nignx 配置中的 `upstream` 项，可以对应到不同的 Lua 配置中的 `location` 项，亦即可以同一个 `upstream` 项中使用到不同的 Consul 服务名

* `instance` string: 在总体配置的 `consul.instances` 下配置的 Consul 实例名称

* `serv_name` string: Consul 注册的服务名

References
==========

### Consul 部署

例如我们有两台机器：biz01(10.33.33.1) 和 biz02(10.33.33.2)，用这两台建立一个最初的集群。

分别在 biz01 和 biz02 上启动 Consul agent，其中，两个节点都是 server 节点，要求集群至少有 2 个节点，biz02 加入到 biz01，启动时读取 `config-dir` 目录下的配置进行最初的服务注册：

```shell
# on biz01
./consul agent -server -node=biz01 -bootstrap-expect=2 -bind=10.33.33.1 -data-dir=/tmp/consul -config-dir=/etc/consul.d
# on biz02
./consul agent -server -node=biz02 -bootstrap-expect=2 -bind=10.33.33.2 -join=10.33.33.1 -data-dir=/tmp/consul -config-dir=/etc/consul.d
```

其它节点想要加入这个集群可同样加入到 biz01： `-join=10.33.33.1`，去掉参数 `-server` 即为 client 节点

### 服务注册

#### Agent 启动时注册

例如在 biz01 的 `config-dir` 目录下的服务注册配置文件如 `service-proj01.json`：
```
{
    "services": [
        {
            "name": "proj01",
            "id": "proj01_biz01",
            "tags": ["biz01"],
            "address": "127.0.0.1",
            "port": 8080,
            "checks": [
                {
                    "http": "http://127.0.0.1:8080/health",
                    "interval": "10s"
                }
            ]
        }
    ]
}
```

#### API 注册

例如在 biz01 启动的 agent 会在本地的默认 8500 端口提供 HTTP API

```shell
curl "http://127.0.0.1:8500/v1/agent/service/register" -X PUT \
    -d '{"Name": "proj01", "ID": "proj01_biz01", "Tags": ["biz01"], "Address": "127.0.0.1", "Port": 8080, "Check": {"HTTP": "http://127.0.0.1:8080/health", "Interval": "10s"}}'
```

### 服务发现

例如在 biz01 启动的 agent 会在本地的默认 8600 端口提供 DNS

```shell
dig @127.0.0.1 -p 8600 proj01.service.consul SRV
```


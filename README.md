Name
====

trochilus_gateway

本项目基于 Openresty 来实现一个 API 网关。

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Version](#version)
* [Description](#description)
* [Synopsis](#synopsis)
* [Dependencies](#dependencies)
* [Deployment](#deployment)
* [Configuration](#configuration)
* [Plugins](#plugins)

Status
======

Developing.

Version
=======

v0.1.0

Description
===========

本项目是一个 Lua 库，提供给 Openresty Nginx 调用。本库提供了在 **Nginx 处理一个 HTTP 请求的各阶段** 相应的启用 API 网关的 hook 方法。网关的具体功能均以插件形式提供，各插件的开关与配置需放在一个配置文件中，可对不同的请求路径分别进行不同的配置。详见 [Configuration](#configuration)

本库在 Nginx 启动阶段 `init_worker` 读取配置并初始化各插件，在处理请求的 `rewrite` 阶段进行路由，选择所使用的配置，在后续若干阶段执行各插件的功能。

Openresty Nginx 阶段时序图：
![Lua Nginx Modules Directives](https://cloud.githubusercontent.com/assets/2137369/15272097/77d1c09e-1a37-11e6-97ef-d9767035fc3e.png)

[Back to TOC](#table-of-contents)

Synopsis
========
```nginx
# nginx.conf

worker_processes auto;
env OPRPATH;
error_log /data/openresty/trochilus_gateway/logs/error.log error;
events {
    worker_connections 65535;
}
http {
    client_body_buffer_size 8m;
    client_max_body_size 8m;
    lua_code_cache on;
    lua_shared_dict gateway 64m;
    lua_package_path "/data/openresty/trochilus_common/src/?.lua;/data/openresty/trochilus_gateway/trochilus_gateway/src/?.lua;;";
    log_format cus '[$time_iso8601] $body_bytes_sent "$request" $status $request_time';
    access_log /data/openresty/trochilus_gateway/logs/access.log cus;

    init_worker_by_lua_block {
        gateway = require("trochilus.gateway.gateway")
        gateway.on_init_worker(ngx, {yaml = "/data/openresty/trochilus_gateway/trochilus_gateway/src/config/gateway.yml"})
    }
    rewrite_by_lua_block {
        gateway.on_rewrite(ngx)
    }
    access_by_lua_block {
        gateway.on_access(ngx)
    }
    body_filter_by_lua_block {
        gateway.on_body_filter(ngx)
    }
    log_by_lua_block {
        gateway.on_log(ngx)
    }
    upstream consul {
        balancer_by_lua_block {
            gateway.on_balancer(ngx)
        }
        server 0.0.0.1;
    }

    server {
        listen 8081;
        location / {
            set $gateway_path "path1";
            proxy_pass http://consul;
        }
    }
}
```

```yaml
# gateway.yml

group_id: gg
locations:
  - id: loc1
    path: path1
    method: GET
    plugins:
      some_plugin:
        some_conf_key: ""
kafka:
  instances:
    - key: k1
      refresh_interval: 10000
      broker_list:
        - host: "127.0.0.1"
          port: 6667
          name: "kafka.test.com"
  fallback:
    host: "127.0.0.1"
    port: 514
    ali_ver: "2.0"
    ali_tag: mytag
consul:
  instances:
    - key: d1
      dns_period: 10
```

[Back to TOC](#table-of-contents)

Dependencies
============

* Linux 64-bit

* Openresty >= 1.11.2.2

* Kakfa 服务端（如果配置为需要）

* Consul agent（如果配置为需要）

* [trochilus_common](https://github.com/ldeng7/trochilus_common)

[Back to TOC](#table-of-contents)

Deployment
==========

* 下载、编译、安装 Openresty

* 下载 Lua 项目，目录如 `/data/openresty`

```shell
cd /data/openresty/
git clone git@github.com:ldeng7/trochilus_common.git
mkdir -p trochilus_gateway/logs
cd trochilus_gateway
git clone git@github.com:ldeng7/trochilus_gateway.git
```

* 编辑配置文件

  所有配置文件可放在 `/data/openresty/trochilus_gateway/trochilus_gateway/src/config/` 目录下

  * Nginx 配置 `nginx.conf`

  * 网关配置，使用 yaml，名称随意，在 `nginx.conf` 中指定正确就行。Yaml 中可以使用 `!env XXX` 来引用环境变量

* 启动 Nginx

  启动命令为：

```
/usr/local/openresty/nginx/sbin/nginx -p /data/openresty/trochilus_gateway -c trochilus_gateway/src/config/nginx.conf
```

[Back to TOC](#table-of-contents)

Configuration
=============

### Nginx 配置

* `env` 使用环境变量 `OPRPATH`

* `lua_code_cache` 必须为 `on`

* `lua_shared_dict` 必须为 `trochilus_gateway`，用于部分插件的进程间通信

* `lua_package_path` 参照 [Synopsis](#synopsis)，引入 Lua 项目的路径

* `init_worker_by_lua_block` 参照 [Synopsis](#synopsis)，必须放在 `http` 域

* `rewrite_by_lua_block`, `access_by_lua_block`, `body_filter_by_lua_block`, `log_by_lua_block` 参照 [Synopsis](#synopsis)，可放在 `http` 或 `server` 域使其所有子域都激活此网关；也可以放在 `location` 域使仅部分 location 激活

* `balancer_by_lua_block` 参照 [Synopsis](#synopsis)，必须放在 `upstream` 域

### 网关配置

#### 总体配置

* `group_id` string: 一个网关配置的总体标识

#### `locations` 路由、插件配置

* `id` string: 路由项的 ID

* `path` string: 在 Nginx 配置中使用 `set` 指令设置的变量 `gateway_path`，其值将与该值进行匹配以进行路由

* `method` string: 在路由项中限定 HTTP method，支持 `GET`, `POST`, `PUT`, `DELETE`, `HEAD`，必须大写，默认为 `nil`，即不限制

  `path` 和 `method` 两个参数完全确定一项路由

  可以同时存在 `path` 相同而 `method` 不同的路由项，此时的优先级：限制为某个 method > 不限制。例如配置两个路由项：


```yaml
- id: loc1
  path: path1
  method: GET
- id: loc2
  path: path1
```

  则 GET 请求会路由到 `loc1`，而其它 method 的请求会路由到 `loc2`

* `plugins` map: 每个路由配置的插件集合，其中的键为插件的名称，每个插件的具体配置参数详见每个插件的文档

#### `kafka` 配置

* `instances` array:

  * `key` string: 一个 Kafka 实例的名称，在其它需要使用 Kafka 的配置中使用这个名称来引用一个实例

  * `refresh_interval` int: metadata 刷新间隔，单位毫秒，默认 `nil`，即不刷新

  * `broker_list` array: Kafka 实例的 broker list

    * `host` string: 填 IP，否则如果填的是域名，则必须在 Nginx 配置中使用 `resolver` 指令为 Nginx 配置 DNS，且保证域名可用

    * `port` int: 端口

    * `name` string: 如果 `host` 填的是域名，则忽略此项；否则，可把域名填在这里，此时会实际使用在 `host` 中填的 IP，而域名可以不可用

* `fallback` map: 可选，配置此项后 Kafka 发送失败会使用 syslog 协议发送

  * `host` string:

  * `port` int:

  * `sock_type` string: `tcp` or `udp`，默认 `tcp`

  * `ali_ver` string:

  * `ali_tag` string:

#### `consul` 配置

* `instances` array \[ map \]:

  * `key` string: 一个 Consul 实例的名称，在其它需要使用 Consul 的配置中使用这个名称来引用一个实例

  * `host` string: 访问 Consul 服务的 host，默认 `127.0.0.1`

  * `dns_port` int: Consul DNS 的端口，默认 `8600`

  * `dns_timeout` int: Consul DNS 的超时，单位毫秒，默认 `500`

  * `dns_period` int: DNS 更新周期，单位秒，默认 `60`

  * `api_port` int: Consul API 的端口，默认 `8500`

  * `api_timeout` int: Consul API 的超时，单位毫秒，默认 `500`

[Back to TOC](#table-of-contents)

Plugins
=======

* [discovery](./src/trochilus/gateway/plugin/discovery)
* [fuse](./src/trochilus/gateway/plugin/fuse)
* [jwt_auth](./src/trochilus/gateway/plugin/jwt_auth)
* [kafka_log](./src/trochilus/gateway/plugin/kafka_log)
* [kafka_stat](./src/trochilus/gateway/plugin/kafka_stat)
* [limit_rate](./src/trochilus/gateway/plugin/limit_rate)
* [limit_req](./src/trochilus/gateway/plugin/limit_req)
* [timeout](./src/trochilus/gateway/plugin/timeout)
* [x_req_id](./src/trochilus/gateway/plugin/x_req_id)

[Back to TOC](#table-of-contents)

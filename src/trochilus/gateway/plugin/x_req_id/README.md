Name
====

x_req_id

添加 `X-Request-ID` 请求头插件

Description
===========

在 `rewrite` 阶段：检查请求头是否包含 `X-Request-ID`，不包含则添加，值为 32 位 16 进制，a ~ f 小写字符串

Synopsis
========

```yaml
locations:
  - plugins:
      x_req_id: {}
```

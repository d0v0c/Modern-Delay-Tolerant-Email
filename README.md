# 延迟容忍网络（DTN）邮件仿真测试

> 项目概述：用 Docker Compose + ION-DTN 搭建邮件收发测试环境

- 部署 Postfix + Dovecot 邮件系统，用 tc/netem 模拟深空网络延迟。
- 用容器替代虚拟机以降低开销，并引入 tini 加速容器启停，实现秒级拓扑切换。
- 设计基于 socat 的网络代理方案，将 Thunderbird 客户端从 Docker 容器剥离至宿主机运行，有效避开容器内运行 GUI 程序的兼容性难题。
- 使用 tcpdump/Wireshark 抓包分析，验证设计延迟与实际观测延迟的一致性。

## Lauch the program

```bash
cd Code/
docker compose up -d --build
```


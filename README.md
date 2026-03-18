# skynet.sh
天网 V9.6 终极部署脚本
# 🛡️ 天网系统 (Skynet) V9.6 终极真理版

> 专为纯 IPv6 VPS（如 HAX、Woiden）打造的【工业级高可用双栈代理架构】。
> 基于 Psiphon 底层协议与 Sing-box 核心路由，辅以 WARP-GO 强力赋能，实现全自动断线寻回与极品 IP 绝对锁定。

---

---

## 🚀 部署指南

### 1. 环境准备 (安装 curl)
如果你使用的是刚刚重置的纯净白板 VPS（例如全新 Debian/Ubuntu 系统），可能连最基础的下载工具都没有。请先执行以下命令安装 `curl`：

```bash
apt-get update -y && apt-get install curl -y
确认你的机器已经可以正常连网后，直接复制并执行以下命令。系统将在 2 分钟内自动完成双栈赋能、核心编译、沙盒开辟与大盘组装：
apt-get update -y && apt-get install -y curl wget && curl -sSL "https://raw.githubusercontent.com/tkzjwxx/skynet.sh/main/install.sh" | bash
核心操作手册
系统部署完毕后，你可以在任意终端位置直接敲击以下快捷指令：

ss：打开实时全息监控大盘（按 Ctrl+C 退出）。

c 或 myip：静态查看一次大盘状态。

s1 / s2 / s3：介入对应战区沙盒，执行【安全抽卡】（单抽/连抽/切国家）。

l1 / l2 / l3：介入对应战区沙盒，执行【狂暴死磕】（强行锁定指定 IP）。

s4：唤醒幽灵斥候旁路，执行深海打捞与黑名单管理。
💀 核弹级一键物理卸载
如果你想将 VPS 恢复到装机前的“白璧无瑕”状态，且不想重装系统。请直接复制以下整段“物理超度”指令。它将瞬间斩杀所有气闸、沙盒、哨兵进程，并销毁所有配置文件与 WARP：
echo -e "\033[1;31m💀 正在启动【天网系统】核弹级销毁程序...\033[0m" && systemctl stop w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 2>/dev/null && systemctl disable w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 2>/dev/null && rm -f /etc/systemd/system/w_master.service /etc/systemd/system/sing-box.service /etc/systemd/system/psiphon*.service && systemctl daemon-reload && pkill -9 -f psiphon-tunnel-core 2>/dev/null ; pkill -9 -f sing-box 2>/dev/null ; pkill -9 -f w_master 2>/dev/null ; pkill -9 -f sl 2>/dev/null && fuser -k -9 1081/tcp 1082/tcp 1083/tcp 2081/tcp 2082/tcp 2083/tcp 2084/tcp 8443/udp 8444/udp 8445/udp >/dev/null 2>&1 && rm -rf /etc/s-box && rm -f /usr/bin/s[1-4] /usr/bin/l[1-3] /usr/bin/sl[1-3] /usr/bin/w_master /usr/bin/myip /usr/bin/c /usr/bin/ss /root/install_skynet.sh && (crontab -l 2>/dev/null | grep -v "/sbin/reboot" | crontab -) && warp-go u >/dev/null 2>&1 && systemctl stop warp-go 2>/dev/null && rm -rf /usr/local/bin/warp-go && echo -e "\033[1;32m✅ 物理超度完毕！所有气闸、沙盒、哨兵、大盘已彻底焚毁。你的 VPS 现已恢复纯净白板状态！\033[0m"

# 🌐 Skynet Matrix V21 / 天网出站矩阵系统 V21

[English](#english) | [简体中文](#chinese)

---

<h2 id="english">🇺🇸 English</h2>

**Skynet V21** is a highly advanced, automated, and self-healing proxy matrix deployed via a single script. Tailored for pure IPv6 VPS (like Woiden, Hax), it integrates Cloudflare WARP, Sing-box, and multiple Psiphon nodes into a seamless ecosystem.

### ⚙️ Core Architecture
* **Foundation**: WARP-GO (IPv4 egress) + `gai.conf` patch (IPv6 lock-in prevention).
* **Forwarding Core**: Sing-box handles inbound Hysteria2 (native IPv6 direct connect) and VMess (for CF Argo Tunnel).
* **Outbound Matrix**: 4 independent Psiphon proxy instances (US, GB, JP, SG regions) running locally on ports 1081-1084.
* **Auto-Healing**: Includes a background watchdog (`w_master`) and chasing daemons (`sl`) to automatically detect dead IPs, recover connections, and restart routing gates.

### ⌨️ Interactive Command Center
Once installed, Skynet registers powerful single-letter/short commands globally:
* `c` / `ss` : Global Dashboard (Monitor IP targets, real-time status, and SLA logs).
* `v` : Generate node URLs (HY2 / VMess) and CF Argo Tunnel configuration guide.
* `s1` / `s2` / `s3` : **Safe Gacha Mode** for US/GB/JP nodes. Interactively fish for clean IPs.
* `l1` / `l2` / `l3` : **Berserk Mode**. Forcefully lock and retake a specific high-quality IP.
* `s4` : **Ghost Scout**. A dedicated node for deep-sea IP fishing and blacklisting bad IPs.
* `u` : Complete self-destruct and uninstall mechanism.

*(Note: Automatically reboots daily at 4:00 AM to flush memory and reset the SLA logs).*

### 🚀 Quick Install
```bash
bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh))
```
*(⚠️ Note: The script will pause and open the WARP menu. Please install WARP, verify you get an IPv4 address, and type `0` to exit the menu so the installation can complete!)*

---

<h2 id="chinese">🇨🇳 简体中文</h2>

**天网系统 V21** 是一套专为纯 IPv6 VPS（Woiden/HAX 等）打造的自动化、多节点、带强力自愈机制的代理矩阵生态。

突破传统单点脚本的极限，天网 V21 融合了 WARP 底层出站、Sing-box 分流引擎、以及四路独立的 Psiphon 战区，并配备了守护进程（哨兵），可实现节点断流全自动寻回。

### ⚙️ 核心系统架构
* **底层护盾**：WARP-GO（提供 IPv4） + wget/gai.conf 防卡死干预。
* **分流中枢**：Sing-box（接管入站），提供 Hysteria2（公网原生直连）与 VMess（本地端口，专供 Argo Tunnel 内网穿透映射）。
* **战区矩阵**：本地运行 4 个独立 Psiphon 引擎（对应 1081-1084 端口），分管 🇺🇸 US / 🇬🇧 GB / 🇯🇵 JP / 🇸🇬 SG 四大物理战区。
* **自愈闭环**：独创 `w_master` 后台主控哨兵与 `sl` 寻回猎犬，IP 漂移假死全自动斩断气闸、重新抽卡并恢复连接。

### ⌨️ 天网指挥部快捷键
部署完成后，系统注入了极其丰富的全局实战指令：
* `c` 或 `ss`：**全局大盘与实时监控**（上帝视角查看四路战区锁定 IP、健康度与存活时长）。
* `v`：**节点链接提取器**（一键生成 HY2/VMess 配置，内含极其详细的 CF Argo 映射指南）。
* `s1` / `s2` / `s3`：**战术安全抽卡**（呼出交互面板，进行极品 IP 单抽、鱼塘连抽，并动态切换国家战区）。
* `l1` / `l2` / `l3`：**狂暴死磕引擎**（输入指定的极品 IP，系统死咬目标强行夺回）。
* `s4`：**幽灵斥候旁路引擎**（独立于前三路的深海洗号池，支持恶意 IP 黑名单批量拦截机制）。
* `u`：**物理超度自毁程序**（清理一切痕迹还你纯净系统）。

*(💡 附加特性：系统注入了每日凌晨 4:00 自动重启任务，以重置状态和防爆休眠机制)*

### 🚀 创世重筑部署指令
请使用 `root` 权限登录纯 IPv6 机器执行：

```bash
bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh))
```
*(⚠️ 核心提示：脚本执行中途会挂起并唤出【勇哥 WARP 菜单】。请务必手动安装 WARP（推荐双栈），当屏幕提示成功获取 WARP IPv4 后，输入 `0` 退出菜单，天网主程序将自动接力完成全部闭环！)*

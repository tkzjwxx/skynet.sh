# 🌐 Skynet Matrix V21 / 天网出站矩阵系统 V21

[English](#english) | [简体中文](#chinese)

---

<h2 id="english">🇺🇸 English</h2>

**Skynet V21** is a highly advanced, automated proxy matrix tailored for pure IPv6 VPS (like Woiden, Hax). It integrates Cloudflare WARP, Sing-box, and multiple Psiphon nodes into a self-healing ecosystem, utilizing Cloudflare Argo Tunnels to bypass strict network blockades.

### ⚙️ Traffic Flow & Architecture
* **Inbound (Argo Tunnel -> Sing-box)**: Cloudflare forwards traffic to local VMess ports (`10001`, `10002`, `10003`).
* **Inbound (Direct IPv6)**: Sing-box also listens on `8443`, `8444`, `8445` for raw Hysteria2 direct connections.
* **Outbound Matrix (Sing-box -> Psiphon -> WARP)**: Traffic is routed to 3 independent Psiphon nodes (S1, S2, S3) running locally, which then exit to the internet via the WARP IPv4 network.

### 🚀 Step 1: Install Skynet V21
Run the following chained command as `root` on your pure IPv6 VPS. It will automatically install `curl` if missing and start the deployment:
```bash
apt-get update -y && apt-get install -y curl && bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh))
```
*(⚠️ Note: The script will pause and open the WARP menu. Please install WARP, verify you get an IPv4 address, and type `0` to exit the menu so the installation can complete.)*

### 🌩️ Step 2: Configure Cloudflare Argo Tunnel (CRITICAL)
For the VMess nodes to work, you **MUST** map the local Sing-box ports to your subdomains using Cloudflare Zero Trust:
1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/) -> **Networks** -> **Tunnels**.
2. Click **Create a tunnel** (Select Cloudflared) and name it (e.g., `Skynet`).
3. Copy the installation command provided by CF (`cloudflared service install eyJ...`) and run it in your VPS terminal.
4. Click **Next** and configure the **Public Hostnames** (Add 3 routes):
   * Route 1: `us.yourdomain.com` -> Service Type: `HTTP` -> URL: `localhost:10001`
   * Route 2: `uk.yourdomain.com` -> Service Type: `HTTP` -> URL: `localhost:10002`
   * Route 3: `jp.yourdomain.com` -> Service Type: `HTTP` -> URL: `localhost:10003`
5. Save the tunnel.

### ⌨️ Step 3: Global Commands
Type these shortcuts anywhere in your terminal:
* `v` : Generate your VMess/HY2 node links (Remember to replace the dummy domains in VMess links with the subdomains you just mapped in Step 2).
* `c` / `ss` : Open the live dashboard to monitor IPs and auto-healing status.
* `s1` / `s2` / `s3` : Enter the interactive IP Gacha mode to fish for clean Psiphon IPs.
* `l1` / `l2` / `l3` : Berserk Mode to force-lock a specific IP.

---

<h2 id="chinese">🇨🇳 简体中文</h2>

**天网系统 V21** 是一套专为纯 IPv6 VPS 打造的自动化代理矩阵生态。它通过底层 WARP 获取 IPv4 出口，配合 Sing-box 分流与四路独立的 Psiphon 战区，并强制绑定 Cloudflare Argo Tunnel（内网穿透），实现 IP 防封与节点自愈。

### ⚙️ 核心流量走向
* **入站 (Argo -> Sing-box)**：Cloudflare 边缘节点将流量通过隧道穿透至本机的 `10001`, `10002`, `10003` 端口 (VMess)。同时保留 `8443-8445` 端口供 Hysteria2 原生 IPv6 直连备用。
* **出站 (Sing-box -> Psiphon -> WARP)**：入站流量被分发至本机的 3 个独立 Psiphon 战区引擎 (S1/S2/S3)，最终通过 WARP 的 IPv4 隧道走向外网。

### 🚀 第一步：执行创世部署
请使用 `root` 权限登录纯 IPv6 机器执行以下链式指令（自带环境依赖补全，防止纯净系统报错）：
```bash
apt-get update -y && apt-get install -y curl && bash <(curl -sL [https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh](https://raw.githubusercontent.com/tkzjwxx/skynet-v21-ipv6/main/install.sh))
```
*(⚠️ 核心提示：执行中途会挂起并唤出【WARP 菜单】。请手动安装 WARP，当屏幕提示成功获取 WARP IPv4 后，输入 `0` 退出菜单，主程序将自动接力完成全量部署！)*

### 🌩️ 第二步：配置 CF Argo 隧道映射 (必做核心步骤)
如果不做这一步，你提取到的 VMess 节点将无法连接！部署完成后，请按照以下步骤打通隧道：
1. 登录 [Cloudflare Zero Trust 后台](https://one.dash.cloudflare.com/)，依次点击左侧菜单的 **Networks** -> **Tunnels**。
2. 点击 **Create a tunnel**（选择 Cloudflared），随便起个名字（比如 Skynet）。
3. 选择你的系统环境（Debian/Ubuntu 64-bit），**复制页面下方给出的长命令**（以 `cloudflared service install eyJ...` 开头），**直接粘贴到你的 VPS 终端里运行**。
4. 运行成功后点击页面右下角的 **Next**，来到 **Public Hostnames** 映射页面。你需要**添加 3 条记录**：
   * **子域名 1** (接管 S1 战区) -> Service Type 选 `HTTP` -> URL 填 `localhost:10001`
   * **子域名 2** (接管 S2 战区) -> Service Type 选 `HTTP` -> URL 填 `localhost:10002`
   * **子域名 3** (接管 S3 战区) -> Service Type 选 `HTTP` -> URL 填 `localhost:10003`
5. 全部添加完成后，保存隧道。此时你的机器已经成功与 Cloudflare 边缘节点硬连接！

### ⌨️ 第三步：使用全局指令提取节点与管理
此时，天网矩阵已彻底成型。请在终端直接输入以下单字母指令：
* `v`：**生成节点链接**（⚠️ 拿到 VMess 节点后，请将里面的“你的专属CF子域名”替换成你刚才在第二步映射的真实域名！）。
* `c` 或 `ss`：**全局大盘与实时监控**（上帝视角查看四路战区锁定 IP、健康度与存活时长）。
* `s1` / `s2` / `s3`：**战术安全抽卡**（呼出交互面板，进行极品 IP 单抽、鱼塘连抽，并动态切换国家战区）。
* `l1` / `l2` / `l3`：**狂暴死磕引擎**（输入指定的极品 IP，系统死咬目标强行夺回）。
* `s4`：**幽灵斥候旁路引擎**（独立深海洗号池，支持恶意 IP 黑名单批量拦截机制）。
* `u`：**物理超度自毁程序**（清理一切痕迹还你纯净系统）。

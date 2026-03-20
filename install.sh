#!/bin/bash
# ====================================================================
# 天网系统 V22 终极版 (绝对物理防泄露 + 双轨 SLA 监控 + 零死锁重构)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网 V22 终极防御版】全量创世重筑...\033[0m"

# 0. 强力拔除 HAX 废弃源
sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null

# 1. 清理旧环境 (保护 cloudflared)
systemctl stop psiphon1 psiphon2 psiphon3 psiphon4 sing-box w_master warp-go wg-quick@wgcf 2>/dev/null
killall -9 w_master 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/ss /usr/bin/u /usr/bin/v /usr/bin/s[1-4] /usr/bin/l[1-4] /usr/bin/sl[1-4] /usr/bin/c[1-4]

# 2. 基础依赖安装
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget socat net-tools psmisc jq unzip tar openssl cron nano >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

# ====================================================================
# 2.1 网络干预：仅针对 wget 开启 IPv6
# ====================================================================
echo "prefer-family = IPv6" > ~/.wgetrc
sed -i '/precedence ::ffff:0:0\/96  10/d' /etc/gai.conf 2>/dev/null
echo -e "\033[1;32m✅ 已配置 wget 的 IPv6 防卡死补丁\033[0m"

# ====================================================================
# 3. WARP 部署
# ====================================================================
echo -e "\033[1;32m🌐 第一阶段：正在拉取勇哥 WARP 引擎...\033[0m"

rm -f /root/CFwarp.sh
curl -sL -o /root/CFwarp.sh https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh
chmod +x /root/CFwarp.sh

echo -e "\n\033[1;45;37m ⏸️ 主脚本已挂起！即将唤出勇哥 WARP 菜单... \033[0m"
echo -e "\033[1;36m👉 请根据机器情况手动安装 (纯v6机建议装双栈 或 单栈IPv4)。\033[0m"
echo -e "\033[1;33m⚠️ 关键：安装成功并看到 WARP IP 后，请在菜单输入 0 退出！\033[0m"
sleep 5

bash /root/CFwarp.sh

echo -e "\n\033[1;32m▶️ WARP 菜单已关闭，天网主程序恢复执行！\033[0m"
echo -e "\033[1;33m⏳ 正在校验 WARP IPv4 连通性...\033[0m"
V4_READY=false
for i in {1..6}; do
    WARP_IP=$(curl -s4 -m 5 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    if [ -n "$WARP_IP" ]; then
        echo -e "\033[1;32m✅ WARP IPv4 获取成功！出站 IP: $WARP_IP\033[0m"
        V4_READY=true
        break
    else
        echo -e "\033[1;35m⚠️ 未检测到 IPv4，重试中...\033[0m"
        sleep 5
    fi
done

if [ "$V4_READY" = false ]; then
    echo -e "\n\033[1;41;37m 💀 致命错误：WARP 未获取到 IPv4！部署熔断。\033[0m"
    exit 1
fi

# ====================================================================
# 4. 打捞核心组件
# ====================================================================
echo -e "\033[1;33m📦 第二阶段：凭 IPv4 护盾拉取核心...\033[0m"
curl -sL -A "Mozilla/5.0" -o /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

echo -ne "正在请求 Sing-box 最新直链... "
S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)

if [[ -z "$S_URL" || "$S_URL" != *"github.com"* ]]; then
    S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
fi
curl -sL --connect-timeout 15 -A "Mozilla/5.0" -o /tmp/sbox.tar.gz "$S_URL"

if [ -s /tmp/sbox.tar.gz ] && tar -tzf /tmp/sbox.tar.gz >/dev/null 2>&1; then
    tar -xzf /tmp/sbox.tar.gz -C /tmp/ 2>/dev/null
    mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box 2>/dev/null
    chmod +x /etc/s-box/sing-box
else
    echo -e "\n\033[1;41;37m 💀 致命错误：Sing-box 解压失败！\033[0m"
    exit 1
fi

# ====================================================================
# 5. 配置核心路由与气闸
# ====================================================================
cat << 'CONFIG_EOF' > /etc/s-box/sing-box.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-in-1", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-2", "listen": "::", "listen_port": 8444, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-3", "listen": "::", "listen_port": 8445, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "vmess", "tag": "vmess-in-1", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s1"} },
    { "type": "vmess", "tag": "vmess-in-2", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s2"} },
    { "type": "vmess", "tag": "vmess-in-3", "listen": "127.0.0.1", "listen_port": 10003, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s3"} }
  ],
  "outbounds": [
    { "type": "socks", "tag": "out-s1", "server": "127.0.0.1", "server_port": 1081 },
    { "type": "socks", "tag": "out-s2", "server": "127.0.0.1", "server_port": 1082 },
    { "type": "socks", "tag": "out-s3", "server": "127.0.0.1", "server_port": 1083 }
  ],
  "route": {"rules": [ 
    {"inbound": ["hy2-in-1", "vmess-in-1"], "outbound": "out-s1"}, 
    {"inbound": ["hy2-in-2", "vmess-in-2"], "outbound": "out-s2"}, 
    {"inbound": ["hy2-in-3", "vmess-in-3"], "outbound": "out-s3"} 
  ]}
}
CONFIG_EOF
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null
cat > /etc/systemd/system/sing-box.service << 'SVC_EOF'
[Unit]
Description=Sing-box Service
After=network.target
[Service]
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
[Install]
WantedBy=multi-user.target
SVC_EOF
systemctl daemon-reload && systemctl enable --now sing-box >/dev/null 2>&1

# ====================================================================
# 6. 生成专属节点链接与隧道配置指南
# ====================================================================
cat << 'EOF' > /usr/bin/v
#!/bin/bash
IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || curl -s6 -m 5 icanhazip.com 2>/dev/null)
[ -z "$IP" ] && IP=$(ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
[ -z "$IP" ] && IP="[获取IPv6失败_请手动替换]"
UUID="d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a"
PW="PsiphonUS_2026"

clear
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;32m🎉 天网系统 V22 - 节点配置与 Cloudflare 隧道映射指南\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"

echo -e "\n\033[1;35m【第一部分】Cloudflare Zero Trust 网页端隧道配置参数\033[0m"
echo -e "请在 CF 隧道 (Tunnels) -> Public Hostname 建立 3 条映射记录："
echo -e "👉 \033[1;33m绑定的子域名 1\033[0m (接管 S1) -> Service Type: \033[1;37mHTTP\033[0m, URL: \033[1;32mlocalhost:10001\033[0m"
echo -e "👉 \033[1;33m绑定的子域名 2\033[0m (接管 S2) -> Service Type: \033[1;37mHTTP\033[0m, URL: \033[1;32mlocalhost:10002\033[0m"
echo -e "👉 \033[1;33m绑定的子域名 3\033[0m (接管 S3) -> Service Type: \033[1;37mHTTP\033[0m, URL: \033[1;32mlocalhost:10003\033[0m"

echo -e "\n\033[1;35m【第二部分】Argo 隧道 VMess 节点 (导入客户端后需替换域名)\033[0m"
gen_vmess() {
  local name=$1; local path=$2
  local json="{\"v\":\"2\",\"ps\":\"$name\",\"add\":\"你的专属CF子域名\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"你的专属CF子域名\",\"path\":\"$path\",\"tls\":\"tls\"}"
  echo "vmess://$(echo -n "$json" | base64 -w 0)"
}
echo -e "🇺🇸 S1 战区 (映射端口 10001, 路径 /s1): \n\033[0m$(gen_vmess "Skynet-CF-S1" "/s1")"
echo -e "\n🇬🇧 S2 战区 (映射端口 10002, 路径 /s2): \n\033[0m$(gen_vmess "Skynet-CF-S2" "/s2")"
echo -e "\n🇯🇵 S3 战区 (映射端口 10003, 路径 /s3): \n\033[0m$(gen_vmess "Skynet-CF-S3" "/s3")"

echo -e "\n\033[1;35m【第三部分】直连 Hysteria2 节点 (IPv6 原生直通保底)\033[0m"
echo -e "🇺🇸 S1 战区 (直连端口 8443): \n\033[0m hysteria2://$PW@[$IP]:8443/?sni=bing.com&insecure=1#Skynet-HY2-S1"
echo -e "\n🇬🇧 S2 战区 (直连端口 8444): \n\033[0m hysteria2://$PW@[$IP]:8444/?sni=bing.com&insecure=1#Skynet-HY2-S2"
echo -e "\n🇯🇵 S3 战区 (直连端口 8445): \n\033[0m hysteria2://$PW@[$IP]:8445/?sni=bing.com&insecure=1#Skynet-HY2-S3"
echo -e "\n\033[1;36m=================================================================\033[0m"
EOF
chmod +x /usr/bin/v

# 7. 初始化沙盒底层引擎
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN=2081; OUT=1081; DIR="/etc/s-box"; REG="US"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN=2082; OUT=1082; DIR="/etc/s-box/sub2"; REG="GB"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN=2083; OUT=1083; DIR="/etc/s-box/sub3"; REG="JP"; SVC="psiphon3"; }
    [ "$NODE" == "4" ] && { IN=2084; OUT=1084; DIR="/etc/s-box/sub4"; REG="SG"; SVC="psiphon4"; }
    
    cp /etc/s-box/psiphon-tunnel-core "$DIR/" 2>/dev/null
    cat > "$DIR/base.config" << P_EOF
{"LocalHttpProxyPort":$((IN+16000)),"LocalSocksProxyPort":$IN,"PropagationChannelId":"FFFFFFFFFFFFFFFF","SponsorId":"FFFFFFFFFFFFFFFF","EgressRegion": "$REG","DataRootDirectory":"$DIR","RemoteServerListDownloadFilename":"remote_server_list","RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=","RemoteServerListUrl":"https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed","UseIndistinguishableTLS":true}
P_EOF
    cat > /etc/systemd/system/${SVC}.service << SVC_EOF
[Unit]
Description=Psiphon $NODE
After=network.target
[Service]
WorkingDirectory=$DIR
ExecStart=$DIR/psiphon-tunnel-core -config base.config
Restart=always
[Install]
WantedBy=multi-user.target
SVC_EOF
    systemctl enable --now ${SVC} >/dev/null 2>&1
done

# ====================================================================
# 8. 独立战术引擎 (绝对熔断、双轨SLA、零死锁修复)
# ====================================================================
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; DIR="/etc/s-box"; REG="US"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; DIR="/etc/s-box/sub2"; REG="GB"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; DIR="/etc/s-box/sub3"; REG="JP"; SVC="psiphon3"; }
    
    cat << EOF > /usr/bin/c${NODE}
#!/bin/bash
> "\$DIR/tmp_pool.txt" 2>/dev/null
echo -e "✅ \033[1;32mS${NODE} 鱼塘历史遗留已擦除！\033[0m\n"
EOF
    chmod +x /usr/bin/c${NODE}

    # S 安全抽卡
    cat << EOF > /usr/bin/s${NODE}
#!/bin/bash
NODE="${NODE}"; IN_PORT="${IN_PORT}"; OUT_PORT="${OUT_PORT}"; DIR="${DIR}"; SVC="${SVC}"; SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")
# ⚠️ 绝对熔断：斩断气闸防泄露
fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
echo \$\$ > "\$DIR/s\${NODE}.manual"
echo "\$(date '+[%m-%d %H:%M:%S]') [🛑 人为] 主人介入 S\${NODE} 抽卡，已斩断对外气闸防泄露！" >> "\$SLA_LOG"
trap 'trap - EXIT; echo "\$(date "+[%m-%d %H:%M:%S]") [🔰 退出] S\${NODE} 退出人工模式" >> "\$SLA_LOG"; rm -f "\$DIR/s\${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT HUP QUIT
clear
echo -e "\033[1;36m╔══════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║  🐺 [S\${NODE}] 天网安全抽卡引擎 - 战区配置面板         ║\033[0m"
echo -e "\033[1;36m╚══════════════════════════════════════════════════════╝\033[0m"
OLD_LOCK=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null | tr -d '[:space:]')
echo -e "\033[1;33m🛡️  当前锁定 IP :\033[0m \033[1;32m\${OLD_LOCK:-未锁定}\033[0m\n"
echo -e "\033[1;37m▶ 第一步：选择目标国家战区\033[0m"
echo -e "  [1] 🇺🇸 美国  [2] 🇬🇧 英国  [3] 🇯🇵 日本  [4] 🇸🇬 新加坡"
echo -ne "\033[1;33m👉 编号 (默认${NODE}): \033[0m"; read r; case "\$r" in 1) TR="US";; 2) TR="GB";; 3) TR="JP";; 4) TR="SG";; *) TR="${REG}";; esac
sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"\$TR\"/g" \$DIR/base.config
echo -e "  \033[1;32m✅ 战区锁定: \$TR\033[0m\n\033[1;90m──────────────────────────────────────────────────────\033[0m"
echo -e "\033[1;37m▶ 第二步：选择行动模式\033[0m"
echo -e "  [1] 🎯 极品单抽    [2] 🎣 鱼塘连抽"
echo -ne "\033[1;33m👉 模式 (默认1): \033[0m"; read m
if [ "\$m" == "2" ]; then
    echo -ne "👉 连抽次数 (默认10): "; read c; [ -z "\$c" ] && c=10
    echo -e "\n\033[1;36m🌊 启动鱼塘打捞作业...\033[0m"
    for ((i=1; i<=c; i++)); do
        echo -ne "\r\033[K\033[1;36m⏳ [\$i/\$c]\033[0m 抽卡中..."
        systemctl stop "\$SVC" 2>/dev/null; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"; sleep 8
        API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 5 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if [ -z "\$IP" ]; then
            sleep 3
            API=\${APIS[\$RANDOM % \${#APIS[@]}]}
            IP=\$(curl -s4 -m 5 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        fi
        if [ -n "\$IP" ]; then
            echo "\$IP" >> "\$DIR/tmp_pool.txt"
            echo -e "\n  └─ \033[1;32m✔ 成功入网: \$IP\033[0m"
        else
            echo -e "\n  └─ \033[1;31m✖ 节点超时失效\033[0m"
        fi
    done
    echo -e "\n\n\033[1;32m📊 鱼塘打捞结果:\033[0m"; sort "\$DIR/tmp_pool.txt" 2>/dev/null | uniq -c | sort -nr; rm -f "\$DIR/tmp_pool.txt"
else
    while true; do
        systemctl stop "\$SVC" 2>/dev/null; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
        echo -ne "\r\033[K\033[1;36m⏳ 正在盲抽...\033[0m"; sleep 8
        API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 5 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if [ -z "\$IP" ]; then
            sleep 3
            API=\${APIS[\$RANDOM % \${#APIS[@]}]}
            IP=\$(curl -s4 -m 5 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        fi
        [ -z "\$IP" ] && continue
        echo -e "\n\033[1;32m🎯 命中 IP: \033[1;37m\$IP\033[0m"
        echo -ne "\033[1;33m✨ 满意按 [Y] 锁定并开启气闸，按回车重抽: \033[0m"; read k
        if [[ "\$k" == "y" || "\$k" == "Y" ]]; then
            # 更新双重SLA探针
            echo "\$IP" > "\$DIR/s\${NODE}.lock"
            date +%s > "\$DIR/s\${NODE}.uptime"
            date +%s > "\$DIR/s\${NODE}.session"
            rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null
            echo -e "\033[1;32m✅ 极品已挂锁！监控引擎已同步。\033[0m\n"; break
        fi
    done
fi
EOF
    chmod +x /usr/bin/s${NODE}

    # L 狂暴死磕
    cat << EOF > /usr/bin/l${NODE}
#!/bin/bash
NODE="${NODE}"; IN_PORT="${IN_PORT}"; OUT_PORT="${OUT_PORT}"; DIR="${DIR}"; SVC="${SVC}"; SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")
# ⚠️ 绝对熔断：防止泄露
fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
echo \$\$ > "\$DIR/s\${NODE}.manual"
echo "\$(date '+[%m-%d %H:%M:%S]') [🛑 人为] 主人介入 L\${NODE} 死磕，已斩断气闸防泄露！" >> "\$SLA_LOG"
trap 'trap - EXIT; echo "\$(date "+[%m-%d %H:%M:%S]") [🔰 退出] S\${NODE} 退出人工模式" >> "\$SLA_LOG"; rm -f "\$DIR/s\${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT HUP QUIT
clear
echo -e "\033[1;35m╔══════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;35m║   🐺 [L\${NODE}] 狂暴死磕引擎 - 极品 IP 强制夺回        ║\033[0m"
echo -e "\033[1;35m╚══════════════════════════════════════════════════════╝\033[0m"
CUR_REG=\$(grep -oP '"EgressRegion"\s*:\s*"\K[A-Z]+' \$DIR/base.config 2>/dev/null || echo "US")
TARGET=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null)
echo -e "\033[1;33m🎯 当前死磕目标: \033[1;37m\${TARGET:-未设定} \033[1;36m(当前战区: \$CUR_REG)\033[0m"
echo -ne "\033[1;32m👉 输入新IP (直接回车则按原计划死磕): \033[0m"; read i
if [ -n "\$i" ]; then
    TARGET="\$i"
    echo "\$TARGET" > "\$DIR/s\${NODE}.lock"
    # 若重设目标，清空旧探针
    date +%s > "\$DIR/s\${NODE}.uptime"
    date +%s > "\$DIR/s\${NODE}.session"
    echo -e "  [1] 🇺🇸 US  [2] 🇬🇧 GB  [3] 🇯🇵 JP  [4] 🇸🇬 SG"
    echo -ne "👉 \033[1;33m请为新 IP 匹配战区 (默认保持 \$CUR_REG): \033[0m"; read r
    case "\$r" in 1) TR="US";; 2) TR="GB";; 3) TR="JP";; 4) TR="SG";; *) TR="\$CUR_REG";; esac
    sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"\$TR\"/g" \$DIR/base.config
    echo -e "  \033[1;32m✅ 新目标锁定，底层战区已同步更新为: \$TR\033[0m"
fi
echo -e "\033[1;90m──────────────────────────────────────────────────────\033[0m\n"
while true; do
    ((a++)); echo -ne "\r\033[K\033[1;35m⏳ [第 \$a 次]\033[0m 字节级强行夺回中..."
    systemctl stop "\$SVC" 2>/dev/null; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
    IP=""
    for i in {1..5}; do
        sleep 3
        API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 3 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "\$IP" ] && break
    done
    if [ "\$IP" == "\$TARGET" ]; then
        # ⚠️ 修复盲区：人工死磕成功后，必须更新 Session 连续时间，并即刻开启气闸
        date +%s > "\$DIR/s\${NODE}.session"
        rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null
        fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
        socat TCP4-LISTEN:\$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:\$IN_PORT &
        echo -e "\n\n\033[1;32m██████████████████████████████████████████████████████\033[0m"
        echo -e "\033[1;32m█                                                    █\033[0m"
        echo -e "\033[1;32m█   🎉 命中目标！死磕成功，监控大盘已同步！          █\033[0m"
        echo -e "\033[1;32m█   🌟 极品 IP: \033[1;37m%-36s\033[1;32m █\033[0m" "\$IP"
        echo -e "\033[1;32m█                                                    █\033[0m"
        echo -e "\033[1;32m██████████████████████████████████████████████████████\033[0m\n"
        exit 0
    fi
done
EOF
    chmod +x /usr/bin/l${NODE}

    # SL 寻回复苏
    cat << EOF > /usr/bin/sl${NODE}
#!/bin/bash
NODE="${NODE}"; IN_PORT="${IN_PORT}"; OUT_PORT="${OUT_PORT}"; DIR="${DIR}"; SVC="${SVC}"; SLA_LOG="/etc/s-box/stability.log"
TARGET=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null); [ -z "\$TARGET" ] && exit 0
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")
ATTEMPTS=0; CHASE_START=\$(date +%s)
echo "\$(date '+[%m-%d %H:%M:%S]') [🕵️ 寻回] S\${NODE} 启动高频洗牌盲抽，目标：\$TARGET" >> "\$SLA_LOG"
while true; do
    ((ATTEMPTS++))
    if [ -f "\$DIR/s\${NODE}.manual" ]; then exit 0; fi
    if [ \$((\$(date +%s) - CHASE_START)) -ge 1200 ]; then
        echo "\$(date '+[%m-%d %H:%M:%S]') [🌙 休眠] S\${NODE} 追捕20分钟无果，防爆休眠开启！" >> "\$SLA_LOG"
        touch "\$DIR/s\${NODE}.hibernating"; systemctl stop "\$SVC" 2>/dev/null; exit 0
    fi
    systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
    IP=""
    for i in {1..5}; do
        sleep 3
        API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 3 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "\$IP" ] && break
    done
    if [ "\$IP" == "\$TARGET" ]; then
        rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null
        COST=\$((\$(date +%s) - CHASE_START))
        echo "\$(date '+[%m-%d %H:%M:%S]') [🟢 恢复] S\${NODE} 耗时 \$COST 秒，洗牌 \$ATTEMPTS 次后复苏目标：\$IP" >> "\$SLA_LOG"
        fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
        socat TCP4-LISTEN:\$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:\$IN_PORT &
        [ ! -f "\$DIR/s\${NODE}.session" ] && date +%s > "\$DIR/s\${NODE}.session"
        exit 0
    fi
done
EOF
    chmod +x /usr/bin/sl${NODE}
done

# 写入旁路 S4
cat << 'EOF' > /usr/bin/s4
#!/bin/bash
DIR="/etc/s-box/sub4"; BLACKLIST_FILE="/etc/s-box/blacklist/bad_ips.txt"; SVC="psiphon4"; IN_PORT=2084
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com"); touch "$BLACKLIST_FILE"
trap 'echo -e "\n\033[1;33m🛑 已中止 S4 操作。\033[0m"; exit 0' INT TERM EXIT HUP QUIT

clear; echo -e "\033[1;36m   👻 [S4] 幽灵斥候 - 旁路洗号引擎 \033[0m\n   当前黑名单拦截库: $(wc -l < $BLACKLIST_FILE 2>/dev/null || echo 0) 条\n"
echo -e "  \033[1;32m[1] 🌊 启动深海打捞\033[0m      \033[1;33m[2] 📥 批量导入黑名单\033[0m"
echo -e "  \033[1;34m[3] 📜 查看当前黑名单\033[0m   \033[1;31m[4] 🗑️ 清空全部黑名单\033[0m"
echo -e "  \033[1;37m[0] 🚪 退出\033[0m"
read -p "👉 请选择 (默认 1): " MENU_CHOICE; [ -z "$MENU_CHOICE" ] && MENU_CHOICE=1

if [ "$MENU_CHOICE" == "0" ]; then exit 0
elif [ "$MENU_CHOICE" == "3" ]; then echo -e "\n\033[1;36m📜 现存黑名单 IP 列表:\033[0m"; if [ -s "$BLACKLIST_FILE" ]; then cat "$BLACKLIST_FILE" | column; else echo -e "\033[1;90m(当前黑名单为空)\033[0m"; fi; echo -e "\n\033[1;32m✅ 查看完毕！\033[0m"; exit 0
elif [ "$MENU_CHOICE" == "4" ]; then > "$BLACKLIST_FILE"; echo -e "\n\033[1;31m💥 轰！所有黑名单数据已被彻底清空！\033[0m"; exit 0
elif [ "$MENU_CHOICE" == "2" ]; then echo -e "\033[1;36m💡 输入 nano 进入高级编辑模式，或直接粘贴 IP！\033[0m"; read -p "输入 (回车退出): " INPUT_DATA; if [ "$INPUT_DATA" == "nano" ]; then nano "$BLACKLIST_FILE"; else for BAD_IP in $INPUT_DATA; do echo "$BAD_IP" >> "$BLACKLIST_FILE"; done; fi; exit 0
elif [ "$MENU_CHOICE" == "1" ]; then
    echo "  [1] 🇺🇸 美国 (US)   [2] 🇬🇧 英国 (GB)   [3] 🇯🇵 日本 (JP)"; read -p "战区 (默认 1): " REG_CHOICE
    [ "$REG_CHOICE" == "1" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"US\"/g" $DIR/base.config
    [ "$REG_CHOICE" == "2" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"GB\"/g" $DIR/base.config
    [ "$REG_CHOICE" == "3" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"JP\"/g" $DIR/base.config
    read -p "打捞次数 (默认 20): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=20
    ATTEMPTS=0; VALID_IPS=()
    echo -e "\n\033[1;36m🌊 启动幽灵侦查作业...\033[0m"
    while [ $ATTEMPTS -lt $SCAN_MAX ]; do
        ((ATTEMPTS++)); echo -ne "\r\033[K🔍 [$ATTEMPTS/$SCAN_MAX] 下网..."
        systemctl stop "$SVC" >/dev/null 2>&1; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* >/dev/null 2>&1; systemctl start "$SVC"; sleep 8
        API=${APIS[$RANDOM % ${#APIS[@]}]}
        IP=$(curl -s4 -m 5 --socks5 127.0.0.1:$IN_PORT $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if [ -z "$IP" ]; then sleep 2; API=${APIS[$RANDOM % ${#APIS[@]}]}; IP=$(curl -s4 -m 5 --socks5 127.0.0.1:$IN_PORT $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1); fi
        if [ -n "$IP" ]; then
            # ⚠️ 修复漏洞：精准封杀单IP，绝不错杀C段
            if grep -q "^${IP}$" "$BLACKLIST_FILE" 2>/dev/null; then echo -e "\n  ├─ 🚫 触发黑名单: $IP"; else echo -e "\n  └─ 🌟 捕获纯净极品: \033[1;32m$IP\033[0m"; VALID_IPS+=("$IP"); fi
        else echo -e "\n  ├─ \033[1;31m❌ 节点寻路超时，拉网失败\033[0m"; fi
    done
    echo -e "\n\033[1;33m📊 打捞过滤后获得 ${#VALID_IPS[@]} 个极品。\033[0m"
    if [ ${#VALID_IPS[@]} -gt 0 ]; then
        printf "%s\n" "${VALID_IPS[@]}" | sort -V | uniq -c | sort -nr
        echo "  [1] 全部绞杀 (打入黑名单)   [0] 留着备用 (退出)"; read -p "请裁决: " EXEC_CHOICE
        if [ "$EXEC_CHOICE" == "1" ]; then printf "%s\n" "${VALID_IPS[@]}" | sort -u >> "$BLACKLIST_FILE"; echo -e "\033[1;32m✅ 已送入黑名单。\033[0m"; fi
    fi
fi
trap - EXIT
EOF
chmod +x /usr/bin/s4

# ====================================================================
# 9. 全局大盘与后台守卫引擎 (双轨 SLA 界面重塑)
# ====================================================================
cat << 'EOF' > /usr/bin/c
#!/bin/bash
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")
draw_dashboard() {
    clear
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
    echo -e "\033[1;37m                                   🛡️ 天网系统 V22 (零泄露防线·双轨SLA监控) 🛡️\033[0m"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
    printf "%-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\n" "通道" "战区" "锁定目标 IP" "当前真实 IP" "对外气闸" "总存活" "未漂移" "健康状态及行动指示"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    for N in 1 2 3; do
        [ "$N" == "1" ] && { IN=2081; OUT=1081; W="/etc/s-box"; R="S1"; }
        [ "$N" == "2" ] && { IN=2082; OUT=1082; W="/etc/s-box/sub2"; R="S2"; }
        [ "$N" == "3" ] && { IN=2083; OUT=1083; W="/etc/s-box/sub3"; R="S3"; }
        REG=$(grep -oP '"EgressRegion"\s*:\s*"\K[A-Z]+' $W/base.config 2>/dev/null || echo "US")
        TAR=$(cat "$W/s$N.lock" 2>/dev/null)
        API=${APIS[$RANDOM % ${#APIS[@]}]}
        CUR=$(curl -s4 -m 4 --socks5 127.0.0.1:$IN $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if netstat -tlnp 2>/dev/null | grep -q ":$OUT "; then G_R="🟢开启"; else G_R="🔴截断"; fi
        
        UP_TOT="--:--:--"; UP_SES="--:--:--"
        NW=$(date +%s)
        if [ -n "$TAR" ]; then
            if [ -f "$W/s$N.uptime" ]; then ST_TOT=$(cat "$W/s$N.uptime" 2>/dev/null); DF=$((NW - ST_TOT)); [ $DF -gt 0 ] && UP_TOT=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
            if [ -f "$W/s$N.session" ]; then ST_SES=$(cat "$W/s$N.session" 2>/dev/null); DF=$((NW - ST_SES)); [ $DF -gt 0 ] && UP_SES=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        fi

        if [ -f "$W/s$N.manual" ]; then C="\033[1;35m"; G="🛑挂起"; S="🛑 人工调优防泄露中"; elif [ -z "$CUR" ]; then C="\033[1;33m"; G="🔴截断"; S="🟡 假死网络断流中"; elif [ "$CUR" == "$TAR" ]; then C="\033[1;32m"; G="🟢开启"; S="✅ 稳定零泄漏"; else C="\033[1;31m"; G="🔴截断"; S="🚨 IP漂移！夺回中"; fi
        printf "${C}%-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\033[0m\n" "$R" "$REG" "$TAR" "${CUR:-空}" "$G_R" "$UP_TOT" "$UP_SES" "$S"
    done
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
    echo -e "\033[1;37m                                   📋 任务史记 (过滤系统杂音，展示核心动态)                               \033[0m"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
}
TODAY=$(date '+%m-%d')
if [[ "$1" == "--live" ]]; then
    while true; do draw_dashboard; grep "^\[$TODAY" /etc/s-box/stability.log | tail -n 25; echo -e "\033[1;90m\n[提示] 正在实时监控中... 按 Ctrl+C 退出\033[0m"; sleep 2; done
else
    draw_dashboard; LOG_CONTENT=$(grep "^\[$TODAY" /etc/s-box/stability.log); if [ -z "$LOG_CONTENT" ]; then echo "   等待记录..."; else echo "$LOG_CONTENT"; fi
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
fi
EOF
chmod +x /usr/bin/c

cat << 'EOF' > /usr/bin/ss
#!/bin/bash
/usr/bin/c --live
EOF
chmod +x /usr/bin/ss

cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")

# ⚠️ 修复死锁：开机大清洗，毁灭所有的残留免死金牌和假死标记，防止系统永久瘫痪
find /etc/s-box -name "*.manual" -o -name "*.session" -o -name "*.hibernating" | xargs rm -f 2>/dev/null
echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS 开机/重置！天网哨兵上线，残留缓存已清洗。" >> "$SLA_LOG"

get_node_ip() {
    local PORT=$1; local IP=""
    local RAND_API=${APIS[$RANDOM % ${#APIS[@]}]}
    IP=$(curl -s4 -m 6 --socks5 127.0.0.1:$PORT $RAND_API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    [ -n "$IP" ] && { echo "$IP"; return; }
    sleep 2
    for api in "${APIS[@]}"; do
        [ "$api" == "$RAND_API" ] && continue
        IP=$(curl -s4 -m 6 --socks5 127.0.0.1:$PORT $api 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "$IP" ] && { echo "$IP"; return; }
    done
    echo ""
}

while true; do
    for NODE in 1 2 3; do
        [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box"; }
        [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; }
        [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; }
        
        # 遇到手动操作，直接跳过
        if [ -f "$WORK/s${NODE}.manual" ]; then continue; fi
        
        # ⚠️ 修复防爆死循环：如果该节点已休眠，哨兵绝对不强行唤醒
        if [ -f "$WORK/s${NODE}.hibernating" ]; then continue; fi
        
        LOCK="$WORK/s${NODE}.lock"; [ ! -f "$LOCK" ] && continue
        TARGET=$(cat "$LOCK" | tr -d '[:space:]'); [ -z "$TARGET" ] && continue
        CURRENT=$(get_node_ip $IN_PORT)
        
        if [[ -n "$CURRENT" && "$CURRENT" == "$TARGET" ]]; then
            if ! netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then
                socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT &
                echo "$(date '+[%m-%d %H:%M:%S]') [🟢 恢复] S${NODE} 利用底层缓存秒连，气闸开启！" >> "$SLA_LOG"
                [ ! -f "$WORK/s${NODE}.session" ] && date +%s > "$WORK/s${NODE}.session"
            fi
        elif ! pgrep -f "/usr/bin/sl${NODE}" > /dev/null; then
            if [[ -n "$CURRENT" && "$CURRENT" != "$TARGET" ]]; then
                fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
                echo "$(date '+[%m-%d %H:%M:%S]') [🚨 漂移] S${NODE} 发生漂移($CURRENT)！Session清零，斩断气闸呼叫SL！" >> "$SLA_LOG"
                rm -f "$WORK/s${NODE}.session" 2>/dev/null
                nohup /usr/bin/sl${NODE} >/dev/null 2>&1 &
                sleep 15
            elif [ -z "$CURRENT" ]; then
                fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
                echo "$(date '+[%m-%d %H:%M:%S]') [🟡 假死] S${NODE} 深度断网！斩断气闸(保留Session)，移交SL复苏！" >> "$SLA_LOG"
                nohup /usr/bin/sl${NODE} >/dev/null 2>&1 &
                sleep 15
            fi
        fi
    done
    sleep 20
done
EOF
chmod +x /usr/bin/w_master
cat > /etc/systemd/system/w_master.service << 'EOF'
[Unit]
Description=Skynet Master
[Service]
ExecStart=/usr/bin/w_master
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now w_master >/dev/null 2>&1

# ====================================================================
# 10. 终极自毁退路：U 指令
# ====================================================================
cat << 'EOF' > /usr/bin/u
#!/bin/bash
clear; echo -e "\033[1;31m⚠️ 正在启动【天网自毁回滚程序】\033[0m\n👉 确定要彻底焚毁天网吗？(输入 y 确认): \c"
read confirm; [ "$confirm" != "y" ] && exit 0
systemctl stop w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 warp-go wg-quick@wgcf >/dev/null 2>&1
systemctl disable w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 >/dev/null 2>&1
rm -f /etc/systemd/system/w_master.service /etc/systemd/system/sing-box.service /etc/systemd/system/psiphon*.service
systemctl daemon-reload; pkill -9 -f psiphon-tunnel-core; pkill -9 -f sing-box; pkill -9 -f w_master; pkill -9 -f sl
[ -f "/root/CFwarp.sh" ] && echo -e "\033[1;33m👉 请在弹出的菜单中选择卸载 WARP\033[0m" && bash /root/CFwarp.sh
rm -rf /etc/s-box /usr/local/bin/warp-go /usr/bin/warp-go /root/CFwarp.sh /usr/bin/s[1-4] /usr/bin/l[1-4] /usr/bin/sl[1-4] /usr/bin/c[1-4] /usr/bin/c /usr/bin/ss /usr/bin/u /usr/bin/v
crontab -l 2>/dev/null | grep -v "stability.log" | crontab -
sed -i '/prefer-family = IPv6/d' ~/.wgetrc 2>/dev/null
echo "🎉 物理超度完毕！"
EOF
chmod +x /usr/bin/u

# 11. 凌晨 4 点重启任务
(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，开启新史记 ===\" > /etc/s-box/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网系统 V22 部署完毕！零泄漏气闸与双轨监控引擎已全量接管！\033[0m"

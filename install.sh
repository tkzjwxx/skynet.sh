#!/bin/bash
# ====================================================================
# 天网系统 V9.6 终极真理版 (双栈互联 + 绝对生命周期 + 错峰高可用)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网系统 V9.6 终极版】全量创世部署...\033[0m"

# 1. 基础环境基建与系统级修复
echo -e "\033[1;36m📦 1/7 正在修复系统环境与安装依赖...\033[0m"
if ! grep -q "$(hostname)" /etc/hosts; then
    echo "127.0.0.1 localhost $(hostname) $(hostname).localdomain" | sudo tee -a /etc/hosts > /dev/null
fi
apt-get update -y >/dev/null 2>&1
apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl nano cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

# 2. 部署 WARP-GO (为纯 IPv6 机器打通 IPv4 全球节点池)
echo -e "\033[1;36m🌐 2/7 正在植入 WARP-GO，获取全球 IPv4 访问权限...\033[0m"
wget -qN https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh
bash warp-go.sh 4 >/dev/null 2>&1
sleep 5

# 3. 下载底层双核引擎 (内置镜像加速防断流)
echo -e "\033[1;36m⚙️ 3/7 正在下载 Sing-box 与 Psiphon 核心...\033[0m"
wget -q --show-progress --no-check-certificate -O /etc/s-box/psiphon-tunnel-core https://mirror.ghproxy.com/https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core
wget -qO- https://mirror.ghproxy.com/https://github.com/SagerNet/sing-box/releases/download/v1.9.3/sing-box-1.9.3-linux-amd64.tar.gz | tar xz -C /tmp/
mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box
chmod +x /etc/s-box/sing-box

# 4. 部署 Sing-box 核心路由与防火墙免疫
echo -e "\033[1;36m🚦 4/7 正在烧录 Sing-box 路由与生成 TLS 证书...\033[0m"
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 36500 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null

cat << 'EOF' > /etc/s-box/sing-box.json
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
  "route": {"rules": [ {"inbound": ["hy2-in-1", "vmess-in-1"], "outbound": "out-s1"}, {"inbound": ["hy2-in-2", "vmess-in-2"], "outbound": "out-s2"}, {"inbound": ["hy2-in-3", "vmess-in-3"], "outbound": "out-s3"} ] }
}
EOF

cat > /etc/systemd/system/sing-box.service << 'EOF'
[Unit]
Description=Sing-box Core Router
After=network.target
[Service]
ExecStartPre=-/sbin/ip6tables -I INPUT -p udp --dport 8443 -j ACCEPT
ExecStartPre=-/sbin/ip6tables -I INPUT -p udp --dport 8444 -j ACCEPT
ExecStartPre=-/sbin/ip6tables -I INPUT -p udp --dport 8445 -j ACCEPT
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable sing-box >/dev/null 2>&1 && systemctl start sing-box

# 5. 部署四大赛风沙盒 (S1-S3主力 + S4旁路)
echo -e "\033[1;36m🐺 5/7 正在开辟底层物理战区沙盒...\033[0m"
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; HTTP_PORT=18081; DIR="/etc/s-box"; REG="US"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; HTTP_PORT=18082; DIR="/etc/s-box/sub2"; REG="GB"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; HTTP_PORT=18083; DIR="/etc/s-box/sub3"; REG="JP"; }
    [ "$NODE" == "4" ] && { IN_PORT=2084; HTTP_PORT=18084; DIR="/etc/s-box/sub4"; REG="US"; }

    cp /etc/s-box/psiphon-tunnel-core "$DIR/psiphon-tunnel-core" 2>/dev/null
    cat > "$DIR/base.config" << EOF
{
  "LocalHttpProxyPort": $HTTP_PORT,
  "LocalSocksProxyPort": $IN_PORT,
  "PropagationChannelId": "FFFFFFFFFFFFFFFF",
  "SponsorId": "FFFFFFFFFFFFFFFF",
  "EgressRegion": "$REG",
  "DataRootDirectory": "$DIR",
  "RemoteServerListDownloadFilename": "remote_server_list",
  "RemoteServerListSignaturePublicKey": "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
  "RemoteServerListUrl": "https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed",
  "UseIndistinguishableTLS": true
}
EOF
    cat > /etc/systemd/system/psiphon${NODE}.service << EOF
[Unit]
Description=Psiphon Tunnel Node $NODE
After=network.target
[Service]
WorkingDirectory=$DIR
ExecStart=$DIR/psiphon-tunnel-core -config base.config
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable psiphon${NODE} >/dev/null 2>&1 && systemctl start psiphon${NODE}
done

# 6. 注入天网四大微服务引擎 (S/L/SL/S4)
echo -e "\033[1;36m🧠 6/7 正在注入 S/L/SL 解耦引擎与 S4 旁路洗号程序...\033[0m"
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; DIR="/etc/s-box"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; DIR="/etc/s-box/sub2"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; DIR="/etc/s-box/sub3"; SVC="psiphon3"; }

cat << 'EOF' > /usr/bin/s${NODE}
#!/bin/bash
NODE="__NODE__"; IN_PORT="__IN_PORT__"; OUT_PORT="__OUT_PORT__"; DIR="__DIR__"; SVC="__SVC__"; SLA_LOG="/etc/s-box/stability.log"
echo $$ > "$DIR/s${NODE}.manual"
echo "$(date '+[%m-%d %H:%M:%S]') 🛑 主人手动介入 S${NODE} 模式！哨兵大管家已挂起。" >> "$SLA_LOG"
trap 'echo "$(date '+[%m-%d %H:%M:%S]') 🔰 主人退出 S${NODE} 模式！哨兵重新接管防线。" >> "$SLA_LOG"; rm -f "$DIR/s${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT HUP QUIT
clear; echo -e "\033[1;35m╔═════════════════════════════════════════════════╗\n║   🐺 [S$NODE] 全球鱼塘探测与安全抽卡引擎        ║\n╚═════════════════════════════════════════════════╝\033[0m"
OLD_LOCK=$(cat "$DIR/s${NODE}.lock" 2>/dev/null | tr -d '[:space:]')
[ -n "$OLD_LOCK" ] && echo -e "🛡️ \033[1;32m当前保底 IP: $OLD_LOCK\033[0m\n"
fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
echo -e "\033[1;36m🌍 请选择 S$NODE 本次目标国家池 (底层永久生效)：\033[0m"
echo "  [1] 🇺🇸 美国 (US)   [2] 🇬🇧 英国 (GB)   [3] 🇯🇵 日本 (JP)   [4] 🇸🇬 新加坡 (SG)"
read -p "请输入编号 (默认 1): " REG_CHOICE
case "$REG_CHOICE" in 2) TARGET_REG="GB";; 3) TARGET_REG="JP";; 4) TARGET_REG="SG";; *) TARGET_REG="US";; esac
sed -i "s/\"EgressRegion\": \"[A-Z]*\"/\"EgressRegion\": \"$TARGET_REG\"/g" $DIR/base.config
echo -e "✅ 已切换至: \033[1;32m$TARGET_REG\033[0m\n---------------------------------------------------"
echo "模式：[1] 单抽  [2] 鱼塘连抽"
read -p "请输入模式 (默认 1): " MODE_CHOICE
if [ "$MODE_CHOICE" == "2" ]; then
    read -p "连抽次数 (默认 10): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=10
    rm -f "$DIR/tmp_pool.txt"
    for ((i=1; i<=SCAN_MAX; i++)); do
        echo -ne "\r\033[K⏳ [$i/$SCAN_MAX] 盲抽中..."
        systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"
        sleep 6; IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
        [ -n "$IP" ] && echo "$IP" >> "$DIR/tmp_pool.txt"
    done
    echo -e "\n\n\033[1;32m📊 鱼塘结果:\033[0m"; sort -V "$DIR/tmp_pool.txt" | uniq -c | sort -V
else
    ATTEMPTS=0
    while true; do
        ((ATTEMPTS++)); echo -ne "\r\033[K⏳ [$ATTEMPTS 次] 盲抽中..."
        systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"
        sleep 6; IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
        [ -z "$IP" ] && continue
        echo -e "\n🎯 抽中 IP: \033[32m$IP\033[0m"
        read -p "✨ 满意按 [Y] 锁定替换，按 [回车] 重抽: " k
        if [[ "$k" == "y" || "$k" == "Y" ]]; then
            # 💡 只有确认替换新 IP 时，才重置存活寿命
            echo "$IP" > "$DIR/s${NODE}.lock"; date +%s > "$DIR/s${NODE}.uptime"
            echo -e "✅ \033[1;32m新极品已挂锁！\033[0m"; break
        fi
    done
fi
EOF

cat << 'EOF' > /usr/bin/l${NODE}
#!/bin/bash
NODE="__NODE__"; IN_PORT="__IN_PORT__"; OUT_PORT="__OUT_PORT__"; DIR="__DIR__"; SVC="__SVC__"; SLA_LOG="/etc/s-box/stability.log"
echo $$ > "$DIR/s${NODE}.manual"
echo "$(date '+[%m-%d %H:%M:%S]') 🛑 主人手动介入 L${NODE} 模式！哨兵大管家已挂起。" >> "$SLA_LOG"
trap 'echo "$(date '+[%m-%d %H:%M:%S]') 🔰 主人退出 L${NODE} 模式！哨兵重新接管防线。" >> "$SLA_LOG"; rm -f "$DIR/s${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT HUP QUIT
clear; echo -e "\033[1;31m╔═════════════════════════════════════════════════╗\n║   🐺 [L$NODE] 人工狂暴死磕引擎 (应急介入) ║\n╚═════════════════════════════════════════════════╝\033[0m"
TARGET=$(cat "$DIR/s${NODE}.lock" 2>/dev/null | tr -d '[:space:]')
read -p "🎯 锁定IP为 [$TARGET]，输入死磕IP (回车默认): " INPUT_IP
# 💡 核心绝对寿命逻辑：仅当输入不同 IP 时才清零秒表
if [[ -n "$INPUT_IP" && "$INPUT_IP" != "$TARGET" ]]; then 
    TARGET="$INPUT_IP"; echo "$TARGET" > "$DIR/s${NODE}.lock"; date +%s > "$DIR/s${NODE}.uptime"
fi
fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ATTEMPTS=0
while true; do
    ((ATTEMPTS++)); echo -ne "\r\033[K⏳ [第 $ATTEMPTS 次] 正在地下室疯狂重抽..."
    systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"
    sleep 8
    IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
    if [ "$IP" == "$TARGET" ]; then
        echo -e "\n🎉 \033[1;31m命中目标！$IP\033[0m"; echo -e "✅ \033[1;32m挂锁完成！\033[0m"
        exit 0
    fi
done
EOF

cat << 'EOF' > /usr/bin/sl${NODE}
#!/bin/bash
NODE="__NODE__"; IN_PORT="__IN_PORT__"; OUT_PORT="__OUT_PORT__"; DIR="__DIR__"; SVC="__SVC__"
SLA_LOG="/etc/s-box/stability.log"
TARGET=$(cat "$DIR/s${NODE}.lock" 2>/dev/null | tr -d '[:space:]'); [ -z "$TARGET" ] && exit 1
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ATTEMPTS=0; CHASE_START=$(date +%s)
ping -c 2 -W 2 "$TARGET" >/dev/null 2>&1 && echo "$(date '+[%m-%d %H:%M:%S]') 🔍 S${NODE} 侦察: 目标 ($TARGET) 存活！开始追捕！" >> "$SLA_LOG" || echo "$(date '+[%m-%d %H:%M:%S]') 🔍 S${NODE} 侦察: 目标 ($TARGET) Ping超时。按纪律强制追捕！" >> "$SLA_LOG"

while true; do
    ((ATTEMPTS++))
    if [ -f "$DIR/s${NODE}.manual" ]; then rm -f "$DIR/s${NODE}.hibernating" 2>/dev/null; exit 0; fi
    NOW=$(date +%s); ELAPSED=$((NOW - CHASE_START))
    if [ "$ELAPSED" -ge 1200 ]; then
        echo "$(date '+[%m-%d %H:%M:%S]') 🌙 S${NODE} 追捕20分钟未果！进入深度休眠(2小时)..." >> "$SLA_LOG"
        touch "$DIR/s${NODE}.hibernating"; systemctl stop "$SVC" 2>/dev/null
        sleep 7200
        rm -f "$DIR/s${NODE}.hibernating" 2>/dev/null; CHASE_START=$(date +%s); ATTEMPTS=0
        echo "$(date '+[%m-%d %H:%M:%S]') ☀️ S${NODE} 2小时休眠结束！开启新一轮追捕！" >> "$SLA_LOG"; continue
    fi
    
    # 💡 错峰防爆：随机休眠 3 到 8 秒，防止多个 SL 同秒重启 CPU
    STAGGER=$((RANDOM % 6 + 3)); sleep $STAGGER
    systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"
    IP=""
    for i in {1..12}; do IP=$(curl -s -m 3 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]'); [ -n "$IP" ] && break; sleep 1; done
    [ -z "$IP" ] && continue
    if [ $((ATTEMPTS % 3)) -eq 0 ]; then echo "$(date '+[%m-%d %H:%M:%S]') ⚙️ SL 狂飙追捕中... S${NODE} 已抽 $ATTEMPTS 次 (刚抽到: $IP)" >> "$SLA_LOG"; fi
    if [ "$IP" == "$TARGET" ]; then
        rm -f "$DIR/s${NODE}.hibernating" 2>/dev/null
        echo "$(date '+[%m-%d %H:%M:%S]') 🟢 S${NODE} 历经 $ATTEMPTS 次重抽，成功夺回极品 IP！" >> "$SLA_LOG"
        socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT &
        # 💡 核心绝对寿命逻辑：夺回后严禁重置 uptime！历史战绩永不归零！
        exit 0
    fi
done
EOF

    sed -i "s|__NODE__|$NODE|g; s|__IN_PORT__|$IN_PORT|g; s|__OUT_PORT__|$OUT_PORT|g; s|__DIR__|$DIR|g; s|__SVC__|$SVC|g" /usr/bin/s${NODE} /usr/bin/l${NODE} /usr/bin/sl${NODE}
    chmod +x /usr/bin/s${NODE} /usr/bin/l${NODE} /usr/bin/sl${NODE}
done

# -------- S4 旁路引擎 --------
cat > /usr/bin/s4 << 'EOF'
#!/bin/bash
DIR="/etc/s-box/sub4"; BLACKLIST_FILE="/etc/s-box/blacklist/bad_ips.txt"; SVC="psiphon4"; IN_PORT=2084
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip"); touch "$BLACKLIST_FILE"
clear; echo -e "\033[1;36m   👻 [S4] 幽灵斥候 - 旁路洗号引擎 \033[0m\n   黑名单数: $(wc -l < $BLACKLIST_FILE 2>/dev/null || echo 0)\n"
echo "  [1] 启动深海打捞   [2] 管理高级黑名单   [3] 退出"
read -p "选择 (默认 1): " MENU_CHOICE; [ -z "$MENU_CHOICE" ] && MENU_CHOICE=1
if [ "$MENU_CHOICE" == "2" ]; then
    echo -e "\033[1;36m💡 输入 nano 一次性粘贴上千行！\033[0m"; read -p "输入 (回车退出): " INPUT_DATA
    if [ "$INPUT_DATA" == "nano" ]; then nano "$BLACKLIST_FILE"; else for BAD_IP in $INPUT_DATA; do echo "$BAD_IP" >> "$BLACKLIST_FILE"; done; fi
    exit 0
elif [ "$MENU_CHOICE" == "1" ]; then
    echo "  [1] 🇺🇸 美国 (US)   [2] 🇬🇧 英国 (GB)   [3] 🇯🇵 日本 (JP)"; read -p "战区 (默认 1): " REG_CHOICE
    [ "$REG_CHOICE" == "1" ] && sed -i 's/"EgressRegion": "[A-Z]*"/"EgressRegion": "US"/' $DIR/base.config
    [ "$REG_CHOICE" == "2" ] && sed -i 's/"EgressRegion": "[A-Z]*"/"EgressRegion": "GB"/' $DIR/base.config
    [ "$REG_CHOICE" == "3" ] && sed -i 's/"EgressRegion": "[A-Z]*"/"EgressRegion": "JP"/' $DIR/base.config
    read -p "打捞次数 (默认 20): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=20
    ATTEMPTS=0; VALID_IPS=()
    while [ $ATTEMPTS -lt $SCAN_MAX ]; do
        ((ATTEMPTS++)); echo -ne "\r\033[K🔍 [$ATTEMPTS/$SCAN_MAX] 下网..."
        systemctl stop "$SVC" >/dev/null 2>&1; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* >/dev/null 2>&1; systemctl start "$SVC"; sleep 8
        IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
        if [ -n "$IP" ]; then
            if grep -q "^${IP%.*}\|^\(${IP}\)" "$BLACKLIST_FILE" 2>/dev/null; then echo -e "\n🚫 触发黑名单: $IP"; else echo -e "\n🌟 捕获纯净极品: \033[1;32m$IP\033[0m"; VALID_IPS+=("$IP"); fi
        fi
    done
    echo -e "\n\033[1;33m📊 打捞过滤后获得 ${#VALID_IPS[@]} 个极品。\033[0m"
    if [ ${#VALID_IPS[@]} -gt 0 ]; then
        printf "%s\n" "${VALID_IPS[@]}" | sort -V | uniq -c | sort -nr
        echo "  [1] 全部绞杀 (打入黑名单)   [0] 留着备用 (退出复制)"; read -p "请裁决: " EXEC_CHOICE
        if [ "$EXEC_CHOICE" == "1" ]; then printf "%s\n" "${VALID_IPS[@]}" | sort -u >> "$BLACKLIST_FILE"; fi
    fi
fi
EOF
chmod +x /usr/bin/s4

# 7. 激活 W 共识哨兵、MYIP 大盘、SS 快捷键与定时重启
echo -e "\033[1;36m👁️ 7/7 正在组装真理监控大盘与系统守护进程...\033[0m"
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")

echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS 系统开机/重启完成！天网哨兵已上线并重新接管大盘！" >> "$SLA_LOG"

get_node_ip() {
    local PORT=$1; local IP=""
    local RAND_API=${APIS[$RANDOM % ${#APIS[@]}]}
    IP=$(curl -s -m 5 --socks5 127.0.0.1:$PORT $RAND_API 2>/dev/null | tr -d '[:space:]')
    [ -n "$IP" ] && { echo "$IP"; return; }
    for api in "${APIS[@]}"; do
        [ "$api" == "$RAND_API" ] && continue
        IP=$(curl -s -m 3 --socks5 127.0.0.1:$PORT $api 2>/dev/null | tr -d '[:space:]')
        [ -n "$IP" ] && { echo "$IP"; return; }
    done
    echo ""
}

while true; do
    for NODE in 1 2 3; do
        [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box"; }
        [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; }
        [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; }
        
        if [ -f "$WORK/s${NODE}.manual" ]; then if kill -0 $(cat "$WORK/s${NODE}.manual" 2>/dev/null | tr -d '[:space:]') 2>/dev/null; then continue; fi; rm -f "$WORK/s${NODE}.manual" 2>/dev/null; fi
        LOCK="$WORK/s${NODE}.lock"; [ ! -f "$LOCK" ] && continue
        TARGET=$(cat "$LOCK" | tr -d '[:space:]'); [ -z "$TARGET" ] && continue
        
        CURRENT=$(get_node_ip $IN_PORT)
        if [[ -n "$CURRENT" && "$CURRENT" == "$TARGET" ]]; then
            if ! netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then 
                socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT & 
                echo "$(date '+[%m-%d %H:%M:%S]') 🟢 S${NODE} 利用底层缓存记忆秒连成功！开机/自愈完成，气闸开启！" >> "$SLA_LOG"
            fi
        elif [[ -n "$CURRENT" && "$CURRENT" != "$TARGET" ]]; then
            fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
            if ! pgrep -f "/usr/bin/sl${NODE}" > /dev/null; then 
                echo "$(date '+[%m-%d %H:%M:%S]') 🔴 S${NODE} 漂移($CURRENT)！呼叫后台 SL 追捕！" >> "$SLA_LOG"
                nohup /usr/bin/sl${NODE} >/dev/null 2>&1 &
                # 💡 排队防爆机制：唤醒 SL 后哨兵强行挂起 15 秒
                sleep 15
            fi
        elif [ -z "$CURRENT" ]; then
            fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
            if ! pgrep -f "/usr/bin/sl${NODE}" > /dev/null; then 
                echo "$(date '+[%m-%d %H:%M:%S]') 🔴 S${NODE} 深度假死(探针失联)！斩杀气闸，移交 SL 复苏！" >> "$SLA_LOG"
                nohup /usr/bin/sl${NODE} >/dev/null 2>&1 &
                # 💡 排队防爆机制
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
Description=Skynet Sentinel Master
After=network.target sing-box.service psiphon1.service psiphon2.service psiphon3.service
[Service]
Type=simple
ExecStart=/usr/bin/w_master
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable w_master >/dev/null 2>&1 && systemctl start w_master

cat > /usr/bin/myip << 'EOF'
#!/bin/bash
clear; echo -e "\033[1;36m=======================================================================================================================\033[0m"
echo -e "\033[1;37m                                   🛡️ 天网系统 9.6 (双栈互联·全息史记版) 🛡️\033[0m"
echo -e "\033[1;36m=======================================================================================================================\033[0m"
printf "%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\n" "通道" "国家" "锁定 IP (目标)" "当前真实 IP" "对外气闸" "绝对存活时长" "健康状态及行动指示"
echo "-----------------------------------------------------------------------------------------------------------------------"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box"; REG="S1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; REG="S2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; REG="S3"; }
    REGION=$(grep -oP '"EgressRegion": "\K[A-Z]+' $WORK/base.config 2>/dev/null || echo "未知")
    TARGET=$(cat "$WORK/s${NODE}.lock" 2>/dev/null | tr -d '[:space:]'); [ -z "$TARGET" ] && TARGET="未锁定"
    CURRENT=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
    if netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then GATE_REAL="开启"; else GATE_REAL="熔断"; fi
    
    UPTIME_STR="--:--:--"
    if [ -f "$WORK/s${NODE}.uptime" ] && [ "$TARGET" != "未锁定" ]; then
        START_TIME=$(cat "$WORK/s${NODE}.uptime" 2>/dev/null | tr -d '[:space:]')
        if [[ "$START_TIME" =~ ^[0-9]+$ ]]; then
            NOW=$(date +%s); DIFF=$((NOW - START_TIME)); [ $DIFF -lt 0 ] && DIFF=0
            DAYS=$((DIFF / 86400)); HOURS=$(( (DIFF % 86400) / 3600 )); MINS=$(( (DIFF % 3600) / 60 )); SECS=$((DIFF % 60))
            if [ "$DAYS" -gt 0 ]; then UPTIME_STR=$(printf "%d天 %02d:%02d:%02d" $DAYS $HOURS $MINS $SECS); else UPTIME_STR=$(printf "%02d:%02d:%02d" $HOURS $MINS $SECS); fi
        fi
    fi
    
    if [ -f "$WORK/s${NODE}.manual" ]; then COLOR="\033[1;35m"; GATE_TEXT="🛑挂起"; UPTIME_STR="人工干预中"; STATUS="🛑 人工干预中 (S / L 模式)"
    elif [ -f "$WORK/s${NODE}.hibernating" ]; then COLOR="\033[1;36m"; GATE_TEXT="🔴熔断"; UPTIME_STR="深度休眠中"; STATUS="🌙 追捕20分钟未果，深度休眠中 (等待唤醒)"
    elif pgrep -f "/usr/bin/sl${NODE}" > /dev/null; then COLOR="\033[1;31m"; GATE_TEXT="🔴熔断"; UPTIME_STR="断线追捕中"; STATUS="🚨 气闸熔断！影子 SL 引擎正在后台寻回..."
    elif [ -z "$CURRENT" ]; then COLOR="\033[1;33m"; GATE_TEXT="🔴熔断"; CURRENT="获取失败"; STATUS="🟡 网络假死阻塞中 (死等复苏，存活累计中)"
    elif [[ "$GATE_REAL" == "开启" && "$CURRENT" == "$TARGET" ]]; then COLOR="\033[1;32m"; GATE_TEXT="🟢开启"; STATUS="✅ 稳定零泄漏 (极品IP稳固锁定)"
    else COLOR="\033[1;31m"; GATE_TEXT="🔴熔断"; UPTIME_STR="等待起搏"; STATUS="🚨 状态异常！等待哨兵判定..."
    fi
    printf "${COLOR}%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\033[0m\n" "$REG" "$REGION" "$TARGET" "${CURRENT:-空}" "$GATE_TEXT" "$UPTIME_STR" "$STATUS"
done
echo -e "\033[1;36m=======================================================================================================================\033[0m"
echo -e "\033[1;37m                                   📋 当日核心行动日志 (全天无删减史记)                               \033[0m"
echo -e "\033[1;36m=======================================================================================================================\033[0m"

TODAY=$(date '+%m-%d')
if [ "$1" == "--live" ]; then
    grep "^\[$TODAY" /etc/s-box/stability.log | tail -n 15 2>/dev/null || echo -e "\033[1;90m   今日暂无行动记录...\033[0m"
else
    LOG_CONTENT=$(grep "^\[$TODAY" /etc/s-box/stability.log | grep -v "⚙️ SL 狂飙追捕中" | tail -n 300 2>/dev/null)
    if [ -z "$LOG_CONTENT" ]; then echo -e "\033[1;90m   今日暂无行动记录...\033[0m"
    else echo "$LOG_CONTENT"
    fi
fi
echo -e "\033[1;36m=======================================================================================================================\033[0m"
EOF
chmod +x /usr/bin/myip
ln -sf /usr/bin/myip /usr/bin/c

# 生成带 UI 修复的快捷 ss 监控指令
echo '#!/bin/bash' > /usr/bin/ss
echo 'export LANG=C.UTF-8' >> /usr/bin/ss
echo 'watch -c -n 5 /usr/bin/myip --live' >> /usr/bin/ss
chmod +x /usr/bin/ss

# 植入每日凌晨 4 点绝对净化重启任务
(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 4 * * * /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 【天网系统 V9.6 终极版】全量创世部署完毕！\033[0m"

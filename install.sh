#!/bin/bash
# ====================================================================
# 天网系统 V10.0 指挥官版 (官方直连 + 史记净化 + 唯一指令 c)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网系统 V10.0】全量创世部署 (终极整合版)...\033[0m"

# 1. 环境修复与依赖安装
MY_HOST=$(hostname); echo "127.0.0.1 localhost $MY_HOST" > /etc/hosts
apt-get update -y >/dev/null 2>&1
apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

# 2. 部署 WARP-GO (打通全球双栈)
echo -e "\033[1;36m🌐 2/7 正在植入 WARP-GO，获取全球 IPv4 访问权限...\033[0m"
wget -qN https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh
bash warp-go.sh 4 >/dev/null 2>&1
sleep 8

# 3. 核心引擎官方直连拉取
wget -q --show-progress -O /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
wget -q --show-progress -O /tmp/sbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.3/sing-box-1.9.3-linux-amd64.tar.gz
tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box
chmod +x /etc/s-box/* && rm -rf /tmp/sbox.tar.gz /tmp/sing-box-*

# 4. 烧录 Sing-box 核心路由 (VMess 10001-10003 已就绪)
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null
cat << 'CONFIG_EOF' > /etc/s-box/sing-box.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-1", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "vmess", "tag": "vm-1", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s1"} },
    { "type": "vmess", "tag": "vm-2", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s2"} },
    { "type": "vmess", "tag": "vm-3", "listen": "127.0.0.1", "listen_port": 10003, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s3"} }
  ],
  "outbounds": [
    { "type": "socks", "tag": "out-1", "server": "127.0.0.1", "server_port": 1081 },
    { "type": "socks", "tag": "out-2", "server": "127.0.0.1", "server_port": 1082 },
    { "type": "socks", "tag": "out-3", "server": "127.0.0.1", "server_port": 1083 }
  ],
  "route": {"rules": [ {"inbound": ["hy2-1", "vm-1"], "outbound": "out-1"}, {"inbound": ["vm-2"], "outbound": "out-2"}, {"inbound": ["vm-3"], "outbound": "out-3"} ]}
}
CONFIG_EOF
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

# 5. 开辟战区沙盒 (US/GB/JP)
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN=2081; DIR="/etc/s-box"; REG="US"; }
    [ "$NODE" == "2" ] && { IN=2082; DIR="/etc/s-box/sub2"; REG="GB"; }
    [ "$NODE" == "3" ] && { IN=2083; DIR="/etc/s-box/sub3"; REG="JP"; }
    [ "$NODE" == "4" ] && { IN=2084; DIR="/etc/s-box/sub4"; REG="US"; }
    cp /etc/s-box/psiphon-tunnel-core "$DIR/" 2>/dev/null
    cat > "$DIR/base.config" << P_EOF
{"LocalHttpProxyPort":$((IN+16000)),"LocalSocksProxyPort":$IN,"PropagationChannelId":"FFFFFFFFFFFFFFFF","SponsorId":"FFFFFFFFFFFFFFFF","EgressRegion":"$REG","DataRootDirectory":"$DIR","RemoteServerListDownloadFilename":"remote_server_list","RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=","RemoteServerListUrl":"https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed","UseIndistinguishableTLS":true}
P_EOF
    cat > /etc/systemd/system/psiphon${NODE}.service << SVC_EOF
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
    systemctl enable --now psiphon${NODE} >/dev/null 2>&1
done

# 6. 注入终极 S/L/SL 引擎 (带 UI 与 实时日志输出)
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN=2081; OUT=1081; DIR="/etc/s-box"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN=2082; OUT=1082; DIR="/etc/s-box/sub2"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN=2083; OUT=1083; DIR="/etc/s-box/sub3"; SVC="psiphon3"; }

cat << 'EOF' > /usr/bin/s${NODE}
#!/bin/bash
NODE="__NODE__"; IN="__IN__"; OUT="__OUT__"; DIR="__DIR__"; SVC="__SVC__"; SLA_LOG="/etc/s-box/stability.log"
echo $$ > "$DIR/s${NODE}.manual"
echo "$(date '+[%m-%d %H:%M:%S]') 🛑 主人介入 S${NODE}" >> "$SLA_LOG"
trap 'trap - EXIT; echo "$(date "+[%m-%d %H:%M:%S]") 🔰 退出模式" >> "$SLA_LOG"; rm -f "$DIR/s${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT
clear; echo -e "\033[1;36m╔══════════════════════════════════════════════════════╗\n║   🐺 [S${NODE}] 天网安全抽卡引擎 - 尊享版 UI            ║\n╚══════════════════════════════════════════════════════╝\033[0m"
OLD=$(cat "$DIR/s${NODE}.lock" 2>/dev/null); echo -e "\033[1;33m🛡️  当前锁定 IP :\033[0m \033[1;32m${OLD:-未锁定}\033[0m\n"
echo -e "\033[1;37m▶ 选择战区: [1]US [2]GB [3]JP [4]SG\033[0m"; read r; case "$r" in 2) TR="GB";; 3) TR="JP";; 4) TR="SG";; *) TR="US";; esac
sed -i "s/\"EgressRegion\": \"[A-Z]*\"/\"EgressRegion\": \"$TR\"/g" $DIR/base.config
echo -e "  \033[1;34m[1]\033[0m 极品单抽  \033[1;34m[2]\033[0m 鱼塘连抽"; read m
if [ "$m" == "2" ]; then
    read -p "连抽次数: " c; [ -z "$c" ] && c=10
    for ((i=1; i<=c; i++)); do echo -ne "\r\033[K⏳ [$i/$c] 盲抽中..."; systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"; sleep 6; IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN api.ipify.org 2>/dev/null); [ -n "$IP" ] && echo "$IP" >> "$DIR/tmp.txt"; done
    echo -e "\n📊 打捞结果:"; sort "$DIR/tmp.txt" | uniq -c; rm -f "$DIR/tmp.txt"
else
    while true; do echo -ne "\r\033[K⏳ 盲抽中..."; systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"; sleep 7
    IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN api.ipify.org 2>/dev/null); [ -z "$IP" ] && continue
    echo -e "\n🎯 命中: \033[1;32m$IP\033[0m"; read -p "满意按[y]锁定: " k
    if [[ "$k" == "y" ]]; then echo "$IP" > "$DIR/s${NODE}.lock"; date +%s > "$DIR/s${NODE}.uptime"; echo "✅ 已挂锁！"; break; fi; done
fi
EOF

cat << 'EOF' > /usr/bin/l${NODE}
#!/bin/bash
NODE="__NODE__"; IN="__IN__"; OUT="__OUT__"; DIR="__DIR__"; SVC="__SVC__"; SLA_LOG="/etc/s-box/stability.log"
echo $$ > "$DIR/s${NODE}.manual"
echo "$(date '+[%m-%d %H:%M:%S]') 🛑 主人介入 L${NODE} 死磕" >> "$SLA_LOG"
trap 'trap - EXIT; echo "$(date "+[%m-%d %H:%M:%S]") 🔰 退出模式" >> "$SLA_LOG"; rm -f "$DIR/s${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT
clear; echo -e "\033[1;35m╔══════════════════════════════════════════════════════╗\n║   🐺 [L${NODE}] 狂暴死磕引擎 - 极品强制夺回            ║\n╚══════════════════════════════════════════════════════╝\033[0m"
TAR=$(cat "$DIR/s${NODE}.lock" 2>/dev/null); read -p "死磕目标 (默认 $TAR): " i; [ -n "$i" ] && TAR="$i"
while true; do ((a++)); echo -ne "\r\033[K\033[1;35m⏳ [$a]\033[0m 夺回中..."; systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"; sleep 8
IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN api.ipify.org 2>/dev/null)
if [ "$IP" == "$TAR" ]; then echo -e "\n\n\033[1;32m██████████████████████████████████████████████████████\n█   🎉 命中目标！死磕成功！ $IP \033[0m\n"; exit 0; fi; done
EOF

cat << 'EOF' > /usr/bin/sl${NODE}
#!/bin/bash
NODE="__NODE__"; IN="__IN__"; OUT="__OUT__"; DIR="__DIR__"; SVC="__SVC__"; SLA_LOG="/etc/s-box/stability.log"
TAR=$(cat "$DIR/s${NODE}.lock" 2>/dev/null); [ -z "$TAR" ] && exit 0
echo "$(date '+[%m-%d %H:%M:%S]') 🕵️ 诊断确认假死。S${NODE} 寻回任务启动 -> $TAR" >> "$SLA_LOG"
C_ST=$(date +%s); AT=0
while true; do ((AT++)); if [ -f "$DIR/s${NODE}.manual" ]; then exit 0; fi
if [ $(($(date +%s) - C_ST)) -ge 1200 ]; then echo "$(date '+[%m-%d %H:%M:%S]') 🌙 S${NODE} 追捕超时休眠。" >> "$SLA_LOG"; touch "$DIR/s${NODE}.hibernating"; systemctl stop "$SVC" 2>/dev/null; exit 0; fi
echo "$(date '+[%m-%d %H:%M:%S]') [TRACE] S${NODE} 第 $AT 次抽卡尝试..." >> "$SLA_LOG"
systemctl stop "$SVC" 2>/dev/null; fuser -k -9 "$IN/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* 2>/dev/null; systemctl start "$SVC"; sleep 8
IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN api.ipify.org 2>/dev/null)
if [ "$IP" == "$TAR" ]; then rm -f "$DIR/s${NODE}.hibernating"; echo "$(date '+[%m-%d %H:%M:%S]') 🟢 成功！S${NODE} 命中极品 IP：$IP" >> "$SLA_LOG"; socat TCP4-LISTEN:$OUT,fork,reuseaddr TCP4:127.0.0.1:$IN & exit 0; fi
done
EOF
    sed -i "s|__NODE__|$NODE|g; s|__IN__|$IN|g; s|__OUT__|$OUT|g; s|__DIR__|$DIR|g; s|__SVC__|$SVC|g" /usr/bin/s${NODE} /usr/bin/l${NODE} /usr/bin/sl${NODE}
    chmod +x /usr/bin/s${NODE} /usr/bin/l${NODE} /usr/bin/sl${NODE}
done

# 7. 唯一核心指挥官 c (静态史记 + 动态监控)
cat << 'EOF' > /usr/bin/c
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
draw() {
    clear; echo -e "\033[1;36m=======================================================================================================================\033[0m"
    echo -e "\033[1;37m                                   🛡️ 天网系统 V10.0 (唯一指挥官·完美史记版) 🛡️\033[0m"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
    printf "%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\n" "通道" "国家" "锁定 IP (目标)" "当前真实 IP" "对外气闸" "持续存活时长" "健康状态及行动指示"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    for N in 1 2 3; do
        [ "$N" == "1" ] && { I=2081; O=1081; W="/etc/s-box"; R="S1"; }
        [ "$N" == "2" ] && { I=2082; O=1082; W="/etc/s-box/sub2"; R="S2"; }
        [ "$N" == "3" ] && { I=2083; O=1083; W="/etc/s-box/sub3"; R="S3"; }
        RE=$(grep -oP '"EgressRegion": "\K[A-Z]+' $W/base.config 2>/dev/null || echo "US")
        TA=$(cat "$W/s$N.lock" 2>/dev/null); CU=$(curl -s -m 4 --socks5 127.0.0.1:$I api.ipify.org 2>/dev/null)
        UP="--:--:--"; if [ -f "$W/s$N.uptime" ] && [ -n "$TA" ]; then ST=$(cat "$W/s$N.uptime"); DF=$(($(date +%s) - ST)); [ $DF -gt 0 ] && UP=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        G=$(netstat -tlnp 2>/dev/null | grep -q ":$O " && echo "🟢开启" || echo "🔴熔断")
        if [ -f "$W/s$N.manual" ]; then C="\033[1;35m"; S="🛑 手动介入"; elif [ -z "$CU" ]; then C="\033[1;33m"; S="🟡 探测假死"; elif [ "$CU" == "$TA" ]; then C="\033[1;32m"; S="✅ 稳定锁定"; else C="\033[1;31m"; S="🚨 漂移判定"; fi
        printf "${C}%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\033[0m\n" "$R" "$RE" "$TA" "${CU:-空}" "$G" "$UP" "$S"
    done
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
}
T=$(date '+%m-%d')
if [[ "$1" == "--live" || "$1" == "ss" ]]; then
    while true; do draw; grep "^\[$T" $SLA_LOG | grep -vE "介入|退出" | tail -n 25; sleep 2; done
else
    draw; LOG=$(grep "^\[$T" $SLA_LOG | grep -vE "TRACE|介入|退出"); echo "${LOG:-等待系统初始化史记...}"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
fi
EOF
chmod +x /usr/bin/c; ln -sf /usr/bin/c /usr/bin/ss

# 8. 哨兵大管家 (防抖双重诊断)
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"; APIS=("api.ipify.org" "icanhazip.com")
get_ip() { local ip=$(curl -s -m 6 --socks5 127.0.0.1:$1 ${APIS[$RANDOM%2]} 2>/dev/null); [ -z "$ip" ] && sleep 2 && ip=$(curl -s -m 6 --socks5 127.0.0.1:$1 ${APIS[$RANDOM%2]} 2>/dev/null); echo "$ip"; }
while true; do
    for N in 1 2 3; do
        [ "$N" == "1" ] && { I=2081; O=1081; W="/etc/s-box"; }
        [ "$N" == "2" ] && { I=2082; O=1082; W="/etc/s-box/sub2"; }
        [ "$N" == "3" ] && { I=2083; O=1083; W="/etc/s-box/sub3"; }
        [ -f "$W/s$N.manual" ] && continue
        TA=$(cat "$W/s$N.lock" 2>/dev/null | tr -d '[:space:]'); [ -z "$TA" ] && continue
        CU=$(get_ip $I)
        if [[ -n "$CU" && "$CU" == "$TA" ]]; then
            ! netstat -tlnp 2>/dev/null | grep -q ":$O " && socat TCP4-LISTEN:$O,fork,reuseaddr TCP4:127.0.0.1:$I &
        elif ! pgrep -f "/usr/bin/sl$N" > /dev/null; then
            fuser -k -9 "$O/tcp" >/dev/null 2>&1
            echo "$(date '+[%m-%d %H:%M:%S]') 🔴 S$N 失联判定成功。移交 SL 追捕。" >> "$SLA_LOG"
            nohup /usr/bin/sl$N >/dev/null 2>&1 &
            sleep 15
        fi
    done; sleep 20
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

# 9. 凌晨 4 点重置任务
(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重启，开启新史记 ===\" >> /etc/s-box/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网系统 V10.0 终极部署完毕！唯一指令：c\033[0m"

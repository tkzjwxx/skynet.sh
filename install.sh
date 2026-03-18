#!/bin/bash
# ====================================================================
# 天网系统 V10.10 (最终封卷版 | 纯净无劫持·全境通·含自毁退路)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网 V10.10】全量创世重筑 (纯净本源版)...\033[0m"

# 1. 清理环境 (干净整洁是稳定的基础)
systemctl stop psiphon1 psiphon2 psiphon3 psiphon4 sing-box w_master warp-go 2>/dev/null
killall -9 w_master 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/ss /usr/bin/u /usr/bin/s[1-3] /usr/bin/l[1-3] /usr/bin/sl[1-3]

# 2. 基础依赖安装
apt-get update -y && apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3

# 3. 核心组件打捞 (双源容错，绝不断流)
echo -e "\033[1;33m📦 正在打捞核心组件...\033[0m"
wget -q --show-progress -O /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

S_VER="1.11.0"
S_URL1="https://github.com/SagerNet/sing-box/releases/download/v${S_VER}/sing-box-${S_VER}-linux-amd64.tar.gz"
S_URL2="https://ghp.ci/$S_URL1"
wget -q --show-progress -O /tmp/sbox.tar.gz "$S_URL2" || wget -q --show-progress -O /tmp/sbox.tar.gz "$S_URL1"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box && chmod +x /etc/s-box/sing-box

# 4. WARP-GO 终极静默双栈注入
echo -e "\033[1;32m🌐 正在织入 WARP-GO 双栈网络 (官方静默模式)...\033[0m"
wget -qN https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh
# 终极解法：传参 d (Dualstack) 并通过 <<< "y" 回答所有确认提示，杜绝跳菜单！
bash warp-go.sh d <<< "y" >/dev/null 2>&1

# 5. 配置核心路由与气闸 (Sing-box)
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
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null
cat > /etc/systemd/system/sing-box.service << 'SVC_EOF'
[Unit]
Description=Sing-box
After=network.target
[Service]
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
[Install]
WantedBy=multi-user.target
SVC_EOF
systemctl daemon-reload && systemctl enable --now sing-box >/dev/null 2>&1

# 6. 初始化沙盒底层引擎 & UI 指令注入
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN=2081; OUT=1081; DIR="/etc/s-box"; REG="US"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN=2082; OUT=1082; DIR="/etc/s-box/sub2"; REG="GB"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN=2083; OUT=1083; DIR="/etc/s-box/sub3"; REG="JP"; SVC="psiphon3"; }
    
    cp /etc/s-box/psiphon-tunnel-core "$DIR/" 2>/dev/null
    cat > "$DIR/base.config" << P_EOF
{"LocalHttpProxyPort":$((IN+16000)),"LocalSocksProxyPort":$IN,"PropagationChannelId":"FFFFFFFFFFFFFFFF","SponsorId":"FFFFFFFFFFFFFFFF","EgressRegion":"$REG","DataRootDirectory":"$DIR","RemoteServerListDownloadFilename":"remote_server_list","RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=","RemoteServerListUrl":"https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed","UseIndistinguishableTLS":true}
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

    # S 引擎 (科技蓝)
cat << EOF > /usr/bin/s${NODE}
#!/bin/bash
DIR="$DIR"; IN="$IN"; SVC="$SVC"; SLA_LOG="/etc/s-box/stability.log"
echo \$\$ > "\$DIR/s${NODE}.manual"
echo "\$(date '+[%m-%d %H:%M:%S]') 🛑 主人介入 S${NODE}" >> "\$SLA_LOG"
trap 'trap - EXIT; echo "\$(date "+[%m-%d %H:%M:%S]") 🔰 退出模式" >> "\$SLA_LOG"; rm -f "\$DIR/s${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT HUP QUIT
clear; echo -e "\033[1;36m╔══════════════════════════════════════════════════════╗\n║   🐺 [S${NODE}] 天网安全抽卡引擎 - 战区配置面板          ║\n╚══════════════════════════════════════════════════════╝\033[0m"
OLD=\$(cat "\$DIR/s${NODE}.lock" 2>/dev/null); echo -e "\033[1;33m🛡️  当前锁定 IP :\033[0m \033[1;32m\${OLD:-未锁定}\033[0m\n"
echo -e "\033[1;37m▶ 选择战区: [1]US [2]GB [3]JP [4]SG\033[0m"; read -p "👉 编号 (默认1): " r; case "\$r" in 2) TR="GB";; 3) TR="JP";; 4) TR="SG";; *) TR="US";; esac
sed -i "s/\"EgressRegion\": \"[A-Z]*\"/\"EgressRegion\": \"\$TR\"/g" \$DIR/base.config
echo -e "  \033[1;34m[1]\033[0m 极品单抽  \033[1;34m[2]\033[0m 鱼塘连抽"; read -p "👉 模式 (默认1): " m
if [ "\$m" == "2" ]; then
    read -p "连抽次数 (默认10): " c; [ -z "\$c" ] && c=10; rm -f "\$DIR/tmp.txt"
    for ((i=1; i<=c; i++)); do echo -ne "\r\033[K\033[1;36m⏳ [\$i/\$c]\033[0m 盲抽中..."; systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"; sleep 6; IP=\$(curl -s -m 5 --socks5 127.0.0.1:\$IN api.ipify.org 2>/dev/null); [ -n "\$IP" ] && echo "\$IP" >> "\$DIR/tmp.txt"; done
    echo -e "\n\n\033[1;32m📊 鱼塘打捞结果:\033[0m"; sort "\$DIR/tmp.txt" | uniq -c | sort -V; rm -f "\$DIR/tmp.txt"
else
    A=0; while true; do ((A++)); echo -ne "\r\033[K\033[1;36m⏳ [第 \$A 次]\033[0m 盲抽中..."; systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"; sleep 7
    IP=\$(curl -s -m 5 --socks5 127.0.0.1:\$IN api.ipify.org 2>/dev/null); [ -z "\$IP" ] && continue
    echo -e "\n\033[1;32m🎯 命中 IP: \033[1;37m\$IP\033[0m"; read -p "✨ 满意按 [Y] 锁定并开启气闸: " k
    if [[ "\$k" == "y" || "\$k" == "Y" ]]; then echo "\$IP" > "\$DIR/s${NODE}.lock"; date +%s > "\$DIR/s${NODE}.uptime"; echo -e "\033[1;32m✅ 极品已挂锁！\033[0m\n"; break; fi; done
fi
EOF

    # L 引擎 (紫金尊贵)
cat << EOF > /usr/bin/l${NODE}
#!/bin/bash
DIR="$DIR"; IN="$IN"; SVC="$SVC"; SLA_LOG="/etc/s-box/stability.log"
echo \$\$ > "\$DIR/s${NODE}.manual"
echo "\$(date '+[%m-%d %H:%M:%S]') 🛑 主人介入 L${NODE}" >> "\$SLA_LOG"
trap 'trap - EXIT; echo "\$(date "+[%m-%d %H:%M:%S]") 🔰 退出模式" >> "\$SLA_LOG"; rm -f "\$DIR/s${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT HUP QUIT
clear; echo -e "\033[1;35m╔══════════════════════════════════════════════════════╗\n║   🐺 [L${NODE}] 狂暴死磕引擎 - 极品强制夺回            ║\n╚══════════════════════════════════════════════════════╝\033[0m"
TAR=\$(cat "\$DIR/s${NODE}.lock" 2>/dev/null); echo -ne "\033[1;33m🎯 死磕目标: \033[1;37m\${TAR:-未设定}\033[0m (回车确认/输入新IP): "; read i; [ -n "\$i" ] && TAR="\$i" && echo "\$TAR" > "\$DIR/s${NODE}.lock"
A=0; while true; do ((A++)); echo -ne "\r\033[K\033[1;35m⏳ [第 \$A 次]\033[0m 字节级夺回中..."; systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"; sleep 8
IP=\$(curl -s -m 5 --socks5 127.0.0.1:\$IN api.ipify.org 2>/dev/null)
if [ "\$IP" == "\$TAR" ]; then echo -e "\n\n\033[1;32m██████████████████████████████████████████████████████\n█   🎉 命中目标！死磕成功！\n█   🌟 极品 IP: \033[1;37m\$IP\033[1;32m\n██████████████████████████████████████████████████████\033[0m\n"; exit 0; fi; done
EOF

    # SL 后台引擎 (防端口冲突修复)
cat << EOF > /usr/bin/sl${NODE}
#!/bin/bash
DIR="$DIR"; IN="$IN"; OUT="$OUT"; SVC="$SVC"; SLA_LOG="/etc/s-box/stability.log"
TAR=\$(cat "\$DIR/s${NODE}.lock" 2>/dev/null); [ -z "\$TAR" ] && exit 0
echo "\$(date '+[%m-%d %H:%M:%S]') 🕵️ 诊断确认失联。S${NODE} 寻回启动 -> \$TAR" >> "\$SLA_LOG"
C_ST=\$(date +%s); AT=0
while true; do ((AT++)); if [ -f "\$DIR/s${NODE}.manual" ]; then exit 0; fi
if [ \$((\$(date +%s) - C_ST)) -ge 1200 ]; then echo "\$(date '+[%m-%d %H:%M:%S]') 🌙 S${NODE} 追捕超时休眠。" >> "\$SLA_LOG"; touch "\$DIR/s${NODE}.hibernating"; systemctl stop "\$SVC" 2>/dev/null; exit 0; fi
echo "\$(date '+[%m-%d %H:%M:%S]') [TRACE] S${NODE} 第 \$AT 次尝试..." >> "\$SLA_LOG"
systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"; sleep 8
IP=\$(curl -s -m 5 --socks5 127.0.0.1:\$IN api.ipify.org 2>/dev/null)
if [ "\$IP" == "\$TAR" ]; then 
    rm -f "\$DIR/s${NODE}.hibernating"
    echo "\$(date '+[%m-%d %H:%M:%S]') 🟢 成功！S${NODE} 命中极品 IP：\$IP" >> "\$SLA_LOG"
    fuser -k -9 "\$OUT/tcp" >/dev/null 2>&1
    socat TCP4-LISTEN:\$OUT,fork,reuseaddr TCP4:127.0.0.1:\$IN & 
    exit 0
fi
done
EOF
    chmod +x /usr/bin/s${NODE} /usr/bin/l${NODE} /usr/bin/sl${NODE}
done

# 7. 指挥官大盘 c
cat << 'EOF' > /usr/bin/c
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
draw_ui() {
    clear; echo -e "\033[1;36m=======================================================================================================================\033[0m"
    echo -e "\033[1;37m                                   🛡️ 天网系统 V10.10 (最终卷 · 真理大盘) 🛡️\033[0m"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
    printf "%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\n" "通道" "国家" "锁定 IP (目标)" "当前真实 IP" "对外气闸" "持续存活时长" "健康状态及行动指示"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    for N in 1 2 3; do
        [ "$N" == "1" ] && { I=2081; O=1081; W="/etc/s-box"; R="S1"; }
        [ "$N" == "2" ] && { I=2082; O=1082; W="/etc/s-box/sub2"; R="S2"; }
        [ "$N" == "3" ] && { I=2083; O=1083; W="/etc/s-box/sub3"; R="S3"; }
        RE=$(grep -oP '"EgressRegion": "\K[A-Z]+' $W/base.config 2>/dev/null || echo "US")
        TA=$(cat "$W/s$N.lock" 2>/dev/null)
        CU=$(curl -s --connect-timeout 1 -m 2 --socks5 127.0.0.1:$I api.ipify.org 2>/dev/null)
        UP="--:--:--"; if [ -f "$W/s$N.uptime" ] && [ -n "$TA" ]; then ST=$(cat "$W/s$N.uptime"); DF=$(($(date +%s) - ST)); [ $DF -gt 0 ] && UP=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        G=$(netstat -tlnp 2>/dev/null | grep -q ":$O " && echo "🟢开启" || echo "🔴熔断")
        if [ -f "$W/s$N.manual" ]; then C="\033[1;35m"; S="🛑 手动介入"; elif [ -z "$CU" ]; then C="\033[1;33m"; S="🟡 探测阻塞"; elif [ "$CU" == "$TA" ]; then C="\033[1;32m"; S="✅ 稳定锁定"; else C="\033[1;31m"; S="🚨 漂移判定"; fi
        printf "${C}%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\033[0m\n" "$R" "$RE" "$TA" "${CU:-空}" "$G" "$UP" "$S"
    done
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
}

if [ "$1" == "--live" ]; then
    while true; do
        draw_ui; echo -e "\033[1;37m                                   📋 实时战况监控 (每 2 秒动态起搏)                               \033[0m"
        grep "^\[$(date '+%m-%d')" $SLA_LOG | grep -vE "介入|退出" | tail -n 20
        echo -e "\n\033[1;90m[提示] 实时滚屏中... 按 Ctrl+C 退出\033[0m"; sleep 2
    done
else
    draw_ui; echo -e "\033[1;37m                                   📋 任务史记 (今日 4:00 起始)                               \033[0m"
    LOG=$(grep "^\[$(date '+%m-%d')" $SLA_LOG | grep -vE "TRACE|介入|退出")
    echo "${LOG:-等待系统初始化史记...}"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
fi
EOF
chmod +x /usr/bin/c

# 8. 绝对物理级的 SS 脚本
cat << 'EOF' > /usr/bin/ss
#!/bin/bash
/usr/bin/c --live
EOF
chmod +x /usr/bin/ss

# 9. 真理哨兵 w_master
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"; APIS=("api.ipify.org" "icanhazip.com")
get_ip() { local ip=$(curl -s -m 5 --socks5 127.0.0.1:$1 ${APIS[$RANDOM%2]} 2>/dev/null); [ -z "$ip" ] && sleep 2 && ip=$(curl -s -m 5 --socks5 127.0.0.1:$1 ${APIS[$RANDOM%2]} 2>/dev/null); echo "$ip"; }
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
            echo "$(date '+[%m-%d %H:%M:%S]') 🔴 S$N 失联判定。移交 SL 追捕。" >> "$SLA_LOG"
            nohup /usr/bin/sl$N >/dev/null 2>&1 &
            sleep 15
        fi
    done; sleep 15
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

# 10. 终极自毁退路：U 指令
cat << 'EOF' > /usr/bin/u
#!/bin/bash
clear; echo -e "\033[1;31m⚠️ 警告：正在启动【天网自毁回滚程序】！\033[0m\n👉 确定要彻底焚毁天网并恢复白板吗？(输入 y 确认): \c"
read confirm; [ "$confirm" != "y" ] && echo "✅ 已取消。" && exit 0
echo -e "\033[1;33m💀 正在物理超度...\033[0m"
systemctl stop w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 warp-go >/dev/null 2>&1
systemctl disable w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 >/dev/null 2>&1
rm -f /etc/systemd/system/w_master.service /etc/systemd/system/sing-box.service /etc/systemd/system/psiphon*.service
systemctl daemon-reload
pkill -9 -f psiphon-tunnel-core; pkill -9 -f sing-box; pkill -9 -f w_master; pkill -9 -f sl
bash <(curl -sSL https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh) un >/dev/null 2>&1
rm -rf /etc/s-box /usr/local/bin/warp-go /usr/bin/warp-go
rm -f /usr/bin/s[1-3] /usr/bin/l[1-3] /usr/bin/sl[1-3] /usr/bin/c /usr/bin/ss
crontab -l 2>/dev/null | grep -v "stability.log" | crontab -
echo -e "\033[1;32m🎉 物理超度完毕！VPS 已恢复纯净状态！\033[0m"
rm -f /usr/bin/u
EOF
chmod +x /usr/bin/u

# 11. 凌晨 4 点重启任务 (🚨 核心修复：每天覆盖写入，绝不膨胀)
(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，开启新史记 ===\" > /etc/s-box/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网系统 V10.10 (纯净版) 部署完毕！指令：c (大盘) | ss (实时) | u (卸载)\033[0m"

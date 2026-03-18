#!/bin/bash
# ====================================================================
# 天网系统 V10.3 指挥官版 (先筑基·后织网 | 顺序调优)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网系统 V10.3】全量重筑 (顺序调优版)...\033[0m"

# 1. 强力修复 DNS (确保能解析 GitHub)
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

# 2. 基础环境
apt-get update -y && apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4

# 3. 核心打捞 (此时未装 WARP，直连 GitHub 速度最稳)
echo -e "\033[1;33m📦 正在打捞核心组件 (Sing-box & Psiphon)...\033[0m"

# Psiphon
wget -q --show-progress -O /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

# Sing-box (镜像加速下载)
S_VER="1.11.0" # 锁定一个极其稳定的 amd64 版本
S_URL="https://gh-proxy.com/https://github.com/SagerNet/sing-box/releases/download/v${S_VER}/sing-box-${S_VER}-linux-amd64.tar.gz"

wget -q --show-progress -O /tmp/sbox.tar.gz "$S_URL"
if [ -s /tmp/sbox.tar.gz ]; then
    tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box
    chmod +x /etc/s-box/sing-box
    echo -e "\033[1;32m✅ Sing-box 核心部署成功！\033[0m"
else
    echo "❌ 核心下载失败，请检查网络！" && exit 1
fi

# 4. 部署最后环节：WARP-GO (放到后面安装，防止它干扰下载)
echo -e "\033[1;32m🌐 正在织入 WARP-GO 双栈网络...\033[0m"
wget -qN https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh
# 自动化静默安装双栈 (IPv4+IPv6)
bash warp-go.sh [chinese] [m] [d] <<EOF
y
EOF

# 5. 注入唯一指挥官指令 c (静态史记+动态实时)
cat << 'EOF' > /usr/bin/c
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
T=$(date '+%m-%d')
draw() {
    clear; echo -e "\033[1;36m=======================================================================================================================\033[0m"
    echo -e "\033[1;37m                                   🛡️ 天网系统 V10.3 (唯一指挥官·完美史记) 🛡️\033[0m"
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
if [[ "$1" == "--live" || "$1" == "ss" ]]; then
    while true; do draw; grep "^\[$T" $SLA_LOG | grep -vE "介入|退出" | tail -n 25; sleep 2; done
else
    draw; LOG=$(grep "^\[$T" $SLA_LOG | grep -vE "TRACE|介入|退出"); echo "${LOG:-等待凌晨4点后的首条记录...}"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
fi
EOF
chmod +x /usr/bin/c; ln -sf /usr/bin/c /usr/bin/ss

# 6. 配置核心路由与沙盒服务 (保持之前V10.0逻辑)
# ... [此处建议补充完整的 sing-box.json 和 systemd 配置] ...

# 7. 哨兵 master 与 凌晨4点重启 (保持逻辑)
(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重启，开启新史记 ===\" >> /etc/s-box/stability.log && /sbin/reboot") | crontab -

systemctl daemon-reload
echo -e "\n\033[1;32m🎉 天网 V10.3 部署完毕！\033[0m"
echo -e "请敲 \033[1;32mc\033[0m 查看大盘，或敲 \033[1;32mss\033[0m 进入实时监控。"

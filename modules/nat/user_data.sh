#!/bin/bash
set -eux

# =========================
# 1. 네트워크 준비 대기
# =========================
sleep 10

# =========================
# 2. IP Forwarding 활성화
# =========================
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-nat.conf
sysctl -p /etc/sysctl.d/99-nat.conf

# =========================
# 3. 외부 인터페이스 자동 감지
# =========================
EXT_IF=$(ip route | awk '/default/ {print $5}')

# =========================
# 4. iptables NAT 설정
# =========================
iptables -t nat -F
iptables -F

iptables -t nat -A POSTROUTING -o ${EXT_IF} -j MASQUERADE
iptables -A FORWARD -i ${EXT_IF} -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o ${EXT_IF} -j ACCEPT

# =========================
# 5. 규칙 영구 저장
# =========================
apt-get update -y
apt-get install -y iptables-persistent netfilter-persistent

iptables-save > /etc/iptables/rules.v4
systemctl enable netfilter-persistent
systemctl restart netfilter-persistent


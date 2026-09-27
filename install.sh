#!/bin/bash
set -e

PORT=8443
SNI="speed.cloudflare.com"
PATH_X="/xray"

UUID=$(xray uuid)
KEYS=$(xray x25519)
PRIVATE=$(echo "$KEYS" | awk '/PrivateKey:/ {print $2}')
PUBLIC=$(echo "$KEYS" | awk '/Password \(PublicKey\):/ {print $2}')
SHORTID=$(openssl rand -hex 8)

mkdir -p /usr/local/etc/xray

cat > /usr/local/etc/xray/config.json «EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$SNI:443",
          "serverNames": [
            "$SNI"
          ],
          "privateKey": "$PRIVATE",
          "shortIds": [
            "$SHORTID"
          ]
        },
        "xhttpSettings": {
          "path": "$PATH_X",
          "mode": "stream-one"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

xray run -test -config /usr/local/etc/xray/config.json

systemctl restart xray
systemctl enable xray

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    ufw allow $PORT/tcp
fi

echo
echo "===== XRAY READY ====="
echo "Address: 213.193.197.61"
echo "Port: $PORT"
echo "UUID: $UUID"
echo "PublicKey: $PUBLIC"
echo "ShortID: $SHORTID"
echo "SNI: $SNI"
echo "Path: $PATH_X"
echo "======================"

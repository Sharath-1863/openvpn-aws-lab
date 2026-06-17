#!/bin/bash

USER_NAME="$1"

EASYRSA_DIR="/home/ubuntu/openvpn-ca"
CLIENT_DIR="/home/ubuntu/client-configs"

PUBLIC_IP=$(curl -s checkip.amazonaws.com)

if [ -z "$USER_NAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 2
fi

if [ -z "$PUBLIC_IP" ]; then
    echo "Unable to determine public IP"
    exit 3
fi

for file in \
    "$EASYRSA_DIR/pki/ca.crt" \
    "$EASYRSA_DIR/pki/private/ca.key" \
    "$EASYRSA_DIR/ta.key"
do
    if [ ! -f "$file" ]; then
        echo "Missing required file: $file"
        exit 4
    fi
done

mkdir -p "${CLIENT_DIR}/${USER_NAME}"

cd "$EASYRSA_DIR" || exit 1

if [ -f "pki/issued/${USER_NAME}.crt" ]; then
    echo ""
    echo "User '${USER_NAME}' already exists."
    echo ""
    exit 5
fi

echo ""
echo "==========================================="
echo "Creating VPN User: ${USER_NAME}"
echo "Server Public IP: ${PUBLIC_IP}"
echo "==========================================="
echo ""

./easyrsa gen-req "${USER_NAME}" nopass

./easyrsa sign-req client "${USER_NAME}"

cat > "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn" <<EOF
client
dev tun
proto udp

remote ${PUBLIC_IP} 1194

resolv-retry infinite
nobind

persist-key
persist-tun

remote-cert-tls server

cipher AES-256-GCM
auth SHA256

key-direction 1

verb 3
EOF

echo "<ca>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
cat "${EASYRSA_DIR}/pki/ca.crt" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
echo "</ca>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"

echo "<cert>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' "${EASYRSA_DIR}/pki/issued/${USER_NAME}.crt" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
echo "</cert>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"

echo "<key>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
cat "${EASYRSA_DIR}/pki/private/${USER_NAME}.key" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
echo "</key>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"

echo "<tls-auth>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
cat "${EASYRSA_DIR}/ta.key" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
echo "</tls-auth>" >> "${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"

cd "${CLIENT_DIR}" || exit 1

tar czf "${USER_NAME}.tar.gz" "${USER_NAME}"

echo ""
echo "==========================================="
echo "VPN User Created Successfully"
echo "==========================================="
echo "Username    : ${USER_NAME}"
echo "Public IP   : ${PUBLIC_IP}"
echo "OVPN File   : ${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn"
echo "Archive     : ${CLIENT_DIR}/${USER_NAME}.tar.gz"
echo ""
echo "Download OVPN:"
echo "scp ubuntu@${PUBLIC_IP}:${CLIENT_DIR}/${USER_NAME}/${USER_NAME}.ovpn ."
echo "==========================================="
echo ""

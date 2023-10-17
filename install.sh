#!/bin/bash

. ./lib/debug.sh
. ./lib/utils.sh

function install_wireguard()
{
	apt-get install libmnl-dev libelf-dev linux-headers-$(uname -r) build-essential pkg-config git iptables resolvconf -y
	cd WireGuard/src
	make && make install
	[ $? -ne 0 ] && red_echo "Failed to install_wireguard" && exit 1
	green_echo "Succeed to install wireguard"
	exit 0
}

function create_key()
{
	local obj=$1
	cd /etc/wireguard
	wg genkey | tee ${obj}_prikey | wg pubkey > ${obj}_pubkey
	cd - &>/dev/null
}

wg_cfg_file="/etc/wireguard/wg0.conf"

function create_wg0()
{
	local file=$wg_cfg_file
	[ -f $file ] && return
	create_key srv
	srv_prikey=$(cat /etc/wireguard/srv_prikey)
	cat >  $file << EOF
[Interface]
PrivateKey = ${srv_prikey}
Address = 10.10.10.1/24
ListenPort = 54321
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF
}

function qrencode_show()
{
	local file=$1
	
	[ -f $file ] || (echo "Failed to qrencode_show : \"$file\" is not exist" && return 1)
	which qrencode &>/dev/null
	if [ $? -ne 0 ]; then
		apt install qrencode -y &>/dev/null
	fi
	cat $file | qrencode -t UTF8
}

function _add_user()
{
	local file=$wg_cfg_file
	local username=$1

	while true
	do
		nb=$(($(echo ${RANDOM})%100))
		ips="10.10.10.${nb}"
		grep ${ips} $file &>/dev/null
		[ $? -ne 0 ] && break;
	done

	create_key cli
	cli_prikey=$(cat /etc/wireguard/cli_prikey)
	cli_pubkey=$(cat /etc/wireguard/cli_pubkey)

	cat >> $file << EOF

[Peer]
PublicKey = ${cli_pubkey}
AllowedIPs = ${ips}/32
EOF
	srv_pubkey=$(cat /etc/wireguard/srv_pubkey)
	port=$(awk '/ListenPort/{print $3}' $wg_cfg_file)
	srv_ip=$( ip addr | grep "eth0" -A 4 | awk '/\<inet\>/{print $2}' | awk -F/ '{print $1}')

	cat > ${username}.conf << EOF
[Interface]
PrivateKey = ${cli_prikey}
Address = ${ips}/24
DNS = 8.8.8.8
MTU = 1420

[Peer]
PublicKey = ${srv_pubkey}
Endpoint = ${srv_ip}:${port}
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25
EOF

	qrencode_show ${username}.conf
}

function add_user()
{
	read -p "input username " username
	create_wg0
	_add_user $username
}

function restart_wireguard()
{
	echo 1 > /proc/sys/net/ipv4/ip_forward
	wg-quick down wg0 &>/dev/null
	wg-quick up wg0 &>/dev/null
	if [ $? -ne 0 ]; then 
		red_echo "Failed to restart wireguard"
		exit 1
	fi
	green_echo "Succeed to restart wireguard"
}

function change_port()
{
	local old_port	
	local new_port
	old_port=$(awk '/ListenPort/{print $3}' $wg_cfg_file)

	while true
	do
		new_port=$(($(echo ${RANDOM})%8964))
		[ $new_port -ne $old_port ] && break;
	done

	sed -i "/ListenPort/s/${old_port}/${new_port}/" $wg_cfg_file &>/dev/null
	green_echo "New port : $new_port"
}

ensure_root
get_sysinfo
echo $OS
echo $VERSION

if [ "$1" == "-c" ]; then
change_port
restart_wireguard
	exit 0
fi

which gawk || \
	apt install gawk -y &>/dev/null

while true
do
	clear
	green_echo "For wireguard."
	red_echo "1) Install wireguard"
	yellow_echo "2) Add user"
	red_echo "3) Change port"
	yellow_echo "4) Quit"

	read -p "input choice : " ch
	case $ch in
		1)
			install_wireguard
			;;
		2)
			add_user
			restart_wireguard
			exit 0
			;;
		3)
			change_port
			restart_wireguard
			exit 0
			;;
		4)
			echo "Bye.."
			exit 0
			;;
		*)
			read -p"Error input, try again" ch
			;;
	esac
done

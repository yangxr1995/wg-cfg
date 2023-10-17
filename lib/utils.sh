#!/bin/echo "This is utils lib for bash, can't execute !"

function red_echo()
{
	echo -e "\e[31m ${1} \e[0m"
}

function green_echo()
{
	echo -e "\e[32m ${1} \e[0m"
}

function yellow_echo()
{
	echo -e "\e[33m ${1} \e[0m"
}

function blue_echo()
{
	echo -e "\e[34m ${1} \e[0m"
}

function get_sysinfo()
{
	local release_file="/etc/os-release"

	[ -f $release_file ] || \
		( echo "Cant get sysinfo : \"${release_file}\" not exist"  \
			&& exit 1 )

	for OS in ubuntu centos
	do
		grep -i ${OS} ${release_file} &>/dev/null
		[ $? -eq 0 ] && break
		OS="null"
	done

	for VERSION in "16" "20" "6" "7"
	do
		grep "${VERSION}\.[0-9]*" ${release_file} &>/dev/null
		[ $? -eq 0 ] && break
		VERSION="null"
	done

	if [ "$OS" == "null" -o "VERSION" == "null" ]; then
		echo "Cant get sysinfo"
		exit 1
	fi
}

function ensure_root()
{
	if [ $UID -ne 0 ]; then
		echo "Must be root"
		exit 1
	fi
}

#!/bin/echo "This is debug lib for bash, can't execute !"

function debug()
{
	if [ "$DEBUG" == "true" ]; then
		if [ "$1" == "on" ]; then
			set -x
		elif [ "$1" == "off" ]; then
			set +x
		fi
	fi
}

function DEBUG()
{
	if [ "$DEBUG" == "true" ]; then	
		$@
	fi
}

function ERRTRAP()
{
	echo "[LINE : $1] Error : Command or function exited with status $?"
}

function StartTimer()
{
    Interval=${1:-10}
    if [ ${Interval} -gt 0 ]; then
        (sleep $Interval && kill -14 $$) &
        TimerPID=$!
		DEBUG echo "Start timer : mypid : $$, timerpid : $TimerPID"
    else
        echo "Error Interval must be postive"
    fi
}

function CloseTimer()
{
	kill -0 $TimerPID 2>/dev/null && kill $TimerPID 
	DEBUG echo "Close timer : kill $TimerPID"
}

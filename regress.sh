#!/bin/sh
TN=test2

function runit {
	local _exp=$1; shift
	local _cmd=$*
	local _tf=`mktemp tmp.XXXXXXX || exit 1`
	local _rc
	echo -n "Running Command: '$_cmd' "
	$_cmd >$_tf 2>&1
	_rc=$?
	if [ $_rc -ne $_exp ]; then
		echo "Error"
		echo "Expecting $_exp Got $_rc"
		echo "Output:"
		cat $_tf
		rm -f $_tf
		exit 1
	fi
	echo "Success"
	rm -f $_tf
}

function testit {
	local _exp=$1; shift
	local _command=$*
	local _tf=`mktemp tmp.XXXXXXX || exit 1`
	cmd >$_tf 2>&1
	if [ "$_exp" != $_out ]; then
		echo "Error running command:"
		echo "$_cmd"
		echo "Expected: $_exp"
		echo -n "Got:"
		cat $_tf
		rm -f $_tf
		exit 1
	fi
	rm -f $_tf

}

runit 0 pca $TN init
runit 1 pca $TN init

runit 0 pca $TN list macros
runit 0 pca $TN list policy
runit 0 pca $TN list extension

#runit 0 pca $TN create root -days 10 -bits 1024
#runit 0 pca $TN show root
#runit 0 pca $TN create req -name cloudy -newkey -days 5 -cn cloudy.example.com -ct NoTown -sp NoWhere -co XX -or ACME -ou Enigma -em bitbucket@example.com -san DNS:partlycloudy.example.com


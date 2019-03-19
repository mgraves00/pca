#!/bin/sh
TN=test2

TMPNAM=regress-tmp
function die {
	local _rc=$1; shift
	local _msg=$*
	echo $_msg >&2
	rm -f $TMPNAM.*
	exit $_rc
}

function runit {
	local _exp=$1; shift
	local _cmd=$*
	local _tf=`mktemp $TMPNAM.XXXXXX || die 1 "runit: mktemp"`
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
		die 1 ""
	fi
	echo "Success"
	rm -f $_tf
}

function testit {
	local _exp=$1; shift
	local _cmd=$*
	local _tf=`mktemp $TMPNAM.XXXXXXX || die 1 "testit: mktemp"`
	local _rc
	echo -n "Testing Command: '$_cmd' "
	$_cmd >$_tf 2>&1
	_rc=$?
	if [ $_rc -ne 0 ]; then
		echo "Error"
		echo "Command exited with $_rc"
		echo "Output:"
		cat $_tf
		rm -f $_tf
		die 1 ""
	fi
	_out=`cat $_tf`
	if [ "$_exp" != "$_out" ]; then
		echo "Error"
		echo "Expecting $_exp"
		echo "Got       $_out"
		rm -f $_tf
		die 1 ""
	fi
	echo "Success"
	rm -f $_tf
}

# clean up from last failure
#rm -rf .$TN.ca

runit 0 pca $TN init
runit 1 pca $TN init

runit 0 pca $TN config list macros
runit 0 pca $TN config list policy
runit 0 pca $TN config list extension

# macro / policy / extension all use the same function
testit "CAHOME=$HOME/.pca/$TN" pca $TN config get macro -key CAHOME
testit "$HOME/.pca/$TN" pca $TN config get macro -key CAHOME -value
testit "TEST10=10" pca $TN config set macro -a -key TEST10 -value 10
testit "TEST10=11" pca $TN config set macro -key TEST10 -value 11
testit "" pca $TN config set macro -d -key TEST10
testit "" pca $TN config get macro -key TEST10

# create a root cert
runit 0 pca $TN create root -days 10 -bits 1024 -or "testCA"
runit 0 pca $TN show root
testit "root-test2.crt: subject= /O=testCA" pca $TN show root -subject

# create a request
runit 0 pca $TN create req -name sunny -newkey 512 -days 5 -cn sunny.example.com -or "testCA" -san DNS=bright.example.com
testit "sunny: subject=/O=testCA/CN=sunny.example.com" pca $TN show req -name sunny
runit 0 pca $TN sign -name sunny
runit 0 pca $TN show cert -name sunny
runit 0 pca $TN show cert -name sunny -subject
runit 0 pca $TN show cert -name sunny -expire
runit 0 pca $TN show cert -name sunny -subjecthash
runit 0 pca $TN show cert -name sunny -issuer
runit 0 pca $TN show cert -name sunny -issuerhash

# export PKCS12
_of=`mktemp $TMPNAM.XXXXXXX || die 1 "mktemp"`
runit 1 pca $TN export pkcs12 -name sunny -pass "letmein" -file $_of
runit 0 pca $TN export pkcs12 -name sunny -pass "letmein" -file $_of -overwrite
_tf=`mktemp $TMPNAM.XXXXXXX || die 1 "mktemp"`
echo "letmein" > $_tf
runit 0 pca $TN export pkcs12 -name sunny -pass file:$_tf -file $_of -overwrite
runit 0 'echo "letemin" | pca '$TN export pkcs12 -name sunny -pass -  -overwrite

# test CRL
runit 0 pca $TN create crl
runit 0 pca $TN show crl
runit 0 pca $TN show crl -issuer
runit 0 pca $TN show crl -hash
runit 0 pca $TN show crl -fingerprint
runit 0 pca $TN show crl -num
runit 0 pca $TN show crl -last
runit 0 pca $TN show crl -next

# revoke cert
runit 0 pca $TN revoke -name sunny
# refresh crl
runit 0 pca $TN create crl
runit 0 pca $TN show crl

# cleanup sunny
runit 1 pca $TN delete req
runit 0 pca $TN delete req -name sunny
runit 0 pca $TN delete key -name sunny
runit 0 pca $TN delete cert -name sunny
testit "" pca $TN show cert -subject
testit "" pca $TN show req


# work on req options
runit 0 pca $TN create req -name cloudy -newkey 512 -days 5 -cn cloudy.example.com -or "testCA" -ou "testDiv" -ct NoPlace -sp NoWhere -co XX -em bitbucket@cloudy.example.com -san DNS=sad.example.com
testit "cloudy: subject=/C=XX/ST=NoWhere/L=NoPlace/O=testCA/OU=testDiv/CN=cloudy.example.com/emailAddress=bitbucket@cloudy.example.com" pca $TN show req -name cloudy
runit 0 pca $TN sign -name cloudy -sign
testit "CA:TRUE,pathlen:1" pca $TN 'show cert -name cloudy | egrep "CA:[TF][RA]" | tr -d " "'


die 0 "Complete Success"

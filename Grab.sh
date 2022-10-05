#!/bin/bash 

echo "Grab Version"


#curl -s  -I "https://plex.tv/downloads/latest/1?channel=16&build=linux-ubuntu-x86_64&distro=ubuntu&X-Plex-Token="

# Ubuntu / Debian (Intel / AMD 64Bit)
# Ubuntu / Debian (Intel / AMD 32Bit)
# Ubuntu / Debian (ARMv8)
# Ubuntu / Debian (ARMv7)
# Fedora / CentOS / SUSE (32bit)
# Fedora / CentOS / SUSE (64bit)
# Windows
# Mac
# FreeBSD

JSONTMP=/tmp/5.json
JSONFILE=./json/5.json
#echo $JSONFILE

echo "curl -w httpcode=%{http_code} -s https://plex.tv/api/downloads/5.json --output $JSONTMP 2> /dev/null"

#url for media server builds
CURL_RETURN_CODE=0
CURL_OUTPUT=`curl -w httpcode=%{http_code} -s https://plex.tv/api/downloads/5.json --output $JSONTMP 2> /dev/null` || CURL_RETURN_CODE=$?

if [ ${CURL_RETURN_CODE} -ne 0 ]; then  
    echo "Curl connection failed with return code - ${CURL_RETURN_CODE}"
    exit
else
    echo "Curl connection success"
    # Check http code for curl operation/response in  CURL_OUTPUT
    httpCode=$(echo "${CURL_OUTPUT}" | sed -e 's/.*\httpcode=//')

    if [ ${httpCode} -ne 200 ]; then
        echo "Curl operation/command failed due to server return code - ${httpCode}"
        exit
    fi
fi


LST=( 
	linux-x86_64.debian
	linux-x86.debian
	linux-aarch64.debian
	linux-armv7neon.debian
	linux-x86.redhat
	linux-x86_64.redhat
	windows-x86.windows
	darwin-x86_64.macos
	freebsd-x86_64.freebsd )

NAS=( 
	linux-x86_64.qnap
	linux-aarch64.qnap
	linux-armv7hf.qnap
	linux-armv7neon.qnap
)

VERSION=$(cat $JSONTMP|jq -r '.computer.Linux|.version')
echo "checkmark 1"

if [ $? != 0 ] 
then
 echo "[3;31mError parsing json[0m"
 exit
fi

cp $JSONTMP $JSONFILE

grep $VERSION README.md >/dev/null
if [ $? == 0 ] 
then
 echo "[3;31mAlready in Readme[0m"
 exit
fi

echo "[1;33mAdding $VERSION[0m"

old_ifs="$IFS"

for a in ${LST[@]}
do
IFS="."
read build distrib <<< "$a"

echo "Search $build for $distrib"
URL=$(cat "$JSONTMP"|jq --arg BUILD "$build" --arg DISTRO "$distrib"  -r '.computer[]|.releases[]|select(.build==$BUILD and .distro==$DISTRO)|.url')

sed -i "/# $a/a \\\n$URL"  README.md

done

# reset IFS for loop
IFS="$old_ifs"

for a in ${NAS[@]}
do
IFS="."
read build distrib <<< "$a"

echo "Search $build for $distrib"
URL=$(cat "$JSONTMP"|jq --arg BUILD "$build" --arg DISTRO "$distrib"  -r '.nas[]|.releases[]|select(.build==$BUILD and .distro==$DISTRO)|.url')

sed -i "/# $a/a \\\n$URL"  README.md

done

#rm $JSONFILE

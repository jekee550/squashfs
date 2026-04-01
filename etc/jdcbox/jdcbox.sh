#!/bin/sh
NAME='jdcbox'
PLATFORM=$(uname -m 2>/dev/null)
if [ -z "$PLATFORM" ]; then
	echo "PLATFORM is NULL"
	exit 1
fi
if [ -n "$(cat /proc/mounts | grep -w /opt)" ]; then
	MOUNTED='/opt'
else
	MOUNTED='/tmp'
fi

CMD="$MOUNTED/$NAME/$NAME"
MD5="$MOUNTED/$NAME/$NAME.md5"
DIR="$MOUNTED/$NAME/"

install_cdn() {
	CDN='https://jdcnode.jdcloud.com'
	KEY='7da26364556500f12df3'
	UNIQID='0'
	RAND=$(date +%s)
	EXPIRE=$((RAND + 3600))
	echo "$NAME $CDN Install"
	for I in 1 2 3 4 5; do
		echo "$NAME $CDN Downlaod $I"
		SIGNATURE=$(echo -n "/release/${NAME}_md5sum-$EXPIRE-$UNIQID-$RAND-$KEY" | md5sum | awk '{print$1}')
		if curl --retry 3 -s -o "$MD5" "$CDN/release/${NAME}_md5sum?auth_token=$EXPIRE-$UNIQID-$RAND-$SIGNATURE"; then
			echo "$NAME $CDN Downlaod $MD5 Done $I"
			MD5SUM=$(cat "$MD5" | grep -w "${NAME}_$PLATFORM" | awk '{print$1}')
		else
			echo "$NAME $CDN Downlaod $MD5 Failed $I"
		fi
		CHECKSUM=$(md5sum "$CMD" 2>/dev/null | awk '{print$1}')
		if [ -n "$CHECKSUM" ] && [ -n "$MD5SUM" ] && [ "$CHECKSUM" = "$MD5SUM" ]; then
			chmod +x "$CMD" && echo "$NAME $CDN Check Done"
			return 0
		fi
		SIGNATURE=$(echo -n "/release/${NAME}_$PLATFORM-$EXPIRE-$UNIQID-$RAND-$KEY" | md5sum | awk '{print$1}')
		if curl --retry 3 -s -o "$CMD" "$CDN/release/${NAME}_$PLATFORM?auth_token=$EXPIRE-$UNIQID-$RAND-$SIGNATURE"; then
			echo "$NAME $CDN Downlaod $NAME Done $I"
			CHECKSUM=$(md5sum "$CMD" 2>/dev/null | awk '{print$1}')
		else
			echo "$NAME $CDN Downlaod $NAME Failed $I"
		fi
		if [ -n "$CHECKSUM" ] && [ -n "$MD5SUM" ] && [ "$CHECKSUM" = "$MD5SUM" ]; then
			chmod +x "$CMD" && echo "$NAME $CDN Check Done"
			return 0
		else
			echo "$NAME Check Failed $I"
			echo "$NAME Download After $((10 * I))s"
			sleep $((10 * I))
		fi
	done
	return 1
}

install_src() {
	SRC=$1
	MODE=$2
	echo "$NAME $SRC Install $MODE"
	if curl "$MODE" --retry 3 -s -o "$MD5" "$SRC/release/${NAME}_md5sum"; then
		echo "$NAME $SRC $MD5 Done"
		MD5SUM=$(cat "$MD5" | grep -w "${NAME}_$PLATFORM" | awk '{print$1}')
	else
		echo "$NAME $SRC $MD5 Failed"
	fi
	if curl "$MODE" --retry 3 -s -o "$CMD" "$SRC/release/${NAME}_$PLATFORM"; then
		echo "$NAME $NAME $SRC Done"
		CHECKSUM=$(md5sum "$CMD" 2>/dev/null | awk '{print$1}')
	else
		echo "$NAME $NAME $SRC Failed"
	fi
	if [ -n "$CHECKSUM" ] && [ -n "$MD5SUM" ] && [ "$CHECKSUM" = "$MD5SUM" ]; then
		chmod +x "$CMD" && echo "$NAME $SRC Check Done"
		return 0
	else
		echo "$NAME $SRC Check Failed"
		return 1
	fi
}

init() {
	echo "$NAME Init"
	mkdir -p "$DIR"
	if install_cdn; then
		return 0
	else
		if install_src 'http://[2402:db40:5f00:d500:5cf:7098:925f:bcdf]' '-6'; then
			return 0
		fi
		if install_src 'http://[2402:db40:5f00:d500:5cf:7098:925f:bcdf]:8080' '-6'; then
			return 0
		fi
		if install_src 'http://116.196.72.5' '-4'; then
			return 0
		fi
		if install_src 'http://116.196.72.5:8080' '-4'; then
			return 0
		fi
	fi
	rm -rf "$CMD"
	rm -rf "$MD5"
	return 1
}

while true; do
	if init; then
		echo "$NAME Start"
		"$CMD" "$@"
	fi
	sleep 10
done


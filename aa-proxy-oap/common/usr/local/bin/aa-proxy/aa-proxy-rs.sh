#!/bin/sh
#
# Start aa-proxy-rs daemon
#
# For documentation and command line parameters go to:
# https://github.com/manio/aa-proxy-rs

DAEMON="aa-proxy-rs"
DAEMONPATH="/usr/local/bin/aa-proxy"
PIDFILE="/var/run/$DAEMON.pid"
AA_PROXY_RS_ARGS="-b NaviPi --hostapd-conf /etc/hostapd/hostapd.conf -k"

RETVAL=0

case "$1" in
	start)
		printf "Starting $DAEMON: "
		start-stop-daemon -S -b -q -m -p "$PIDFILE" -x "$DAEMONPATH/$DAEMON" -- $AA_PROXY_RS_ARGS
		RETVAL=$?
		[ $RETVAL = 0 ] && echo "OK" || echo "FAIL"
		;;
	stop)
		printf "Stopping $DAEMON: "
		start-stop-daemon -K -q -p "$PIDFILE"
		RETVAL=$?
		[ $RETVAL = 0 ] && echo "OK" || echo "FAIL"
		;;
	restart)
		$0 stop
		$0 start
		;;
	*)
		echo "Usage: $0 {start|stop}"
		;;
esac

exit $RETVAL

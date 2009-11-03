#! /bin/sh
#
# mongrel init.d script
#

DESC="mongrel servers"
NAME=mongrel
DAEMON=/var/lib/gems/1.8/bin//mongrel_rails
SCRIPTNAME=/etc/init.d/$NAME

test -x $DAEMON || exit 0

# configuration 
# don't change here, override in /etc/default/mongrel instead
USER=www-data
CONFIG_BASE=/etc/mongrel/sites-enabled
DEFAULT_CONFIG=/etc/mongrel/default
PIDS_DIR=/var/run/mongrel
LOGS_DIR=/var/log/mongrel
LS=/bin/ls

# Read config file if it is present.
if [ -r $DEFAULT_CONFIG ]
then
  . $DEFAULT_CONFIG
fi

set -e

# do the work for each config file in the mongrel dir
COUNTER=0
for a_conf in `$LS $CONFIG_BASE/`; do
	case "$1" in
		start)
			echo -n "Starting $DESC: "
			DAEMON_OPTS="start -c $CONFIG_BASE/$a_conf"
			start-stop-daemon --start --quiet --pidfile $PIDS_DIR/mongrel_$COUNTER.pid \
												--exec $DAEMON -- $DAEMON_OPTS \
												-P $PIDS_DIR/mongrel_$COUNTER.pid \
												-l $LOGS_DIR/mongrel_$COUNTER.log \
												--user $USER
			echo "$NAME $COUNTER."
			;;
		stop)
			echo -n "Stopping $DESC: "
			start-stop-daemon --stop --quiet --pidfile $PIDS_DIR/mongrel_$COUNTER.pid \
							--exec $DAEMON
			echo "$NAME $COUNTER."
		;;
		restart|force-reload)
			echo -n "Restarting $DESC: "
			start-stop-daemon --stop --quiet --pidfile $PIDS_DIR/mongrel_$COUNTER.pid\
												--exec $DAEMON
			sleep 1
			start-stop-daemon --start --quiet --pidfile $PIDS_DIR/mongrel_$COUNTER.pid \
												--exec $DAEMON -- $DAEMON_OPTS \
												-P $PIDS_DIR/mongrel_$COUNTER.pid \
												-l $LOGS_DIR/mongrel_$COUNTER.log \
												--user $USER
			echo "$NAME $COUNTER."
		;;
		reload)
			echo -n "Reloading $DESC configuration: "
			start-stop-daemon --stop --signal HUP --quiet 
												--pidfile $PIDS_DIR/mongrel_$COUNTER.pid \
												--exec $DAEMON
			echo "$NAME $COUNTER."
		;;
		*)
			N=/etc/init.d/$NAME
			echo "Usage: $N {start|stop|restart|force-reload}" >&2
			exit 1
		;;
	esac
	let COUNTER=COUNTER+1
done


exit 0

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
for a_conf in `$LS $CONFIG_BASE`; do
	case "$1" in
		start)
			echo -n "Starting $DESC: "
			$DAEMON start -d -C $CONFIG_BASE/$a_conf \
												-P $PIDS_DIR/mongrel_$COUNTER.pid \
												-l $LOGS_DIR/mongrel_$COUNTER.log \
												--user $USER --group $USER
			echo "$NAME $COUNTER."
			;;
		stop)
			echo -n "Stopping $DESC: "
			$DAEMON stop -P $PIDS_DIR/mongrel_$COUNTER.pid
			echo "$NAME $COUNTER."
		;;
		restart|force-reload|reload)
			echo -n "Restarting $DESC: "
			DAEMON_OPTS="start -C $CONFIG_BASE/$a_conf"
			$DAEMON stop -P $PIDS_DIR/mongrel_$COUNTER.pid
			sleep 1
			$DAEMON start -d -C $CONFIG_BASE/$a_conf \
												-P $PIDS_DIR/mongrel_$COUNTER.pid \
												-l $LOGS_DIR/mongrel_$COUNTER.log \
												--user $USER --group $USER
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

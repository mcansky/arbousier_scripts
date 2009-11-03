#! /bin/sh
#
# skeleton	example file to build /etc/init.d/ scripts.
#		This file should be used to construct scripts for /etc/init.d.
#
#		Written by Miquel van Smoorenburg <miquels@cistron.nl>.
#		Modified for Debian 
#		by Ian Murdock <imurdock@gnu.ai.mit.edu>.
#
# Version:	@(#)skeleton  1.9  26-Feb-2001  miquels@cistron.nl
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

# Read config file if it is present.
if [ -r /etc/default/mongrel ]
then
  . /etc/default/mongrel
fi

set -e

# run the command

case "$1" in
  start)
        echo -n "Starting $DESC: "
        start-stop-daemon --start --quiet --pidfile /usr/local/nginx/logs/nginx.pid \
                --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon --stop --quiet --pidfile /usr/local/nginx/logs/nginx.pid \
                --exec $DAEMON
        echo "$NAME."
        ;;
  restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon --stop --quiet --pidfile \
                /usr/local/nginx/logs/nginx.pid --exec $DAEMON
        sleep 1
        start-stop-daemon --start --quiet --pidfile \
                /usr/local/nginx/logs/nginx.pid --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  reload)
      echo -n "Reloading $DESC configuration: "
      start-stop-daemon --stop --signal HUP --quiet --pidfile /usr/local/nginx/logs/nginx.pid \
          --exec $DAEMON
      echo "$NAME."
      ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

# run the given command ($2, {start|stop|reload}) for the given app ($1)
for_app() {
  echo -n $1
  DAEMON_OPTS="start -e ${environment} -a 127.0.0.1 -c $dir"
	if [ ! -z "$prefix" ]; then
		DAEMON_OPTS="$DAEMON_OPTS --prefix=$prefix"
	fi
  last_port=$(( $port + $servers - 1 ))
  case "$2" in
    start|reload)
      for p in `seq $port $last_port`; do
        pidfile="/var/run/$NAME.$1.$p.pid"
        case "$2" in
          start)
            start-stop-daemon --start --background --chuid $USER --make-pidfile --pidfile $pidfile --exec $DAEMON -- $DAEMON_OPTS -p $p
          ;;
          reload)
            SIGUSR2=12
            start-stop-daemon --stop --signal $SIGUSR2 --quiet --pidfile $pidfile  || echo "couldn't reload process $pidfile"
          ;;
        esac
      done
      ;;
    stop)
      for pidfile in `ls /var/run/$NAME.$1.*.pid`; do
        (start-stop-daemon --stop --quiet --pidfile $pidfile || kill -9 `cat $pidfile` || echo "couldn't kill process $pidfile (`cat $pidfile`), removing pid file anyway") && rm -f $pidfile
      done
      ;;
  esac
  echo "."
}

# run the given command ('stop' or 'start') for each app configured
# in /etc/mongrel_cluster
each_app() {
  for app in `ls $CONFIG_BASE/`; do
    for_app $app $1
  done
}

# runs given command ($1) for the given app ($2) or all apps, 
# if $2 is not given
run_command() {
  if [ "x$2" = "x" ]
  then
    # no site given
    each_app $1
  else
    for_app $2 $1
  fi
}


case "$1" in
  start)
  echo "Starting $DESC: $NAME"
  run_command 'start' $2
  echo "."
  ;;
  stop)
  echo "Stopping $DESC: $NAME"
  run_command 'stop' $2  
  echo "."
  ;;
  reload)
  echo "Reloading $DESC: $NAME"
  run_command 'reload' $2  
  echo "."
  ;;
  restart|force-reload)
  #
  #  If the "reload" option is implemented, move the "force-reload"
  #  option to the "reload" entry above. If not, "force-reload" is
  #  just the same as "restart".
  #
  echo "Restarting $DESC: $NAME"
  run_command 'stop' $2
  sleep 1
  run_command 'start' $2
  echo "."
  ;;
  *)
  # echo "Usage: $SCRIPTNAME {start|stop|reload|restart}" >&2
  echo "Usage: $SCRIPTNAME {start|stop|reload|restart}" >&2
  exit 1
  ;;
esac

exit 0

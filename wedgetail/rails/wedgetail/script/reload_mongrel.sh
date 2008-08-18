#!/bin/sh
kill `cat tmp/pids/mongrel.8000.pid`
kill `cat tmp/pids/mongrel.8001.pid`
kill `cat tmp/pids/mongrel.8002.pid`
/usr/bin/ruby1.8 /usr/bin/mongrel_rails start -d -e development -p 8000 -P tmp/pids/mongrel.8000.pid -l log/mongrel.8000.log
/usr/bin/ruby1.8 /usr/bin/mongrel_rails start -d -e development -p 8001 -P tmp/pids/mongrel.8001.pid -l log/mongrel.8001.log
/usr/bin/ruby1.8 /usr/bin/mongrel_rails start -d -e development -p 8002 -P tmp/pids/mongrel.8002.pid -l log/mongrel.8002.log

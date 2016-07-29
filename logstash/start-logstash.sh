#!/bin/sh
#  run logstash, config is in *.conf, watch config for changes
export DIR=$(readlink -f ${0%/*})
echo "DIR $DIR"
cd $DIR
/opt/logstash/bin/logstash -f ./\*.conf --auto-reload

#!/bin/sh
#  run logstash, config is in *.conf, watch config for changes
export DIR=$(readlink -f ${0%/*})
/opt/logstash/bin/logstash -f $DIR/\*.conf --auto-reload

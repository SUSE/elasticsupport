#!/bin/sh
#  run logstash, config is in *.conf, watch config for changes
export DIR=$(readlink -f ${0%/*})
echo "DIR $DIR"
cd $DIR
# 2.3
#/usr/share/logstash/bin/logstash -f ./\*.conf --auto-reload
#/opt/logstash/bin/logstash -f ./\*.conf --auto-reload
# 5.0
/usr/share/logstash/bin/logstash --path.settings $DIR
#/opt/logstash/bin/logstash --path.settings $DIR

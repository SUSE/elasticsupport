#!/bin/sh
#  run logstash, config is in config/ sub-dir, watch it for changes
/opt/logstash/bin/logstash -f config --auto-reload

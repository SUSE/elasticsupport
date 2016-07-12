#encoding: utf-8
#
# Import supportconfig into elasticsearch
#
# This file implements the Elasticsupport::Supportconfig
# base class, interfacing Elasticsupport with
#   Supportconfig (for input)
# and
#   Elasticsearch (for output)
#
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

module Elasticsupport
  INDEX = 'elasticsupport'
  class Supportconfig < Supportconfig::Supportconfig
    private
      def provide_mappings_to_elasticsearch mappings
        mappings.each do |type, mapping|
          # insert ':properties' level
          # see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
          # add 'timestamp' and 'hostname'
          properties = {
            hostname: { type: 'string', index: 'not_analyzed' },
            timestamp: { type: 'date' }
          }
          properties.merge! mapping
#          puts "#{self.class} mappings #{type} => #{properties.inspect}"
          
          # create or update mapping
          begin
            # try create, might fail with 'index_already_exists_exception'
            @elasticsupport.client.indices.create index: _index_for(type),
              body: {
                mappings: {
                  type => { properties: properties }
                }
              }
          rescue Elasticsearch::Transport::Transport::Errors::BadRequest => arg
            raise unless arg.message =~ /index_already_exists_exception/
            # update mapping
            @elasticsupport.client.indices.put_mapping index: _index_for(type), type: type,
              body: {
                type => { properties: properties }
              }
          end
        end
      end
    public
    #
    # constructor
    # - provide mapping to Elasticsearch
    # - call superclass constructor (parses file, calls callback)
    #
    def initialize elasticsupport, dir, fname
      # save caller instanc to set/access hostname, timestamp, etc.
      @elasticsupport = elasticsupport
      if self.respond_to? :_mappings
        provide_mappings_to_elasticsearch self._mappings
      end
      super dir, fname
    end
    def _index_for type
      "#{INDEX}"
    end
    
    # called from BasicSupport
    def hostname= hostname
      @elasticsupport.hostname = hostname
    end
    def timestamp= timestamp
      @elasticsupport.timestamp = timestamp
    end

    def _write type, body
      body[:timestamp] = @elasticsupport.timestamp.to_i * 1000 # ensure timestamp field as msec since epoch
      body[:hostname] = @elasticsupport.hostname
      @elasticsupport.client.index index: _index_for(type), type: type.to_s, body: body
#     puts body.inspect
    end
  end
end

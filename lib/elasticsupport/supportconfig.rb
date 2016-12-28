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
          # add 'name'
          properties = {
            name: { type: 'string', index: 'not_analyzed' }
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
    #  unless fname.nil?
    #   - call superclass constructor (parses file, calls callback)
    #
    def initialize elasticsupport, dir, fname = nil
      # save caller instanc to set/access name, timestamp, etc.
      @elasticsupport = elasticsupport
      if self.respond_to? :_mappings
        provide_mappings_to_elasticsearch self._mappings
      end
      super dir, fname if fname
    end
    def _index_for type
      "#{INDEX}"
    end
    
    # called from BasicSupport
    def name= name
      @elasticsupport.name = name
    end

    def _write type, body
#      puts "_write #{type}:#{body.inspect}"
      body[:name] = @elasticsupport.name
      @elasticsupport.client.index index: _index_for(type), type: type.to_s, body: body
#     puts body.inspect
    end

    # read type which matches name
    def _read type, name
      result = @elasticsupport.client.search index: _index_for(type), type: type.to_s, q: "name:#{name}"
      result["hits"]["hits"][0] rescue nil
    end
    # update type with id
    def _update type, id, body
      @elasticsupport.client.update index: _index_for(type), type: type.to_s, id: id, body: body
    end
  end
end

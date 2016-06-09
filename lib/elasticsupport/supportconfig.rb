#--
# Copyright (c) 2016 SUSE LINUX Products GmbH
#
# Author: Klaus Kämpf <kkaempf@suse.de>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Elasticsupport
  INDEX = 'elasticsupport'
  class Supportconfig < Supportconfig::Supportconfig
    def initialize elasticsupport, dir, fname
      # save caller instanc to set/access hostname, timestamp, etc.
      @elasticsupport = elasticsupport
      if self.respond_to? :_mappings
        # insert ':properties' level
        # see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
        # add 'timestamp' and 'hostname'
        self._mappings.each do |type, mapping|
          properties = {
            hostname: { type: 'string', index: 'not_analyzed' },
            timestamp: { type: 'date' }
          }
          properties.merge! mapping
#          puts "#{self.class} mappings #{type} => #{properties.inspect}"
          begin
            @elasticsupport.client.indices.create index: _index_for(type),
              body: {
                mappings: {
                  type => { properties: properties }
                }
              }
          rescue Elasticsearch::Transport::Transport::Errors::BadRequest => arg
            raise unless arg.message =~ /index_already_exists_exception/
            @elasticsupport.client.indices.put_mapping index: _index_for(type), type: type,
              body: {
                type => { properties: properties }
              }
          end
        end
      end
      super dir, fname
    end
    def _index_for type
      "#{INDEX}-#{type}"
    end
    def hostname= hostname
      @elasticsupport.hostname = hostname
    end
    def timestamp= timestamp
      @elasticsupport.timestamp = timestamp
    end
    def _write type, body
      body[:timestamp] = @elasticsupport.timestamp # ensure timestamp field
      body[:hostname] = @elasticsupport.hostname
      @elasticsupport.client.index index: _index_for(type), type: type.to_s, body: body
#     puts body.inspect
    end
  end
end

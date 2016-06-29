#encoding: utf-8
#
# Import supportconfig's
#   hardware.txt
# into elasticsearch
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'supportconfig'

module Elasticsupport

  class Hardware < Supportconfig
    def _mappings
      {
        lscpu: {
          architecture:          { type: 'string', index: 'not_analyzed' },
          cpu_op_modes:          { type: 'string', index: 'not_analyzed' },
          byte_order:            { type: 'string', index: 'not_analyzed' },
          cpus:                  { type: 'integer' },
          on_line_cpus_list:     { type: 'string', index: 'not_analyzed' },
          threads_per_core:      { type: 'integer' },
          cores_per_socket:      { type: 'integer' },
          sockets:               { type: 'integer' },
          numa_nodes:            { type: 'integer' },
          vendor_id:             { type: 'string', index: 'not_analyzed' },
          cpu_family:            { type: 'integer' },
          model:                 { type: 'integer' },
          model_name:            { type: 'string', index: 'not_analyzed' },
          stepping:              { type: 'integer' },
          cpu_mhz:               { type: 'float' },
          cpu_max_mhz:           { type: 'float' },
          cpu_min_mhz:           { type: 'float' },
          cpu_sockets:           { type: 'integer' },
          bogomips:              { type: 'float' },
          hypervisor_vendor:     { type: 'string', index: 'not_analyzed' },
          virtualization:        { type: 'string', index: 'not_analyzed' },
          virtualization_type:   { type: 'string', index: 'not_analyzed' },
          l1d_cache_k:           { type: 'integer' },
          l1i_cache_k:           { type: 'integer' },
          l2_cache_k:            { type: 'integer' },
          l3_cache_k:            { type: 'integer' },
          flags:                 { type: 'string', index: 'not_analyzed' },
          # s390x
          sockets_per_book:      { type: 'integer' },
          books:                 { type: 'integer' },
          hypervisor:            { type: 'string', index: 'not_analyzed' },
          dispatching_mode:      { type: 'string', index: 'not_analyzed' }
        }
      }
    end

    def command content
      # these values are in 'k' (1024)
      k_values = [ 'l1d_cache', 'l1i_cache', 'l2_cache', 'l3_cache' ]
      case content.shift
      when /\/usr\/bin\/lscpu/
        body = Hash.new
        content.each do |l|
          unless l =~ /([^:]+):\s*(.*)/
            STDERR.puts "lscpu? #{l.inspect}"
            next
          end
          key = $1.tr(" -","_").tr("()","").downcase
          value = $2
          if k_values.include? key
            key << "_k"
            if value =~ /(\d+)([KkMm])/
              value = $1.to_i
              case $2
              when 'M' then value = value * 1024
              when 'm' then value = value * 1000
              end
            else
              raise "Not a 'K' value: #{l}"
            end
          else
            m = _mappings[:lscpu][key.to_sym]
            if m.nil?
              next if key =~ /numa_node\d+_cpus/ # skip numa_nodeXX_cpus
              STDERR.puts "Unknown lscpu key #{key.inspect}"
            elsif m[:type] == 'integer'
              value = value.to_i
            elsif m[:type] == 'float'
              value = value.to_f
            end
          end
          body[key] = value
        end
#        puts body.inspect
        _write 'lscpu', body
      else
      end
    end
  end

end # module

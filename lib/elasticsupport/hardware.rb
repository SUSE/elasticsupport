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
          cpu_family:            { type: 'string', index: 'not_analyzed' },
          model:                 { type: 'string', index: 'not_analyzed' },
          model_name:            { type: 'string', index: 'not_analyzed' },
          stepping:              { type: 'string', index: 'not_analyzed' },
          cpu_mhz:               { type: 'string', index: 'not_analyzed' },
          bogomips:              { type: 'string', index: 'not_analyzed' },
          hypervisor_vendor:     { type: 'string', index: 'not_analyzed' },
          virtualization:        { type: 'string', index: 'not_analyzed' },
          virtualization_type:   { type: 'string', index: 'not_analyzed' },
          l1d_cache:             { type: 'string', index: 'not_analyzed' },
          l1i_cache:             { type: 'string', index: 'not_analyzed' },
          l2_cache:              { type: 'string', index: 'not_analyzed' },
          l3_cache:              { type: 'string', index: 'not_analyzed' },
          numa_node0_cpus:       { type: 'string', index: 'not_analyzed' },
          numa_node1_cpus:       { type: 'string', index: 'not_analyzed' }
        }
      }
    end

    def command content
      case content.shift
      when /\/usr\/bin\/lscpu/
        body = Hash.new
        content.each do |l|
          unless l =~ /([^:]+):\s*(.*)/
            STDERR.puts "lscpu? #{l.inspect}"
            next
          end
          body[$1.tr(" -","_").tr("()","").downcase] = $2
        end
#        puts body.inspect
        _write 'lscpu', body
      else
      end
    end
  end

end # module

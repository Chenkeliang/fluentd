#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/plugin_helper/compat_parameters'

module Fluent
  module Compat
    module FormatterUtils
      INJECT_PARAMS = Fluent::PluginHelper::CompatParameters::INJECT_PARAMS
      FORMATTER_PARAMS = Fluent::PluginHelper::CompatParameters::FORMATTER_PARAMS

      module InjectMixin
        def format(tag, time, record)
          r = owner.inject_record(tag, time, record)
          super(tag, time, r)
        end
      end

      def self.convert_formatter_conf(conf)
        return if conf.elements(name: 'inject').first || conf.elements(name: 'format').first

        inject_params = {}
        INJECT_PARAMS.each do |older, newer|
          next unless newer
          if conf.has_key?(older)
            inject_params[newer] = conf[older]
          end
        end

        if conf.has_key?('include_time_key') && Fluent::Config.bool_value(conf['include_time_key'])
          inject_params['time_key'] ||= 'time'
          inject_params['time_type'] ||= 'string'
        end
        if conf.has_key?('time_as_epoch') && Fluent::Config.bool_value(conf['time_as_epoch'])
          inject_params['time_type'] = 'unixtime'
        end
        if conf.has_key?('localtime') || conf.has_key?('utc')
          if conf.has_key?('localtime') && Fluent::Config.bool_value(conf['localtime'])
            inject_params['localtime'] = true
          elsif conf.has_key?('utc') && Fluent::Config.bool_value(conf['utc'])
            inject_params['localtime'] = false
            inject_params['timezone'] ||= "+0000"
          else
            log.warn "both of localtime and utc are specified as false"
          end
        end

        if conf.has_key?('include_tag_key') && Fluent::Config.bool_value(conf['include_tag_key'])
          inject_params['tag_key'] ||= 'tag'
        end

        unless inject_params.empty?
          conf.elements << Fluent::Config::Element.new('inject', '', inject_params, [])
        end

        formatter_params = {}
        FORMATTER_PARAMS.each do |older, newer|
          next unless newer
          if conf.has_key?(older)
            formatter_params[newer] = conf[older]
          end
        end
        unless formatter_params.empty?
          conf.elements << Fluent::Config::Element.new('format', '', formatter_params, [])
        end
      end
    end
  end
end

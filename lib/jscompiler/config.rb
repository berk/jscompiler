#--
# Copyright (c) 2013 Michael Berkovich
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

require 'fileutils'
require 'yaml'
require 'plist'
require 'pp'

module Jscompiler
  class Config

    def self.path
      '.jscompiler'
    end

    ##################################################
    ## Configuration Attributes
    ##################################################

    def self.config
      @config ||= YAML::load(File.open(path)) 
    end

    def self.update_config
      File.open(path, 'w') do |file| 
        file.write(config.to_yaml)
      end
    end

    def self.configured?
      File.exists?(path)
    end

    def self.groups
      config["groups"]
    end

    def self.compiler(group = nil)
      return config["compiler"] if group.nil?
      groups[group]["compiler"] || config["compiler"]
    end

    def self.compiler_command(group=nil, opts = {})
      cmplr = opts[:compiler] || compiler(group)["name"]

      case cmplr
      when 'clojure'
        Jscompiler::Commands::Clojure
      when 'yahoo'
        Jscompiler::Commands::Yahoo
      else
        raise("Unsupported compiler")
      end
    end

    def self.source_root
      config["source_root"]
    end

    def self.files(group)
      groups[group]["files"]
    end

    def self.output(group)
      groups[group]["output"]
    end

    def self.output_path(group)
      output(group)["path"]
    end

    def self.debug?(group)
      output(group)["debug"]
    end

    def self.output_destination(group, opts = {})
      path = output_path(group)
      parts = path.split("/")
      file_name = parts.pop
      if opts[:suffix]
        file_name = file_name.index('.js') ? file_name.gsub(".js", "#{opts[:suffix]}.js") : "#{file_name}#{opts[:suffix]}"
      end
      if opts[:prefix]
        file_name = "#{opts[:prefix]}#{file_name}"
      end
      "#{parts.join("/")}/#{file_name}"
    end

  end
end

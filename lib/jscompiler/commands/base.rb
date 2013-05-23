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

module Jscompiler
  module Commands
  
    class Base

      attr_reader :options

      def initialize(opts = {})
        @options = opts
      end

      def group 
        options[:group]
      end

      def run
        raise("Must be implemented by the extending class")
      end

      def comments_regexp 
        /\/\*(!)*[^*]*\*+(?:[^*\/][^*]*\*+)*\//  
      end

      def sanitize(content)
        content.gsub(comments_regexp, '')
      end

      def prepare_arguments(args)
        args.collect{|arg| arg.join(' ')}.join(' ')
      end

      def prepare_command(cmd, args)
        "#{cmd} #{prepare_arguments(args)}"
      end

      def save_or_delete_temp_file
        if Jscompiler::Config.debug?(group)
          FileUtils.mv(temp_file_path, debug_file_path)
        else
          FileUtils.rm(temp_file_path)
        end
      end

      def temp_file_path
        Jscompiler::Config.output_destination(group, :suffix => ".tmp")
      end

      def debug_file_path
        Jscompiler::Config.output_destination(group, :suffix => ".debug")
      end

      def generate_temp_file
        File.open(temp_file_path, 'w') do |file| 
          Jscompiler::Config.files(group).each do |fl|
            puts("Processing #{fl}...")
            content = File.read(fl)
            content = sanitize(content)
            file.write(content)
          end
        end
      end

      def output_file_path
        return options["output"] if options["output"]
        Jscompiler::Config.output_destination(group, options)
      end

      def execute(cmd, opts = {})
        puts("\r\n$ " + cmd)
        return if opts[:cold]

        # Kernel.spawn(command)    

        result = system(cmd)
        return if opts[:ignore_result]

        unless result
          puts("Build failed.")
          exit 1
        end      
      end   

      def self.compile_group(group, opts = {})
        puts("\r\nCompiling #{group} group...")
        
        t0 = Time.now
        Jscompiler::Config.compiler_command(group, opts).new(opts.merge({
          :group => group
        })).run
        t1 = Time.now

        puts("Done. Compilation took #{t1-t0} seconds\r\n")
      end      

    end

  end
end

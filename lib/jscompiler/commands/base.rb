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

      def prepare(cmd, args)
        "#{cmd} #{args.collect{|arg| arg.join(' ')}.join(' ')};"
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

    end

  end
end

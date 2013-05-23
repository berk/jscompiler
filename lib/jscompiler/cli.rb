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

require 'thor'
require 'fssm'

module Jscompiler
  class Cli < Thor
    include Thor::Actions

    class << self
      def source_root
        File.expand_path('../../',__FILE__)
      end
    end

    map 'i' => :init
    desc 'init', 'Initializes your project and writes your preferences into a .jscompiler configuration file'
    def init
      say("Initializing your project...")

      # say("Which compiler would you like to use?")
      # comps = [
      #   ["1:", "clojure"],
      # ]
      # print_table(comps)
      # num = ask_for_number(1)
      # @compiler = comps[num-1].last
      @compiler = 'clojure'  # the only one for now

      @root = ask("\r\nWhat is your files source folder (a relative path from the current directory)?")
      @files = Dir.glob("#{@root}/**/*.js")
      table = []
      @files.each_with_index do |fl, index|
        table << ["#{index + 1}: ", fl]
      end
      print_table(table)

      say("\r\nEnter the file numbers in the order you want them to be compiled (separated with commas). For example: 2,4,1,3. If the order doesn't matter, just press enter.")
      nums = ask("File order: ")
      if nums.strip != ""
        files = []
        nums.split(",").each do |num|
          index = num.to_i - 1
          if index < 0 or index >= @files.size 
            puts("Invalid file number: #{num}")
            next
          end
          files << @files[index]
        end
        @files = files
        say("The files will be compiled in the following order. You can change the order manually by modifying the .jscompiler file in this folder.")
        table = []
        @files.each_with_index do |fl, index|
          table << ["#{index + 1}: ", fl]
        end
        print_table(table)
      end

      @filename = ask("\r\nWhat should the compiled file be named?")

      @output = ask("\r\nWhere should the compiled file be saved (a relative path from this folder)?")

      @debug = yes?("\r\nWould you like to create a debug version of the file (concatinated, but not compiled)?")

      template 'templates/jscompiler.yml.erb', "./#{Jscompiler::Config.path}"
      FileUtils.mkdir_p(@output)

      say("Configuration has been saved. You now can run the compile command.")      
    end

    map 'c' => :compile
    desc 'compile', 'Compiles selected file group'
    method_option :group, :type => :string, :aliases => "-g", :required => false, :banner => "Group to compile", :default => nil
    def compile
      if @options[:group]
        unless Jscompiler::Config.groups.keys.include?(@options[:group])
          puts("Error: invalid group name")
          return
        end

        Jscompiler::Cli.compile_group(@options[:group])
        return
      end

      Jscompiler::Config.groups.keys.each do |group|  
        Jscompiler::Cli.compile_group(group)
      end
    end

    map 'w' => :watch
    desc 'watch', 'Watches source root folder for cahnges and compiles all affected groups'
    def watch
      say("Started monitoring #{Jscompiler::Config.source_root} folder. To stop use Ctrl+C.")

      monitor = FSSM::Monitor.new
      monitor.path("./#{Jscompiler::Config.source_root}/", '**/*.js') do
        update do |base, relative|
          puts("#{relative} file changed")
          compile(relative)
        end

        delete do |base, relative|
          puts("#{relative} deleted")
          compile(relative)
        end

        def compile(relative)
          Jscompiler::Config.groups.keys.each do |group|  
            full_path = Jscompiler::Config.source_root == '.' ? relative : "#{Jscompiler::Config.source_root}/#{relative}"
            next unless Jscompiler::Config.files(group).include?(full_path)
            Jscompiler::Cli.compile_group(group)
          end
        end        
      end

      monitor.run
    end

    def self.compile_group(group)
      puts("Compiling #{group} group...")
      
      t0 = Time.now
      Jscompiler::Config.compiler_command(group).new({
        :group => group
      }).run
      t1 = Time.now

      puts("\r\nDone. Compilation took #{t1-t0} seconds\r\n")
    end

  private

    def ask_for_number(max, opts = {})
      opts[:message] ||= "Choose: "
      while true
        value = ask(opts[:message])
        if /^[\d]+$/ === value
          num = value.to_i
          if num < 1 or num > max
            say("Hah?")
          else
            return num
          end
        else
          say("Hah?")
        end
      end
    end    

  end
end

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

      ask_for_compiler

      @root = ask("\r\nWhat is your files source folder (a relative path from the current directory)?")
      @root = '.' if @root == ''

      ask_for_file_order
      ask_for_output_path

      template 'templates/jscompiler.yml.erb', "./#{Jscompiler::Config.path}"

      say("Configuration has been saved in .jscompiler file. You now can run the compile commands.")      
    end

    map 'g' => :group
    desc 'group', 'Creates a new file group'
    def group
      unless Jscompiler::Config.configured?
        say("This folder has not yet been configured to run jsc commands. Please run 'jsc init'.")
        return
      end

      @group_name = ask("What would you like to name this group?")
      @root = Jscompiler::Config.source_root
      ask_for_compiler(:default => true)
      ask_for_file_order
      ask_for_output_path

      Jscompiler::Config.config['groups'][@group_name] = {
        "files" => @files,
        "output" => {"path" => @output}, 
      }

      if @compiler != "default"
        Jscompiler::Config.config['groups'][@group_name]["compiler"] = {"name" => @compiler}
      end

      Jscompiler::Config.update_config

      say("Configuration has been saved in .jscompiler file. You now can run the compile commands.")
    end

    map 'c' => :compile
    desc 'compile', 'Compiles selected file group'
    method_option :compiler, :type => :string, :aliases => "-c", :required => false, :banner => "Compiler to use for compilation", :default => nil
    method_option :group, :type => :string, :aliases => "-g", :required => false, :banner => "Group to compile", :default => nil
    method_option :output, :type => :string, :aliases => "-o", :required => false, :banner => "Path and name of the output file", :default => nil
    method_option :prefix, :type => :string, :aliases => "-p", :required => false, :banner => "Prepand prefix to all compiled file names", :default => nil
    method_option :suffix, :type => :string, :aliases => "-s", :required => false, :banner => "Append suffix to all compiled file names", :default => nil
    def compile
      unless Jscompiler::Config.configured?
        say("This folder has not yet been configured to run jsc commands. Please run 'jsc init'.")
        return
      end

      if @options[:group]
        unless Jscompiler::Config.groups.keys.include?(@options[:group])
          puts("Error: invalid group name")
          return
        end

        Jscompiler::Commands::Base.compile_group(@options[:group], @options)
        return
      end

      Jscompiler::Config.groups.keys.each do |group|  
        Jscompiler::Commands::Base.compile_group(group, @options)
      end
    end

    map 'w' => :watch
    desc 'watch', 'Watches source root folder for cahnges and compiles all affected groups'
    def watch
      unless Jscompiler::Config.configured?
        say("This folder has not yet been configured to run jsc commands. Please run 'jsc init'.")
        return
      end

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
            Jscompiler::Commands::Base.compile_group(group)
          end
        end        
      end

      monitor.run
    end

  private

    def ask_for_compiler(opts = {})
      say("Which compiler would you like to use?")
      compilers = ["closure", "yahoo", "uglifier"]
      if opts[:default]
        compilers.unshift("default")
      end
      options = []
      compilers.each_with_index do |c, index|
        options << ["#{index + 1}:", c]
      end
      print_table(options)
      num = ask_for_number(compilers.size)
      @compiler = compilers[num-1]
    end

    def ask_for_output_path(opts = {})
      @output = ask("\r\nWhat is the path of the output file (a relative path from the current folder)?")
      @output = './compiled.js' if @output == ''
      if @output.index('/')
        FileUtils.mkdir_p(@output.split('/')[0..-2].join('/'))  
      end
    end

    def ask_for_file_order(opts = {})
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
    end

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

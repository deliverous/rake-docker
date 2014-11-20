require 'rake/tasklib'
require 'time'

module Rake

  class DockerLib < TaskLib
    Target = '.target'
    attr_accessor :name
    attr_accessor :version
    attr_accessor :image_name

    def initialize(name=nil, options={}, &block)
      fail "name required" if name.nil?
      @version = options[:version]
      @image_name = name
      @image_name = @image_name +":#{@version}" unless version.nil?
      no_cache = options[:no_cache] || false
      version = options[:version] || nil

      tasks = DockerTasks.new
      tasks.instance_eval &block

      desc "Prepare for build #{@image_name}"
      task :prepare do
        command = ['rsync', '-aqP', 'Dockerfile']
        command << 'src/' if Dir.exists?('src')
        command << "#{DockerLib::Target}/"
        sh *command
        v = verbose
        verbose(false) do
          cd DockerLib::Target do
            verbose(v) { instance_eval &tasks.prepare_config if not tasks.prepare_config.nil? }
          end
        end
      end

      build_image_tag = "#{DockerLib::Target}/.#{@image_name.tr('/: |&', '_')}"
      file build_image_tag do 
        command = ['docker', 'build']
        command << '--no-cache' if (Rake.application.options.build_all or no_cache)
        command << '-t' << @image_name << DockerLib::Target
        sh *command
        touch build_image_tag
      end

      FileList["#{DockerLib::Target}/**/*"].each do |file|
        file build_image_tag => [file]
      end

      desc "Build #{@image_name}"
      task build: [:prepare, build_image_tag]

      desc "Push #{@image_name}"
      task :push do
        sh 'docker', 'push', @image_name
      end

      desc "Publish #{@image_name}"
      task publish: [:build, :test, :push]

      desc "Test container #{@image_name}"
      task :test do
        test_name = tasks.test_config.image_value || "#{name.split('/')[-1]}-test"
        sh "docker run -d --name '#{test_name}' #{tasks.test_config.option_value} #{@image_name} #{tasks.test_config.args_value}"
        begin
          ruby "-S testrb #{test_files} #{test_options}" do |ok, status|
            if !ok && status.respond_to?(:signaled?) && status.signaled?
              raise SignalException.new(status.termsig)
            elsif !ok
              fail "Command failed with status (#{status.exitstatus})"
            end
          end
        ensure
          sh "docker stop '#{test_name}'"
          sh "docker rm '#{test_name}'"
        end    
      end
    end

    def test_options
      (ENV['TESTOPTS'] || ENV['TESTOPT'] || ENV['TEST_OPTS'] || ENV['TEST_OPT'] || "")
    end

    def test_files
      if ENV['TEST']
        ENV['TEST']
      else
        Dir.glob('./test/**/test*.rb').map { |file| "\"#{file}\""}.join(" ")
      end
    end
  end


  class DockerTestConfig
    attr_reader :image_value
    attr_reader :option_value
    attr_reader :args_value

    def initialize
      @image_value = nil
      @option_value = ''
      @args_value = ''
    end

    def image(value)
      @image_value = value
    end

    def args(value)
      @args_value = value
    end

    def options(value)
      @option_value = value
    end
  end


  class DockerTasks
    attr_reader :prepare_config
    attr_reader :test_config

    def initialize
      @test_config = DockerTestConfig.new
    end

    def prepare(&block)
      @prepare_config = block
    end

    def test(&block)
      @test_config.instance_eval &block
    end
  end

end

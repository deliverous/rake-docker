require 'rake/tasklib'
require 'time'

module Rake
  class DockerLib < TaskLib
    Target = '.target'
    attr_accessor :name
    attr_accessor :version
    attr_accessor :image_name

    def initialize(name=nil, options={})
      fail "name required" if name.nil?
      @version = options[:version]
      @image_name = name
      @image_name = @image_name +":#{@version}" unless version.nil?
      no_cache = options[:no_cache] || false
      version = options[:version] || nil

      desc "Prepare for build #{@image_name}"
      task :prepare do |prepare_task|
        command = ['rsync', '-aqP', 'Dockerfile']
        command << 'src/' if Dir.exists?('src')
        command << "#{DockerLib::Target}/"
        sh *command
        v = verbose
        verbose(false) do
          cd DockerLib::Target do
            verbose(v) { yield prepare_task if block_given? }
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
      task publish: [:build, :push]
    end
  end
end

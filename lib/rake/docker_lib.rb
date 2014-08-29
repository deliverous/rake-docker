require 'rake/tasklib'
require 'time'

module Rake
  class DockerLib < TaskLib
    attr_accessor :name
    attr_accessor :version
    attr_accessor :image_name

    def initialize(name=nil, version=nil)
      fail "name required" if name.nil?
      @version = version
      @image_name = name
      @image_name = @image_name +":#{@version}" unless version.nil?

      desc "Prepare for build #{@image_name}"
      task :prepare do |prepare_task|
        sh 'rsync -aqP --exclude Rakefile --delete * .target/'
        v = verbose
        verbose(false) do
          cd '.target' do
            verbose(v) { yield prepare_task if block_given? }
          end
        end
      end

      build_image_tag = ".target/.#{@image_name.tr('/: |&', '_')}"
      file build_image_tag do 
        command = ['docker', 'build']
        command << '--no-cache' if Rake.application.options.build_all
        command << '-t' << @image_name << '.target'
        sh *command
        sh 'touch', build_image_tag
      end

      FileList['.target/**/*'].each do |file|
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

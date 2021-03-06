Gem::Specification.new do |spec|
  spec.name = "rake-docker"
  spec.version = "0.0.1"
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Deliverous R&D"]
  spec.email = ["contact@deliverous.com"]
  spec.homepage = "http://deliverous.com/"
  spec.summary = "Rake tasks relative to docker"
  spec.description = ""

  spec.required_rubygems_version = ">= 1.3.6"

  spec.add_dependency 'rake'
  spec.add_dependency 'climate_control'

  spec.files = Dir["{lib}/**/*.rb", "{lib}/**/*.erb", "{bin}/*", "{lib}/**/*.rake", "{lib}/**/*.yml", "LICENSE", "*.md", "templates/**"]
  spec.bindir = 'bin'

  spec.require_path = 'lib'
  #spec.license       = 'MIT'
end

require File.join(File.dirname(__FILE__), 'lib', 'etherpad-lite', 'version')

Gem::Specification.new do |spec|
  spec.name = 'etherpad-lite'
  spec.version = EtherpadLite::VERSION
  spec.summary = "A Ruby client library for Etherpad Lite"
  spec.description = "etherpad-lite is a Ruby interface to Etherpad Lite's HTTP JSON API"
  spec.authors = ['Jordan Hollinger']
  spec.date = '2013-01-20'
  spec.email = 'jordan@jordanhollinger.com'
  spec.homepage = 'http://github.com/jhollinger/ruby-etherpad-lite'

  spec.require_paths = ['lib']
  spec.extra_rdoc_files = %w{README.rdoc}
  spec.files = [Dir.glob('lib/**/*'), 'README.rdoc', 'CHANGELOG', 'LICENSE'].flatten

  spec.specification_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION if spec.respond_to? :specification_version

  spec.add_dependency('rest-client', ['>= 1.6'])
end

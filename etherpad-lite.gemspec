Gem::Specification.new do |spec|
  spec.name = 'etherpad-lite'
  spec.version = '0.0.1'
  spec.summary = "A Ruby client library for Etherpad Lite"
  spec.description = "etherpad-lite is a Ruby interface to Etherpad Lite's HTTP JSON API"
  spec.authors = ['Jordan Hollinger']
  spec.date = '2011-08-28'
  spec.email = 'jordan@jordanhollinger.com'
  spec.homepage = 'http://github.com/jhollinger/etherpad-lite'

  spec.require_paths = ['lib']
  spec.extra_rdoc_files = %w{README.rdoc}
  spec.files = [Dir.glob('lib/**/*'), Dir.glob('spec/**/*'), 'README.rdoc', 'LICENSE', 'TODO.txt'].flatten

  spec.specification_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION if spec.respond_to? :specification_version
end

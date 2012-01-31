require 'rspec'

# Load etherpad-lite
$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'
require 'etherpad-lite'

RSpec.configure do |c|
  c.mock_with :rspec
end

# Load test config
require 'yaml'
TEST_CONFIG = YAML.load_file(File.dirname(__FILE__) + '/config.yml')
TEST_CONFIG[:api_key_file] = File.new(TEST_CONFIG[:api_key_file]) unless TEST_CONFIG[:api_key_file].nil?

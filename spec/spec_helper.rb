require 'rspec'

# Load etherpad-lite
require File.dirname(__FILE__) + '/../lib/etherpad-lite/client'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/models/padded'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/models/instance'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/models/pad'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/models/group'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/models/author'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/models/session'

RSpec.configure do |c|
  c.mock_with :rspec
end

# Load test config
require 'yaml'
TEST_CONFIG = YAML.load_file(File.dirname(__FILE__) + '/config.yml')
TEST_CONFIG[:api_key_file] = File.new(TEST_CONFIG[:api_key_file]) unless TEST_CONFIG[:api_key_file].nil?

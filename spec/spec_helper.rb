require 'rspec'

# Load etherpad-lite
require File.dirname(__FILE__) + '/../lib/etherpad-lite/padded'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/instance'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/pad'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/group'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/author'
require File.dirname(__FILE__) + '/../lib/etherpad-lite/session'

Rspec.configure do |c|
  c.mock_with :rspec
end

# Load test config
require 'yaml'
TEST_CONFIG = YAML.load_file(File.dirname(__FILE__) + '/config.yml')

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

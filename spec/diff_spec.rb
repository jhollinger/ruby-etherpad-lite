require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Diff do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:url], TEST_CONFIG[:api_key_file] || TEST_CONFIG[:api_key], TEST_CONFIG[:api_version]
  end

  it "should return a diff" do
    pad = @eth.create_pad 'my new diffed pad', :text => 'The initial text'
    pad.diff(0, 1).html.should =~ /The initial text/
  end
end

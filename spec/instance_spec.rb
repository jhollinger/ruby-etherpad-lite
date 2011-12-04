require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Instance do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:url], TEST_CONFIG[:api_key_file] || TEST_CONFIG[:api_key]
  end

  it "should have the right API key" do
    api_key = if TEST_CONFIG[:api_key_file]
      begin
        TEST_CONFIG[:api_key_file].read
      rescue IOError
        TEST_CONFIG[:api_key_file].reopen(TEST_CONFIG[:api_key_file], mode='r')
        TEST_CONFIG[:api_key_file].read
      end
    else
      TEST_CONFIG[:api_key]
    end
    @eth.client.api_key.should == api_key
  end

  it "shouldn't be secure" do
    @eth.client.secure?.should == false
  end
end

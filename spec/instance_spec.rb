require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Instance do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:instances][:http][:url], TEST_CONFIG[:instances][:http][:api_key]
  end

  it "should have the right API key" do
    @eth.client.api_key.should == TEST_CONFIG[:instances][:http][:api_key]
  end

  it "shouldn't be secure" do
    @eth.client.secure?.should == false
  end
end

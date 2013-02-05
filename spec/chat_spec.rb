require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::ChatMessage do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:url], TEST_CONFIG[:api_key_file] || TEST_CONFIG[:api_key], TEST_CONFIG[:api_version]
  end

  if TEST_CONFIG[:api_version].to_s > '1.2.1'
    it "should list the chart history" do
      @eth.pad('chatty pad').chat_messages.should == []
    end

    it "should list the chart head" do
      @eth.pad('chatty pad').chat_size.should == 0
    end
  end
end

require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Author do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:url], TEST_CONFIG[:api_key_file] || TEST_CONFIG[:api_key], TEST_CONFIG[:api_version]
  end

  it "should be created" do
    author = @eth.create_author
    author.id.nil?.should == false
  end

  it "should be mapped to 'Author A'" do
    author = @eth.create_author :mapper => 'Author A'
    author.id.nil?.should == false
  end

  it "should be mapped to 'Author A'" do
    author1 = @eth.create_author :mapper => 'Author A'
    author2 = @eth.author 'Author A'
    # They should be the same
    author1.id.should == author2.id
  end

  it "should list pads of 'Author A'" do
    author = @eth.create_author :mapper => 'Author A'
    author.pad_ids.should == []
    author.pads.should == []
  end
end

require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Pad do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:instances][:http][:url], TEST_CONFIG[:instances][:http][:api_key]
  end

  it "should blow up when querying a non-existing pad" do
    pad = @eth.get_pad 'a non-existant pad'
    begin
      txt = pad.text
    rescue ArgumentError => e
    end
    e.message.should == 'padID does not exist'
  end

  it "should create a new pad" do
    pad = @eth.create_pad 'my new pad', :text => 'The initial text'
    pad.text.should == "The initial text\n"
  end

  it "should blow up when creating a Pad that already exists" do
    begin
      pad = @eth.create_pad 'my new pad', :text => 'The initial text'
    rescue ArgumentError => e
    end
    e.message.should == 'padID does already exist'
  end

  it "should automatically create a Pad" do
    pad = @eth.pad 'another new pad'
    pad.text = "The initial text"
    pad.text.should == "The initial text\n"
  end

  it "should automatically find a Pad" do
    pad = @eth.pad 'another new pad'
    pad.text.should == "The initial text\n"
  end

  it "should find a Pad" do
    pad = @eth.get_pad 'another new pad'
    pad.text.should == "The initial text\n"
  end

  it "should have a read-only id" do
    pad = @eth.get_pad 'another new pad'
    pad.read_only_id.should =~ /^r\.\w+/
  end

  it "should add revisions" do
    pad = @eth.get_pad 'another new pad'
    pad.text == "New text"
    pad.revision_numbers.last == 2
  end

  it "should have the first revision" do
    pad = @eth.get_pad 'another new pad'
    pad.text(:rev => 1).should == "The initial text\n"
  end

  it "should have the first revision" do
    pad = @eth.get_pad 'another new pad'
    pad.revisions[1].text.should == "The initial text\n"
  end

  it "should have the same name and id" do
    pad = @eth.get_pad 'another new pad'
    pad.name.should == pad.id
  end

  it "should be initialized as revision 0" do
    pad = @eth.pad 'brand new pad', :text => 'Brand new text'
    pad.text = 'Even newer text'
    pad.text = 'Even even newer text'
    pad = @eth.get_pad 'brand new pad', :rev => 0
    pad.text.should == "Brand new text\n"
  end

  it "should be deleted" do
    @eth.get_pad('another new pad').delete
    @eth.create_pad('another new pad').id.should_not == nil
  end
end

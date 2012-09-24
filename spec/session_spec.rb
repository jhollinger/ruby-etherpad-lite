require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Session do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:url], TEST_CONFIG[:api_key_file] || TEST_CONFIG[:api_key], TEST_CONFIG[:api_version]
  end

  it "should be created for a Group" do
    group = @eth.group 'Maycomb'
    author = @eth.author 'Atticus'
    session = group.create_session(author, 20)
    session.valid_until.should == Time.now.to_i + 20 * 60
  end

  it "should be created for an Author" do
    group = @eth.group 'Maycomb'
    author = @eth.author 'Scout'
    session = author.create_session(group, 15)
    session.valid_until.should == Time.now.to_i + 15 * 60
  end

  it "should be found in a Group" do
    group = @eth.group 'Maycomb'
    author = @eth.author 'Atticus'
    group.sessions.map(&:author_id).include?(author.id).should == true
  end

  it "shouldn be found in a Group" do
    group = @eth.group 'Maycomb'
    author = @eth.author 'Atticus'
    author.sessions.map(&:group_id).include?(group.id).should == true
  end

  it "shouldn't be found in the wrong Group" do
    group = @eth.group 'Other group'
    author = @eth.author 'Scout'
    group.sessions.map(&:author_id).include?(author.id).should == false
  end

  it "shouldn't be found in the wrong Group" do
    group = @eth.group 'Other group'
    author = @eth.author 'Scout'
    author.sessions.map(&:group_id).include?(group.id).should == false
  end
end

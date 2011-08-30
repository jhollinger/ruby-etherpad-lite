require File.dirname(__FILE__) + '/spec_helper'

describe EtherpadLite::Group do
  before do
    @eth = EtherpadLite.connect TEST_CONFIG[:instances][:http][:url], TEST_CONFIG[:instances][:http][:api_key]
  end

  it "should be created" do
    group = @eth.create_group
    group.id.nil?.should == false
  end

  it "should be mapped to 'Group A'" do
    group = @eth.create_group :mapper => 'Group A'
    group.id.nil?.should == false
  end

  it "should be mapped to 'Group A'" do
    group1 = @eth.create_group :mapper => 'Group A'
    group2 = @eth.group 'Group A'
    # They should be the same
    group1.id.should == group2.id
  end

  it "should create a Group Pad" do
    group = @eth.group 'Group A'
    pad = group.pad 'Important Group Stuff'
    pad.id.should == "#{group.id}$Important Group Stuff"
  end

  it "should create a Group Pad with the right name" do
    group = @eth.group 'Group A'
    pad = group.pad 'Important Group Stuff'
    pad.name.should == "Important Group Stuff"
  end

  it "should find a Group Pad with the right group" do
    group = @eth.group 'Group A'
    group.get_pad('Important Group Stuff').group_id.should == group.id
  end

  it "should find a Group Pad with the right id" do
    group = @eth.group 'Group A'
    group.pad_ids.should == [:"#{group.id}$Important Group Stuff"]
  end

  it "should find a Group Pad with the right name" do
    group = @eth.group 'Group A'
    group.pads.first.name.should == "Important Group Stuff"
  end

  it "should explicitly create a Group Pad" do
    group = @eth.group 'Group A'
    pad = group.create_pad 'new group pad', :text => 'abc'
    pad.text.should == "abc\n"
  end

  context 'Group Pad' do
    context 'Privacy' do
      it "should be private" do
        group = @eth.group 'Group A'
        pad = group.get_pad 'new group pad'
        pad.private?.should == true
      end

      it "should not be public" do
        group = @eth.group 'Group A'
        pad = group.get_pad 'new group pad'
        pad.public?.should == false
      end

      it "should change to public" do
        group = @eth.group 'Group A'
        pad = group.get_pad 'new group pad'
        pad.public = true
        pad.public?.should == true
      end

      it "should change to not private" do
        group = @eth.group 'Group A'
        pad = group.get_pad 'new group pad'
        pad.private = false
        pad.private?.should == false
      end
    end

    context 'Password' do
      it "should not have a password" do
        group = @eth.group 'Group A'
        pad = group.get_pad 'new group pad'
        pad.password?.should == false
      end

      it "should have a password set" do
        group = @eth.group 'Group A'
        pad = group.get_pad 'new group pad'
        pad.password = 'correct horse battery staple'
        pad.password?.should == true
      end
    end
  end
end

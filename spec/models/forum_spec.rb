require File.dirname(__FILE__) + '/../spec_helper'

describe Forum do
  dataset :forums
  
  before do
    @site = Page.current_site = sites(:test) if defined? Site
    @forum = forums(:public)
    @reader = Reader.current = readers(:normal)
  end
  
  it "should require a name" do
    @forum.name = nil
    @forum.should_not be_valid
    @forum.errors.on(:name).should_not be_empty
  end
  
  describe "topics.bydate" do
    it "should list its topics in descending date order" do
      forums(:public).topics.bydate.first.should == topics(:newer)
      forums(:private).topics.bydate.first.should == topics(:private)
    end
  end
  
  describe "topics.stickyfirst" do
    it "should list its topics with the sticky first" do
      forums(:private).topics.stickyfirst.first.should == topics(:sticky)
    end
  end
  
  describe "when the forum is public" do
    before do
      Radiant::Config['forum.public?'] = true
    end

    it "should be visible to a reader" do
      forums(:public).visible_to?(@reader).should be_true
    end
    
    it "should be visible when there is no reader" do
      forums(:public).visible_to?(nil).should be_true
    end
  end

  describe "when the whole forum is private" do
    before do
      Radiant::Config['forum.public?'] = false
    end

    it "should be visible to a reader" do
      forums(:public).visible_to?(@reader).should be_true
    end
    
    it "should not be visible when there is no reader" do
      forums(:public).visible_to?(nil).should be_false
    end
  end

end

require File.dirname(__FILE__) + "/../spec_helper"

describe 'Forum-extended page' do
  dataset :forums
  
  before do
    login_as_reader(:normal)
  end
  
  it "should normally be commentable" do
    pages(:uncommented).locked?.should be_false
  end
  
  it "should be locked if marked not commentable" do
    pages(:uncommentable).locked?.should be_true
  end
  
  it "should be locked if marked comments_closed" do
    pages(:comments_closed).locked?.should be_true
  end
  
  it "should be locked if there is a commentable period and it has expired" do
    Radiant::Config['forum.commentable_period'] = 28
    page = pages(:commentable)
    page.commentable_period.should == 28.days
    page.locked?.should be_false
    page.created_at = Time.now - 30.days
    page.locked?.should be_true
  end
    
end

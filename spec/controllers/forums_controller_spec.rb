require File.dirname(__FILE__) + '/../spec_helper'
Radiant::Config['reader.layout'] = 'Main'

describe ForumsController do
  dataset :forum_sites
  dataset :forum_readers
  dataset :forums
  dataset :layouts

  before do
    controller.stub!(:request).and_return(request)
    controller.set_current_site
  end
    
  describe "on get to index" do
    before do
      get :index
    end

    it "should render the forum front page" do
      response.should be_success
      response.should render_template("index")
    end  
  end
    
  describe "on get to show" do
    before do
      @forum = forums(:public)
      get :show, :id => forum_id(:public)
    end
    
    it "should render the show template" do
      response.should be_success
      response.should render_template("show")
    end
        
    it "should not show a forum from another site" do
      
    end
  end
  
  [:new, :edit, :update, :create, :destroy].each do |action|
    it "should redirect #{action} requests to admin login" do
      get action, :id => forum_id(:public)
      response.should be_redirect
      response.should redirect_to(admin_forums_url)
    end
  end
end

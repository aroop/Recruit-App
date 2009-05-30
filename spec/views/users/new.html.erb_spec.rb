require File.dirname(__FILE__) + '/../../spec_helper'

describe "/users/new" do
  before(:each) do
    assigns[:user] = User.new
  end
  
  describe "when the user limit has been reached" do
    before(:each) do
      assigns[:current_account] = @account = accounts(:localhost)
      @account.subscription.update_attribute(:user_limit, @account.users.count)
      render 'users/new'
    end
    
    it "should show text explaining the limit" do
      response.should have_text(/You have reached the maximum number of users you can have with your account level./)
    end

    it "should not show the form" do
      response.should_not have_tag('form')
    end
  end
  
  describe "when the limit has not been reached" do
    before(:each) do
      render 'users/new'
    end
    
    it "should show the form" do
      response.should have_tag('form[action=?]', users_path)
    end
  
    it "should not show the text explaining the limit" do
      response.should_not have_text(/You have reached the maximum number of open users you can have with your account level./)
    end
  end
end
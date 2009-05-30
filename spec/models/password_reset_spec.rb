require File.dirname(__FILE__) + '/../spec_helper'

describe PasswordReset do
  before(:each) do
    @account = accounts(:localhost)
    @user = @account.users.first
  end
  
  it "should get a token when created" do
    @pr = PasswordReset.create(:user => @user)
    @pr.token.should_not be_blank
  end
  
  it "should send an email when created" do
    (@emails = ActionMailer::Base.deliveries).clear
    @pr = PasswordReset.create(:user => @user)
    @emails.size.should == 1
    @email = @emails.first
    @email.to.should == [ @user.email ]
    @email.body.should include('your password to be reset')
    @email.body.should include("http://#{@pr.user.account.full_domain}/account/reset/#{@pr.token}")
  end
end
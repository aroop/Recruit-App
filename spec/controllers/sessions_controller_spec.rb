require File.dirname(__FILE__) + '/../spec_helper'

describe SessionsController do
  it 'logins and redirects' do
    post :create, :login => 'quentin', :password => 'test'
    session[:user_id].should_not be_nil
    response.should be_redirect
  end
  
  it 'fails login and does not redirect' do
    post :create, :login => 'quentin', :password => 'bad password'
    session[:user_id].should be_nil
    response.should be_success
  end

  it 'logs out' do
    login_as :quentin
    get :destroy
    session[:user_id].should be_nil
    response.should be_redirect
  end

  it 'remembers me' do
    controller.expects(:handle_remember_cookie!).with(true)
    post :create, :login => 'quentin', :password => 'test', :remember_me => "1"
  end
  
  it 'does not remember me' do
    controller.expects(:handle_remember_cookie!).with(false)
    post :create, :login => 'quentin', :password => 'test', :remember_me => "0"
  end

  it 'logs in with cookie' do
    users(:quentin).remember_me
    request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    controller.send(:logged_in?).should be_true
  end
  
  it 'fails expired cookie login' do
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    controller.send(:logged_in?).should_not be_true
  end
  
  it 'fails cookie login' do
    users(:quentin).remember_me
    request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    controller.send(:logged_in?).should_not be_true
  end
  
  it "should render the forgot password form" do
    get :forgot
    response.should render_template('forgot')
  end
  
  it "should create a password reset request when submitting the form for a valid email address" do
    PasswordReset.expects(:create).with(has_entry(:user => @user = users(:quentin)))
    post :forgot, :email => @user.email
    response.should render_template('forgot_complete')    
  end
  
  it "should not create a password reset request when submitting the form with an invalid email address" do
    PasswordReset.expects(:create).never
    post :forgot, :email => 'bogus'
    response.should render_template('forgot')
    flash[:error].should == "That account wasn't found."
  end
  
  it "should render the reset form when finding a valid reset request" do
    PasswordReset.expects(:find_by_token).with('foo').returns(PasswordReset.new(:user => @user = users(:quentin)))
    get :reset, :token => 'foo'
    response.should render_template('reset')
  end
  
  it "should render a 404 when unable to find a valid reset request" do
    lambda { get :reset, :token => 'foo' }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should update the user password when submitting the reset request" do
    PasswordReset.expects(:find_by_token).with('foo').returns(@pr = PasswordReset.new(:user => @user = users(:quentin)))
    @user.expects(:update_attributes).with(:password => 'bob', :password_confirmation => 'bob').returns(true)
    @pr.expects(:destroy)
    
    post :reset, :token => 'foo', :user => { :password => 'bob', :password_confirmation => 'bob' }
    flash[:notice].should == "Your password has been updated.  Please log in with your new password."
    response.should redirect_to(new_session_url)
  end

  def auth_token(token)
    CGI::Cookie.new('name' => 'auth_token', 'value' => token)
  end
    
  def cookie_for(user)
    auth_token users(user).remember_token
  end
end

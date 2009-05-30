require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  before(:each) do
    controller.stubs(:current_account).returns(@account = accounts(:localhost))
    @user = @account.users.first
  end
  
  it "should prevent listing users if not logged in" do
    get :index
    response.should redirect_to(new_session_url)
  end
  
  describe "with normal users" do
    before(:each) do
      controller.stubs(:current_user).returns(users(:aaron))
    end
    
    it "should allow viewing the index" do
      @account.users.stubs(:find).returns([])
      get :index
      response.should render_template('index')
      assigns(:users).should == []
    end
    
    it "should prevent adding new users" do
      get :new
      response.should redirect_to(new_session_url)
    end
    
    it "should prevent creating users" do
      post :create, :user => { :name => 'bob' }
      response.should redirect_to(new_session_url)
    end
    
    it "should prevent editing users" do
      get :edit, :id => @user.id
      response.should redirect_to(new_session_url)
    end
    
    it "should prevent updating users" do
      put :update, :id => @user.id, :user => { :name => 'bob' }
      response.should redirect_to(new_session_url)
    end
  end
  
  describe "with admin users" do
    before(:each) do
      controller.stubs(:current_user).returns(users(:quentin))
      @account.stubs(:reached_user_limit?).returns(false)
    end

    it "should allow viewing the index" do
      @account.users.stubs(:find).returns([])
      get :index
      response.should render_template('index')
      assigns(:users).should == []
    end

    it "should allow adding users" do
      @account.users.expects(:build).returns(@user = User.new)
      get :new
      assigns(:user).should == @user
      response.should render_template('new')
    end

    it "should allow creating users" do
      @account.users.expects(:build).with(valid_user.stringify_keys).returns(@user = User.new)
      @user.expects(:save).returns(true)
      post :create, :user => valid_user
      response.should redirect_to(users_url)
    end
    
    it "should allow editing users" do
      get :edit, :id => @user.id
      assigns(:user).should == @user
      response.should render_template('edit')
    end
    
    it "should allow updating users" do
      @account.users.expects(:find).with(@user.id.to_s).returns(@user)
      @user.expects(:update_attributes).with(valid_user.stringify_keys).returns(true)
      put :update, :id => @user.id, :user => valid_user
      response.should redirect_to(users_url)
    end
    
    it "should prevent creating users when the user limit has been reached" do
      @account.expects(:reached_user_limit?).returns(true)
      @account.users.expects(:build).returns(@user = User.new)
      @user.expects(:save).never
      post :create, :user => valid_user
      response.should redirect_to(new_user_url)
    end
  end
end
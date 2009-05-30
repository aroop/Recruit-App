# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  skip_before_filter :login_required, :except => :destroy

  def create
    logout_keeping_session!
    user = current_account.users.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  def forgot
    return unless request.post?
    
    if !params[:email].blank? && @user = current_account.users.find_by_email(params[:email])
      PasswordReset.create(:user => @user, :remote_ip => request.remote_ip)
      render :action => 'forgot_complete'
    else
      flash[:error] = "That account wasn't found."
    end
    
  end
  
  def reset
    raise ActiveRecord::RecordNotFound unless @password_reset = PasswordReset.find_by_token(params[:token])
    raise ActiveRecord::RecordNotFound unless @password_reset.user.account == current_account
    
    @user = @password_reset.user
    return unless request.post?
    
    if !params[:user][:password].blank? && 
      if @user.update_attributes(:password => params[:user][:password],
        :password_confirmation => params[:user][:password_confirmation])
        @password_reset.destroy
        flash[:notice] = "Your password has been updated.  Please log in with your new password."
        redirect_to new_session_url
      end
    end
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end

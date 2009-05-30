# This module, included by all controllers in the admin namespace,
# overrides AuthenticatedSystem methods to use browser-based
# authentication rather using a login form.
module AdminControllerMethods
  
  def self.included(base)
    base.send :prepend_before_filter, :check_admin_subdomain
  end
  
  protected
  
    def current_user
      @current_user ||= login_from_basic_auth unless @current_user == false
    end
    
    # This method is called when authentication fails for the admin
    # area.  If you handle authentication in the code, rather than
    # in the web server (see the login_from_basic_auth method), then
    # you'll want to use the commented-out code in this method to
    # display the browser popup to collect the username and password.
    def access_denied
      render :text => 'Access Denied', :status => 403
    end
    
    # def access_denied
    #   request_http_basic_authentication 'Admin Area'
    # end
    
    # Handle logins by HTTP Auth (browser popup).  By default
    # this method just requires that the user be authenticated by
    # the web server, by checking to make sure the REMOTE_USER
    # header has been set.  If you don't want to mess with the web
    # server configuration for doing authentication, you can see the
    # commented-out code for an example of how to do the
    # authentication here.
    def login_from_basic_auth
      !request.headers['REMOTE_USER'].blank?
    end
    
    # def login_from_basic_auth
    #   authenticate_with_http_basic do |username, password|
    #     # This has to return true to let the user in
    #     username == 'bubba' && password == 'gump'
    #   end
    # end
    
    # Since the default, catch-all routes at the bottom of routes.rb
    # allow the admin controllers to be accessed via any subdomain,
    # this before_filter prevents that kind of access, rendering
    # (by default) a 404.
    def check_admin_subdomain
      raise ActionController::RoutingError, "Not Found" unless admin_subdomain?
    end
end
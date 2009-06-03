module SubscriptionSystem

  # Set up some stuff for ApplicationController
  def self.included(base)
    base.send :before_filter, :login_required
    base.send :before_filter, :check_account_status
    base.send :helper_method, :current_account, :admin?, :admin_subdomain?
    base.send :filter_parameter_logging, :password, :creditcard
  end
  
  protected
  
    def current_account
      @current_account ||= Account.find_by_full_domain(request.host)
      # raise ActiveRecord::RecordNotFound unless @current_account
      @current_account
    end
    
    def admin?
      logged_in? && current_user.admin?
    end
    
    def admin_subdomain?
      request.subdomains.first == AppConfig['admin_subdomain']
    end

    def check_account_status
      account_subdomain = request.subdomains.first || ''
      unless account_subdomain == '' || account_subdomain == 'www'
        redirect_to "http://" + request.domain + request.port_string if current_account.nil? 
      end
    end
    
end

# Comments
# => Ajay - Added 'check_account_status' method & line 'base.send :before_filter, :check_account_status'
# => Ajay - Stopped raising exception when account is not found
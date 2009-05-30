class PasswordReset < ActiveRecord::Base
  include TokenGenerator
  
  belongs_to :user
  
  after_create :send_email
  
  protected
  
    def send_email
      SubscriptionNotifier.deliver_password_reset(self)
    end
end

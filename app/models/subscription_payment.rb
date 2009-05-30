class SubscriptionPayment < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :account
  
  before_create :set_account
  after_create :send_receipt
  
  def set_account
    self.account = subscription.account
  end
  
  def send_receipt
    return unless amount > 0
    if setup?
      SubscriptionNotifier.deliver_setup_receipt(self)
    elsif misc?
      SubscriptionNotifier.deliver_misc_receipt(self)
    else
      SubscriptionNotifier.deliver_charge_receipt(self)
    end
    true
  end
  
  def self.stats
    {
      :last_month => calculate(:sum, :amount, :conditions => { :created_at => (1.month.ago.beginning_of_month .. 1.month.ago.end_of_month) }),
      :this_month => calculate(:sum, :amount, :conditions => { :created_at => (Time.now.beginning_of_month .. Time.now.end_of_month) }),
      :last_30 => calculate(:sum, :amount, :conditions => { :created_at => (1.month.ago .. Time.now) })
    }
  end
end

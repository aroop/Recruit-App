class Account < ActiveRecord::Base
  
  has_many :users, :dependent => :destroy
  has_one :admin, :class_name => "User", :conditions => { :admin => true }
  has_one :subscription, :dependent => :destroy
  has_many :subscription_payments
  
  validates_format_of :domain, :with => /\A[a-zA-Z0-9]+\Z/
  validates_exclusion_of :domain, :in => %W( support blog www billing help api #{AppConfig['admin_subdomain']} ), :message => "The domain <strong>{{value}}</strong> is not available."
  validate :valid_domain?
  validate_on_create :valid_user?
  validate_on_create :valid_plan?
  validate_on_create :valid_payment_info?
  validate_on_create :valid_subscription?
  
  attr_accessible :name, :domain, :user, :plan, :plan_start, :creditcard, :address
  attr_accessor :user, :plan, :plan_start, :creditcard, :address
  
  after_create :create_admin
  after_create :send_welcome_email
  
  acts_as_paranoid
  
  Limits = {
    'user_limit' => Proc.new {|a| a.users.count }
  }
  
  Limits.each do |name, meth|
    define_method("reached_#{name}?") do
      return false unless self.subscription
      self.subscription.send(name) && self.subscription.send(name) <= meth.call(self)
    end
  end
  
  def needs_payment_info?
    if new_record?
      AppConfig['require_payment_info_for_trials'] && @plan && @plan.amount.to_f + @plan.setup_amount.to_f > 0
    else
      self.subscription.needs_payment_info?
    end
  end
  
  # Does the account qualify for a particular subscription plan
  # based on the plan's limits
  def qualifies_for?(plan)
    Subscription::Limits.keys.collect {|rule| rule.call(self, plan) }.all?
  end
  
  def active?
    self.subscription.next_renewal_at >= Time.now
  end
  
  def domain
    @domain ||= self.full_domain.blank? ? '' : self.full_domain.split('.').first
  end
  
  def domain=(domain)
    @domain = domain
    self.full_domain = "#{domain}.#{AppConfig['base_domain']}"
  end
  
  def to_s
    name.blank? ? full_domain : "#{name} (#{full_domain})"
  end
  
  protected
  
    def valid_domain?
      conditions = new_record? ? ['full_domain = ?', self.full_domain] : ['full_domain = ? and id <> ?', self.full_domain, self.id]
      self.errors.add(:domain, 'is not available') if self.full_domain.blank? || self.class.count(:conditions => conditions) > 0
    end
    
    # An account must have an associated user to be the administrator
    def valid_user?
      if !@user
        errors.add_to_base("Missing user information")
      elsif !@user.valid?
        @user.errors.full_messages.each do |err|
          errors.add_to_base(err)
        end
      end
    end
    
    def valid_payment_info?
      if needs_payment_info?
        unless @creditcard && @creditcard.valid?
          errors.add_to_base("Invalid payment information")
        end
        
        unless @address && @address.valid?
          errors.add_to_base("Invalid address")
        end
      end
    end
    
    def valid_plan?
      errors.add_to_base("Invalid plan selected.") unless @plan
    end
    
    def valid_subscription?
      return if errors.any? # Don't bother with a subscription if there are errors already
      self.build_subscription(:plan => @plan, :next_renewal_at => @plan_start, :creditcard => @creditcard, :address => @address)
      if !subscription.valid?
        errors.add_to_base("Error with payment: #{subscription.errors.full_messages.to_sentence}")
        return false
      end
    end
    
    def create_admin
      self.user.admin = true
      self.user.account = self
      self.user.save
    end
    
    def send_welcome_email
      SubscriptionNotifier.deliver_welcome(self)
    end
    
end

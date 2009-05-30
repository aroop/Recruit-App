class SubscriptionPlan < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  
  has_many :subscriptions
  
  # renewal_period is the number of months to bill at a time
  # default is 1
  validates_numericality_of :renewal_period, :trial_period, :only_integer => true, :greater_than => 0
  validates_presence_of :name
  
  attr_accessor :discount

  def to_s
    "#{self.name} - #{number_to_currency(self.amount)} / month"
  end
  
  def to_param
    self.name
  end
  
  def amount(include_discount = true)
    include_discount && @discount && @discount.apply_to_recurring? ? self[:amount] - @discount.calculate(self[:amount]) : self[:amount]
  end
  
  def setup_amount(include_discount = true)
    include_discount && setup_amount? && @discount && @discount.apply_to_setup? ? self[:setup_amount] - @discount.calculate(self[:setup_amount]) : self[:setup_amount]
  end
  
  def trial_period(include_discount = true)
    include_discount && @discount ? self[:trial_period] + @discount.trial_period_extension : self[:trial_period]
  end
  
  def revenues
    @revenues ||= subscriptions.calculate(:sum, :amount, :group => 'subscriptions.state')
  end
  
end

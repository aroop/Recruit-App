class SubscriptionDiscount < ActiveRecord::Base
  include Comparable
  class ComparableError < StandardError; end
  
  validates_numericality_of :amount
  validates_presence_of :code, :name
  
  before_save :check_percentage

  attr_accessor :calculated_amount

  def available?
    return false if self.start_on && self.start_on > Time.now.to_date
    return false if self.end_on && self.end_on < Time.now.to_date
    true
  end

  def calculate(subtotal)
    return 0 unless subtotal.to_i > 0
    return 0 unless self.available?
    self.calculated_amount = if self.percent
      (self.amount * subtotal).round(2)
    else
      self.amount > subtotal ? subtotal : self.amount
    end
  end

  def <=>(other)
    return 1 if other.nil?
    raise ComparableError, "Can't compare discounts that are calcuated differently" if percent != other.percent
    amount <=> other.amount
  end

  protected

    def check_percentage
      if self.amount > 1 and self.percent
        self.amount = self.amount / 100
      end
    end

end

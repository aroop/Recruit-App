require File.dirname(__FILE__) + '/../spec_helper'
include ActionView::Helpers::NumberHelper

describe SubscriptionPlan do
  before(:each) do
    @plan = subscription_plans(:basic)
  end

  it "should return a formatted name" do
    @plan.to_s.should == "#{@plan.name} - #{number_to_currency(@plan.amount)} / month"
  end
  
  it "should return the name for URL params" do
    @plan.to_param.should == @plan.name
  end
  
  it "should return a discounted amount with a discount" do
    @plan.discount = SubscriptionDiscount.new(valid_discount)
    @plan.amount.should == @plan[:amount] - 5
  end
  
  it "should not return a discounted amount if the discount does not apply to the periodic charge" do
    @plan.discount = SubscriptionDiscount.new(valid_discount(:apply_to_recurring => false))
    @plan.amount.should == @plan[:amount]
  end
  
  it "should return the full amount with a discount when suppressing the discount" do
    @plan.discount = SubscriptionDiscount.new(valid_discount)
    @plan.amount(false).should == @plan[:amount]
  end
  
  it "should return the full amount without a discount" do
    @plan.discount.should be_nil
    @plan.amount.should == @plan[:amount]
  end
  
  it "should return a discounted setup amount" do
    @plan.discount = SubscriptionDiscount.new(valid_discount(:apply_to_setup => true))
    @plan.setup_amount = 10
    @plan.setup_amount.should == @plan[:setup_amount] - 5
  end
  
  it "should not return a discounted setup amount if the discount does not apply to the setup fee" do
    @plan.discount = SubscriptionDiscount.new(valid_discount(:apply_to_setup => false))
    @plan.setup_amount = 10
    @plan.setup_amount.should == @plan[:setup_amount]
  end
  
  it "should return the default trial period without a discount" do
    @plan.trial_period.should == 1
  end
  
  it "should return the default trial period with a discount with the default trial period extension" do
    @plan.discount = SubscriptionDiscount.new(valid_discount)
    @plan.trial_period.should == 1
  end
  
  it "should return a longer trial period with a discount with trial period extension" do
    @plan.discount = SubscriptionDiscount.new(valid_discount(:trial_period_extension => 2))
    @plan.trial_period.should == 3
  end
  
  def valid_discount(attributes = {})
    {:code => 'foo', :amount => 5}.merge(attributes)
  end
end

require File.dirname(__FILE__) + '/../spec_helper'

describe SubscriptionDiscount do
  before(:each) do
    @discount = SubscriptionDiscount.new(:amount => 5, :code => 'foo')
  end
  
  it "should be 0 for amounts less than or equal to zero" do
    @discount.calculate(0).should == 0
    @discount.calculate(-1).should == 0
  end
  
  it "should not be greater than the subtotal" do
    @discount.calculate(4).should == 4
  end
  
  it "should not be greater than the amount" do
    @discount.calculate(5).should == 5
    @discount.calculate(6).should == 5
  end
  
  it "should calculate based on percentage" do
    @discount = SubscriptionDiscount.new(:amount => 0.1, :percent => true)
    @discount.calculate(78.99.to_d).to_f.should == 7.9
  end
  
  it "should not be available if starting in the future" do
    SubscriptionDiscount.new(:start_on => 1.day.from_now.to_date).should_not be_available
  end
  
  it "should not be available if ended in the past" do
    SubscriptionDiscount.new(:end_on => 1.day.ago.to_date).should_not be_available
  end
  
  it "should be available if started in the past" do
    SubscriptionDiscount.new(:start_on => 1.week.ago.to_date).should be_available
  end
  
  it "should be available if ending in the future" do
    SubscriptionDiscount.new(:end_on => 1.week.from_now.to_date).should be_available
  end
  
  it "should be 0 if not available" do
    @discount = SubscriptionDiscount.new(:amount => 0.1, :percent => true, :end_on => 1.week.ago.to_date)
    @discount.calculate(10).should == 0
  end
  
  it "should be greater than another discount if the amount is greater than the other one" do
    @lesser_discount = SubscriptionDiscount.new(:amount => @discount.amount - 1)
    (@discount > @lesser_discount).should be_true
    (@discount < @lesser_discount).should be_false
  end
  
  it "should not be greater than another discount if the amount is less than the other one" do
    @greater_discount = SubscriptionDiscount.new(:amount => @discount.amount + 1)
    (@discount > @greater_discount).should be_false
    (@discount < @greater_discount).should be_true
  end
  
  it "should be greater than another discount if other one is nil" do
    (@discount > nil).should be_true
    (@discount < nil).should be_false
  end
  
  it "should raise an error when comparing percent vs. amount discounts" do
    @other_discount = SubscriptionDiscount.new(:amount => 0.1, :percent => true)
    lambda { @discount > @other_discount }.should raise_error(SubscriptionDiscount::ComparableError)
  end
  
end
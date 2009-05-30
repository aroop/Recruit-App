require File.dirname(__FILE__) + '/../../spec_helper'

describe "accounts/new" do
  it "should omit the credit card form when creating a free account" do
    assigns[:plan] = @plan = subscription_plans(:free)
    assigns[:account] = Account.new(:plan => @plan)
    render 'accounts/new'
    response.should_not have_tag('input[name=?]', 'creditcard[first_name]')
  end

  it "should include the credit card form when creating a paid account" do
    assigns[:plan] = @plan = subscription_plans(:basic)
    assigns[:creditcard] = @card = ActiveMerchant::Billing::CreditCard.new
    assigns[:address] = @address = SubscriptionAddress.new
    assigns[:account] = @account = Account.new(:plan => @plan)
    @account.stubs(:needs_payment_info?).returns(true)
    render 'accounts/new'
    response.should have_tag('input[name=?]', 'creditcard[first_name]')
  end

  it "should omit the credit card form when creating a paid account without payment info required up-front" do
    AppConfig['require_payment_info_for_trials'] = false
    assigns[:plan] = @plan = subscription_plans(:basic)
    assigns[:creditcard] = @card = ActiveMerchant::Billing::CreditCard.new
    assigns[:address] = @address = SubscriptionAddress.new
    assigns[:account] = @account = Account.new(:plan => @plan)
    @account.stubs(:needs_payment_info?).returns(false)
    render 'accounts/new'
    response.should_not have_tag('input[name=?]', 'creditcard[first_name]')
  end
end
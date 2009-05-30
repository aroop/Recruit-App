require File.dirname(__FILE__) + '/../spec_helper'
include ActiveMerchant::Billing

describe Subscription do
  before(:each) do
    @basic = subscription_plans(:basic)
  end
  
  it "should be created as a trial by default" do
    s = Subscription.new(:plan => @basic)
    s.state.should == 'trial'
  end
  
  it "should be created as active with plans that are free" do
    @basic.amount = 0
    s = Subscription.new(:plan => @basic)
    s.state.should == 'active'
  end
  
  it "should be created with a renewal date a month from now by default" do
    s = Subscription.create(:plan => @basic)
    s.next_renewal_at.at_midnight.should == Time.now.advance(:months => 1).at_midnight
  end
  
  it "should be created with a specified renewal date" do
    s = Subscription.create(:plan => @basic, :next_renewal_at => 1.day.from_now)
    s.next_renewal_at.at_midnight.should == Time.now.advance(:days => 1).at_midnight
  end
  
  it "should be created with a renewal date based on the subscription plan renewal period" do
    @basic.renewal_period = 3
    s = Subscription.create(:plan => @basic)
    s.next_renewal_at.at_midnight.should == Time.now.advance(:months => 3).at_midnight
  end
  
  it "should return the amount in pennies" do
    s = Subscription.new(:amount => 10)
    s.amount_in_pennies.should == 1000
  end
  
  it "should set values from the assigned plan" do
    s = Subscription.new(:plan => @basic)
    s.amount.should == @basic.amount
    s.user_limit.should == @basic.user_limit
  end
  
  it "should need payment info when no card is saved and the plan is not free" do
    Subscription.new(:plan => @basic).needs_payment_info?.should be_true
  end
  
  it "should not need payment info when the card is saved and the plan is not free" do
    Subscription.new(:plan => @basic, :card_number => 'foo').needs_payment_info?.should be_false
  end
  
  it "should not need payment info when no card is saved but the plan is free" do
    @basic.amount = 0
    Subscription.new(:plan => @basic).needs_payment_info?.should be_false
  end
  
  it "should find expiring trial subscriptions" do
    Subscription.expects(:find).with(:all, :include => :account, 
      :conditions => { :state => 'trial', :next_renewal_at => (7.days.from_now.beginning_of_day .. 7.days.from_now.end_of_day) })
    Subscription.find_expiring_trials
  end
  
  it "should find active subscriptions needing payment" do
    Subscription.expects(:find).with(:all, :include => :account, 
      :conditions => { :state => 'active', :next_renewal_at => (Time.now.beginning_of_day .. Time.now.end_of_day) })
    Subscription.find_due
  end
  
  it "should find active subscriptions needing payment in the past" do
    Subscription.expects(:find).with(:all, :include => :account, 
      :conditions => { :state => 'active', :next_renewal_at => (2.days.ago.beginning_of_day .. 2.days.ago.end_of_day) })
    Subscription.find_due(2.days.ago)
  end
  
  describe "when assigned a discounted plan" do
    before(:each) do
      @basic.discount.should be_nil
      @basic_amount = @basic.amount
      @basic.discount = SubscriptionDiscount.new(:code => 'foo', :amount => 2)
    end
    
    it "should set the amount based on the discounted plan amount" do
      s = Subscription.new(valid_subscription)
      s.amount.should == @basic_amount - 2
    end
    
    it "should set the amount based on the account discount, if present" do
      s = Subscription.new(:discount => SubscriptionDiscount.new(:code => 'bar', :amount => 3))
      s.plan = @basic
      s.amount.should == @basic_amount - 3
    end
    
    it "should set the amount based on the plan discount, if larger than the account discount" do
      s = Subscription.new(:discount => SubscriptionDiscount.new(:code => 'bar', :amount => 1))
      s.plan = @basic
      s.amount.should == @basic_amount - 2
    end
    
  end
  
  describe "when being created" do
    before(:each) do
      @sub = Subscription.new(:plan => @basic)
    end
    
    describe "without a credit card" do
      it "should not include card storage in the validation" do
        @sub.expects(:store_card).never
        @sub.should be_valid
      end
    end
    
    describe "with a credit card" do
      before(:each) do
        @sub.creditcard = @card = CreditCard.new(valid_card)
        @sub.address = @address = SubscriptionAddress.new(valid_address)
        @sub.stubs(:gateway).returns(@gw = Base.gateway(:bogus).new)
      end
      
      it "should include card storage in the validation" do
        @sub.expects(:store_card).with(@card, :billing_address => @address.to_activemerchant).returns(true)
        @sub.should be_valid
      end
      
      it "should not be valid if the card storage fails" do
        @gw.expects(:store).returns(Response.new(false, 'Forced failure'))
        @sub.should_not be_valid
        @sub.errors.full_messages.should include('Forced failure')
      end
      
      it "should not be valid if billing fails" do
        @sub.subscription_plan.trial_period = nil
        @gw.expects(:store).returns(BogusResponse.new(true, 'Forced success'))
        @gw.expects(:purchase).returns(BogusResponse.new(false, 'Purchase failure'))
        @sub.should_not be_valid
        @sub.errors.full_messages.should include('Purchase failure')
      end
      
      describe "storing the card" do
        before(:each) do
          @time = Time.now
          Time.stubs(:now).returns(@time)
        end
        
        after(:each) do
          @sub.should be_valid
        end
        
        it "should keep the subscription in trial state" do
          @sub.expects(:state=).never
        end

        it "should not save the subscription" do
          @sub.expects(:save).never
        end

        it "should set the renewal date if not set" do
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 1))
        end
        
        it "should set the renewal date based on the trial period" do
          @sub.subscription_plan.trial_period = 2
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 2))
        end
        
        it "should set the renewal date based on the discount" do
          @sub.subscription_plan.discount = SubscriptionDiscount.new(:amount => 0, :code => 'foo', :trial_period_extension => 2)
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 3))
        end
        
        it "should keep the renewal date when previously set" do
          @sub.next_renewal_at = 1.day.from_now
          @sub.expects(:next_renewal_at=).never
        end
        
        it "should not bill now if there is a trial period" do
          @sub.subscription_plan.trial_period = 1
          @gw.expects(:purchase).never
        end
        
        describe "without a trial period" do
          before(:each) do
            @sub.subscription_plan.trial_period = nil
            @response = Response.new(true, 'Forced Success')
          end
          
          it "should bill now" do
            @gw.expects(:purchase).returns(@response)
          end
          
          it "should bill the setup amount, if any" do
            @sub.subscription_plan.setup_amount = 500
            @gw.expects(:purchase).with(@sub.subscription_plan.setup_amount * 100, 'success').returns(@response)
          end
          
          it "should bill the plan amount, if no setup amount" do
            @sub.subscription_plan.setup_amount = nil
            @gw.expects(:purchase).with(@sub.subscription_plan.amount * 100, 'success').returns(@response)
          end
          
          it "should record the charge with the setup amount" do
            @sub.subscription_plan.setup_amount = 500
            @gw.expects(:purchase).returns(@response)
            @sub.subscription_payments.expects(:build).with(has_entries(:amount => @sub.subscription_plan.setup_amount, :setup => true))
          end
          
          it "should record the charge with the plan amount" do
            @sub.subscription_plan.setup_amount = nil
            @gw.expects(:purchase).returns(@response)
            @sub.subscription_payments.expects(:build).with(has_entries(:amount => @sub.subscription_plan.amount, :setup => false))
          end
        end
      end
    end
  end
  
  describe "" do
    before(:each) do
      @sub = subscriptions(:one)
    end
    
    it "should apply the discount to the amount when changing the discount" do
      @sub.update_attribute(:discount, @discount = subscription_discounts(:sub))
      @sub.amount.should == @sub.subscription_plan.amount(false) - @discount.calculate(@sub.subscription_plan.amount(false))
    end

    it "should reflect the assigned amount, not the amount from the plan" do
      @sub.update_attribute(:amount, @sub.subscription_plan.amount - 1)
      @sub.reload
      @sub.amount.should == @sub.subscription_plan.amount - 1
    end
    
    describe "when destroyed" do
      before(:each) do
        @sub.stubs(:gateway).returns(@gw = Base.gateway(:bogus).new)
        @sub.stubs(:paypal).returns(@pp = Base.gateway(:bogus).new)
      end
      
      it "should delete the stored card info at the gateway" do
        @gw.expects(:unstore).with(@sub.billing_id).returns(true)
        @pp.expects(:unstore).never
        @sub.destroy
      end
    
      it "should not attempt to delete the stored card info with no billing id" do
        @sub.billing_id = nil
        @gw.expects(:unstore).never
        @pp.expects(:unstore).never
        @sub.destroy
      end
      
      it "should destroy the PayPal record if it's a PayPal customer" do
        @sub.expects(:paypal?).returns(true)
        @pp.expects(:unstore).with(@sub.billing_id).returns(true)
        @gw.expects(:unstore).never
        @sub.destroy
      end
    end
    
    describe "when failing to store the card" do
      it "should return false and set the error message to the processor response" do
        @sub.stubs(:gateway).returns(@gw = Base.gateway(:bogus).new)
        @response = Response.new(false, 'Forced failure')
        @gw.expects(:update).returns(@response)
        @card = stub('CreditCard', :display_number => '1111', :expiry_date => CreditCard::ExpiryDate.new(5, 2012))
        @sub.store_card(@card).should be_false
        @sub.errors.full_messages.should include('Forced failure')
      end
    end
    
    describe "when storing the credit card" do
      describe "successfully" do
      before(:each) do
        @time = Time.now
        @sub.stubs(:gateway).returns(@gw = Base.gateway(:bogus).new)
        @response = BraintreeResponse.new(true, 'Forced success', { 'customer_vault_id' => '123' }, { 'authorization' => 'foo' })
        @card = stub('CreditCard', :display_number => '1111', :expiry_date => CreditCard::ExpiryDate.new(5, 2012))
        Time.stubs(:now).returns(@time)
      end
      
      after(:each) do
        @sub.expects(:card_number=).with('1111')
        @sub.expects(:card_expiration=).with('05-2012')
        @sub.expects(:state=).with('active')
        @sub.expects(:save)
        @sub.store_card(@card).should be_true
      end

      describe "for the first time" do
        before(:each) do
          @sub.card_number = nil
          @sub.billing_id = nil
        end
      
        it "should store the card and store the billing id" do
          @gw.expects(:store).with(@card, {}).returns(@response)
          @sub.expects(:billing_id=).with('123')
          @gw.stubs(:purchase).returns(@response)
        end

        it "should bill the amount and set the renewal date a month hence with a renewal date in the past" do
          @sub.next_renewal_at = 2.days.ago
          @gw.stubs(:store).returns(@response)
          @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(@response)
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 1))
        end

        it "should bill the amount and set the renewal date a month hence and with no renewal date" do
          @sub.next_renewal_at = nil
          @gw.stubs(:store).returns(@response)
          @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(@response)
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 1))
        end
      
          it "should not bill and not change the renewal date with a renewal date in the future" do
            @sub.next_renewal_at = @time.advance(:days => 2)
            @gw.stubs(:store).returns(@response)
            @gw.expects(:purchase).never
            @sub.expects(:next_renewal_at=).never
          end

          it "should record the charge with no renewal date" do
          @sub.next_renewal_at = nil
          @gw.stubs(:store).returns(@response)
            @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(@response)
            @sub.subscription_payments.expects(:create).with(has_entry(:amount => @sub.amount))
        end
      
          it "should not record a change with a renewal date in the future" do
          @sub.next_renewal_at = @time.advance(:days => 2)
          @gw.stubs(:store).returns(@response)
          @gw.expects(:purchase).never
            @sub.subscription_payments.expects(:create).never
        end
      end

      describe "subsequent times" do
        before(:each) do
          @gw.stubs(:update).returns(@response)
          @gw.stubs(:purchase).returns(@response)
        end
        
        it "should update the vault when updating an existing card" do
          @gw.expects(:update).with(@sub.billing_id, @card, {}).returns(@response)
        end

        it "should make a purchase and set the renewal date a month hence with a renewal date in the past" do
          @sub.next_renewal_at = 2.days.ago
          @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(@response)
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 1))
        end

        it "should make a purchase and set the renewal date a month hence and with no renewal date" do
          @sub.next_renewal_at = nil
          @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(@response)
          @sub.expects(:next_renewal_at=).with(@time.advance(:months => 1))
        end

          it "should not call the gateway and not change the renewal date with a renewal date in the future" do
            @sub.next_renewal_at = @time.advance(:days => 2)
            @gw.expects(:purchase).never
            @sub.expects(:next_renewal_at=).never
          end

          it "should record the charge with no renewal date" do
          @sub.next_renewal_at = nil
            @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(@response)
            @sub.subscription_payments.expects(:create).with(has_entry(:amount => @sub.amount))
        end

          it "should not record a change with a renewal date in the future" do
          @sub.next_renewal_at = @time.advance(:days => 2)
          @gw.expects(:purchase).never
            @sub.subscription_payments.expects(:create).never
        end
        
        it "should clear out the payment info if switching from paypal" do
          @sub.card_number = 'PayPal'
          @sub.expects(:destroy_gateway_record)
        end
        
        it "should not clear out the payment info if not switching from paypal" do
          @sub.expects(:destroy_gateway_record).never
        end
      end
    end
    
      describe "unsuccessfully" do
        before(:each) do
          @time = Time.now
          @sub.stubs(:gateway).returns(@gw = Base.gateway(:bogus).new)
          @response = BraintreeResponse.new(true, 'Forced success', { 'customer_vault_id' => '123' }, { 'authorization' => 'foo' })
          @card = stub('CreditCard', :display_number => '1111', :expiry_date => CreditCard::ExpiryDate.new(5, 2012))
          Time.stubs(:now).returns(@time)
        end

        after(:each) do
          @sub.expects(:next_renewal_at=).never
          @sub.expects(:state=).never
          @sub.expects(:save).never
          @sub.store_card(@card).should be_false
          @sub.errors.full_messages.should == ['Forced failure']
        end

        it "should return an error message for a failed capture" do
          @sub.next_renewal_at = nil
          @gw.stubs(:store).returns(@response)
          @gw.expects(:purchase).with(@sub.amount_in_pennies, @response.token).returns(Response.new(false, 'Forced failure', {}, { :authorization => 'foo' }))
        end
    
      end
    end
    
    describe "when switching plans" do
      before(:each) do
        @plan = subscription_plans(:advanced)
      end
      
      it "should refuse switching to a plan with a user limit less than the current number of users" do
        @plan.update_attribute(:user_limit, 2)
        @sub.account.users.expects(:count).returns(3)
        @sub.plan = @plan
        @sub.valid?.should be_false
        @sub.errors.full_messages.should include('User limit for new plan would be exceeded.  Please delete some users and try again.')
      end
  
      it "should allow switching to a plan with a user limit greater than the current number of users" do
        @plan.update_attribute(:user_limit, 2)
        @sub.account.users.expects(:count).returns(2)
        @sub.plan = @plan
        @sub.valid?.should be_true
      end
  
      it "should allow switching to a plan with no user limit" do
        @plan.update_attribute(:user_limit, nil)
        @sub.plan = @plan
        @sub.valid?.should be_true
      end
      
      it "should apply the subscription discount to the plan amount" do
        # @sub.update_attribute(:discount, @discount = subscription_discounts(:sub))
        # @sub.update_attribute(:plan, @plan)
        @sub.update_attributes(:plan => @plan, :discount => @discount = subscription_discounts(:sub))
        @sub.amount.should == @plan.amount(false) - @discount.calculate(@plan.amount(false))
      end
    end
    
    describe "when charging" do
      before(:each) do
        @sub.stubs(:gateway).returns(@gw = Base.gateway(:bogus).new)
        @response = Response.new(true, 'Forced success', {:authorized_amount => (@sub.amount * 100).to_s}, :test => true, :authorization => '411')
      end
    
      it "should charge nothing for free accounts and update the renewal date and state" do
        @sub.amount = 0
        @gw.expects(:purchase).never
        @sub.expects(:update_attributes).with(:next_renewal_at => @sub.next_renewal_at.advance(:months => 1), :state => 'active')
        @sub.charge.should be_true
      end
    
      it "should not record a payment when charging nothing" do
        @sub.amount = 0
        @sub.subscription_payments.expects(:create).never
        @sub.charge.should be_true
      end

      it "should charge for paid accounts and update the renewal date and state" do
        @gw.expects(:purchase).with(@sub.amount * 100, @sub.billing_id).returns(@response)
        @sub.expects(:update_attributes).with(:next_renewal_at => @sub.next_renewal_at.advance(:months => 1), :state => 'active')
        @sub.charge.should be_true
      end
      
      it "should record the payment when charging paid accounts" do
        @gw.expects(:purchase).with(@sub.amount * 100, @sub.billing_id).returns(@response)
        @sub.subscription_payments.expects(:create).with(:amount => @sub.amount, :account => @sub.account, :transaction_id => @response.authorization)
        @sub.charge.should be_true
      end
      
      it "should return an error when the processor fails" do
        @gw.expects(:purchase).with(@sub.amount * 100, @sub.billing_id).returns(Response.new(false, 'Oops'))
        @sub.expects(:update_attribute).never
        @sub.subscription_payments.expects(:create).never
        @sub.charge.should be_false
        @sub.errors.full_messages.should include('Oops')
      end
    end

    describe "when starting paypal" do
      before(:each) do
        @gw = Base.gateway(:paypal_express_recurring).new(:login => 'login', :password => 'password', :signature => 'sig')
        @response = PaypalExpressResponse.new(true, 'Forced success', { :token => 'start' })
        Base.gateway(:paypal_express_recurring).expects(:new).returns(@gw)
      end
      
      it "should set up the authorization redirect to start the process" do
        @gw.expects(:setup_agreement).with(:return_url => 'foo', :cancel_return_url => 'bar', :description => AppConfig['app_name']).returns(@response)
        @gw.expects(:redirect_url_for).with('start').returns('http://go')
        @sub.start_paypal('foo', 'bar').should == 'http://go'
      end
    
      it "should report errors with the authorization setup" do
        @response = PaypalExpressResponse.new(false, 'Forced failure')
        @gw.expects(:setup_agreement).returns(@response)
        @gw.expects(:redirect_url_for).never
        @sub.start_paypal('foo', 'bar').should be_false
        @sub.errors.full_messages.should == ['PayPal Error: Forced failure']
      end
    end
    
    describe "when completing paypal" do
      before(:each) do
        @time = Time.now
        Time.stubs(:now).returns(@time)
        @start_date = @sub.next_renewal_at < 1.day.from_now.at_beginning_of_day ? 1.day.from_now : @sub.next_renewal_at
        @gw = Base.gateway(:paypal_express_recurring).new(:login => 'login', :password => 'password', :signature => 'sig')
        @bt = Base.gateway(:braintree).new(:login => 'login', :password => 'password')
        @response = PaypalExpressResponse.new(true, 'Forced success', { 'profile_id' => '890' })
        @details_response = PaypalExpressResponse.new(true, 'Forced success', { 'profile_id' => '890', 'next_billing_date' => @start_date.to_s })
        Base.gateway(:paypal_express_recurring).expects(:new).returns(@gw)
      end
      
      it "should update the billing info with a successful agreement creation" do
        @gw.expects(:create_profile).with('baz', paypal_profile_options).returns(@response)
        @gw.expects(:get_profile_details).with('890').returns(@details_response)
        @sub.expects(:destroy_gateway_record)
        @sub.complete_paypal('baz').should be_true
        @sub.card_number.should == 'PayPal'
        @sub.card_expiration.should == 'N/A'
        @sub.billing_id.should == '890'
        @sub.next_renewal_at.to_i.should == @start_date.to_i
      end
      
      it "should clear the card storage when switching from cc" do
        Base.gateway(AppConfig['gateway']).expects(:new).returns(@bt)
        @bt.expects(:unstore).with(@sub.billing_id)
        @gw.expects(:create_profile).with('baz', paypal_profile_options).returns(@response)
        @gw.expects(:get_profile_details).with('890').returns(@details_response)
        @sub.complete_paypal('baz').should be_true
      end
      
      it "should set errors and fail when failing to create agreement" do
        @gw.expects(:create_profile).with('baz', paypal_profile_options).returns(PaypalExpressResponse.new(false, 'Forced failure'))
        @gw.expects(:get_profile_details).never
        @sub.expects(:card_number=).never
        @sub.expects(:card_expiration=).never
        @sub.expects(:billing_id=).never
        @sub.complete_paypal('baz').should be_false
        @sub.errors.full_messages.should == ['PayPal Error: Forced failure']
      end
    end
  end
end

def paypal_profile_options(opts = {})
  { :description => AppConfig['app_name'], :start_date => @start_date, :frequency => 1, :amount => @sub.amount_in_pennies }.merge(opts)
end
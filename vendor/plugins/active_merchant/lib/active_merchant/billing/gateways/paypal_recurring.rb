require File.dirname(__FILE__) + '/paypal/paypal_common_api'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalRecurringGateway < Gateway
      include PaypalCommonAPI
      
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      self.supported_countries = ['US']
      self.homepage_url = 'https://www.paypal.com/cgi-bin/webscr?cmd=_wp-pro-overview-outside'
      self.display_name = 'PayPal Website Payments Pro (US)'
      
      def store(credit_card, options = {})
        requires!(options, :description, :start_date, :frequency, :amount)

        commit 'CreateRecurringPaymentsProfile', build_create_profile_request(credit_card, options)
      end
      
      # Unsupported.  Destroy existing record, then create a 
      # new one and return it
      def update(billing_id, credit_card, options = {})
        unstore(billing_id)
        store(credit_card, options)
        commit 'UpdateRecurringPaymentsProfile', build_change_profile_request(billing_id, options)        
      end
      
      def unstore(billing_id)
        commit 'ManageRecurringPaymentsProfileStatus', build_manage_profile_request(billing_id, 'Cancel', options)
      end
      
      # Unsupported
      def purchase(amount, billing_id)
        # no-op
      end
      
      def details(billing_id)
        commit 'GetRecurringPaymentsProfileDetails', build_get_profile_details_request(profile_id)
      end

      private
      
      def build_create_profile_request(credit_card, options)
        billing_address = options[:billing_address] || options[:address]
        
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'CreateRecurringPaymentsProfileReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'CreateRecurringPaymentsProfileRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'n2:CreateRecurringPaymentsProfileRequestDetails' do
              
              add_credit_card(xml, credit_card, billing_address, options)
              xml.tag! 'n2:RecurringPaymentsProfileDetails' do
                xml.tag! 'n2:BillingStartDate', (options[:start_date].is_a?(Date) ? options[:start_date].to_time : options[:start_date]).utc.iso8601
                xml.tag! 'n2:ProfileReference', options[:reference] unless options[:reference].blank?
              end
              xml.tag! 'n2:ScheduleDetails' do
                xml.tag! 'n2:Description', options[:description]
                xml.tag! 'n2:PaymentPeriod' do
                  xml.tag! 'n2:BillingPeriod', options[:period] || 'Month'
                  xml.tag! 'n2:BillingFrequency', options[:frequency]
                  xml.tag! 'n2:TotalBillingCycles', options[:cycles] unless options[:cycles].blank?
                  xml.tag! 'n2:Amount', amount(options[:amount]), 'currencyID' => options[:currency] || 'USD'
                end
                if !options[:trialamount].blank?
                  xml.tag! 'n2:TrialPeriod' do
                    xml.tag! 'n2:BillingPeriod', options[:trialperiod] || 'Month'
                    xml.tag! 'n2:BillingFrequency', options[:trialfrequency]
                    xml.tag! 'n2:TotalBillingCycles', options[:trialcycles] || 1
                    xml.tag! 'n2:Amount', amount(options[:trialamount]), 'currencyID' => options[:currency] || 'USD'
                  end        
                end
                if !options[:initialamount].blank? && option[:initialamount].to_i > 0
                  xml.tag! 'n2:ActivationDetails' do
                    xml.tag! 'n2:InitialAmount', amount(options[:initialamount]), 'currencyID' => options[:currency] || 'USD'
                  end        
                end
                xml.tag! 'n2:AutoBillOutstandingAmount', options[:auto_bill_outstanding] ? 'AddToNextBilling' : 'NoAutoBill'
              end
            end
          end
        end

        xml.target!
      end
      
      def add_credit_card(xml, credit_card, address, options)
        xml.tag! 'n2:CreditCard' do
          xml.tag! 'n2:CreditCardType', credit_card_type(card_brand(credit_card))
          xml.tag! 'n2:CreditCardNumber', credit_card.number
          xml.tag! 'n2:ExpMonth', format(credit_card.month, :two_digits)
          xml.tag! 'n2:ExpYear', format(credit_card.year, :four_digits)
          xml.tag! 'n2:CVV2', credit_card.verification_value
          
          if [ 'switch', 'solo' ].include?(card_brand(credit_card).to_s)
            xml.tag! 'n2:StartMonth', format(credit_card.start_month, :two_digits) unless credit_card.start_month.blank?
            xml.tag! 'n2:StartYear', format(credit_card.start_year, :four_digits) unless credit_card.start_year.blank?
            xml.tag! 'n2:IssueNumber', format(credit_card.issue_number, :two_digits) unless credit_card.issue_number.blank?
          end
          
          xml.tag! 'n2:CardOwner' do
            xml.tag! 'n2:PayerName' do
              xml.tag! 'n2:FirstName', credit_card.first_name
              xml.tag! 'n2:LastName', credit_card.last_name
            end
            
            xml.tag! 'n2:Payer', options[:email]
            add_address(xml, 'n2:Address', address)
          end
        end
      end

      def build_change_profile_request(profile_id, options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'UpdateRecurringPaymentsProfileReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'UpdateRecurringPaymentsProfileRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'n2:UpdateRecurringPaymentsProfileRequestDetails' do
              xml.tag! 'ProfileID', profile_id
              xml.tag! 'n2:Note', options[:note] unless options[:note].blank?
              xml.tag! 'n2:Description', options[:description] unless options[:description].blank?
              xml.tag! 'n2:ProfileReference', options[:reference] unless options[:reference].blank?
              xml.tag! 'n2:AdditionalBillingCycles', options[:additional_billing_cycles] unless options[:additional_billing_cycles].blank?
              xml.tag! 'n2:AutoBillOutstandingAmount', options[:auto_bill_outstanding] ? 'AddToNextBilling' : 'NoAutoBill'
              if options.has_key?(:amount)
                xml.tag! 'n2:Amount', amount(options[:amount]), 'currencyID' => options[:currency] || 'USD'
              end
              if options.has_key?(:start_date)
                xml.tag! 'n2:BillingStartDate', (options[:start_date].is_a?(Date) ? options[:start_date].to_time : options[:start_date]).utc.iso8601
              end
            end
          end
        end

        xml.target!
      end
      
      def build_manage_profile_request(profile_id, action, options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'ManageRecurringPaymentsProfileStatusReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'ManageRecurringPaymentsProfileStatusRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'n2:ManageRecurringPaymentsProfileStatusRequestDetails' do
              xml.tag! 'ProfileID', profile_id
              xml.tag! 'n2:Action', action
              xml.tag! 'n2:Note', options[:note] unless options[:note].blank?
            end
          end
        end

        xml.target!
      end

      def build_get_profile_details_request(profile_id)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'GetRecurringPaymentsProfileDetailsReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'GetRecurringPaymentsProfileDetailsRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'ProfileID', profile_id
          end
        end

        xml.target!
      end

      def credit_card_type(type)
        case type
        when 'visa'             then 'Visa'
        when 'master'           then 'MasterCard'
        when 'discover'         then 'Discover'
        when 'american_express' then 'Amex'
        when 'switch'           then 'Switch'
        when 'solo'             then 'Solo'
        end
      end
      
      def build_response(success, message, response, options = {})
         Response.new(success, message, response, options)
      end
    end
  end
end

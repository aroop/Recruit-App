require File.dirname(__FILE__) + '/paypal/paypal_common_api'
require File.dirname(__FILE__) + '/paypal/paypal_express_response'
require File.dirname(__FILE__) + '/paypal_express_common'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalExpressRecurringGateway < Gateway
      include PaypalCommonAPI
      include PaypalExpressCommon

      LIVE_REDIRECT_URL = 'https://www.paypal.com/cgi-bin/webscr?cmd=_customer-billing-agreement&token='
      TEST_REDIRECT_URL = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_customer-billing-agreement&token='
      
      def redirect_url
        test? ? TEST_REDIRECT_URL : LIVE_REDIRECT_URL
      end
      
      def redirect_url_for(token)
        "#{redirect_url}#{token}"
      end

      def setup_agreement(options = {})
        requires!(options, :description, :return_url, :cancel_return_url)
      
        commit 'SetCustomerBillingAgreement', build_setup_request(options)
      end

      def get_agreement(token)
        commit 'GetBillingAgreementCustomerDetails', build_get_agreement_request(token)
      end

      # self.test_redirect_url = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token='
      # self.supported_countries = ['US']
      # self.homepage_url = 'https://www.paypal.com/cgi-bin/webscr?cmd=xpt/merchant/ExpressCheckoutIntro-outside'
      # self.display_name = 'PayPal Express Checkout Recurring'
      # API_VERSION = 50.0

      # def setup_agreement(options = {})
      #   requires!(options, :description, :return_url, :cancel_return_url)
      # 
      #   commit 'SetExpressCheckout', build_setup_request('Authorization', options)
      # end

      def details_for(token)
        commit 'GetExpressCheckoutDetails', build_get_details_request(token)
      end

      def create_profile(token, options = {})
        requires!(options, :description, :start_date, :frequency, :amount)

        commit 'CreateRecurringPaymentsProfile', build_create_profile_request(token, options)
      end

      def get_profile_details(profile_id)
        commit 'GetRecurringPaymentsProfileDetails', build_get_profile_details_request(profile_id)
      end

      def update_profile(profile_id, options = {})
        commit 'UpdateRecurringPaymentsProfile', build_change_profile_request(profile_id, options)
      end

      def cancel_profile(profile_id, options = {})
        commit 'ManageRecurringPaymentsProfileStatus', build_manage_profile_request(profile_id, 'Cancel', options)
      end

      def suspend_profile(profile_id, options = {})
        commit 'ManageRecurringPaymentsProfileStatus', build_manage_profile_request(profile_id, 'Suspend', options)
      end

      def reactivate_profile(profile_id, options = {})
        commit 'ManageRecurringPaymentsProfileStatus', build_manage_profile_request(profile_id, 'Reactivate', options)
      end

      def bill_outstanding_amount(profile_id, options = {})
        commit 'BillOutstandingAmount', build_bill_outstanding_amount(profile_id, options)
      end
      
      def unstore(profile_id)
        cancel_profile(profile_id)
      end

      private

      def build_setup_request(options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'SetCustomerBillingAgreementReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'SetCustomerBillingAgreementRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'n2:SetCustomerBillingAgreementRequestDetails' do
              xml.tag! 'n2:BillingAgreementDetails' do
                xml.tag! 'n2:BillingType', 'RecurringPayments'
                xml.tag! 'n2:BillingAgreementDescription', options[:description]
              end
              xml.tag! 'n2:ReturnURL', options[:return_url]
              xml.tag! 'n2:CancelURL', options[:cancel_return_url]
            end
          end
        end

        xml.target!
      end

      def build_get_agreement_request(token)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'GetBillingAgreementCustomerDetailsReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'GetBillingAgreementCustomerDetailsRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'Token', token
          end
        end

        xml.target!
      end

      # def build_setup_request(action, options)
      #   xml = Builder::XmlMarkup.new :indent => 2
      #   xml.tag! 'SetExpressCheckoutReq', 'xmlns' => PAYPAL_NAMESPACE do
      #     xml.tag! 'SetExpressCheckoutRequest', 'xmlns:n2' => EBAY_NAMESPACE do
      #       xml.tag! 'n2:Version', API_VERSION
      #       xml.tag! 'n2:SetExpressCheckoutRequestDetails' do
      #         xml.tag! 'n2:PaymentAction', action
      #         xml.tag! 'n2:NoShipping', options[:no_shipping] ? '1' : '0'
      #         xml.tag! 'n2:ReturnURL', options[:return_url]
      #         xml.tag! 'n2:CancelURL', options[:cancel_return_url]
      #         xml.tag! 'n2:BillingAgreementDetails' do
      #           xml.tag! 'n2:BillingType', 'RecurringPayments'
      #           xml.tag! 'n2:BillingAgreementDescription', options[:description]
      #         end
      #       end
      #     end
      #   end
      # 
      #   xml.target!
      # end

      def build_get_details_request(token)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'GetExpressCheckoutDetailsReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'GetExpressCheckoutDetailsRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'Token', token
          end
        end

        xml.target!
      end

      def build_create_profile_request(token, options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'CreateRecurringPaymentsProfileReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'CreateRecurringPaymentsProfileRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'n2:CreateRecurringPaymentsProfileRequestDetails' do
              xml.tag! 'Token', token unless token.blank?
              if options[:credit_card]
                xml.tag! 'n2:CreditCard' do
                  xml.tag! 'n2:CreditCardType', options[:credit_card][:type]
                  xml.tag! 'n2:CreditCardNumber', options[:credit_card][:number]
                  xml.tag! 'n2:ExpMonth', options[:credit_card][:exp_month]
                  xml.tag! 'n2:ExpYear', options[:credit_card][:exp_year]
                  xml.tag! 'n2:CVV2', options[:credit_card][:cvv2] unless options[:credit_card][:cvv2].blank?
                  xml.tag! 'n2:CardOwner', options[:credit_card][:card_owner]
                  xml.tag! 'n2:StartMonth', options[:credit_card][:start_month] unless options[:credit_card][:start_month].blank?
                  xml.tag! 'n2:StartYear', options[:credit_card][:start_year] unless options[:credit_card][:start_year].blank?
                  xml.tag! 'n2:IssueNumber', options[:credit_card][:issue_number] unless options[:credit_card][:issue_number].blank?
                end
              end
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
                xml.tag! 'n2:AutoBillOutstandingAmount', options[:auto_bill_outstanding] ? 'AddToNextBilling' : 'NoAutoBill'
              end
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

      def build_bill_outstanding_amount(profile_id, options)
        xml = Builder::XmlMarkup.new :indent => 2
        xml.tag! 'BillOutstandingAmountReq', 'xmlns' => PAYPAL_NAMESPACE do
          xml.tag! 'BillOutstandingAmountRequest', 'xmlns:n2' => EBAY_NAMESPACE do
            xml.tag! 'n2:Version', API_VERSION
            xml.tag! 'ProfileID', profile_id
            if options.has_key?(:amount)
              xml.tag! 'n2:Amount', amount(options[:amount]), 'currencyID' => options[:currency] || 'USD'
            end
            xml.tag! 'n2:Note', options[:note] unless options[:note].blank?
          end
        end

        xml.target!
      end

      def build_response(success, message, response, options = {})
        PaypalExpressResponse.new(success, message, response, options)
      end
    end
  end
end

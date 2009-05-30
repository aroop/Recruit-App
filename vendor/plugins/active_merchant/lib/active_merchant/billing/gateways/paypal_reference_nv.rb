require File.dirname(__FILE__) + '/paypal_nv/paypal_nv_common_api'
require File.dirname(__FILE__) + '/paypal_express_nv'
require File.dirname(__FILE__) + '/paypal_nv/paypal_reference_nv_response'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalReferenceNvGateway < Gateway
      include PaypalNvCommonAPI

      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      self.supported_countries = ['US']
      self.homepage_url = 'https://www.paypal.com/cgi-bin/webscr?cmd=_wp-pro-overview-outside'
      self.display_name = 'PayPal Website Payments Pro (US)'

      def store(money, credit_card, options = {})
        requires!(options, :ip)
        response = commit('DoDirectPayment', build_sale_or_authorization_request('Authorization', 100, credit_card, clean_options(options)))
        void(response.authorization) if response.success?
        response
      end

      def purchase(money, credit_card, options = {})
        commit('DoReferenceTransaction', build_reference_request('Sale', money, credit_card, clean_options(options)))
      end

      # Unsupported
      def unstore(identification, options = {})
        # no-op
      end
      
      # Unsupported.  Just create a new record and return it.
      def update(identification, creditcard, options = {})
        store(100, creditcard, options)
      end
      
      def void(identification, options = {})
        commit('DoVoid', options.merge(:authorizationid => identification))
      end
      
      private

      def build_sale_or_authorization_request(action, money, credit_card_or_reference, options)
        post = {}
        post[:paymentaction] = action
        post[:buttonsource] = application_id.to_s.slice(0,32) unless application_id.blank?
        add_addresses(post, options)
        add_customer_data(post, options)
        add_invoice(post, options)
        add_credit_card(post, credit_card_or_reference)
        add_amount(post, money, options)
        add_subtotals(post, options)
        post
      end

      def build_reference_request(action, money, reference, options)
        post = {}
        post[:paymentaction] = action
        post[:buttonsource] = application_id.to_s.slice(0,32) unless application_id.blank?
        post[:referenceid] = reference
        add_addresses(post, options)
        add_customer_data(post, options)
        add_invoice(post, options)
        add_amount(post, money, options)
        add_subtotals(post, options)
        post
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
      
      def clean_options(options)
        options.merge!(:no_shipping => true)
        options[:billing_address][:country] = Country.find(options[:billing_address][:country]).code(:alpha2).to_s if options[:billing_address]
        options
      end

      def build_response(success, message, response, options = {})
         PaypalReferenceNvResponse.new(success, message, response, options)
      end
    end
  end
end

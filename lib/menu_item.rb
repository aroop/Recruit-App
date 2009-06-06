require 'rubygems'
require 'action_view'
require 'active_support'

class MenuItem
  include ActionView::Helpers::TagHelper,
            ActionView::Helpers::UrlHelper
            
  attr_accessor :path, :title, :html_class, :active, :visible, :children
  
  def initialize(title, path, html_class=nil, active=false, visible=true)
    @title, @path, @html_class, @active, @visible = title, path, html_class, active, visible
    @children = []
  end
  
  def active(controller)
    puts "---------------------------------"
    puts "#{children}"
    puts "---------------------------------"
    @@controller = controller
    children.any?(&:on_current_page?) || on_current_page?
  end
  
  def on_current_page?
    current_page?(@path)
  end
  
  cattr_accessor :controller
    def controller # make it available to current_page? in UrlHelper
      @@controller
    end
  
end

# Yep, monkey patch ActionView's UrlHelper
# All that changes here is s/@controller/controller
module ActionView
  module Helpers #:nodoc:
    module UrlHelper
      def current_page?(options)
        url_string = CGI.escapeHTML(url_for(options))
        request = controller.request
        if url_string =~ /^\w+:\/\//
          url_string == "#{request.protocol}#{request.host_with_port}#{request.request_uri}"
        else
          url_string == request.request_uri
        end
      end
    end
  end
end
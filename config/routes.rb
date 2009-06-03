ActionController::Routing::Routes.draw do |map|
  map.resources :contacts

  # The priority is based upon order of creation: first created -> highest priority.

  # Admin stuff for the website
  map.with_options(:conditions => {:subdomain => AppConfig['admin_subdomain']}) do |subdom|
    subdom.root :controller => 'subscription_admin/subscriptions', :action => 'index'
    subdom.with_options(:namespace => 'subscription_admin/', :name_prefix => 'admin_', :path_prefix => nil) do |admin|
      admin.resources :subscriptions, :member => { :charge => :post }
      admin.resources :accounts
      admin.resources :subscription_plans, :as => 'plans'
      admin.resources :subscription_discounts, :as => 'discounts'
    end
  end
  
  # Marketing website
  map.with_options(:conditions => {:subdomain => ''}) do |subdom|
    subdom.root :controller => "static", :action => "index"
    subdom.with_options :controller => "static" do |main| 
      main.tour '/tour', :action => 'tour'
      main.blog '/blog', :action => 'blog'
      main.support '/support', :action => 'support'
      main.contact '/contact', :action => 'contact'
    end
  end
  
  map.with_options(:conditions => {:subdomain => 'www'}) do |subdom|
    subdom.root :controller => "static", :action => "index"
    subdom.with_options :controller => "static" do |main| 
      main.tour '/tour', :action => 'tour'
      main.blog '/blog', :action => 'blog'
      main.support '/support', :action => 'support'
      main.contact '/contact', :action => 'contact'
    end
  end
  
  map.root :controller => "contacts"

  # Login & Logout
  map.login 'login', :controller => 'sessions', :action => 'new'
  map.login 'logout', :controller => 'sessions', :action => 'destroy'

  # See how all your routes lay out with "rake routes"
  map.plans '/signup', :controller => 'accounts', :action => 'plans'
  map.connect '/signup/d/:discount', :controller => 'accounts', :action => 'plans'
  map.thanks '/signup/thanks', :controller => 'accounts', :action => 'thanks'
  map.create '/signup/create/:discount', :controller => 'accounts', :action => 'create', :discount => nil
  map.resource :account, :collection => { :dashboard => :get, :thanks => :get, :plans => :get, :billing => :any, :paypal => :any, :plan => :any, :plan_paypal => :any, :cancel => :any, :canceled => :get }
  map.new_account '/signup/:plan/:discount', :controller => 'accounts', :action => 'new', :plan => nil, :discount => nil
  
  map.resources :users
  map.resource :session
  map.forgot_password '/account/forgot', :controller => 'sessions', :action => 'forgot'
  map.reset_password '/account/reset/:token', :controller => 'sessions', :action => 'reset'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end

# Sample of regular route:
#   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
# Keep in mind you can assign values other than :controller and :action

# Sample of named route:
#   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
# This route can be invoked with purchase_url(:id => product.id)

# Sample resource route (maps HTTP verbs to controller actions automatically):
#   map.resources :products

# Sample resource route with options:
#   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

# Sample resource route with sub-resources:
#   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

# Sample resource route within a namespace:
#   map.namespace :admin do |admin|
#     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
#     admin.resources :products
#   end

# You can have the root of your site routed with map.root -- just remember to delete public/index.html.

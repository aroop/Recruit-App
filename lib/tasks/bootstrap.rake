namespace :db do
  desc 'Load an initial set of data'
  task :bootstrap => :environment do
    puts 'Creating tables...'
    Rake::Task["db:migrate"].invoke
    
    puts 'Loading data...'
    if SubscriptionPlan.count == 0
      plans = [
        { 'name' => 'Free', 'amount' => 0, 'user_limit' => 1, 'storage' => nil, 'ssl_support' => false },
        { 'name' => 'Solo', 'amount' => 14, 'user_limit' => 2, 'storage' => 1, 'ssl_support' => true  },
        { 'name' => 'Basic', 'amount' => 24, 'user_limit' => 6, 'storage' => 3, 'ssl_support' => true  },
        { 'name' => 'Plus', 'amount' => 49, 'user_limit' => 15, 'storage' => 10, 'ssl_support' => true },
        { 'name' => 'Premium', 'amount' => 99, 'user_limit' => 40, 'storage' => 20, 'ssl_support' => true },
        { 'name' => 'Max', 'amount' => 149, 'user_limit' => nil, 'storage' => 50, 'ssl_support' => true }
      ].collect do |plan|
        SubscriptionPlan.create(plan)
      end
    end
    
    user = User.new(:name => 'Test', :login => 'test', :password => 'test', :password_confirmation => 'test', :email => 'test@example.com')
    a = Account.create(:name => 'Test Account', :domain => 'localhost', :plan => plans.first, :user => user)
    a.update_attribute(:full_domain, 'localhost')
    
    # puts 'Changing secret in environment.rb...'
    # new_secret = ActiveSupport::SecureRandom.hex(64)
    # config_file_name = File.join(RAILS_ROOT, 'config', 'environment.rb')
    # config_file_data = File.read(config_file_name)
    # File.open(config_file_name, 'w') do |file|
    #   file.write(config_file_data.sub('9cb7f8ec7e560956b38e35e5e3005adf68acaf1f64600950e2f7dc9e6485d6d9c65566d193204316936b924d7cc72f54cad84b10a70a0257c3fd16e732152565', new_secret))
    # end
    # 
    puts "All done!  You can now login to the test account at the localhost domain with the login test and password test.\n\n"
  end
end
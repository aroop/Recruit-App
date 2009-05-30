class SubscriptionGenesis < ActiveRecord::Migration
  def self.up
    create_table "accounts", :force => true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "full_domain"
      t.datetime "deleted_at"
    end
    
    add_index 'accounts', 'full_domain'

    create_table "password_resets", :force => true do |t|
      t.string   "email"
      t.integer  "user_id",    :limit => 11
      t.string   "remote_ip"
      t.string   "token"
      t.datetime "created_at"
    end

    create_table "subscription_discounts", :force => true do |t|
      t.string   "name"
      t.string   "code"
      t.decimal  "amount",             :precision => 6, :scale => 2, :default => 0.0
      t.boolean  "percent"
      t.date     "start_on"
      t.date     "end_on"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "apply_to_setup",                                   :default => true
      t.boolean  "apply_to_recurring",                               :default => true
      t.integer  "trial_period_extension", :default => 0
    end

    create_table "subscription_payments", :force => true do |t|
      t.integer  "account_id",      :limit => 11
      t.integer  "subscription_id", :limit => 11
      t.decimal  "amount",                        :precision => 10, :scale => 2, :default => 0.0
      t.string   "transaction_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "setup"
      t.boolean  "misc"
    end
    
    add_index 'subscription_payments', 'account_id'
    add_index 'subscription_payments', 'subscription_id'

    create_table "subscription_plans", :force => true do |t|
      t.string   "name"
      t.decimal  "amount",                       :precision => 10, :scale => 2
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_limit",     :limit => 11
      t.integer  "renewal_period", :limit => 11,                                :default => 1
      t.decimal  "setup_amount",                 :precision => 10, :scale => 2
      t.integer  "trial_period",   :limit => 11,                                :default => 1
    end

    create_table "subscriptions", :force => true do |t|
      t.decimal  "amount",                                 :precision => 10, :scale => 2
      t.datetime "next_renewal_at"
      t.string   "card_number"
      t.string   "card_expiration"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "state",                                                                 :default => "trial"
      t.integer  "subscription_plan_id",     :limit => 11
      t.integer  "account_id",               :limit => 11
      t.integer  "user_limit",               :limit => 11
      t.integer  "renewal_period",           :limit => 11,                                :default => 1
      t.string   "billing_id"
      t.integer  "subscription_discount_id", :limit => 11
    end
    
    add_index 'subscriptions', 'account_id'

    if table_exists?('users')
      add_column :users, :admin, :boolean, :default => true
      add_column :users, :account_id, :integer
    else
      create_table "users", :force => true do |t|
        t.string   "login"
        t.string   "email"
        t.string   "name"
        t.string   "remember_token"
        t.string   "crypted_password",          :limit => 40
        t.string   "salt",                      :limit => 40
        t.datetime "remember_token_expires_at"
        t.datetime "updated_at"
        t.datetime "created_at"
        t.integer  "account_id",                :limit => 11
        t.boolean  "admin",                                   :default => false
      end
    end
    
    add_index 'users', 'account_id'
  end

  def self.down
  end
end

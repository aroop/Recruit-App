class AddStorageToPlan < ActiveRecord::Migration
  def self.up
    add_column :subscription_plans, :storage, :integer
    add_column :subscription_plans, :ssl_support, :boolean
  end

  def self.down
    remove_column :subscription_plans, :storage
    remove_column :subscription_plans, :ssl_support
  end
end

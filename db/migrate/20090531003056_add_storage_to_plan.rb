class AddStorageToPlan < ActiveRecord::Migration
  def self.up
    add_column :subscription_plans, :storage, :integer
  end

  def self.down
    remove_column :subscription_plans, :storage
    
  end
end

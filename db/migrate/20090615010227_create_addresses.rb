class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.text :street_address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end

class CreatePhoneNumbers < ActiveRecord::Migration
  def self.up
    create_table :phone_numbers do |t|
      t.references :phone_number_type
      t.string :value
      t.references :address
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_numbers
  end
end

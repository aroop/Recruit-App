class CreatePhoneNumberTypes < ActiveRecord::Migration
  def self.up
    create_table :phone_number_types do |t|
      t.string :name
    end
    PhoneNumberType.reset_column_information
    %w"Work Mobile Fax Pager Home Skype Other".each do |type| 
      phone_number_type = PhoneNumberType.new
      phone_number_type.name = type
      phone_number_type.save!
    end
  end

  def self.down
    drop_table :phone_number_types
  end
end

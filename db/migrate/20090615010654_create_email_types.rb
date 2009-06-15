class CreateEmailTypes < ActiveRecord::Migration
  def self.up
    create_table :email_types do |t|
      t.string :name
    end
    EmailType.reset_column_information
    %w"Work Home Other".each do |type| 
      email_type = EmailType.new
      email_type.name = type
      email_type.save!
    end
  end

  def self.down
    drop_table :email_types
  end
end

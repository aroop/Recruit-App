class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.references :email_type
      t.string :value
      t.references :address
      t.timestamps
    end
  end

  def self.down
    drop_table :emails
  end
end

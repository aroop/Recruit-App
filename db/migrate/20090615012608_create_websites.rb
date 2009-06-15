class CreateWebsites < ActiveRecord::Migration
  def self.up
    create_table :websites do |t|
      t.string :value
      t.references :website_type
      t.references :address
      t.timestamps
    end
  end

  def self.down
    drop_table :websites
  end
end

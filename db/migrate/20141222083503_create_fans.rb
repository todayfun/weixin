class CreateFans < ActiveRecord::Migration
  def change
    create_table :fans do |t|
      t.string :openid
      t.string :nickname
      t.string :sex
      t.string :city
      t.time :subscribe_time

      t.timestamps
    end
    
    add_index :fans,:openid
  end
end

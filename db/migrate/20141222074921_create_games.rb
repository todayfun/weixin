class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :guid
      t.string :title
      t.string :banner
      t.text :wxdata
      t.text :args
      t.text :rule
      t.text :winners
      t.datetime :start_at
      t.datetime :end_at
      t.string :status
      t.string :stamp

      t.timestamps
    end
    
    add_index :games,:guid
    add_index :games,:status
    add_index :games,:stamp
  end
end

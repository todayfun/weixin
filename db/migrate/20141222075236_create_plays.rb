class CreatePlays < ActiveRecord::Migration
  def change
    create_table :plays do |t|
      t.string :guid
      t.string :game_guid
      t.string :owner
      t.float :score
      t.text :args
      t.text :friends
      t.text :friend_plays
      t.time :start_at
      t.time :end_at
      t.string :status
      t.string :stamp

      t.timestamps
    end
    
    add_index :plays,:guid
    add_index :plays,:game_guid
    add_index :plays,:owner
    add_index :plays,:score
    add_index :plays,:status
    add_index :plays,:stamp
  end
end

# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141222083503) do

  create_table "fans", :force => true do |t|
    t.string   "openid"
    t.string   "nickname"
    t.string   "sex"
    t.string   "city"
    t.time     "subscribe_time"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "fans", ["openid"], :name => "index_fans_on_openid"

  create_table "games", :force => true do |t|
    t.string   "guid"
    t.string   "title"
    t.string   "banner"
    t.text     "wxdata"
    t.text     "args"
    t.text     "rule"
    t.text     "winners"
    t.time     "start_at"
    t.time     "end_at"
    t.string   "status"
    t.string   "stamp"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "games", ["guid"], :name => "index_games_on_guid"
  add_index "games", ["stamp"], :name => "index_games_on_stamp"
  add_index "games", ["status"], :name => "index_games_on_status"

  create_table "plays", :force => true do |t|
    t.string   "guid"
    t.string   "game_guid"
    t.string   "owner"
    t.float    "score"
    t.text     "args"
    t.text     "friends"
    t.text     "friend_plays"
    t.time     "start_at"
    t.time     "end_at"
    t.string   "status"
    t.string   "stamp"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "plays", ["game_guid"], :name => "index_plays_on_game_guid"
  add_index "plays", ["guid"], :name => "index_plays_on_guid"
  add_index "plays", ["owner"], :name => "index_plays_on_owner"
  add_index "plays", ["score"], :name => "index_plays_on_score"
  add_index "plays", ["stamp"], :name => "index_plays_on_stamp"
  add_index "plays", ["status"], :name => "index_plays_on_status"

end

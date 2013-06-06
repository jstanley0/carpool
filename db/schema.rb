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

ActiveRecord::Schema.define(:version => 20130516143750) do

  create_table "car_pools", :force => true do |t|
    t.string   "name"
    t.float    "ride_cost",    :default => 12.0
    t.integer  "schedule_id"
    t.string   "start_place"
    t.string   "start_time"
    t.string   "return_place"
    t.string   "return_time"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "car_pools", ["schedule_id"], :name => "index_car_pools_on_schedule_id"

  create_table "drivers", :force => true do |t|
    t.integer  "user_id"
    t.integer  "car_pool_id"
    t.float    "balance",     :default => 0.0
    t.integer  "schedule_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "drivers", ["car_pool_id"], :name => "index_drivers_on_car_pool_id"
  add_index "drivers", ["schedule_id"], :name => "index_drivers_on_schedule_id"
  add_index "drivers", ["user_id"], :name => "index_drivers_on_user_id"

  create_table "rides", :force => true do |t|
    t.integer  "car_pool_id"
    t.date     "date"
    t.integer  "driver_id"
    t.boolean  "charged"
    t.text     "participants"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "rides", ["car_pool_id"], :name => "index_rides_on_car_pool_id"
  add_index "rides", ["date"], :name => "index_rides_on_date"
  add_index "rides", ["driver_id"], :name => "index_rides_on_driver_id"

  create_table "schedules", :force => true do |t|
    t.boolean "mon",        :default => true
    t.boolean "tue",        :default => true
    t.boolean "wed",        :default => true
    t.boolean "thu",        :default => true
    t.boolean "fri",        :default => true
    t.boolean "sat",        :default => false
    t.boolean "sun",        :default => false
    t.text    "exceptions"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "notify_address"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end

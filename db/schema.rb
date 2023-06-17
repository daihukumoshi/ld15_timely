# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_06_16_071914) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "timescaledb"

  create_table "comments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "commenter_id"
    t.string "comment"
    t.datetime "time"
    t.string "img"
    t.boolean "reaction"
  end

  create_table "friends", force: :cascade do |t|
    t.integer "following_id"
    t.integer "followed_id"
  end

  create_table "needs", force: :cascade do |t|
    t.integer "user_id"
    t.string "needtime"
    t.datetime "pushtime"
  end

  create_table "statuses", force: :cascade do |t|
    t.integer "user_id"
    t.integer "task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "user_id"
    t.string "task_name"
    t.integer "minutes"
  end

  create_table "users", force: :cascade do |t|
    t.string "user_name"
    t.string "password_digest"
    t.string "display_name"
  end

end

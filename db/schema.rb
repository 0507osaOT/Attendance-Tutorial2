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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20240717221110) do

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "status"
    t.string "note"
    t.integer "user_id"
    t.datetime "overtime"
    t.string "approval"
    t.string "overtime_content"
    t.string "overtime_instructor"
    t.string "work_status"
    t.string "work_instructor"
    t.datetime "chg_started_at"
    t.datetime "chg_finished_at"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "bases", force: :cascade do |t|
    t.string "base_number"
    t.string "base_name"
    t.string "attendance_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "monthly_attendances", force: :cascade do |t|
    t.string "month"
    t.string "year"
    t.string "instructor"
    t.string "master_status"
    t.integer "user_id"
    t.string "approval"
    t.index ["user_id"], name: "index_monthly_attendances_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "department"
    t.datetime "basic_time", default: "2024-04-16 23:00:00"
    t.datetime "work_time", default: "2024-04-16 22:30:00"
    t.string "employee_number"
    t.string "uid"
    t.string "affiliation"
    t.datetime "basic_work_time", default: "2022-12-07 22:30:00"
    t.datetime "designated_work_start_time", default: "2022-12-08 00:30:00"
    t.datetime "designated_work_end_time", default: "2022-12-08 09:00:00"
    t.boolean "superior", default: false
    t.boolean "superior_flag"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end

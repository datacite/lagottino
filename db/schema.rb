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

ActiveRecord::Schema.define(version: 2018_09_07_134519) do

  create_table "events", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.text "uuid", null: false
    t.string "subj_id", limit: 191, null: false
    t.string "obj_id", limit: 191
    t.string "source_id", limit: 191
    t.string "aasm_state"
    t.string "state_event"
    t.text "callback"
    t.text "error_messages"
    t.text "source_token"
    t.datetime "created_at", precision: 3, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.datetime "indexed_at", default: "1970-01-01 00:00:00", null: false
    t.datetime "occurred_at"
    t.string "message_action", limit: 191, default: "create", null: false
    t.string "relation_type_id", limit: 191
    t.text "subj"
    t.text "obj"
    t.integer "total", default: 1
    t.string "license", limit: 191
    t.index ["source_id", "created_at"], name: "index_events_on_source_id_created_at"
    t.index ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", unique: true
    t.index ["updated_at"], name: "index_events_on_updated_at"
    t.index ["uuid"], name: "index_events_on_uuid", unique: true, length: 36
  end

end

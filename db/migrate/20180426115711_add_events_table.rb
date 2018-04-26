class AddEventsTable < ActiveRecord::Migration[5.2]
  def up
    create_table "events", force: :cascade do |t|
      t.text     "uuid",                   limit: 65535,                      null: false
      t.string   "subj_id",                limit: 191,                      null: false
      t.string   "obj_id",                 limit: 191
      t.string   "source_id",              limit: 191
      t.string  "aasm_state"
      t.string   "state_event",            limit: 255
      t.text     "callback",               limit: 65535
      t.text     "error_messages",         limit: 65535
      t.text     "source_token",           limit: 65535
      t.datetime "created_at",                                                null: false
      t.datetime "updated_at",                                                null: false
      t.datetime "indexed_at",             default: '1970-01-01 00:00:00',    null: false
      t.datetime "occurred_at"
      t.string   "message_action",         limit: 191, default: "create",     null: false
      t.string   "relation_type_id",       limit: 191
      t.text     "subj",                   limit: 65535
      t.text     "obj",                    limit: 65535
      t.integer  "total",                  limit: 4,     default: 1
    end

    add_index "events", ["subj_id"], name: "index_events_on_subj_id", using: :btree
    add_index "events", ["source_id", "created_at"], name: "index_events_on_source_id_created_at", using: :btree
    add_index "events", ["updated_at"], name: "index_events_on_updated_at", using: :btree

    create_table "sources", force: :cascade do |t|
      t.string   "name",        limit: 191
      t.string   "title",       limit: 255,                                   null: false
      t.string   "group_id",    limit: 191
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "description", limit: 65535
      t.boolean  "private",                   default: false
      t.boolean  "cumulative",                default: false
    end

    add_index "sources", ["name"], name: "index_sources_on_name", unique: true, using: :btree
  end
end

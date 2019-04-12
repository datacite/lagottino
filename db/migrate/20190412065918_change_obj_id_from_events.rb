class ChangeObjIdFromEvents < ActiveRecord::Migration[5.2]
  def up
    remove_index :events, column: ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", unique: true
    change_column :events, :subj_id, :text, null: false, :limit => 65535
    change_column :events, :obj_id, :text, :limit => 65535
    # Only 40 character for the index (the sieze of a IPv6 address) there is max for the index of 3072 Bytes.
    add_index :events, ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", :length => {:subj_id => 199, :obj_id => 40}, unique: true
  end

  def down
    remove_index :events, name: "index_events_on_multiple_columns"
    change_column :events, :subj_id, :string, limit: 191, null: false
    change_column :events, :obj_id, :string, limit: 191
    add_index :events, column: ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", unique: true
  end
end

class ChangeObjIdFromEvents < ActiveRecord::Migration[5.2]
  def up
    remove_index :events, column: ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", unique: true
    change_column :events, :subj_id, :text, null: false, :limit => 65535
    change_column :events, :obj_id, :text, :limit => 65535
    add_index :events, ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", :length => {:subj_id => 191, :obj_id => 191}, unique: true
  end

  def down
    remove_index :events, name: "index_events_on_multiple_columns"
    change_column :events, :subj_id, :string, limit: 191, null: false
    change_column :events, :obj_id, :string, limit: 191
    add_index :events, column: ["subj_id", "obj_id", "source_id", "relation_type_id"], name: "index_events_on_multiple_columns", unique: true
  end
end

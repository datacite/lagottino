class AddUniqueEventIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :events, [:subj_id, :obj_id, :source_id, :relation_type_id], unique: true, name: "index_events_on_multiple_columns"
    remove_index :events, column: [:subj_id], name: "index_events_on_subj_id"
    drop_table :sources
  end
end

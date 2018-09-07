class AddUuidIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :events, [:uuid], name: "index_events_on_uuid", length: 36, unique: true
  end
end

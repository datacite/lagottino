class AddIndexForIndexedAt < ActiveRecord::Migration[5.2]
  def up
    add_index :events, ["created_at", "indexed_at", "updated_at"], name: "index_events_on_created_indexed_updated"
  end

  def down
    remove_index :events, column: ["created_at", "indexed_at", "updated_at"], name: "index_events_on_created_indexed_updated"
  end
end

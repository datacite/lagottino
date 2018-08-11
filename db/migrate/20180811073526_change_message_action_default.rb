class ChangeMessageActionDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:events, :message_action, from: "add", to: "create")
  end
end

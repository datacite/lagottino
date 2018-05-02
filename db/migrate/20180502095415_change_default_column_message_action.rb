class ChangeDefaultColumnMessageAction < ActiveRecord::Migration[5.2]
  def up
    change_column_default :events, :message_action, 'add'
  end

  def down
    change_column_default :events, :message_action, 'create'
  end
end

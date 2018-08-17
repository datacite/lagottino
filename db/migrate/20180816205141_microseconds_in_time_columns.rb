class MicrosecondsInTimeColumns < ActiveRecord::Migration[5.2]
  def up
    change_column :events, :created_at, :datetime, limit: 3
    change_column :events, :updated_at, :datetime, limit: 3
  end

  def down
    change_column :events, :created_at, :datetime
    change_column :events, :updated_at, :datetime
  end
end

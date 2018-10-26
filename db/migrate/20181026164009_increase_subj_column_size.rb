class IncreaseSubjColumnSize < ActiveRecord::Migration[5.2]
  def up
    change_column :events, :subj, :text, :limit => 16777215
    change_column :events, :obj, :text, :limit => 16777215
  end

  def down
    change_column :events, :subj, :text
    change_column :events, :obj, :text
  end
end

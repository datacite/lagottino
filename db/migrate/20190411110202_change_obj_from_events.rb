class ChangeObjFromEvents < ActiveRecord::Migration[5.2]
  def up
    change_column :events, :subj_id, :string,  limit: 255
    change_column :events, :obj_id, :string,  limit: 255
  end

  def down
    change_column :events, :subj_id
    change_column :events, :obj_id
  end
end

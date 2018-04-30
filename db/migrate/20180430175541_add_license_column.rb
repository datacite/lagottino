class AddLicenseColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :license, :string, limit: 191
  end
end

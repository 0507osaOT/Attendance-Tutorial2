class AddDetailsToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :approval, :string
    add_column :attendances, :overtime_content, :string
    #add_column :attendances, :status, :string
  end
end

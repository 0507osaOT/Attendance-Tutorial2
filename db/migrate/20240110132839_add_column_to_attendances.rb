class AddColumnToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_instructor, :string
  end
end

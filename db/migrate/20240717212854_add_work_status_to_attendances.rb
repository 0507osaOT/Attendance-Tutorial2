class AddWorkStatusToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :work_status, :string
  end
end

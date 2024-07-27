class AddWorkApprovalToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :work_approval, :string
  end
end

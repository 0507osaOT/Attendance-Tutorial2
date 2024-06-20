class AddApprovalToMonthlyAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :monthly_attendances, :approval, :string
  end
end

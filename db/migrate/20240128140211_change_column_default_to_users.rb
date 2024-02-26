class ChangeColumnDefaultToUsers < ActiveRecord::Migration[5.1]
  def change
    change_column_default :users, :designated_work_start_time, from: nil, to: "2022-12-08 00:30:00"
    change_column_default :users, :designated_work_end_time, from: nil, to: "2022-12-08 09:00:00"
    change_column_default :users, :basic_work_time, from: nil, to: "2022-12-07 22:30:00"
  end
end

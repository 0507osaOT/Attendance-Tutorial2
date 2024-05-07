class CreateMonthlyAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :monthly_attendances do |t|
      t.string "month" #申請する勤怠情報の月
      t.string "year"  #申請する勤怠情報の年
      t.string "instructor"  #申請先の上長
      t.string "master_status" #申請状態
      t.references :user, foreign_key: true  #申請者のユーザーid
      
    end
  end
end

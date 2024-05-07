class CreateAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :attendances do |t|
      t.date :worked_on
      t.datetime :started_at
      t.datetime :finished_at
      t.string :status  # 正しい型で定義する
      t.string :note
      t.references :user, foreign_key: true
    end
  end
end

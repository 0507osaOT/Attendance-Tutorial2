class CreateBases < ActiveRecord::Migration[6.0]
  def change
    create_table :bases do |t|
      t.string :base_number
      t.string :base_name
      t.string :attendance_type

      t.timestamps
    end
  end
end
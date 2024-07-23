class AddWorkInstructorToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :work_instructor, :string
  end
end

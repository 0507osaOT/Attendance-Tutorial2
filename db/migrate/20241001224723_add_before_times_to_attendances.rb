class AddBeforeTimesToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :before_finished_at, :datetime
  end
end

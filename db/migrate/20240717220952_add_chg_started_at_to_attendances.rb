class AddChgStartedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :chg_started_at, :datetime
  end
end

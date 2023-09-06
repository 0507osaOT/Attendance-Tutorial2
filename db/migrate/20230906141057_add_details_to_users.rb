class AddDetailsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :affiliation, :string
    add_column :users, :basic_work_time, :datetime
    add_column :users, :designated_work_start_time, :datetime
    add_column :users, :designated_work_end_time, :datetime
    add_column :users, :superior, :boolean, default: false
  end
end

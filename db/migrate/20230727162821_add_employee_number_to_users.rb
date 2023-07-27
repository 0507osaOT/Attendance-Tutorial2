# db/migrate/20230521093142_add_employee_number_to_users.rb

class AddEmployeeNumberToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :employee_number, :string
  end
end
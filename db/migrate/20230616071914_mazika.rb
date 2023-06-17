class Mazika < ActiveRecord::Migration[6.1]
  def change
    add_column(:comments, :img, :string)
    add_column(:comments, :reaction, :boolean)
  end
end

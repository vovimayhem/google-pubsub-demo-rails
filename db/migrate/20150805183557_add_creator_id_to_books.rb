class AddCreatorIdToBooks < ActiveRecord::Migration[5.2]
  def change
    add_column :books, :creator_id, :string
    add_index  :books, :creator_id
  end
end

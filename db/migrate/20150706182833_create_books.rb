class CreateBooks < ActiveRecord::Migration[5.2]
  def change
    create_table :books do |t|
      t.string :title, required: true
      t.string :author
      t.date :published_on
      t.text :description

      t.timestamps null: false
    end
  end
end

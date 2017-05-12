class CreateTask < ActiveRecord::Migration[5.0]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :content
      t.string :status

      t.timestamps
    end
  end
end

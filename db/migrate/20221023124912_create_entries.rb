class CreateEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :entries do |t|
      t.string :title
      t.string :url
      t.datetime :published_at
      t.text :content
      t.integer :feed_id
      t.integer :reading_time
      t.integer :external_id

      t.timestamps
    end
  end
end

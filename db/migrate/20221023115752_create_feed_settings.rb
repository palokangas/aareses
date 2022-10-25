class CreateFeedSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :feed_settings do |t|
      t.integer :user_id
      t.integer :rss_provider_id
      t.string :token

      t.timestamps
    end
  end
end

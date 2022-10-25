class AddDetailsToFeeds < ActiveRecord::Migration[7.0]
  def change
    add_column :feeds, :external_id, :integer
    add_column :feeds, :title, :string
    add_column :feeds, :site_url, :string
    add_column :feeds, :checked_at, :datetime
    add_column :feeds, :category_id, :integer
  end
end

class AddUserToFeeds < ActiveRecord::Migration[7.0]
  def change
    add_column :feeds, :user_id, :integer
  end
end

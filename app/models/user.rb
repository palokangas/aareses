class User < ApplicationRecord
  has_many :feed_setting
  has_many :feeds
end

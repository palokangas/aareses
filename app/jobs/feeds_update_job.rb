class FeedsUpdateJob < ApplicationJob
  queue_as :default
  class ConnectionException < StandardError; end

  retry_on ConnectionException

  discard_on ActiveJob::DeserializationError

  def perform(command: "full_update", id: nil)
    # Let's assume we always have the same user and only one rss_backend
    user = User.find(1)
    settings = FeedSetting.where(user_id: user, rss_provider_id: 1).first
    client = FeedsHelper::Miniflux.new(settings&.token)

    case command
    when "full_update"
      full_update(client, user)
    when "mark_entry_read"
      client.mark_entry_read(id)
    when "mark_feed_read"
      client.mark_feed_read(id)
    end
  end

  private

  def full_update(client, user)
    res = client.feeds
    unless res.ok?
      logger.debug "Error refreshing feeds. Invalid request result."
      raise ConnectionException
    end

    feeds = JSON.parse(res.body)
    new_feed_ids = update_feeds(user, feeds)
    update_entries(new_feed_ids, client)
  end

  # Update all entries on all feeds one feed at a time
  def update_entries(new_feed_ids, client)
    new_feed_ids.each do |ext_id|
      feed_id = Feed.find_by(external_id: ext_id)&.id
      new_entries = client.entries_for(feed_ext_id: ext_id)
      new_entry_ids = new_entries["entries"]&.map { |entry| entry["id"] }
      logger.debug("Destroying entries that were removed from server")

      existing_entries = Entry.where(feed_id: feed_id)
      existing_entries.where.not(external_id: [new_entry_ids]).destroy_all
      existing_entries_ids = existing_entries.pluck(:external_id)

      new_entries["entries"].each do |entry|
        next if existing_entries_ids.include?(entry["id"])
        Entry.create(
          external_id: entry["id"],
          title: entry["title"],
          url: entry["url"],
          published_at: entry["published_at"],
          content: entry["content"],
          reading_time: entry["reading_time"],
          feed_id: feed_id
        )
      end
    end
  end

  # Add any new feeds and remove ones that were removed from server
  def update_feeds(user, feeds)
    existing_feeds_ids = user.feeds.all.pluck(:external_id)
    refreshed_feed_ids = []

    nr_old_feeds = 0
    nr_new_feeds = 0
    feeds.each do |feed|
      if existing_feeds_ids.include?(feed["id"])
        nr_old_feeds += 1
        refreshed_feed_ids.append(existing_feeds_ids.delete(feed["id"]))
      else
        user.feeds.create(
          title: feed["title"],
          external_id: feed["id"],
          site_url: feed["site_url"],
          category_id: feed.dig("category", "id")
        )
        nr_new_feeds += 1
        refreshed_feed_ids.append(feed["id"])
        puts "Feed #{feed["title"]} succesfully added to #{user.name}'s feeds."
      end
    end
    logger.debug "Added #{nr_new_feeds} new feeds."
    logger.debug "Kept #{nr_old_feeds} old feeds."
    user.feeds.where(external_id: existing_feeds_ids).destroy_all
    logger.debug "Destroyed #{existing_feeds_ids.length} feeds that were removed from rss backend."

    refreshed_feed_ids
  end
end

module FeedsHelper
  class Miniflux
    include HTTParty
    base_uri 'https://uutistutka.fi/rss/v1'

    def initialize(token)
      @headers = { "X-Auth-Token" => token}
      @logger = Rails.logger
    end

    def debug(msg)
      @logger.debug(msg)
    end

    def feeds
      self.class.get("/feeds", headers: @headers)
    end

    def mark_entry_read(id)
      body = {
        entry_ids: [id],
        status: "read"
      }.to_json

      response = self.class.put("/entries", {
        body: body,
        headers: @headers.merge({'Content-Type' => 'application/json'})
      })

      if response.success?
        debug "Succesfully marked entry #{id} read on server."
      else
        res_json = JSON.parse(response.body)
        debug "Error when marking entry #{id} read on server. Server returned #{res_json["error_message"]}"
      end
    end

    def entries_for(feed_ext_id:, status: "unread")
      self.class.get("/feeds/#{feed_ext_id}/entries?status=#{status}", headers: @headers)
    end

    def entries(status: "unread")
      self.class.get("/entries?status=#{status}", headers: @headers)
    end

    def me
      self.class.get("/me", headers: @headers)
    end
  end
end

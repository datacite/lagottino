class Client

  def self.find_by_ids(ids)
    url = ENV['API_URL'] + "/clients?ids=" + ids
    response = Maremma.get(url, content_type: 'application/vnd.api+json')

    if response.status == 200
      response.body["data"].reduce({}) do |sum, c|
        sum["datacite.#{c.dig("id")}"] = c.dig("attributes", "name")
        sum
      end
    elsif response.body["errors"].present?
      Rails.logger.info "Client API returned an error: #{response.body['errors'].first['title']}"
    end
  end
end
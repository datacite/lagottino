class Member

  def self.find_by_ids(ids)
    logger = Logger.new(STDOUT)

    url = ENV['API_URL'] + "/clients?ids=" + ids
    response = Maremma.get(url, content_type: 'application/vnd.api+json')
    
    if response.status == 200
      response.body["data"].map { |c| { "id" => c.dig("id"), "name" => c.dig("attributes", "name") }}
    elsif response.body["errors"].present?
      logger.info "Client API returned an error: #{response.body['errors'].first['title']}"
    end
  end
end
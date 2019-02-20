class Event < ActiveRecord::Base
  # include helper module for query caching
  include Cacheable

  # include event processing
  include Processable

  # include doi normalization
  include Identifiable

  # include helper module for Elasticsearch
  include Indexable
  
  include Elasticsearch::Model

  before_validation :set_defaults

  validates :uuid, format: { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i }

  # include state machine
  include AASM

  aasm :whiny_transitions => false do
    state :waiting, :initial => true
    state :working, :failed, :done

    # Reset after failure
    event :reset do
      transitions from: [:failed], to: :waiting
    end

    event :start do
      transitions from: [:waiting], to: :working
    end

    event :finish do
      transitions from: [:working], to: :done
    end

    event :error do
      transitions to: :failed
    end
  end


  #   after_transition :to => [:failed, :done] do |event|
  #     event.send_callback if event.callback.present?
  #   end

  #   after_transition :failed => :waiting do |event|
  #     event.queue_event_job
  #   end

  serialize :subj, JSON
  serialize :obj, JSON
  serialize :error_messages, JSON

  validates :subj_id, :source_id, :source_token, presence: true

  attr_accessor :container_title, :url

  # use different index for testing
  index_name Rails.env.test? ? "events-test" : "events"

  mapping dynamic: 'false' do
    indexes :uuid,             type: :keyword
    indexes :subj_id,          type: :keyword
    indexes :obj_id,           type: :keyword
    indexes :doi,              type: :keyword
    indexes :orcid,            type: :keyword
    indexes :prefix,           type: :keyword
    indexes :subtype,          type: :keyword
    indexes :citation_type,    type: :keyword
    indexes :issn,             type: :keyword
    indexes :subj,             type: :object, properties: {
      "@type" => { type: :keyword },
      "@id" => { type: :keyword },
      uid: { type: :keyword },
      name: { type: :text },
      givenName: { type: :text },
      familyName: { type: :text },
      author: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text }
      }},
      periodical: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text },
        "issn" => { type: :keyword }
      }},
      alternateName: { type: :text },
      volumeNumber: { type: :keyword },
      issueNumber: { type: :keyword },
      pagination: { type: :keyword },
      publisher: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text }
      }},
      funder: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text }
      }},
      proxyIdentifiers: { type: :keyword },
      version: { type: :keyword },
      datePublished: { type: :date, format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      dateModified: { type: :date, format: "date_optional_time", ignore_malformed: true },
      registrantId: { type: :keyword },
      cache_key: { type: :keyword }
    }
    indexes :obj,               type: :object, properties: {
      type: { type: :keyword },
      id: { type: :keyword },
      uid: { type: :keyword },
      name: { type: :text },
      givenName: { type: :text },
      familyName: { type: :text },
      author: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text }
      }},
      periodical: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text },
        "issn" => { type: :keyword }
      }},
      alternateName: { type: :text },
      volumeNumber: { type: :keyword },
      issueNumber: { type: :keyword },
      pagination: { type: :keyword },
      publisher: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text }
      }},
      funder: { type: :object, properties: {
        "@type" => { type: :keyword },
        "@id" => { type: :keyword },
        name: { type: :text }
      }},
      proxyIdentifiers: { type: :keyword },
      version: { type: :keyword },
      datePublished: { type: :date, format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      dateModified: { type: :date, format: "date_optional_time", ignore_malformed: true },
      registrantId: { type: :keyword },
      cache_key: { type: :keyword }
    }
    indexes :source_id,        type: :keyword
    indexes :source_token,     type: :keyword
    indexes :message_action,   type: :keyword
    indexes :relation_type_id, type: :keyword
    indexes :registrant_id,    type: :keyword
    indexes :access_method,    type: :keyword
    indexes :metric_type,      type: :keyword
    indexes :total,            type: :integer
    indexes :license,          type: :text, fields: { keyword: { type: "keyword" }}
    indexes :error_messages,   type: :object
    indexes :callback,         type: :text
    indexes :aasm_state,       type: :keyword
    indexes :state_event,      type: :keyword
    indexes :year_month,       type: :keyword
    indexes :created_at,       type: :date
    indexes :updated_at,       type: :date
    indexes :indexed_at,       type: :date
    indexes :occurred_at,      type: :date
    indexes :cache_key,        type: :keyword
  end

  def as_indexed_json(options={})
    {
      "uuid" => uuid,
      "subj_id" => subj_id,
      "obj_id" => obj_id,
      "subj" => subj.merge(cache_key: subj_cache_key),
      "obj" => obj.merge(cache_key: obj_cache_key),
      "doi" => doi,
      "orcid" => orcid,
      "issn" => issn,
      "prefix" => prefix,
      "subtype" => subtype,
      "citation_type" => citation_type,
      "source_id" => source_id,
      "source_token" => source_token,
      "message_action" => message_action,
      "relation_type_id" => relation_type_id,
      "registrant_id" => registrant_id,
      "access_method" => access_method,
      "metric_type" => metric_type,
      "total" => total,
      "license" => license,
      "error_messages" => error_messages,
      "aasm_state" => aasm_state,
      "state_event" => state_event,
      "year_month" => year_month,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "indexed_at" => indexed_at,
      "occurred_at" => occurred_at,
      "cache_key" => cache_key
    }
  end

  def self.query_fields
    ['subj_id^10', 'obj_id^10', 'subj.name^5', 'subj.author^5', 'subj.periodical^5', 'subj.publisher^5', 'obj.name^5', 'obj.author^5', 'obj.periodical^5', 'obj.publisher^5', '_all']
  end

  def self.query_aggregations
    {
      sources: { terms: { field: 'source_id', size: 50, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 50, min_doc_count: 1 } },
      registrants: { terms: { field: 'registrant_id', size: 50, min_doc_count: 1 }, aggs: { year: { date_histogram: { field: 'occurred_at', interval: 'year', min_doc_count: 1 }, aggs: { "total_by_year" => { sum: { field: 'total' }}}}} },
      pairings: { terms: { field: 'registrant_id', size: 50, min_doc_count: 1 }, aggs: { recipient: { terms: { field: 'registrant_id', size: 50, min_doc_count: 1 }, aggs: { "total" => { sum: { field: 'total' }}}}} },
      citation_types: { terms: { field: 'citation_type', size: 50, min_doc_count: 1 }, aggs: { year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' }}}}} },
      relation_types: { terms: { field: 'relation_type_id', size: 50, min_doc_count: 1 }, aggs: { year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' }}}}} },
      dois: { terms: { field: 'obj_id', size: 50, min_doc_count: 1 }, aggs: { relation_types: { terms: { field: 'relation_type_id',size: 50, min_doc_count: 1 }, aggs: { "total_by_type" => { sum: { field: 'total' }}}}} }
    }
  end

  def self.index(options={})
    from_id = (options[:from_id] || 1).to_i
    until_id = (options[:until_id] || from_id + 499).to_i

    # get every id between from_id and until_id
    (from_id..until_id).step(500).each do |id|
      EventIndexByIdJob.perform_later(id: id)
      puts "Queued indexing for events with IDs starting with #{id}."
    end
  end

  def self.index_by_id(options={})
    return nil unless options[:id].present?
    id = options[:id].to_i

    errors = 0
    count = 0

    logger = Logger.new(STDOUT)

    Event.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |events|
      response = Event.__elasticsearch__.client.bulk \
        index:   Event.index_name,
        type:    Event.document_type,
        body:    events.map { |event| { index: { _id: event.id, data: event.as_indexed_json } } }

      # log errors
      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      response['items'].select { |k, v| k.values.first['error'].present? }.each do |err|
        logger.error "[Elasticsearch] " + err.inspect
      end

      count += events.length
    end

    if errors > 1
      logger.error "[Elasticsearch] #{errors} errors indexing #{count} events with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      logger.info "[Elasticsearch] Indexed #{count} events with IDs #{id} - #{(id + 499)}."
    end
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    logger.info "[Elasticsearch] Error #{error.message} indexing events with IDs #{id} - #{(id + 499)}."

    count = 0

    Event.where(id: id..(id + 499)).find_each do |event|
      IndexJob.perform_later(event)
      count += 1
    end

    logger.info "[Elasticsearch] Indexed #{count} events with IDs #{id} - #{(id + 499)}."
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def send_callback
    data = { "data" => {
               "id" => uuid,
               "type" => "events",
               "state" => aasm_state,
               "errors" => error_messages,
               "messageAction" => message_action,
               "sourceToken" => source_token,
               "total" => total,
               "timestamp" => timestamp }}
    Maremma.post(callback, data: data.to_json, token: ENV['API_KEY'])
  end
  def access_method
    if relation_type_id.to_s =~ /(requests|investigations)/
      relation_type_id.split("-").last if relation_type_id.present?
    end
  end

  def metric_type
    if relation_type_id.to_s =~ /(requests|investigations)/
      arr = relation_type_id.split("-", 4)
      arr[0..2].join("-")
    end
  end

  def doi
    Array.wrap(subj["proxyIdentifiers"]).grep(/\A10\.\d{4,5}\/.+\z/) { $1 } +
    Array.wrap(obj["proxyIdentifiers"]).grep(/\A10\.\d{4,5}\/.+\z/) { $1 } +
    Array.wrap(subj["funder"]).map { |f| doi_from_url(f["@id"]) }.compact +
    Array.wrap(obj["funder"]).map { |f| doi_from_url(f["@id"]) }.compact +
    [doi_from_url(subj_id), doi_from_url(obj_id)].compact
  end

  def prefix
    [doi.map { |d| d.to_s.split('/', 2).first }].compact
  end

  def orcid
    Array.wrap(subj["author"]).map { |f| orcid_from_url(f["@id"]) }.compact +
    Array.wrap(obj["author"]).map { |f| orcid_from_url(f["@id"]) }.compact +
    [orcid_from_url(subj_id), orcid_from_url(obj_id)].compact
  end

  def issn
    Array.wrap(subj.dig("periodical", "issn")).compact + 
    Array.wrap(obj.dig("periodical", "issn")).compact
  rescue TypeError
    nil
  end

  def registrant_id
    [subj["registrantId"], obj["registrantId"], subj["provider_id"], obj["provider_id"]].compact
  end

  def subtype
    [subj["@type"], obj["@type"]].compact
  end

  def citation_type
    return nil if subj["@type"].blank? || subj["@type"] == "CreativeWork" || obj["@type"].blank? || obj["@type"] == "CreativeWork"

   [subj["@type"], obj["@type"]].compact.sort.join("-")
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end

  def orcid_from_url(url)
    Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
  end

  def timestamp
    updated_at.utc.iso8601 if updated_at.present?
  end

  def year_month
    occurred_at.utc.iso8601[0..6] if occurred_at.present?
  end

  def cache_key
    timestamp = updated_at || Time.zone.now
    "events/#{uuid}-#{timestamp.iso8601}"
  end

  def subj_cache_key
    timestamp = subj["dateModified"] || Time.zone.now.iso8601
    "objects/#{subj_id}-#{timestamp}"
  end

  def obj_cache_key
    timestamp = obj["dateModified"] || Time.zone.now.iso8601
    "objects/#{obj_id}-#{timestamp}"
  end

  def set_defaults
    self.uuid = SecureRandom.uuid if uuid.blank?
    self.subj_id = normalize_doi(subj_id) || subj_id
    self.obj_id = normalize_doi(obj_id) || obj_id

    # make sure subj and obj have correct id
    self.subj = subj.to_h.merge("id" => self.subj_id)
    self.obj = obj.to_h.merge("id" => self.obj_id)
    
    self.total = 1 if total.blank?
    self.relation_type_id = "references" if relation_type_id.blank?
    self.occurred_at = Time.zone.now.utc if occurred_at.blank?
    self.license = "https://creativecommons.org/publicdomain/zero/1.0/" if license.blank?
  end
end
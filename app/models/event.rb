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
    indexes :prefix,           type: :keyword
    indexes :type,             type: :keyword
    indexes :citation_type,    type: :keyword
    indexes :subj,             type: :object, properties: {
      type: { type: :keyword },
      id: { type: :keyword },
      name: { type: :text },
      author: { type: :object },
      periodical: { type: :text },
      "alternate-name" => { type: :text },
      "volume-number" => { type: :keyword },
      "issue-number" => { type: :keyword },
      pagination: { type: :keyword },
      publisher: { type: :keyword },
      version: { type: :keyword },
      issn: { type: :keyword },
      "date-published" => { type: :date, format: "yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      "provider-id" => { type: :keyword }
    }
    indexes :obj,              type: :object, properties: {
      type: { type: :keyword },
      id: { type: :keyword },
      name: { type: :text },
      author: { type: :object },
      periodical: { type: :text },
      "alternate-name" => { type: :text },
      "volume-number" => { type: :keyword },
      "issue-number" => { type: :keyword },
      pagination: { type: :keyword },
      publisher: { type: :keyword },
      version: { type: :keyword },
      issn: { type: :keyword },
      "date-published" => { type: :date, format: "date_optional_time||yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      "provider-id" => { type: :keyword }
    }
    indexes :source_id,        type: :keyword
    indexes :source_token,     type: :keyword
    indexes :message_action,   type: :keyword
    indexes :relation_type_id, type: :keyword
    indexes :provider_id,      type: :keyword
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
      "subj" => subj,
      "obj" => obj,
      "doi" => doi,
      "prefix" => prefix,
      "type" => type,
      "citation_type" => citation_type,
      "source_id" => source_id,
      "source_token" => source_token,
      "message_action" => message_action,
      "relation_type_id" => relation_type_id,
      "provider_id" => provider_id,
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
    ['subj_id^10', 'obj_id^10', '_all']
  end

  def self.query_aggregations
    {
      sources: { terms: { field: 'source_id', size: 50, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 50, min_doc_count: 1 } },
      citation_types: { terms: { field: 'citation_type', size: 50, min_doc_count: 1 }, aggs: { year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' }}}}} },
      relation_types: { terms: { field: 'relation_type_id', size: 50, min_doc_count: 1 }, aggs: { year_months: { date_histogram: { field: 'occurred_at', interval: 'month', min_doc_count: 1 }, aggs: { "total_by_year_month" => { sum: { field: 'total' }}}}} }
    }
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
               "message_action" => message_action,
               "source_token" => source_token,
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
    [doi_from_url(subj_id), doi_from_url(obj_id)].compact
  end

  def prefix
    [doi.map { |d| d.to_s.split('/', 2).first }].compact
  end

  def provider_id
    [subj["provider-id"], obj["provider-id"]].compact
  end

  def type
    [subj["type"], obj["type"]].compact
  end

  def citation_type
    return nil if subj["type"].blank? || subj["type"] == "creative-work" || obj["type"].blank? || obj["type"] == "creative-work"

   [subj["type"], obj["type"]].compact.sort.join("-")
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
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

  def set_defaults
    self.uuid = SecureRandom.uuid if uuid.blank?
    self.subj_id = normalize_doi(subj_id) || subj_id
    self.obj_id = normalize_doi(obj_id) || obj_id
    self.subj = {} if subj.blank?
    self.obj = {} if obj.blank?
    self.total = 1 if total.blank?
    self.relation_type_id = "references" if relation_type_id.blank?
    self.occurred_at = Time.zone.now.utc if occurred_at.blank?
    self.license = "https://creativecommons.org/publicdomain/zero/1.0/" if license.blank?
  end
end
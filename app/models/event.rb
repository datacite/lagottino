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

  # after_commit :queue_event_job, :on => :create

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

  scope :by_state, ->(state) { where("aasm_state = ?", state) }
  scope :order_by_date, -> { order("updated_at DESC") }

  # use different index for testing
  index_name Rails.env.test? ? "events-test" : "events"

  mapping dynamic: 'false' do
    indexes :uuid,             type: :keyword
    indexes :subj_id,          type: :keyword
    indexes :obj_id,           type: :keyword
    indexes :source_id,        type: :keyword
    indexes :source_token,     type: :keyword
    indexes :message_action,   type: :keyword
    indexes :relation_type_id, type: :keyword
    indexes :total,            type: :integer
    indexes :license,          type: :text, fields: { keyword: { type: "keyword" }}
    indexes :error_messages,   type: :text
    indexes :callback,         type: :text
    indexes :aasm_state,       type: :keyword
    indexes :state_event,      type: :keyword
    indexes :created_at,    type: :date
    indexes :updated_at,    type: :date
    indexes :indexed_at,    type: :date
    indexes :occurred_at,   type: :date
  end

  def as_indexed_json(options={})
    {
      "uuid" => uuid,
      "subj_id" => subj_id,
      "obj_id" => obj_id,
      "source_id" => source_id,
      "source_token" => source_token,
      "message_action" => message_action,
      "relation_type_id" => relation_type_id,
      "total" => total,
      "license" => license,
      "error_messages" => error_messages,
      "aasm_state" => aasm_state,
      "state_event" => state_event,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "indexed_at" => indexed_at,
      "occurred_at" => occurred_at
    }
  end

  def self.query_fields
    ['subj_id^10', 'obj_id^10', '_all']
  end

  def self.query_aggregations
    {
      years: { date_histogram: { field: 'occurred-at', interval: 'year', min_doc_count: 1 } },
      months: { date_histogram: { field: 'occurred-at', interval: 'year', min_doc_count: 1 } }
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

  def timestamp
    updated_at.utc.iso8601 if updated_at.present?
  end

  def cache_key
    "events/#{uuid}-#{timestamp}"
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
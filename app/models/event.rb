class Event < ActiveRecord::Base
  # include helper module for query caching
  include Cacheable

  # include event processing
  include Processable

  belongs_to :work, inverse_of: :events, autosave: true, foreign_key: :subj_id, primary_key: :pid
  belongs_to :related_work, class_name: "Work", inverse_of: :events, autosave: true, foreign_key: :obj_id, primary_key: :pid
  belongs_to :source, primary_key: :name, inverse_of: :events

  before_create :create_uuid
  before_save :set_defaults
  after_commit :queue_event_job, :on => :create

  # include state machine
  include AASM

  aasm :whiny_transitions => false do
    state :waiting, :initial => true
    state :working, :failed, :done

    # event :start do
    #   transitions :from => :undetermined, :to => :draft, :after => Proc.new { set_to_inactive }
    # end

    # event :register do
    #   # can't register test prefix
    #   transitions :from => [:undetermined, :draft], :to => :registered, :unless => :is_test_prefix?, :after => Proc.new { set_to_inactive }

    #   transitions :from => :undetermined, :to => :draft, :after => Proc.new { set_to_inactive }
    # end

    # event :publish do
    #   # can't index test prefix
    #   transitions :from => [:undetermined, :draft, :registered], :to => :findable, :unless => :is_test_prefix?, :after => Proc.new { set_to_active }

    #   transitions :from => :undetermined, :to => :draft, :after => Proc.new { set_to_inactive }
    # end

    # event :hide do
    #   transitions :from => [:findable], :to => :registered, :after => Proc.new { set_to_inactive }
    # end

    # event :flag do
    #   transitions :from => [:registered, :findable], :to => :flagged
    # end

    # event :link_check do
    #   transitions :from => [:tombstoned, :registered, :findable, :flagged], :to => :broken
    # end
  end

  # NB this is coupled to events_controller, event.rake
  # state_machine :initial => :waiting do
  #   state :waiting, value: 0
  #   state :working, value: 1
  #   state :failed, value: 2
  #   state :done, value: 3

  #   after_transition :to => [:failed, :done] do |event|
  #     event.send_callback if event.callback.present?
  #   end

  #   after_transition :failed => :waiting do |event|
  #     event.queue_event_job
  #   end

  #   # Reset after failure
  #   event :reset do
  #     transition [:failed] => :waiting
  #     transition any => same
  #   end

  #   event :start do
  #     transition [:waiting] => :working
  #     transition any => same
  #   end

  #   event :finish do
  #     transition [:working] => :done
  #     transition any => same
  #   end

  #   event :error do
  #     transition any => :failed
  #   end
  # end

  serialize :subj, JSON
  serialize :obj, JSON
  serialize :error_messages, JSON

  validates :subj_id, :source_id, :source_token, presence: true
  validates_associated :source

  scope :by_state, ->(state) { where("state = ?", state) }
  scope :order_by_date, -> { order("updated_at DESC") }

  scope :waiting, -> { by_state(0).order_by_date }
  scope :working, -> { by_state(1).order_by_date }
  scope :failed, -> { by_state(2).order_by_date }
  scope :stuck, -> { where(state: [0,1]).where("updated_at < ?", Time.zone.now - 24.hours).order_by_date }
  scope :done, -> { by_state(3).order_by_date }
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def source
    cached_source(source_id)
  end

  def send_callback
    data = { "data" => {
               "id" => uuid,
               "type" => "events",
               "state" => human_state_name,
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

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
  end

  def set_defaults
    write_attribute(:subj, {}) if subj.blank?
    write_attribute(:obj, {}) if obj.blank?
    write_attribute(:total, 1) if total.blank?
    write_attribute(:relation_type_id, "references") if relation_type_id.blank?
    write_attribute(:occurred_at, Time.zone.now.utc) if occurred_at.blank?
  end
end
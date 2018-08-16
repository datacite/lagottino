class EventSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :events
  set_id :uuid
  # cache_options enabled: true, cache_length: 24.hours
  
  attributes :subj_id, :obj_id, :message_action, :source_token, :relation_type_id, :source_id, :total, :license, :occurred_at, :timestamp, :subj, :obj
  
  attribute :timestamp, &:updated_at

  attribute :subj do |object|
    object.try(:subj) || {}
  end

  attribute :obj do |object|
    object.try(:obj) || {}
  end
end

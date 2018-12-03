class EventSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :events
  set_id :uuid
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :subj_id, :obj_id, :source_id, :relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp
  
  belongs_to :subj, serializer: ObjectSerializer, record_type: :objects
  belongs_to :obj, serializer: ObjectSerializer, record_type: :objects

  attribute :subj do |object|
    object.subj.compact
  end

  attribute :obj do |object|
    object.obj.compact
  end
  
  attribute :timestamp, &:updated_at
end

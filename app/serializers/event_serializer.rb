class EventSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :events
  set_id :uuid
  #cache_options enabled: true, cache_length: 24.hours
  
  attributes :source_id, :relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp
  
  belongs_to :subj, serializer: ObjectSerializer, record_type: :objects #, if: Proc.new { |record| record.subj && record.subj["uid"] }
  belongs_to :obj, serializer: ObjectSerializer, record_type: :objects #, if: Proc.new { |record| record.obj && record.obj["uid"] }

  attribute :timestamp, &:updated_at
end

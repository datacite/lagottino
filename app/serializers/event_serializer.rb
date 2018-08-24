class EventSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :events
  set_id :uuid
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :message_action, :source_token, :relation_type_id, :source_id, :total, :license, :occurred_at, :timestamp
  
  belongs_to :subj, serializer: ObjectSerializer, record_type: :objects, if: Proc.new { |record| record.subj.uid.present? }
  belongs_to :obj, serializer: ObjectSerializer, record_type: :objects, if: Proc.new { |record| record.obj.uid.present? }

  attribute :timestamp, &:updated_at
end

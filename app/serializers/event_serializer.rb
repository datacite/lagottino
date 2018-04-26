class EventSerializer < ActiveModel::Serializer
  cache key: 'event'
  attributes :id, :state, :message_action, :source_token, :callback, :subj_id, :obj_id, :relation_type_id, :source_id, :total, :occurred_at, :subj, :obj

  def id
    object.to_param
  end

  def state
    object.aasm_state
  end

  def updated
    object.updated_at.iso8601
  end

  def occured_at
    object.occured_at.iso8601
  end
end

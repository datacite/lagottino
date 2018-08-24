class ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :objects
  set_id :id
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :name, :author, :periodical, "volume-number", "issue-number", :pagination, :publisher, :issn, :version, "date-published"

  belongs_to :provider
  

  attribute :timestamp, &:updated_at
end

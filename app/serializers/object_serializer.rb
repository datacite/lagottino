class ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :objects
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :subtype, :name, :author, :periodical, :volume_number, :issue_number, :pagination, :publisher, :issn, :version, :date_published

  attribute :subtype do |object|
    object.type
  end
end

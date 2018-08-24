class ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :objects
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :name, :author, :periodical, :volume_number, :issue_number, :pagination, :publisher, :issn, :version, :date_published
end

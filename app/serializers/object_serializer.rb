class ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :objects
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :name, :author, :periodical, "volume-number", "issue-number", :pagination, :publisher, :issn, :version, "date-published"
end

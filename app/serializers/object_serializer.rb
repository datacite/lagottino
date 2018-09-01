class ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :objects
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :subtype, :name, :author, :periodical, :volume_number, :issue_number, :pagination, :publisher, :issn, :version, :date_published

  attribute :subtype do |object|
    object.type
  end

  attribute :author do |object|
    object.author.map do |a|
      a.present? ? a.transform_keys! { |key| key.tr('_', '-') } : nil
    end.compact
  end
end

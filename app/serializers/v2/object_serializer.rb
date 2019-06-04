class V2::ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :objects
  
  attributes :subtype, :name, :author, :publisher, :periodical, :includedInDataCatalog, :version, :datePublished, :dateModified, :funder, :proxyIdentifiers, :registrantId

  attribute :subtype do |object|
    object["@type"]
  end

  attribute :datePublished do |object|
    object.date_published
  end

  attribute :registrantId do |object|
    object.registrant_id
  end
end

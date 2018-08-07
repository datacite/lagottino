module Facetable
  extend ActiveSupport::Concern

  included do
    def facet_by_year(arr)
      arr.map do |hsh|
        { "id" => hsh["key_as_string"][0..3],
          "title" => hsh["key_as_string"][0..3],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_month(arr)
      arr.map do |hsh|
        { "id" => hsh["key_as_string"][5..6],
          "title" => hsh["key_as_string"][5..6],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_key(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].humanize,
          "count" => hsh["doc_count"] }
      end
    end
  end
end


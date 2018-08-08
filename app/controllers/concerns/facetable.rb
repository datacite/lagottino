module Facetable
  extend ActiveSupport::Concern

  SOURCES = {
    "datacite-usage" => "DataCite Usage Stats"
  }

  included do
    def facet_by_year(arr)
      arr.map do |hsh|
        { "id" => hsh["key_as_string"][0..3],
          "title" => hsh["key_as_string"][0..3],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_year_month(arr)
      arr.map do |hsh|
        month = hsh["key_as_string"][5..6].to_i
        title = I18n.t("date.month_names")[month] + " " + hsh["key_as_string"][0..3]

        { "id" => hsh["key_as_string"][0..6],
          "title" => title,
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_source(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => SOURCES[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_relation_type(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "sum" => hsh.dig("total_by_relation_type_id", "value") }
      end
    end

    def facet_by_metric_type(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].gsub(/-/, ' ').titleize,
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


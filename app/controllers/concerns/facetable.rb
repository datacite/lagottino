module Facetable
  extend ActiveSupport::Concern

  SOURCES = {
    "datacite-usage" => "DataCite Usage Stats",
    "datacite-related" => "DataCite Related Identifiers",
    "datacite-crossref" => "DataCite to Crossref",
    "datacite-kisti" => "DataCite to KISTI",
    "datacite-cnki" => "DataCite to CNKI",
    "datacite-istic" => "DataCite to ISTIC",
    "datacite-medra" => "DataCite to mEDRA",
    "datacite-op" => "DataCite to OP",
    "datacite-jalc" => "DataCite to JaLC",
    "datacite-airiti" => "DataCite to Airiti",
    "datacite-url" => "DataCite URL Links",
    "datacite-funder" => "DataCite Funder Information",
    "crossref" => "Crossref to DataCite"
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
          "count" => hsh["doc_count"],
          "sum" => hsh.dig("total_by_year_month", "value") }
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
        arr = hsh.dig("year_months", "buckets").map do |h|
          month = h["key_as_string"][5..6].to_i
          title = I18n.t("date.month_names")[month] + " " + h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..6],
            "title" => title,
            "sum" => h.dig("total_by_year_month", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "year-months" => arr }
      end
    end

    def facet_by_citation_type(arr)
      arr.map do |hsh|
        arr = hsh.dig("year_months", "buckets").map do |h|
          month = h["key_as_string"][5..6].to_i
          title = I18n.t("date.month_names")[month] + " " + h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..6],
            "title" => title,
            "sum" => h.dig("total_by_year_month", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "year-months" => arr }
      end
    end

    def facet_by_pairings(arr)
      arr.map do |hsh|
        arr = hsh.dig("recipient", "buckets").map do |h|
          title = h["key"]
          {
            "id" => h["key"],
            "title" => title,
            "sum" => h.dig("total", "value") }
        end
        arr.reject! {|h| h["id"] == hsh["key"]}
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "registrants" => arr }
      end
    end

    def facet_by_registrants(arr)
      arr.map do |hsh|
        arr = hsh.dig("year", "buckets").map do |h|
          title = h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..3],
            "title" => title,
            "sum" => h.dig("total_by_year", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "years" => arr }
      end
    end

    def facet_by_metric_type(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].gsub(/-/, ' ').titleize,
          "count" => hsh["doc_count"] }
      end
    end

    # def facet_by_registrant(arr)
    #   # generate hash with id and name for each registrant in facet
    #   # crossref_ids = arr.select { |hsh| hsh["key"].start_with?("crossref") }.map { |hsh| hsh["key"] }.join(",")
    #   datacite_ids = arr.select { |hsh| hsh["key"].start_with?("datacite") }.map { |hsh| hsh["key"] }.join(",")
    #   registrants = Client.find_by_ids(datacite_ids)

    #   arr.map do |hsh|
    #     { "id" => hsh["key"],
    #       "title" => registrants[hsh["key"]],
    #       "count" => hsh["doc_count"] }
    #   end
    # end

    def facet_by_key(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].humanize,
          "count" => hsh["doc_count"] }
      end
    end
  end
end


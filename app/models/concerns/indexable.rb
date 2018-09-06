module Indexable
  extend ActiveSupport::Concern

  included do
    after_commit on: [:create, :update] do
      # use index_document instead of update_document to also update virtual attributes
      IndexJob.perform_later(self)
    end
  
    before_destroy do
      begin
        __elasticsearch__.delete_document
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        nil
      end
    end
  end
   
  module ClassMethods
    # don't raise an exception when not found
    def find_by_id(id, options={})
      return nil unless id.present?

      __elasticsearch__.search({
        query: {
          term: {
            uuid: id
          }
        },
        aggregations: query_aggregations
      })
    end

    def find_by_id_list(ids, options={})
      options[:cursor] ||= -1

      __elasticsearch__.search({
        size: 1000,
        from: 0,
        search_after: options[:cursor],
        sort: [{ updated_at: { order: 'asc' }}],
        query: {
          terms: {
            id: ids.split(",")
          }
        },
        aggregations: query_aggregations
      })
    end

    def find_by_ids(ids, options={})
      options[:cursor] ||= -1

      __elasticsearch__.search({
        size: 1000,
        from: 0,
        search_after: options[:cursor],
        sort: [{ updated_at: { order: 'asc' }}],
        query: {
          terms: {
            obj_id: ids.split(",").map(&:upcase)
          }
        },
        aggregations: query_aggregations
      })
    end

    def query(query, options={})
      if options.dig(:page, :cursor).present?
        from = 0
        search_after = [options.dig(:page, :cursor)]
        sort = [{ updated_at: { order: 'asc' }}]
      else
        from = (options.dig(:page, :number) - 1) * options.dig(:page, :size)
        search_after = nil
        sort = options[:sort]
      end

      must = []
      must << { multi_match: { query: query, fields: query_fields, type: "phrase_prefix", max_expansions: 50 }} if query.present?
      must << { term: { subj_id: options[:subj_id] }} if options[:subj_id].present?
      must << { term: { obj_id: options[:obj_id] }} if options[:obj_id].present?
      must << { term: { citation_type: options[:citation_type] }} if options[:citation_type].present?
      must << { term: { year_month: options[:year_month] }} if options[:year_month].present?
      must << { range: { occurred_at: { gte: "#{options[:occurred_at].split(",").min}||/y", lte: "#{options[:occurred_at].split(",").max}||/y", format: "yyyy" }}} if options[:occurred_at].present?
      must << { terms: { prefix: options[:prefix].split(",") }} if options[:prefix].present?
      must << { terms: { doi: options[:doi].downcase.split(",") }} if options[:doi].present?
      must << { terms: { subtype: options[:subtype].split(",") }} if options[:subtype].present?
      must << { terms: { source_id: options[:source_id].split(",") }} if options[:source_id].present?
      must << { terms: { relation_type_id: options[:relation_type_id].split(",") }} if options[:relation_type_id].present?
      must << { terms: { registrant_id: options[:registrant_id].split(",") }} if options[:registrant_id].present?
      must << { terms: { registrant_id: options[:provider_id].split(",") }} if options[:provider_id].present?
      must << { terms: { issn: options[:issn].split(",") }} if options[:issn].present?
      
      must_not = []

      __elasticsearch__.search({
        size: options.dig(:page, :size),
        from: from,
        search_after: search_after,
        sort: sort,
        query: {
          bool: {
            must: must,
            must_not: must_not
          }
        },
        aggregations: query_aggregations
      }.compact)
    end

    def recreate_index(options={})
      client     = self.gateway.client
      index_name = self.index_name

      client.indices.delete index: index_name rescue nil if options[:force]
      client.indices.create index: index_name, body: { settings:  {"index.requests.cache.enable": true }}
    end
  end
end

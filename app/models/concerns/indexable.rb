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
            obj_id: id.upcase
          }
        },
        aggregations: query_aggregations
      })
    end

    def find_by_id_list(ids, options={})
      options[:sort] ||= { "_doc" => { order: 'asc' }}

      __elasticsearch__.search({
        from: options[:from] || 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        query: {
          terms: {
            id: ids.split(",")
          }
        },
        aggregations: query_aggregations
      })
    end

    def find_by_ids(ids, options={})
      options[:sort] ||= { "_doc" => { order: 'asc' }}

      __elasticsearch__.search({
        from: options[:from] || 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        query: {
          terms: {
            obj_id: ids.split(",").map(&:upcase)
          }
        },
        aggregations: query_aggregations
      })
    end

    def query(query, options={})
      options[:sort] ||= { "_doc" => { order: 'asc' }}

      must = []
      must << { multi_match: { query: query, fields: query_fields, type: "phrase_prefix", max_expansions: 50 }} if query.present?
      must << { term: { subj_id: options[:subj_id] }} if options[:subj_id].present?
      must << { term: { obj_id: options[:obj_id] }} if options[:obj_id].present?
      must << { term: { doi: options[:doi] }} if options[:doi].present?
      must << { term: { year_month: options[:year_month] }} if options[:year_month].present?
      must << { range: { occurred_at: { gte: "#{options[:occurred_at].split(",").min}||/y", lte: "#{options[:occurred_at].split(",").max}||/y", format: "yyyy" }}} if options[:occurred_at].present?
      must << { term: { prefix: options[:prefix] }} if options[:prefix].present?
      must << { term: { source_id: options[:source_id] }} if options[:source_id].present?
      must << { term: { relation_type_id: options[:relation_type_id] }} if options[:relation_type_id].present?
      must << { term: { metric_type: options[:metric_type] }} if options[:metric_type].present?
      must << { term: { access_method: options[:access_method] }} if options[:access_method].present?

      must_not = []

      __elasticsearch__.search({
        from: options[:from] || 0,
        size: options[:size] || 25,
        sort: [options[:sort]],
        query: {
          bool: {
            must: must,
            must_not: must_not
          }
        },
        aggregations: query_aggregations
      })
    end

    def recreate_index(options={})
      client     = self.gateway.client
      index_name = self.index_name

      client.indices.delete index: index_name rescue nil if options[:force]
      client.indices.create index: index_name, body: { settings:  {"index.requests.cache.enable": true }}
    end
  end
end

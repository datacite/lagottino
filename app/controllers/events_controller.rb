class EventsController < ApplicationController

  include Identifiable

  include Facetable

  prepend_before_action :authenticate_user_from_token!, :except => [:index, :show]
  before_action :load_event, only: [:show, :destroy]
  authorize_resource only: [:destroy]

  def create
    @event = Event.new(safe_params.except(:format))
    authorize! :create, @event

    if @event.save
      render json: @event, :status => :created
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.where(uuid: params[:id]).first
    exists = @event.present?

    # create event if it doesn't exist already
    @event = Event.new(safe_params.except(:format)) unless @event.present?

    authorize! :update, @event

    if @event.update_attributes(safe_params)
      render jsonapi: @event, status: exists ? :ok : :created
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def show
    render jsonapi: @event
  end

  def index
    cursor = params.dig(:page, :cursor)
    size = (params.dig(:page, :size) || 1000).to_i

    if params[:id].present?
      response = Event.find_by_id(params[:id]) 
    elsif params[:ids].present?
      response = Event.find_by_ids(params[:ids], cursor: cursor, size: size)
    else
      response = Event.query(params[:query],
                             subj_id: params[:subj_id],
                             obj_id: params[:obj_id],
                             doi: params[:doi],
                             prefix: params[:prefix],
                             source_id: params[:source_id], 
                             relation_type_id: params[:relation_type_id],
                             metric_type: params[:metric_type],
                             access_method: params[:access_method],
                             year_month: params[:year_month], 
                             cursor: cursor, 
                             size: size)
    end

    total = response.results.total
    total_pages = (total.to_f / size).ceil
    sources = total > 0 ? facet_by_source(response.response.aggregations.sources.buckets) : nil
    prefixes = total > 0 ? facet_by_source(response.response.aggregations.prefixes.buckets) : nil
    relation_types = total > 0 ? facet_by_relation_type(response.response.aggregations.relation_types.buckets) : nil

    @events = response.results.results

    options = {}
    options[:meta] = {
      total: total,
      total_pages: total_pages,
      sources: sources,
      prefixes: prefixes,
      relation_types: relation_types
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @events.blank? ? nil : request.base_url + "/events?" + {
        "page[cursor]" => @events.last["sort"].first,
        "page[size]" => params.dig("page", "size") }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: EventSerializer.new(@events, options).serialized_json, status: :ok
  end

  def destroy
    if @event.destroy
      render json: { data: {} }, status: :ok
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  # use cached counts for total number of results
  def get_total_entries(params)
    case
    when params[:source_token] && params[:state] then Event.cached_event_source_token_state_count(params[:source_token], params[:state])
    when params[:source_token] then Event.cached_event_source_token_count(params[:source_token])
    when Rails.env.development? || Rails.env.test? then Event.count
    else Event.cached_event_count
    end
  end

  protected

  def load_event
    @event = Event.where(uuid: params[:id]).first

    fail ActiveRecord::RecordNotFound unless @event.present?
  end

  private

  def safe_params
    nested_params = [:pid, :name, { author: [:given, :family, :literal, :orcid] }, :title, "container-title", :issued, :published, :url, :doi, :type]
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:uuid, "message-action", "source-token", :callback, "subj-id", "obj-id", "relation-type-id", "source-id", :total, :license, "occurred-at", :subj, :obj, subj: nested_params, obj: nested_params]        
    )
  end
end

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
    page = (params.dig(:page, :number) || 1).to_i
    size = (params.dig(:page, :size) || 25).to_i
    from = (page - 1) * size

    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "-obj_id" then { "obj_id" => { order: 'desc' }}
           when "total" then { "total" => { order: 'asc' }}
           when "-total" then { "total" => { order: 'desc' }}
           when "created" then { created_at: { order: 'asc' }}
           when "-created" then { created_at: { order: 'desc' }}
           else { "obj_id" => { order: "asc" }}
           end

    if params[:id].present?
      response = Event.find_by_id(params[:id]) 
    elsif params[:ids].present?
      response = Event.find_by_ids(params[:ids], from: from, size: size, sort: sort)
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
                             from: from, 
                             size: size, 
                             sort: sort)
    end

    total = response.results.total
    total_pages = (total.to_f / size).ceil
    year_months = total > 0 ? facet_by_year_month(response.response.aggregations.year_months.buckets) : nil
    sources = total > 0 ? facet_by_source(response.response.aggregations.sources.buckets) : nil
    prefixes = total > 0 ? facet_by_source(response.response.aggregations.prefixes.buckets) : nil
    relation_types = total > 0 ? facet_by_key(response.response.aggregations.relation_types.buckets) : nil
    metric_types = total > 0 ? facet_by_metric_type(response.response.aggregations.metric_types.buckets) : nil
    access_methods = total > 0 ? facet_by_key(response.response.aggregations.access_methods.buckets) : nil

    @events = response.page(page).per(size).records

    meta = {
      total: total,
      total_pages: total_pages,
      page: page,
      year_months: year_months,
      sources: sources,
      prefixes: prefixes,
      relation_types: relation_types,
      metric_types: metric_types,
      access_methods: access_methods
    }.compact

    render jsonapi: @events, meta: meta, include: @include
  end

  def destroy
    if @event.destroy
      render json: { data: {} }, status: :ok
    else
      errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
      render jsonapi: { errors: errors }, status: :unprocessable_entity
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

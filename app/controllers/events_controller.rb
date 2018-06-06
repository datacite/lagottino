class EventsController < ApplicationController

  include Identifiable

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
    # support doi as alias for obj_id
    params[:obj_id] ||= params[:doi]

    collection = Event
    collection = collection.where(source_id: params[:source_id]) if params[:source_id].present?
    collection = collection.where(obj_id: normalize_doi(params[:obj_id])) if params[:obj_id].present?
    collection = collection.where(subj_id: params[:subj_id]) if params[:subj_id].present?

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    
    total = get_total_entries(params)
    total_pages = (total / page[:size]).ceil

    order = case params[:sort]
            when "created" then "events.created_at"
            when "name" then "events.uuid"
            when "-name" then "events.uuid DESC"
            else "events.created_at DESC"
            end

    @events = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total, 'total-pages' => total_pages, page: page[:number].to_i }
    render jsonapi: @events, meta: meta
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

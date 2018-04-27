class EventsController < ApplicationController
  prepend_before_action :authenticate_user_from_token!, :except => [:index, :show]
  before_action :load_event, only: [:show, :destroy]
  load_and_authorize_resource :except => [:create, :show, :index]
  load_resource :except => [:create, :index]

  def create
    unless safe_params.key? :type
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @event = Event.new(safe_params.except(:type))
      authorize! :create, @event

      if @event.save
        render json: @event, :status => :created
      else
        errors = @event.errors.full_messages.map { |message| { status: 422, title: message } }
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotUnique
    render json: @event, :status => :created
  end

  def show
    render json: @event
  end

  def index
    collection = Event
    collection = collection.where(source_id: params[:source_id]) if params[:source_id].present?
    collection = collection.where(aasm_state: params[:state]) if params[:state].present?
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
    render json: @events, meta: meta
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
    when params[:state] then Event.cached_event_state_count(params[:state])
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
    #fail ActionController::ParameterMissing, "param is missing or the value is empty: data" unless params[:data].present?
    nested_params = [:pid, :name, { author: [:given, :family, :literal, :orcid] }, :title, "container-title", :issued, :published, :URL, :doi, :type]
    attributes = [:uuid, :message_action, :source_token, :callback, :subj_id, :obj_id, :relation_type_id, :source_id, :total, :occurred_at, subj: nested_params, obj: nested_params]
    p = params.require(:data).permit(:id, :type, attributes: attributes)
    p.merge(
      container_title: "container-title",
      url: :URL
    ).except("container-title")
  end
end

require 'spree_core'
require 'spree_extension'
require 'spree_chimpy/engine'
require 'spree_chimpy/version'
require 'spree_chimpy/subscription'
require 'spree_chimpy/workers/delayed_job'
require 'gibbon'
# require 'coffee_script'

module SpreeChimpy
  extend self

  def config(&block)
    Rails.application.config.after_initialize do
      yield(SpreeChimpy::Config)
    end
  end

  def enqueue(event, object)
    payload = {class: object.class.name, id: object.id, object: object}
    ActiveSupport::Notifications.instrument("spree.chimpy.#{event}", payload)
  end

  def log(message)
    Rails.logger.info "spree_chimpy: #{message}"
  end

  def configured?
    # Config.key.present? && (Config.list_name.present? || Config.list_id.present?)
  end

  def reset
    @list = @orders = nil
  end

  def api
    Gibbon::Request.new({ api_key: Config.key }.merge(Config.api_options)) if configured?
  end

  def store_api_call
    SpreeChimpy.api.ecommerce.stores(SpreeChimpy::Config.store_id)
  end

  def list
    @list ||= Interface::List.new(Config.list_name,
                        Config.customer_segment_name,
                        Config.double_opt_in,
                        Config.send_welcome_email,
                        Config.list_id) if configured?
  end

  def orders
    @orders ||= Interface::Orders.new if configured?
  end

  def list_exists?
    list.list_id
  end

  def segment_exists?
    list.segment_id
  end

  def create_segment
    list.create_segment
  end

  def sync_merge_vars
    existing   = list.merge_vars + %w(EMAIL)
    merge_vars = Config.merge_vars.except(*existing)

    merge_vars.each do |tag, method|
      list.add_merge_var(tag.upcase, method.to_s.humanize.titleize)
    end
  end

  def merge_vars(model)
    attributes = Config.merge_vars.except('EMAIL')

    array = attributes.map do |tag, method|
      value = model.send(method) if model.methods.include?(method)

      [tag, value.to_s]
    end

    Hash[array]
  end

  def ensure_list
    if Config.list_name.present?
      Rails.logger.error("spree_chimpy: hmm.. a list named `#{Config.list_name}` was not found. Please add it and reboot the app") unless list_exists?
    end
    if Config.list_id.present?
      Rails.logger.error("spree_chimpy: hmm.. a list with ID `#{Config.list_id}` was not found. Please add it and reboot the app") unless list_exists?
    end
  end

  def ensure_segment
    if list_exists? && !segment_exists?
      create_segment
      Rails.logger.error("spree_chimpy: hmm.. a static segment named `#{Config.customer_segment_name}` was not found. Creating it now")
    end
  end

  def handle_event(event, payload = {})
    payload[:event] = event

    case
    when defined?(::Delayed::Job)
      ::Delayed::Job.enqueue(payload_object: SpreeChimpy::Workers::DelayedJob.new(payload),
                             run_at: Proc.new { 4.minutes.from_now })
    when defined?(::Sidekiq)
      SpreeChimpy::Workers::Sidekiq.perform_in(4.minutes, payload.except(:object))
    when defined?(::Resque)
      ::Resque.enqueue(SpreeChimpy::Workers::Resque, payload.except(:object))
    else
      perform(payload)
    end
  end

  def perform(payload)
    return unless configured?

    event  = payload[:event].to_sym
    object = payload[:object] || payload[:class].constantize.find(payload[:id])

    case event
    when :order
      orders.sync(object)
    when :subscribe
      list.subscribe(object.email, merge_vars(object), customer: object.is_a?(Spree.user_class))
    when :unsubscribe
      list.unsubscribe(object.email)
    end
  end
end

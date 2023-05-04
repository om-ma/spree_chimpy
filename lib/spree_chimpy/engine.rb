require_relative 'configuration'

module SpreeChimpy
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_chimpy'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer "spree_chimpy.environment", before: :load_config_initializers do |app|
      SpreeChimpy::Config = SpreeChimpy::Configuration.new
    end

    # config.after_initialize do
    #   Spree::PermittedAttributes.user_attributes << :subscribed
    # end

    initializer 'spree_chimpy.ensure' do
      if !Rails.env.test? && SpreeChimpy.configured?
        SpreeChimpy.ensure_list
        # SpreeChimpy.ensure_segment
      end
    end

    # initializer 'spree_chimpy.double_opt_in' do |app|
    #   if SpreeChimpy::Config.subscribed_by_default && !SpreeChimpy::Config.double_opt_in
    #     Rails.logger.warn("spree_chimpy: You have 'subscribed by default' enabled while 'double opt-in' is disabled. This is not recommended.")
    #   end
    # end

    initializer 'spree_chimpy.subscribe' do
      ActiveSupport::Notifications.subscribe /^spree\.chimpy\./ do |name, start, finish, id, payload|
        SpreeChimpy.handle_event(name.split('.').last, payload)
      end
    end

    def self.activate
      if defined?(Spree::StoreController)
        Spree::StoreController.send(:include, SpreeChimpy::ControllerFilters)
      else
        Spree::BaseController.send(:include,  SpreeChimpy::ControllerFilters)
      end

      # for those shops that use the api controller
      if defined?(Spree::Api::BaseController)
        Spree::Api::BaseController.send(:include,  SpreeChimpy::ControllerFilters)
      end

      Dir.glob(File.join(File.dirname(__FILE__), '../../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end

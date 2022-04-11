module Spree
  module UserDecorator

    def self.prepended(base)
      base.after_create  :subscribe
      base.after_destroy :unsubscribe
      base.after_initialize :assign_subscription_default

      base.delegate :subscribe, :resubscribe, :unsubscribe, to: :subscription
    end

    def subscription
      Spree::Chimpy::Subscription.new(self)
    end

    def assign_subscription_default
      self.subscribed ||= Spree::Chimpy::Config.subscribed_by_default if new_record?
    end
  
  end
end
::Spree::User.prepend(Spree::UserDecorator)
module Spree::Hominid
  class Subscription
    def initialize(user)
      @user       = user
      @changes    = user.changes.dup
      @interface  = Config.list
    end

    def needs_update?
      @user.subscribed && attributes_changed?
    end

    def subscribe
      if update_allowed?
        @interface.subscribe(@user.email, merge_vars)
        @interface.segment_emails([@user.email]) if @user.kind_of? Spree.user_class
      end
    end

    def unsubscribe
      @interface.unsubscribe(@user.email) if update_allowed?
    end

    def resubscribe(&block)
      block.call

      if @changes[:subscribed] && !@user.subscribed
        unsubscribe
      else
        subscribe
      end
    end

  private
    def update_allowed?
      @interface && @user.subscribed
    end

    def attributes_changed?
      Config.preferred_merge_vars.values.any? do |attr|
        @user.send("#{attr}_changed?")
      end
    end

    def merge_vars
      array = Config.preferred_merge_vars.except('EMAIL').map do |tag, method|
        [tag, @user.send(method)]
      end

      Hash[array]
    end
  end
end

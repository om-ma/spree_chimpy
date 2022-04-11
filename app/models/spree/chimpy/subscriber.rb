class Spree::Chimpy::Subscriber < ActiveRecord::Base
  self.table_name = "spree_chimpy_subscribers"

  EMAIL_REGEX = /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i

  validates :email, presence: true
  validates_format_of :email, with: EMAIL_REGEX, allow_blank: false, if: :email_changed?

  after_create  :subscribe
  around_update :resubscribe
  after_destroy :unsubscribe

  # delegate :subscribe, :resubscribe, :unsubscribe, to: :subscription

private
  def subscription
    Spree::Chimpy::Subscription.new(self)
  end

  def subscribe
    gibbon = Gibbon::Request.new(api_key: "97ff800b55a5527cb38ce3102464e4bb-us2")
    gibbon.timeout = 10 
    gibbon.lists("5dbf468fc5").members.create(body: { email_address: self.email, status: "subscribed", merge_fields: {}})

  end  
end

FactoryGirl.define do
  factory :subscriber, class: SpreeChimpy::Subscriber do
    sequence(:email) { |n| "foo#{n}@email.com" }
    subscribed true
  end
end

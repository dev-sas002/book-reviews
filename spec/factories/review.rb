FactoryBot.define do
  factory :review do
    association :reviewable, factory: :book
    user
    rating { Faker::Number.between(from: 1, to: 5) }
    description { Faker::Lorem.sentence }

    trait :for_author do
      association :reviewable, factory: :author
    end

    trait :without_description do
      description { nil }
    end
  end
end

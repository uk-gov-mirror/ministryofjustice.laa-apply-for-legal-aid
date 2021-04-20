FactoryBot.define do
  factory :application_proceeding_type do
    proceeding_type
    legal_aid_application
    chances_of_success

    trait :with_chances_of_success_submitted_today do
      after(:create) do |application_proceeding_type|
        create(:chances_of_success, :with_optional_text, submitted_at: Time.zone.today, application_proceeding_type: application_proceeding_type)
      end
    end
  end
end

module ProceedingMeritsTask
  class ChancesOfSuccess < ApplicationRecord
    belongs_to :legal_aid_application

    PRETTY_SUCCESS_PROSPECTS = {
      likely: 'Likely (>50%)',
      marginal: 'Marginal (45-49%)',
      poor: 'Poor (<45%)',
      borderline: 'Borderline',
      not_known: 'Uncertain'

    }.freeze

    enum success_prospect: {
      likely: 'likely'.freeze,
      marginal: 'marginal'.freeze,
      poor: 'poor'.freeze,
      borderline: 'borderline'.freeze,
      not_known: 'not_known'.freeze
    }, _prefix: true

    def self.prospects_unlikely_to_succeed
      success_prospects.except(:likely).keys
    end

    def submit!
      update!(submitted_at: Time.current) unless submitted_at?
      ActiveSupport::Notifications.instrument 'dashboard.chances_of_success_submitted'
    end

    def pretty_success_prospect
      PRETTY_SUCCESS_PROSPECTS[success_prospect.to_sym]
    end

    def statement_of_case_uploaded?
      legal_aid_application.attachments.statement_of_case.any?
    end
  end
end

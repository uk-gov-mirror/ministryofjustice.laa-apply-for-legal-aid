module Flow
  module Flows
    class ProviderDependants < FlowSteps
      STEPS = {
        has_dependants: {
          path: ->(application) { urls.providers_legal_aid_application_has_dependants_path(application) },
          forward: ->(application) { application.has_dependants? ? :dependants : :outgoings_summary }
        },
        dependants: {
          path: ->(application) { urls.new_providers_legal_aid_application_dependant_path(application) },
          forward: :has_other_dependants,
          check_answers: ->(app) { app.provider_checking_citizens_means_answers? ? :means_summaries : :check_passported_answers }
        },
        has_other_dependants: {
          path: ->(application) { urls.providers_legal_aid_application_has_other_dependants_path(application) },
          forward: ->(_, has_other_dependant) { has_other_dependant ? :dependants : :outgoings_summary }
        }
      }.freeze
    end
  end
end

module Flow
  module Flows
    class ProviderDependants < FlowSteps
      STEPS = {
        has_dependants: {
          path: ->(application) { urls.providers_legal_aid_application_has_dependants_path(application) },
          forward: ->(application) do
            if application.has_dependants?
              :dependants
            else
              application.outgoing_types? ? :outgoings_summary : :no_outgoings_summaries
            end
          end
        },
        dependants: {
          path: ->(application) { urls.new_providers_legal_aid_application_dependant_path(application) },
          forward: :has_other_dependants,
          check_answers: ->(app) {
                           app.checking_non_passported_means? ? :means_summaries : :check_passported_answers
                         }
        },
        has_other_dependants: {
          path: ->(application) { urls.providers_legal_aid_application_has_other_dependants_path(application) },
          forward: ->(application, has_other_dependant) {
                     if has_other_dependant
                       :dependants
                     else
                       application.outgoing_types? ? :outgoings_summary : :no_outgoings_summaries
                     end
                   }
        },
        remove_dependant: {
          path: ->(application, dependant) { urls.providers_legal_aid_application_remove_dependant_path(application, dependant) },
          forward: :has_other_dependants
        }
      }.freeze
    end
  end
end

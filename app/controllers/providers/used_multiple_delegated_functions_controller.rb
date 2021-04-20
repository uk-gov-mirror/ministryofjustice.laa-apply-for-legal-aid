module Providers
  class UsedMultipleDelegatedFunctionsController < ProviderBaseController
    include PreDWPCheckVisible

    def show
      form
    end

    def update
      return continue_or_draft if draft_selected?

      render :show unless save_continue_and_update_scope_limitations
    end

    private

    def save_continue_and_update_scope_limitations
      return false unless form.save(form_params)

      form.earliest_delegated_functions_date ? add_delegated_scope_limitations : remove_delegated_scope_limitations

      submit_application_reminder if form.earliest_delegated_functions_date && form.earliest_delegated_functions_date >= 1.month.ago

      # TODO pass earliest reported date to the flow to decide if earliest DF date needs to be confirmed or not
      # go_forward(form.earliest_delegated_functions_reported_date)
      go_forward
    end

    def submit_application_reminder
      return if legal_aid_application.awaiting_applicant?
      return if legal_aid_application.applicant_entering_means?

      SubmitApplicationReminderService.new(legal_aid_application).send_email
    end

    def application_proceeding_types
      legal_aid_application.application_proceeding_types
    end

    def proceeding_types
      legal_aid_application.proceeding_types
    end

    def remove_delegated_scope_limitations
      application_proceeding_types.each(&:remove_default_delegated_functions_scope_limitation)
    end

    def add_delegated_scope_limitations
      proceeding_types.each do |proceeding_type|
        LegalFramework::AddAssignedScopeLimitationService.call(legal_aid_application, proceeding_type.id, :delegated)
      end
    end

    def form
      @form ||= LegalAidApplications::UsedMultipleDelegatedFunctionsForm.call(legal_aid_application)
    end

    def form_params
      merged_params = merge_with_model(form) do
        params.require(:legal_aid_applications_used_multiple_delegated_functions_form)
              .except(:delegated_functions)
      end
      convert_date_params(merged_params)
    end
  end
end

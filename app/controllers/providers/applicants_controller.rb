module Providers
  class ApplicantsController < ProviderBaseController
    legal_aid_application_not_required!
    use_custom_authorization!

    def new
      @form = Applicants::BasicDetailsForm.new(model: applicant)
    end

    def create
      @form = Applicants::BasicDetailsForm.new(form_params)

      if save_continue_or_draft(@form)
        legal_aid_application.update!(
          applicant: applicant,
          provider_step: edit_applicant_key_point.step
        )
        replace_last_page_in_history(edit_applicant_path)
      else
        render :new
      end
    end

    private

    def legal_aid_application
      @legal_aid_application ||= LegalAidApplication.create!(
        provider: current_provider,
        office: current_provider.selected_office
      )
    end

    def applicant
      @applicant ||= Applicant.new
    end

    def edit_applicant_path
      edit_applicant_key_point.path(legal_aid_application)
    end

    def edit_applicant_key_point
      @edit_applicant_key_point ||= Flow::KeyPoint.new(:providers, :edit_applicant)
    end

    def form_params
      merge_with_model(applicant) do
        params.require(:applicant).permit(*Applicants::BasicDetailsForm::ATTRIBUTES)
      end
    end
  end
end

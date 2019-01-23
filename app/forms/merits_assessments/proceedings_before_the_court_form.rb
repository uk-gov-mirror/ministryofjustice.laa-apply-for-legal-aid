module MeritsAssessments
  class ProceedingsBeforeTheCourtForm
    include BaseForm

    form_for MeritsAssessment

    attr_accessor :proceedings_before_the_court, :details_of_proceedings_before_the_court

    before_validation :clear_details_of_proceedings_before_the_court
    validates :proceedings_before_the_court, presence: true
    validates :details_of_proceedings_before_the_court, presence: true, if: proc { |form| form.proceedings_before_the_court.to_s == 'true' }

    private

    def proceedings_before_the_court?
      proceedings_before_the_court.to_s == 'false'
    end

    def clear_details_of_proceedings_before_the_court
      details_of_proceedings_before_the_court.clear if proceedings_before_the_court?
    end
  end
end

module Caseworkers
  class ApplicantsController <  CaseworkerBaseController
    def show
      @applicant = Applicant.find params[:id]
      render json: @applicant, serializer: ApplicantSerializer
    end
  end
end


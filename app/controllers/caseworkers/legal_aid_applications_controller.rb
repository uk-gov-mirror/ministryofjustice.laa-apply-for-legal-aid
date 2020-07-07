module Caseworkers
  class LegalAidApplicationsController < CaseworkerBaseController

    def show
      legal_aid_application = LegalAidApplication.find_by(id: params[:id])
      render json: legal_aid_application, serializer: LegalAidApplicationSerializer
    end

  end
end

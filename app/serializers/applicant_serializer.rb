class ApplicantSerializer < ApplicationSerializer
  attributes :id,
             :legal_aid_application,
             :first_name,
             :last_name,
             :date_of_birth,
             :national_insurance_number,
             :email

  def legal_aid_application
    hateoas_link :legal_aid_application
  end
end

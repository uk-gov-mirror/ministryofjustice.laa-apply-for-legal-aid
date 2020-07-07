class LegalAidApplicationSerializer < ApplicationSerializer
  attributes :id,
             :application_ref,
             :state


  belongs_to :applicant
  has_many :proceeding_types


  def applicant
    hateoas_link :applicant
  end

  def proceeding_types
    hateoas_link :proceeding_types
  end


end

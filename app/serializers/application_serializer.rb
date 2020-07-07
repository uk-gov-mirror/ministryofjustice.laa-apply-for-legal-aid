class ApplicationSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  def hateoas_link(relationship)
    target = object.__send__(relationship)
    link_type = target.respond_to?(:size) ? :has_many : :has_one
    url_helper_method = link_type == :has_many ? "caseworkers_#{relationship.to_s.singularize}_url" : "caseworkers_#{relationship}_url"
    link_type == :has_many ? hateoas_has_many_link(target, url_helper_method) :  hateoas_has_one_link(target, url_helper_method)
  end

  def hateoas_has_many_link(collection, url_helper_method)
    collection.map { |x| __send__(url_helper_method, x, format: :json) }
  end

  def hateoas_has_one_link(target, url_helper_method)
    __send__(url_helper_method, target, format: :json)
  end
end

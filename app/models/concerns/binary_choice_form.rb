class BinaryChoiceForm
  include ActiveModel::Model

  validate :input_present?

  def self.call(journey:, radio_buttons_input_name:, action: :show, form_params: nil)
    attr_accessor radio_buttons_input_name.to_sym

    new(journey, radio_buttons_input_name, action, form_params)
  end

  def initialize(journey, radio_buttons_input_name, action, form_params)
    super(form_params)
    @journey = journey
    @input_name = radio_buttons_input_name
    @action = action
  end

  private

  def input_present?
    errors.add @input_name.to_sym, error_message if __send__(@input_name).blank?
  end

  def error_message
    I18n.t("#{@journey.to_s.pluralize}.#{@input_name.to_s.pluralize}.#{@action}.error")
  end
end
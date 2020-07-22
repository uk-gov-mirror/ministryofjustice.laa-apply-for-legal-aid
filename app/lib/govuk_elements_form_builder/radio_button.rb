module GovukElementsFormBuilder
  class RadioButton
    CUSTOM_OPTIONS = %i[label input_prefix field_with_error hint title inline text_input input_attributes collection].freeze

    delegate :content_tag, :label, to: :@form_builder

    def initialize(form_builder, hint_helper)
      @form_builder = form_builder
      @hint_helper = hint_helper
    end

    def html(attribute, value, options)
      radio_classes = [options[:class]]
      options[:class] = radio_classes.unshift('govuk-radios__input').compact.join(' ')
      radio_html = radio_button(attribute, value, options.except(*CUSTOM_OPTIONS))

      content_tag(:div, class: 'govuk-radios__item') do
        concat_tags(radio_html, label_html(attribute, value, options), hint_html(attribute, options))
      end
    end

    private

    def label_html(attribute, value, options)
      label_options = { value: value.to_s, class: 'govuk-label govuk-radios__label' }
      label(attribute, options[:label], label_options)
    end

    def hint_html(attribute, options)
      @hint_helper.tag(attribute, options.merge(radio_button_value: value))
    end
  end
end

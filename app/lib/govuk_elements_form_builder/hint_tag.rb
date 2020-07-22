module GovukElementsFormBuilder
  class HintTag
    def initialize(form_builder)
      @form_builder = form_builder
    end

    delegate :object_name, :object, :errors, :content_tag, to: :@form_builder

    def tag(attribute, options)
      return unless hint?(attribute, options)

      classes = ['govuk-hint']
      classes << 'govuk-radios__hint' if options.key?(:radio_button_value)

      id = [attribute, options[:radio_button_value], 'hint'].compact.join('-')
      content_tag(:span, message(attribute, options), class: classes.join(' '), id: id)
    end

    def hint?(attribute, options)
      return false if options.key?(:hint) && options[:hint].blank?

      message(attribute, options).present?
    end

    def with_error_tags(attribute, options)
      concat_tags(tag(attribute, options), error_tag(attribute, options))
    end

    private

    def message(attribute, options)
      return nil if options[:collection]

      options[:hint].presence || I18n.translate("helpers.hint.#{object_name}.#{attribute}", default: nil)
    end

    def error_tag(attribute, options)
      return unless error?(attribute, options)

      message = options[:error] || object.errors[attribute].first
      return unless message.present?

      content_tag(:span, message, class: 'govuk-error-message', id: "#{attribute}-error")
    end

    def error?(attribute, options)
      return true if options[:error]

      attr = options[:field_with_error] || attribute
      object.respond_to?(:errors) &&
        errors.messages.key?(attr) &&
        errors.messages[attr].present?
    end

    def concat_tags(*tags)
      tags.compact.join.html_safe
    end
  end
end

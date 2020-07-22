module GovukElementsFormBuilder
  class InputField
    CUSTOM_OPTIONS = %i[label input_prefix field_with_error hint title inline text_input input_attributes collection].freeze

    def initialize(form_builder, hint_helper)
      @form_builder = form_builder
      @hint_helper = hint_helper
    end

    delegate :content_tag, :object, :errors, :label, to: :@form_builder

    %w[text_field file_field text_area].each do |text_input|
      define_method(text_input) do |attribute, options = {}|
        options[:text_input] = text_input
        options[:class] = input_classes(attribute, options)
        options[:suffix] = options.delete(:suffix)
        input_form_group(attribute, options)
      end
    end

    private

    def input_form_group(attribute, options)
      classes = ['govuk-form-group']
      classes << 'govuk-form-group--error' if error?(attribute, options)
      content_tag(:div, class: classes.join(' ')) do
        concat_tags(label_from_options(attribute, options), @hint_helper.with_error_tags(attribute, options), input_tag(attribute, options))
      end
    end

    def input_tag(attribute, options)
      input_prefix = options[:input_prefix]
      tag_options = options.except(*CUSTOM_OPTIONS)
      tag_options[:id] = attribute
      tag_options[:'aria-describedby'] = aria_describedby(attribute, options)
      tag = @form_builder.__send__(options[:text_input], attribute, tag_options) # this calls text_field/text_area/file_field on the ActionView::Helpers::FormBuilder

      tag = input_prefix ? input_prefix_group(input_prefix) { tag } : tag
      tag = options[:suffix] ? suffix_span_tag(options[:suffix]) { tag } : tag
    end

    def label_from_options(attribute, options)
      return '' if options.key?(:label) && options[:label].nil?

      label_options = text_hash(options.fetch(:label, {}))
      label_classes = ['govuk-label']
      label_classes << "govuk-label--#{label_options[:size]}" if label_options[:size].present?
      label(attribute, label_options[:text], class: label_classes.join(' '), for: attribute)
    end

    def suffix_span_tag(suffix)
      span_tag = content_tag(:span, class: 'input-suffix') do
        " #{suffix}"
      end
      yield + span_tag
    end

    def input_prefix_group(input_prefix)
      content_tag(:div, class: 'govuk-prefix-input') do
        content_tag(:div, class: 'govuk-prefix-input__inner') do
          prefix = content_tag(:span, input_prefix, class: 'govuk-prefix-input__inner__unit')
          concat_tags(prefix, yield)
        end
      end
    end

    def input_classes(attribute, options)
      classes = [options[:class]]
      input_class_type = {
        'text_area' => 'textarea',
        'file_field' => 'file-upload'
      }[options[:text_input]] || 'input'
      classes << "govuk-#{input_class_type}"
      classes << "govuk-#{input_class_type}--error" if error?(attribute, options)
      classes << 'govuk-prefix-input__inner__input' if options[:input_prefix]
      classes.compact.join(' ')
    end

    def text_hash(text)
      text.is_a?(Hash) ? text : { text: text }
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

    def aria_describedby(attribute, options)
      aria_describedby = []
      aria_describedby << "#{attribute}-hint" if @hint_helper.hint?(attribute, options)
      aria_describedby << "#{attribute}-error" if error?(attribute, options)
      return if aria_describedby.empty?

      aria_describedby.join(' ')
    end
  end
end

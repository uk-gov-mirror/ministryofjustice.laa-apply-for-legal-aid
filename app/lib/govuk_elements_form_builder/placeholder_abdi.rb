module GovukElementsFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Prevents surrounding of erroneous inputs with <div class="field_with_errors">
    # https://guides.rubyonrails.org/configuring.html#configuring-action-view
    ActionView::Base.field_error_proc = proc { |html_tag| html_tag.html_safe }

    CUSTOM_OPTIONS = %i[label input_prefix field_with_error hint title inline text_input input_attributes collection].freeze

    delegate :content_tag, to: :@template
    delegate :errors, to: :@object

    # Usage:
    # <%= form.govuk_text_field :name %>
    # <%= form.govuk_text_area :statement %>
    #
    # You can specify the label and hint copies:
    # e.g., <%= form.govuk_text_field :name, label: 'Enter your name', hint: 'Your real name' %>
    #
    # Otherwise, label and hints are to be defined in the locale file:
    # 'helpers.hint.user.name'
    # 'helpers.label.user.name'
    #
    # Use the "hint: nil" option to not display the hint message.
    # e.g., <%= form.govuk_text_field :name, hint: nil %>
    #
    # Use the "label: nil" option to not display a label.
    # e.g., <%= form.govuk_text_field :name, label: nil, hint: 'hint text' %>
    #
    # Use the :input_prefix to insert a character inside and at the beginning of the input field.
    # e.g., <%= form.govuk_text_field :property_value, input_prefix: '$' %>
    #
    # Use :field_with_error to have the input be marked as erroneous when an other attribute has an error.
    # e.g., <%= form.govuk_text_field :address_line_two, field_with_error: :address_line_one %>
    #
    def govuk_text_field(attribute, options = {})
      InputField.html(attribute, 'text_field', options)
    end

    def govuk_file_field(attribute, options = {})
      InputField.html(attribute, 'file_field', options)
    end

    def govuk_text_area(attribute, options = {})
      InputField.html(attribute, 'text_area', options)
    end

    # Usage:
    # <%= form.govuk_radio_button(:gender, 'm')
    # <%= form.govuk_radio_button(:gender, 'm', label: 'Male')
    #
    # If label is not specified, it will be grabbed from the locale file at:
    # 'helpers.label.user.gender.f'
    #
    def govuk_radio_button(attribute, value, *args)
      RadioButton.html(attribute, value, *args)
    end

    # Usage:
    # Labels of each radio buttons can be either passed as parameters or defined in the locale file.
    # For examples, for the gender of a user, if the radio button values are 'm' and 'f' the labels can be define at:
    # 'helpers.label.user.gender.f'
    #
    # Option 1:
    # <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm']) %>
    # Option 2:
    # <%= form.govuk_collection_radio_buttons(:gender, [{ code: 'f' }, { code: 'm' }], :code) %>
    # Option 3:
    # <%= form.govuk_collection_radio_buttons(:gender, [{ code: 'f', label: 'Female' }, { code: 'm', label: 'Male' }], :code, :label) %>
    #
    # A hint will be displayed if it is defined in the locale file:
    # 'helpers.hint.user.gender'
    #
    # You can pass a title with the :title parameter.
    # e.g., <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], title: 'What is your gender?') %>
    #
    # You can pass an error with the :error parameter.
    # e.g., <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], error: 'Please select a gender') %>
    #
    # If you wish to specify the size of the heading and/or which header tag to use, pass a hash into title with text and size:
    # And the default for header tag, if no htag is supplied, is h1
    # <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], title: { text: 'What is your gender?', size: :m, htag: :h2 } ) %>
    #
    # Use the :inline parameter to have the radio buttons displayed horizontally rather than vertically
    # e.g., <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], inline: true) %>
    #
    def govuk_collection_radio_buttons(attribute, collection, *args)
      RadioButtonsCollection.html(attribute, collection, *args)
    end

    private

    def concat_tags(*tags)
      tags.compact.join.html_safe
    end

    def hint_and_error_tags(attribute, options)
      concat_tags(HintTag.tag(attribute, options), error_tag(attribute, options))
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
  end
end

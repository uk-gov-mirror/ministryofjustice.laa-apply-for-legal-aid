module GovukElementsFormBuilder
  module RadioButtonsCollection
    def self.html
      options = args.extract_options!.symbolize_keys!
      value_attr, label_attr = extract_value_and_label_attributes(args)

      content_tag(:div, class: collection_radio_buttons_classes(attribute, options)) do
        fieldset(attribute, options) do
          classes = ['govuk-radios']
          classes << (options[:inline] ? 'govuk-radios--inline' : 'govuk-!-padding-top-2')
          concat_tags(
            hint_and_error_tags(attribute, options),
            content_tag(:div, class: classes.join(' ')) do
              inputs = collection.map do |obj|
                value = value_attr ? obj[value_attr] : obj
                label = label_attr ? obj[label_attr] : nil
                input_attributes = options.dig(:input_attributes, value.to_s) || {}
                govuk_radio_button(attribute, value, options.merge(input_attributes).merge(label: label, collection: true))
              end
              concat_tags(inputs)
            end
          )
        end
      end
    end

    def self.extract_value_and_label_attributes(args)
      value_attr = args[0].is_a?(Hash) ? nil : args[0]
      label_attr = args[1].is_a?(Hash) ? nil : args[1]
      [value_attr, label_attr]
    end

    def self.collection_radio_buttons_classes(attribute, options)
      classes = ['govuk-form-group']
      classes << 'govuk-form-group--error' if error?(attribute, options)
      classes.join(' ')
    end

    def self.fieldset(attribute, options)
      content_tag(:fieldset, class: 'govuk-fieldset', 'aria-describedby': aria_describedby(attribute, options)) do
        legend_tag = options[:title] ? fieldset_legend(options[:title]) : nil
        concat_tags(legend_tag, yield)
      end
    end

    def self.aria_describedby(attribute, options)
      aria_describedby = []
      aria_describedby << "#{attribute}-hint" if HintTag.hint?(attribute, options)
      aria_describedby << "#{attribute}-error" if error?(attribute, options)
      return if aria_describedby.empty?

      aria_describedby.join(' ')
    end

    # title param can either be:
    # * a text string, e.g  "My title"
    # * a hash, e.g { text: "My title", size: :m, htag: :h2 }
    #
    def self.fieldset_legend(title)
      title = text_hash(title)
      size = title.fetch(:size, 'xl')
      htag = title.fetch(:htag, :h1)
      content_tag(:legend, class: "govuk-fieldset__legend govuk-fieldset__legend--#{size}") do
        content_tag(htag, title[:text], class: 'govuk-fieldset__heading')
      end
    end

    def self.text_hash(text)
      text.is_a?(Hash) ? text : { text: text }
    end
  end
end

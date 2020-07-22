require 'rails_helper'

RSpec.describe RadioButton do
  describe 'govuk_radio_button' do
    let(:attribute) { 'understands_terms_of_court_order' }
    let(:resource_form) { Respondents::RespondentForm.new }
    let(:hint_copy) { 'hint hint' }
    let(:label_copy) { CGI.escapeHTML I18n.t("helpers.label.respondent.#{attribute}.true") }
    let(:input) { parsed_html.at_css("input##{resource}_#{attribute}_true") }
    let(:value) { true }
    let(:params) { [:understands_terms_of_court_order, value, { hint: hint_copy }] }

    subject { builder.govuk_radio_button(*params) }

    it 'generates a radio button' do
      expect(input.classes).to include('govuk-radios__input')
      expect(input[:type]).to eq('radio')
      expect(input[:value]).to eq(value.to_s)
      expect(input[:name]).to eq("#{resource}[#{attribute}]")
    end

    it 'surrounds the field in a div' do
      div = input.parent

      expect(div.name).to eq('div')
      expect(div.classes).to include('govuk-radios__item')
    end

    it 'includes a label' do
      label = input.parent.at_css('label')

      expect(label.classes).to include('govuk-label')
      expect(label.classes).to include('govuk-radios__label')
      expect(label[:for]).to eq("#{resource}_#{attribute}_true")
      expect(label.content).to eq(label_copy)
    end

    it 'includes a hint message' do
      hint_span = input.parent.at_css('span.govuk-hint')
      expect(hint_span.content).to include(hint_copy)
      expect(hint_span[:id]).to eq("#{attribute}-#{value}-hint")
    end

    context 'adding a custom class to the input' do
      let(:custom_class) { 'govuk-!-width-one-third' }
      let(:params) { [:understands_terms_of_court_order, value, { class: custom_class }] }

      it 'adds custom class to the input' do
        expect(input.classes).to include(custom_class)
      end
    end

    context 'label is passed as a parameter' do
      let(:custom_label) { Faker::Lorem.sentence }
      let(:params) { [:understands_terms_of_court_order, value, { label: custom_label }] }

      it 'display the custom label instead of the one in locale file' do
        label = input.parent.at_css('label')
        expect(label.content).to eq(custom_label)
      end
    end
  end
end

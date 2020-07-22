require 'rails_helper'

RSpec.describe GovukElementsFormBuilder::InputField do
  let(:view_context) { ActionController::Base.new.view_context }
  let(:resource) { 'applicant' }
  let(:resource_form) { Applicants::BasicDetailsForm.new }
  let(:builder) { FormBuilder.new resource.to_sym, resource_form, view_context, {} }
  let(:parsed_html) { Nokogiri::HTML(subject) }
  let(:hint_helper) { double 'HintTag', tag: '', hint?: true, with_error_tags: '' }

  class FormBuilder < ActionView::Helpers::FormBuilder
    delegate :content_tag, to: :@template
    delegate :errors, to: :@object
  end

  shared_examples_for 'a basic input field' do
    it 'surrounds the field in a div' do
      div = tag.parent
      expect(div.name).to eq('div')
      expect(div.classes).to include('govuk-form-group')
    end

    it 'includes a label' do
      expect(label.classes).to include('govuk-label')
      expect(label[:for]).to eq(attribute)
      expect(label.content).to eq(label_copy)
    end

    it 'includes a hint message' do
      hint_span = tag.parent.at_css("span##{attribute}-hint")
      expect(hint_span.classes).to include('govuk-hint')
      expect(hint_span.content).to include(hint_copy)
      expect(tag['aria-describedby']).to eq("#{attribute}-hint")
    end

    context 'hint: nil' do
      let(:params) { { hint: nil } }

      it 'does not include a hint message' do
        expect(subject).not_to include('govuk-hint')
        expect(tag['aria-describedby']).to eq(nil)
      end
    end

    context 'Display hint and no label (label: nil, hint: hint_copy)' do
      let(:params) { { label: nil, hint: hint_copy } }

      it 'does not include a hint message' do
        expect(subject).not_to include('govuk-label')
        expect(subject).to include('govuk-hint')
      end
    end

    context 'pass a label parameter' do
      let(:custom_label) { Faker::Lorem.sentence }
      let(:params) { { label: custom_label } }

      it 'shows the custom label' do
        expect(label.classes).to include('govuk-label')
        expect(label[:for]).to eq(attribute)
        expect(label.content).to eq(custom_label)
      end
    end

    context 'when validation error on object' do
      let(:nino_error) { I18n.t("activemodel.errors.models.#{resource}.attributes.#{attribute}.blank") }

      before { resource_form.valid? }

      it 'includes an error message' do
        error_span = tag.previous_element
        expect(error_span.content).to eq(nino_error)
        expect(error_span.name).to eq('span')
        expect(error_span.classes).to include('govuk-error-message')
        expect(tag.classes).to include(expected_error_class)
        expect(tag['aria-describedby'].split(' ')).to include('national_insurance_number-error')
        expect(tag.parent.classes).to include('govuk-form-group--error')
      end
    end

    context 'adding a custom class to the input' do
      let(:custom_class) { 'govuk-!-width-one-third' }
      let(:params) { { class: custom_class } }

      it 'adds custom class to the input' do
        expect(tag.classes).to include(custom_class)
      end
    end

    context 'pass a label parameter with text and size' do
      let(:custom_label) { Faker::Lorem.sentence }
      let(:params) { { label: { text: custom_label, size: :m }} }

      it 'shows the custom label' do
        expect(label.classes).to include('govuk-label')
        expect(label[:for]).to eq(attribute)
        expect(label.content).to eq(custom_label)
      end

      it 'includes a size class' do
        expect(label.classes).to include('govuk-label--m')
      end
    end
  end

  describe 'govuk_text_field' do
    let(:attribute) { 'national_insurance_number' }
    let(:params) { {} }
    let(:label_copy) { I18n.t("activemodel.attributes.#{resource}.#{attribute}") }
    let(:hint_copy) { I18n.t("helpers.hint.#{resource}.#{attribute}") }
    let(:tag) { parsed_html.at_css("input##{attribute}") }
    let(:label) { tag.parent.at_css('label') }
    let(:expected_error_class) { 'govuk-input--error' }

    subject { described_class.new(builder, hint_helper).text_field(attribute.to_sym, params) }

    it_behaves_like 'a basic input field'

    it 'generates a text field' do
      expect(tag.classes).to include('govuk-input')
      expect(tag[:type]).to eq('text')
      expect(tag[:name]).to eq("#{resource}[#{attribute}]")
    end

    context 'suffix' do
      let(:params) { { suffix: 'litres' } }

      it 'shows the suffix' do
        expect(subject).to include %(<span class="input-suffix"> litres</span></div>)
      end
    end

    context 'has an input_prefix option' do
      let(:prefix) { '£' }
      let(:params) { { input_prefix: prefix } }

      it 'includes a prefix ' do
        expect(tag.previous_element.content).to eq(prefix)
        expect(tag.previous_element.name).to eq('span')
        expect(tag.previous_element.classes).to contain_exactly('govuk-prefix-input__inner__unit')
        expect(tag.parent.name).to eq('div')
        expect(tag.parent.classes).to contain_exactly('govuk-prefix-input__inner')
        expect(tag.parent.parent.name).to eq('div')
        expect(tag.parent.parent.classes).to contain_exactly('govuk-prefix-input')
      end
    end
  end

  describe 'govuk_text_area' do
    let(:attribute) { 'national_insurance_number' }
    let(:params) { [attribute.to_sym] }
    let(:label_copy) { I18n.t("activemodel.attributes.#{resource}.#{attribute}") }
    let(:hint_copy) { I18n.t("helpers.hint.#{resource}.#{attribute}") }
    let(:tag) { parsed_html.at_css("textarea##{attribute}") }
    let(:label) { tag.parent.at_css('label') }
    let(:expected_error_class) { 'govuk-textarea--error' }

    subject { described_class.new(builder, hint_helper).text_area(*params) }

    it_behaves_like 'a basic input field'

    it 'generates a text_area tag' do
      expect(tag.name).to eq('textarea')
      expect(tag.classes).to include('govuk-textarea')
      expect(tag[:name]).to eq("#{resource}[#{attribute}]")
    end
  end

  describe 'govuk_file_field' do
    let(:attribute) { 'national_insurance_number' }
    let(:params) { [attribute.to_sym] }
    let(:label_copy) { I18n.t("activemodel.attributes.#{resource}.#{attribute}") }
    let(:hint_copy) { I18n.t("helpers.hint.#{resource}.#{attribute}") }
    let(:label) { tag.parent.at_css('label') }
    let(:tag) { parsed_html.at_css('input[type=file]') }
    let(:expected_error_class) { 'govuk-file-upload--error' }

    subject { described_class.new(builder, hint_helper).file_field(*params) }

    it_behaves_like 'a basic input field'

    it 'generates a file_field tag' do
      expect(tag.classes).to include('govuk-file-upload')
      expect(tag[:type]).to eq('file')
      expect(tag[:name]).to eq("#{resource}[#{attribute}]")
    end
  end
end

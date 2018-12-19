require 'rails_helper'

class TestHelper < ActionView::Base; end

RSpec.describe GovukElementsFormBuilder::FormBuilder do
  let(:helper) { TestHelper.new }
  let(:resource) { 'applicant' }
  let(:resource_form) { Applicants::BasicDetailsForm.new }
  let(:builder) { described_class.new resource.to_sym, resource_form, helper, {} }
  let(:parsed_html) { Nokogiri::HTML(subject) }

  describe 'govuk_text_field' do
    let(:attribute) { 'email' }
    let(:params) { [:email] }
    let(:email_label) { I18n.t("activemodel.attributes.#{resource}.#{attribute}") }
    let(:email_hint) { I18n.t("helpers.hint.#{resource}.#{attribute}") }
    let(:input) { parsed_html.at_css("input##{attribute}") }

    subject { builder.govuk_text_field(*params) }

    it 'generates a text field' do
      expect(input.classes).to include('govuk-input')
      expect(input[:type]).to eq('text')
      expect(input[:name]).to eq("#{resource}[#{attribute}]")
    end

    it 'surrounds the field in a div' do
      div = input.parent

      expect(div.name).to eq('div')
      expect(div.classes).to include('govuk-form-group')
    end

    it 'includes a label' do
      label = input.parent.at_css('label')

      expect(label.classes).to include('govuk-label')
      expect(label[:for]).to eq('email')
      expect(label.content).to eq(email_label)
    end

    it 'includes a hint message' do
      hint_span = input.parent.at_css("span##{attribute}-hint")

      expect(hint_span.classes).to include('govuk-hint')
      expect(hint_span.content).to include(email_hint)
      expect(input['aria-describedby']).to eq("#{attribute}-hint")
    end

    context 'hint: nil' do
      let(:params) { [:email, hint: nil] }

      it 'does not include a hint message' do
        expect(subject).not_to include('govuk-hint')
        expect(input['aria-describedby']).to eq('')
      end
    end

    context 'pass a label parameter' do
      let(:custom_label) { "Your client's email" }
      let(:params) { [:email, label: custom_label] }

      it 'shows the custom label' do
        label = input.parent.at_css('label')

        expect(label.classes).to include('govuk-label')
        expect(label[:for]).to eq('email')
        expect(label.content).to eq(custom_label)
      end
    end

    context 'suffix' do
      let(:params) { [:email, suffix: 'litres'] }

      it 'shows the suffix' do
        expect(subject).to include %(<span class="input-suffix"> litres</span></div>)
      end
    end

    context 'adding a custom class to the input' do
      let(:custom_class) { 'govuk-!-width-one-third' }
      let(:params) { [:email, class: custom_class] }

      it 'adds custom class to the input' do
        expect(input.classes).to include(custom_class)
      end
    end

    context 'has an input_prefix option' do
      let(:prefix) { '£' }
      let(:params) { [:email, input_prefix: prefix] }

      it 'includes a prefix ' do
        expect(input.previous_element.content).to eq(prefix)
        expect(input.previous_element.name).to eq('span')
        expect(input.previous_element.classes).to contain_exactly('govuk-prefix-input__inner__unit')
        expect(input.parent.name).to eq('div')
        expect(input.parent.classes).to contain_exactly('govuk-prefix-input__inner')
        expect(input.parent.parent.name).to eq('div')
        expect(input.parent.parent.classes).to contain_exactly('govuk-prefix-input')
      end
    end

    context 'when validation error on object' do
      let(:email_error) { I18n.t("activemodel.errors.models.#{resource}.attributes.#{attribute}.blank") }

      before { resource_form.valid? }

      it 'includes an error message' do
        error_span = input.previous_element
        expect(error_span.content).to eq(email_error)
        expect(error_span.name).to eq('span')
        expect(error_span.classes).to include('govuk-error-message')
        expect(input.classes).to include('govuk-input--error')
        expect(input['aria-describedby'].split(' ')).to include('email-error')
        expect(input.parent.classes).to include('govuk-form-group--error')
      end
    end
  end

  describe 'govuk_radio_button' do
    let(:attribute) { 'uses_online_banking' }
    let(:resource_form) { Applicants::UsesOnlineBankingForm.new }
    let(:params) { [:uses_online_banking, true] }
    let(:label_copy) { CGI.escapeHTML I18n.t("helpers.label.#{resource}.#{attribute}.true") }
    let(:input) { parsed_html.at_css("input##{resource}_#{attribute}_true") }

    subject { builder.govuk_radio_button(*params) }

    it 'generates a radio button' do
      expect(input.classes).to include('govuk-radios__input')
      expect(input[:type]).to eq('radio')
      expect(input[:value]).to eq('true')
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

    context 'adding a custom class to the input' do
      let(:custom_class) { 'govuk-!-width-one-third' }
      let(:params) { [:uses_online_banking, true, class: custom_class] }

      it 'adds custom class to the input' do
        expect(input.classes).to include(custom_class)
      end
    end

    context 'label is passed as a parameter' do
      let(:custom_label) { 'Yes I use online banking' }
      let(:params) { [:uses_online_banking, true, label: custom_label] }

      it 'display the custom label instead of the one in locale file' do
        label = input.parent.at_css('label')
        expect(label.content).to eq(custom_label)
      end
    end
  end

  describe 'govuk_collection_radio_buttons' do
    let(:attribute) { 'uses_online_banking' }
    let(:resource_form) { Applicants::UsesOnlineBankingForm.new }
    let(:options) { [true, false] }
    let(:params) { [:uses_online_banking, options] }
    let(:inputs) { options.map { |option| parsed_html.at_css("input##{resource}_#{attribute}_#{option}") } }
    let(:input) { inputs.first }
    let(:div_radios) { parsed_html.at_css('div.govuk-radios') }
    let(:div_form_group) { parsed_html.at_css('div.govuk-form-group') }
    let(:fieldset) { parsed_html.at_css('fieldset') }
    let(:legend) { parsed_html.at_css('legend') }
    let(:h1) { parsed_html.at_css('h1') }

    subject { builder.govuk_collection_radio_buttons(*params) }

    it 'generates radio buttons' do
      expect(inputs.size).to eq(options.size)
      expect(inputs.pluck(:class).uniq).to include('govuk-radios__input')
      expect(inputs.pluck(:type).uniq).to include('radio')
      expect(inputs.pluck(:value)).to eq(options.map(&:to_s))
      expect(inputs.pluck(:name).uniq).to include("#{resource}[#{attribute}]")
    end

    it 'surrounds the radio buttons in a div' do
      expect(div_radios.children.size).to eq(options.size)
      expect(div_radios.search('[type=radio]').count).to eq(options.size)
      expect(div_radios.children.pluck(:class).uniq).to include('govuk-radios__item')
    end

    it 'surrounds everything in a from group div' do
      first_div = parsed_html.search('div').first
      expect(first_div.classes).to include('govuk-form-group')
    end

    it 'includes a fieldset tag' do
      expect(div_form_group.child.name).to eq('fieldset')
      expect(fieldset.classes).to include('govuk-fieldset')
    end

    context 'when there is a hint message defined' do
      let(:hint_message) { 'Choose an option' }
      let(:span_hint) { parsed_html.at_css('span.govuk-hint') }

      before do
        allow(I18n)
          .to receive(:translate)
          .with("helpers.hint.#{resource}.#{attribute}", default: nil)
          .and_return(hint_message)
      end

      it 'includes a hint message' do
        expect(fieldset['aria-describedby'].split(' ')).to include("#{attribute}-hint")
        expect(span_hint[:id]).to eq("#{attribute}-hint")
        expect(span_hint.content).to eq(hint_message)
        expect(span_hint.parent).to eq(fieldset)
      end
    end

    context 'when validation error on object' do
      let(:error_message) { I18n.t("activemodel.errors.models.#{resource}.attributes.#{attribute}.blank") }
      let(:span_error) { parsed_html.at_css('span.govuk-error-message') }

      before { resource_form.valid? }

      it 'includes an error message' do
        expect(fieldset['aria-describedby'].split(' ')).to include("#{attribute}-error")
        expect(span_error[:id]).to eq("#{attribute}-error")
        expect(span_error.content).to eq(error_message)
        expect(span_error.parent).to eq(fieldset)
      end
    end

    context 'title is passed as a parameter' do
      let(:title) { 'Pick an option' }
      let(:params) { [:uses_online_banking, options, title: title] }

      it 'display the title in a <legend> and <h1> tag' do
        expect(fieldset.child.name).to eq('legend')
        expect(fieldset.child.child.name).to eq('h1')
        expect(legend.classes).to include('govuk-fieldset__legend')
        expect(legend.classes).to include('govuk-fieldset__legend--xl')
        expect(h1.classes).to include('govuk-fieldset__heading')
        expect(h1.content).to eq(title)
      end
    end
  end
end

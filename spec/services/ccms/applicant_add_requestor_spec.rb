require 'rails_helper'

module CCMS
  RSpec.describe ApplicantAddRequestor do
    let(:expected_xml) { ccms_data_from_file 'applicant_add_request.xml' }

    let(:address) do
      double Address,
             address_line_one: '102',
             address_line_two: 'Petty France',
             city: 'London',
             pretty_postcode: 'SW1H 9AJ'
    end

    let(:applicant) do
      double Applicant,
             address: address,
             first_name: 'lenovo',
             last_name: 'Hurlock',
             date_of_birth: Date.new(1969, 1, 1)
    end

    describe 'XML request' do
      it 'generates the expected XML' do
        with_modified_env(modified_environment_vars) do
          requestor = described_class.new(applicant)
          allow(requestor).to receive(:transaction_request_id).and_return('20190101121530123456')
          expect(requestor.formatted_xml).to eq expected_xml.chomp
        end
      end
    end

    describe '#transaction_request_id' do
      it 'returns the id based on current time' do
        Timecop.freeze(2019, 1, 2, 3, 4, 5.123456) do
          requestor = described_class.new(applicant)
          expect(requestor.transaction_request_id).to start_with '20190102030405123456'
        end
      end
    end
  end
end

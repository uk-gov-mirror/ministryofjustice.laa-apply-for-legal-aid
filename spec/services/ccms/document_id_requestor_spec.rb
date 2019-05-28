require 'rails_helper'

module CCMS
  RSpec.describe DocumentIdRequestor do
    let(:expected_xml) { ccms_data_from_file 'document_id_request.xml' }
    let(:expected_tx_id) { '20190101121530123456' }
    let(:case_ccms_reference) { '1234567890' }

    describe 'XML request' do
      it 'generates the expected XML' do
        with_modified_env(modified_environment_vars) do
          requestor = described_class.new(case_ccms_reference)
          allow(requestor).to receive(:transaction_request_id).and_return(expected_tx_id)
          expect(requestor.formatted_xml).to eq expected_xml.chomp
        end
      end
    end

    describe '#transaction_request_id' do
      it 'returns the id based on current time' do
        Timecop.freeze(2019, 1, 1, 12, 15, 30.123456) do
          requestor = described_class.new(case_ccms_reference)
          expect(requestor.transaction_request_id).to start_with expected_tx_id
        end
      end
    end
  end
end

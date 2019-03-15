require 'rails_helper'

RSpec.describe Citizens::BankTransactionsController, type: :request do
  let(:legal_aid_application) { create :legal_aid_application, :with_applicant }
  let(:secure_id) { legal_aid_application.generate_secure_id }

  before { get citizens_legal_aid_application_path(secure_id) }

  describe 'PATCH /citizens/bank_transactions/:id/remove_transation_type' do
    let!(:transaction_type) { create :transaction_type }
    let(:bank_transaction) { create :bank_transaction, transaction_type: transaction_type }
    let(:headers) { {} }

    subject do
      patch(
        remove_transation_type_citizens_bank_transaction_path(bank_transaction),
        headers: headers
      )
    end

    it 'does not delete the transaction type' do
      expect { subject }.not_to change { TransactionType.count }
    end

    it 'removes the assocation with the transaction type' do
      subject
      expect(bank_transaction.reload.transaction_type).to be_nil
    end

    it 'redirects on completion' do
      subject
      expect(response).to redirect_to(citizens_identify_types_of_income_path)
    end

    context 'with JSON request' do
      let(:headers) { { 'ACCEPT' => 'application/json' } }

      it 'removes the assocation with the transaction type' do
        subject
        expect(bank_transaction.reload.transaction_type).to be_nil
      end

      it 'returns a json response' do
        subject
        expect(response.content_type).to eq('application/json')
      end

      it 'does not redirect on success' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

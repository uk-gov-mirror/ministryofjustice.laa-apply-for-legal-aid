require 'rails_helper'

RSpec.describe Citizens::BanksController, type: :request do
  let(:application) { create :application, :with_applicant }
  let(:secure_id) { application.generate_secure_id }
  let!(:banks) { create(:true_layer_bank).banks }
  let(:enable_mock) { false }

  before do
    get citizens_legal_aid_application_path(secure_id)
    allow(Rails.configuration.x.true_layer).to receive(:enable_mock).and_return(enable_mock)
  end

  describe 'GET citizens/banks' do
    before { get citizens_banks_path }

    it 'shows the banks' do
      banks.each do |bank|
        expect(response.body).to include(bank[:display_name])
        expect(response.body).to include(bank[:provider_id])
        expect(response.body).to include(bank[:logo_url])
      end
    end

    it 'does not show the mock bank' do
      expect(response.body).not_to include('mock')
    end

    context 'enable_mock is set to true' do
      let(:enable_mock) { true }

      it 'shows the mock bank' do
        expect(response.body).to include('mock')
      end
    end
  end

  describe 'POST citizens/banks' do
    let(:provider_id) { Faker::Bank.name }
    before { post citizens_banks_path, params: { provider_id: provider_id } }

    it 'redirects to true layer' do
      expect(response).to redirect_to(applicant_true_layer_omniauth_authorize_path)
    end

    it 'sets provider_id in the session' do
      expect(session[:provider_id]).to eq(provider_id)
    end

    context 'no bank was selected' do
      let(:provider_id) { nil }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'shows an error' do
        expect(response.body).to include(I18n.t('citizens.banks.create.error'))
      end
    end
  end
end
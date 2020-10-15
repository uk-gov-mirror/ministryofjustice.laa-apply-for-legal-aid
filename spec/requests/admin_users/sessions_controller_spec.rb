require 'rails_helper'

RSpec.describe AdminUsers::SessionsController, type: :request do
  describe 'GET admin_users/sessions#new' do
    let(:subject) { get new_admin_user_session_path }

    it 'renders successfully' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'shows login form' do
      subject
      expect(unescaped_response_body).to include('admin_user_username')
    end

    context 'in production environment' do
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      it 'does not show login form' do
        subject
        expect(unescaped_response_body).not_to include('admin_user_username')
      end

      it 'shows google login' do
        subject
        expect(unescaped_response_body).not_to include(I18n.t('.admin_users.sessions.google_login'))
      end
    end
  end
end

require 'rails_helper'

module Providers
  module ApplicationMeritsTask
    RSpec.describe DateClientToldIncidentsController, type: :request do
      let(:legal_aid_application) { create :legal_aid_application }
      let(:login_provider) { login_as legal_aid_application.provider }

      describe 'GET /providers/applications/:legal_aid_application_id/date_client_told_incident' do
        subject do
          get providers_legal_aid_application_date_client_told_incident_path(legal_aid_application)
        end

        before do
          login_provider
          subject
        end

        it 'renders successfully' do
          expect(response).to have_http_status(:ok)
        end

        context 'when not authenticated' do
          let(:login_provider) { nil }
          it_behaves_like 'a provider not authenticated'
        end

        context 'with an existing incident' do
          let(:incident) { create :incident }
          let(:legal_aid_application) { create :legal_aid_application, latest_incident: incident }

          it 'renders successfully' do
            expect(response).to have_http_status(:ok)
          end

          it 'displays told_on incident data' do
            expect(response.body).to include(incident.told_on.day.to_s)
            expect(response.body).to include(incident.told_on.month.to_s)
            expect(response.body).to include(incident.told_on.year.to_s)
          end

          it 'displays occurred_on incident data' do
            expect(response.body).to include(incident.occurred_on.day.to_s)
            expect(response.body).to include(incident.occurred_on.month.to_s)
            expect(response.body).to include(incident.occurred_on.year.to_s)
          end
        end
      end

      describe 'PATCH /providers/applications/:legal_aid_application_id/date_client_told_incident' do
        let(:told_on) { 3.days.ago.to_date }
        let(:occurred_on) { 5.days.ago.to_date }
        let(:told_on_3i) { told_on.day }
        let(:params) do
          {
            application_merits_task_incident: {
              'told_on(3i)': told_on_3i,
              'told_on(2i)': told_on.month,
              'told_on(1i)': told_on.year,
              'occurred_on(3i)': occurred_on.day,
              'occurred_on(2i)': occurred_on.month,
              'occurred_on(1i)': occurred_on.year
            }
          }
        end
        let(:draft_button) { { draft_button: 'Save as draft' } }
        let(:button_clicked) { {} }
        let(:incident) { legal_aid_application.reload.latest_incident }

        subject do
          patch(
            providers_legal_aid_application_date_client_told_incident_path(legal_aid_application),
            params: params.merge(button_clicked)
          )
        end

        before { login_provider }

        it 'creates a new incident with the values entered' do
          expect { subject }.to change { ::ApplicationMeritsTask::Incident.count }.by(1)
          expect(incident.told_on).to eq(told_on)
          expect(incident.occurred_on).to eq(occurred_on)
        end

        it 'redirects to the next page' do
          subject
          expect(response).to redirect_to(flow_forward_path)
        end

        context 'when not authenticated' do
          let(:login_provider) { nil }
          before { subject }
          it_behaves_like 'a provider not authenticated'
        end

        context 'when incomplete' do
          let(:told_on_3i) { '' }

          it 'renders show' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

        context 'with alpha-numeric date' do
          let(:told_on_3i) { '6s2' }

          it 'renders show' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'contains error message' do
            subject
            expect(response.body).to include('govuk-error-summary')
            expect(response.body).to include(I18n.t('activemodel.errors.models.application_merits_task/incident.attributes.told_on.date_not_valid'))
          end
        end

        context 'when invalid' do
          let(:told_on_3i) { '32' }

          it 'renders show' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

        context 'when save as draft selected' do
          let(:button_clicked) { draft_button }

          it 'redirects to provider draft endpoint' do
            subject
            expect(response).to redirect_to provider_draft_endpoint
          end
        end
      end
    end
  end
end

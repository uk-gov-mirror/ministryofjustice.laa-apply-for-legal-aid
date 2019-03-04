require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe 'provider statement of case requests', type: :request do
  let(:legal_aid_application) { create :legal_aid_application }
  let(:provider) { legal_aid_application.provider }
  let(:soc) { nil }

  describe 'GET /providers/applications/:legal_aid_application_id/statement_of_case' do
    subject { get providers_legal_aid_application_statement_of_case_path(legal_aid_application) }

    context 'when the provider is not authenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'when the provider is authenticated' do
      before do
        legal_aid_application.statement_of_case = soc
        login_as provider
        subject
      end

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not display error' do
        expect(response.body).not_to match 'id="statement-error"'
      end

      context 'no statement of case record exists for the application' do
        it 'displays an empty text box' do
          expect(legal_aid_application.statement_of_case).to be nil
          expect(response.body).to have_text_area_with_id_and_content('statement', '')
        end
      end

      context 'statement of case record already exists for the application' do
        let(:soc) { legal_aid_application.create_statement_of_case(statement: 'This is my case statement') }
        it 'displays the details of the statement on the page' do
          expect(response.body).to have_text_area_with_id_and_content('statement', soc.statement)
        end
      end
    end
  end

  describe 'PATCH /providers/applications/:legal_aid_application_id/statement_of_case' do
    let(:entered_text) { Faker::Lorem.paragraph(3) }
    let(:original_file) { uploaded_file('spec/fixtures/files/documents/hello_world.pdf', 'application/pdf') }
    let(:statement_of_case) { legal_aid_application.statement_of_case }
    let(:params_statement_of_case) do
      {
        statement: entered_text,
        original_files: [original_file]
      }
    end
    let(:draft_button) { { draft_button: 'Save as draft' } }
    let(:upload_button) { { upload_button: 'Upload' } }
    let(:button_clicked) { {} }
    let(:params) { { statement_of_case: params_statement_of_case }.merge(button_clicked) }

    subject { patch providers_legal_aid_application_statement_of_case_path(legal_aid_application), params: params }

    before { login_as provider }

    it 'updates the record' do
      subject
      expect(statement_of_case.reload.statement).to eq(entered_text)
      expect(statement_of_case.original_files.first).to be_present
    end

    it 'redirects to the next page' do
      subject
      expect(response).to redirect_to providers_legal_aid_application_estimated_legal_costs_path(legal_aid_application)
    end

    context '2 files are uploaded' do
      before do
        legal_aid_application.build_statement_of_case.save!
        filepath = "#{Rails.root}/spec/fixtures/files/documents/hello_world.pdf"
        statement_of_case.original_files.attach(io: File.open(filepath), filename: 'hello_world.pdf', content_type: 'application/pdf')
        PdfConverterWorker.clear
      end

      it 'converts both files to pdf' do
        expect { subject && PdfConverterWorker.drain }.to change { PdfFile.count }.by(2)

        statement_of_case.original_files.each do |original_file|
          pdf_file = PdfFile.find_by(original_file_id: original_file.id).file
          expect(pdf_file.filename.base).to eq(original_file.filename.base), 'Should have the same base name'
        end
      end
    end

    context 'Continue button pressed' do
      context 'model has no files attached previously' do
        context 'file is empty and text it empty' do
          let(:params_statement_of_case) do
            {
              statement: ''
            }
          end

          it 'fails' do
            subject
            expect(response.body).to include('There is a problem')
            expect(response.body).to include(I18n.t('activemodel.errors.models.statement_of_case.attributes.statement.blank'))
          end
        end

        context 'file is empty but text is entered' do
          let(:params_statement_of_case) do
            {
              statement: entered_text
            }
          end

          it 'updates the statement text' do
            subject
            expect(statement_of_case.reload.statement).to eq(entered_text)
            expect(statement_of_case.original_files.first).not_to be_present
          end
        end

        context 'text is empty but file is present' do
          let(:entered_text) { '' }

          it 'updates the file' do
            subject
            expect(statement_of_case.reload.statement).to eq('')
            expect(statement_of_case.original_files.first).to be_present
          end
        end

        context 'file is invalid content type' do
          let(:original_file) { uploaded_file('spec/fixtures/files/zip.zip', 'application/zip') }

          it 'does not save the object and raise an error' do
            subject
            expect(response.body).to include(I18n.t('activemodel.errors.models.statement_of_case.attributes.original_files.content_type_invalid'))
            expect(statement_of_case).to be_nil
          end
        end

        context 'file is too big' do
          before { allow(StatementOfCases::StatementOfCaseForm).to receive(:max_file_size).and_return(0) }

          it 'does not save the object and raise an error' do
            subject
            expect(response.body).to include(I18n.t('activemodel.errors.models.statement_of_case.attributes.original_files.file_too_big', size: 0))
            expect(statement_of_case).to be_nil
          end
        end

        context 'file is empty' do
          let(:original_file) { uploaded_file('spec/fixtures/files/empty_file') }

          it 'does not save the object and raise an error' do
            subject
            expect(response.body).to include(I18n.t('activemodel.errors.models.statement_of_case.attributes.original_files.file_empty'))
            expect(statement_of_case).to be_nil
          end
        end

        context 'on error' do
          let(:entered_text) { '' }
          let(:original_file) { nil }

          it 'returns http success' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'displays error' do
            subject
            expect(response.body).to match 'id="statement-error"'
          end

          context 'file contains a malware' do
            let(:original_file) { uploaded_file('spec/fixtures/files/malware.doc') }

            it 'does not save the object and raise an error' do
              subject
              expect(response.body).to include(I18n.t('activemodel.errors.models.statement_of_case.attributes.original_files.file_virus'))
              expect(statement_of_case).to be_nil
            end
          end
        end
      end

      context 'model already has files attached' do
        before { create :statement_of_case, :with_empty_text, :with_attached_files, legal_aid_application: legal_aid_application }

        context 'text is empty' do
          let(:entered_text) { '' }

          context 'no additional file uploaded' do
            let(:params_statement_of_case) do
              {
                statement: entered_text
              }
            end

            it 'does not alter the record' do
              subject
              expect(statement_of_case.reload.statement).to eq('')
              expect(statement_of_case.original_files.count).to eq 1
            end
          end

          context 'additional file uploaded' do
            it 'attaches the file' do
              subject
              expect(statement_of_case.reload.statement).to eq('')
              expect(statement_of_case.original_files.count).to eq 2
            end
          end
        end

        context 'text is entered and an additional file is uploaded' do
          let(:entered_text) { 'Now we have two attached files' }
          it 'updates the text and attaches  the additional file' do
            subject
            expect(statement_of_case.reload.statement).to eq entered_text
            expect(statement_of_case.original_files.count).to eq 2
          end
        end
      end
    end

    context 'Save as draft' do
      let(:button_clicked) { draft_button }

      it 'updates the record' do
        subject
        expect(statement_of_case.reload.statement).to eq(entered_text)
        expect(statement_of_case.original_files.first).to be_present
      end

      it 'redirects to provider applications home page' do
        subject
        expect(response).to redirect_to providers_legal_aid_applications_path
      end

      context 'nothing specified' do
        let(:entered_text) { '' }
        let(:original_file) { nil }

        it 'redirects to provider applications home page' do
          subject
          expect(response).to redirect_to providers_legal_aid_applications_path
        end
      end
    end

    context 'Upload button pressed' do
      let(:button_clicked) { upload_button }
      let(:original_file) { nil }

      it 'errors if no file is specified' do
        subject
        expect(response.body).to include 'There is a problem'
        expect(response.body).to include 'You must choose at least one file'
      end
    end
  end

  describe 'DELETE /providers/applications/:legal_aid_application_id/statement_of_case' do
    let(:statement_of_case) { create :statement_of_case, :with_attached_files }
    let(:legal_aid_application) { statement_of_case.legal_aid_application }
    let(:original_file) { statement_of_case.original_files.first }
    let(:params) { { original_file_id: original_file.id } }

    subject { delete providers_legal_aid_application_statement_of_case_path(legal_aid_application), params: params }

    before do
      login_as provider
      subject
    end

    it 'redirects to show' do
      expect(request).to redirect_to(providers_legal_aid_application_statement_of_case_path(legal_aid_application))
    end

    it 'deletes the file' do
      expect(ActiveStorage::Attachment.exists?(original_file.id)).to be(false)
    end
  end
end

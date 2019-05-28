module CCMS
  class ObtainCaseReferenceService < BaseSubmissionService
    def call
      tx_id = reference_data_requestor.transaction_request_id
      response = reference_data_requestor.call
      submission.case_ccms_reference = ReferenceDataResponseParser.new(tx_id, response).reference_id
      create_history(:initialised, submission.aasm_state) if submission.obtain_case_ref!
    rescue CcmsError, StandardError => e # TODO: Replace `StandardError` with list of known expected errors
      handle_failure(e)
    end

    private

    def reference_data_requestor
      @reference_data_requestor ||= ReferenceDataRequestor.new
    end
  end
end

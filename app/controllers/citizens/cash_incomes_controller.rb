module Citizens
  class CashIncomesController < CitizenBaseController
    before_action :aggregated_cash_income, only: %i[show update]

    def show
      return go_forward unless Setting.allow_cash_payment?
    end

    def update
      if aggregated_cash_income.update(form_params)
        go_forward
      else
        render :show
      end
    end

    private

    def aggregated_cash_income
      @aggregated_cash_income ||= AggregatedCashIncome.find_by(legal_aid_application_id: legal_aid_application.id)
    end

    def form_params
      params
        .require(:aggregated_cash_income)
        .merge({
                 legal_aid_application_id: legal_aid_application[:id],
                 none_selected: params[:none_selected]
               })
    end
  end
end
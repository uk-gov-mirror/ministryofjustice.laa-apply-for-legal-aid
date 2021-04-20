module LegalAidApplications
  class UsedMultipleDelegatedFunctionsForm
    include ActiveModel::Model

    # validate :date_in_range
    # validates :used_delegated_functions, presence: { unless: :draft? }
    # validates :used_delegated_functions_on, date: { not_in_the_future: true }, allow_nil: true
    # validates :used_delegated_functions_on,
    #           :used_delegated_functions_reported_on,
    #           presence: { unless: :date_not_required? }

    # after_validation :update_substantive_application_deadline

    attr_accessor :legal_aid_application_id,
                  :none_selected

    class << self
      def proceeding_type_name(type)
        ProceedingType.find(type.proceeding_type_id).meaning.downcase.strip.gsub(/[^a-z ]/i, '').gsub(/\s+/, '_')
      end

      def call(legal_aid_application)

        legal_aid_application.application_proceeding_types.each do |proceeding_type|
          name = proceeding_type_name(proceeding_type)
          attr_accessor :"check_box_#{name}",
                        :"#{name}_used_delegated_functions_on_1i",
                        :"#{name}_used_delegated_functions_on_2i",
                        :"#{name}_used_delegated_functions_on_3i",
                        :"#{name}_used_delegated_functions_on"
        end

        model = new
        model.__send__('legal_aid_application_id=', legal_aid_application.id)

        legal_aid_application.application_proceeding_types.each do |proceeding_type|
          name = proceeding_type_name(proceeding_type)
          populate_attribute(model, name, proceeding_type.used_delegated_functions_on)
        end

        model
      end

      def populate_attribute(model, name, date)
        return unless date

        model.__send__("check_box_#{name}=", 'true')
        model.__send__("#{name}_used_delegated_functions_on=", date)
        model.__send__('none_selected=', false)
      end
    end

    def save(params)
      update_proceeding_attributes(params)

      return false unless valid?

      save_proceeding_records
      update_substantive_application_deadline
      true
    end

    def update_proceeding_attributes(params)
      params.each do |key, value|
        __send__("#{key}=", value) if defined? method(key).call
      end
    end

    def save_proceeding_records
      application_proceeding_types.each do |type|
        name = ProceedingType.find(type.proceeding_type_id).meaning.downcase.strip.gsub(/[^a-z ]/i, '').gsub(/\s+/, '_')
        delegated_functions_date = checkbox_for?(name) ? delegated_functions_date(name) : nil

        type.update(used_delegated_functions_on: delegated_functions_date)
        type.update(used_delegated_functions_reported_on: delegated_functions_reported_date(delegated_functions_date))
      end
    end

    def earliest_delegated_functions_date
      earliest_delegated_functions&.used_delegated_functions_on
    end

    def earliest_delegated_functions_reported_date
      earliest_delegated_functions&.used_delegated_functions_reported_on
    end

    private

    def legal_aid_application
      @legal_aid_application ||= LegalAidApplication.find(legal_aid_application_id)
    end

    def application_proceeding_types
      @application_proceeding_types ||= legal_aid_application.application_proceeding_types
    end

    def earliest_delegated_functions
      @earliest_delegated_functions ||= application_proceeding_types.first.earliest_delegated_functions
    end

    def proceeding_type_name(type)
      ProceedingType.find(type.proceeding_type_id).meaning.downcase.strip.gsub(/[^a-z ]/i, '').gsub(/\s+/, '_')
    end

    def checkbox_for?(category)
      __send__("check_box_#{category}") == 'true'
    end

    def delegated_functions_date(name)
      Date.parse("#{__send__("#{name}_used_delegated_functions_on_1i")}-#{__send__("#{name}_used_delegated_functions_on_2i")}-#{__send__("#{name}_used_delegated_functions_on_3i")}")
    end

    def delegated_functions_reported_date(date)
      Time.zone.today unless date.nil? || date_over_a_month_ago?(date)
    end

    def date_over_a_month_ago?(date)
      date.before?(Time.zone.today - 1.month + 1.day)
    end

    def date_in_range?
      return if date_not_required? || !datetime?(earliest_delegated_functions_date)
      return true if Time.zone.parse(earliest_delegated_functions_date.to_s) >= Date.current.ago(12.months)

      add_date_in_range_error
    end

    def datetime?(value)
      value.methods.include? :strftime
    end

    def add_date_in_range_error
      translation_path = 'activemodel.errors.models.legal_aid_application.attributes.used_delegated_functions_on.date_not_in_range'
      errors.add(:used_delegated_functions, I18n.t(translation_path, months: Time.zone.now.ago(12.months).strftime('%d %m %Y')))
    end

    def substantive_application_deadline
      return unless earliest_delegated_functions_date && earliest_delegated_functions_date != :invalid

      SubstantiveApplicationDeadlineCalculator.call legal_aid_application
    end

    def update_substantive_application_deadline
      legal_aid_application.substantive_application_deadline_on = substantive_application_deadline
      legal_aid_application.save!
    end
  end
end

module LegalAidApplications
  class UsedMultipleDelegatedFunctionsForm
    include ActiveModel::Model

    # validate :date_in_range
    # validates :used_delegated_functions, presence: { unless: :draft? }
    # validates :used_delegated_functions_on, date: { not_in_the_future: true }, allow_nil: true
    # validates :used_delegated_functions_on,
    #           :used_delegated_functions_reported_on,
    #           presence: { unless: :date_not_required? }

    attr_accessor :application_proceeding_types,
                  :none_selected

    class << self
      def proceeding_type_name(type)
        ProceedingType.find(type.proceeding_type_id).meaning.downcase.strip.gsub(/[^a-z ]/i, '').gsub(/\s+/, '_')
      end

      def call(application_proceeding_types)

        application_proceeding_types.each do |proceeding_type|
          name = proceeding_type_name(proceeding_type)
          attr_accessor :"check_box_#{name}",
                        :"#{name}_used_delegated_functions_on_1i",
                        :"#{name}_used_delegated_functions_on_2i",
                        :"#{name}_used_delegated_functions_on_3i",
                        :"#{name}_used_delegated_functions_on"
        end

        model = new

        model.__send__('application_proceeding_types=', application_proceeding_types)

        application_proceeding_types.each do |proceeding_type|
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

    # after_validation :update_substantive_application_deadline

    def save(params)
      update_proceeding_attributes(params)

      return false unless valid?

      save_proceeding_records
    end

    def update_proceeding_attributes(params)
      params.each do |key, value|
        __send__("#{key}=", value) if defined? method(key).call
      end
    end

    def save_proceeding_records
      application_proceeding_types.each do |type|
        name = ProceedingType.find(type.proceeding_type_id).meaning.downcase.strip.gsub(/[^a-z ]/i, '').gsub(/\s+/, '_')
        if checkbox_for(name) == 'true'
          type.update(used_delegated_functions_on: process_on_date(name))
          type.update(used_delegated_functions_reported_on: process_reported_on_date(name))
        else
          type.update(used_delegated_functions_on: nil)
          type.update(used_delegated_functions_reported_on: nil)
        end
      end
    end

    def used_delegated_functions?
      application_proceeding_types.any? { |type| type.used_delegated_functions_on.present? }
    end

    def earliest_delegated_functions_date
      @earliest_delegated_functions_date ||= application_proceeding_types.earliest_delegated_function_date
    end

    private

    def proceeding_type_name(type)
      ProceedingType.find(type.proceeding_type_id).meaning.downcase.strip.gsub(/[^a-z ]/i, '').gsub(/\s+/, '_')
    end

    def process_on_date(name)
      Date.parse("#{__send__("#{name}_used_delegated_functions_on_1i")}-#{__send__("#{name}_used_delegated_functions_on_2i")}-#{__send__("#{name}_used_delegated_functions_on_3i")}")
    end

    def process_reported_on_date(name)
      Time.zone.today unless process_on_date(name).before?(Time.zone.today - 1.month + 1.day)
    end

    def checkbox_for(category)
      __send__("check_box_#{category}")
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

    # def substantive_application_deadline
    #   return unless used_delegated_functions_on && used_delegated_functions_on != :invalid
    #
    #   SubstantiveApplicationDeadlineCalculator.call self
    # end
    #
    # def update_substantive_application_deadline
    #   model.substantive_application_deadline_on = substantive_application_deadline
    # end
  end
end

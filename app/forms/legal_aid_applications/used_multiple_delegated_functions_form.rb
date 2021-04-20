module LegalAidApplications
  class UsedMultipleDelegatedFunctionsForm
    include ActiveModel::Model

    # validate :date_in_range
    # validates :used_delegated_functions, presence: { unless: :draft? }
    # validates :used_delegated_functions_on, date: { not_in_the_future: true }, allow_nil: true
    # validates :used_delegated_functions_on,
    #           :used_delegated_functions_reported_on,
    #           presence: { unless: :date_not_required? }

    validate :validate_dates,
             :nothing_selected

    attr_accessor :application_proceeding_types,
                  :application_proceeding_names,
                  :check_box_none_selected

    class << self
      def call(proceeding_types, proceeding_names)
        populate_attr_accessors(proceeding_names)
        model = new
        model.__send__('application_proceeding_types=', proceeding_types)
        model.__send__('application_proceeding_names=', proceeding_names)
        populate_model_attributes(model)
        model
      end

      def populate_attr_accessors(proceeding_names)
        proceeding_names.each do |proceeding_name|
          name = proceeding_name[:name]
          attr_accessor :"check_box_#{name}",
                        :"#{name}_used_delegated_functions_on_1i",
                        :"#{name}_used_delegated_functions_on_2i",
                        :"#{name}_used_delegated_functions_on_3i",
                        :"#{name}_used_delegated_functions_on"
        end
      end

      def populate_model_attributes(model)
        model.application_proceeding_types.each do |type|
          date = type.used_delegated_functions_on
          next unless date

          proceeding_name = model.application_proceeding_names.detect { |name| name[:id] == type.proceeding_type_id }[:name]
          model.__send__("check_box_#{proceeding_name}=", 'true')
          model.__send__("#{proceeding_name}_used_delegated_functions_on=", date)
          model.__send__('check_box_none_selected=', false)
        end
      end
    end

    def save(params)
      update_proceeding_attributes(params)

      return false unless valid?

      save_proceeding_records
    end

    def earliest_delegated_functions_date
      earliest_delegated_functions&.used_delegated_functions_on
    end

    def earliest_delegated_functions_reported_date
      earliest_delegated_functions&.used_delegated_functions_reported_on
    end

    private_class_method :populate_attr_accessors,
                         :populate_model_attributes

    private

    def update_proceeding_attributes(params)
      params.each do |key, value|
        __send__("#{key}=", value) if defined? method(key).call
      end
    end

    def save_proceeding_records
      application_proceeding_types.each do |type|
        name = application_proceeding_names.detect { |name| name[:id] == type.proceeding_type_id }[:name]
        delegated_functions_date = checkbox_for?(name) ? delegated_functions_date(name) : nil

        type.update(used_delegated_functions_on: delegated_functions_date)
        type.update(used_delegated_functions_reported_on: delegated_functions_reported_date(delegated_functions_date))
      end
    end

    def nothing_selected
      return if checkbox_for?(:none_selected) || application_proceeding_names.any? { |type| checkbox_for? type[:name] }

      errors.add(:delegated_functions, I18n.t("#{error_base_path}.nothing_selected"))
    end

    def validate_dates
      return if checkbox_for? :none_selected

      application_proceeding_names.each do |proceeding_name|
        name = proceeding_name[:name]
        next unless checkbox_for? name

        validate_proceeding_date(name)
      end
    end

    def validate_proceeding_date(name)
      date = delegated_functions_date(name)
      valid = date != :invalid_date

      add_date_invalid(name) unless valid
      add_date_in_range_error(name) unless !valid || date >= Date.current.ago(12.months)
      add_date_in_future(name) unless !valid || date <= Date.current
    end

    def add_date_in_future(name)
      errors.add("#{name}_used_delegated_functions_on", I18n.t("#{error_base_path}.date_is_in_the_future"))
    end

    def add_date_invalid(name)
      errors.add("#{name}_used_delegated_functions_on", I18n.t("#{error_base_path}.date_invalid"))
    end

    def add_date_in_range_error(name)
      translation_path = "#{error_base_path}.date_not_in_range"
      errors.add("#{name}_used_delegated_functions_on", I18n.t(translation_path, months: Time.zone.now.ago(12.months).strftime('%d %m %Y')))
    end

    def error_base_path
      'activemodel.errors.models.application_proceeding_types.attributes.used_delegated_functions_on'
    end

    def earliest_delegated_functions
      @earliest_delegated_functions ||= application_proceeding_types.first.earliest_delegated_functions
    end

    def checkbox_for?(category)
      __send__("check_box_#{category}") == 'true'
    end

    def delegated_functions_date(name)
      Date.parse("#{__send__("#{name}_used_delegated_functions_on_1i")}-#{__send__("#{name}_used_delegated_functions_on_2i")}-#{__send__("#{name}_used_delegated_functions_on_3i")}")
    rescue ArgumentError
      :invalid_date
    end

    def delegated_functions_reported_date(date)
      Time.zone.today unless date.nil? || date_over_a_month_ago?(date)
    end

    def date_over_a_month_ago?(date)
      date.before?(Time.zone.today - 1.month + 1.day)
    end
  end
end

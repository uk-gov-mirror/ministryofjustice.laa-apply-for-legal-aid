module Citizens
  class InformationController < CitizenBaseController
    def show
      puts ">>>>>>>>>>>>  #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
      puts 'starting show page'
      puts "Current locale is: #{I18n.locale}"
      legal_aid_application
    end
  end
end

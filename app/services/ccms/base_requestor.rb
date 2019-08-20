module CCMS
  class BaseRequestor
    class << self
      attr_reader :wsdl, :namespaces

      def wsdl_from(filename)
        @wsdl = filename
      end

      def uses_namespaces(namespaces)
        @namespaces = namespaces.freeze
      end
    end

    def formatted_xml
      result = ''
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write(REXML::Document.new(request_xml), result)
      result
    end

    def transaction_request_id
      @transaction_request_id ||= Time.current.strftime('%Y%m%d%H%M%S%6N') + rand.to_s[2..8]
    end

    private

    # temporarily ignore this until connectivity with ccms is working
    # :nocov:
    def soap_client
      @soap_client ||= Savon.client(
        env_namespace: :soap,
        wsdl: wsdl_location,
        namespaces: namespaces,
        pretty_print_xml: true,
        convert_request_keys_to: :none,
        namespace_identifier: 'ns2',
        log: false
      )
    end
    # :nocov:

    def soap_envelope(namespaces)
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.__send__('soap:Envelope', namespaces) do
          xml.__send__('soap:Header') { soap_header(xml) }
          xml.__send__('soap:Body') { soap_body(xml) }
        end
      end
    end

    def soap_header(xml)
      xml.__send__('ns1:Security') do
        xml.__send__('ns1:UsernameToken') do
          xml.__send__('ns1:Username', ENV['SOAP_CLIENT_USERNAME'])
          xml.__send__('ns1:Password', 'Type' => ENV['SOAP_CLIENT_PASSWORD_TYPE']) { xml.text ENV['SOAP_CLIENT_PASSWORD'] }
        end
      end
    end

    def ns3_header_rq(xml)
      xml.__send__('ns3:TransactionRequestID', transaction_request_id)
      xml.__send__('ns3:Language', 'ENG')
      xml.__send__('ns3:UserLoginID', ENV['USER_LOGIN'])
      xml.__send__('ns3:UserRole', ENV['USER_ROLE'])
    end

    def wsdl_location
      "#{File.dirname(__FILE__)}/wsdls/#{self.class.wsdl}".freeze
    end

    def namespaces
      self.class.namespaces
    end
  end
end

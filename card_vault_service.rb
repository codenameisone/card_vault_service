require 'pry'

# Savon for SOAP
require 'savon'

# ActiveSupport::Inflector to use +camelize+
require 'active_support/inflector'
class CardVaultService

  # +initialize+ method takes params hash:
  #   {
  #     wsdl_url: 'http://service.url.com?wdsl',
  #     merchant_code: 'merchant_code',
  #     location_code: 'location_code',
  #     customer_code: 'default_customer_code',
  #     client_code: 'your_client_code',
  #     user_name: 'username',
  #     password: 'pass1234'
  #   }

  def initialize(params)
    params.each {|k, v| instance_variable_set "@#{k}", v}
  end

  # +get_stored_credit_card+ method takes a token:
  # "C100000000000000"
  #
  # in case of successful API request returns:
  # {
  #     credit_card:
  #         {
  #             billing_address: {postal_code: "44311"},
  #             card_account_number: "4636798623230128",
  #             card_type: "Visa",
  #             expiration_month: "10",
  #             expiration_year: "2015",
  #             name_on_card: "CHOLDER NAME",
  #             token: "C100000000582774"
  #         }
  # }
  #
  # in case of failed API request returns:
  # {error: "Reason of failure here"}

  def get_stored_credit_card(token)
    @token = token
    get_card_response client.call(:get_stored_credit_card, message: request_message(__callee__)).hash
  end

  # +add_stored_credit_card+ method takes params hash:
  # {
  #     card_account_number: '4111111111111111',
  #     expiration_month: 10,
  #     expiration_year: 2015,
  #     name_on_card: 'CARDHOLDER NAME',
  #     postal_code: 44311
  # }
  #
  # in case of successful API request returns:
  # {token: "C100000000000000"}
  #
  # in case of failed API request returns:
  # {error: "Reason of failure here"}

  def add_stored_credit_card(params)
    process_params(params)
    add_card_response client.call(:add_stored_credit_card, message: request_message(:add_stored_card)).hash
  end

  protected

  def client
    Savon.client(wsdl: WSDL_URL, convert_request_keys_to: :camelcase)
  end

  def request_message(method_name)
    method_name = method_name.to_s << "_params"
    {'clientCredentials' => client_credentials, method_name.camelize(:lower) => self.send(method_name) }
  end

  def get_stored_credit_card_params
    {customer_identifier: customer_identifier, retrieve_card_number: true, token: @token}
  end

  def add_stored_card_params
    {
        credit_card: {
            billing_address: {postal_code: @postal_code},
            card_account_number: @card_account_number,
            expiration_month: @expiration_month,
            expiration_year: @expiration_year,
            name_on_card: @name_on_card
        },
        customer_identifier: customer_identifier
    }
  end

  def client_credentials
    {client_code: @client_code, password: @password, user_name: @user_name}
  end

  def customer_identifier
    {customer_code: @customer_code, location_code: @location_code, merchant_code: @merchant_code}
  end

  def process_params(params)
    params.each {|k, v| instance_variable_set "@#{k}", v}
  end

  def get_card_response(response)
    if response[:envelope][:body][:get_stored_credit_card_response][:get_stored_credit_card_result][:succeeded]
      {credit_card: response[:envelope][:body][:get_stored_credit_card_response][:get_stored_credit_card_result][:credit_card]}
    else
      {error: response[:envelope][:body][:get_stored_credit_card_response][:get_stored_credit_card_result][:failure_reason]}
    end
  end

  def add_card_response(response)
    if response[:envelope][:body][:add_stored_credit_card_response][:add_stored_credit_card_result][:succeeded]
      {token: response[:envelope][:body][:add_stored_credit_card_response][:add_stored_credit_card_result][:token]}
    else
      {error: response[:envelope][:body][:add_stored_credit_card_response][:add_stored_credit_card_result][:failure_reason]}
    end
  end
end


WSDL_URL = 'https://services.pwsdemo.com/WSDL/PwsDemo_creditcardmanagementservice.xml'
MERCHANT = 'YachtSpot'
LOCATION = 'YachtSpot'
CUSTOMER = 'DEFAULT'

CLIENT_CODE = 'YachtSpot'
USER_NAME = 'Linxtrans'
PASSWORD = '4CgxqszzS!'

service_params = {
    wsdl_url: WSDL_URL,
    merchant_code: MERCHANT,
    location_code: LOCATION,
    customer_code: CUSTOMER,
    client_code: CLIENT_CODE,
    user_name: USER_NAME,
    password: PASSWORD
}

p CardVaultService.new(service_params).get_stored_credit_card('C100000000582802')

add_card_params = {
    card_account_number: '4111111111111111',
    expiration_month: 10,
    expiration_year: 2015,
    name_on_card: 'CHOLDER NAME',
    postal_code: 44311
}

p CardVaultService.new(service_params).add_stored_credit_card(add_card_params)


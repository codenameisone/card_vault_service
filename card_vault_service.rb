require 'pry'

# Savon for SOAP
require 'savon'

class CardVaultService
  # You may want to move this to application settings
  WSDL_URL = 'https://services.pwsdemo.com/WSDL/PwsDemo_creditcardmanagementservice.xml'

  # +get_stored_credit_card+ method takes token:
  # 'C100000000000000' and
  # ClientCredentials, CustomerIdentifier structs
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

  def get_stored_credit_card(token, client_credentials, customer_identifier)
    message = {
      'clientCredentials' => client_credentials.to_h,
      'getStoredCreditCardParams' => {
        customer_identifier: customer_identifier.to_h,
        retrieve_card_number: true,
        token: token
      }
    }
    get_card_response client.call(:get_stored_credit_card, message: message).hash
  end

  # +add_stored_credit_card+ method takes CreditCard, ClientCredentials, CustomerIdentifier structs
  #
  # in case of successful API request returns:
  # {token: "C100000000000000"}
  #
  # in case of failed API request returns:
  # {error: "Reason of failure here"}

  def add_stored_credit_card(credit_card, client_credentials, customer_identifier)
    message = {
      'clientCredentials' => client_credentials.to_h,
      'addStoredCardParams' => {
        credit_card: credit_card.to_h,
        customer_identifier: customer_identifier.to_h
      }
    }
    add_card_response client.call(:add_stored_credit_card, message: message).hash
  end

  # +update_stored_credit_card+ method takes CreditCard, ClientCredentials, CustomerIdentifier structs
  #
  # in case of successful API request returns:
  # {succeeded: true}
  #
  # in case of failed API request returns:
  # {error: "Reason of failure here"}

  def update_stored_credit_card(credit_card, client_credentials, customer_identifier)
    message = {
      'clientCredentials' => client_credentials.to_h,
      'updateStoredCardParams' => {
        credit_card: credit_card.to_h,
        customer_identifier: customer_identifier.to_h
      }
    }
    update_card_response client.call(:update_stored_credit_card, message: message).hash
  end

  protected

  def client
    Savon.client(wsdl: WSDL_URL, convert_request_keys_to: :camelcase)
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

  def update_card_response(response)
    if response[:envelope][:body][:update_stored_credit_card_response][:update_stored_credit_card_result][:succeeded]
      {succeeded: true}
    else
      {error: response[:envelope][:body][:update_stored_credit_card_response][:update_stored_credit_card_result][:failure_reason]}
    end
  end
end

# ClientCredintials struct keeps user specific credentials for PWS
# It contains:
# client_code #=> 'ClientCode'
# user_name => 'username'
# password => 'password'
ClientCredentials = Struct.new(:client_code, :user_name, :password) do
  def to_h
    {client_code: client_code, password: password, user_name: user_name}
  end
end

# CustomerIdentifier struct keeps values like merchant, location and customer codes required in PWS service:
# It contains:
# merchant_code #=> 'merchantcode'
# location_code #=> 'locationcode'
# customer_code #=> 'customercode'
CustomerIdentifier = Struct.new(:merchant_code, :location_code, :customer_code) do
  def to_h
    {customer_code: customer_code, location_code: location_code, merchant_code: merchant_code}
  end
end

# CreditCard struct keeps credit card data required for adding new one to PWS service:
# It contains:
# card_account_number #=> '0000000000001234'
# expiration_month #=> 00
# expiration_year #=> 0000
# name_on_card #=> 'CARDHOLDER NAME'
# postal_code #=> 11111
# token #=> 'C100000000583695'
# Token is required for update_stored_credit_card to fetch the specific card,
# in other cases this parameter can be omitted.
CreditCard = Struct.new(:card_account_number, :expiration_month, :expiration_year, :name_on_card, :postal_code, :token) do
  def to_h
    {
      billing_address: {postal_code: postal_code},
      card_account_number: card_account_number,
      expiration_month: expiration_month,
      expiration_year: expiration_year,
      name_on_card: name_on_card,
      token: token
    }
  end
end

# Service showcase:

MERCHANT = 'YachtSpot'
LOCATION = 'YachtSpot'
CUSTOMER = 'DEFAULT'

CLIENT_CODE = 'YachtSpot'
USER_NAME = 'Linxtrans'
PASSWORD = '4CgxqszzS!'

# c_c = ClientCredentials.new(CLIENT_CODE, USER_NAME, PASSWORD)
# c_i = CustomerIdentifier.new(MERCHANT, LOCATION, CUSTOMER)
# token = 'C100000000585750'
#
# p CardVaultService.new.get_stored_credit_card(token, c_c, c_i)
#
# cr_c = CreditCard.new(
#     '4111111111111111',
#     10,
#     2015,
#     'CHOLDER NAME',
#     44311
# )
#
# token = CardVaultService.new.add_stored_credit_card(cr_c, c_c, c_i)[:token]
#
# cr_c = CreditCard.new(
#     '4111111111111111',
#     12,
#     2015,
#     'CHOLDER NAME',
#     44311,
#     token
# )
#
# p CardVaultService.new.update_stored_credit_card(cr_c, c_c, c_i)

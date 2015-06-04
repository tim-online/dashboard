require 'savon'

XOLPHIN_WSDL = 'https://www.sslcertificaten.nl/API3?WSDL'

# create a client for the service
client = Savon.client do
  wsdl XOLPHIN_WSDL
  pretty_print_xml true
  # raise_errors false
  convert_request_keys_to :none
  # log true
end

# print client.operations
# print ENV['XOLPHIN_USER']
# print ENV['XOLPHIN_PASS']
# exit 2
message = {
  Authentication: {
    Username: ENV['XOLPHIN_USER'],
    Password: ENV['XOLPHIN_PASS']
  }
}

response = client.call(:get_certificates, message: message)
items = response.body[:get_certificates_response][:return][:item]

SCHEDULER.every '1d', :first_in => 0 do |job|
  response = client.call(:get_certificates, message: message)
  items = response.body[:get_certificates_response][:return][:item]

  items = items.compact.sort_by do |a|
    a[:expire_date].to_s
  end

  rows = items.take(6).map do |item|
    diff_days = (item[:expire_date] - Date.today).to_i
    {
      'cols' => [
        {
          'value' => item[:domain].sub(/^www\./, ''),
          'title' => '',
          'class' => '',
        },
        {
          'value' => item[:expire_date].strftime('%d-%m-%Y'),
          'title' => '',
          'class' => diff_days < 14 ? 'icon-warning-sign' : '',
        },
      ]
    }
  end

  send_event('xolphin_certificates', {
    rows: rows,
    headers: [
      'Domein',
      'Datum'
    ]
  })
end

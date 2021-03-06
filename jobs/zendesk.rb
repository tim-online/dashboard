require 'zendesk_api'

client = ZendeskAPI::Client.new do |config|
  # Mandatory:

  config.url = "https://#{ENV['ZD_HOST']}/api/v2" # e.g. https://mydesk.zendesk.com/api/v2

  # Basic / Token Authentication
  config.username = ENV['ZD_USER']

  # Choose one of the following depending on your authentication choice
  # config.token = "your zendesk token"
  config.password = ENV['ZD_PASS']

  # OAuth Authentication
  # config.access_token = "your OAuth access token"

  # Optional:

  # Retry uses middleware to notify the user
  # when hitting the rate limit, sleep automatically,
  # then retry the request.
  config.retry = true

  # Logger prints to STDERR by default, to e.g. print to stdout:
  # require 'logger'
  # config.logger = Logger.new(STDOUT)

  # Changes Faraday adapter
  # config.adapter = :patron

  # Merged with the default client options hash
  # config.client_options = { :ssl => false }

  # When getting the error 'hostname does not match the server certificate'
  # use the API at https://yoursubdomain.zendesk.com/api/v2
end

SCHEDULER.every '5m', :first_in => 0 do |job|
  tickets = client.search(
    :query => "status<solved type:ticket",
    :sort_by => "created_at",
    :sort_order => "desc",
    :reload => true)
  rows = parse_tickets(tickets)

  send_event('unresolved_zendesk_tickets', {
    rows: rows,
    headers: [
      'Datum',
      'Onderwerp'
    ]
  })
  send_event('count_unresolved_zendesk_tickets', current: tickets.count)
end

SCHEDULER.every '5m', :first_in => 0 do |job|
  tickets = client.search(
    :query => "status:solved type:ticket",
    :sort_by => "created_at",
    :sort_order => "desc",
    :reload => true)
  rows = parse_tickets(tickets)

  send_event('recently_resolved_zendesk_tickets', {
    rows: rows,
    headers: [
      'Datum',
      'Onderwerp'
    ]
  })
  send_event('count_recently_resolved_zendesk_tickets', current: tickets.count)
end

def parse_tickets(tickets)
  tickets.map do |ticket|
    if ticket.via.source.from.name
      # Use email from header
      submitter = ticket.via.source.from.name
    else
      # Use zendesk user name (requires an extra api call)
      submitter = ticket.submitter.name
    end

    {
      'cols' => [
        {
          'value' => ticket.created_at.strftime('%d-%m'),
          'title' => '',
          'class' => '',
        },
        {
          'value' => ticket.subject[0..50].gsub(/\s\w+$/,'...'),
          'title' => '',
          'class' => '',
        },
      ],
    }
  end
end

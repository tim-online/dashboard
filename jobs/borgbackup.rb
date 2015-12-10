require 'time'
require 'open-uri'

SCHEDULER.every '12h', :first_in => 0 do |job|
  # buffer = '[
  #   {
  #     "repo": "ironhide.tim-online.nl",
  #     "date": "2012-04-23T18:25:43.511Z"
  #   },
  #   {
  #     "repo": "starscream.tim-online.nl",
  #     "date": "2013-04-23T18:25:43.511Z"
  #   },
  #   {
  #     "repo": "mirage.tim-online.nl",
  #     "date": "2013-04-23T18:25:43.511Z"
  #   }
  # ]'

  url = 'http://backups.tim-online.nl:2674/recent'
  buffer = open(url).read
  items = JSON.parse(buffer)

  # rows = items.take(6).map do |item|
  rows = items.map do |item|
    item['date'] = Time.parse(item['date'])
    diff_days = (Date.today - item['date'].to_datetime).to_i
    {
      'cols' => [
        {
          'value' => item['repo'],
          'title' => '',
          'class' => '',
        },
        {
          'value' => item['date'].strftime('%d-%m-%Y'),
          'title' => '',
          'class' => diff_days > 2 ? 'icon-warning-sign' : '',
        },
      ]
    }
  end

  send_event('borgbackup', {
    rows: rows,
    headers: [
      'Repo',
      'Datum'
    ]
  })
end


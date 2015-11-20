require 'time'

# SCHEDULER.every '1d', :first_in => 0 do |job|
SCHEDULER.every '1m', :first_in => 0 do |job|
  json = '[
    {
      "repo": "ironhide.tim-online.nl",
      "date": "2012-04-23T18:25:43.511Z"
    },
    {
      "repo": "starscream.tim-online.nl",
      "date": "2013-04-23T18:25:43.511Z"
    },
    {
      "repo": "mirage.tim-online.nl",
      "date": "2013-04-23T18:25:43.511Z"
    }
  ]'

  items = JSON.parse(json)

  # rows = items.take(6).map do |item|
  rows = items.map do |item|
    item['date'] = Time.parse(item['date'])
    diff_days = (item['date'].to_datetime - Date.today).to_i
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
          'class' => diff_days < 14 ? 'icon-warning-sign' : '',
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


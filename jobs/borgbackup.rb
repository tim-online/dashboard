require 'time'
require 'open-uri'

SCHEDULER.every '12h', :first_in => 0 do |job|
  # buffer = '[
  #   {
  #     "repo": "ironhide.tim-online.nl",
  #     "date": "2012-04-23T18:25:43.511Z"
  #     "mysql_date": "2012-04-23T18:25:43.511Z"
  #   },
  #   {
  #     "repo": "starscream.tim-online.nl",
  #     "date": "2013-04-23T18:25:43.511Z"
  #     "mysql_date": "2013-04-23T18:25:43.511Z"
  #   },
  #   {
  #     "repo": "mirage.tim-online.nl",
  #     "date": "2013-04-23T18:25:43.511Z"
  #     "mysql_date": ""
  #   }
  # ]'

  url = 'http://backups.tim-online.nl:2674/recent'
  buffer = open(url, :read_timeout => 60*10).read
  items = JSON.parse(buffer)

  # rows = items.take(6).map do |item|
  rows = items.map do |item|
    item['date'] = Time.parse(item['date'])
    diff_days = (Date.today - item['date'].to_datetime).to_i

    ret = {
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
        {
          'value' => '-',
          'title' => '',
          'class' => '',
        },
      ]
    }

    if item['mysql_date'] and item['mysql_date'] != ''
      item['mysql_date'] = Time.parse(item['mysql_date'])
      mysql_diff_days = (Date.today - item['mysql_date'].to_datetime).to_i

      ret['cols'][2]['value'] = item['mysql_date'].strftime('%d-%m-%Y')
      ret['cols'][2]['class'] = mysql_diff_days > 2 ? 'icon-warning-sign' : ''
    end

    ret
  end

  send_event('borgbackup', {
    rows: rows,
    headers: [
      'Repo',
      'Datum',
      'Mysql Datum'
    ]
  })
end


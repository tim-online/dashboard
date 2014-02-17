require 'jira'

options = {
  :username => ENV['JIRA_USER'],
  :password => ENV['JIRA_PASSWORD'],
  :site     => "https://#{ENV['JIRA_HOST']}",
  :context_path => '',
  :auth_type => :basic
}

client = JIRA::Client.new(options)

# issues = client.Issue.jql('duedate = now() ORDER BY due ASC')
# issues = client.Issue.jql('duedate > startOfWeek() AND duedate < endOfWeek() ORDER BY due ASC')


SCHEDULER.every '5m', :first_in => 0 do |job|
  issues = client.Issue.jql('status not in (Resolved, Closed) AND duedate >= now() ORDER BY due ASC')
  rows = issues.map do |issue|
    {
      'cols' => [
        {
          'value' => Date.parse(issue.duedate).strftime('%d-%m'),
          'title' => '',
          'class' => '',
        },
        {
          'value' => issue.project.name,
          'title' => '',
          'class' => '',
        },
        {
          'value' => issue.summary,
          'title' => '',
          'class' => '',
        }
      ]
    }
  end

  send_event('jira_duedate_week', {
    rows: rows,
    headers: [
      'Datum',
      'Project',
      'Issue'
    ]
  })
end

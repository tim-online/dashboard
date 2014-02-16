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
  issues = client.Issue.jql('duedate > startOfWeek() AND duedate < endOfWeek() ORDER BY due ASC')
  issues = issues[0..15]
  issues = issues.map do |issue|
    { label: issue.duedate, value: issue.summary }
  end

  send_event('jira_duedate_week', items: issues)
end

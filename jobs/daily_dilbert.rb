require 'net/http'

# Proxy URL - e.g. "http://127.1.1.1:8080/"
@proxy = ""
@currentDir = Dir.pwd
@stripDir = File.join(@currentDir,"assets/images/daily_dilbert")
@stripPattern = @stripDir+"/%Y%m%d.gif"
@stripsRotateEvery = 120 #seconds

def get_strip_url
  proxyURI = URI.parse(@proxy)
  http = Net::HTTP.new('www.dilbert.com', nil, proxyURI.host, proxyURI.port)
  response = http.request(Net::HTTP::Get.new('/fast'))
  response.body.scan(/<img src=\"(\/dyn\/str\_strip\/[\/0-9]*\.strip\.print\.gif)\" \/>/)[0][0] if response and response.body
end

def download_strip(url)
  proxyURI = URI.parse(@proxy)
  file_name = DateTime.now.strftime(@stripPattern)
  Net::HTTP.start('www.dilbert.com', nil, proxyURI.host, proxyURI.port) { |http|
    response = http.get(url)
    open(file_name, "wb") { |file| file.write(response.body) }
  }
  file_name
end

def make_web_friendly(file)
  # File.join doesn't work somehow - create by simple concatenation
  "/" + File.basename(File.dirname(file)) + "/" + File.basename(file)
end

SCHEDULER.every '15m', first_in: 0 do
  url = get_strip_url
  file = download_strip(url)
  if not File.exists?(file)
    warn "Dilbert strip download failed from url #{url} to file #{file}"
  end

  Dir[@stripDir+"/*"].sort!.reverse_each { |file|
     #warn "Working with #{file}"
     send_event('daily_dilbert', image: make_web_friendly(file))
     sleep(@stripsRotateEvery)
  }
end

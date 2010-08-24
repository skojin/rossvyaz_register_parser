require 'rubygems'
require 'mechanize'
require 'csv'

CSV_DELIMITER = ','

# LIB

# try handler HTTP Timeout and network errors, do 3 attempt to get page
# fail on 4th
def timeout_safe # :block
  error_n = 0
  begin
    $stderr.puts("  try get same page again...") if error_n > 0
    yield
  rescue Errno::EBADF, Timeout::Error
    error_n += 1
    error_name = $!.class.to_s
    if error_n >= 3
      $stderr.puts "#{error_name} ERROR #3"
      raise $!
    end
    sleep_for = error_n * 5
    $stderr.puts "#{error_name} ERROR ##{error_n}, sleep #{sleep_for} seconds before next attempt"
    sleep sleep_for
    retry
  end
end

def parse(doc, lines)
  doc.search('table tr').each do |tr|
    cells = tr.search('td').map{|c| c.inner_html}
    row = cells.map{|c| c.strip }
    lines << row
  end
  lines
end

# FETCH AND PARSE    
all_lines = []
  
agent = Mechanize.new
agent.redirect_ok = true
agent.max_history = 1

page = agent.get('http://www.rossvyaz.ru/activity/num_resurs/registerNum/')
doc_links = page.links_with(:href => %r{/docs/num})

File.open('num_resurs.csv', 'w') do |file|
  CSV::Writer.generate(file, CSV_DELIMITER) do |csv|
    doc_links.each do |link|
      puts "load #{link.href}"
      doc_page = timeout_safe { agent.click(link) }
      puts "  parse..."
      parse(doc_page, csv)
    end
  end
end

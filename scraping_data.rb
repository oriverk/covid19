require 'selenium-webdriver'

driver = Selenium::WebDriver.for :remote, desired_capabilities: :chrome, url: "http://#{ENV['SELENIUM_HOST']}:4444/wd/hub"

# スクレイピング
driver.navigate.to(ENV['URL'])
list_table = driver.find_element(:class => "list_table")
urls = list_table.find_elements(:tag_name => "a")
# texts = list_table.find_elements(:tag_name => "a")
# count = urls.length - 1
url = urls[0].attribute("href")
puts "news url = "
puts url

driver.navigate.to("https://www.pref.miyazaki.lg.jp/kohosenryaku/kenko/hoken/covid19_20200408.html")
# noicon
uls = driver.find_elements(:class => "noicon")
count = uls.length - 1
for i in 0..count do
  puts "---"
  ul = uls[i]
  p ul.text
  p ul.text.match(/（1）居住地(\w+)/m)
  p ul.text.match(/（2）年齢(\w+)/m)
end

exit


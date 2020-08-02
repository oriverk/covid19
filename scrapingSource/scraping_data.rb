require 'selenium-webdriver'
require 'date'

today = Date.today.strftime("%Y/%m/%d")
driver = Selenium::WebDriver.for :remote, desired_capabilities: :chrome, url: "http://#{ENV['SELENIUM_HOST']}:4444/wd/hub"

# 最新ニュースのURL取得
driver.navigate.to(ENV['URL'])
list_table = driver.find_element(:class => "datatable")
trs = list_table.find_elements(:tag_name => "tr")

count = trs.length - 1
datas = []
dates = {}
statuses = {"入院中"=>0, "宿泊療養中"=>0, "退院" => 0, "死亡" => 0}

for i in 1..count do
  # 1行目は列名にあたるのでスキップする
  data = {}
  tr = trs[i]
  tds = tr.find_elements(:tag_name => "td")

  no = tds[0].text

  date_splits = tds[1].text.split("月")
  month = date_splits[0]
  if month.length == 1 then
    month = "0#{month}"
  end
  day = date_splits[1].split("日")[0]
  if day.length == 1 then
    day = "0#{day}"
  end
  date = "2020-#{month}-#{day}T08:00:00.000Z"

  if dates.has_key?(date) == false then
    dates[date] = 1
  else
    dates[date] += 1
  end

  age = tds[2].text
  gender = tds[3].text
  address = tds[4].text.split("\n")[0]
  status = tds[5].text

  case status
  when "入院調整中", "入院中",
    statuses["入院中"] += 1
  when "宿泊療養中"
    statuses["宿泊療養中"] += 1
  when "死亡"
    statuses["死亡"] += 1
  else
    statuses["退院"] += 1
  end

  contactStatus = tds[6].text

  data["NO"] = no
  data["リリース日"] = date
  data["居住地"] = address
  data["年代"] = age
  data["性別"] = gender
  data["退院"] = status
  data["接触状況"] = contactStatus

  datas.push(data)
end

reverseDates = Hash[dates.to_a.reverse]
dataHash = []
reverseDates.each do |key, value|
  dataHash.push({
                    "日付"=> key,
                    "小計"=> value
                })
end

statusHash = []
statuses.each do |key, value|
  statusHash.push({
                      "attr"=>key,
                      "value"=>value
                  })
end

data_count = datas.length

data_hash = {}
File.open("data/data.json") do |file|
  data_hash = JSON.load(file)
end

# data.json を更新
data_hash["lastUpdate"] = today
data_hash["patients"]["date"] = today
data_hash["patients"]["data"] = datas
data_hash["main_summary"]["children"][0]["value"] = data_count
data_hash["main_summary"]["children"][0]["children"] = statusHash
data_hash["patients_summary"]["data"] = dataHash

data_json = JSON.pretty_generate(data_hash, {:indent => "    "})
File.open("data/data.json", mode = "w") { |f|
  f.write(data_json)
}

exit

# Description:
#   bot helps to enjoy slack life
#
# Dependencies:
#   $ npm install
#
# Configuration:
#   You need to set following environment variables
#     SLACK_TOKEN METADATA_API_KEY CHANNEL
#

Botkit  = require 'botkit'
helper  = require './helper.coffee'
os      = require 'os'
request = require 'request'

controller = Botkit.slackbot {retry: Infinity, debug: true}

bot = controller.spawn token:process.env.SLACK_TOKEN
  .startRTM()

controller.on 'tick', (bot, event) ->
  return null

# pikabo help
controller.hears ['^help'], 'direct_message,direct_mention,mention', (bot,message) ->
  bot.reply message, '''
```
pikabo help          -- Display this help
pikabo ping          -- Check whether a bot is alive
pikabo weather       -- Ask today's weather
pikabo pollen        -- Ask today's pollen
pikabo yahoo-news    -- Display current yahoo news highlight
pikabo kindle        -- Display daily kindle sale book
pikabo train         -- Display train status
pikabo ping [IPADDR]         -- Execute ping [IPADDR] from bot server
pikabo traceroute [IPADDR]   -- Execute traceroute [IPADDR] from bot server
pikabo whois [IPADDR]        -- Execute whois [IPADDR]
pikabo vote [TITLE] [ITEM1],[ITEM2],[ITEM3] -- Create vote template
```
                     '''

# pikabo ping/pikabo ping 8.8.8.8
controller.hears ['^ping(.*)'], 'direct_message,direct_mention,mention', (bot, message) ->
  matches = message.text.match /ping(.*)/i
  if matches[1].length < 1
    bot.reply message, 'PONG'
  else
    ip_addr = matches[1].trim()
    if helper.isIpaddr ip_addr
      exec = require('child_process').exec
      exec "ping #{ip_addr} -c 5", (error, stdout, stderr) ->
        if stdout?
          bot.reply message, "```#{stdout}```"
        else
          bot.reply message, 'Something wrong'
    else
      bot.reply message, 'Omae IPv4 address mo wakaranaino'

# pikabo traceroute 8.8.8.8
controller.hears ['^traceroute(.*)'], 'direct_message,direct_mention,mention', (bot, message) ->
  matches = message.text.match /traceroute(.*)/i
  if matches[1].length < 1
    bot.reply message, 'IPv4 address wo iretene'
  else
    ip_addr = matches[1].trim()
    if helper.isIpaddr ip_addr
      exec = require('child_process').exec
      exec "traceroute #{ip_addr}", (error, stdout, stderr) ->
        if stdout?
          bot.reply message, "```#{stdout}```"
        else
          bot.reply message, 'Something wrong'
    else
      bot.reply message, 'Omae IPv4 address mo wakaranaino'

# pikabo whois 8.8.8.8
controller.hears ['^whois(.*)'], 'direct_message,direct_mention,mention', (bot, message) ->
  matches = message.text.match /whois(.*)/i
  if matches[1].length < 1
    bot.reply message, 'IPv4 address wo iretene'
  else
    ip_addr = matches[1].trim()
    if helper.isIpaddr ip_addr
      exec = require('child_process').exec
      exec "whois #{ip_addr}", (error, stdout, stderr) ->
        if stdout?
          bot.reply message, "```#{stdout}```"
        else
          bot.reply message, 'Something wrong'
    else
      bot.reply message, 'Omae IPv4 address mo wakaranaino'

# pikabo weather
controller.hears ['^weather'], 'direct_message,direct_mention,mention', (bot, message) ->
  helper.getWeather (weathers) ->
    res  = "今日の天気は#{weathers[0]['telop']}ってとこだな。"
    res += "最高気温は#{weathers[0]['maxtemp']}度らしいよ。" if weathers[0]['maxtemp']?
    res += "\nちなみに明日は#{weathers[1]['telop']}よ。"
    res += "最高気温は#{weathers[1]['maxtemp']}度らしいよ。" if weathers[1]['maxtemp']?
    bot.reply message, res

# pikabo yahoo-news
controller.hears ['^yahoo-news'], 'direct_message,direct_mention,mention', (bot, message) ->
  helper.getYahooNews (items) ->
    bot.reply message, "Yahoo Newsな。詳細は自分で確認して。"
    for item in items
      bot.reply message, "・#{item}"

# pikabo pollen
controller.hears ['^pollen'], 'direct_message,direct_mention,mention', (bot, message) ->
  helper.getPollen (pollens) ->
    bot.reply message, "今日は「花粉は#{pollens[0]}」ってさ"

# pikabo kindle
controller.hears ['^kindle'], 'direct_message,direct_mention,mention', (bot, message) ->
  helper.getKindleBook (book) ->
    bot.reply message, "今日のKindle日替わりセール本は「#{book}」よ。買うしかないっしょ!!"

# pikabo say train
controller.hears ['^train'], 'direct_message,direct_mention,mention', (bot, message) ->
  helper.getDelayedTrain (trains) ->
    if trains.length > 0
      bot.reply message, '遅延してる電車な。'
      for train in trains
        bot.reply message, "・#{train}"
    else
      bot.reply message, '遅延は特になし。'

# pikabo vote title item1,item2,item3
controller.hears ['^vote (.*)'], 'direct_message,direct_mention,mention', (bot, message) ->
  matches = message.text.match /vote (.*)/i
  params = matches[1].trim().split(" ")
  title = params[0]
  items = params.slice(1).join(" ").split(",")
  bot.reply message, "#{title}の投票するよ"
  bot.reply message, "集計するときは-1を忘れずに(pikaboを除く)"
  bot.reply message, "-----------------------------------------"
  helper.postMessages message, items


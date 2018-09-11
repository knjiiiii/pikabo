module.exports = (robot) ->
  robot.hear /(天気|weather) (.*)/, (msg) ->
    request = require 'request'
    request
      url:'https://map.yahooapis.jp/weather/V1/place'
      ps:
        appid: process.env.YAHOO_APPID
        coordinates: "35.3388593,139.491122"
        output: "json"
    , (err, response, body) ->
      if response.statusCode is 200
        json = JSON.parse body
        result = json['YDF']['Feature'][0]['Property']['WeatherList']['Weather']
        msg.send "今降ってる降水量は#{result['Rainfall']}です" if result['Type'] = observation
      else
        console.log "response error: #{response.statusCode}"
        console.log body

###
module.exports = (robot) ->
  robot.hear /(天気|weather) (.*)/, (msg) ->
    georequest = robot.http("https://maps.googleapis.com/maps/api/geocode/json")
                   .query(address: msg.match[1])
                   .get()
    weather = robot.http("https://map.yahooapis.jp/weather/V1/place")
                   .query(coordinates: "#{location['lat']},#{location['lng']}", appid=process.env.YAHOO_APPID)
                   .get()
    weather (err, res, body) ->
      json = JSON.parse body
      result = json['YDF']['Feature'][0]['Property']['WeatherList']['Weather']
      msg.send "今降ってる降水量は#{result['Rainfall']}です" if result['Type'] = observation
###

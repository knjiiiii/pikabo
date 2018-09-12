module.exports = (robot) ->
  robot.hear /(天気|weather) (.*)/, (msg) ->

    # 位置情報の取得
    georequest = require 'request'
    georequest = robot.http("https://maps.googleapis.com/maps/api/geocode/json")
                   .query(address: msg.match[2])
                   .get()
    georequest (err, res, body) ->
      json = JSON.parse body
      location = json['results'][0]['geometry']['location']

      # 降水量の取得
      request = require 'request'
      request
        url: "https://map.yahooapis.jp/weather/V1/place?appid=#{process.env.YAHOO_APPID}&coordinates=#{location['lng']},#{location['lat']}&output=json"
      , (err, response, body) ->
        if response.statusCode is 200
          json = JSON.parse body
          result = json['Feature'][0]['Property']['WeatherList']['Weather']
          msg.send "現在の#{msg.match[2]}の降水量は#{result[0]['Rainfall']}です。そのうち自発的に伝えるつもり。"
        else
          res = []
          res.push "response error: #{response.statusCode}"
          res.push "\n"+body
          msg.send res 


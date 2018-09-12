module.exports = (robot) ->
  robot.hear /(天気|weather) (.*)/, (msg) ->

    # 降水量取得
    rainfunc = (geo) ->
      rainrequest = require 'request'
      rainrequest
        url: "https://map.yahooapis.jp/weather/V1/place"
        qs:
          appid: process.env.YAHOO_APPID
          coordinates: geo
          output: 'json'
        , (err, response, body) ->
          if response.statusCode is 200
            json = JSON.parse body
            rainresult = json['Feature'][0]['Property']['WeatherList']['Weather']
            msg.send "現在の#{msg.match[2]}の降水量は#{rainresult[0]['Rainfall']}です。そのうち自発的に伝えるつもり。"
          else
            msg.send "#{response.statusCode}っぽい察して"

    # 位置情報の取得
    georequest = require 'request'
    georequest
      url: "https://map.yahooapis.jp/geocode/V1/geoCoder"
      qs:
        appid: process.env.YAHOO_APPID
        query: msg.match[2]
        recursive: 'true'
        output: 'json'
      , (err, response, body) ->
        if response.statusCode is 200
          json = JSON.parse body
          if json['ResultInfo']['Count'] > 0
            georesult = json['Feature'][0]['Geometry']
            rainfunc(georesult['Coordinates'])
          else
            msg.send "町、大字レベル (ex：東京都港区六本木)でおねがい"


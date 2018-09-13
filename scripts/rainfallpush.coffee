# Description:
#   bot helps to enjoy slack life
#
# Dependencies:
#   $ npm install
#

cronJob = require('cron').CronJob
rainrequest = require 'request'

module.exports = (robot) ->

  # 毎分rainfallCheckを実行
  new cronJob(
    # Crontabの設定方法と基本一緒 *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
    cronTime: "0 */30 6-21 * * 1-5" # 実行時間
    start:    true              # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"      # タイムゾーン指定
    onTick: ->                  # 時間が来た時に実行する処理
      rainfallCheck robot
      return
    )

　# 降水量取得
  rainfallCheck = (robot) ->
    rainrequest
      url: "https://map.yahooapis.jp/weather/V1/place"
      qs:
        appid: process.env.YAHOO_APPID
#        coordinates: "132.458282,33.424833",  # 雨降ってるところテスト用（例：愛媛）
        coordinates: "139.757793,35.671182",  # 日比谷
        output: 'json'
      , (err, response, body) ->
        if response.statusCode is 200
          json = JSON.parse body
          rainresult = json['Feature'][0]['Property']['WeatherList']['Weather']

          if rainresult[0].Rainfall > 0
            robot.send {room: "#sandbox"}, "今、日比谷は雨降ってるっぽい？降水量が#{rainresult[0]['Rainfall']}mm/hですって。"
          else
            robot.send {room: "#sandbox"}, "今、日比谷は雨降って無さそう"
        else
          robot.send {room: "#sandbox"}, "#{response.statusCode}っぽい察して"

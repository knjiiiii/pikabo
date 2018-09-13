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
    cronTime: "0 */1 * * * 1-5" # 実行時間
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
        coordinates: "138.55898280,37.37189930",
        output: 'json'
      , (err, response, body) ->
        if response.statusCode is 200
          json = JSON.parse body
          rainresult = json['Feature'][0]['Property']['WeatherList']['Weather']
          robot.send {room: "#sandbox"}, "今、日比谷は雨降ってるっぽい？降水量が#{rainresult[0]['Rainfall']}mm/hですって。"
        else
          robot.send {room: "#sandbox"}, "#{response.statusCode}っぽい察して"

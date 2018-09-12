# Description:
#   bot helps to enjoy slack life
#
# Dependencies:
#   $ npm install
#

CronJob = require("cron").CronJob
Quiche = require("quiche")
Promise = require("bluebird")

rainfall_param = {
  lat: "37.37189930",
  lon: "138.55898280",
  zoom: "16",
  nonzoom: "14",
  map_image_x: "500",
  map_image_y: "500"
}

rainfallcheck_param = {
  cron_time: "0 */10 0,6-22 * * *",
  lat: "37.37189930",
  lon: "138.55898280",
  lat_for_map: "37.37189930",
  lon_for_map: "137.75898280",
  zoom: "9",
  map_image_x: "500",
  map_image_y: "500",
  alert_channel_id: "CBTHZAB25",
  alert_thresh: "0.5"
}


module.exports = (robot) ->

  job = new CronJob(
    cronTime: rainfallcheck_param.cron_time
    onTick: ->
      rainfallCheck robot, robot, false
      return
    start: true
  )

  robot.brain.set 'raining', 'false'

  unless process.env.YAHOO_APPID?
    robot.logger.warning 'Required YAHOO_APPID environment.'
    return

  robot.hear /^rainfallcheck$/i, (msg) ->
    rainfallCheck robot, msg, true
    return

  robot.hear /^rainfall$/i, (msg) ->
    url = getRainfallRadarUrl rainfall_param.lat, rainfall_param.lon, rainfall_param.nonzoom, rainfall_param.map_image_x, rainfall_param.map_image_y
    msg.send url
    return

  robot.hear /^rainfall zoom$/i, (msg) ->
    url = getRainfallRadarUrl rainfall_param.lat, rainfall_param.lon, rainfall_param.zoom, rainfall_param.map_image_x, rainfall_param.map_image_y
    msg.send url
    return

  robot.hear /rainfall( zoom)? (.+)/i, (msg) ->
    zoom = if msg.match[1] then "16" else "14"
    area = msg.match[2]

    console.log msg.match

    if msg.match[1] == undefined and msg.match[2] == "zoom"
      # capture this at
      # robot.hear /^rainfall zoom$/
      return

    getLALFromAreaString_promised(msg, area).then ((result) ->
      console.log result
      if result.ResultInfo.Count == 0
        msg.send "「#{area}」 を地名として特定できませんでした。"
        return
      else
        msg.send "#{result.Feature[0].Name}の現在の雨雲"
        coordinates = (result.Feature[0].Geometry.Coordinates).split(",")
        lon = coordinates[0]
        lat = coordinates[1]
        url = getRainfallRadarUrl lat, lon, zoom, rainfall_param.map_image_x, rainfall_param.map_image_y
        msg.send url
      )

rainfallCheck = (robot, msg, notify_nodiff) ->

  # YOLP(地図):気象情報API - Yahoo!デベロッパーネットワーク
  # http://developer.yahoo.co.jp/webapi/map/openlocalplatform/v1/weather.html

  url = "http://weather.olp.yahooapis.jp/v1/place"

  robot.http(url)
  .query({
    appid: process.env.YAHOO_APPID,
    coordinates: rainfallcheck_param.lon + "," + rainfallcheck_param.lat,
    output: "json"
    })
  .get() (err, res, body) ->
    data = JSON.parse(body)
    rainfall = data.Feature[0].Property.WeatherList.Weather
    rainfallCheckShowResult robot, rainfall, notify_nodiff, rainfallcheck_param.map_image_x


rainfallCheckShowResult = (robot, rainfall, notify_nodiff, width) ->

  timeString = getTimeString 30
  send_message = false

  if rainfall[3].Rainfall >= rainfallcheck_param.alert_thresh and ((robot.brain.get 'raining') == 'false')
    send_message = true
    head_message = timeString + "に" + rainfall[3].Rainfall + "mm/hの雨が近づいています。 "

  else if rainfall[3].Rainfall < rainfallcheck_param.alert_thresh and ((robot.brain.get 'raining') == 'true')
    send_message = true
    head_message = timeString + "に雨が止みます。 "

  else if notify_nodiff and rainfall[3].Rainfall >= rainfallcheck_param.alert_thresh and ((robot.brain.get 'raining') == 'true')
    send_message = true
    head_message = timeString + "にも" + rainfall[3].Rainfall + "mm/hの雨が降り続いています。 "

  else if notify_nodiff and rainfall[3].Rainfall < rainfallcheck_param.alert_thresh and ((robot.brain.get 'raining') == 'false')
    send_message = true
    head_message = timeString + "には雨の心配はありません:  "

  # update rainfall
  if rainfall[3].Rainfall > rainfallcheck_param.alert_thresh
    robot.brain.set 'raining', 'true'
  else
    robot.brain.set 'raining', 'false'

  if send_message == true
    # Reference for options

    # Quiche
    # https://www.npmjs.com/package/quiche

    # Raw options
    # https://developers.google.com/chart/image/docs/gallery/bar_charts

    graph_font_size = 16

    d = new Date
    d.setTime (d.getTime() + 1000 * 60 * 30) # Add 30 minutes
    year  = d.getFullYear()
    month = d.getMonth() + 1
    date  = d.getDate()
    hour  = d.getHours()
    min   = d.getMinutes()

    if month < 10
      month_str = "0#{month}"
    else
      month_str = "#{month}"

    if date < 10
      date_str = "0#{date}"
    else
      date_str = "#{date}"

    if hour < 10
      hour_str = "0#{hour}"
    else
      hour_str = "#{hour}"

    if min < 10
      min_str = "0#{min}"
    else
      min_str = "#{min}"

    d_str = "|date:#{year}" +
      month_str +
      date_str +
      hour_str +
      min_str +
      "|datelabel:on"

    bar = new Quiche 'bar'
    bar.setWidth width
    bar.setHeight 150
    bar.setBarWidth 0
    bar.setBarSpacing 0
    bar.addAxisLabels('x', [getTimeString(0), getTimeString(10), getTimeString(20), getTimeString(30), getTimeString(40), getTimeString(50), getTimeString(60)])
    bar.addData [rainfall[0].Rainfall, rainfall[1].Rainfall, rainfall[2].Rainfall, rainfall[3].Rainfall, rainfall[4].Rainfall, rainfall[5].Rainfall, rainfall[6].Rainfall], 'Rainfall(mm/h)', '00AAFF'
    bar.setAutoScaling()
    bar.setLegendBottom()
    bar.setTransparentBackground()

    # First param controls http vs. https
    bar_image_url = bar.getUrl true
    bar_image_url = bar_image_url + "&chm=N,000000,0,-1,16&chxs=0,000000,16,0,l|1,000000,16,0,l&chdls=000000,16"


    radar_url = "http://weather.yahoo.co.jp/weather/zoomradar/?lat=#{rainfallcheck_param.lat}&lon=#{rainfallcheck_param.lon}&z=12"

    rainfall_image_url = (getRainfallRadarUrl rainfallcheck_param.lat_for_map, rainfallcheck_param.lon_for_map, rainfallcheck_param.zoom, rainfallcheck_param.map_image_x, rainfallcheck_param.map_image_y)  + d_str

    urls = [bar_image_url, radar_url, rainfall_image_url]
    Promise.all( urls.map((url) ->

      bar_image_url = results[0]
      radar_url = results[1]
      rainfall_image_url = results[2]

      robot.send {room: rainfallcheck_param.alert_channel_id}, ( head_message + bar_image_url + "\n" +
        timeString + "の雨雲の様子: " + rainfall_image_url + "\n" +
        "より詳しいページヘ行く: " + radar_url + "\n" )
    )


getTimeString = (offset_minutes) ->

  d = new Date
  d.setTime (d.getTime() + 1000 * 60 * offset_minutes) # Add offset_minutes

  hour  = d.getHours()
  min   = d.getMinutes()

  if hour < 10
    hour_str = "0#{hour}"
  else
    hour_str = "#{hour}"

  if min < 10
    min_str = "0#{min}"
  else
    min_str = "#{min}"

  return hour_str+":"+min_str


getRainfallRadarUrl = (lat, lon, zoom, width, height) ->

  # for Slack preview
  zurashi = ("000" + (Math.floor(Math.random() * 100) + 1).toString()).slice(-3)
  real_size = lat.indexOf(".")

  lat = lat[0..(real_size + 1 + 3)] + zurashi

  # YOLP(地図):Yahoo!スタティックマップAPI - Yahoo!デベロッパーネットワーク
  # http://developer.yahoo.co.jp/webapi/map/openlocalplatform/v1/static.html#exp_weather

  url = "http://map.olp.yahooapis.jp/OpenLocalPlatform/V1/static?appid=" +
    process.env.YAHOO_APPID +
    "&lat=" + lat +
    "&lon=" + lon +
    "&z=" + zoom +
    "&width=" + width +
    "&height=" + height +
    "&overlay=type:rainfall"


getLALFromAreaString_promised = (msg, area) ->
  # YOLP(地図):Yahoo!ジオコーダAPI - Yahoo!デベロッパーネットワーク
  # http://developer.yahoo.co.jp/webapi/map/openlocalplatform/v1/geocoder.html
  return new Promise (resolve, reject) ->
    msg.http('http://geo.search.olp.yahooapis.jp/OpenLocalPlatform/V1/geoCoder')
      .query({
        appid: process.env.YAHOO_APPID
        query: area
        results: 1
        output: 'json'
      })
      .get() (err, res, body) ->
        if err
          reject err
        else
          resolve JSON.parse(body)
        return


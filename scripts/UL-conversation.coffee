module.exports = (robot) ->
  status  = {}

  robot.respond /(.*)/i, (res) ->
    message = res.match[1]
    return if message is ''

    res
      .http('https://chatbot-api.userlocal.jp/api/chat')
      .headers('Content-Type': 'application/json')
      .post(JSON.stringify({ message: message, key: process.env.HUBOT_UL_API_KEY})) (err, response, body) ->
        if err?
          console.log "Encountered an error #{err}"
        else
          res.send JSON.parse(body).result


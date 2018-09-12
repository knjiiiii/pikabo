# Description:
#   bot helps to enjoy slack life

module.exports = (robot) ->
  robot.respond /shell (.*)/i, (msg) ->
    COMMAND = msg.match[1]
    @exec = require('child_process').exec
    command = COMMAND 
    msg.reply "#{command}"
    @exec command, (error, stdout, stderr) ->
      msg.send error if error?
      msg.send stdout if stdout?
      msg.send stderr if stderr?


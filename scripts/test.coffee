module.exports = (robot) ->
	robot.respond /add (.*)/i, (msg) ->
		searchText = msg.match[1]
		@exec = require('child_process').exec
		command = "ls"
		msg.reply "#{command}"
		@exec command, (error, stdout, stderr) ->
			msg.send error if error?
			msg.send stdout if stdout?
			msg.send stderr if stderr?


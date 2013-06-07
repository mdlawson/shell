readline = require "readline"
os = require "os"
path = require "path"
fs = require "fs"
{spawn} = require "child_process"

EOL = os.EOL

path_dirs = process.env.PATH.split path.delimiter

bin_ext = process.env.PATHEXT.toLowerCase().split path.delimiter

history_file = path.join process.env.APPDATA,"Shell/history"
config_file =  path.join process.env.APPDATA,"Shell/config"

isBin = (file) -> 
  lower = file.toLowerCase()
  for ext in bin_ext
    if lower.indexOf(ext) > -1 then return true

class Terminal
  constructor: ->
    @history = @readHistory()
    @config = {plugins:{},completers:{},commands:{},prompt: -> process.cwd() + " > "}
    try
      config = require config_file
      config.plugins and for key,val of config.plugins
        @config.plugins[key] = val
      config.completers and for key,val of config.completers
        @config.completers[key] = val    
      config.commands and for key,val of config.commands
        @config.commands[key] = val
      config.prompt and @config.prompt = config.prompt
    @start()
    @prompt()
  prompt: =>
    if @config.prompt.length > 0
      @config.prompt.call @, (prompt) => 
        @rl.setPrompt prompt
        @rl.prompt()
    else
      prompt = @config.prompt.call @
      @rl.setPrompt prompt
      @rl.prompt()
  processLine: (line) =>
    line = line.replace /\$(\S+)|%(\S+)%/, (match,p1,p2) ->
      return process.env[p1 or p2]
    parts = line.match /(?:[^\s"']+|"[^"]*"|'[^']*')+/g
    cmd = parts.shift()
    if @config.commands[cmd] then @config.commands[cmd].call @,parts
    else if cmd is "cd"
      try 
        process.chdir parts[0]
      catch err
        if err.code is "ENOENT" then console.log "No such directory"
      @prompt()
    else if cmd is "exit"
      @rl.close()
      @writeHistory @history
    else if cmd is "cls"
      process.stdout.write '\u001B[2J\u001B[0;0f'
      @prompt()
    else if cmd is ""
      @prompt()
    else
      @stop()
      child = spawn cmd,parts,
        stdio: "inherit"
      child.on "exit", =>
        @start()
        @prompt()
      child.on "error", (err) =>
        if err.code is "ENOENT" then console.log cmd, "Not recognized as a valid command"
        @start()
        @prompt()
  
  completer: (line) =>
    parts = line.split " "
    completions = []
    if parts.length
      completer = @config.completers[parts[0]] 
      if completer
        results = completer.call @, line.replace(parts[0]+" ","")
        if results[0].length then return results
    if parts.length is 1
      fragment = parts[0]
      for dir in path_dirs
        if fs.existsSync dir
          for file in fs.readdirSync dir
            if file.indexOf(fragment) is 0 and isBin(file) then completions.push file
    else if parts.length is 2
      fragment = parts[1]
      line = fragment
      if fragment[fragment.length - 1] is "\\"
        matchingFragment = false
        base = path.join(process.cwd(),fragment)
      else
        matchingFragment = true
        line = path.basename(fragment)
        base = path.join(process.cwd(),path.dirname(fragment))

      for file in fs.readdirSync base
        if (matchingFragment and file.indexOf(line) is 0) or not matchingFragment
          isDir = fs.statSync(path.join(base,file)).isDirectory()
          if isDir then file += "\\"
          unless parts[0] is "cd" and not isDir then completions.push file
    return [completions,line]
  
  interupt: => 
    @prompt()
    return
  
  start: ->
    @rl = readline.createInterface
      input: process.stdin
      output: process.stdout
      completer: @completer
    @rl.on "line", @processLine
    @rl.on 'SIGINT', @interupt
    @rl.history = @history
  stop: -> @rl.close()  

  readHistory: ->
    dir = path.dirname history_file
    try 
      stats = fs.statSync path.dirname history_file
    catch e
      fs.mkdirSync dir
    file = fs.readFileSync(history_file,{encoding:"utf8",flag:"a+"})
    return file.split EOL  
  writeHistory: (data) ->
    string = data.join EOL
    fs.writeFileSync(history_file,string,{encoding:"utf8"})


term = new Terminal
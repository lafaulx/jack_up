class @JackUp.FileUploader
  constructor: (@options) ->
    @path = @options.path
    @isSync = @options.isSync
    @responded = false

  _onProgressHandler: (file) =>
    (progress) =>
      if progress.lengthComputable
        percent = progress.loaded/progress.total*100
        @trigger 'upload:percentComplete', percentComplete: percent, progress: progress, file: file

        if percent == 100
          @trigger 'upload:sentToServer', file: file

  _onReadyStateChangeHandler: (file, callback) =>
    self = @
    (event) =>
      status = null
      return if event.target.readyState != 4

      try
        status = event.target.status
      catch error
        return

      acceptableStatuses = [200, 201]
      acceptableStatus = acceptableStatuses.indexOf(status) > -1

      if status > 0 && !acceptableStatus
        @trigger 'upload:failure', responseText: event.target.responseText, event: event, file: file

      if acceptableStatus && event.target.responseText && !@responded
        @responded = true && !self.isSync
        @trigger 'upload:success', responseText: event.target.responseText, event: event, file: file

      callback and callback()

  _executeUpload: (file, callback) ->
    xhr = new XMLHttpRequest()
    xhr.upload.addEventListener 'progress', @_onProgressHandler(file), false
    xhr.addEventListener 'readystatechange', @_onReadyStateChangeHandler(file, callback), false

    xhr.open 'POST', @path, true

    xhr.setRequestHeader 'Content-Type', file.type
    xhr.setRequestHeader 'X-File-Name', unescape(encodeURIComponent(file.name))
    xhr.setRequestHeader 'X-CSRF-Token', $('meta[name=csrf-token]').attr('content')

    @trigger 'upload:start', file: file
    xhr.send file

  upload: (file) ->
    self = @

    if @isSync
      if file instanceof Array and file.length > 0
        f = file.shift()

        @_executeUpload f, ->
          self.upload(file)
    else 
      @_executeUpload(file)

_.extend JackUp.FileUploader.prototype, JackUp.Events

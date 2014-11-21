getFilesFromEvent = (event) ->
  if event.originalEvent.dataTransfer?
    event.originalEvent.dataTransfer.files
  else if event.originalEvent.currentTarget? && event.originalEvent.currentTarget.files?
    event.originalEvent.currentTarget.files
  else if event.originalEvent.target? && event.originalEvent.target.files?
    event.originalEvent.target.files
  else
    []

filesWithData = (event) ->
  _.map getFilesFromEvent(event), (file) ->
    file.__guid__ = Math.random().toString(36)
    file

class @JackUp.Processor
  constructor: (options) ->
    @uploadPath = options.path
    @isSync = options.isSync

  _upload: (files) ->
    fileUploader = new JackUp.FileUploader({path: @uploadPath, isSync: @isSync})
    @bubble 'upload:start', 'upload:success', 'upload:failure', 'upload:sentToServer', 'upload:percentComplete',
      from: fileUploader

    fileUploader.upload files

  processFilesForEvent: (event) =>
    files = filesWithData(event)

    _.each files, (file) =>
      reader = new FileReader()
      reader.onload = (event) =>
        @trigger 'upload:dataRenderReady', result: event.target.result, file: file

        if /^data:image/.test event.target.result
          image = $("<img>").attr("src", event.target.result)
          @trigger 'upload:imageRenderReady', image: image, file: file

      reader.readAsDataURL(file)

      if !@isSync
        @_upload(file)

    if @isSync
      @_upload(files)

    console.log('Files length', files.length)

_.extend JackUp.Processor.prototype, JackUp.Events

do ($ = jQuery, window, document) ->

  pluginName = "jCropFileInput"
  defaults =
    ratio: "",
    preview_height: "640",
    preview_width: "480"

  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options
      @_defaults = defaults
      @_name = pluginName
      @init()

    init: ->
      $(@element).on('change', @on_fileinput_change)

    on_fileinput_change: (evt) =>
      file = evt.target.files[0]
      reader = new FileReader()
      reader.onloadend = (evt) =>
        @resize_image(reader.result, file)
      reader.readAsDataURL(file)

    resize_image: (data, file) ->
      self = this
      fileType = file.type
      console.log(fileType)
      maxWidth = 1800
      maxHeight = 2400
      image = new Image()
      try
        image.src = data
      catch e
        console.log "Invalid image with file type " + fileType + " : " + e
      image.onload = (evt) =>
        size = @get_image_size(image.width, image.height)
        console.log(size)
        imageWidth = size.width
        imageHeight = size.height
        canvas = document.createElement('canvas')
        canvas.width = imageWidth
        canvas.height = imageHeight

        ctx = canvas.getContext('2d')
        ctx.drawImage(evt.target, 0, 0, imageWidth, imageHeight)
        data = canvas.toDataURL(fileType)
        console.log(data)
        @show_preview(data)

    get_image_size: (width, height) ->
      newWidth = width
      newHeight = height

      if width > height
        if width > @options.preview_width
          newHeight *= @options.preview_width / width
          newWidth = @options.preview_width
      else
        if height > @options.preview_height
          newWidth *= @options.preview_height / height
          newHeight = @options.preview_height
      return {width: newWidth, height: newHeight}
  
    show_preview: (data) ->
      console.log("preview")
      $img = $("<img>")
      $img.prop('src', data)
      $(@element).after($img)

  # A really lightweight plugin wrapper around the constructor,
  # preventing against multiple instantiations
  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(@, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))

do ($ = jQuery, window, document) ->

  pluginName = "JCropFileInput"
  defaults =
    ratio: undefined,
    jcrop_width: "640",
    jcrop_height: "480",
    preview_height: "150",
    preview_width: "150"

  class JCropFileInput
    constructor: (@element, options) ->
      @options = $.extend({}, defaults, options)
      @_defaults = defaults
      @_name = pluginName
      @init()

    init: ->
      $(@element).on('change', @on_fileinput_change)
      @widgetContainer = $("<div>")
      @widgetContainer.addClass('jcrop-fileinput-container')
      $(@element).after(@widgetContainer)
  
    on_fileinput_change: (evt) =>
      file = evt.target.files[0]
      reader = new FileReader()
      reader.onloadend = (evt) =>
        @resize_image(reader.result, file)
      reader.readAsDataURL(file)

    resize_image: (data, file) ->
      fileType = file.type
      image = document.createElement('img')
      image.src = data
      image.onload = (evt) =>
        size = @get_crop_area_size(image.width, image.height)
        imageWidth = size.width
        imageHeight = size.height
        canvas = document.createElement('canvas')
        canvas.width = imageWidth
        canvas.height = imageHeight

        ctx = canvas.getContext('2d')
        ctx.drawImage(image, 0, 0, imageWidth, imageHeight)
        data = canvas.toDataURL(fileType)
        @setup_jcrop(data)

    get_crop_area_size: (width, height) ->
      newWidth = width
      newHeight = height

      if width > height
        if width > @options.jcrop_width
          newHeight *= @options.jcrop_width / width
          newWidth = @options.jcrop_width
      else
        if height > @options.jcrop_height
          newWidth *= @options.jcrop_height / height
          newHeight = @options.jcrop_height
      return {width: newWidth, height: newHeight}

    setup_jcrop: (data) ->
      $img = $("<img>")
      $img.prop('src', data)
      $img.addClass('jcrop-image')
      @widgetContainer.append($img)
      $img.Jcrop({
        onChange: @on_jcrop_select,
        onSelect: @on_jcrop_select,
        aspectRatio: @options.ratio
      })

    on_jcrop_select: (coords) =>
      console.log(coords)

  # A really lightweight plugin wrapper around the constructor,
  # preventing against multiple instantiations
  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(@, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new JCropFileInput(@, options))

do ($ = jQuery, window, document) ->

  pluginName = "JCropFileInput"
  defaults =
    ratio: undefined,
    jcrop_width: "640",
    jcrop_height: "480",
    preview_height: "150",
    preview_width: "150",
    save_callback: undefined

  class JCropFileInput
    constructor: (@element, options) ->
      @options = $.extend({}, defaults, options)
      @_defaults = defaults
      @_name = pluginName
      @init()

    init: ->
      element_wrapper = document.createElement('div')
      element_wrapper.className ='jcrop-fileinput-wrapper'
      $(@element).wrap(element_wrapper)
      # Get a reference to the wrapping div as the wrap function makes a clone.
      @button_wrapper = $(@element).parent()
      $(@element).after("<button>Upload a file</button>")
      $(@element).on("change", @on_fileinput_change)

      @widgetContainer = $("<div>")
      @widgetContainer.addClass("jcrop-fileinput-container")
      @targetCanvas = document.createElement("canvas")
      #@widgetContainer.append($(@targetCanvas))
      @button_wrapper.after(@widgetContainer)
  
    on_fileinput_change: (evt) =>
      file = evt.target.files[0]
      reader = new FileReader()
      reader.onloadend = () =>
        @original_filetype = file.type
        @original_image = @build_image(reader.result, @on_original_image_loaded)
      reader.readAsDataURL(file)

    on_original_image_loaded: (image) =>
      @original_width = image.width
      @original_height = image.height
      @resize_image(image)
      
    on_save: (evt) =>
      evt.preventDefault()
      image_data = @targetCanvas.toDataURL(@original_filetype)
      @jcrop_api.destroy()
      @button_wrapper.slideDown()
      @widgetContainer.empty()
      if @options.save_callback
        @options.save_callback(image_data)

    build_image: (image_data, callback) ->
      image = document.createElement("img")
      image.src = image_data
      image.onload = () =>
        if callback
          callback(image)
      return image

    build_toolbar: () ->
      $toolbar = $("<div>").addClass('jcrop-fileinput-toolbar')
      $save_button = $("<button>Save</button>")
      $save_button.on('click', @on_save)
      $toolbar.append($save_button)

    resize_image: (image) ->
      size = @get_crop_area_size(image.width, image.height)
      canvas_width = size.width
      canvas_height = size.height
      canvas = document.createElement("canvas")
      canvas.width = canvas_width
      canvas.height = canvas_height

      ctx = canvas.getContext("2d")
      ctx.drawImage(image, 0, 0, canvas_width, canvas_height)
      canvas_image_data = canvas.toDataURL(@original_filetype)
      @setup_jcrop(canvas_image_data)

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
      $img.prop("src", data)
      $img.addClass("jcrop-image")
      @button_wrapper.slideUp()
      @widgetContainer.append($img)
      @widgetContainer.append(@build_toolbar())
      @widgetContainer.slideDown()
      instance = this
      $img.Jcrop(
        {
          onChange: @on_jcrop_select,
          onSelect: @on_jcrop_select,
          aspectRatio: @options.ratio
        }, () ->
          instance.jcrop_api = this
      )

    on_jcrop_select: (coords) =>
      @crop_original_image(coords)

    crop_original_image: (coords) ->
      if not coords
        return
      factor = @original_width / @options.jcrop_width
      canvas = @targetCanvas
      origin_x = coords.x * factor
      origin_y = coords.y * factor
      canvas_width = coords.w * factor
      canvas_height = coords.h * factor
      canvas.width = canvas_width
      canvas.height = canvas_height
      ctx = canvas.getContext("2d")
      ctx.drawImage(
        @original_image,
        origin_x, origin_y, canvas_width, canvas_height,
        0, 0, canvas_width, canvas_height
      )

    set_ratio: (ratio_value) ->
      if not @jcrop_api
        return
      @jcrop_api.setOptions({aspectRatio: ratio_value})

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(@, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new JCropFileInput(@, options))
      else
        instance = $.data(@, "plugin_#{pluginName}")
        for option, value of options
          if option == "ratio"
            instance.set_ratio(value)

do ($ = jQuery, window, document) ->

  pluginName = "JCropFileInput"
  defaults =
    ratio: undefined,
    jcrop_width: 640,
    jcrop_height: 480,
    scale_height: undefined,
    scale_width: undefined,
    max_height: 9999,
    max_width: 9999,
    save_callback: undefined

  class JCropFileInput
    constructor: (@element, options) ->
      @options = $.extend({}, defaults, options)
      @_defaults = defaults
      @_name = pluginName
      @init()

    init: ->
      element_wrapper = document.createElement("div")
      element_wrapper.className ="jcrop-fileinput-wrapper"
      $(@element).wrap(element_wrapper)
      # Get a reference to the wrapping div as the wrap function makes a clone.
      @button_wrapper = $(@element).parent()
      $(@element).after("<button>Upload a file</button>")
      $(@element).on("change", @on_fileinput_change)

      @widgetContainer = $("<div>")
      @widgetContainer.addClass("jcrop-fileinput-container")
      @targetCanvas = document.createElement("canvas")
      @button_wrapper.after(@widgetContainer)

    on_fileinput_change: (evt) =>
      file = evt.target.files[0]
      reader = new FileReader()
      reader.onloadend = () =>
        @original_filetype = file.type
        @original_image = @build_image(reader.result, @on_original_image_loaded)
      reader.readAsDataURL(file)

      # Reset the input field by replacing it with a clone
      $(@element).replaceWith($(@element).val("").clone(true))

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
      if @options.scale_width and @options.scale_height
        image = @build_image(image_data)
        image_data = @get_resized_image(image,
                                        @options.scale_width,
                                        @options.scale_height)
      if @options.max_width or @options.scale_height
        image = @build_image(image_data)
        size = @get_max_size(image.width, image.height,
                             @options.max_width, @options.max_height)
        image_data = @get_resized_image(image, size.width, size.height)
      if @options.save_callback
        @options.save_callback(image_data)

    build_image: (image_data, callback) ->
      image = document.createElement("img")
      image.src = image_data
      image.onload = () ->
        if callback
          callback(image)
      return image

    build_toolbar: () ->
      $toolbar = $("<div>").addClass("jcrop-fileinput-toolbar")
      $save_button = $("<button>Save</button>")
      $save_button.on("click", @on_save)
      $toolbar.append($save_button)

    get_resized_image: (image, width, height) ->
      canvas_width = width
      canvas_height = height
      canvas = document.createElement("canvas")
      canvas.width = canvas_width
      canvas.height = canvas_height
      ctx = canvas.getContext("2d")
      ctx.drawImage(image, 0, 0, canvas_width, canvas_height)
      canvas.toDataURL(@original_filetype)

    resize_image: (image) ->
      size = @get_max_size(image.width, image.height,
                           @options.jcrop_width, @options.jcrop_height)
      canvas_image_data = @get_resized_image(image, size.width, size.height)
      @setup_jcrop(canvas_image_data)

    get_max_size: (width, height, max_width, max_height) ->
      newWidth = width
      newHeight = height

      if width > height
        if width > max_width
          newHeight *= max_width / width
          newWidth = max_width
      else
        if height > max_height
          newWidth *= max_height / height
          newHeight = max_height
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
          aspectRatio: @options.ratio,
          bgColor: "white",
          bgOpacity: 0.5,
        }, () ->
          api = this
          api.setSelect([0,0,$img.width(), $img.height()])
          instance.jcrop_api = api
      )

    on_jcrop_select: (coords) =>
      @crop_original_image(coords)

    crop_original_image: (coords) ->
      if not coords
        return
      if @original_width > @original_height
        factor = @original_width / @options.jcrop_width
      else
        factor = @original_height / @options.jcrop_height

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

    set_options: (options) ->
      @options = $.extend({}, @options, options)
      @set_ratio(@options.ratio)

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
        instance.set_options(options)

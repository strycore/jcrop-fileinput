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
    save_callback: undefined,
    delete_callback: undefined,
    show_crop_button: false,
    show_delete_button: false,
    labels: {
      upload: 'Upload an image',
      change: 'Upload an image',
      delete: 'Delete image',
      crop: 'Crop',
      save: 'Save',
    }

  class JCropFileInput
    constructor: (@element, options) ->
      @options = $.extend({}, defaults, options)
      @_defaults = defaults
      @_name = pluginName
      @init()

    init: ->
      # Connect file input to signal
      $(@element).on("change", @on_fileinput_change)

      # Wrap file input in root element
      _controls_root = document.createElement("div")
      _controls_root.className = "jcrop-fileinput-wrapper"
      $(@element).wrap(_controls_root)
      # Get a reference to the wrapping div as the wrap function makes a clone.
      @controls_root = $(@element).parent()

      # Wrap the file input inside a fake button, in order to style it nicely.
      $upload_button = $("<div>#{@options.labels.upload}</div>")
      $upload_button.addClass('jcrop-fileinput-fakebutton')
      $upload_button.addClass('jcrop-fileinput-button')
      $(@element).wrap($upload_button)

      # Initialize crop button
      $crop_button = $("<button>#{@options.labels.crop}</button>")
      $crop_button.addClass("jcrop-fileinput-button")
      $crop_button.addClass("jcrop-fileinput-crop-button")
      $crop_button.on('click', @on_crop_click)
      if not @options.show_crop_button
        $crop_button.hide()
      $(@element).parent().before($crop_button)

      # Initialize delete button
      $delete_button = $("<button>#{@options.labels.delete}</button>")
      $delete_button.addClass("jcrop-fileinput-button")
      $delete_button.addClass("jcrop-fileinput-delete-button")
      $delete_button.on('click', @on_delete_click)
      if not @options.show_delete_button
        $delete_button.hide()
      $(@element).parent().after($delete_button)

      # Initialize status bar
      $status = $("<div></div>")
      $status.addClass("jcrop-fileinput-status")
      @controls_root.append($status)

      # Handle initial value of widget
      if $(@element).attr('data-initial')
        initial_image_src = $(@element).attr('data-initial')
        @build_image(initial_image_src, @on_initial_ready)

      # Build the container for JCrop
      @widgetContainer = $("<div>")
      @widgetContainer.addClass("jcrop-fileinput-container")
      @controls_root.after(@widgetContainer)

      # Instanciate the canvas containing the resized image
      @targetCanvas = document.createElement("canvas")

    on_initial_ready: (image) =>
      ### Fires when image in initial value of the input field is read ###
      @original_image = image
      @original_width = image.width
      @original_height = image.height
      @targetCanvas.width = image.width
      @targetCanvas.height = image.height

      @set_status_text(image.src, image.width, image.height)
      @add_thumbnail(image)

    add_thumbnail: (image) ->
      ### Adds the HTML img tag 'image' to the controls, binds click event ###
      @controls_root.find('.jcrop-fileinput-thumbnail').remove()
      $image = $(image)
      $image.addClass('jcrop-fileinput-thumbnail')
      $image.on('click', @on_crop_click)
      @controls_root.prepend($image)

    on_crop_click: (evt) =>
      evt.preventDefault()
      @build_jcrop_widget(@original_image.src)

    on_delete_click: (evt) =>
      evt.preventDefault()

      # Delete preview
      @controls_root.find('.jcrop-fileinput-thumbnail').remove()
      @set_status_text(null)

      # Run callback
      if @options.delete_callback
        @options.delete_callback()

    on_fileinput_change: (evt) =>
      file = evt.target.files[0]
      filename = file.name
      console.log file
      reader = new FileReader()
      reader.onloadend = () =>
        if @is_canvas_supported()
          @original_filetype = file.type
          @original_image = @build_image(reader.result,
                                          @on_uploaded_image_load)
          @set_status_text(filename, 
                           @original_image.width, @original_image.height)
        else if @options.save_callback
          @options.save_callback(reader.result)
      reader.readAsDataURL(file)

      # Reset the input field by replacing it with a clone
      # This is necessary to avoid uploading the user submitted image when the
      # actual form is uploaded.
      # BUT: Since it will recreate a DOM element, it will loose all that was
      # applied to it such as ... a polyfill, for example.
      # SO: Commenting this line. You can reset the element by intercepting the
      # submit signal on the main form. Keeping this around to keep in mind to
      # look for a better alternative.
      #$(@element).replaceWith($(@element).val("").clone(true))

    on_uploaded_image_load: (image) =>
      @original_width = image.width
      @original_height = image.height
      @resize_image(image)

    on_save: (evt) =>
      ### Signal triggered when the save button is pressed ###
      evt.preventDefault()
      image_data = @targetCanvas.toDataURL(@original_filetype)
      @jcrop_api.destroy()
      @controls_root.slideDown()
      @widgetContainer.empty()
      @build_image(image_data, @on_image_ready)

    on_image_ready: (image) =>
      @add_thumbnail(image)
      image_data = image.src
      if @options.scale_width and @options.scale_height
        image_data = @get_resized_image(image,
                                        @options.scale_width,
                                        @options.scale_height)
      else if @options.max_width or @options.max_height
        size = @get_max_size(image.width, image.height,
                             @options.max_width, @options.max_height)
        image_data = @get_resized_image(image, size.width, size.height)
      if @options.save_callback
        @options.save_callback(image_data)

    is_canvas_supported: () ->
      ### Returns true if the current browser supports canvas. ###
      canv = document.createElement('canvas')
      return !!(canv.getContext && canv.getContext('2d'))

    build_image: (image_data, callback) ->
      ### Returns an image HTML element containing image data
          The image may (and will probably will not) be fully loaded when the
          image returns.  Use the callback to get the fully instanciated image.
      ###
      image = document.createElement("img")
      image.src = image_data
      image.onload = () ->
        if callback
          callback(image)
      return image

    build_toolbar: () ->
      ### Return a toolbar jQuery element containing actions applyable to
          the JCrop widget.
      ###
      $toolbar = $("<div>").addClass("jcrop-fileinput-toolbar")
      $save_button = $("<button>#{@options.labels.save}</button>")
      $save_button.addClass("jcrop-fileinput-button")
      $save_button.on("click", @on_save)
      $toolbar.append($save_button)

    set_status_text: (filename, width, height) ->
      if not filename
        text = ''
      else
        text = "#{filename} (#{width}x#{height}px)"
      status_bar = @controls_root.find('.jcrop-fileinput-status')
      status_bar.text(text)

    get_resized_image: (image, width, height) ->
      canvas_width = width
      canvas_height = height
      canvas = document.createElement("canvas")
      canvas.width = canvas_width
      canvas.height = canvas_height
      ctx = canvas.getContext("2d")
      ctx.drawImage(image, 0, 0, width, height)
      canvas.toDataURL(@original_filetype)

    resize_image: (image) ->
      size = @get_max_size(image.width, image.height,
                           @options.jcrop_width, @options.jcrop_height)
      canvas_image_data = @get_resized_image(image, size.width, size.height)
      @build_jcrop_widget(canvas_image_data)

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

    build_jcrop_widget: (data) ->
      ### Adds a fully configured JCrop widget to the widgetContainer ###
      @controls_root.slideUp()
      instance = this  # used to keep a reference to the JCrop API

      # Initial cleanup
      @widgetContainer.find('.jcrop-image').remove()
      @widgetContainer.find('.jcrop-fileinput-toolbar').remove()

      # Element creation
      $img = $("<img>")
      $img.prop("src", data)
      $img.addClass("jcrop-image")
      @widgetContainer.append($img)
      @widgetContainer.append(@build_toolbar())
      @widgetContainer.slideDown()
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
      if @original_width > @options.jcrop_width or @original_height > @options.jcrop_height
        if @original_width > @original_height
          factor = @original_width / @options.jcrop_width
        else
          factor = @original_height / @options.jcrop_height
      else
        factor = 1

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

do ($ = jQuery, window, document) ->

  pluginName = "JCropFileInput"
  defaults =
    ratio: undefined,
    jcrop_width: 640,
    jcrop_height: 480,
    scale_height: undefined,
    scale_width: undefined,
    min_width: undefined,
    min_height: undefined,
    max_height: 9999,
    max_width: 9999,
    save_callback: undefined,
    delete_callback: undefined,
    invalid_callback: undefined,
    show_crop_button: false,
    show_delete_button: false,
    debug: false,
    labels: {
      upload: 'Upload an image',
      change: 'Modify image',
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

      # Wrap file input in buttons container
      _buttons_wrap = document.createElement("div")
      _buttons_wrap.className = "jcrop-fileinput-actions"
      $(@element).wrap(_buttons_wrap)
      # Get a reference to the wrapping div as the wrap function makes a clone.
      @buttons = $(@element).parent()

      # Wrap file input in root element
      _controls_root = document.createElement("div")
      _controls_root.className = "jcrop-fileinput-wrapper"
      $(@buttons).wrap(_controls_root)
      @controls_root = $(@buttons).parent()

      # Wrap the file input inside a fake button, in order to style it nicely.
      $upload_label = $("<span></span>")
      $upload_label.addClass('jcrop-fileinput-upload-label')
      $upload_label.text(@options.labels.upload)
      $upload_button = $("<button></button>")
      $upload_button.addClass('jcrop-fileinput-fakebutton')
      $upload_button.addClass('jcrop-fileinput-button')
      $(@element).wrap($upload_button)
      $(@element).before($upload_label)

      # Initialize crop button
      $crop_button = $("<button>#{@options.labels.crop}</button>")
      $crop_button.addClass("jcrop-fileinput-button")
      $crop_button.addClass("jcrop-fileinput-crop-button")
      $crop_button.on('click', @on_crop_click)
      if not @options.show_crop_button
        $crop_button.hide()
      $(@buttons).prepend($crop_button)

      # Initialize delete button
      $delete_button = $("<button>#{@options.labels.delete}</button>")
      $delete_button.addClass("jcrop-fileinput-button")
      $delete_button.addClass("jcrop-fileinput-delete-button")
      $delete_button.on('click', @on_delete_click)
      if not @options.show_delete_button
        $delete_button.hide()
      $(@buttons).append($delete_button)

      # Initialize status bar
      $status = $("<div></div>")
      $status.addClass("jcrop-fileinput-status")
      @controls_root.prepend($status)

      # Handle initial value of widget
      if $(@element).attr('data-initial')
        initial_image_src = $(@element).attr('data-initial')
        @build_image(initial_image_src, @on_initial_ready)
        @set_image_uploaded(true)
      else
        @set_image_uploaded(false)

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
      thumb_size = @get_max_size(image.width, image.height, 50, 50)
      thumbnail = @get_resized_image(image, thumb_size.width, thumb_size.height)
      image_container = document.createElement('div')
      image_container.className = 'jcrop-fileinput-thumbnail'
      $image = $("<img>")
      $image.prop('src', thumbnail)
      $image.on('click', @on_crop_click)
      $image.wrap(image_container)
      $image_container = $image.parent()
      @controls_root.prepend($image_container)

    on_crop_click: (evt) =>
      evt.preventDefault()
      @build_jcrop_widget(@original_image)

    on_delete_click: (evt) =>
      evt.preventDefault()
      @set_image_uploaded(false)

      # Run callback
      if @options.delete_callback
        @options.delete_callback()

    on_fileinput_change: (evt) =>
      file = evt.target.files[0]
      if not file
        @debug("No file given")
      filename = file.name
      reader = new FileReader()
      reader.onloadend = () =>
        @controls_root.find('.jcrop-fileinput-delete-button').show()
        @controls_root.find('.jcrop-fileinput-upload-label').text(@options.labels.change)
        if @is_canvas_supported()
          @controls_root.find('.jcrop-fileinput-crop-button').show()
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
      @build_jcrop_widget(image)

    on_save: (evt) =>
      ### Signal triggered when the save button is pressed ###
      evt.preventDefault()
      image_data = @targetCanvas.toDataURL(@original_filetype)
      @jcrop_api.destroy()
      @controls_root.slideDown()
      @widgetContainer.empty()
      @build_image(image_data, @on_image_ready)

    on_image_ready: (image) =>
      ### Processes the cropped image ###
      @add_thumbnail(image)
      @set_image_uploaded(true)
      image_data = image.src
      if @options.scale_width and @options.scale_height
        # Scale image to scale size
        width = @options.scale_width
        height = @options.scale_height
      else if @options.max_width or @options.max_height
        # Resizing image to fit max size
        size = @get_max_size(image.width, image.height,
                             @options.max_width, @options.max_height)
        width = size.width
        height = size.height
      else
        width = image.width
        height = image.height
      image_data = @get_resized_image(image, width, height)
      if width < @options.min_width or height < @options.min_height
        @controls_root.addClass("jcrop-fileinput-invalid")
        if @options.invalid_callback
          @options.invalid_callback()
      else
        @controls_root.removeClass("jcrop-fileinput-invalid")

      if @options.save_callback
        @options.save_callback(image_data)

    is_canvas_supported: () ->
      ### Returns true if the current browser supports canvas. ###
      canv = document.createElement('canvas')
      return !!(canv.getContext && canv.getContext('2d'))

    set_image_uploaded: (has_image) ->
      ### Makes change to the UI depending of the presence of an image ###
      if has_image
        @controls_root.find('.jcrop-fileinput-upload-label').text(@options.labels.change)
        @controls_root.addClass('jcrop-fileinput-has-file')
      else
        # Delete preview
        @controls_root.removeClass('jcrop-fileinput-has-file')
        @controls_root.find('.jcrop-fileinput-thumbnail').remove()
        @controls_root.find('.jcrop-fileinput-delete-button').hide()
        @controls_root.find('.jcrop-fileinput-crop-button').hide()

        @controls_root.find('.jcrop-fileinput-upload-label').text(@options.labels.upload)
        @set_status_text(null)

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

    set_status_text: (filename_text, width, height) ->
      status_bar = @controls_root.find('.jcrop-fileinput-status')
      status_bar.empty()
      if not filename_text
        return
      filename = $("<span>").addClass('jcrop-fileinput-filename').text(filename_text)
      filename.prop('title', filename_text)
      size_text = "(#{width}x#{height}px)"
      size = $("<span>").addClass('jcrop-fileinput-size').text(size_text)
      status_bar.append(filename)
      status_bar.append(size)

    get_resized_image: (image, width, height) ->
      ### Resize an image to fixed size ###
      if not width or not height
        @debug("Missing image dimensions")
        return
      @debug("Resizing image to #{width}x#{height}")
      canvas_width = width
      canvas_height = height
      canvas = document.createElement("canvas")
      canvas.width = canvas_width
      canvas.height = canvas_height
      ctx = canvas.getContext("2d")
      ctx.drawImage(image, 0, 0, width, height)
      canvas.toDataURL(@original_filetype)

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

    build_jcrop_widget: (image) ->
      ### Adds a fully configured JCrop widget to the widgetContainer ###
      @debug("initalizing jcrop ")
      size = @get_max_size(image.width, image.height,
                           @options.jcrop_width, @options.jcrop_height)
      data = @get_resized_image(image, size.width, size.height)
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

    debug: (message) ->
      if @options['debug']
        console.log(message)

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

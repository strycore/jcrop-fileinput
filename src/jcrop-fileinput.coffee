do ($ = jQuery, window, document) ->

  pluginName = "JCropFileInput"
  defaults =
    ratio: undefined,
    jcropWidth: 640,
    jcropHeight: 480,
    scaleHeight: undefined,
    scaleWidth: undefined,
    minWidth: undefined,
    minHeight: undefined,
    maxHeight: 9999,
    maxWidth: 9999,
    thumbMaxWidth: 50,
    thumbMaxHeight: 50,
    saveCallback: undefined,
    deleteCallback: undefined,
    invalidCallback: undefined,
    showCropButton: false,
    showDeleteButton: false,
    debug: false,
    labels: {
      upload: "Upload an image",
      change: "Modify image",
      delete: "Delete image",
      crop: "Crop",
      save: "Save",
    }

  class JCropFileInput
    constructor: (@element, options) ->
      @options = $.extend({}, defaults, options)
      @defaults = defaults
      @name = pluginName
      @init()

    init: ->
      if window.Blob
        @blob = new Blob()
      else
        @blob = null

      # Attach the plugin instance to the element
      @element.JCropFileInput = @

      # Connect file input to signal
      $(@element).on("change", @onFileinputChange)

      # Override form submit if no callback has been provided
      if not @options.saveCallback
        @overrideFormSubmit()

      # Wrap file input in buttons container
      buttonsWrap = document.createElement("div")
      buttonsWrap.className = "jcrop-fileinput-actions"
      $(@element).wrap(buttonsWrap)
      # Get a reference to the wrapping div as the wrap function makes a clone.
      @buttons = $(@element).parent()

      # Wrap file input in root element
      controlsRootWrap = document.createElement("div")
      controlsRootWrap.className = "jcrop-fileinput-wrapper"
      $(@buttons).wrap(controlsRootWrap)
      @controlsRoot = $(@buttons).parent()

      # Wrap the file input inside a fake button, in order to style it nicely.
      $uploadLabel = $("<span></span>")
      $uploadLabel.addClass("jcrop-fileinput-upload-label")
      $uploadLabel.text(@options.labels.upload)
      $uploadButton = $("<span></span>")
      $uploadButton.addClass("jcrop-fileinput-fakebutton")
      $uploadButton.addClass("jcrop-fileinput-button")
      $(@element).wrap($uploadButton)
      $(@element).before($uploadLabel)

      # Initialize crop button
      $cropButton = $("<button>#{@options.labels.crop}</button>")
      $cropButton.addClass("jcrop-fileinput-button")
      $cropButton.addClass("jcrop-fileinput-crop-button")
      $cropButton.on("click", @onCropClick)
      if not @options.showCropButton
        $cropButton.hide()
      $(@buttons).prepend($cropButton)

      # Initialize delete button
      $deleteButton = $("<button>#{@options.labels.delete}</button>")
      $deleteButton.addClass("jcrop-fileinput-button")
      $deleteButton.addClass("jcrop-fileinput-delete-button")
      $deleteButton.on("click", @onDeleteClick)
      if not @options.showDeleteButton
        $deleteButton.hide()
      $(@buttons).append($deleteButton)

      # Initialize status bar
      $status = $("<div></div>")
      $status.addClass("jcrop-fileinput-status")
      @controlsRoot.prepend($status)

      # Handle initial value of widget
      if $(@element).attr("data-initial")
        initialImageSrc = $(@element).attr("data-initial")
        @buildImage(initialImageSrc, @onInitialReady)
        @setImageUploaded(true)
      else
        @setImageUploaded(false)

      # Build the container for JCrop
      @widgetContainer = $("<div>")
      @widgetContainer.addClass("jcrop-fileinput-container")
      @controlsRoot.after(@widgetContainer)

      # Instanciate the canvas containing the resized image
      @targetCanvas = document.createElement("canvas")

    onInitialReady: (image) =>
      ### Fires when image in initial value of the input field is read ###
      @originalImage = image
      @originalWidth = image.width
      @originalHeight = image.height
      @targetCanvas.width = image.width
      @targetCanvas.height = image.height

      @setStatusText(image.src, image.width, image.height)
      @addThumbnail(image)

    addThumbnail: (image) ->
      ### Adds the HTML img tag "image" to the controls, binds click event ###
      @controlsRoot.find(".jcrop-fileinput-thumbnail").remove()
      thumbSize = @getMaxSize(
        image.width, image.height,
        @options.thumbMaxWidth, @options.thumbMaxHeight
      )
      thumbnail = @getResizedImage(image, thumbSize.width, thumbSize.height)
      imageContainer = document.createElement("div")
      imageContainer.className = "jcrop-fileinput-thumbnail"
      $image = $("<img>")
      $image.prop("src", thumbnail)
      $image.on("click", @onCropClick)
      $image.wrap(imageContainer)
      $imageContainer = $image.parent()
      @controlsRoot.prepend($imageContainer)

    onCropClick: (evt) =>
      evt.preventDefault()
      @buildJcropWidget(@originalImage)

    onDeleteClick: (evt) =>
      evt.preventDefault()
      @setImageUploaded(false)

      # Run callback
      if @options.deleteCallback
        @options.deleteCallback()

    onFileinputChange: (evt) =>
      file = evt.target.files[0]
      if not file
        @debug("No file given")
      filename = file.name
      reader = new FileReader()
      reader.onloadend = () =>
        @controlsRoot.find(".jcrop-fileinput-delete-button").show()
        @controlsRoot.find(
          ".jcrop-fileinput-upload-label"
        ).text(@options.labels.change)
        if @isCanvasSupported()
          @controlsRoot.find(".jcrop-fileinput-crop-button").show()
          @originalFiletype = file.type
          @originalImage = @buildImage(reader.result, @onUploadedImageLoad)
          @setStatusText(filename,
                           @originalImage.width, @originalImage.height)
        # Fallback when canvas not available: call callback with original image
        else if @options.saveCallback
          @options.saveCallback(reader.result)

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

    onUploadedImageLoad: (image) =>
      @originalWidth = image.width
      @originalHeight = image.height
      @buildJcropWidget(image)

    onSave: (evt) =>
      ### Signal triggered when the save button is pressed ###
      evt.preventDefault()
      imageData = @targetCanvas.toDataURL(@originalFiletype)
      @jcropApi.destroy()
      @controlsRoot.slideDown()
      @widgetContainer.empty()
      @buildImage(imageData, @onImageReady)

    onImageReady: (image) =>
      ### Processes the cropped image ###
      @addThumbnail(image)
      @setImageUploaded(true)
      imageData = image.src
      if @options.scaleWidth and @options.scaleHeight
        # Scale image to scale size
        width = @options.scaleWidth
        height = @options.scaleHeight
        @debug("Scale image to #{width}x#{height}")
      else if @options.maxWidth or @options.maxHeight
        # Resizing image to fit max size
        size = @getMaxSize(image.width, image.height, @options.maxWidth, @options.maxHeight)
        width = size.width
        height = size.height
        @debug("Resized image to #{width}x#{height}")
      else
        width = image.width
        height = image.height
      imageData = @getResizedImage(image, width, height)
      if width < @options.minWidth or height < @options.minHeight
        @controlsRoot.addClass("jcrop-fileinput-invalid")
        if @options.invalidCallback
          @options.invalidCallback(width, height)
      else
        @controlsRoot.removeClass("jcrop-fileinput-invalid")

      @targetCanvas.toBlob(@setBlob)
      if @options.saveCallback
        @options.saveCallback(imageData)

    isCanvasSupported: () ->
      ### Returns true if the current browser supports canvas. ###
      canv = document.createElement("canvas")
      return !!(canv.getContext && canv.getContext("2d"))

    setImageUploaded: (hasImage) ->
      ### Makes change to the UI depending of the presence of an image ###
      if hasImage
        @controlsRoot.find(
          ".jcrop-fileinput-upload-label"
        ).text(@options.labels.change)
        @controlsRoot.addClass("jcrop-fileinput-has-file")
      else
        # Delete preview
        @controlsRoot.removeClass("jcrop-fileinput-has-file")
        @controlsRoot.find(".jcrop-fileinput-thumbnail").remove()
        @controlsRoot.find(".jcrop-fileinput-delete-button").hide()
        @controlsRoot.find(".jcrop-fileinput-crop-button").hide()

        @controlsRoot.find(
          ".jcrop-fileinput-upload-label"
        ).text(@options.labels.upload)
        @setStatusText(null)

    buildImage: (imageData, callback) ->
      ### Returns an image HTML element containing image data
          The image may (and will probably will not) be fully loaded when the
          image returns.  Use the callback to get the fully instanciated image.
      ###
      image = document.createElement("img")
      image.src = imageData
      image.onload = () ->
        if callback
          callback(image)
      return image

    setBlob: (blob) =>
      @blob = blob
      #console.log("Set blob to ", blob)

    buildToolbar: () ->
      ### Return a toolbar jQuery element containing actions applyable to
          the JCrop widget.
      ###
      $toolbar = $("<div>").addClass("jcrop-fileinput-toolbar")
      $saveButton = $("<button>#{@options.labels.save}</button>")
      $saveButton.addClass("jcrop-fileinput-button")
      $saveButton.on("click", @onSave)
      $toolbar.append($saveButton)

    setStatusText: (filenameText, width, height) ->
      statusBar = @controlsRoot.find(".jcrop-fileinput-status")
      statusBar.empty()
      if not filenameText
        return
      filenameParts = filenameText.split("/")
      filenameText = filenameParts[filenameParts.length - 1]
      className = "jcrop-fileinput-filename"
      filename = $("<span>").addClass(className).text(filenameText)
      filename.prop("title", filenameText)
      sizeText = "(#{width} x #{height} px)"
      size = $("<span>").addClass("jcrop-fileinput-size").text(sizeText)
      statusBar.append(filename)
      statusBar.append(size)

    getResizedImage: (image, width, height) ->
      ### Resize an image to fixed size ###
      if not width or not height
        @debug("Missing image dimensions")
        return
      @debug("Resizing image to #{width}x#{height}")
      canvasWidth = width
      canvasHeight = height
      canvas = document.createElement("canvas")
      canvas.width = canvasWidth
      canvas.height = canvasHeight
      ctx = canvas.getContext("2d")
      ctx.drawImage(image, 0, 0, width, height)
      canvas.toDataURL(@originalFiletype)

    getMaxSize: (width, height, maxWidth, maxHeight) ->
      newWidth = width
      newHeight = height

      if width > height
        if width > maxWidth
          newHeight *= maxWidth / width
          newWidth = maxWidth
      else
        if height > maxHeight
          newWidth *= maxHeight / height
          newHeight = maxHeight
      return {width: newWidth, height: newHeight}

    buildJcropWidget: (image) ->
      ### Adds a fully configured JCrop widget to the widgetContainer ###
      @debug("initalizing jcrop ")
      size = @getMaxSize(image.width, image.height,
                           @options.jcropWidth, @options.jcropHeight)
      data = @getResizedImage(image, size.width, size.height)
      @controlsRoot.slideUp()
      instance = this  # used to keep a reference to the JCrop API

      # Initial cleanup
      @widgetContainer.find(".jcrop-image").remove()
      @widgetContainer.find(".jcrop-fileinput-toolbar").remove()

      # Element creation
      $img = $("<img>")
      $img.prop("src", data)
      $img.addClass("jcrop-image")
      @widgetContainer.append($img)
      @widgetContainer.append(@buildToolbar())
      @widgetContainer.slideDown()
      $img.Jcrop(
        {
          onChange: @onJcropSelect,
          onSelect: @onJcropSelect,
          aspectRatio: @options.ratio,
          bgColor: "white",
          bgOpacity: 0.5,
        }, () ->
          api = this
          api.setSelect([0,0,$img.width(), $img.height()])
          instance.jcropApi = api
      )

    onJcropSelect: (coords) =>
      @cropOriginalImage(coords)

    cropOriginalImage: (coords) ->
      if not coords
        return
      isWider = @originalWidth > @options.jcropWidth
      isHigher = @originalHeight > @options.jcropHeight
      if isWider or isHigher
        if @originalWidth > @originalHeight
          factor = @originalWidth / @options.jcropWidth
        else
          factor = @originalHeight / @options.jcropHeight
      else
        factor = 1

      canvas = @targetCanvas
      originX = Math.max(coords.x * factor, 0)
      originY = Math.max(coords.y * factor, 0)
      canvasWidth = parseInt(coords.w * factor)
      canvasHeight = parseInt(coords.h * factor)
      canvas.width = canvasWidth
      canvas.height = canvasHeight
      ctx = canvas.getContext("2d")
      ctx.drawImage(
        @originalImage,
        originX, originY, canvasWidth, canvasHeight,
        0, 0, canvasWidth, canvasHeight
      )

    overrideFormSubmit: () ->
      form = $(@element).closest("form").get(0)
      if not form
        return
      $(form).on "submit", (evt) =>
        evt.preventDefault()
        formData = new FormData()
        for i in [0..form.length]
          field = form[i]
          if not field
            continue
          fieldName = field.name
          if not fieldName
            continue

          jcropInstance = field.JCropFileInput
          if not jcropInstance
            value = field.value
            formData.append(fieldName, value)

        formData.append(@element.name, @blob, "image.png")
        request = new XMLHttpRequest()
        actionUrl = form.action or "."
        request.open("POST", actionUrl)
        request.send(formData)
        request.onload = () ->
          # Not the ideal way, but currently the only way
          document.open()
          document.write(request.responseText)
          document.close()

    debug: (message) ->
      if @options.debug
        console.log(message)

    setOptions: (options) ->
      @options = $.extend({}, @options, options)
      @setRatio(@options.ratio)

    setRatio: (ratioValue) ->
      if not @jcropApi
        return
      @jcropApi.setOptions({aspectRatio: ratioValue})

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(@, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new JCropFileInput(@, options))
      else
        instance = $.data(@, "plugin_#{pluginName}")
        instance.setOptions(options)

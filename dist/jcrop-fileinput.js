(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var JCropFileInput, defaults, pluginName;
    pluginName = "JCropFileInput";
    defaults = {
      ratio: void 0,
      jcropWidth: 640,
      jcropHeight: 480,
      scaleHeight: void 0,
      scaleWidth: void 0,
      minWidth: void 0,
      minHeight: void 0,
      maxHeight: 9999,
      maxWidth: 9999,
      thumbMaxWidth: 50,
      thumbMaxHeight: 50,
      saveCallback: void 0,
      onSubmit: function() {},
      deleteCallback: void 0,
      invalidCallback: void 0,
      showCropButton: false,
      showDeleteButton: false,
      debug: false,
      labels: {
        upload: "Upload an image",
        change: "Modify image",
        "delete": "Delete image",
        crop: "Crop",
        save: "Save"
      }
    };
    JCropFileInput = (function() {
      function JCropFileInput(element, options) {
        this.element = element;
        this.onJcropSelect = bind(this.onJcropSelect, this);
        this.setBlob = bind(this.setBlob, this);
        this.onImageReady = bind(this.onImageReady, this);
        this.onSave = bind(this.onSave, this);
        this.onUploadedImageLoad = bind(this.onUploadedImageLoad, this);
        this.onFileinputChange = bind(this.onFileinputChange, this);
        this.onDeleteClick = bind(this.onDeleteClick, this);
        this.onCropClick = bind(this.onCropClick, this);
        this.onInitialReady = bind(this.onInitialReady, this);
        this.options = $.extend({}, defaults, options);
        this.defaults = defaults;
        this.name = pluginName;
        this.init();
      }

      JCropFileInput.prototype.init = function() {
        var $cropButton, $deleteButton, $status, $uploadButton, $uploadLabel, buttonsWrap, controlsRootWrap, initialImageSrc;
        if (window.Blob) {
          this.blob = new Blob();
        } else {
          this.blob = null;
        }
        this.element.JCropFileInput = this;
        $(this.element).on("change", this.onFileinputChange);
        if (!this.options.saveCallback) {
          this.overrideFormSubmit();
        }
        buttonsWrap = document.createElement("div");
        buttonsWrap.className = "jcrop-fileinput-actions";
        $(this.element).wrap(buttonsWrap);
        this.buttons = $(this.element).parent();
        controlsRootWrap = document.createElement("div");
        controlsRootWrap.className = "jcrop-fileinput-wrapper";
        $(this.buttons).wrap(controlsRootWrap);
        this.controlsRoot = $(this.buttons).parent();
        $uploadLabel = $("<span></span>");
        $uploadLabel.addClass("jcrop-fileinput-upload-label");
        $uploadLabel.text(this.options.labels.upload);
        $uploadButton = $("<span></span>");
        $uploadButton.addClass("jcrop-fileinput-fakebutton");
        $uploadButton.addClass("jcrop-fileinput-button");
        $(this.element).wrap($uploadButton);
        $(this.element).before($uploadLabel);
        $cropButton = $("<button>" + this.options.labels.crop + "</button>");
        $cropButton.addClass("jcrop-fileinput-button");
        $cropButton.addClass("jcrop-fileinput-crop-button");
        $cropButton.on("click", this.onCropClick);
        if (!this.options.showCropButton) {
          $cropButton.hide();
        }
        $(this.buttons).prepend($cropButton);
        $deleteButton = $("<button>" + this.options.labels["delete"] + "</button>");
        $deleteButton.addClass("jcrop-fileinput-button");
        $deleteButton.addClass("jcrop-fileinput-delete-button");
        $deleteButton.on("click", this.onDeleteClick);
        if (!this.options.showDeleteButton) {
          $deleteButton.hide();
        }
        $(this.buttons).append($deleteButton);
        $status = $("<div></div>");
        $status.addClass("jcrop-fileinput-status");
        this.controlsRoot.prepend($status);
        if ($(this.element).attr("data-initial")) {
          initialImageSrc = $(this.element).attr("data-initial");
          this.buildImage(initialImageSrc, this.onInitialReady);
          this.setImageUploaded(true);
        } else {
          this.setImageUploaded(false);
        }
        this.widgetContainer = $("<div>");
        this.widgetContainer.addClass("jcrop-fileinput-container");
        this.controlsRoot.after(this.widgetContainer);
        return this.targetCanvas = document.createElement("canvas");
      };

      JCropFileInput.prototype.onInitialReady = function(image) {

        /* Fires when image in initial value of the input field is read */
        this.originalImage = image;
        this.originalWidth = image.width;
        this.originalHeight = image.height;
        this.targetCanvas.width = image.width;
        this.targetCanvas.height = image.height;
        this.setStatusText(image.src, image.width, image.height);
        return this.addThumbnail(image);
      };

      JCropFileInput.prototype.addThumbnail = function(image) {

        /* Adds the HTML img tag "image" to the controls, binds click event */
        var $image, $imageContainer, imageContainer, thumbSize, thumbnail;
        this.controlsRoot.find(".jcrop-fileinput-thumbnail").remove();
        thumbSize = this.getMaxSize(image.width, image.height, this.options.thumbMaxWidth, this.options.thumbMaxHeight);
        thumbnail = this.getResizedImage(image, thumbSize.width, thumbSize.height);
        imageContainer = document.createElement("div");
        imageContainer.className = "jcrop-fileinput-thumbnail";
        $image = $("<img>");
        $image.prop("src", thumbnail);
        $image.on("click", this.onCropClick);
        $image.wrap(imageContainer);
        $imageContainer = $image.parent();
        return this.controlsRoot.prepend($imageContainer);
      };

      JCropFileInput.prototype.onCropClick = function(evt) {
        evt.preventDefault();
        return this.buildJcropWidget(this.originalImage);
      };

      JCropFileInput.prototype.onDeleteClick = function(evt) {
        evt.preventDefault();
        this.setImageUploaded(false);
        if (this.options.deleteCallback) {
          return this.options.deleteCallback();
        }
      };

      JCropFileInput.prototype.onFileinputChange = function(evt) {
        var file, filename, reader;
        file = evt.target.files[0];
        if (!file) {
          this.debug("No file given");
        }
        filename = file.name;
        reader = new FileReader();
        reader.onloadend = (function(_this) {
          return function() {
            _this.controlsRoot.find(".jcrop-fileinput-delete-button").show();
            _this.controlsRoot.find(".jcrop-fileinput-upload-label").text(_this.options.labels.change);
            if (_this.isCanvasSupported()) {
              _this.controlsRoot.find(".jcrop-fileinput-crop-button").show();
              _this.originalFiletype = file.type;
              _this.originalImage = _this.buildImage(reader.result, _this.onUploadedImageLoad);
              return _this.setStatusText(filename, _this.originalImage.width, _this.originalImage.height);
            } else if (_this.options.saveCallback) {
              return _this.options.saveCallback(reader.result);
            }
          };
        })(this);
        return reader.readAsDataURL(file);
      };

      JCropFileInput.prototype.onUploadedImageLoad = function(image) {
        this.originalWidth = image.width;
        this.originalHeight = image.height;
        return this.buildJcropWidget(image);
      };

      JCropFileInput.prototype.onSave = function(evt) {

        /* Signal triggered when the save button is pressed */
        var imageData;
        evt.preventDefault();
        imageData = this.targetCanvas.toDataURL(this.originalFiletype);
        this.jcropApi.destroy();
        this.controlsRoot.slideDown();
        this.widgetContainer.empty();
        return this.buildImage(imageData, this.onImageReady);
      };

      JCropFileInput.prototype.onImageReady = function(image) {

        /* Processes the cropped image */
        var height, imageData, size, width;
        this.addThumbnail(image);
        this.setImageUploaded(true);
        imageData = image.src;
        if (this.options.scaleWidth && this.options.scaleHeight) {
          width = this.options.scaleWidth;
          height = this.options.scaleHeight;
          this.debug("Scale image to " + width + "x" + height);
        } else if (this.options.maxWidth || this.options.maxHeight) {
          size = this.getMaxSize(image.width, image.height, this.options.maxWidth, this.options.maxHeight);
          width = size.width;
          height = size.height;
          this.debug("Resized image to " + width + "x" + height);
        } else {
          width = image.width;
          height = image.height;
        }
        imageData = this.getResizedImage(image, width, height);
        if (width < this.options.minWidth || height < this.options.minHeight) {
          this.controlsRoot.addClass("jcrop-fileinput-invalid");
          if (this.options.invalidCallback) {
            this.options.invalidCallback(width, height);
          }
        } else {
          this.controlsRoot.removeClass("jcrop-fileinput-invalid");
        }
        this.targetCanvas.toBlob(this.setBlob);
        if (this.options.saveCallback) {
          return this.options.saveCallback(imageData);
        }
      };

      JCropFileInput.prototype.isCanvasSupported = function() {

        /* Returns true if the current browser supports canvas. */
        var canv;
        canv = document.createElement("canvas");
        return !!(canv.getContext && canv.getContext("2d"));
      };

      JCropFileInput.prototype.setImageUploaded = function(hasImage) {

        /* Makes change to the UI depending of the presence of an image */
        if (hasImage) {
          this.controlsRoot.find(".jcrop-fileinput-upload-label").text(this.options.labels.change);
          return this.controlsRoot.addClass("jcrop-fileinput-has-file");
        } else {
          this.controlsRoot.removeClass("jcrop-fileinput-has-file");
          this.controlsRoot.find(".jcrop-fileinput-thumbnail").remove();
          this.controlsRoot.find(".jcrop-fileinput-delete-button").hide();
          this.controlsRoot.find(".jcrop-fileinput-crop-button").hide();
          this.controlsRoot.find(".jcrop-fileinput-upload-label").text(this.options.labels.upload);
          return this.setStatusText(null);
        }
      };

      JCropFileInput.prototype.buildImage = function(imageData, callback) {

        /* Returns an image HTML element containing image data
            The image may (and will probably will not) be fully loaded when the
            image returns.  Use the callback to get the fully instanciated image.
         */
        var image;
        image = document.createElement("img");
        image.src = imageData;
        image.onload = function() {
          if (callback) {
            return callback(image);
          }
        };
        return image;
      };

      JCropFileInput.prototype.setBlob = function(blob) {
        return this.blob = blob;
      };

      JCropFileInput.prototype.buildToolbar = function() {

        /* Return a toolbar jQuery element containing actions applyable to
            the JCrop widget.
         */
        var $saveButton, $toolbar;
        $toolbar = $("<div>").addClass("jcrop-fileinput-toolbar");
        $saveButton = $("<button>" + this.options.labels.save + "</button>");
        $saveButton.addClass("jcrop-fileinput-button");
        $saveButton.on("click", this.onSave);
        return $toolbar.append($saveButton);
      };

      JCropFileInput.prototype.setStatusText = function(filenameText, width, height) {
        var className, filename, filenameParts, size, sizeText, statusBar;
        statusBar = this.controlsRoot.find(".jcrop-fileinput-status");
        statusBar.empty();
        if (!filenameText) {
          return;
        }
        filenameParts = filenameText.split("/");
        filenameText = filenameParts[filenameParts.length - 1];
        className = "jcrop-fileinput-filename";
        filename = $("<span>").addClass(className).text(filenameText);
        filename.prop("title", filenameText);
        sizeText = "(" + width + " x " + height + " px)";
        size = $("<span>").addClass("jcrop-fileinput-size").text(sizeText);
        statusBar.append(filename);
        return statusBar.append(size);
      };

      JCropFileInput.prototype.getResizedImage = function(image, width, height) {

        /* Resize an image to fixed size */
        var canvas, canvasHeight, canvasWidth, ctx;
        if (!width || !height) {
          this.debug("Missing image dimensions");
          return;
        }
        this.debug("Resizing image to " + width + "x" + height);
        canvasWidth = width;
        canvasHeight = height;
        canvas = document.createElement("canvas");
        canvas.width = canvasWidth;
        canvas.height = canvasHeight;
        ctx = canvas.getContext("2d");
        ctx.drawImage(image, 0, 0, width, height);
        return canvas.toDataURL(this.originalFiletype);
      };

      JCropFileInput.prototype.getMaxSize = function(width, height, maxWidth, maxHeight) {
        var newHeight, newWidth;
        newWidth = width;
        newHeight = height;
        if (width > height) {
          if (width > maxWidth) {
            newHeight *= maxWidth / width;
            newWidth = maxWidth;
          }
        } else {
          if (height > maxHeight) {
            newWidth *= maxHeight / height;
            newHeight = maxHeight;
          }
        }
        return {
          width: newWidth,
          height: newHeight
        };
      };

      JCropFileInput.prototype.buildJcropWidget = function(image) {

        /* Adds a fully configured JCrop widget to the widgetContainer */
        var $img, data, instance, size;
        this.debug("initalizing jcrop ");
        size = this.getMaxSize(image.width, image.height, this.options.jcropWidth, this.options.jcropHeight);
        data = this.getResizedImage(image, size.width, size.height);
        this.controlsRoot.slideUp();
        instance = this;
        this.widgetContainer.find(".jcrop-image").remove();
        this.widgetContainer.find(".jcrop-fileinput-toolbar").remove();
        $img = $("<img>");
        $img.prop("src", data);
        $img.addClass("jcrop-image");
        this.widgetContainer.append($img);
        this.widgetContainer.append(this.buildToolbar());
        this.widgetContainer.slideDown();
        return $img.Jcrop({
          onChange: this.onJcropSelect,
          onSelect: this.onJcropSelect,
          aspectRatio: this.options.ratio,
          bgColor: "white",
          bgOpacity: 0.5
        }, function() {
          var api;
          api = this;
          api.setSelect([0, 0, $img.width(), $img.height()]);
          return instance.jcropApi = api;
        });
      };

      JCropFileInput.prototype.onJcropSelect = function(coords) {
        return this.cropOriginalImage(coords);
      };

      JCropFileInput.prototype.cropOriginalImage = function(coords) {
        var canvas, canvasHeight, canvasWidth, ctx, factor, isHigher, isWider, originX, originY;
        if (!coords) {
          return;
        }
        isWider = this.originalWidth > this.options.jcropWidth;
        isHigher = this.originalHeight > this.options.jcropHeight;
        if (isWider || isHigher) {
          if (this.originalWidth > this.originalHeight) {
            factor = this.originalWidth / this.options.jcropWidth;
          } else {
            factor = this.originalHeight / this.options.jcropHeight;
          }
        } else {
          factor = 1;
        }
        canvas = this.targetCanvas;
        originX = Math.max(coords.x * factor, 0);
        originY = Math.max(coords.y * factor, 0);
        canvasWidth = parseInt(coords.w * factor);
        canvasHeight = parseInt(coords.h * factor);
        canvas.width = canvasWidth;
        canvas.height = canvasHeight;
        ctx = canvas.getContext("2d");
        ctx.drawImage(this.originalImage, originX, originY, canvasWidth, canvasHeight, 0, 0, canvasWidth, canvasHeight);
        return console.log('humm...');
      };

      JCropFileInput.prototype.overrideFormSubmit = function() {
        var form;
        console.log('!!!!');
        return;
        form = $(this.element).closest("form").get(0);
        if (!form) {
          return;
        }
        return $(form).on("submit", (function(_this) {
          return function(evt) {
            var actionUrl, field, formData, i, j, ref, request;
            evt.preventDefault();
            formData = new FormData(form);
            for (i = j = 0, ref = form.length; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
              field = form[i];
              if (!field || !field.name) {
                continue;
              }
              if (field.name === _this.element.name) {
                formData.append(_this.element.name, _this.blob, "image.png");
              }
            }
            request = new XMLHttpRequest();
            actionUrl = form.action || ".";
            request.open("POST", actionUrl);
            request.send(formData);
            return request.onload = function(event) {
              return _this.options.onSubmit(event);
            };
          };
        })(this));
      };

      JCropFileInput.prototype.debug = function(message) {
        if (this.options.debug) {
          return console.log(message);
        }
      };

      JCropFileInput.prototype.setOptions = function(options) {
        this.options = $.extend({}, this.options, options);
        return this.setRatio(this.options.ratio);
      };

      JCropFileInput.prototype.setRatio = function(ratioValue) {
        if (!this.jcropApi) {
          return;
        }
        return this.jcropApi.setOptions({
          aspectRatio: ratioValue
        });
      };

      return JCropFileInput;

    })();
    return $.fn[pluginName] = function(options) {
      return this.each(function() {
        var instance;
        if (!$.data(this, "plugin_" + pluginName)) {
          return $.data(this, "plugin_" + pluginName, new JCropFileInput(this, options));
        } else {
          instance = $.data(this, "plugin_" + pluginName);
          return instance.setOptions(options);
        }
      });
    };
  })(jQuery, window, document);

}).call(this);

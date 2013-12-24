(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var JCropFileInput, defaults, pluginName;
    pluginName = "JCropFileInput";
    defaults = {
      ratio: void 0,
      jcrop_width: 640,
      jcrop_height: 480,
      scale_height: void 0,
      scale_width: void 0,
      min_width: void 0,
      min_height: void 0,
      max_height: 9999,
      max_width: 9999,
      save_callback: void 0,
      delete_callback: void 0,
      invalid_callback: void 0,
      show_crop_button: false,
      show_delete_button: false,
      debug: false,
      labels: {
        upload: 'Upload an image',
        change: 'Modify image',
        "delete": 'Delete image',
        crop: 'Crop',
        save: 'Save'
      }
    };
    JCropFileInput = (function() {
      function JCropFileInput(element, options) {
        this.element = element;
        this.on_jcrop_select = __bind(this.on_jcrop_select, this);
        this.set_blob = __bind(this.set_blob, this);
        this.on_image_ready = __bind(this.on_image_ready, this);
        this.on_save = __bind(this.on_save, this);
        this.on_uploaded_image_load = __bind(this.on_uploaded_image_load, this);
        this.on_fileinput_change = __bind(this.on_fileinput_change, this);
        this.on_delete_click = __bind(this.on_delete_click, this);
        this.on_crop_click = __bind(this.on_crop_click, this);
        this.on_initial_ready = __bind(this.on_initial_ready, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.init();
      }

      JCropFileInput.prototype.init = function() {
        var $crop_button, $delete_button, $status, $upload_button, $upload_label, initial_image_src, _buttons_wrap, _controls_root;
        this.blob = new Blob();
        this.element.JCropFileInput = this;
        $(this.element).on("change", this.on_fileinput_change);
        if (!this.options.save_callback) {
          this.override_form_submit();
        }
        _buttons_wrap = document.createElement("div");
        _buttons_wrap.className = "jcrop-fileinput-actions";
        $(this.element).wrap(_buttons_wrap);
        this.buttons = $(this.element).parent();
        _controls_root = document.createElement("div");
        _controls_root.className = "jcrop-fileinput-wrapper";
        $(this.buttons).wrap(_controls_root);
        this.controls_root = $(this.buttons).parent();
        $upload_label = $("<span></span>");
        $upload_label.addClass('jcrop-fileinput-upload-label');
        $upload_label.text(this.options.labels.upload);
        $upload_button = $("<span></span>");
        $upload_button.addClass('jcrop-fileinput-fakebutton');
        $upload_button.addClass('jcrop-fileinput-button');
        $(this.element).wrap($upload_button);
        $(this.element).before($upload_label);
        $crop_button = $("<button>" + this.options.labels.crop + "</button>");
        $crop_button.addClass("jcrop-fileinput-button");
        $crop_button.addClass("jcrop-fileinput-crop-button");
        $crop_button.on('click', this.on_crop_click);
        if (!this.options.show_crop_button) {
          $crop_button.hide();
        }
        $(this.buttons).prepend($crop_button);
        $delete_button = $("<button>" + this.options.labels["delete"] + "</button>");
        $delete_button.addClass("jcrop-fileinput-button");
        $delete_button.addClass("jcrop-fileinput-delete-button");
        $delete_button.on('click', this.on_delete_click);
        if (!this.options.show_delete_button) {
          $delete_button.hide();
        }
        $(this.buttons).append($delete_button);
        $status = $("<div></div>");
        $status.addClass("jcrop-fileinput-status");
        this.controls_root.prepend($status);
        if ($(this.element).attr('data-initial')) {
          initial_image_src = $(this.element).attr('data-initial');
          this.build_image(initial_image_src, this.on_initial_ready);
          this.set_image_uploaded(true);
        } else {
          this.set_image_uploaded(false);
        }
        this.widgetContainer = $("<div>");
        this.widgetContainer.addClass("jcrop-fileinput-container");
        this.controls_root.after(this.widgetContainer);
        return this.targetCanvas = document.createElement("canvas");
      };

      JCropFileInput.prototype.on_initial_ready = function(image) {
        /* Fires when image in initial value of the input field is read*/

        this.original_image = image;
        this.original_width = image.width;
        this.original_height = image.height;
        this.targetCanvas.width = image.width;
        this.targetCanvas.height = image.height;
        this.set_status_text(image.src, image.width, image.height);
        return this.add_thumbnail(image);
      };

      JCropFileInput.prototype.add_thumbnail = function(image) {
        /* Adds the HTML img tag 'image' to the controls, binds click event*/

        var $image, $image_container, image_container, thumb_size, thumbnail;
        this.controls_root.find('.jcrop-fileinput-thumbnail').remove();
        thumb_size = this.get_max_size(image.width, image.height, 50, 50);
        thumbnail = this.get_resized_image(image, thumb_size.width, thumb_size.height);
        image_container = document.createElement('div');
        image_container.className = 'jcrop-fileinput-thumbnail';
        $image = $("<img>");
        $image.prop('src', thumbnail);
        $image.on('click', this.on_crop_click);
        $image.wrap(image_container);
        $image_container = $image.parent();
        return this.controls_root.prepend($image_container);
      };

      JCropFileInput.prototype.on_crop_click = function(evt) {
        evt.preventDefault();
        return this.build_jcrop_widget(this.original_image);
      };

      JCropFileInput.prototype.on_delete_click = function(evt) {
        evt.preventDefault();
        this.set_image_uploaded(false);
        if (this.options.delete_callback) {
          return this.options.delete_callback();
        }
      };

      JCropFileInput.prototype.on_fileinput_change = function(evt) {
        var file, filename, reader,
          _this = this;
        file = evt.target.files[0];
        if (!file) {
          this.debug("No file given");
        }
        filename = file.name;
        reader = new FileReader();
        reader.onloadend = function() {
          _this.controls_root.find('.jcrop-fileinput-delete-button').show();
          _this.controls_root.find('.jcrop-fileinput-upload-label').text(_this.options.labels.change);
          if (_this.is_canvas_supported()) {
            _this.controls_root.find('.jcrop-fileinput-crop-button').show();
            _this.original_filetype = file.type;
            _this.original_image = _this.build_image(reader.result, _this.on_uploaded_image_load);
            return _this.set_status_text(filename, _this.original_image.width, _this.original_image.height);
          } else if (_this.options.save_callback) {
            return _this.options.save_callback(reader.result);
          }
        };
        return reader.readAsDataURL(file);
      };

      JCropFileInput.prototype.on_uploaded_image_load = function(image) {
        this.original_width = image.width;
        this.original_height = image.height;
        return this.build_jcrop_widget(image);
      };

      JCropFileInput.prototype.on_save = function(evt) {
        /* Signal triggered when the save button is pressed*/

        var image_data;
        evt.preventDefault();
        image_data = this.targetCanvas.toDataURL(this.original_filetype);
        this.jcrop_api.destroy();
        this.controls_root.slideDown();
        this.widgetContainer.empty();
        return this.build_image(image_data, this.on_image_ready);
      };

      JCropFileInput.prototype.on_image_ready = function(image) {
        /* Processes the cropped image*/

        var height, image_data, size, width;
        this.add_thumbnail(image);
        this.set_image_uploaded(true);
        image_data = image.src;
        if (this.options.scale_width && this.options.scale_height) {
          width = this.options.scale_width;
          height = this.options.scale_height;
        } else if (this.options.max_width || this.options.max_height) {
          size = this.get_max_size(image.width, image.height, this.options.max_width, this.options.max_height);
          width = size.width;
          height = size.height;
        } else {
          width = image.width;
          height = image.height;
        }
        image_data = this.get_resized_image(image, width, height);
        if (width < this.options.min_width || height < this.options.min_height) {
          this.controls_root.addClass("jcrop-fileinput-invalid");
          if (this.options.invalid_callback) {
            this.options.invalid_callback();
          }
        } else {
          this.controls_root.removeClass("jcrop-fileinput-invalid");
        }
        this.targetCanvas.toBlob(this.set_blob);
        if (this.options.save_callback) {
          return this.options.save_callback(image_data);
        }
      };

      JCropFileInput.prototype.is_canvas_supported = function() {
        /* Returns true if the current browser supports canvas.*/

        var canv;
        canv = document.createElement('canvas');
        return !!(canv.getContext && canv.getContext('2d'));
      };

      JCropFileInput.prototype.set_image_uploaded = function(has_image) {
        /* Makes change to the UI depending of the presence of an image*/

        if (has_image) {
          this.controls_root.find('.jcrop-fileinput-upload-label').text(this.options.labels.change);
          return this.controls_root.addClass('jcrop-fileinput-has-file');
        } else {
          this.controls_root.removeClass('jcrop-fileinput-has-file');
          this.controls_root.find('.jcrop-fileinput-thumbnail').remove();
          this.controls_root.find('.jcrop-fileinput-delete-button').hide();
          this.controls_root.find('.jcrop-fileinput-crop-button').hide();
          this.controls_root.find('.jcrop-fileinput-upload-label').text(this.options.labels.upload);
          return this.set_status_text(null);
        }
      };

      JCropFileInput.prototype.build_image = function(image_data, callback) {
        /* Returns an image HTML element containing image data
            The image may (and will probably will not) be fully loaded when the
            image returns.  Use the callback to get the fully instanciated image.
        */

        var image;
        image = document.createElement("img");
        image.src = image_data;
        image.onload = function() {
          if (callback) {
            return callback(image);
          }
        };
        return image;
      };

      JCropFileInput.prototype.set_blob = function(blob) {
        return this.blob = blob;
      };

      JCropFileInput.prototype.build_toolbar = function() {
        /* Return a toolbar jQuery element containing actions applyable to
            the JCrop widget.
        */

        var $save_button, $toolbar;
        $toolbar = $("<div>").addClass("jcrop-fileinput-toolbar");
        $save_button = $("<button>" + this.options.labels.save + "</button>");
        $save_button.addClass("jcrop-fileinput-button");
        $save_button.on("click", this.on_save);
        return $toolbar.append($save_button);
      };

      JCropFileInput.prototype.set_status_text = function(filename_text, width, height) {
        var filename, filename_parts, size, size_text, status_bar;
        status_bar = this.controls_root.find('.jcrop-fileinput-status');
        status_bar.empty();
        if (!filename_text) {
          return;
        }
        filename_parts = filename_text.split("/");
        filename_text = filename_parts[filename_parts.length - 1];
        filename = $("<span>").addClass('jcrop-fileinput-filename').text(filename_text);
        filename.prop('title', filename_text);
        size_text = "(" + width + "x" + height + "px)";
        size = $("<span>").addClass('jcrop-fileinput-size').text(size_text);
        status_bar.append(filename);
        return status_bar.append(size);
      };

      JCropFileInput.prototype.get_resized_image = function(image, width, height) {
        /* Resize an image to fixed size*/

        var canvas, canvas_height, canvas_width, ctx;
        if (!width || !height) {
          this.debug("Missing image dimensions");
          return;
        }
        this.debug("Resizing image to " + width + "x" + height);
        canvas_width = width;
        canvas_height = height;
        canvas = document.createElement("canvas");
        canvas.width = canvas_width;
        canvas.height = canvas_height;
        ctx = canvas.getContext("2d");
        ctx.drawImage(image, 0, 0, width, height);
        return canvas.toDataURL(this.original_filetype);
      };

      JCropFileInput.prototype.get_max_size = function(width, height, max_width, max_height) {
        var newHeight, newWidth;
        newWidth = width;
        newHeight = height;
        if (width > height) {
          if (width > max_width) {
            newHeight *= max_width / width;
            newWidth = max_width;
          }
        } else {
          if (height > max_height) {
            newWidth *= max_height / height;
            newHeight = max_height;
          }
        }
        return {
          width: newWidth,
          height: newHeight
        };
      };

      JCropFileInput.prototype.build_jcrop_widget = function(image) {
        /* Adds a fully configured JCrop widget to the widgetContainer*/

        var $img, data, instance, size;
        this.debug("initalizing jcrop ");
        size = this.get_max_size(image.width, image.height, this.options.jcrop_width, this.options.jcrop_height);
        data = this.get_resized_image(image, size.width, size.height);
        this.controls_root.slideUp();
        instance = this;
        this.widgetContainer.find('.jcrop-image').remove();
        this.widgetContainer.find('.jcrop-fileinput-toolbar').remove();
        $img = $("<img>");
        $img.prop("src", data);
        $img.addClass("jcrop-image");
        this.widgetContainer.append($img);
        this.widgetContainer.append(this.build_toolbar());
        this.widgetContainer.slideDown();
        return $img.Jcrop({
          onChange: this.on_jcrop_select,
          onSelect: this.on_jcrop_select,
          aspectRatio: this.options.ratio,
          bgColor: "white",
          bgOpacity: 0.5
        }, function() {
          var api;
          api = this;
          api.setSelect([0, 0, $img.width(), $img.height()]);
          return instance.jcrop_api = api;
        });
      };

      JCropFileInput.prototype.on_jcrop_select = function(coords) {
        return this.crop_original_image(coords);
      };

      JCropFileInput.prototype.crop_original_image = function(coords) {
        var canvas, canvas_height, canvas_width, ctx, factor, origin_x, origin_y;
        if (!coords) {
          return;
        }
        if (this.original_width > this.options.jcrop_width || this.original_height > this.options.jcrop_height) {
          if (this.original_width > this.original_height) {
            factor = this.original_width / this.options.jcrop_width;
          } else {
            factor = this.original_height / this.options.jcrop_height;
          }
        } else {
          factor = 1;
        }
        canvas = this.targetCanvas;
        origin_x = coords.x * factor;
        origin_y = coords.y * factor;
        canvas_width = coords.w * factor;
        canvas_height = coords.h * factor;
        canvas.width = canvas_width;
        canvas.height = canvas_height;
        ctx = canvas.getContext("2d");
        return ctx.drawImage(this.original_image, origin_x, origin_y, canvas_width, canvas_height, 0, 0, canvas_width, canvas_height);
      };

      JCropFileInput.prototype.override_form_submit = function() {
        var form,
          _this = this;
        form = $(this.element).closest('form').get(0);
        if (!form) {
          return;
        }
        return $(form).on('submit', function(evt) {
          var action_url, field, field_name, form_data, i, jcrop_instance, request, value, _i, _ref;
          evt.preventDefault();
          form_data = new FormData();
          console.log(form);
          for (i = _i = 0, _ref = form.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
            field = form[i];
            if (!field) {
              continue;
            }
            field_name = field.name;
            if (!field_name) {
              continue;
            }
            jcrop_instance = field.JCropFileInput;
            if (!jcrop_instance) {
              value = field.value;
              form_data.append(field_name, value);
            }
          }
          form_data.append('image', _this.blob, "image.png");
          request = new XMLHttpRequest();
          action_url = form.action || ".";
          request.open("POST", action_url);
          request.send(form_data);
          return request.onload = function(oEvent) {
            document.open();
            document.write(request.responseText);
            return document.close();
          };
        });
      };

      JCropFileInput.prototype.debug = function(message) {
        if (this.options['debug']) {
          return console.log(message);
        }
      };

      JCropFileInput.prototype.set_options = function(options) {
        this.options = $.extend({}, this.options, options);
        return this.set_ratio(this.options.ratio);
      };

      JCropFileInput.prototype.set_ratio = function(ratio_value) {
        if (!this.jcrop_api) {
          return;
        }
        return this.jcrop_api.setOptions({
          aspectRatio: ratio_value
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
          return instance.set_options(options);
        }
      });
    };
  })(jQuery, window, document);

}).call(this);

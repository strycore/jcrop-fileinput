module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    meta: {
      banner: "/*\n" +
        " *  <%= pkg.title || pkg.name %> - v<%= pkg.version %>\n" +
        " *  <%= pkg.description %>\n" +
        " *  <%= pkg.homepage %>\n" +
        " *\n" +
        " *  Made by <%= pkg.author.name %>\n" +
        " *  Under <%= pkg.licenses[0].type %> License\n" +
        " */\n"
    },

    coffeelint: {
      app: ["src/jcrop-fileinput.coffee"]
    },

    uglify: {
      myTarget: {
        src: ["dist/jcrop-fileinput.js"],
        dest: "dist/jcrop-fileinput.min.js"
      },
      options: {
        banner: "<%= meta.banner %>"
      }
    },

    coffee: {
      compile: {
        files: {
          "dist/jcrop-fileinput.js": "src/jcrop-fileinput.coffee"
        }
      }
    },

    sass: {
      dist: {
        files: {
          "dist/jcrop-fileinput.css": "src/jcrop-fileinput.scss"
        }
      }
    },

    watch: {
      coffee: {
        files: "src/jcrop-fileinput.coffee",
        tasks: ["coffee"]
      },
      sass: {
        files: "src/jcrop-fileinput.scss",
        tasks: ["sass"]
      }
    },

    connect: {
      options: {
        port: 9000,
        hostname: "*"
      },
      livereload: {
        options: {
          open: true,
          livereload: 32739,
          base: [
            "bower_components",
            "dist",
            "demo"
          ]
        }
      }
    },

    browserSync: {
        dev: {
            bsFiles: {
                src: [
                    'dist/*',
                    'demo/*.html'
                ]
            },
            options: {
                watchTask: true,
                server: '.'
            }
        }
    }

  });

  grunt.loadNpmTasks("grunt-coffeelint");
  grunt.loadNpmTasks("grunt-contrib-uglify");
  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.loadNpmTasks("grunt-contrib-sass");
  grunt.loadNpmTasks("grunt-contrib-watch");
  grunt.loadNpmTasks('grunt-browser-sync');
  grunt.registerTask("default", ["coffeelint", "coffee", "sass", "uglify"]);
  grunt.registerTask("server", ["browserSync", "watch"]);
};

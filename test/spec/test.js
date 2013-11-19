/*global describe, it, $, beforeEach, expect */
"use strict";


describe("JCrop File Inputs", function () {

    var instance;

    beforeEach(function() {
        $("#jcropupload").JCropFileInput();
        instance = $("#jcropupload").data("plugin_JCropFileInput");
    });

    describe("Given default options", function () {
        it("initialize correctly", function () {
            expect(instance).to.not.equal(undefined);
        });

        it("has default options", function () {
            expect(instance.options.jcrop_width).to.equal(640);
            expect(instance.options.jcrop_height).to.equal(480);
        });
    });

    describe("Given overloaded options", function () {
        beforeEach(function() {
            $("#jcropupload").JCropFileInput({
                ratio: 0.2
            });
            instance = $("#jcropupload").data("plugin_JCropFileInput");
        });

        it("use given options", function() {
            expect(instance.options.ratio).to.equal(0.2);
        });
    });

    describe("Given init()ed JCropFileInput object", function () {
        it("has all the wrapper divs", function() {
            var elm = $("#jcropupload");
            expect(elm.parent().hasClass("jcrop-fileinput-fakebutton")).to.equal(true);
            expect(elm.parent().parent().hasClass("jcrop-fileinput-wrapper")).to.equal(true);
        });
    });

    describe("Given a fileinput change event ", function () {

        // TODO : Find a way to test input[type=file]
        //it("has correct filetype", function  () {
        //    var elm = $("#jcropupload");
        //    console.log(elm.get(0).files);
        //    elm.get(0).files.push({});
        //    elm.trigger("change");
        //});
    });
});

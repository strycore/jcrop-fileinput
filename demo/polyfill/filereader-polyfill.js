$(function () {
  $("input[type=file]").fileReader({
    filereader: "polyfill/FileReader/filereader.swf",
    expressinstall: "polyfill/swfobject/expressInstall.swf",
    debugMode: false,
  });
});

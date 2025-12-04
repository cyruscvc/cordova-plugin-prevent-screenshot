var exec = require('cordova/exec');

var screenshot = {
    // These two now really block screenshots on iOS (black screen)
    enable: function (success, error) {
        exec(success || function () {}, error || function () {}, 'ScreenshotBlocker', 'enable', []);
    },

    disable: function (success, error) {
        exec(success || function () {}, error || function () {}, 'ScreenshotBlocker', 'disable', []);
    },

    // Keep your Android detection methods exactly as before
    registerListener: function (callback) {
        exec(callback, callback, 'ScreenshotBlocker', 'listen', []);
    },

    activateDetectAndroid: function (callback) {
        exec(callback || function () {}, callback || function () {}, 'ScreenshotBlocker', 'activateDetect', []);
        console.log("Activate Detect Android");
    }
};

// Register the plugin under the exact name your app expects
cordova.addConstructor(function () {
    if (!window.plugins) {
        window.plugins = {};
    }
    window.plugins.preventscreenshot = screenshot;

    // Auto-register the listener so events keep working (exactly like your original)
    screenshot.registerListener(function (message) {
        console.log('received listener:', message);

        if (message === "background") {
            var event = new Event('onGoingBackground');
            document.dispatchEvent(event);
        }
        if (message === "tookScreenshot") {
            var event = new Event('onTookScreenshot');
            document.dispatchEvent(event);
        }
    });

    return window.plugins.preventscreenshot;
});

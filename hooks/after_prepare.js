// hooks/after_prepare.js
var fs = require('fs');
var path = require('path');

var iosPath = path.join('platforms', 'ios');
var appDelegatePath = path.join(iosPath, 'AppDelegate.m');

if (!fs.existsSync(appDelegatePath)) {
    console.log('AppDelegate.m not found - skipping hook.');
    return;
}

var content = fs.readFileSync(appDelegatePath, 'utf8');

// Insert into didFinishLaunchingWithOptions (before return YES;)
var insertPoint = content.lastIndexOf('return YES;');
if (insertPoint !== -1) {
    var hookCode = `
        // Screenshot detection (existing or add)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDidTakeScreenshot:)
                                                     name:UIApplicationUserDidTakeScreenshotNotification
                                                   object:nil];

        // Prevention flag init
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"screenshotPreventionEnabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Defer to plugin for enable (after webview ready)
    `;
    var newContent = content.slice(0, insertPoint) + hookCode + '\n    ' + content.slice(insertPoint);
    fs.writeFileSync(appDelegatePath, newContent);
    console.log('Injected screenshot hook into AppDelegate.m');
}

// For SceneDelegate.m (iOS 13+), manual edit if needed: Add similar in scene:willConnectTo:

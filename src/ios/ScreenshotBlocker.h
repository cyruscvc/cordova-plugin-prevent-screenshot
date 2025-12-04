#import <Cordova/CDVPlugin.h>
#import <UIKit/UIKit.h>

@interface ScreenshotBlocker : CDVPlugin

- (void)enable:(CDVInvokedUrlCommand*)command;  // Existing? Extend for prevention
- (void)disable:(CDVInvokedUrlCommand*)command; // Existing? Extend for disable
- (void)isEnabled:(CDVInvokedUrlCommand*)command; // Optional check

@end

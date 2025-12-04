#import "ScreenshotBlocker.h"

static BOOL preventionEnabled = NO;
static UITextField *secureField = nil;
static UIWindow *protectedWindow = nil;

@implementation ScreenshotBlocker

- (void)enable:(CDVInvokedUrlCommand*)command {
    // Your existing Android-forwarding logic? (e.g., if not iOS, no-op)
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"screenshotPreventionEnabled"]) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    protectedWindow = self.viewController.view.window;
    if (!protectedWindow) {
        // Retry post-deviceready
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self enable:command];
        });
        return;
    }

    // Create hidden secure UITextField
    secureField = [[UITextField alloc] initWithFrame:protectedWindow.bounds];
    secureField.secureTextEntry = YES;
    secureField.hidden = YES;
    secureField.backgroundColor = [UIColor clearColor];
    [protectedWindow insertSubview:secureField atIndex:0];

    // Reparent for protection (screenshots go black)
    [protectedWindow.layer removeFromSuperlayer];
    [secureField.layer addSublayer:protectedWindow.layer];

    preventionEnabled = YES;
    [defaults setBool:YES forKey:@"screenshotPreventionEnabled"];
    [defaults synchronize];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)disable:(CDVInvokedUrlCommand*)command {
    if (!preventionEnabled) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    // Reverse: Restore layer hierarchy
    if (secureField && protectedWindow) {
        [protectedWindow.layer removeFromSuperlayer];
        // Re-add to original superlayer (window's root view or superview.layer)
        UIView *rootView = protectedWindow.rootViewController.view;
        [rootView.layer addSublayer:protectedWindow.layer];
        [secureField removeFromSuperview];
        secureField = nil;
        protectedWindow = nil;
    }

    preventionEnabled = NO;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"screenshotPreventionEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

// Detection (your existing, enhanced with overlay)
- (void)userDidTakeScreenshot:(NSNotification *)notification {
    // Fire JS event (adapt to your callback ID or global event)
    NSString *jsStatement = @"setTimeout(function() { cordova.fireDocumentEvent('onTookScreenshot'); }, 0);";
    [self.commandDelegate evalJs:jsStatement];

    if (preventionEnabled) {
        [self showDetectionOverlay];
    }
}

- (void)showDetectionOverlay {
    if (!protectedWindow) return;

    UIView *overlay = [[UIView alloc] initWithFrame:protectedWindow.bounds];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    overlay.alpha = 0.0;
    [protectedWindow addSubview:overlay];

    UILabel *label = [[UILabel alloc] initWithFrame:overlay.bounds];
    label.text = @"Screenshots are prohibited";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:16];
    [overlay addSubview:label];

    [UIView animateWithDuration:0.3 animations:^{
        overlay.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.5 animations:^{
            overlay.alpha = 0.0;
        } completion:^(BOOL finished) {
            [overlay removeFromSuperview];
        }];
    }];
}

@end

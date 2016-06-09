#import "IonicDeeplinkPlugin.h"

#import <Cordova/CDVAvailability.h>

@implementation IonicDeeplinkPlugin

- (void)pluginInitialize {
  _handlers = [[NSMutableArray alloc] init];
}

/* ------------------------------------------------------------- */

- (void)onAppTerminate {
  _handlers = nil;
  [super onAppTerminate];
}

- (void)canOpenApp:(CDVInvokedUrlCommand *)command {
  CDVPluginResult* result = nil;

  NSString* scheme = [command.arguments objectAtIndex:0];

  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:scheme]]) {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:(true)];
  } else {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:(false)];
  }

  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)onDeepLink:(CDVInvokedUrlCommand *)command {
  [_handlers addObject:command.callbackId];
  // Try to consume any events we got before we were listening
  [self sendToJs];
}

- (BOOL)handleLink:(NSURL *)url {
  NSLog(@"IonicDeepLinkPlugin: Handle link (internal) %@", url);

  _lastEvent = [self createResult:url];

  [self sendToJs];

  return YES;
}

- (BOOL)handleContinueUserActivity:(NSUserActivity *)userActivity {

  if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] || userActivity.webpageURL == nil) {
    return NO;
  }

  NSURL *url = userActivity.webpageURL;
  _lastEvent = [self createResult:url];
  NSLog(@"IonicDeepLinkPlugin: Handle continueUserActivity (internal) %@", url);

  [self sendToJs];

  return NO;
}

- (void) sendToJs {
  // Send the last event to JS if we have one
  if (_handlers.count == 0 || _lastEvent == nil) {
    return;
  }

  // Iterate our handlers and send the event
  for (id callbackID in _handlers) {
    [self.commandDelegate sendPluginResult:_lastEvent callbackId:callbackID];
  }

  // Clear out the last event
  _lastEvent = nil;
}

- (CDVPluginResult *)createResult:(NSURL *)url {
  NSDictionary* data = @{
    @"url": [url absoluteString] ?: @"",
    @"path": [url path] ?: @"",
    @"queryString": [url query] ?: @"",
    @"scheme": [url scheme] ?: @"",
    @"host": [url host] ?: @""
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
  [result setKeepCallbackAsBool:YES];
  return result;
}

@end

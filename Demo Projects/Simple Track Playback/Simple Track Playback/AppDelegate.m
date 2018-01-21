/*
 Copyright 2015 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "AppDelegate.h"
#import "Config.h"

@interface AppDelegate ()
@property (nonatomic, strong) SPTAuth *auth;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (nonatomic, strong) UIViewController *authViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set up shared authentication information
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.clientID = @kClientId;
    auth.requestedScopes = @[SPTAuthStreamingScope];
    auth.redirectURL = [NSURL URLWithString:@kCallbackURL];
#ifdef kTokenSwapServiceURL
    auth.tokenSwapURL = [NSURL URLWithString:@kTokenSwapServiceURL];
#endif
#ifdef kTokenRefreshServiceURL
    auth.tokenRefreshURL = [NSURL URLWithString:@kTokenRefreshServiceURL];
#endif
    auth.sessionUserDefaultsKey = @kSessionUserDefaultsKey;
    return YES;
}

/*- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.auth = [SPTAuth defaultInstance];
    self.player = [SPTAudioStreamingController sharedInstance];
    
    // The client ID you got from the developer site
    self.auth.clientID = @"d318391d90fb4362936afd76b0d08c61";
    // The redirect URL as you entered it at the developer site
    self.auth.redirectURL = [NSURL URLWithString:@"sbhacksiv-login://callback"];
    // Setting the `sessionUserDefaultsKey` enables SPTAuth to automatically store the session object for future use.
    self.auth.sessionUserDefaultsKey = @"current session";
    // Set the scopes you need the user to authorize. `SPTAuthStreamingScope` is required for playing audio.
    self.auth.requestedScopes = @[SPTAuthStreamingScope];
    
    // Become the streaming controller delegate
    self.player.delegate = self;
    
    // Start up the streaming controller.
    NSError *audioStreamingInitError;
    NSAssert([self.player startWithClientId:self.auth.clientID error:&audioStreamingInitError],
             @"There was a problem starting the Spotify SDK: %@", audioStreamingInitError.description);
    
    // Start authenticating when the app is finished launching
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startAuthenticationFlow];
    });
    
    return YES;
}*/

- (void)startAuthenticationFlow
{
    // Check if we could use the access token we already have
    if ([self.auth.session isValid]) {
        // Use it to log in
        [self.player loginWithAccessToken:self.auth.session.accessToken];
    } else {
        // Get the URL to the Spotify authorization portal
        NSURL *authURL = [self.auth spotifyWebAuthenticationURL];
        // Present in a SafariViewController
        self.authViewController = [[SFSafariViewController alloc] initWithURL:authURL];
        [self.window.rootViewController presentViewController:self.authViewController animated:YES completion:nil];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    SPTAuthCallback authCallback = ^(NSError *error, SPTSession *session) {
        // This is the callback that'll be triggered when auth is completed (or fails).
        
        if (error) {
            NSLog(@"*** Auth error: %@", error);
        } else {
            auth.session = session;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sessionUpdated" object:self];
    };
    
    /*
     Handle the callback from the authentication service. -[SPAuth -canHandleURL:]
     helps us filter out URLs that aren't authentication URLs (i.e., URLs you use elsewhere in your application).
     */
    
    if ([auth canHandleURL:url]) {
        [auth handleAuthCallbackWithTriggeredAuthURL:url callback:authCallback];
        return YES;
    }
    
    return NO;
}
/*- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options
{
    // If the incoming url is what we expect we handle it
    if ([self.auth canHandleURL:url]) {
        // Close the authentication window
        [self.authViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        self.authViewController = nil;
        
        // Parse the incoming url to a session object
        [self.auth handleAuthCallbackWithTriggeredAuthURL:url callback:^(NSError *error, SPTSession *session) {
            if (session) {
                // login to the player
                [self.player loginWithAccessToken:self.auth.session.accessToken];
            }
        }];
        return YES;
    }
    return NO;
}*/

- (void)audioStreamingDidLogin:(SPTAudioStreamingController *)audioStreaming
{
    [self.player playSpotifyURI:@"spotify:track:58s6EuEYJdlb0kO7awm3Vp" startingWithIndex:0 startingWithPosition:0 callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** failed to play: %@", error);
            return;
        }
    }];
}

@end

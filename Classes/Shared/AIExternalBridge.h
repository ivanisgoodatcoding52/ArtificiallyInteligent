//
//  AIExternalBridge.h
//  Artificially Inteligent
//
//  Lets OTHER SpringBoard-resident tweaks request an AI response without
//  switching to our app or opening our chat UI - a request comes in, gets
//  routed through the user's currently-configured provider (same one
//  Settings.app controls), and a response goes back out, all same-process
//  and near-instant to dispatch (the network round-trip itself still takes
//  as long as it takes).
//
//  This does NOT require linking against this project at all. Darwin
//  notifications are a bare OS facility any process can post/observe, and
//  the payload travels through a shared NSUserDefaults suite rather than
//  the notification itself (Darwin notifications carry no payload data).
//  Any tweak can implement this same protocol independently:
//
//  WIRE PROTOCOL
//  --------------
//  Shared defaults suite: "com.rg.artificiallyinteligient"
//
//  To make a request:
//    1. Generate a request ID (any unique string - a UUID is simplest).
//    2. Write a JSON string to the "AIBridgePendingRequest" key of the
//       shared suite: {"id": "<your id>", "text": "<the message>"}
//    3. Post the Darwin notification "com.rg.artificiallyinteligient.bridge.request"
//       via CFNotificationCenterPostNotification on the Darwin center.
//    4. Register for "com.rg.artificiallyinteligient.bridge.response"
//       on the Darwin center. When it fires, read "AIBridgeLastResponse"
//       from the same shared suite: {"id": "...", "reply": "...", "error": "..."}
//       ("error" is only present if the request failed - check for it
//       before assuming "reply" is valid.)
//    5. Compare the response's "id" to the one you generated - this is a
//       single-slot mailbox, so a response you see might belong to a
//       different caller's concurrent request. Ignore it if the id doesn't
//       match yours.
//
//  This is intentionally simple (one request in flight at a time) rather
//  than a queued/multiplexed system - reasonable for occasional cross-tweak
//  calls, not for high-frequency or concurrent use from many callers at once.
//

#import <Foundation/Foundation.h>

@interface AIExternalBridge : NSObject

// Starts listening for incoming bridge requests. Call once, typically from
// Tweak.xm's %ctor, so the bridge is live for as long as SpringBoard runs.
+ (void)startListening;

@end

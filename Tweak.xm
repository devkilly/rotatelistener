// SECTION: Interface declarations

@interface UIView (Gestures)
@property (nonatomic, retain) NSArray *allSubviews;
@end

@interface SBOrientationLockManager
+(SBOrientationLockManager *) sharedInstance;
-(bool)isUserLocked;
-(void)lock;
-(void)unlock;
@end

@interface _UIStatusBarWifiSignalView : UIView
@property (nonatomic, assign) BOOL isTappedOn;
@property (nonatomic, assign) BOOL isWifiView;
@property (nonatomic, retain) UITapGestureRecognizer *tapGesture;
-(void)didMoveToWindow;
-(void)toggleRotation:(UITapGestureRecognizer *)sender;
@end

// Need CFNotificationCenter to get a reference to SBOrientationLockManager from anywhere not just SB
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

static void toggle(CFNotificationCenterRef center, void *oversever, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{

	if ([[%c(SBOrientationLockManager) sharedInstance] isUserLocked])
	{
        [[%c(SBOrientationLockManager) sharedInstance] unlock];
    } else
	{
        [[%c(SBOrientationLockManager) sharedInstance] lock];
	}
}

// SECTION: Tweak/Hooks

%hook _UIStatusBarWifiSignalView
%property (nonatomic, assign) BOOL isWifiView;
%property (nonatomic, retain) UITapGestureRecognizer *tapGesture;
-(void)didMoveToWindow
{
	if(!self.tapGesture)
	{
		self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleRotation:)];
		self.tapGesture.numberOfTapsRequired = 1;
		[self.tapGesture setCancelsTouchesInView: NO];
		[self.superview.superview addGestureRecognizer:self.tapGesture];
	}
	%orig;
}

%new
-(void)toggleRotation:(UITapGestureRecognizer *)sender 
{
	if (DEBUG == 1)
	{
		NSLog(@"***************Rotating***************");
	}
	// Send notification to CFNC to actually toggle using SBOrientationLockManager
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), // center
		CFSTR("rotatelistener.gesture"), // name
		NULL, // object
		NULL, // userInfo
		true	// deliverImmediately?
	);
}
%end

// Add observer to SBOrientationLockManager to receive messages and toggle
%hook SBOrientationLockManager
-(SBOrientationLockManager*) init {
	SBOrientationLockManager *orig = %orig;
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), // center
		NULL, 	// observer
		toggle,	// callBack
		CFSTR("rotatelistener.gesture"),	// name
		NULL,	// object
		CFNotificationSuspensionBehaviorDeliverImmediately // suspension behavior
	);
	return orig;
}

%end
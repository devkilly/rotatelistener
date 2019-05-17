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

@interface _UIStatusBarPersistentAnimationView : UIView
@end

@interface _UIStatusBarSignalView : _UIStatusBarPersistentAnimationView
@end

@interface _UIStatusBarWifiSignalView : _UIStatusBarSignalView
@property (nonatomic, assign) BOOL isTappedOn;
@property (nonatomic, assign) BOOL isWifiView;
@property (nonatomic, retain) UITapGestureRecognizer *tapGesture;
-(void)didMoveToWindow;
-(void)toggleRotation:(UITapGestureRecognizer *)sender;
@end

@interface _UIStatusBarWifiItem
@property (copy) _UIStatusBarWifiSignalView* _signalView;
@end

/*
@interface UITapGestureRecognizer
@property (assign, nonatomic) unsigned long long numberOfTapsRequired;
-(id)initWithTarget:(id)target action(SEL)action;
*/

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
	// call toggle
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), // center
		CFSTR("rotatelistener.gesture"), // name
		NULL, // object
		NULL, // userInfo
		true	// deliverImmediately?
	);
}

%end

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
/*
%hook _UIStatusBarWifiItem
-(_UIStatusBarWifiSignalView *) _signalView{
	if (DEBUG ==1) NSLog(@"henloooo");
	_UIStatusBarWifiSignalView *orig = %orig;
	orig.isWifiView = YES;
	return orig;
}
%end
*/
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

@interface _UIBatteryView : UIView
@property (nonatomic, retain) UITapGestureRecognizer *tapGesture;
-(void)didMoveToWindow;
-(void)toggleRotation:(UITapGestureRecognizer *)sender;
@end

// Need CFNotificationCenter to get a reference to SBOrientationLockManager from anywhere not just SB
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

static void toggle(CFNotificationCenterRef center, void *oversever, 
	CFStringRef name, const void *object, CFDictionaryRef userInfo)
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

%hook _UIBatteryView
%property (nonatomic, retain) UITapGestureRecognizer *tapGesture;
-(void)didMoveToWindow
{
	if(!self.tapGesture)
	{
		self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleRotation:)];
		self.tapGesture.numberOfTapsRequired = 2;
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

	CGPoint touchLocation = [sender locationInView:sender.view];	// gets coordinates of touch input
	CGRect rightStatusBarFrame = [self.superview.superview convertRect:self.superview.frame fromView:self.superview.superview]; // gets frame of only the uiview holding battery, wifi, signal 
	// extend the frame to go all the way up to the top of the screen
	rightStatusBarFrame = CGRectMake(rightStatusBarFrame.origin.x, 0, 
		rightStatusBarFrame.size.width, rightStatusBarFrame.size.height + rightStatusBarFrame.origin.y);
	if (CGRectContainsPoint(rightStatusBarFrame, touchLocation))
	{
		// call toggle
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), // center
			CFSTR("rotatelistener.gesture"), // name
			NULL, // object
			NULL, // userInfo
			true	// deliverImmediately?
		);
	}
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
/**
 * Project: Sovereign Radar Elite v10.0
 * Architect: General Wsam Al-Safi (Basrah / Nasiriyah)
 * Feature: Full Cloud-Sync ESP (Box, Health, Name, Lines)
 * Control: Double Tap to toggle Menu
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// [🎯] إحداثيات مركز القيادة السيادية (نفس لوحتك السابقة)
#define COMMAND_API @"http://16.171.230.58/dashboard_v70_pro.php?api=true"

// هياكل المحرك الرياضي (UE4 Math)
struct FVector { float X, Y, Z; };
struct FMatrix { float M[4][4]; };

// متغيرات الرؤية السحابية
static uintptr_t GWorld = 0;
static uintptr_t GNames = 0;
static uintptr_t ViewMatrixAddr = 0;
static BOOL isRadarActive = YES;
static BOOL showBox = YES;
static BOOL showName = YES;
static BOOL showHealth = YES;

// =========================================================
// [🎨] واجهة المنيو الاحترافي (Sovereign Mod Menu)
// =========================================================
@interface SovereignRadarMenu : UIView
@property (nonatomic, strong) UILabel *title;
@end

@implementation SovereignRadarMenu
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.9] colorWithAlphaComponent:0.9];
        self.layer.cornerRadius = 20;
        self.layer.borderColor = [UIColor cyanColor].CGColor;
        self.layer.borderWidth = 1.5;
        self.alpha = 0; // يبدأ مخفياً

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 25)];
        lbl.text = @"SOVEREIGN RADAR v10";
        lbl.textColor = [UIColor cyanColor];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:13];
        [self addSubview:lbl];

        [self addSwitch:@"رادار الصناديق (Box)" y:50 action:@selector(toggleBox:)];
        [self addSwitch:@"رادار الأسماء (Names)" y:90 action:@selector(toggleName:)];
        [self addSwitch:@"شريط الصحة (Health)" y:130 action:@selector(toggleHealth:)];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrag:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)addSwitch:(NSString *)title y:(float)y action:(SEL)selector {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(15, y, 140, 30)];
    l.text = title; l.textColor = [UIColor whiteColor]; l.font = [UIFont systemFontOfSize:11];
    [self addSubview:l];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(self.frame.size.width - 55, y, 0, 0)];
    sw.onTintColor = [UIColor cyanColor]; sw.transform = CGAffineTransformMakeScale(0.7, 0.7);
    sw.on = YES; [sw addTarget:self action:selector forControlEvents:UIControlEventValueChanged];
    [self addSubview:sw];
}

- (void)toggleBox:(UISwitch *)s { showBox = s.on; }
- (void)toggleName:(UISwitch *)s { showName = s.on; }
- (void)toggleHealth:(UISwitch *)s { showHealth = s.on; }

- (void)onDrag:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [p setTranslation:CGPointZero inView:self.superview];
}
@end

// =========================================================
// [👁️] طبقة الرسم السيادية (ESP Overlay)
// =========================================================
@interface SovereignRadarView : UIView
@end

@implementation SovereignRadarView
- (void)drawRect:(CGRect)rect {
    if (!isRadarActive) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // [تكتيك السيادة]: محاكاة رسم لاعبين (سيتم الربط بالأوفستات حياً)
    [self drawPlayer:ctx x:200 y:300 w:100 h:200 hp:80 name:@"General_Wsam"];
    [self drawPlayer:ctx x:500 y:250 w:80 h:160 hp:30 name:@"Enemy_Target"];
}

- (void)drawPlayer:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name {
    if (showBox) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }
    if (showHealth) {
        float hpRate = (h * hp) / 100;
        CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
        CGContextFillRect(ctx, CGRectMake(x - 6, y, 4, h));
        CGContextSetFillColorWithColor(ctx, (hp > 50 ? [UIColor greenColor] : [UIColor redColor]).CGColor);
        CGContextFillRect(ctx, CGRectMake(x - 6, y + (h - hpRate), 4, hpRate));
    }
    if (showName) {
        NSDictionary *attr = @{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont boldSystemFontOfSize:9]};
        [name drawAtPoint:CGPointMake(x, y - 15) withAttributes:attr];
    }
}
@end

// =========================================================
// [🚀] محرك المزامنة والاغتيال المليمتري
// =========================================================
static SovereignRadarMenu *wsamMenu = nil;
static SovereignRadarView *radarOverlay = nil;

void syncRadarOffsets() {
    NSURL *url = [NSURL URLWithString:COMMAND_API];
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (!data) return;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *payload = json[@"payload"];
        
        for (NSDictionary *item in payload) {
            NSString *name = item[@"name"];
            uintptr_t addr = strtoull([item[@"address"] UTF8String], NULL, 16);
            
            // تخصيص إحداثيات الرادار مليمتر بمليمتر من اللوحة
            if ([name isEqualToString:@"GWorld"]) GWorld = addr;
            if ([name isEqualToString:@"GNames"]) GNames = addr;
            if ([name isEqualToString:@"ViewMatrix"]) ViewMatrixAddr = addr;
        }
        NSLog(@"[Sovereign] Radar Intelligence Updated from Cloud.");
    }] resume];
}

void __attribute__((constructor)) start_wsam_radar() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            // 1. حقن طبقة الرادار
            radarOverlay = [[SovereignRadarView alloc] initWithFrame:win.bounds];
            radarOverlay.backgroundColor = [UIColor clearColor];
            radarOverlay.userInteractionEnabled = NO;
            [win addSubview:radarOverlay];

            // 2. حقن المنيو السيادي
            wsamMenu = [[SovereignRadarMenu alloc] initWithFrame:CGRectMake(100, 100, 220, 240)];
            [win addSubview:wsamMenu];

            // 3. تفعيل النقر المزدوج
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[SovereignRadarMenu class] action:@selector(toggleGlobalMenu)];
            tap.numberOfTapsRequired = 2;
            [win addGestureRecognizer:tap];

            // 4. بدء المزامنة الدورية للأوفستات
            [NSTimer scheduledTimerWithTimeInterval:30 repeats:YES block:^(NSTimer * _Nonnull timer) {
                syncRadarOffsets();
                dispatch_async(dispatch_get_main_queue(), ^{ [radarOverlay setNeedsDisplay]; });
            }];
            syncRadarOffsets();
        }
    });
}

@implementation SovereignRadarMenu (Global)
+ (void)toggleGlobalMenu {
    [UIView animateWithDuration:0.3 animations:^{
        wsamMenu.alpha = (wsamMenu.alpha == 0) ? 1 : 0;
        wsamMenu.transform = (wsamMenu.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    }];
}
@end

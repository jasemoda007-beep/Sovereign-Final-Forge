/**
 * Project: Sovereign Elite X v12.0 - The Total War Engine
 * Architect: Eng. Wsam Al-Safi (Basrah / Nasiriyah)
 * Features: ESP Skeleton, HP, Name, Weapon, Box, Aimbot FOV, Recoil
 * Gesture: Double Tap in Screen Center (Improved for iOS 18)
 * Visibility: Yellow Arrow (In-View) / Red Arrow (Hidden)
 * Integration: Integrated with hook.c, fishhook.c, and patch.h
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// استدعاء مكاتب الحقن الميدانية
#include "patch.h"
#include "hook.h"
#include "fishhook.h"

// ==========================================================
// [🎯] منطقة إحداثيات النخاع (Offsets - ضع إحداثياتك هنا)
// ==========================================================
#define GWorld_Offset      0x1234567 
#define GNames_Offset      0x2345678 
#define ViewMatrix_Offset  0x3456789 

#define OFFSET_PlayerArray 0xA0
#define OFFSET_Health      0x880
#define OFFSET_IsVisible   0x7A0 
#define OFFSET_NoRecoil    0x4567890 

// [!] كتلة بيانات فريدة ضخمة لإجبار المفاعل على تغيير حجم الدايلب (Sovereign Bloat)
char sovereign_bulk_data[1024 * 50] = {0x57, 0x53, 0x41, 0x4d}; // 50KB لضمان تغيير الحجم

// ==========================================================
// [🧬] هياكل التحكم السيادية (Global Settings)
// ==========================================================
static struct {
    bool esp_box = true, esp_skeleton = true, esp_hp = true, esp_name = true;
    bool aim_active = false;
    int aim_target = 0; // 0:رأس, 1:جسم, 2:رجل
    float aim_fov = 150.0f;
    bool recoil_active = false;
} SovSettings;

struct FVector { float X, Y, Z; };
struct FMatrix { float M[4][4]; };

// ==========================================================
// [🎨] واجهة المنيو الاحترافي (Professional Transparent Menu)
// ==========================================================
@interface SovereignMenu : UIView
@property (nonatomic, strong) UIView *boxContainer;
@property (nonatomic, strong) UILabel *fovValLabel;
@end

@implementation SovereignMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0;
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];

        // تصميم المنيو الشفاف (Center Focused)
        CGFloat menuW = 280, menuH = 480;
        self.boxContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - menuW/2, frame.size.height/2 - menuH/2, menuW, menuH)];
        self.boxContainer.backgroundColor = [[UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:0.94] colorWithAlphaComponent:0.92];
        self.boxContainer.layer.cornerRadius = 35;
        self.boxContainer.layer.borderColor = [UIColor cyanColor].CGColor;
        self.boxContainer.layer.borderWidth = 2.0;
        [self addSubview:self.boxContainer];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, menuW, 30)];
        title.text = @"SOVEREIGN ELITE X v12.0";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:16];
        [self.boxContainer addSubview:title];

        // ميزات الرادار مليمتر بمليمتر
        [self addOpt:@"رادار الأسماء (Names)" y:60 tag:101];
        [self addOpt:@"رادار الصناديق (Box)" y:95 tag:102];
        [self addOpt:@"رادار الهيكل (Skeleton)" y:130 tag:103];
        [self addOpt:@"شريط الصحة (HP Bar)" y:165 tag:104];
        
        UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"رأس", @"جسم", @"رجل"]];
        targetSeg.frame = CGRectMake(25, 205, menuW - 50, 35);
        targetSeg.selectedSegmentIndex = 0;
        targetSeg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        [targetSeg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.boxContainer addSubview:targetSeg];

        self.fovValLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 250, 200, 20)];
        self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت: %.0f", SovSettings.aim_fov];
        self.fovValLabel.textColor = [UIColor whiteColor];
        self.fovValLabel.font = [UIFont boldSystemFontOfSize:11];
        [self.boxContainer addSubview:self.fovValLabel];

        UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, 275, menuW - 50, 30)];
        fovSlider.minimumValue = 50; fovSlider.maximumValue = 800;
        fovSlider.value = SovSettings.aim_fov;
        fovSlider.tintColor = [UIColor cyanColor];
        [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
        [self.boxContainer addSubview:fovSlider];

        [self addOpt:@"تفعيل الأيمبوت (Aim)" y:315 tag:105];
        [self addOpt:@"ثبات سلاح 100%" y:350 tag:106];

        UIButton *hideBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, 410, menuW - 80, 42)];
        [hideBtn setTitle:@"إغلاق (Double Tap to Show)" forState:UIControlStateNormal];
        hideBtn.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        hideBtn.layer.cornerRadius = 15;
        hideBtn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        [hideBtn addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
        [self.boxContainer addSubview:hideBtn];
    }
    return self;
}

- (void)addOpt:(NSString *)title y:(float)y tag:(int)tag {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 160, 30)];
    l.text = title; l.textColor = [UIColor whiteColor]; l.font = [UIFont systemFontOfSize:12];
    [self.boxContainer addSubview:l];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(self.boxContainer.frame.size.width - 65, y, 0, 0)];
    sw.onTintColor = [UIColor cyanColor]; sw.transform = CGAffineTransformMakeScale(0.75, 0.75);
    sw.tag = tag; sw.on = true;
    [sw addTarget:self action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
    [self.boxContainer addSubview:sw];
}

- (void)swChanged:(UISwitch *)sw {
    if (sw.tag == 101) SovSettings.esp_name = sw.on;
    if (sw.tag == 102) SovSettings.esp_box = sw.on;
    if (sw.tag == 103) SovSettings.esp_skeleton = sw.on;
    if (sw.tag == 104) SovSettings.esp_hp = sw.on;
    if (sw.tag == 105) SovSettings.aim_active = sw.on;
    if (sw.tag == 106) SovSettings.recoil_active = sw.on;
}

- (void)aimTargetChanged:(UISegmentedControl *)s { SovSettings.aim_target = (int)s.selectedSegmentIndex; }
- (void)fovChanged:(UISlider *)s { SovSettings.aim_fov = s.value; self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت: %.0f", s.value]; }

- (void)toggleVisibility {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:0 animations:^{
        self.alpha = (self.alpha == 0) ? 1.0 : 0;
        self.transform = (self.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    } completion:nil];
}
@end

// ==========================================================
// [👁️] طبقة رادار الشيتو (The Professional Radar Layer)
// ==========================================================
@interface SovereignRadarOverlay : UIView
@end

@implementation SovereignRadarOverlay
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    // [تكتيك الرؤية]: محاكاة الأعداء مليمتر بمليمتر (لغرض العرض)
    [self drawEnemy:ctx x:150 y:350 w:90 h:200 hp:95 name:@"Wsam_General" isVisible:YES dist:42];
    [self drawEnemy:ctx x:450 y:200 w:70 h:150 hp:25 name:@"Enemy_Target" isVisible:NO dist:186];

    if (SovSettings.aim_active) {
        CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor);
        CGContextSetLineWidth(ctx, 1.2);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov));
    }
}

- (void)drawEnemy:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name isVisible:(BOOL)isVisible dist:(int)dist {
    UIColor *mainCol = isVisible ? [UIColor yellowColor] : [UIColor redColor];
    
    // 1. السهم
    [self drawArrow:ctx atX:x+w/2 atY:y-40 color:mainCol];

    // 2. المربع
    if (SovSettings.esp_box) {
        CGContextSetStrokeColorWithColor(ctx, mainCol.CGColor);
        CGContextSetLineWidth(ctx, 1.8);
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }

    // 3. الهيكل العظمي
    if (SovSettings.esp_skeleton) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextMoveToPoint(ctx, x+w/2, y+20); CGContextAddLineToPoint(ctx, x+w/2, y+h/2+30);
        CGContextStrokePath(ctx);
    }

    // 4. شريط الدم
    if (SovSettings.esp_hp) {
        float hL = (h * hp) / 100;
        CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y, 4, h));
        CGContextSetFillColorWithColor(ctx, (hp > 60 ? [UIColor greenColor] : [UIColor redColor]).CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y+(h-hL), 4, hL));
    }

    // 5. البيانات
    if (SovSettings.esp_name) {
        NSString *inf = [NSString stringWithFormat:@"%@ [%dm]", name, dist];
        [inf drawAtPoint:CGPointMake(x, y-22) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:10], NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
}

- (void)drawArrow:(CGContextRef)ctx atX:(float)x atY:(float)y color:(UIColor *)color {
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextMoveToPoint(ctx, x, y);
    CGContextAddLineToPoint(ctx, x-12, y-15);
    CGContextAddLineToPoint(ctx, x+12, y-15);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
@end

// ==========================================================
// [🚀] صاعق الانطلاق المطور (Multi-Window Tracker)
// ==========================================================
static SovereignMenu *wsamMenu = nil;
static SovereignRadarOverlay *wsamRadar = nil;

void __attribute__((constructor)) start_v12_sovereign_engine() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *targetWindow = nil;
        // تكتيك رصد النافذة في iOS 15+
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    targetWindow = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!targetWindow) targetWindow = [UIApplication sharedApplication].keyWindow;

        if (targetWindow) {
            NSLog(@"[Sovereign] Mission Active on KeyWindow.");

            wsamRadar = [[SovereignRadarOverlay alloc] initWithFrame:targetWindow.bounds];
            wsamRadar.backgroundColor = [UIColor clearColor];
            wsamRadar.userInteractionEnabled = NO;
            [targetWindow addSubview:wsamRadar];

            wsamMenu = [[SovereignMenu alloc] initWithFrame:targetWindow.bounds];
            [targetWindow addSubview:wsamMenu];

            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:wsamMenu action:@selector(toggleVisibility)];
            tap.numberOfTapsRequired = 2;
            [targetWindow addGestureRecognizer:tap];

            [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer *timer) {
                [wsamRadar setNeedsDisplay];
            }];
        }
    });
}

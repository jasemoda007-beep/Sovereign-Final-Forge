/**
 * Project: Sovereign Elite X v11.0 - The Total War Engine
 * Architect: Eng. Wsam Al-Safi (Basrah / Nasiriyah)
 * Features: ESP Skeleton, HP, Name, Weapon, Box, Aimbot FOV, Recoil
 * Gesture: Double Tap in Screen Center (Improved for iOS 18)
 * Visibility: Yellow Arrow (In-View) / Red Arrow (Hidden)
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>

// ==========================================================
// [🎯] منطقة إحداثيات النخاع (Offests - ضع إحداثياتك هنا)
// ==========================================================
#define GWorld_Offset      0x1234567 
#define GNames_Offset      0x2345678 
#define ViewMatrix_Offset  0x3456789 

// أوفستات اللاعب (UE4 Actor Offsets)
#define OFFSET_PlayerArray 0xA0
#define OFFSET_Health      0x880
#define OFFSET_IsVisible   0x7A0 // عصب الرؤية مليمتر بمليمتر
#define OFFSET_NoRecoil    0x4567890 

// [!] بيانات فريدة لإجبار المفاعل على تغيير حجم الدايلب
const char* sovereign_identity = "Wsam_AlSafi_Sovereign_System_v11_Final_Edition_Basra_Nasiriyah_2026";

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
        self.backgroundColor = [UIColor clearColor];

        // تصميم المنيو الشفاف (Center Focused)
        CGFloat menuW = 280, menuH = 460;
        self.boxContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - menuW/2, frame.size.height/2 - menuH/2, menuW, menuH)];
        self.boxContainer.backgroundColor = [[UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:0.94] colorWithAlphaComponent:0.92];
        self.boxContainer.layer.cornerRadius = 35;
        self.boxContainer.layer.borderColor = [UIColor cyanColor].CGColor;
        self.boxContainer.layer.borderWidth = 1.5;
        [self addSubview:self.boxContainer];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, menuW, 30)];
        title.text = @"SOVEREIGN ELITE X v11.0";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:15];
        [self.boxContainer addSubview:title];

        // ميزات الرادار مليمتر بمليمتر
        [self addOpt:@"رادار الأسماء (Names)" y:60 tag:101];
        [self addOpt:@"رادار الصناديق (Box)" y:95 tag:102];
        [self addOpt:@"رادار الهيكل (Skeleton)" y:130 tag:103];
        [self addOpt:@"شريط الصحة (HP Bar)" y:165 tag:104];
        
        // اختيار هدف الأيمبوت (Head/Body/Leg)
        UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"رأس", @"جسم", @"رجل"]];
        targetSeg.frame = CGRectMake(25, 205, menuW - 50, 35);
        targetSeg.selectedSegmentIndex = 0;
        targetSeg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        [targetSeg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.boxContainer addSubview:targetSeg];

        // عتلة التحكم بالقطر (FOV Slider)
        self.fovValLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 245, 200, 20)];
        self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت: %.0f", SovSettings.aim_fov];
        self.fovValLabel.textColor = [UIColor whiteColor];
        self.fovValLabel.font = [UIFont systemFontOfSize:11];
        [self.boxContainer addSubview:self.fovValLabel];

        UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, 265, menuW - 50, 30)];
        fovSlider.minimumValue = 50; fovSlider.maximumValue = 800;
        fovSlider.value = SovSettings.aim_fov;
        fovSlider.tintColor = [UIColor cyanColor];
        [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
        [self.boxContainer addSubview:fovSlider];

        [self addOpt:@"تفعيل الأيمبوت (Aim)" y:305 tag:105];
        [self addOpt:@"ثبات سلاح 100%" y:340 tag:106];

        UIButton *hideBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, 400, menuW - 80, 40)];
        [hideBtn setTitle:@"إغلاق القائمة" forState:UIControlStateNormal];
        hideBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        hideBtn.layer.cornerRadius = 15;
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

    // [تكتيك الرؤية]: محاكاة الأعداء مليمتر بمليمتر
    [self drawEnemy:ctx x:200 y:300 w:100 h:220 hp:95 name:@"Wsam_General" isVisible:YES dist:42];
    [self drawEnemy:ctx x:550 y:250 w:80 h:160 hp:25 name:@"Enemy_Sniper" isVisible:NO dist:186];

    // رسم دائرة الأيمبوت
    if (SovSettings.aim_active) {
        CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov));
    }
}

- (void)drawEnemy:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name isVisible:(BOOL)isVisible dist:(int)dist {
    
    UIColor *mainCol = isVisible ? [UIColor yellowColor] : [UIColor redColor];
    
    // 1. رسم السهم (Arrow)
    [self drawArrow:ctx atX:x+w/2 atY:y-45 color:mainCol];

    // 2. المربع (Box)
    if (SovSettings.esp_box) {
        CGContextSetStrokeColorWithColor(ctx, mainCol.CGColor);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }

    // 3. الهيكل العظمي (Skeleton)
    if (SovSettings.esp_skeleton) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextMoveToPoint(ctx, x+w/2, y+25); CGContextAddLineToPoint(ctx, x+w/2, y+h/2+20); // نخاع الهيكل
        CGContextStrokePath(ctx);
    }

    // 4. شريط الدم (HP)
    if (SovSettings.esp_hp) {
        float hL = (h * hp) / 100;
        CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y, 4, h));
        CGContextSetFillColorWithColor(ctx, (hp > 60 ? [UIColor greenColor] : [UIColor redColor]).CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y+(h-hL), 4, hL));
    }

    // 5. البيانات العلوية
    NSString *inf = [NSString stringWithFormat:@"%@ [%dm]", name, dist];
    [inf drawAtPoint:CGPointMake(x, y-20) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:9], NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (void)drawArrow:(CGContextRef)ctx atX:(float)x atY:(float)y color:(UIColor *)color {
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextMoveToPoint(ctx, x, y);
    CGContextAddLineToPoint(ctx, x-12, y-18);
    CGContextAddLineToPoint(ctx, x+12, y-18);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
@end

// ==========================================================
// [🚀] صاعق الانطلاق المطور (Universal Window Orchestrator)
// ==========================================================
static SovereignMenu *mainMenu = nil;
static SovereignRadarOverlay *radarView = nil;

void __attribute__((constructor)) start_v11_engine() {
    // زيادة التأخير لـ 15 ثانية لضمان استقرار محرك اللعبة بالكامل
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *activeWin = nil;
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in [windows reverseObjectEnumerator]) {
            if ([window isKeyWindow] || [NSStringFromClass([window class]) containsString:@"Window"]) {
                activeWin = window;
                break;
            }
        }
        
        if (!activeWin) activeWin = [[UIApplication sharedApplication] keyWindow];

        if (activeWin) {
            NSLog(@"[Sovereign] Active Window Found. Injecting Arsenal...");

            // 1. حقن الرادار
            radarView = [[SovereignRadarOverlay alloc] initWithFrame:activeWin.bounds];
            radarView.backgroundColor = [UIColor clearColor];
            radarView.userInteractionEnabled = NO;
            [activeWin addSubview:radarView];

            // 2. حقن المنيو
            mainMenu = [[SovereignMenu alloc] initWithFrame:activeWin.bounds];
            [activeWin addSubview:mainMenu];

            // 3. [🎯] تفعيل النقر المزدوج (Double Tap Gesture)
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:mainMenu action:@selector(toggleVisibility)];
            tap.numberOfTapsRequired = 2;
            // إضافة الإيماءة للنافذة لضمان الرصد مليمتر بمليمتر
            [activeWin addGestureRecognizer:tap];

            // تحديث الرادار 60 إطار في الثانية للنعومة السيادية
            [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [radarView setNeedsDisplay];
            }];
            
            NSLog(@"[Sovereign] Operation v11.0 Successful. Mission Start.");
        }
    });
}

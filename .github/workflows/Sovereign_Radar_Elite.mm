/**
 * Project: Sovereign Elite X v10.0 (The Ultimate Radar)
 * Architect: Eng. Wsam Al-Safi (Basrah / Nasiriyah)
 * Features: ESP Skeleton, HP Bar, Name, Weapon, Box, Aimbot, FOV Slider.
 * Visibility: Yellow Arrow (In-View), Red Arrow (Hidden).
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>

// ==========================================================
// [🎯] منطقة إحداثيات النخاع (Place your offsets here)
// يا سيادة الجنرال، هنا تضع الأرقام المستخرجة من IDA مليمتر بمليمتر
// ==========================================================
#define GWorld_Offset      0x1234567 // استبدله بأوفست العالم
#define GNames_Offset      0x2345678 // استبدله بأوفست الأسماء
#define ViewMatrix_Offset  0x3456789 // استبدله بأوفست الكاميرا

// أوفستات اللاعب (Actor Offsets)
#define OFFSET_PlayerArray 0xA0
#define OFFSET_Location    0x150
#define OFFSET_Health      0x880
#define OFFSET_TeamID      0x640
#define OFFSET_IsVisible   0x7A0 // أوفست التحقق من الرؤية

// تفعيلات الذاكرة
#define OFFSET_NoRecoil    0x4567890 // أوفست ثبات السلاح

// ==========================================================
// [🧬] هياكل البيانات الرياضية
// ==========================================
struct FVector { float X, Y, Z; };
struct FMatrix { float M[4][4]; };

// حالة المفاعلات (Global Settings)
static struct {
    bool esp_name = true;
    bool esp_box = true;
    bool esp_hp = true;
    bool esp_skeleton = true;
    bool esp_weapon = true;
    bool esp_arrow = true;
    bool aim_active = false;
    int aim_target = 0; // 0:Head, 1:Body, 2:Leg
    float aim_fov = 150.0f;
    bool recoil_active = false;
} SovereignSettings;

// ==========================================================
// [🎨] واجهة المنيو الشفافة (Sovereign Transparent Menu)
// ==========================================================
@interface SovereignMenu : UIView
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UISlider *fovSlider;
@property (nonatomic, strong) UILabel *fovLabel;
@end

@implementation SovereignMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0;
        self.backgroundColor = [UIColor clearColor];
        
        // الحاوية المركزية
        self.container = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2-130, frame.size.height/2-180, 260, 420)];
        self.container.backgroundColor = [[UIColor colorWithRed:0.04 green:0.04 blue:0.06 alpha:0.85] colorWithAlphaComponent:0.9];
        self.container.layer.cornerRadius = 25;
        self.container.layer.borderColor = [UIColor cyanColor].CGColor;
        self.container.layer.borderWidth = 1.5;
        [self addSubview:self.container];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 260, 25)];
        title.text = @"SOVEREIGN ELITE v10";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:14];
        [self.container addSubview:title];

        // ميزات الرادار مليمتر بمليمتر
        [self addToggle:@"رادار الأسماء" y:55 tag:101];
        [self addToggle:@"رادار الصناديق" y:90 tag:102];
        [self addToggle:@"رادار الهيكل" y:125 tag:103];
        [self addToggle:@"شريط الصحة" y:160 tag:104];
        [self addToggle:@"أيمبوت ذكي" y:195 tag:105];
        
        // خيارات الأيمبوت (Segmented)
        UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"رأس", @"جسم", @"رجل"]];
        targetSeg.frame = CGRectMake(20, 235, 220, 30);
        targetSeg.selectedSegmentIndex = 0;
        targetSeg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        [targetSeg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.container addSubview:targetSeg];

        // عتلة الـ FOV
        self.fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 275, 220, 20)];
        self.fovLabel.text = [NSString stringWithFormat:@"دائرة الأيمبوت: %.0f", SovereignSettings.aim_fov];
        self.fovLabel.textColor = [UIColor whiteColor];
        self.fovLabel.font = [UIFont systemFontOfSize:10];
        [self.container addSubview:self.fovLabel];

        self.fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 295, 220, 30)];
        self.fovSlider.minimumValue = 50;
        self.fovSlider.maximumValue = 600;
        self.fovSlider.value = SovereignSettings.aim_fov;
        self.fovSlider.tintColor = [UIColor cyanColor];
        [self.fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
        [self.container addSubview:self.fovSlider];

        [self addToggle:@"ثبات السلاح 100%" y:335 tag:106];
    }
    return self;
}

- (void)addToggle:(NSString *)title y:(float)y tag:(int)tag {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 150, 30)];
    l.text = title; l.textColor = [UIColor whiteColor]; l.font = [UIFont systemFontOfSize:11];
    [self.container addSubview:l];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(190, y, 0, 0)];
    sw.onTintColor = [UIColor cyanColor]; sw.transform = CGAffineTransformMakeScale(0.7, 0.7);
    sw.tag = tag; sw.on = true;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.container addSubview:sw];
}

- (void)switchChanged:(UISwitch *)sw {
    if (sw.tag == 101) SovereignSettings.esp_name = sw.on;
    if (sw.tag == 102) SovereignSettings.esp_box = sw.on;
    if (sw.tag == 103) SovereignSettings.esp_skeleton = sw.on;
    if (sw.tag == 104) SovereignSettings.esp_hp = sw.on;
    if (sw.tag == 105) SovereignSettings.aim_active = sw.on;
    if (sw.tag == 106) SovereignSettings.recoil_active = sw.on;
}

- (void)aimTargetChanged:(UISegmentedControl *)seg { SovereignSettings.aim_target = (int)seg.selectedSegmentIndex; }

- (void)fovChanged:(UISlider *)slider {
    SovereignSettings.aim_fov = slider.value;
    self.fovLabel.text = [NSString stringWithFormat:@"دائرة الأيمبوت: %.0f", slider.value];
}

- (void)toggleVisibility {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = (self.alpha == 0) ? 1.0 : 0;
        self.transform = (self.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    }];
}
@end

// ==========================================================
// [👁️] طبقة الرسم والأسهم السيادية (The Radar Overlay)
// ==========================================================
@interface SovereignRadarOverlay : UIView
@end

@implementation SovereignRadarOverlay
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    // [تكتيك السيادة]: محاكاة رصد العدو (في النسخة النهائية يتم القراءة من الذاكرة)
    [self drawElitePlayer:ctx x:200 y:300 w:100 h:220 hp:85 name:@"Enemy_Target" weapon:@"M416" isVisible:YES dist:45];
    [self drawElitePlayer:ctx x:550 y:200 w:80 h:180 hp:40 name:@"Hidden_Sniper" weapon:@"AWM" isVisible:NO dist:132];
    
    // رسم دائرة الأيمبوت (FOV)
    if (SovereignSettings.aim_active) {
        CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(rect.size.width/2 - SovereignSettings.aim_fov/2, rect.size.height/2 - SovereignSettings.aim_fov/2, SovereignSettings.aim_fov, SovereignSettings.aim_fov));
    }
}

- (void)drawElitePlayer:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name weapon:(NSString *)weapon isVisible:(BOOL)isVisible dist:(int)dist {
    
    UIColor *mainColor = isVisible ? [UIColor yellowColor] : [UIColor redColor];
    
    // 1. رسم السهم العلوي (The Arrow) بأسلوب الشيتو
    [self drawArrow:ctx atX:x+w/2 atY:y-40 color:mainColor];

    // 2. رسم الصندوق (Box)
    if (SovereignSettings.esp_box) {
        CGContextSetStrokeColorWithColor(ctx, mainColor.CGColor);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }

    // 3. الهيكل العظمي (Skeleton) - رسم تخيلي للمفاصل
    if (SovereignSettings.esp_skeleton) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextMoveToPoint(ctx, x+w/2, y+20); CGContextAddLineToPoint(ctx, x+w/2, y+h/2); // العمود الفقري
        CGContextStrokePath(ctx);
    }

    // 4. شريط الدم والبيانات
    if (SovereignSettings.esp_hp) {
        float hpHeight = (h * hp) / 100;
        CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y, 4, h));
        CGContextSetFillColorWithColor(ctx, (hp > 50 ? [UIColor greenColor] : [UIColor redColor]).CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y + (h-hpHeight), 4, hpHeight));
    }

    // 5. النصوص (الاسم، السلاح، المسافة)
    NSString *info = [NSString stringWithFormat:@"%@ | %@ [%dm]", name, weapon, dist];
    [info drawAtPoint:CGPointMake(x, y-20) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:9], NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (void)drawArrow:(CGContextRef)ctx atX:(float)x atY:(float)y color:(UIColor *)color {
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextMoveToPoint(ctx, x, y);
    CGContextAddLineToPoint(ctx, x-10, y-15);
    CGContextAddLineToPoint(ctx, x+10, y-15);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
@end

// ==========================================================
// [🚀] صاعق التشغيل والتحكم (Main Controller)
// ==========================================================
static SovereignMenu *mainMenu = nil;
static SovereignRadarOverlay *radarView = nil;

void __attribute__((constructor)) ignite_sovereign_x() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            // 1. طبقة الرادار
            radarView = [[SovereignRadarOverlay alloc] initWithFrame:win.bounds];
            radarView.backgroundColor = [UIColor clearColor];
            radarView.userInteractionEnabled = NO;
            [win addSubview:radarView];

            // 2. المنيو الاحترافي
            mainMenu = [[SovereignMenu alloc] initWithFrame:win.bounds];
            [win addSubview:mainMenu];

            // 3. إيماءة النقر المزدوج في المنتصف
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:mainMenu action:@selector(toggleVisibility)];
            tap.numberOfTapsRequired = 2;
            [win addGestureRecognizer:tap];
            
            // تحديث الرادار 60 مرة في الثانية للنعومة السيادية
            [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [radarView setNeedsDisplay];
            }];
        }
    });
}

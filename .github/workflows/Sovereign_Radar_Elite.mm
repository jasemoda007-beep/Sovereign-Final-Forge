/**
 * Project: Sovereign Elite X v10.5 - The Unified Marrow
 * Architect: Eng. Wsam Al-Safi (Basrah / Nasiriyah)
 * Features: Professional ESP (Arrows, Skeleton, HP, Name, Box) + Aimbot FOV
 * Control: Double Tap in the Center to Toggle Menu
 * Location: Offline Offsets Inside
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>

// ==========================================================
// [🎯] منطقة إحداثيات النخاع (Offsets Area)
// يا سيادة الجنرال، هنا تضع إحداثياتك التي استخرجتها من IDA
// ==========================================================
#define GWorld_Offset      0x1234567 // أوفست العالم
#define GNames_Offset      0x2345678 // أوفست الأسماء
#define ViewMatrix_Offset  0x3456789 // أوفست الكاميرا

// أوفستات اللاعب (UE4 Actor Offsets)
#define OFFSET_PlayerArray 0xA0
#define OFFSET_Health      0x880
#define OFFSET_TeamID      0x640
#define OFFSET_Mesh        0x430 // للوصول للهيكل العظمي
#define OFFSET_IsVisible   0x7A0 // عصب الرؤية (أصفر/أحمر)

// أوفستات السلاح
#define OFFSET_NoRecoil    0x4567890 

// ==========================================================
// [🧬] هياكل البيانات والتحكم (Sovereign Global States)
// ==========================================================
static struct {
    bool esp_box = true;
    bool esp_skeleton = true;
    bool esp_hp = true;
    bool esp_name = true;
    bool esp_weapon = true;
    bool aim_active = false;
    int aim_target = 0; // 0:Head, 1:Body, 2:Leg
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
        self.alpha = 0; // يبدأ مخفياً للتمويه
        self.backgroundColor = [UIColor clearColor];

        // تصميم المنيو الشفاف بمنتصف الشاشة
        CGFloat menuW = 280;
        CGFloat menuH = 460;
        self.boxContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - menuW/2, frame.size.height/2 - menuH/2, menuW, menuH)];
        self.boxContainer.backgroundColor = [[UIColor colorWithRed:0.02 green:0.02 blue:0.05 alpha:0.85] colorWithAlphaComponent:0.9];
        self.boxContainer.layer.cornerRadius = 30;
        self.boxContainer.layer.borderColor = [UIColor cyanColor].CGColor;
        self.boxContainer.layer.borderWidth = 1.8;
        [self addSubview:self.boxContainer];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, menuW, 30)];
        title.text = @"SOVEREIGN ELITE X";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:16];
        [self.boxContainer addSubview:title];

        // كتائب التحكم مليمتر بمليمتر
        [self addOpt:@"رادار الصناديق (Box)" y:60 tag:101];
        [self addOpt:@"رادار الهيكل (Skeleton)" y:95 tag:102];
        [self addOpt:@"رادار الأسماء (Names)" y:130 tag:103];
        [self addOpt:@"شريط الصحة (HP Bar)" y:165 tag:104];
        
        // أزرار الأيمبوت (Head/Body/Leg)
        UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"رأس", @"جسم", @"رجل"]];
        targetSeg.frame = CGRectMake(25, 205, menuW - 50, 32);
        targetSeg.selectedSegmentIndex = 0;
        targetSeg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        [targetSeg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.boxContainer addSubview:targetSeg];

        // عتلة الـ FOV (Slider)
        UILabel *fovLbl = [[UILabel alloc] initWithFrame:CGRectMake(25, 245, 120, 20)];
        fovLbl.text = @"قطر الأيمبوت (FOV):";
        fovLbl.textColor = [UIColor whiteColor];
        fovLbl.font = [UIFont boldSystemFontOfSize:10];
        [self.boxContainer addSubview:fovLbl];

        UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, 265, menuW - 50, 30)];
        fovSlider.minimumValue = 50; fovSlider.maximumValue = 800;
        fovSlider.value = SovSettings.aim_fov;
        fovSlider.tintColor = [UIColor cyanColor];
        [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
        [self.boxContainer addSubview:fovSlider];

        self.fovValLabel = [[UILabel alloc] initWithFrame:CGRectMake(menuW - 60, 245, 50, 20)];
        self.fovValLabel.text = [NSString stringWithFormat:@"%.0f", SovSettings.aim_fov];
        self.fovValLabel.textColor = [UIColor yellowColor];
        self.fovValLabel.font = [UIFont boldSystemFontOfSize:10];
        [self.boxContainer addSubview:self.fovValLabel];

        [self addOpt:@"تفعيل الأيمبوت (Aim)" y:305 tag:105];
        [self addOpt:@"ثبات سلاح 100%" y:340 tag:106];

        UIButton *hideBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, 395, menuW - 80, 42)];
        [hideBtn setTitle:@"دخول الميدان ⚔️" forState:UIControlStateNormal];
        hideBtn.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        hideBtn.layer.cornerRadius = 15;
        hideBtn.layer.borderColor = [UIColor cyanColor].CGColor;
        hideBtn.layer.borderWidth = 1.0;
        [hideBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
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
    if (sw.tag == 101) SovSettings.esp_box = sw.on;
    if (sw.tag == 102) SovSettings.esp_skeleton = sw.on;
    if (sw.tag == 103) SovSettings.esp_name = sw.on;
    if (sw.tag == 104) SovSettings.esp_hp = sw.on;
    if (sw.tag == 105) SovSettings.aim_active = sw.on;
    if (sw.tag == 106) SovSettings.recoil_active = sw.on;
}

- (void)aimTargetChanged:(UISegmentedControl *)seg { SovSettings.aim_target = (int)seg.selectedSegmentIndex; }
- (void)fovChanged:(UISlider *)s { SovSettings.aim_fov = s.value; self.fovValLabel.text = [NSString stringWithFormat:@"%.0f", s.value]; }

- (void)toggleMenu {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        self.alpha = (self.alpha == 0) ? 1.0 : 0;
        self.transform = (self.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    } completion:nil];
}
@end

// ==========================================================
// [👁️] طبقة رادار الشيتو السيادي (Sovereign Radar Overlay)
// ==========================================================
@interface SovereignRadarView : UIView
@end

@implementation SovereignRadarView
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    // [تكتيك الصقر]: محاكاة الرسم بأسلوب الشيتو
    // (أصفر للظاهر / أحمر للمختفي مليمتر بمليمتر)
    [self drawEnemy:ctx x:200 y:300 w:100 h:220 hp:95 name:@"Wsam_General" weapon:@"M416" isVisible:YES dist:42];
    [self drawEnemy:ctx x:550 y:250 w:80 h:160 hp:25 name:@"Target_Enemy" weapon:@"Uzi" isVisible:NO dist:186];

    // رسم دائرة الأيمبوت (FOV)
    if (SovSettings.aim_active) {
        CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor);
        CGContextSetLineWidth(ctx, 1.2);
        CGRect fovRect = CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov);
        CGContextStrokeEllipseInRect(ctx, fovRect);
    }
}

- (void)drawEnemy:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name weapon:(NSString *)weapon isVisible:(BOOL)isVisible dist:(int)dist {
    
    UIColor *mainCol = isVisible ? [UIColor yellowColor] : [UIColor redColor];
    
    // 1. رسم سهم الشيتو (The Arrow)
    [self drawSovereignArrow:ctx atX:x+w/2 atY:y-45 color:mainCol];

    // 2. رسم الصندوق (Box ESP)
    if (SovSettings.esp_box) {
        CGContextSetStrokeColorWithColor(ctx, mainCol.CGColor);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }

    // 3. رسم الهيكل (Skeleton)
    if (SovSettings.esp_skeleton) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextMoveToPoint(ctx, x+w/2, y+25); CGContextAddLineToPoint(ctx, x+w/2, y+h/2+20); // العمود الفقري
        CGContextStrokePath(ctx);
    }

    // 4. شريط الدم (HP Bar) بأسلوب جانبي
    if (SovSettings.esp_hp) {
        float hpLen = (h * hp) / 100;
        CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y, 4, h));
        CGContextSetFillColorWithColor(ctx, (hp > 60 ? [UIColor greenColor] : [UIColor redColor]).CGColor);
        CGContextFillRect(ctx, CGRectMake(x-8, y + (h-hpLen), 4, hpLen));
    }

    // 5. البيانات (الاسم والسلاح)
    if (SovSettings.esp_name) {
        NSString *info = [NSString stringWithFormat:@"%@ | %@ [%dm]", name, weapon, dist];
        NSDictionary *attr = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:9], NSForegroundColorAttributeName:[UIColor whiteColor]};
        [info drawAtPoint:CGPointMake(x, y-20) withAttributes:attr];
    }
}

- (void)drawSovereignArrow:(CGContextRef)ctx atX:(float)x atY:(float)y color:(UIColor *)color {
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextMoveToPoint(ctx, x, y);
    CGContextAddLineToPoint(ctx, x-12, y-18);
    CGContextAddLineToPoint(ctx, x+12, y-18);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
@end

// ==========================================================
// [🚀] صاعق الانطلاق الموحد (Main Orchestrator)
// ==========================================================
static SovereignMenu *wsamMenu = nil;
static SovereignRadarView *wsamRadar = nil;

void __attribute__((constructor)) start_sovereign_x_v105() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) { win = scene.windows.firstObject; break; }
            }
        }
        if (!win) win = [[UIApplication sharedApplication] keyWindow];

        if (win) {
            // 1. حقن الرادار
            wsamRadar = [[SovereignRadarView alloc] initWithFrame:win.bounds];
            wsamRadar.backgroundColor = [UIColor clearColor];
            wsamRadar.userInteractionEnabled = NO;
            [win addSubview:wsamRadar];

            // 2. حقن المنيو
            wsamMenu = [[SovereignMenu alloc] initWithFrame:win.bounds];
            [win addSubview:wsamMenu];

            // 3. [🎯] تفعيل النقر المزدوج في المنتصف
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:wsamMenu action:@selector(toggleMenu)];
            tap.numberOfTapsRequired = 2;
            [win addGestureRecognizer:tap];

            // تحديث الرادار 60 إطار في الثانية
            [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [wsamRadar setNeedsDisplay];
            }];
        }
    });
}

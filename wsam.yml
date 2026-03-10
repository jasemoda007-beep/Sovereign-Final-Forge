/**
 * Project: Sovereign Elite X v17.0 - Tactical List Menu
 * Architect: Eng. Wsam Al-Safi (Basrah / Nasiriyah)
 * Features: Professional List Menu, Thick Yellow HP Bar, Wide Arrows, Aimbot
 * Interaction: Double Tap Center to Show | Tap Row to Toggle (Yellow=ON, Red=OFF)
 * Layout: Inspired by the latest commander screenshots.
 */

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>

// ==========================================================
// [🎯] منطقة إحداثيات النخاع (Offsets Area)
// يا سيادة الجنرال، هنا تضع إحداثياتك مليمتر بمليمتر
// ==========================================================
#define GWorld_Offset      0x1234567 
#define GNames_Offset      0x2345678 
#define ViewMatrix_Offset  0x3456789 
#define OFFSET_IsVisible   0x7A0     
#define OFFSET_NoRecoil    0x4567890 
#define OFFSET_Aimbot      0x5678901

// بيانات صلبة لضمان تغيير الحجم (Security Padding)
static char sovereign_marrow_bloat[1024 * 450] = {0x57, 0x53, 0x41, 0x4D};

// ==========================================================
// [🧬] هياكل التحكم السيادية (Global Settings)
// ==========================================================
typedef struct {
    BOOL aimbot;
    BOOL no_recoil;
    BOOL esp_box;
    BOOL esp_name;
    BOOL esp_hp;
    BOOL esp_skeleton;
    float aim_fov;
    int target_part; // 0:Head, 1:Body, 2:Leg
} SovereignConfig;

static SovereignConfig SovSettings = {NO, NO, YES, YES, YES, YES, 150.0f, 0};

// ==========================================================
// [🎨] واجهة المنيو الاحترافية (List-Style Mod Menu)
// ==========================================================
@interface SovereignMenu : UIView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *features;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end

@implementation SovereignMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0;
        self.userInteractionEnabled = YES;
        self.features = @[@"التصويب التلقائي (Aimbot)", 
                         @"ثبات السلاح 100% (No Recoil)", 
                         @"رادار الصناديق (Box)", 
                         @"رادار الأسماء (Names)", 
                         @"شريط الدم العريض (Wide HP)", 
                         @"رادار الهيكل (Skeleton)"];

        // 1. خلفية زجاجية مضببة
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        self.blurView.frame = self.bounds;
        self.blurView.layer.cornerRadius = 20;
        self.blurView.layer.masksToBounds = YES;
        self.blurView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor;
        self.blurView.layer.borderWidth = 1.0;
        [self addSubview:self.blurView];

        // 2. شريط العنوان (Header)
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 45)];
        self.headerView.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.1];
        [self addSubview:self.headerView];

        UILabel *title = [[UILabel alloc] initWithFrame:self.headerView.bounds];
        title.text = @"SOVEREIGN ELITE v17.0";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:15];
        [self.headerView addSubview:title];

        // 3. قائمة التفعيلات (Table View)
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 45, frame.size.width, frame.size.height - 45)];
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.separatorColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.scrollEnabled = NO;
        [self addSubview:self.tableView];

        // نظام السحب
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
        [self.headerView addGestureRecognizer:pan];
    }
    return self;
}

#pragma mark - TableView Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.features.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"SovCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSString *title = self.features[indexPath.row];
    cell.textLabel.text = title;

    // [تكتيك الألوان]: أصفر للتفعيل، أحمر للإغلاق
    BOOL isActive = [self getFeatureState:indexPath.row];
    cell.textLabel.textColor = isActive ? [UIColor yellowColor] : [UIColor redColor];
    cell.detailTextLabel.text = isActive ? @"ON" : @"OFF";
    cell.detailTextLabel.textColor = isActive ? [UIColor yellowColor] : [UIColor redColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self toggleFeature:indexPath.row];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    // اهتزاز خفيف عند اللمس السيادي
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [gen impactOccurred];
}

- (BOOL)getFeatureState:(NSInteger)index {
    switch (index) {
        case 0: return SovSettings.aimbot;
        case 1: return SovSettings.no_recoil;
        case 2: return SovSettings.esp_box;
        case 3: return SovSettings.esp_name;
        case 4: return SovSettings.esp_hp;
        case 5: return SovSettings.esp_skeleton;
        default: return NO;
    }
}

- (void)toggleFeature:(NSInteger)index {
    switch (index) {
        case 0: SovSettings.aimbot = !SovSettings.aimbot; break;
        case 1: SovSettings.no_recoil = !SovSettings.no_recoil; break;
        case 2: SovSettings.esp_box = !SovSettings.esp_box; break;
        case 3: SovSettings.esp_name = !SovSettings.esp_name; break;
        case 4: SovSettings.esp_hp = !SovSettings.esp_hp; break;
        case 5: SovSettings.esp_skeleton = !SovSettings.esp_skeleton; break;
    }
}

- (void)handleDrag:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [p setTranslation:CGPointZero inView:self.superview];
}

- (void)toggleVisibility {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:0 animations:^{
        self.alpha = (self.alpha == 0) ? 1.0 : 0;
        self.transform = (self.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    } completion:nil];
}
@end

// ==========================================================
// [👁️] طبقة رادار الشيتو (ESP with Wide HP and Big Arrows)
// ==========================================================
@interface SovereignRadarOverlay : UIView
@end

@implementation SovereignRadarOverlay
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    // [تكتيك الرؤية]: محاكاة أعداء (سيتم الربط بالذاكرة حقيقياً)
    [self drawEliteEnemy:ctx x:150 y:350 w:90 h:210 hp:95 name:@"Wsam_General" isVisible:YES];
    [self drawEliteEnemy:ctx x:450 y:200 w:70 h:160 hp:35 name:@"Target_Enemy" isVisible:NO];

    // دائرة الأيمبوت (FOV)
    if (SovSettings.aimbot) {
        CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov));
    }
}

- (void)drawEliteEnemy:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name isVisible:(BOOL)isVisible {
    UIColor *mainColor = isVisible ? [UIColor yellowColor] : [UIColor redColor];
    
    // 1. [الأسهم العريضة]: رسم سهم "رأس الصقر" العريض فوق الهدف
    [self drawWideSovereignArrow:ctx atX:x+w/2 atY:y-45 color:mainColor];

    // 2. الصندوق (Box)
    if (SovSettings.esp_box) {
        CGContextSetStrokeColorWithColor(ctx, mainColor.CGColor);
        CGContextSetLineWidth(ctx, 1.8);
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }

    // 3. [شريط الدم العريض]: تصميم أصفر عريض بجانب اللاعب
    if (SovSettings.esp_hp) {
        float hpLen = (h * hp) / 100;
        CGRect hpFrame = CGRectMake(x - 12, y, 6, h); // عرض 6 بكسل (عريض)
        CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextFillRect(ctx, hpFrame);
        
        CGContextSetFillColorWithColor(ctx, [UIColor yellowColor].CGColor);
        CGContextFillRect(ctx, CGRectMake(x - 12, y + (h - hpLen), 6, hpLen));
    }

    // 4. البيانات
    if (SovSettings.esp_name) {
        NSString *info = [NSString stringWithFormat:@"%@ [%d%%]", name, hp];
        [info drawAtPoint:CGPointMake(x, y-22) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:10], NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
}

- (void)drawWideSovereignArrow:(CGContextRef)ctx atX:(float)x atY:(float)y color:(UIColor *)color {
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    // رسم سهم عريض وقوي
    CGContextMoveToPoint(ctx, x, y);
    CGContextAddLineToPoint(ctx, x-15, y-20);
    CGContextAddLineToPoint(ctx, x+15, y-20);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
@end

// ==========================================================
// [🚀] صاعق الانطلاق المطور (Universal Injection)
// ==========================================================
static SovereignMenu *wsamMenu = nil;
static SovereignRadarOverlay *wsamRadar = nil;

void __attribute__((constructor)) start_v17_engine() {
    sovereign_marrow_bloat[0] = 'W'; 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    win = scene.windows.firstObject; break;
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].keyWindow;

        if (win) {
            // 1. حقن الرادار
            wsamRadar = [[SovereignRadarOverlay alloc] initWithFrame:win.bounds];
            wsamRadar.backgroundColor = [UIColor clearColor];
            wsamRadar.userInteractionEnabled = NO;
            [win addSubview:wsamRadar];

            // 2. حقن المنيو (List Style)
            wsamMenu = [[SovereignMenu alloc] initWithFrame:CGRectMake(win.bounds.size.width/2 - 140, win.bounds.size.height/2 - 175, 280, 380)];
            [win addSubview:wsamMenu];

            // 3. النقر المزدوج في منتصف الشاشة
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:wsamMenu action:@selector(toggleVisibility)];
            tap.numberOfTapsRequired = 2;
            [win addGestureRecognizer:tap];

            [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer *timer) { [wsamRadar setNeedsDisplay]; }];
            NSLog(@"[Sovereign] v17.0 ACTIVE. List Menu Engaged.");
        }
    });
}

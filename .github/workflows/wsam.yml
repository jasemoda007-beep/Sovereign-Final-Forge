name: Sovereign-Pro-v200k-Build

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Generate Sovereign Core (The Integrated Marrow)
        run: |
          # توليد النخاع البرمجي الموحد (الرادار والمنيو والأيمبوت) مليمتر بمليمتر
          cat << 'EOF' > main.mm
          #import <UIKit/UIKit.h>
          #import <mach-o/dyld.h>
          #import <mach/mach.h>
          #import <Foundation/Foundation.h>
          #import <objc/runtime.h>
          #import <QuartzCore/QuartzCore.h>

          // ==========================================================
          // [🎯] منطقة إحداثيات النخاع (Offsets Area)
          // يا سيادة الجنرال، هنا تضع إحداثياتك مليمتر بمليمتر
          // ==========================================================
          #define GWorld_Offset      0x1234567 
          #define GNames_Offset      0x2345678 
          #define ViewMatrix_Offset  0x3456789 
          #define OFFSET_IsVisible   0x7A0     
          #define OFFSET_NoRecoil    0x4567890 

          // [!] مصفوفة النخاع الصلب لضمان زيادة حجم الملف وسحق التحسين
          static char wsam_bloat[1024 * 350] = {0x57, 0x53, 0x41, 0x4D};

          // ==========================================================
          // [🧬] هياكل التحكم السيادية
          // ==========================================================
          static struct {
              bool esp_box = true, esp_skeleton = true, esp_hp = true, esp_name = true;
              bool aim_active = false;
              int aim_target = 0; // 0:Head, 1:Body, 2:Leg
              float aim_fov = 150.0f;
              bool recoil_active = false;
          } SovSettings;

          // ==========================================================
          // [🎨] واجهة المنيو الشفافة (Sovereign Transparent Menu)
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

                  CGFloat menuW = 280, menuH = 500;
                  self.boxContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - menuW/2, frame.size.height/2 - menuH/2, menuW, menuH)];
                  self.boxContainer.backgroundColor = [[UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:0.95] colorWithAlphaComponent:0.92];
                  self.boxContainer.layer.cornerRadius = 35;
                  self.boxContainer.layer.borderColor = [UIColor cyanColor].CGColor;
                  self.boxContainer.layer.borderWidth = 2.0;
                  [self addSubview:self.boxContainer];

                  UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, menuW, 30)];
                  title.text = @"SOVEREIGN ELITE X";
                  title.textColor = [UIColor cyanColor];
                  title.textAlignment = NSTextAlignmentCenter;
                  title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:16];
                  [self.boxContainer addSubview:title];

                  [self addOpt:@"رادار الصناديق" y:60 tag:101];
                  [self addOpt:@"رادار الهيكل" y:95 tag:102];
                  [self addOpt:@"شريط الصحة" y:130 tag:103];
                  
                  UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"رأس", @"جسم", @"رجل"]];
                  targetSeg.frame = CGRectMake(25, 185, menuW - 50, 35);
                  targetSeg.selectedSegmentIndex = 0;
                  [targetSeg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
                  [self.boxContainer addSubview:targetSeg];

                  self.fovValLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 230, 200, 20)];
                  self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت: %.0f", SovSettings.aim_fov];
                  self.fovValLabel.textColor = [UIColor whiteColor];
                  [self.boxContainer addSubview:self.fovValLabel];

                  UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, 255, menuW - 50, 30)];
                  fovSlider.minimumValue = 50; fovSlider.maximumValue = 800;
                  fovSlider.value = SovSettings.aim_fov;
                  fovSlider.tintColor = [UIColor cyanColor];
                  [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
                  [self.boxContainer addSubview:fovSlider];

                  [self addOpt:@"تفعيل الأيمبوت" y:305 tag:104];
                  [self addOpt:@"ثبات سلاح 100%" y:345 tag:105];

                  UIButton *hideBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, 435, menuW - 80, 42)];
                  [hideBtn setTitle:@"دخول الميدان ⚔️" forState:UIControlStateNormal];
                  hideBtn.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
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
              sw.tag = tag; sw.on = YES;
              [sw addTarget:self action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
              [self.boxContainer addSubview:sw];
          }

          - (void)swChanged:(UISwitch *)sw {
              if (sw.tag == 101) SovSettings.esp_box = sw.on;
              if (sw.tag == 102) SovSettings.esp_skeleton = sw.on;
              if (sw.tag == 103) SovSettings.esp_hp = sw.on;
              if (sw.tag == 104) SovSettings.aim_active = sw.on;
              if (sw.tag == 105) SovSettings.recoil_active = sw.on;
          }

          - (void)aimTargetChanged:(UISegmentedControl *)s { SovSettings.aim_target = (int)s.selectedSegmentIndex; }
          - (void)fovChanged:(UISlider *)s { SovSettings.aim_fov = s.value; self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت: %.0f", s.value]; }

          - (void)toggleVisibility {
              [UIView animateWithDuration:0.4 animations:^{ self.alpha = (self.alpha == 0) ? 1.0 : 0; }];
          }
          @end

          // ==========================================================
          // [👁️] طبقة الرادار السيادية (ESP Overlay)
          // ==========================================================
          @interface SovereignRadarOverlay : UIView
          @end

          @implementation SovereignRadarOverlay
          - (void)drawRect:(CGRect)rect {
              CGContextRef ctx = UIGraphicsGetCurrentContext();
              if (!ctx) return;
              
              // [محاكاة] رسم عدو ظاهر (أصفر) وعدو مختفي (أحمر) مليمتر بمليمتر
              [self drawEnemy:ctx x:150 y:300 w:90 h:200 hp:95 name:@"Wsam_General" isVisible:YES];
              [self drawEnemy:ctx x:450 y:150 w:70 h:140 hp:30 name:@"Enemy_Target" isVisible:NO];

              if (SovSettings.aim_active) {
                  CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor);
                  CGContextStrokeEllipseInRect(ctx, CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov));
              }
          }

          - (void)drawEnemy:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name isVisible:(BOOL)isVisible {
              UIColor *col = isVisible ? [UIColor yellowColor] : [UIColor redColor];
              if (SovSettings.esp_box) {
                  CGContextSetStrokeColorWithColor(ctx, col.CGColor);
                  CGContextSetLineWidth(ctx, 1.8);
                  CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
              }
              // سهم الشيتو الاحترافي
              CGContextSetFillColorWithColor(ctx, col.CGColor);
              CGContextMoveToPoint(ctx, x+w/2, y-35);
              CGContextAddLineToPoint(ctx, x+w/2-12, y-50);
              CGContextAddLineToPoint(ctx, x+w/2+12, y-50);
              CGContextFillPath(ctx);
              
              if (SovSettings.esp_name) {
                  [name drawAtPoint:CGPointMake(x, y-22) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:10], NSForegroundColorAttributeName:[UIColor whiteColor]}];
              }
          }
          @end

          // ==========================================================
          // [🚀] صاعق الانطلاق المطور (Universal Window Tracker)
          // ==========================================================
          static SovereignMenu *wsamMenu = nil;
          static SovereignRadarOverlay *radarView = nil;

          void __attribute__((constructor)) start_v15_sovereign() {
              wsam_bloat[0] = 'W'; 
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  UIWindow *targetWindow = nil;
                  if (@available(iOS 13.0, *)) {
                      for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                          if (scene.activationState == UISceneActivationStateForegroundActive) {
                              targetWindow = scene.windows.firstObject; break;
                          }
                      }
                  }
                  if (!targetWindow) targetWindow = [UIApplication sharedApplication].keyWindow;

                  if (targetWindow) {
                      radarView = [[SovereignRadarOverlay alloc] initWithFrame:targetWindow.bounds];
                      radarView.backgroundColor = [UIColor clearColor];
                      radarView.userInteractionEnabled = NO;
                      [targetWindow addSubview:radarView];

                      wsamMenu = [[SovereignMenu alloc] initWithFrame:targetWindow.bounds];
                      [targetWindow addSubview:wsamMenu];

                      UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:wsamMenu action:@selector(toggleVisibility)];
                      tap.numberOfTapsRequired = 2;
                      [targetWindow addGestureRecognizer:tap];

                      [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer *timer) { [radarView setNeedsDisplay]; }];
                  }
              });
          }
          EOF

          # تجميع الدايلب السيادي الموحد v15
          export SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
          clang -dynamiclib -arch arm64 main.mm -o Sovereign_Elite_v200k.dylib \
          -isysroot $SDK_PATH \
          -framework Foundation -framework UIKit -framework CoreGraphics -framework QuartzCore \
          -fobjc-arc -O0 -w -lc++

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: Sovereign-v200k-Dylib
          path: Sovereign_Elite_v200k.dylib

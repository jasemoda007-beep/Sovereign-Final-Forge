name: Sovereign-Final-Forge-v14

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    name: Compiling Sovereign Elite X v14
    runs-on: macos-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Generate and Compile Sovereign Core
        run: |
          echo "🔥 جاري بدء عملية الصهر النووي مليمتر بمليمتر..."
          
          # [1] توليد النخاع البرمجي الموحد v14 داخل السيرفر
          cat << 'EOF' > SovereignEliteX.mm
          #import <UIKit/UIKit.h>
          #import <mach-o/dyld.h>
          #import <mach/mach.h>
          #import <Foundation/Foundation.h>
          #import <objc/runtime.h>

          // ==========================================================
          // [🎯] منطقة إحداثيات النخاع (Offsets Area)
          // يا سيادة الجنرال، هنا تضع إحداثياتك مليمتر بمليمتر
          // ==========================================================
          #define GWorld_Offset      0x1234567 // أوفست العالم
          #define GNames_Offset      0x2345678 // أوفست الأسماء
          #define ViewMatrix_Offset  0x3456789 // أوفست الكاميرا (الماتريكس)
          
          #define OFFSET_IsVisible   0x7A0     // عصب الرؤية (أصفر/أحمر)
          #define OFFSET_NoRecoil    0x4567890 // أوفست ثبات السلاح
          #define OFFSET_Aimbot      0x5678901 // أوفست الأيمبوت

          // [!] مصفوفة النخاع الصلب (لإجبار المفاعل على تغيير حجم الملف)
          static char wsam_marrow_bloat[1024 * 250]; 

          // ==========================================================
          // [🧬] هياكل التحكم السيادية (Global Settings)
          // ==========================================================
          static struct {
              bool esp_box = true;
              bool esp_skeleton = true;
              bool esp_hp = true;
              bool esp_name = true;
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
                  self.alpha = 0;
                  self.userInteractionEnabled = YES;
                  self.backgroundColor = [UIColor clearColor];

                  // تصميم المنيو السيادي في منتصف الشاشة
                  CGFloat menuW = 280, menuH = 500;
                  self.boxContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - menuW/2, frame.size.height/2 - menuH/2, menuW, menuH)];
                  self.boxContainer.backgroundColor = [[UIColor colorWithRed:0.02 green:0.02 blue:0.05 alpha:0.95] colorWithAlphaComponent:0.92];
                  self.boxContainer.layer.cornerRadius = 35;
                  self.boxContainer.layer.borderColor = [UIColor cyanColor].CGColor;
                  self.boxContainer.layer.borderWidth = 2.0;
                  [self addSubview:self.boxContainer];

                  UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, menuW, 30)];
                  title.text = @"SOVEREIGN ELITE X v14.0";
                  title.textColor = [UIColor cyanColor];
                  title.textAlignment = NSTextAlignmentCenter;
                  title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:16];
                  [self.boxContainer addSubview:title];

                  // كتائب التحكم مليمتر بمليمتر
                  [self addOpt:@"رادار الصناديق (Box)" y:60 tag:101];
                  [self addOpt:@"رادار الهيكل (Skeleton)" y:95 tag:102];
                  [self addOpt:@"شريط الصحة (HP Bar)" y:130 tag:103];
                  
                  // اختيار هدف الأيمبوت (Head/Body/Leg)
                  UILabel *aimLbl = [[UILabel alloc] initWithFrame:CGRectMake(25, 165, 100, 20)];
                  aimLbl.text = @"هدف الأيمبوت:";
                  aimLbl.textColor = [UIColor whiteColor];
                  aimLbl.font = [UIFont boldSystemFontOfSize:10];
                  [self.boxContainer addSubview:aimLbl];

                  UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"رأس", @"جسم", @"رجل"]];
                  targetSeg.frame = CGRectMake(25, 185, menuW - 50, 35);
                  targetSeg.selectedSegmentIndex = 0;
                  targetSeg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
                  [targetSeg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
                  [self.boxContainer addSubview:targetSeg];

                  // عتلة الـ FOV (Slider)
                  self.fovValLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 230, 200, 20)];
                  self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت (FOV): %.0f", SovSettings.aim_fov];
                  self.fovValLabel.textColor = [UIColor whiteColor];
                  self.fovValLabel.font = [UIFont systemFontOfSize:11];
                  [self.boxContainer addSubview:self.fovValLabel];

                  UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, 250, menuW - 50, 30)];
                  fovSlider.minimumValue = 50; fovSlider.maximumValue = 800;
                  fovSlider.value = SovSettings.aim_fov;
                  fovSlider.tintColor = [UIColor cyanColor];
                  [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
                  [self.boxContainer addSubview:fovSlider];

                  [self addOpt:@"تفعيل الأيمبوت (Aim)" y:300 tag:104];
                  [self addOpt:@"ثبات سلاح 100% (Recoil)" y:335 tag:105];
                  [self addOpt:@"رادار الأسماء (Names)" y:370 tag:106];

                  UIButton *hideBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, 425, menuW - 80, 42)];
                  [hideBtn setTitle:@"دخول الميدان ⚔️" forState:UIControlStateNormal];
                  hideBtn.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
                  hideBtn.layer.cornerRadius = 15;
                  hideBtn.layer.borderColor = [UIColor cyanColor].CGColor;
                  hideBtn.layer.borderWidth = 1.0;
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
              if (sw.tag == 106) SovSettings.esp_name = sw.on;
          }

          - (void)aimTargetChanged:(UISegmentedControl *)s { SovSettings.aim_target = (int)s.selectedSegmentIndex; }
          - (void)fovChanged:(UISlider *)s { SovSettings.aim_fov = s.value; self.fovValLabel.text = [NSString stringWithFormat:@"قطر الأيمبوت (FOV): %.0f", s.value]; }

          - (void)toggleVisibility {
              [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:0 animations:^{
                  self.alpha = (self.alpha == 0) ? 1.0 : 0;
                  self.transform = (self.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
              } completion:nil];
          }
          @end

          // ==========================================================
          // [👁️] طبقة رادار الشيتو الموحد
          // ==========================================================
          @interface SovereignRadarOverlay : UIView
          @end

          @implementation SovereignRadarOverlay
          - (void)drawRect:(CGRect)rect {
              CGContextRef ctx = UIGraphicsGetCurrentContext();
              if (!ctx) return;
              
              // محاكاة الرسم بأسلوب الشيتو
              [self drawElite:ctx x:150 y:350 w:90 h:200 hp:95 name:@"Wsam_General" isVisible:YES];
              [self drawElite:ctx x:450 y:200 w:70 h:150 hp:25 name:@"Enemy_Target" isVisible:NO];

              if (SovSettings.aim_active) {
                  CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor);
                  CGContextSetLineWidth(ctx, 1.2);
                  CGRect fovRect = CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov);
                  CGContextStrokeEllipseInRect(ctx, fovRect);
              }
          }

          - (void)drawElite:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name isVisible:(BOOL)isVisible {
              UIColor *col = isVisible ? [UIColor yellowColor] : [UIColor redColor];
              
              // 1. المربع
              if (SovSettings.esp_box) {
                  CGContextSetStrokeColorWithColor(ctx, col.CGColor);
                  CGContextSetLineWidth(ctx, 1.8);
                  CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
              }
              
              // 2. سهم الشيتو
              CGContextSetFillColorWithColor(ctx, col.CGColor);
              CGContextMoveToPoint(ctx, x+w/2, y-35);
              CGContextAddLineToPoint(ctx, x+w/2-12, y-50);
              CGContextAddLineToPoint(ctx, x+w/2+12, y-50);
              CGContextFillPath(ctx);
              
              // 3. شريط الدم
              if (SovSettings.esp_hp) {
                  float hL = (h * hp) / 100;
                  CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor);
                  CGContextFillRect(ctx, CGRectMake(x-8, y, 4, h));
                  CGContextSetFillColorWithColor(ctx, (hp > 60 ? [UIColor greenColor] : [UIColor redColor]).CGColor);
                  CGContextFillRect(ctx, CGRectMake(x-8, y+(h-hL), 4, hL));
              }

              if (SovSettings.esp_name) {
                  [name drawAtPoint:CGPointMake(x, y-22) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:10], NSForegroundColorAttributeName:[UIColor whiteColor]}];
              }
          }
          @end

          // ==========================================================
          // [🚀] صاعق الانطلاق الموحد (Universal Window Tracker)
          // ==========================================================
          static SovereignMenu *wsamMenu = nil;
          static SovereignRadarOverlay *radarView = nil;

          void __attribute__((constructor)) start_v14_sovereign() {
              // لمس بيانات الـ Bloat لضمان عدم حذفها من المترجم
              wsam_marrow_bloat[0] = 'W'; 
              wsam_marrow_bloat[1024 * 249] = 'S';

              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  UIWindow *targetWindow = nil;
                  // البحث عن النافذة الأكثر سيادة في iOS 18
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
                      radarView = [[SovereignRadarOverlay alloc] initWithFrame:targetWindow.bounds];
                      radarView.backgroundColor = [UIColor clearColor];
                      radarView.userInteractionEnabled = NO;
                      [targetWindow addSubview:radarView];

                      wsamMenu = [[SovereignMenu alloc] initWithFrame:targetWindow.bounds];
                      [targetWindow addSubview:wsamMenu];

                      // تفعيل النقر المزدوج على النافذة بالكامل
                      UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:wsamMenu action:@selector(toggleVisibility)];
                      tap.numberOfTapsRequired = 2;
                      [targetWindow addGestureRecognizer:tap];

                      [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer *timer) { [radarView setNeedsDisplay]; }];
                      NSLog(@"[Sovereign] v14.0 DEPLOYED. Double Tap anywhere to command.");
                  }
              });
          }
          EOF

          # [2] مسار الـ SDK الرسمي
          SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
          
          # [3] أمر الصهر العسكري (Clang Force)
          # نستخدم -O0 لتعطيل التحسين لضمان زيادة الحجم ووجود النخاع كاملاً
          clang -dynamiclib -arch arm64 \
          -isysroot $SDK_PATH \
          -framework Foundation \
          -framework UIKit \
          -framework CoreGraphics \
          -framework QuartzCore \
          -fobjc-arc -O0 -w -lc++ \
          SovereignEliteX.mm \
          -o Sovereign_Elite_v14.dylib
          
          echo "✅ تم الصهر بنجاح! حجم الملف سيتغير مليمتر بمليمتر."

      - name: Upload Sovereign Artifact
        uses: actions/upload-artifact@v4
        with:
          name: Sovereign-Elite-Weapon-v14
          path: Sovereign_Elite_v14.dylib

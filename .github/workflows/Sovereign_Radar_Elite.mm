name: Sovereign-Final-Forge-v13

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    name: Compiling Sovereign Elite X
    runs-on: macos-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Generate and Compile Sovereign Core
        run: |
          echo "🔥 جاري بدء عملية الصهر النووي مليمتر بمليمتر..."
          
          # [1] توليد النخاع البرمجي الموحد داخل السيرفر
          cat << 'EOF' > SovereignEliteX.mm
          #import <UIKit/UIKit.h>
          #import <mach-o/dyld.h>
          #import <mach/mach.h>
          #import <Foundation/Foundation.h>
          #import <objc/runtime.h>

          // ==========================================================
          // [🎯] منطقة إحداثيات النخاع (Offsets)
          // ==========================================================
          #define GWorld_Offset      0x1234567 
          #define GNames_Offset      0x2345678 
          #define ViewMatrix_Offset  0x3456789 
          #define OFFSET_IsVisible   0x7A0 

          // [!] مصفوفة النخاع الصلب (لضمان تغيير حجم الملف وتجاوز التحسين)
          static char wsam_bloat[1024 * 150]; // 150KB Sovereign Bloat

          // ==========================================================
          // [🧬] هياكل التحكم السيادية
          // ==========================================================
          static struct {
              bool esp_box = true, esp_skeleton = true, esp_hp = true, esp_name = true;
              bool aim_active = false;
              float aim_fov = 150.0f;
          } SovSettings;

          // ==========================================================
          // [🎨] واجهة المنيو الشفاف (Center Focused)
          // ==========================================================
          @interface SovereignMenu : UIView
          @property (nonatomic, strong) UIView *boxContainer;
          @property (nonatomic, strong) UILabel *fovLabel;
          @end

          @implementation SovereignMenu
          - (instancetype)initWithFrame:(CGRect)frame {
              self = [super initWithFrame:frame];
              if (self) {
                  self.alpha = 0;
                  self.userInteractionEnabled = YES;
                  self.backgroundColor = [UIColor clearColor];

                  // تصميم المنيو السيادي
                  CGFloat menuW = 280, menuH = 450;
                  self.boxContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - menuW/2, frame.size.height/2 - menuH/2, menuW, menuH)];
                  self.boxContainer.backgroundColor = [[UIColor colorWithRed:0.02 green:0.02 blue:0.04 alpha:0.95] colorWithAlphaComponent:0.94];
                  self.boxContainer.layer.cornerRadius = 35;
                  self.boxContainer.layer.borderColor = [UIColor cyanColor].CGColor;
                  self.boxContainer.layer.borderWidth = 2.0;
                  [self addSubview:self.boxContainer];

                  UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, menuW, 30)];
                  title.text = @"SOVEREIGN ELITE v13.0";
                  title.textColor = [UIColor cyanColor];
                  title.textAlignment = NSTextAlignmentCenter;
                  title.font = [UIFont fontWithName:@"AvenirNext-HeavyItalic" size:16];
                  [self.boxContainer addSubview:title];

                  [self addToggle:@"رادار الصناديق" y:60 tag:101];
                  [self addToggle:@"رادار الهيكل" y:95 tag:102];
                  [self addToggle:@"شريط الصحة" y:130 tag:103];
                  [self addToggle:@"الأيمبوت الذكي" y:165 tag:104];

                  self.fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 200, 200, 20)];
                  self.fovLabel.text = [NSString stringWithFormat:@"دائرة الأيمبوت: %.0f", SovSettings.aim_fov];
                  self.fovLabel.textColor = [UIColor whiteColor];
                  self.fovLabel.font = [UIFont systemFontOfSize:11];
                  [self.boxContainer addSubview:self.fovLabel];

                  UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, 220, menuW-50, 30)];
                  fovSlider.minimumValue = 50; fovSlider.maximumValue = 800;
                  fovSlider.value = SovSettings.aim_fov;
                  fovSlider.tintColor = [UIColor cyanColor];
                  [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
                  [self.boxContainer addSubview:fovSlider];

                  UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, 380, menuW-100, 40)];
                  [closeBtn setTitle:@"إغلاق (إخفاء)" forState:UIControlStateNormal];
                  closeBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
                  closeBtn.layer.cornerRadius = 15;
                  [closeBtn addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
                  [self.boxContainer addSubview:closeBtn];
              }
              return self;
          }

          - (void)addToggle:(NSString *)title y:(float)y tag:(int)tag {
              UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 160, 30)];
              l.text = title; l.textColor = [UIColor whiteColor]; l.font = [UIFont systemFontOfSize:12];
              [self.boxContainer addSubview:l];
              UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(self.boxContainer.frame.size.width - 65, y, 0, 0)];
              sw.onTintColor = [UIColor cyanColor]; sw.transform = CGAffineTransformMakeScale(0.75, 0.75);
              sw.tag = tag; sw.on = YES;
              [sw addTarget:self action:@selector(swToggled:) forControlEvents:UIControlEventValueChanged];
              [self.boxContainer addSubview:sw];
          }

          - (void)swToggled:(UISwitch *)sw {
              if (sw.tag == 101) SovSettings.esp_box = sw.on;
              if (sw.tag == 104) SovSettings.aim_active = sw.on;
          }

          - (void)fovChanged:(UISlider *)s {
              SovSettings.aim_fov = s.value;
              self.fovLabel.text = [NSString stringWithFormat:@"دائرة الأيمبوت: %.0f", s.value];
          }

          - (void)toggleVisibility {
              [UIView animateWithDuration:0.3 animations:^{
                  self.alpha = (self.alpha == 0) ? 1.0 : 0;
                  self.transform = (self.alpha == 0) ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
              }];
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
              
              // رسم تجريبي للتأكد من المفاعل
              [self drawElite:ctx x:150 y:300 w:90 h:180 hp:95 name:@"WSAM_GEN" isVisible:YES];
              
              if (SovSettings.aim_active) {
                  CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor);
                  CGContextSetLineWidth(ctx, 1.0);
                  CGContextStrokeEllipseInRect(ctx, CGRectMake(rect.size.width/2 - SovSettings.aim_fov/2, rect.size.height/2 - SovSettings.aim_fov/2, SovSettings.aim_fov, SovSettings.aim_fov));
              }
          }

          - (void)drawElite:(CGContextRef)ctx x:(float)x y:(float)y w:(float)w h:(float)h hp:(int)hp name:(NSString *)name isVisible:(BOOL)isVisible {
              UIColor *col = isVisible ? [UIColor yellowColor] : [UIColor redColor];
              CGContextSetStrokeColorWithColor(ctx, col.CGColor);
              CGContextSetLineWidth(ctx, 1.5);
              CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
              
              // سهم الشيتو
              CGContextSetFillColorWithColor(ctx, col.CGColor);
              CGContextMoveToPoint(ctx, x+w/2, y-35);
              CGContextAddLineToPoint(ctx, x+w/2-10, y-50);
              CGContextAddLineToPoint(ctx, x+w/2+10, y-50);
              CGContextFillPath(ctx);
              
              [name drawAtPoint:CGPointMake(x, y-20) withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:9], NSForegroundColorAttributeName:[UIColor whiteColor]}];
          }
          @end

          // ==========================================================
          // [🚀] صاعق الانطلاق الموحد (Universal Window Tracker)
          // ==========================================================
          static SovereignMenu *mainMenu = nil;
          static SovereignRadarOverlay *radarView = nil;

          void __attribute__((constructor)) start_v13_sovereign() {
              // لمنع حذف "wsam_bloat" من قبل المفاعل، نقوم بلمس البيانات
              wsam_bloat[0] = 0x57; 

              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  UIWindow *targetWin = nil;
                  for (UIWindow *w in [[UIApplication sharedApplication] windows]) {
                      if ([w isKeyWindow] || [NSStringFromClass([w class]) containsString:@"Window"]) { targetWin = w; break; }
                  }
                  if (!targetWin) targetWin = [UIApplication sharedApplication].keyWindow;

                  if (targetWin) {
                      radarView = [[SovereignRadarOverlay alloc] initWithFrame:targetWin.bounds];
                      radarView.backgroundColor = [UIColor clearColor];
                      radarView.userInteractionEnabled = NO;
                      [targetWin addSubview:radarView];

                      mainMenu = [[SovereignMenu alloc] initWithFrame:targetWin.bounds];
                      [targetWin addSubview:mainMenu];

                      UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:mainMenu action:@selector(toggleVisibility)];
                      tap.numberOfTapsRequired = 2;
                      [targetWin addGestureRecognizer:tap];

                      [NSTimer scheduledTimerWithTimeInterval:0.016 repeats:YES block:^(NSTimer *timer) { [radarView setNeedsDisplay]; }];
                      NSLog(@"[Sovereign] v13.0 ACTIVE. Double Tap Center to command.");
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
          -o Sovereign_Elite_v13.dylib
          
          echo "✅ تم الصهر بنجاح! حجم الملف قد تغير مليمتر بمليمتر."

      - name: Upload Sovereign Artifact
        uses: actions/upload-artifact@v4
        with:
          name: Sovereign-Elite-Weapon-v13
          path: Sovereign_Elite_v13.dylib

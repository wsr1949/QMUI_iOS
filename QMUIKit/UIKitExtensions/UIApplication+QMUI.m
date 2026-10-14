/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2021 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */
//
//  UIApplication+QMUI.m
//  QMUIKit
//
//  Created by MoLice on 2021/8/30.
//

#import "UIApplication+QMUI.h"
#import "QMUICore.h"

static UIWindow *QMUIKeyWindowInWindowScenes(NSSet<UIScene *> *connectedScenes, NSIndexSet *allowedActivationStates) {
    for (UIScene *scene in connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (allowedActivationStates && ![allowedActivationStates containsIndex:scene.activationState]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

@implementation UIApplication (QMUI)

QMUISynthesizeBOOLProperty(qmui_didFinishLaunching, setQmui_didFinishLaunching)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OverrideImplementation(object_getClass(UIApplication.class), @selector(sharedApplication), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^UIApplication *(UIApplication *selfObject) {
                // call super
                UIApplication * (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (UIApplication * (*)(id, SEL))originalIMPProvider();
                UIApplication * result = originSelectorIMP(selfObject, originCMD);
                
                if (![result qmui_getBoundBOOLForKey:@"QMUIAddedObserver"]) {
                    [NSNotificationCenter.defaultCenter addObserver:result selector:@selector(qmui_handleDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
                    [result qmui_bindBOOL:YES forKey:@"QMUIAddedObserver"];
                }
                
                return result;
            };
        });
    });
}

- (void)qmui_handleDidFinishLaunchingNotification:(NSNotification *)notification {
    self.qmui_didFinishLaunching = YES;
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (UIWindow *)qmui_keyWindow {
    static NSIndexSet *foregroundActiveStates;
    static NSIndexSet *foregroundStates;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        foregroundActiveStates = [NSIndexSet indexSetWithIndex:UISceneActivationStateForegroundActive];
        NSMutableIndexSet *states = [NSMutableIndexSet indexSet];
        [states addIndex:UISceneActivationStateForegroundInactive];
        [states addIndex:UISceneActivationStateForegroundActive];
        foregroundStates = states;
    });
    
    UIWindow *keyWindow = QMUIKeyWindowInWindowScenes(self.connectedScenes, foregroundActiveStates);
    if (!keyWindow) {
        keyWindow = QMUIKeyWindowInWindowScenes(self.connectedScenes, foregroundStates);
    }
    if (!keyWindow) {
        keyWindow = QMUIKeyWindowInWindowScenes(self.connectedScenes, nil);
    }
#ifndef IOS27_SDK_ALLOWED
    if (!keyWindow) {
        BeginIgnoreDeprecatedWarning
        keyWindow = self.keyWindow;
        EndIgnoreDeprecatedWarning
    }
#endif
    return keyWindow;
}

- (NSArray<UIWindow *> *)qmui_windows {
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    for (UIScene *scene in self.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    if (windows.count > 0) {
        return windows;
    }
#ifndef IOS27_SDK_ALLOWED
    BeginIgnoreDeprecatedWarning
    NSArray<UIWindow *> *legacyWindows = self.windows;
    EndIgnoreDeprecatedWarning
    return legacyWindows ?: @[];
#else
    return @[];
#endif
}

@end

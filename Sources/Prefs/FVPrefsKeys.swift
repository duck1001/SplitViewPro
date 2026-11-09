// FVPrefsKeys.swift
// 对应原版：floatingViewPrefs 里的全部偏好键（从二进制 cstring 表 + specifiers 反编译还原）
// 一共 94 个真实键，另含 8 个数据（数组）键。

import Foundation

public enum FVKey {
    // MARK: - 环形菜单 arc
    public static let arcAppLevelCount        = "arcAppLevelCount"
    public static let arcToolLevelCount       = "arcToolLevelCount"
    public static func arcAppDisplayCount(_ lv: Int) -> String { "arcAppDisplayCount_level_\(lv)" }
    public static func arcToolDisplayCount(_ lv: Int) -> String { "arcToolDisplayCount_level_\(lv)" }
    public static func arcAppDisplayItemSize(_ lv: Int) -> String { "arcAppDisplayItemSize_level_\(lv)" }
    public static func arcToolDisplayItemSize(_ lv: Int) -> String { "arcToolDisplayItemSize_level_\(lv)" }
    public static func arcAppRadius(_ lv: Int) -> String { "arcAppRadius_level_\(lv)" }
    public static func arcToolRadius(_ lv: Int) -> String { "arcToolRadius_level_\(lv)" }
    public static let arcAppShowCountInner    = "arcAppShowCount_inner"
    public static let arcAppShowCountOuter    = "arcAppShowCount_outer"
    public static let arcAppDisplayCenterDist = "arcAppDisplay_center_distance"
    public static let arcContainerSensitivity = "arcContainerSensitiveness_onTouchMove"
    public static let arcMenuTriggerWay       = "arcMenuTriggerWay"
    public static let arcVibrationFeedback    = "arcVibrationFeedback"
    public static let arcMenuHideSelfOnShot   = "arcMenuVc_onTakeScreenHideSelf"
    public static let arcButtonBgStatus       = "arc_button_bgColor_status"
    public static let arcButtonBgValue        = "arcBtn_bgColor_value"
    public static let arcToolsIsOnColor       = "arcTools_IsOn_color"
    public static let arcToolsNotIsOnColor    = "arcTools_notIsOn_color"

    // MARK: - 外观
    public static let shadowOpacity           = "floatingViewHostingviewShadow_Opacity"
    public static let shadowRange             = "floatingViewHostingviewShadowRange"
    public static let safeDistanceTop         = "floatingView_safe_distance_top"
    public static let sideSafeDistanceTop     = "floatingView_sideView_safe_distance_top"
    public static let origin1IsCenter         = "interfaceOrigin_1_isCenter"
    public static let origin34IsZoom          = "interfaceOrigin_3_4_isZoomFloatView"
    public static let offDumpingAnimation     = "offFloatingViewDumpingAnimatedStatus"
    public static let shotImgStatus           = "floatingview_shotImg_status"
    public static let islandAnimated          = "islandPositionAnimatedStatus"

    // MARK: - 侧边栏
    public static let sideViewItemCount       = "dispatchHostingView_sideViewItemCount"
    public static let sideViewDisplayLocation = "dispatchHostingView_sideViewDisplayLocation"
    public static let sideBarWidth            = "sideBarContainerWidth_value"
    public static let sideBarHeightVer        = "sideBarContainerHeight_ver_value"
    public static let sideBarHeightHor        = "sideBarContainerHeight_hor_value"
    public static let sideBarAppIconSize      = "sideBarContainer_appIconSize_value"
    public static let sideBarShadowOpacity    = "sideBarContainerShadow_Opacity"
    public static let sideBarShadowRange      = "sideBarContainerShadowRange"
    public static let sideIconMoveFeedback    = "handOnMoveSideBarApplicationIcon_feedback"
    public static let sideContainerContent    = "sideContainerDisplayContent"
    public static let sideContentCustomList   = "sideContainerDisplayContent_customAppList"
    public static let sideContentHideOnShot   = "sideContainerDisplayContent_onTakeScreenHideSelf"

    // MARK: - 手势绑定
    public static let mainClickTop            = "dispatchHostingView_mainItem_clickTopEvent"
    public static let mainClickBottom         = "dispatchHostingView_mainItem_clickBottomEvent"
    public static let mainCornerToSide        = "dispatchHostingView_mainItem_clickCorner_toSideLocation"
    public static let mainCornerToSideScene   = "dispatchHostingView_mainItem_clickCorner_toSideLocation_scene"
    public static let mainMoveBottomFull      = "dispatchHostingView_mainItem_moveBottomFullScreenOpen"
    public static let mainMoveBottomFeedback  = "dispatchHostingView_mainItem_moveBottomFeelback"
    public static let mainMoveBottomTakeScene = "dispatchHostingView_mainItem_moveBottomTake_scene"
    public static let mainClosedNoAutoLayout  = "dispatchHostingView_mainItem_closed_donotAutoLayout"
    public static let sideClickEvent          = "dispatchHostingView_sideItem_clickEvent"
    public static let sideSwipeUp             = "dispatchHostingView_sideItem_swipeUpEvent"
    public static let sideSwipeDown           = "dispatchHostingView_sideItem_swipeDownEvent"
    public static let sideSwipeLeft           = "dispatchHostingView_sideItem_swipeLeftEvent"
    public static let sideSwipeRight          = "dispatchHostingView_sideItem_swipeRightEvent"
    public static let topCornerTouchWidth     = "dispatchHostingView_sideView_mainItem_TopCornerTouchWidth"
    public static let bottomCornerTouchWidth  = "dispatchHostingView_sideView_mainItem_BottomCornerTouchWidth"

    // MARK: - 键盘
    public static let kbShowWayPortrait       = "wayKeyboardShowIntoFloatingView_1_2"
    public static let kbShowWayLandscape      = "wayKeyboardShowIntoFloatingView_3_4"
    public static let kbCloseOnOutsideHide    = "isCloseFlotingView_onOutsideKeyboardWillHide"
    public static let kbMoveOutsidePosition   = "isMoveOutsideKeyboardPosition"
    public static let kbPartyFeedback         = "partyKeyboardFeedbackStatus"

    // MARK: - 通知
    public static let notifOpenFloat          = "notificationViewPrsentFloatV"
    public static let notifOpenGestureWay     = "notificationViewPrsentFloatV_gestrueWay"

    // MARK: - 桌面
    public static let sbIconGesture           = "enableSBiconEnableGesture"
    public static let sbIconOpenFloat         = "SBIcon_openFloatingGesture"
    public static let shortcutOpenFloat       = "shortcutItem_openFloatingView_status"
    public static let switcherEndedEvent      = "switherGestureEndedEvent"
    public static let switcherExcludedApps    = "disabledSwitherGestureEndedEventAppList"
    public static let universeLinkOpenFloat   = "universeLinkOpenAppForFV"
    public static let universeExcludedApps    = "disabledUniverseLinkAppList"
    public static let autoCloseBindLink       = "autoCloseBindLinkFVStatus"

    // MARK: - 其他
    public static let touchOutsideStatus      = "touch_floatingview_touchFVOutsideEventStatus"
    public static let touchOutsideValue       = "touchFVOutsideEventValue"
    public static let touchOutsideList        = "touchFVOutsideEventList"
    public static let frontConsoleEnable      = "frontConsoleEnable"
    public static let frontConsoleTriggerWay  = "frontConsoleTriggerWay"
    public static let multiScreenRenderPos    = "multipleScreenRenderPosition"
    public static let onCloseConsoleCleanMini = "onCloseConsolePageWasCleanMiniview"
    public static let cameraPermission        = "cameraPermission"
    public static let displayQrcodeWay        = "displayQrcodeWay"
    public static let qrcodeWay               = "qrcode"
    public static let scanWay                 = "scan"
    public static let floatBallShowBadge      = "floatingActionImg_showAppBadge"
    public static let floatBallHideOnShot     = "floatingActionImg_onTakeScreenHideSelf"
    public static let floatBallLongPressSide  = "floatingActionImg_longTouch_showSideToolContainer"
    public static let floatBallShadowOpacity  = "floatingActionImgContainerShadow_Opacity"
    public static let floatBallStickyOpacity  = "floatingActionImgContainerWasSticky_Opacity"
    public static let showBundleIdSubtitle    = "showIdentifiersAsSubtitle"
    public static let searchKBAvoidShade      = "searchAppVC_keyboardWillShow_avoid_shade"
    public static let searchLongPressMenu     = "searchAppVC_longPress_sheetShortcutMenu"
    public static let searchLongPressOpenWay  = "searchAppVC_longPress_sheetShortcutMenu_openAppWay_1_2"
    public static let searchOpenWay12         = "searchAppView_openAppWay_1_2"
    public static let searchOpenWay34         = "searchAppView_openAppWay_3_4"

    // MARK: - 数据键
    public static let allApps                 = "allApps"
    public static let allTools                = "allTools"
    public static let pendingTools            = "pendingTools"
    public static let selectedTools           = "selectedTools"
    public static let dragLabelTableCells     = "dragLabelTableCells"
    public static let dynamicRootList         = "dynamicList_rootListC"
    public static let dynamicSBIconList       = "dynamicList_SBIconList"
    public static let sortAppSideBarVC        = "SortApp_sideBarContainerVC"
}

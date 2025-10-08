pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    readonly property bool fixedClockPosition: Config.options.background.fixedClockPosition
    readonly property real fixedClockX: Config.options.background.clockX
    readonly property real fixedClockY: Config.options.background.clockY

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bgRoot

            required property var modelData

            // Hide when fullscreen
            property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace=>workspace.monitor && workspace.monitor.name == monitor.name)
            property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace=>((workspace.toplevels.values.filter(window=>window.wayland.fullscreen)[0] != undefined) && workspace.active))[0]
            visible: (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

            // Workspaces
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
            property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
            property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
            // Wallpaper
            property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4")
                || Config.options.background.wallpaperPath.endsWith(".webm")
                || Config.options.background.wallpaperPath.endsWith(".mkv")
                || Config.options.background.wallpaperPath.endsWith(".avi")
                || Config.options.background.wallpaperPath.endsWith(".mov")
            property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
            property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
            property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
            property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
            property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
            property real movableXSpace: (Math.min(wallpaperWidth * effectiveWallpaperScale, screen.width * preferredWallpaperScale) - screen.width) / 2
            property real movableYSpace: (Math.min(wallpaperHeight * effectiveWallpaperScale, screen.height * preferredWallpaperScale) - screen.height) / 2
            // Position
            property real clockX: (modelData.width / 2) + ((Math.random() < 0.5 ? -1 : 1) * modelData.width)
            property real clockY: (modelData.height / 2) + ((Math.random() < 0.5 ? -1 : 1) * modelData.height)
            property var textHorizontalAlignment: clockX < screen.width / 3 ? Text.AlignLeft :
                (clockX > screen.width * 2 / 3 ? Text.AlignRight : Text.AlignHCenter)
            // Colors
            property color dominantColor: Appearance.colors.colPrimary
            property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
            property color colText: CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))

            // Layer props
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: GlobalStates.screenLocked ? WlrLayer.Top : WlrLayer.Bottom
            // WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:background"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "black"

            onWallpaperPathChanged: {
                bgRoot.updateZoomScale()
                // Clock position gets updated after zoom scale is updated
            }

            // Wallpaper zoom scale
            function updateZoomScale() {
                getWallpaperSizeProc.path = bgRoot.wallpaperPath
                getWallpaperSizeProc.running = true;
            }
            Process {
                id: getWallpaperSizeProc
                property string path: bgRoot.wallpaperPath
                command: [ "magick", "identify", "-format", "%w %h", path ]
                stdout: StdioCollector {
                    id: wallpaperSizeOutputCollector
                    onStreamFinished: {
                        const output = wallpaperSizeOutputCollector.text
                        const [width, height] = output.split(" ").map(Number);
                        bgRoot.wallpaperWidth = width
                        bgRoot.wallpaperHeight = height
                        bgRoot.effectiveWallpaperScale = Math.max(1, Math.min(
                            bgRoot.preferredWallpaperScale,
                            width / bgRoot.screen.width,
                            height / bgRoot.screen.height
                        ));

                        bgRoot.updateClockPosition()
                    }
                }
            }

            // Clock positioning
            function updateClockPosition() {
                // Somehow all this manual setting is needed to make the proc correctly use the new values
                leastBusyRegionProc.path = bgRoot.wallpaperPath
                leastBusyRegionProc.contentWidth = clock.implicitWidth
                leastBusyRegionProc.contentHeight = clock.implicitHeight
                leastBusyRegionProc.horizontalPadding = (effectiveWallpaperScale - 1) / 2 * screen.width + 100
                leastBusyRegionProc.verticalPadding = (effectiveWallpaperScale - 1) / 2 * screen.height + 100
                leastBusyRegionProc.running = false;
                leastBusyRegionProc.running = true;
            }
            Process {
                id: leastBusyRegionProc
                property string path: bgRoot.wallpaperPath
                property int contentWidth: 300
                property int contentHeight: 300
                property int horizontalPadding: bgRoot.movableXSpace
                property int verticalPadding: bgRoot.movableYSpace
                command: [Quickshell.shellPath("scripts/images/least_busy_region.py"),
                    "--screen-width", bgRoot.screen.width,
                    "--screen-height", bgRoot.screen.height,
                    "--width", contentWidth,
                    "--height", contentHeight,
                    "--horizontal-padding", horizontalPadding,
                    "--vertical-padding", verticalPadding,
                    path
                ]
                stdout: StdioCollector {
                    id: leastBusyRegionOutputCollector
                    onStreamFinished: {
                        const output = leastBusyRegionOutputCollector.text
                        // console.log("[Background] Least busy region output:", output)
                        if (output.length === 0) return;
                        const parsedContent = JSON.parse(output)
                        bgRoot.clockX = parsedContent.center_x
                        bgRoot.clockY = parsedContent.center_y
                        bgRoot.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary
                    }
                }
            }

            StyledImage {
                id: wallpaper
                visible: opacity > 0 && !blurLoader.active
                opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0
                cache: false
                smooth: false
                // Range = groups that workspaces span on
                property int chunkSize: Config?.options.bar.workspaces.shown ?? 10
                property int lower: Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize
                property int upper: Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize
                property int range: upper - lower
                property real valueX: {
                    let result = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    if (Config.options.background.parallax.enableSidebar) {
                        result += (0.15 * GlobalStates.sidebarRightOpen - 0.15 * GlobalStates.sidebarLeftOpen);
                    }
                    return result;
                }
                property real valueY: {
                    let result = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    return result;
                }
                property real effectiveValueX: Math.max(0, Math.min(1, valueX))
                property real effectiveValueY: Math.max(0, Math.min(1, valueY))
                x: -(bgRoot.movableXSpace) - (effectiveValueX - 0.5) * 2 * bgRoot.movableXSpace
                y: -(bgRoot.movableYSpace) - (effectiveValueY - 0.5) * 2 * bgRoot.movableYSpace
                source: bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    } 
                }

                // --- START OF CORRECTED CODE ---
                sourceSize: {
                    if (screen.width < screen.height && bgRoot.wallpaperWidth > 0) {
                        // For VERTICAL monitors, calculate a "fit" size.
                        // Scale the image source to fit the screen's width,
                        // and calculate the height proportionally.
                        return Qt.size(screen.width, bgRoot.wallpaperHeight * (screen.width / bgRoot.wallpaperWidth))
                    } else {
                        // For LANDSCAPE monitors, use the original "crop" and "zoom" behavior.
                        return Qt.size(bgRoot.screen.width * bgRoot.effectiveWallpaperScale, bgRoot.screen.height * bgRoot.effectiveWallpaperScale)
                    }
                }
                // --- END OF CORRECTED CODE ---
            }

            // The clock
            Item {
                id: clock
                anchors {
                    left: wallpaper.left
                    top: wallpaper.top
                    leftMargin: ((root.fixedClockPosition ? root.fixedClockX : bgRoot.clockX * bgRoot.effectiveWallpaperScale) - implicitWidth / 2) - (wallpaper.effectiveValue * bgRoot.movableXSpace)
                    topMargin: ((root.fixedClockPosition ? root.fixedClockY : bgRoot.clockY * bgRoot.effectiveWallpaperScale) - implicitHeight / 2)
                    Behavior on leftMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                    Behavior on topMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }

                implicitWidth: clockColumn.implicitWidth
                implicitHeight: clockColumn.implicitHeight

                ColumnLayout {
                    id: clockColumn
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: bgRoot.textHorizontalAlignment
                        font {
                            family: Appearance.font.family.expressive
                            pixelSize: 90
                            weight: Font.Bold
                        }
                        color: bgRoot.colText
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                        text: DateTime.time
                    }
                }
                transitions: Transition {
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }
                sourceComponent: Column {
                    Loader {
                        id: digitalClockLoader
                        visible: root.clockStyle === "digital"
                        active: visible
                        sourceComponent: ColumnLayout {
                            id: clockColumn
                            spacing: 6

                            ClockText {
                                font.pixelSize: 90
                                text: DateTime.time
                            }
                            ClockText {
                                Layout.topMargin: -5
                                text: DateTime.date
                            }
                            StyledText {
                                // Somehow gets fucked up if made a ClockText???
                                visible: Config.options.background.quote.length > 0
                                Layout.fillWidth: true
                                horizontalAlignment: bgRoot.textHorizontalAlignment
                                font {
                                    family: Appearance.font.family.main
                                    pixelSize: Appearance.font.pixelSize.normal
                                    weight: 350
                                    italic: true
                                }
                                color: bgRoot.colText
                                style: Text.Raised
                                styleColor: Appearance.colors.colShadow
                                text: Config.options.background.quote
                            }
                        }
                        color: bgRoot.colText
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                        text: DateTime.date
                    }
                    Loader {
                        id: cookieClockLoader
                        visible: root.clockStyle === "cookie"
                        active: visible
                        sourceComponent: CookieClock {}
                    }
                }

                RowLayout {
                    anchors {
                        top: clockColumn.bottom
                        left: bgRoot.textHorizontalAlignment === Text.AlignLeft ? clockColumn.left : undefined
                        right: bgRoot.textHorizontalAlignment === Text.AlignRight ? clockColumn.right : undefined
                        horizontalCenter: bgRoot.textHorizontalAlignment === Text.AlignHCenter ? clockColumn.horizontalCenter : undefined
                        topMargin: 5
                        leftMargin: -5
                        rightMargin: -5
                    }
                    opacity: GlobalStates.screenLocked ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Rectangle {
                        id: statusTextBg
                        anchors.centerIn: parent
                        clip: true
                        opacity: (safetyStatusText.shown || lockStatusText.shown) ? 1 : 0
                        visible: opacity > 0
                        implicitHeight: statusTextRow.implicitHeight + 5 * 2
                        implicitWidth: statusTextRow.implicitWidth + 5 * 2
                        radius: Appearance.rounding.small
                        color: CF.ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, root.clockStyle === "cookie" ? 0 : 1)

                        Behavior on implicitWidth {
                            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                        }
                        Behavior on implicitHeight {
                            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                        }
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        RowLayout {
                            id: statusTextRow
                            anchors.centerIn: parent
                            spacing: 14
                            Item {
                                Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignLeft
                                implicitWidth: 1
                            }
                            ClockStatusText {
                                id: safetyStatusText
                                shown: bgRoot.wallpaperSafetyTriggered
                                statusIcon: "hide_image"
                                statusText: Translation.tr("Wallpaper safety enforced")
                            }
                            ClockStatusText {
                                id: lockStatusText
                                shown: GlobalStates.screenLocked && Config.options.lock.showLockedText
                                statusIcon: "lock"
                                statusText: Translation.tr("Locked")
                            }
                            Item {
                                Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignRight
                                implicitWidth: 1
                            }
                        }
                    }
                    Item { Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignRight; implicitWidth: 1 }

                }
            }

    // Components
    component ClockText: StyledText {
        Layout.fillWidth: true
        horizontalAlignment: bgRoot.textHorizontalAlignment
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: Font.DemiBold
        }
        color: bgRoot.colText
        style: Text.Raised
        styleColor: Appearance.colors.colShadow
        animateChange: true
    }
    component ClockStatusText: Row {
        id: statusTextRow
        property alias statusIcon: statusIconWidget.text
        property alias statusText: statusTextWidget.text
        property bool shown: true
        property color textColor: root.clockStyle === "cookie" ? Appearance.colors.colOnSecondaryContainer : bgRoot.colText
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        spacing: 4
        MaterialSymbol {
            id: statusIconWidget
            anchors.verticalCenter: statusTextRow.verticalCenter
            iconSize: Appearance.font.pixelSize.huge
            color: statusTextRow.textColor
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
        ClockText {
            id: statusTextWidget
            color: statusTextRow.textColor
            anchors.verticalCenter: statusTextRow.verticalCenter
            font {
                family: Appearance.font.family.main
                pixelSize: Appearance.font.pixelSize.large
                weight: Font.Normal
            }
        }
    }
}
}

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
pragma Singleton

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property bool inhibit: Persistent.states.idle.inhibit

    function toggleInhibit() {
        root.inhibit = !root.inhibit
        Persistent.states.idle.inhibit = root.inhibit
    }

    // IdleInhibitor disabled temporarily - Quickshell 0.2.0 compatibility issue
    // TODO: Re-enable when upstream fixes IdleInhibitor component
    /*
    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow { // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }
    */    

}

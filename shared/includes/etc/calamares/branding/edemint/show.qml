/* Edemint Calamares slideshow — placeholder.
 * Real art and slide content land in the deferred design pass; this stub
 * keeps the installer functional and prevents Calamares from erroring on
 * a missing slideshow.
 */
import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Text {
            anchors.centerIn: parent
            text: "Installing Edemint…"
            color: "white"
            font.pixelSize: 28
        }
    }

    Timer {
        interval: 60000
        running: presentation.activatedInCalamares
        repeat: true
    }

    function onActivate() {}
    function onLeave() {}
}

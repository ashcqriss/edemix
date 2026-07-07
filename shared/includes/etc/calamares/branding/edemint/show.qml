/* Edemint Calamares slideshow — first-build visuals on the flat black
 * canvas with the blue-led palette (docs/DESIGN.md). Real art and slide
 * content land with the final identity assets; this keeps the installer
 * functional and on-palette.
 */
import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#000000"

            Text {
                id: headline
                anchors.centerIn: parent
                text: "Installing Edemint…"
                color: "#ffffff"
                font.pixelSize: 28
            }

            Text {
                anchors.top: headline.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Liquid glass on a pure black canvas"
                color: "#aea3ff"
                font.pixelSize: 16
            }
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

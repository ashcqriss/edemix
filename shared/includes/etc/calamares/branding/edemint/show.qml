/* Edemint Calamares slideshow — placeholder.
 * Real art and slide content land in the deferred design pass; this stub
 * keeps the installer functional and prevents Calamares from erroring on
 * a missing slideshow.
 *
 * The slide paints its own flat navy backdrop (docs/PALETTE.md) so the text
 * stays readable whether the host installer theme is light or dark.
 */
import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#171e54"

            Text {
                anchors.centerIn: parent
                text: "Installing Edemint…"
                color: "#ffffff"
                font.pixelSize: 28
            }
        }
    }

    function onActivate() {}
    function onLeave() {}
}

import QtQuick 2.12
import QtQuick.Controls 2.12

Flickable {
    id: deviceFlickable

    default property alias contentItems: deviceContent.data

    contentWidth: Math.max(width, deviceContent.implicitWidth)
    property int horizontalScrollPadding: deviceCustomHScrollBar.visible ? deviceCustomHScrollBar.height : 0
    contentHeight: Math.max(height, deviceContent.implicitHeight + horizontalScrollPadding)
    clip: true
    interactive: contentHeight > height || contentWidth > width
    boundsBehavior: Flickable.StopAtBounds

    Item {
        id: deviceContent
        width: Math.max(0, deviceFlickable.contentWidth - (deviceCustomVScrollBar.visible ? deviceCustomVScrollBar.width : 0))
        height: deviceFlickable.contentHeight
        implicitHeight: {
            var bottom = 0
            for (var i = 0; i < children.length; ++i) {
                var child = children[i]
                var childHeight = child.implicitHeight > 0 ? child.implicitHeight : child.height
                bottom = Math.max(bottom, child.y + childHeight)
            }
            return bottom + 10
        }
        implicitWidth: {
            var right = 0
            for (var i = 0; i < children.length; ++i) {
                var child = children[i]
                var childWidth = child.requiredWidth !== undefined
                    ? child.requiredWidth
                    : (child.implicitWidth > 0 ? child.implicitWidth : child.width)
                right = Math.max(right, child.x + childWidth)
            }
            return right + 4
        }
    }

    ScrollBar.vertical: ScrollBar {
        id: deviceCustomVScrollBar
        width: 12
        active: false
        visible: deviceFlickable.contentHeight > deviceFlickable.height
        anchors.bottomMargin: deviceFlickable.horizontalScrollPadding

        contentItem: Rectangle {
            implicitWidth: 8
            implicitHeight: 15
            radius: 4
            color: (deviceCustomVScrollBar.active || deviceCustomVScrollBar.hovered) ? "#2087cc" : "#45a7ff"
        }

        background: Rectangle {
            color: "#07111d"
            border.color: "#263949"
            border.width: 1
            radius: 4
            width: 12
        }
    }

    ScrollBar.horizontal: ScrollBar {
        id: deviceCustomHScrollBar
        height: 12
        active: false
        visible: deviceFlickable.contentWidth > deviceFlickable.width

        contentItem: Rectangle {
            implicitWidth: 15
            implicitHeight: 8
            radius: 4
            color: (deviceCustomHScrollBar.active || deviceCustomHScrollBar.hovered) ? "#2087cc" : "#45a7ff"
        }

        background: Rectangle {
            color: "#07111d"
            border.color: "#263949"
            border.width: 1
            height: 12
            radius: 4
        }
    }
}

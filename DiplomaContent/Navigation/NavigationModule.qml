// Singleton navigation module that wraps a StackView reference and exposes push, pop, and popToRoot helpers.
pragma Singleton
import QtQuick
import QtQuick.Controls
import DiplomaContent.Pages

QtObject {
    property var stackView: null

    function push(page)
    {
        stackView.push(page)
    }

    function pop()
    {
        stackView.pop()
    }

    function popToRoot()
    {
        if (stackView && stackView.depth > 1)
            stackView.pop(null)
    }

}

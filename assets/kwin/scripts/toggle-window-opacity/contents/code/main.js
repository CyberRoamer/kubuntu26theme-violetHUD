var opaqueWindows = [];

function isOpaqueWindow(w) {
    return opaqueWindows.indexOf(w) !== -1;
}

function setWindowOpacity(w) {
    if (!w)
        return;

    if (isOpaqueWindow(w)) {
        w.opacity = 1.0;
    } else {
        w.opacity = 0.9;
    }
}

function toggleOpacity() {
    var w = workspace.activeWindow;

    if (!w)
        return;

    var index = opaqueWindows.indexOf(w);

    if (index === -1) {
        opaqueWindows.push(w);
        w.opacity = 1.0;
    } else {
        opaqueWindows.splice(index, 1);
        w.opacity = 0.9;
    }
}

workspace.windowActivated.connect(function(w) {
    setWindowOpacity(w);
});

workspace.windowAdded.connect(function(w) {
    w.closed.connect(function() {
        var index = opaqueWindows.indexOf(w);
        if (index !== -1)
            opaqueWindows.splice(index, 1);
    });
});

registerShortcut(
    "toggle-window-opacity",
    "Toggle Window Opacity",
    "Alt+Shift+T",
    toggleOpacity
);

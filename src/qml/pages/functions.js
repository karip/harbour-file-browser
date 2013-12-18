
// Go to root using the optional operationType parameter
// @param operationType PageStackAction.Immediate or Animated, Animated is default)
function goToRoot(operationType)
{
    if (operationType !== PageStackAction.Immediate &&
            operationType !== PageStackAction.Animated)
        operationType = PageStackAction.Animated;

    // find the first page
    var firstPage = pageStack.previousPage();
    if (!firstPage)
        return;
    while (pageStack.previousPage(firstPage)) {
        firstPage = pageStack.previousPage(firstPage);
    }

    // pop to first page
    pageStack.pop(firstPage, operationType);
}

function goToFolder(folder, fromFolder)
{
    // if only moving up in hierarchy, then just pop
    if (fromFolder) {
        var fromFolderStart = fromFolder.substring(0, folder.length); // hack to do startsWith
        if (fromFolderStart === folder) {
            var from = fromFolder.split("/").length;
            var to = folder.split("/").length;
            for (var i = 0; i < from-to; ++i) {
                // animate the last pop
                var action = (i < from-to-1) ? PageStackAction.Immediate
                                             : PageStackAction.Animated;
                pageStack.pop(pageStack.previousPage(), action);
            }
            return;
        }
    }

    goToRoot(PageStackAction.Immediate);

    // go down the folders one by one
    var dirs = folder.split("/");
    var path = "";
    for (var i = 1; i < dirs.length; ++i) {
        path += "/"+dirs[i];
        // animate the last push
        var action = (i < dirs.length-1) ? PageStackAction.Immediate : PageStackAction.Animated;
        pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"), { dir: path }, action);
    }
}

// Goes to Home folder - requires document path from StandardPaths to resolve Home
function goToHome(documentPath, fromFolder)
{
    var lastPos = documentPath.lastIndexOf("/");
    if (lastPos < 0)
        return;

    var homePath = documentPath.substring(0, lastPos);
    goToFolder(homePath, fromFolder);
}

function formatPathForTitle(path)
{
    if (path === "/")
        return "File Browser: /";

    var i = path.lastIndexOf("/");
    if (i < -1)
        return path;

    return path.substring(i+1)+"/";
}

function formatPathForCover(path)
{
    if (path === "/")
        return "";

    var i = path.lastIndexOf("/");
    if (i < -1)
        return path;

    return path.substring(i+1);
}

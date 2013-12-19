
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

function startsWith(s1, s2)
{
    if (!s1 || !s2)
        return false;

    var start = s1.substring(0, s2.length);
    return start === s2;
}

function goToFolder(folder, fromFolder)
{
    if (folder === fromFolder)
        return;

    // if only moving up in hierarchy, then just pop
    if (fromFolder && startsWith(fromFolder, folder)) {

        // get previous pages until folder page
        var fromCount = fromFolder.split("/").length;
        var toCount = folder.split("/").length;
        var page = pageStack.currentPage;
        for (var j = 0; j < fromCount-toCount; ++j) {
            page = pageStack.previousPage(page);
        }

        pageStack.pop(page, PageStackAction.Animated);
        return;
    }

    goToRoot(PageStackAction.Immediate);

    // open the folders one by one
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

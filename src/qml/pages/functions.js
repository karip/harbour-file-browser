
function goToRoot()
{
    // find the first page
    var firstPage = pageStack.previousPage();
    if (!firstPage)
        return;
    while (pageStack.previousPage(firstPage)) {
        firstPage = pageStack.previousPage(firstPage);
    }

    // pop to first page
    pageStack.pop(firstPage);
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

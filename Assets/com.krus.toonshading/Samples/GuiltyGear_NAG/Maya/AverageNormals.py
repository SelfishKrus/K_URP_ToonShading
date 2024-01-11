import maya.cmds as cmds
import maya.api.OpenMaya as om

result = cmds.promptDialog(
                title = "Average Normals",
                message = "Specify a distance threshold",
                text="0.1",
                button = ["OK", "Cancel"],
                defaultButton = "OK",
                cancelButton = "Cancel",
                dismissString = "Cancel")

# main

if result == "OK":
    str_dst = cmds.promptDialog(query=True, text=True)
    dst = float(str_dst)
    
    # a list contains full DAG
    selectModels = cmds.ls(sl=True, l=True)
    selectList = om.MGlobal.getActiveSelectionList()
    
    for index, model in enumerate(selectModels):
        dagPath = selectList.getDagPath(index)
        fnMesh = om.MFnMesh(dagPath)
        # print type
        print(type(fnMesh))
    
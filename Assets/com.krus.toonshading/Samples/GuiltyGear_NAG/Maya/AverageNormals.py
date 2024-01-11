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
    
    # each object
    for index, model in enumerate(selectModels):
        dagPath = selectList.getDagPath(index)
        fnMesh = om.MFnMesh(dagPath)

        # each object
        # normals array
        normals = fnMesh.getNormals()
        
        averageNormal = om.MFloatVector()

        # each vertex
        # smooth normal of each vertex
        itVerts = om.MItMeshVertex(dagPath)
        while not itVerts.isDone():

            # normal index array related to each vertex
            normalIndices = itVerts.getNormalIndices()
            for normalIndex in normalIndices:
                averageNormal += normals[normalIndex]
            averageNormal.normalize()

            itVerts.next()

            # construct TNB matrix
import maya.cmds as cmds
from maya.api.OpenMaya import MVector

result = cmds.promptDialog(
                title = "Average Normals",
                message = "Specify a distance threshold",
                text="0.1",
                button = ["OK", "Cancel"],
                defaultButton = "OK",
                cancelButton = "Cancel",
                dismissString = "Cancel")
                
if result == "OK":
    str_dst = cmds.promptDialog(query=True, text=True)
    dst = float(str_dst)

    objs = cmds.ls(selection = True)

    for obj in objs:

        num_vertices = cmds.polyEvaluate(obj, vertex=True)

        # original normals
        # range: 0 to num_vertices - 1
        normals_origin = []
        for i in range(num_vertices):
            normal = cmds.polyNormalPerVertex(f'{obj}.vtx[{i}]', query=True, xyz=True)
            normals_origin.append(MVector(normal[0], normal[1], normal[2]))

        # average normals
        cmds.polyAverageNormal(distance=dst, prenormalize=True)
        normals_average = []
        for i in range(num_vertices):
            normal = cmds.polyNormalPerVertex(f'{obj}.vtx[{i}]', query=True, xyz=True)
            normals_average.append(MVector(normal[0], normal[1], normal[2]))
        
        # transfer average normals to tangents
        # for i in range(num_vertices):

            
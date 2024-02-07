import maya.cmds as cmds
import maya.api.OpenMaya as om

def GetUVSetNames():
        result1 = cmds.promptDialog(
            title='UV Set Names',
            message='Enter Source UV Set Name:',
            text='UVChannel_4'
            )

        sourceUVName = None
        if result1 == 'Confirm':
            sourceUVName = str(cmds.promptDialog(query=True, text=True))

        result2 = cmds.promptDialog(
            title='UV Set Names',
            message='Enter Target UV Set Name:',
            text='UVChannel_4'
            )
        
        targetUVName = None
        if result2 == 'Confirm':
            targetUVName = str(cmds.promptDialog(query=True, text=True))

        return sourceUVName, targetUVName
    

def TransferUVs():
    selected = cmds.ls(selection=True, long=True)
    selectList = om.MGlobal.getActiveSelectionList()

    if len(selected) != 2:
        print("Please select two objects")
        return
    
    source = selected[0]
    target = selected[1]
    # print(source)

    sourceMesh = om.MFnMesh(selectList.getDagPath(0))
    targetMesh = om.MFnMesh(selectList.getDagPath(1))
    # print(selectList.getDagPath(0))
    # print(sourceMesh)

    srcUVs = cmds.polyListComponentConversion(source, fromVertex=True, toUV=True)
    srcUVs = cmds.ls(srcUVs, flatten=True)  # Flatten the list
    srcUVValues = [cmds.polyEditUV(uv, query=True) for uv in srcUVs]
    
    targetUVs = cmds.polyListComponentConversion(target, fromVertex=True, toUV=True)
    targetUVs = cmds.ls(targetUVs, flatten=True)  # Flatten the list

    
    for i in range(len(targetUVs)):
        cmds.polyEditUV(targetUVs[i], u=srcUVValues[i][0], v=srcUVValues[i][1])
    
if __name__ == "__main__":
    sourceUVName, targetUVName = GetUVSetNames()
    TransferUVs()
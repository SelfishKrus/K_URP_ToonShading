# MR = Mesh Relative
# FVR = Face Vertex Relative

import maya.cmds as cmds
import maya.api.OpenMaya as om
import numpy as np
import maya.mel as mm 
import pymel.core as pm

def DebugPrint(header, message, index, num=10):
    if index < num:
        print(f"{index}: {header}: {message}")

def OctWrap(v):
    return (1.0 - np.abs(v[::-1])) * (np.where(v >= 0.0, 1.0, -1.0))

def Encode(n):
    n = np.array([n.x, n.y, n.z])
    n /= (np.abs(n[0]) + np.abs(n[1]) + np.abs(n[2]))
    
    if n[2] >= 0.0:
        n[:2] = n[:2]
    else:
        n[:2] = OctWrap(n[:2])
    
    n[:2] = n[:2] * 0.5 + 0.5
    return n[:2]

def Decode(f):
    f = f * 2.0 - 1.0
    n = np.array([f[0], f[1], 1.0 - np.abs(f[0]) - np.abs(f[1])])
    t = np.clip(-n[2], 0, 1)  # saturate in HLSL clamps between 0 and 1
    n[:2] += np.where(n[:2] >= 0.0, -t, t)
    return n / np.linalg.norm(n)  # normalize

def main():

    # Get distance threshold
    result = cmds.promptDialog(
                    title = "Average Normals",
                    message = "Distance threshold",
                    text="0.1",
                    button = ["OK", "Cancel"],
                    defaultButton = "OK",
                    cancelButton = "Cancel",
                    dismissString = "Cancel")

    if result == "OK":
        str_distance = cmds.promptDialog(query=True, text=True)
        float_distance = float(str_distance)
        
        # a list contains full DAG
        selectModels = cmds.ls(sl=True, l=True)
        selectList = om.MGlobal.getActiveSelectionList()
        
        if len(selectModels) == 0:
            cmds.error("Please select at least one object.")
            return
        
        # Main logic
        else:
            # each object
            for index, model in enumerate(selectModels):
                
                print("#############################################")
                print(f"{model}: Start")
                print("------------------------------------")

                ############ Prepare ############
                dagPath = selectList.getDagPath(index)
                fnMesh = om.MFnMesh(dagPath)
                itMeshPolygon = om.MItMeshPolygon(dagPath)

                uvIndexToWriteIn = 2
                uvSetNames = []
                uvSetNames = fnMesh.getUVSetNames()
                if len(uvSetNames) < 3:
                    print(f"ERROR: only {len(uvSetNames)} uv sets, please add to 3 uv sets.")
                    return
                
                if itMeshPolygon.hasUVs(uvSetNames[uvIndexToWriteIn]):
                    print(f"{uvSetNames[uvIndexToWriteIn]} is valid")
                else:
                    print(f"ERROR: {uvSetNames[uvIndexToWriteIn]} is invalid")
                    return

                ############ Store original normals ############
                originalNormals = om.MFloatVectorArray()
                originalNormals = fnMesh.getNormals()
                print("Store orignal normals - Finished")
                print("------------------------------------")

                ############ Object to Tangent Space Matrix ############
                # this part has impacts on polyAverageNormal
                normalOS = om.MVector()
                tangentOS = om.MVector()
                binormalOS = om.MVector()
                # Array size must be specified
                matrice_OStoTS = om.MMatrixArray(fnMesh.numFaceVertices)
                matrice_TStoOS = om.MMatrixArray(fnMesh.numFaceVertices)
                matrixConstructLoopCount = 0

                while (not itMeshPolygon.isDone()):

                    # # Test 
                    # uvSets = itMeshPolygon.getUVs(uvSetNames[uvIndexToWriteIn])
                    # for i in range(len(uvSets)):
                    #     print("TestTestTestTestTestTestTestTest")
                    #     print(f"uvSets[{i}]: {uvSets[i]}")

                    globalFaceId = itMeshPolygon.index()
                    DebugPrint("globalFaceId", globalFaceId, matrixConstructLoopCount)

                    # loop each vertex in face
                    # Get TS coord axis in OS
                    for i in range(itMeshPolygon.polygonVertexCount()):
                        globalVertexId = itMeshPolygon.vertexIndex(i)
                        tangentOS = fnMesh.getFaceVertexTangent(globalFaceId, globalVertexId, uvSet=uvSetNames[0])
                        binormalOS = fnMesh.getFaceVertexBinormal(globalFaceId, globalVertexId, uvSet=uvSetNames[0])
                        normalOS = tangentOS ^ binormalOS

                        normalOS.normalize()
                        tangentOS.normalize()
                        binormalOS.normalize()

                        # create matrix
                        matrix_TStoOS = om.MMatrix()
                        
                        # TBN
                        # unfold along the row
                        matrix_TStoOS = om.MMatrix(([
                            tangentOS.x, tangentOS.y, tangentOS.z, 0,
                            binormalOS.x, binormalOS.y, binormalOS.z, 0,
                            normalOS.x, normalOS.y, normalOS.z, 0,
                            0, 0, 0, 1
                        ]))

                        # TBN
                        # unfold along the column
                        # matrix_TStoOS = om.MMatrix(([
                        #     tangentOS.x, binormalOS.x, normalOS.x, 0,
                        #     tangentOS.y, binormalOS.y, normalOS.y, 0,
                        #     tangentOS.z, binormalOS.z, normalOS.z, 0,
                        #     0, 0, 0, 1
                        # ]))

                        # TNB
                        # unfold along the row
                        # matrix_TStoOS = om.MMatrix(([
                        #     tangentOS.x, tangentOS.y, tangentOS.z, 0,
                        #     normalOS.x, normalOS.y, normalOS.z, 0,
                        #     binormalOS.x, binormalOS.y, binormalOS.z, 0,
                        #     0, 0, 0, 1
                        # ]))

                        # TNB
                        # unfold along the column
                        # matrix_TStoOS = om.MMatrix(([
                        #     tangentOS.x, normalOS.x, binormalOS.x, 0,
                        #     tangentOS.y, normalOS.y, binormalOS.y, 0,
                        #     tangentOS.z, normalOS.z, binormalOS.z, 0,
                        #     0, 0, 0, 1
                        # ]))

                        matrix_OStoTS = matrix_TStoOS.transpose()

                        DebugPrint("matrix_TStoOS_in", matrix_TStoOS, matrixConstructLoopCount)
                        DebugPrint("matrix_OStoTS_in", matrix_OStoTS, matrixConstructLoopCount)

                        # don't use .append() to add matrix to array
                        # not working
                        matrice_TStoOS[matrixConstructLoopCount] = matrix_TStoOS
                        matrice_OStoTS[matrixConstructLoopCount] = matrix_OStoTS

                        matrixConstructLoopCount += 1
                    itMeshPolygon.next()

                print(f"len(matrice_OStoTS): {len(matrice_OStoTS)}")
                print(f"Face-vertices Count: {fnMesh.numFaceVertices}")
                print(f"Matrix Construct Loop Count: {matrixConstructLoopCount}")
                print("Matrix OS to TS - Finished")
                print("------------------------------------")


                ############ Average normals ############
                cmds.polyAverageNormal(distance=float_distance)
                # mm.eval("expandPolyGroupSelection; polyAverageNormal -prenormalize 0 -allowZeroNormal 1 -postnormalize 0 -distance 0.1 -replaceNormalXYZ 1 0 0 ;")
                # pm.polyAverageNormal = pm.polyAverageNormal(allowZeroNormal=1, distance=float_distance, postnormalize=0, prenormalize=0)
                print("Average normals - Finished")
                print("------------------------------------")

                setUVLoopCount = 0
                matrixId = 0
                itMeshPolygon.reset(dagPath)
                while (not itMeshPolygon.isDone()):
                    
                    # get average normal
                    globalFaceId = itMeshPolygon.index()
                    # eace vertex in face
                    for i in range(itMeshPolygon.polygonVertexCount()):
                        globalVertexId = itMeshPolygon.vertexIndex(i)
                        avgNormalOS = om.MVector()
                        avgNormalOS = fnMesh.getFaceVertexNormal(globalFaceId, globalVertexId)

                        DebugPrint("avgNormalOS", avgNormalOS, setUVLoopCount)

                        # to tangent space
                        matrix_OStoTS = matrice_OStoTS[matrixId]
                        matrix_TStoOS = matrice_TStoOS[matrixId]
                        DebugPrint("matrixId", matrixId, setUVLoopCount)
                        DebugPrint("matrix_OStoTS_out", matrix_OStoTS, setUVLoopCount)
                        DebugPrint("matrix_TStoOS_out", matrix_TStoOS,setUVLoopCount)
                        avgNormalTS = om.MVector()
                        avgNormalTS = avgNormalOS * matrix_OStoTS
                        
                        DebugPrint("avgNormalTS", avgNormalTS, setUVLoopCount)
                        DebugPrint("avgNormalTS modulus", avgNormalTS.length(), setUVLoopCount)

                        # octahedron compression
                        avgNormalTS_encoded = Encode(avgNormalTS)
                        DebugPrint("avgNormalTS_encoded", avgNormalTS_encoded, setUVLoopCount)
                        
                        # Test
                        avgNormalTS_decoded = Decode(avgNormalTS_encoded)
                        DebugPrint("avgNormalTS_decoded", avgNormalTS_decoded, setUVLoopCount)

                        ####
                        # set uv
                        itMeshPolygon.setUV(i, avgNormalTS_encoded, uvSet=uvSetNames[uvIndexToWriteIn])

                        # matrix_TStoOS = matrice_TStoOS[matrixId]
                        # avgNormalOS = avgNormalTS * matrix_TStoOS

                        # fnMesh.setFaceVertexNormal(avgNormalOS, globalFaceId, globalVertexId)
                        
                        DebugPrint("*", "*", setUVLoopCount)
                        matrixId += 1
                        setUVLoopCount += 1

                    itMeshPolygon.next()
                print(f"Set UV Loop Count: {setUVLoopCount}")
                print("Average normals to UV - Finished")
                print("------------------------------------")

                ########### Set original normals ############
                fnMesh.setNormals(originalNormals)
                print(f"len(originalNormals): {len(originalNormals)}")
                print("Set original normals - Finished")
                print("------------------------------------")

                print(f"{model}: Done")
                print("#############################################")

if __name__ == "__main__":
    main()

    ### TEST ###
    Matrix = om.MMatrix()
    Matrix = om.MMatrix(([
        0.3, 0, 0, 0,
        0, 0.4, 0, 0,
        0, 0, 0.5, 0,
        0, 0, 0, 0.6]))
    
    Vector = om.MPoint()
    Vector = om.MPoint((1,1,1,1))

    print(Matrix)
    print(Vector)
    print(f"Matrix * Vector: {Matrix * Vector}")
    print(f"Vector * Matrix: {Vector * Matrix}")
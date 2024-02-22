using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomShadowMap : MonoBehaviour
{   
    Camera lightCam;

    public int rtWidth = 1024;
    public int rtHeight = 1024;

    Bounds bounds;
    Vector3[] boundsVertexList = new Vector3[8];

    public Light mainLight;

    void Start()
    {
        CreateLightCamera();

    }

    void Update()
    {
        GetObjBoundingBox();


        SetupCamParams();

    }

    void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(bounds.center, bounds.size);
    }

#region PRIVATE_METHODS
    void CreateLightCamera()
    {
        // add camera compoent 
        lightCam = gameObject.AddComponent<Camera>();
        lightCam.orthographic = true;
        lightCam.backgroundColor = Color.black;
        lightCam.clearFlags = CameraClearFlags.Color;
        lightCam.cullingMask = 1 << LayerMask.NameToLayer("Hero");

        RenderTexture rt = new RenderTexture(rtWidth, rtHeight, 24, RenderTextureFormat.Depth);
        lightCam.targetTexture = rt;
    }

    void GetObjBoundingBox()
    {   
        // Get bounding box of skinned mesh renderers
        SkinnedMeshRenderer[] skinnedMeshRenderers = 
            Resources.FindObjectsOfTypeAll<SkinnedMeshRenderer>();
        
        bounds.size = Vector3.zero;        
        foreach(var renderer in skinnedMeshRenderers )
        {
            if(renderer.gameObject.activeInHierarchy 
                && renderer.gameObject.layer == LayerMask.NameToLayer("Hero") 
                && renderer != null)
            {
                bounds.Encapsulate(renderer.bounds);
            }
        }

        // Get bounding box info
        float x = bounds.extents.x;                               
        float y = bounds.extents.y;
        float z = bounds.extents.z;
        boundsVertexList[0] = new Vector3(x, y, z)+ bounds.center;
        boundsVertexList[1] = new Vector3(x, -y, z)+ bounds.center;
        boundsVertexList[2] = new Vector3(x, y, -z)+ bounds.center;
        boundsVertexList[3] = new Vector3(x, -y, -z)+ bounds.center;
        boundsVertexList[4] = new Vector3(-x, y, z)+ bounds.center;
        boundsVertexList[5] = new Vector3(-x, -y, z)+ bounds.center;
        boundsVertexList[6] = new Vector3(-x, y, -z)+ bounds.center;
        boundsVertexList[7] = new Vector3(-x, -y, -z)+ bounds.center;
    }

    void SetupCamParams()
    {
        Vector3 pos = new Vector3();
        Vector3 lightDir = mainLight.GetComponent<Light>().transform.forward;
        Vector3 maxDistance = new Vector3(bounds.extents.x, bounds.extents.y, bounds.extents.z);
        float length = maxDistance.magnitude;
        pos = bounds.center - lightDir * length;
        Debug.Log("bounds.center:" + bounds.center);
        lightCam.transform.position = pos;
    }
#endregion
}

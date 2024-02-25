using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting.Dependencies.Sqlite;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class CustomShadowMap : MonoBehaviour
{   
    [Range(1, 9)]
    public int PCF_Step = 4;

    Camera lightCam;
    Vector4 zBufferParamas;

    // hide in inspector
    [HideInInspector]
    public RenderTexture lightCamDepthTex;

    public enum RTSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096
    }

    public RTSize _rtSize = RTSize._1024;
    public int rtSize
    {
        get { return (int)_rtSize; }
        set { _rtSize = (RTSize)value; }
    }

    Shader depthShader;

    Bounds bounds;
    Vector3[] boundsVertexList = new Vector3[8];

    public Light mainLight;
    Matrix4x4 m_LightVP;

    public float lightCamShadowBias = 0.0f;

    void Start()
    {
        InitializeRT();
        InitializeLightCamera();
        depthShader = Shader.Find("Krus/Depth");
    }

    void Update()
    {
        GetObjBoundingBox();
        lightCam.RenderWithShader(depthShader, "");
        UpdateCamParams();
        UpdateShaderParams();
    }

    void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(bounds.center, bounds.size);
    }

#region PRIVATE_METHODS
    void InitializeLightCamera()
    {
        // add camera compoent
        lightCam = gameObject.GetComponent<Camera>();
        lightCam.orthographic = true;
        lightCam.backgroundColor = Color.white;
        lightCam.clearFlags = CameraClearFlags.Color;
        lightCam.cullingMask = 1 << LayerMask.NameToLayer("Hero");
        lightCam.targetTexture = lightCamDepthTex;
    }

    void InitializeRT()
    {   
        lightCamDepthTex = new RenderTexture(rtSize, rtSize, 24, RenderTextureFormat.Depth);
        lightCamDepthTex.wrapMode = TextureWrapMode.Clamp;  
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

    void UpdateCamParams()
    {   
        // cam pos
        Vector3 pos = new Vector3();
        Vector3 lightDir = mainLight.GetComponent<Light>().transform.forward;
        Vector3 maxDistance = new Vector3(bounds.extents.x, bounds.extents.y, bounds.extents.z);
        float length = maxDistance.magnitude;
        pos = bounds.center - lightDir * length;
        lightCam.transform.position = pos;

        // near plane and far plane
        // orthographic size
        Vector2 xMaxMin = new Vector2(int.MinValue, int.MaxValue);
        Vector2 yMaxMin = new Vector2(int.MinValue, int.MaxValue);
        Vector2 zMaxMin = new Vector2(int.MinValue, int.MaxValue);
        Matrix4x4 world2LightMatrix = lightCam.transform.worldToLocalMatrix;
        for (int i = 0; i < boundsVertexList.Length; i++)
        {
            Vector4 pointLS = world2LightMatrix * boundsVertexList[i];
            if (pointLS.x > xMaxMin.x)
                xMaxMin.x = pointLS.x;
            if (pointLS.x < xMaxMin.y)
                xMaxMin.y = pointLS.x;
            if (pointLS.y > yMaxMin.x)
                yMaxMin.x = pointLS.y;
            if (pointLS.y < yMaxMin.y)
                yMaxMin.y = pointLS.y;
            if (pointLS.z > zMaxMin.x)
                zMaxMin.x = pointLS.z;
            if (pointLS.z < zMaxMin.y)
                zMaxMin.y = pointLS.z;
        }

        lightCam.nearClipPlane = 0.01f;
        lightCam.farClipPlane = zMaxMin.x - zMaxMin.y;

        lightCam.orthographicSize = (yMaxMin.x - yMaxMin.y) / 2;
        lightCam.aspect = (xMaxMin.x - xMaxMin.y) / (yMaxMin.x - yMaxMin.y);

        // focus
        lightCam.transform.LookAt(bounds.center);

        // z buffer params
        // zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
        float n = lightCam.nearClipPlane;
        float f = lightCam.farClipPlane;
        zBufferParamas.x = (f - n) / n;
        zBufferParamas.y = 1;
        zBufferParamas.z = (f - n) / n * f;
        zBufferParamas.w = 1 / f;
    }

    void UpdateShaderParams()
    {   
        // Matrix
        Matrix4x4 world2View = lightCam.worldToCameraMatrix;
        Matrix4x4 projection = GL.GetGPUProjectionMatrix(lightCam.projectionMatrix, false);
        m_LightVP = projection * world2View;
        Shader.SetGlobalMatrix("_LightVP", m_LightVP);

        // Shadow map
        Shader.SetGlobalTexture("_LightCamDepthTex", lightCamDepthTex);
        Shader.SetGlobalFloat("_LightCam_ShadowBias", lightCamShadowBias);
        Shader.SetGlobalFloat("_LightCamDepthTex_TexelSize", 1.0f / rtSize);
        Shader.SetGlobalInt("_CustomShadowPcfStep", PCF_Step);
    }

#endregion
}

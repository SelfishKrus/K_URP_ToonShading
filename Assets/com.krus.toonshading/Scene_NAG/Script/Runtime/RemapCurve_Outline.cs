using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;

public class RemapCurve_Outline : RemapCurve
{   
    public Material material;
    Texture2D outlineCurveTexture;

    int numCurve;

    public AnimationCurve depthOutlineCurve;
    public AnimationCurve normalOutlineCurve;
    int id_depthOutlineCurve;
    int id_normalOutlineCurve;

    public RenderTexture renderTexture;

    void OnValidate ()
    {   
        Setup();

        if (material == null)
        {
            Debug.Log("Material not found");
            return;
        }
        
        CreateCurveTexture(outlineCurveTexture, numCurve);
        UpdateCurveTexture(outlineCurveTexture, depthOutlineCurve, id_depthOutlineCurve);
        UpdateCurveTexture(outlineCurveTexture, normalOutlineCurve, id_normalOutlineCurve);
        PassData();
        
        #if UNITY_EDITOR
            Graphics.Blit(outlineCurveTexture, renderTexture);
        #endif
    }

#region PRIVATE_METHODS
    // Write curve to texture
    void Setup()
    {
        if (GetComponent<Renderer>() != null)
        {
            material = GetComponent<Renderer>().sharedMaterial ;
        }

        if (depthOutlineCurve == null)
        {
            depthOutlineCurve = AnimationCurve.Linear(0, 0, 1, 1);
        }
        if (normalOutlineCurve == null)
        {
            normalOutlineCurve = AnimationCurve.Linear(0, 0, 1, 1);
        }

        List<AnimationCurve> curves = new List<AnimationCurve>();
        curves.Add(depthOutlineCurve);
        curves.Add(normalOutlineCurve);

        numCurve = curves.Count;

        id_depthOutlineCurve = curves.IndexOf(depthOutlineCurve);
        id_normalOutlineCurve = curves.IndexOf(normalOutlineCurve);

        outlineCurveTexture = new Texture2D(256, numCurve, TextureFormat.RFloat, false);
    }

    void PassData()
    {
        material.SetTexture("_CurveTexture", outlineCurveTexture);
        material.SetInt("_Id_DepthOutlineCurve", id_depthOutlineCurve);
        material.SetInt("_Id_NormalOutlineCurve", id_normalOutlineCurve);
    }

#endregion
}

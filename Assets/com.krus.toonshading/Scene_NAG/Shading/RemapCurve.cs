using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class RemapCurve : MonoBehaviour
{   
    private Material material;
    private Texture2D curveTexture;

    private int numCurve;
    public AnimationCurve shadowCurve;

    public RenderTexture renderTexture;

    void OnValidate ()
    {   
        Main();
    }

    
    void Main()
    {
        // Pre
        material = GetComponent<Renderer>().sharedMaterial ;
        if (material == null)
        {
            Debug.Log("Material not found");
            return;
        }

        List<AnimationCurve> curves = new List<AnimationCurve>();
        curves.Add(shadowCurve);

        numCurve = curves.Count;
        
        // Initialize textre
        curveTexture = new Texture2D(256, numCurve, TextureFormat.RFloat, false);
        curveTexture.filterMode = FilterMode.Bilinear;
        curveTexture.wrapMode = TextureWrapMode.Clamp;

        // Write curves to texture
        UpdateCurveTexture(shadowCurve, 0);

        // Pass texture to shader
        material.SetTexture("_CurveTexture", curveTexture);

        // Display texture
        #if UNITY_EDITOR
            UpdateRenderTexture();
        #endif
    }


    // Write curve to texture
    void UpdateCurveTexture(AnimationCurve curve, int yIndex)
    {
        if (curve == null)
        {
            Debug.Log("Curve not found");
            return;
        }

        for (int i = 0; i < curveTexture.width; i++)
        {
            float t = (float)i / (float)curveTexture.width;
            float v = curve.Evaluate(t);
            curveTexture.SetPixel(i, yIndex, new Color(v, v, v, v));
        }

        curveTexture.Apply();
    }

    // Display texture
    void UpdateRenderTexture()
    {
        Graphics.Blit(curveTexture, renderTexture);
    }
}

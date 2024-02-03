using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RemapCurve : MonoBehaviour
{   
    protected virtual void UpdateCurveTexture(Texture2D curveTexture, AnimationCurve curve, int yIndex)
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

    protected virtual void CreateCurveTexture(Texture2D curveTexture, int numCurve)
    {
        curveTexture.filterMode = FilterMode.Bilinear;
        curveTexture.wrapMode = TextureWrapMode.Clamp;
    }

}

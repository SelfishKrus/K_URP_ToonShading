using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteInEditMode]
public class RemapCurve_Character : RemapCurve
{   
    Texture2D characterCurveTexture;

    public float shadowPatternFactor = 1.0f;
    public float shadowPatternScale = 1.0f;
    int numCurve;
    int id_shadowCurve;

    public AnimationCurve shadowCurve;

    public RenderTexture renderTexture;

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            OnValidate();
        }
    }

    public void ForceValidate()
    {
        OnValidate();
    }

    void OnValidate ()
    {   
        Setup();

        CreateCurveTexture(characterCurveTexture, numCurve);
        UpdateCurveTexture(characterCurveTexture, shadowCurve, id_shadowCurve);
        PassData();
        #if UNITY_EDITOR
            Graphics.Blit(characterCurveTexture, renderTexture);
        #endif
    }

#region PRIVATE_METHODS
    // Write curve to texture
    void Setup()
    {
        List<AnimationCurve> curves = new List<AnimationCurve>();
        curves.Add(shadowCurve);

        numCurve = curves.Count;
        
        id_shadowCurve = curves.IndexOf(shadowCurve);
        
        characterCurveTexture = new Texture2D(256, numCurve, TextureFormat.RFloat, false);
    }

    void PassData()
    {
        Shader.SetGlobalTexture("_CurveTexture", characterCurveTexture);
        Shader.SetGlobalInt("_Id_ShadowCurve", id_shadowCurve);
        Shader.SetGlobalFloat("_ShadowPatternFactor", shadowPatternFactor);
        Shader.SetGlobalFloat("_ShadowPatternScale", shadowPatternScale);
    }


#endregion
}

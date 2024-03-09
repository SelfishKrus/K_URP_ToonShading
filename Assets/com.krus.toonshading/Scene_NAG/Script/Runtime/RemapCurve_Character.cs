using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteInEditMode]
public class RemapCurve_Character : RemapCurve
{   
    Texture2D characterCurveTexture;

    public float shadowPatternThreshold = 0.7f;
    [Range(0.0f, 0.5f)]
    public float shadowPatternSmoothness = 0.0f;
    public float shadowPatternScale = 0.42f;
    int numCurve;
    int id_shadowCurve;

    public AnimationCurve shadowCurve;
    public RenderTexture renderTexture;

    void Start()
    {
        OnValidate();

    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            OnValidate();
        }
    }
    void OnValidate ()
    {   
        Setup();

        CreateCurveTexture(characterCurveTexture, numCurve);
        UpdateCurveTexture(characterCurveTexture, shadowCurve, id_shadowCurve);

        Renderer[] renderers = GetComponentsInChildren<Renderer>();
        foreach (Renderer renderer in renderers)
        {
            PassData(renderer.sharedMaterial);
        }

        #if UNITY_EDITOR
            Graphics.Blit(characterCurveTexture, renderTexture);
        #endif
    }

    public void ForceValidate()
    {
        OnValidate();
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

    void PassData(Material material)
    {
        material.SetTexture("_CurveTexture", characterCurveTexture);
        material.SetInt("_Id_ShadowCurve", id_shadowCurve);
        material.SetFloat("_ShadowPatternThreshold", shadowPatternThreshold);
        material.SetFloat("_ShadowPatternSmoothness", shadowPatternSmoothness);
        material.SetFloat("_ShadowPatternScale", shadowPatternScale);
    }

#endregion
}

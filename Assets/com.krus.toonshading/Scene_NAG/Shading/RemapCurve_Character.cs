using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteInEditMode]
public class RemapCurve_Character : RemapCurve
{   
    public Material material;
    Texture2D characterCurveTexture;

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

        if (material == null)
        {
            Debug.Log("Material not found");
            return;
        }

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
        if (GetComponent<Renderer>() != null)
        {
            material = GetComponent<Renderer>().sharedMaterial ;
        }

        List<AnimationCurve> curves = new List<AnimationCurve>();
        curves.Add(shadowCurve);

        numCurve = curves.Count;
        
        id_shadowCurve = curves.IndexOf(shadowCurve);
        
        characterCurveTexture = new Texture2D(256, numCurve, TextureFormat.RFloat, false);
    }

    void PassData()
    {
        material.SetTexture("_CurveTexture", characterCurveTexture);
        material.SetInt("_Id_ShadowCurve", id_shadowCurve);
    }


#endregion
}

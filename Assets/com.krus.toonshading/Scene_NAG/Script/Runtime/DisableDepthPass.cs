using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DisableDepthPass : MonoBehaviour
{
    // Start is called before the first frame update
    void OnValidate()
    {
        Renderer[] renderers = GetComponentsInChildren<Renderer>();
        foreach (Renderer renderer in renderers)
        {
            Material[] materials = renderer.sharedMaterials;
            foreach (Material material in materials)
            {
                material.SetShaderPassEnabled("DepthOnly", false);
                material.SetShaderPassEnabled("DepthNormals", false);
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}

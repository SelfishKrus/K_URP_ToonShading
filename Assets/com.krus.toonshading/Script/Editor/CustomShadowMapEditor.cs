using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(CustomShadowMap))]
public class CustomShadowMapEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        CustomShadowMap script = (CustomShadowMap)target;
        if (script.lightCamDepthTex != null)
        {   
            float aspectRatio = (float)script.lightCamDepthTex.width / script.lightCamDepthTex.height;
            float rectHeight = 100; // Set the height you want for the rectangle
            float rectWidth = rectHeight * aspectRatio; // Calculate the width based on the texture's aspect ratio

            EditorGUILayout.Separator();
            EditorGUILayout.LabelField("Light Camera Depth Texture", EditorStyles.boldLabel);
            EditorGUI.DrawPreviewTexture(GUILayoutUtility.GetAspectRect(aspectRatio), script.lightCamDepthTex);
        }
    }
}

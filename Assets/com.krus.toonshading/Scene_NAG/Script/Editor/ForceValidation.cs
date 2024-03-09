using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(RemapCurve_Character))]
public class ForceValidation : Editor
{
    void OnSceneGUI()
    {
        Event e = Event.current;
        if (e.isKey && e.type == EventType.KeyDown && e.keyCode == KeyCode.Space)
        {   
            RemapCurve_Character[] scripts = Object.FindObjectsByType<RemapCurve_Character>(FindObjectsSortMode.None);
            foreach (RemapCurve_Character script in scripts)
            {
                script.ForceValidate();
                
            }
        }
    }
}
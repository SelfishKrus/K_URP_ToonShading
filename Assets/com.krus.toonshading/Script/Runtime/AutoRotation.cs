using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class AutoRotation : MonoBehaviour
{   
    public bool isQuit = false;
    public float speed = 50.0f;
    float totalRotation = 0.0f;

    // Update is called once per frame
    void Update()
    {   
        float rotationThisFrame = speed * Time.deltaTime;
        totalRotation += rotationThisFrame;

        // Rotate the object in world space y
        transform.Rotate(Vector3.up, rotationThisFrame, Space.World);

        // Quit the game if the total rotation is greater than 360 degrees.
        if (totalRotation > 360f && isQuit)
        {
            QuitPlayMode();
        }
    }

    void QuitPlayMode()
    {
        #if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
        #else
            Application.Quit();
        #endif
    }
}

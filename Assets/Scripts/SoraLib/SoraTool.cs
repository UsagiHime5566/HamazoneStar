using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SoraTool
{
    public static Color GetRandomColor(){
        //float color, float density, float light
        return Color.HSVToRGB(Random.Range(0f, 1f), Random.Range(0.3f, 0.75f), 0.8f);
    }
}

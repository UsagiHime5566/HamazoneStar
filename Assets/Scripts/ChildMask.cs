using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ChildMask : MonoBehaviour
{
    Image _image;
    public RectTransform rectTransform;
    void Awake()
    {
        _image = GetComponent<Image>();
        rectTransform = GetComponent<RectTransform>();
    }

    

    public void SetColor(Color c){
        _image.color = c;
    }
}

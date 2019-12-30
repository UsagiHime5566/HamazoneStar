using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ShaderCollections : MonoBehaviour
{
    public List<Material> materials;

    Image _image;

    int index = 0;
    void Awake()
    {
        _image = GetComponent<Image>();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.A))
        {
            if (index >= materials.Count || materials[index] == null)
                index = 0;

            _image.material = materials[index];
            index++;
        }
    }

    public void SwitchShader()
    {
        if (index >= materials.Count || materials[index] == null)
            index = 0;

        _image.material = materials[index];
        index++;
    }
}

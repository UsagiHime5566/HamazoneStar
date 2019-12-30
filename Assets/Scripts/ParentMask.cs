using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ParentMask : MonoBehaviour
{
    public ShaderCollections shaderSwitch;
    public List<ChildMask> childMasks;

    public float waitOne = 0.1f;
    public float delayNext = 1.0f;

    public float translateAmount = 20;

    void Start()
    {
        childMasks = new List<ChildMask>(GetComponentsInChildren<ChildMask>());

        
    }

    void Update(){
        if(Input.GetKeyDown(KeyCode.Space)){
            StartCoroutine(GoMovie());
        }
    }

    public bool button1;
    public void DoAction1(){
        if(!button1)
            return;

        StartCoroutine(QueueAction1());
    }

    IEnumerator QueueAction1(){
        for (int loop = 0; loop < 10; loop++)
        {
            Color c = SoraTool.GetRandomColor();
            for (int i = 0; i < childMasks.Count; i++)
            {
                childMasks[i].SetColor(c);
                yield return new WaitForSeconds(waitOne);
            }
        }
    }

    public bool button2;
    public void DoAction2(){
        if(!button2)
            return;

        StartCoroutine(QueueAction2());
    }

    IEnumerator QueueAction2(){
        Color c = Color.black;
        c.a = 1.0f;
        for (int i = 0; i < childMasks.Count; i += 2)
        {
            childMasks[i].SetColor(c);
            if(i+1 < childMasks.Count)
            childMasks[i+1].SetColor(c);
            //yield return new WaitForSeconds(waitOne);
            yield return new WaitForSeconds(waitOne);
        }
        shaderSwitch.SwitchShader();
        yield return new WaitForSeconds(delayNext);

        c.a = 0.0f;
        for (int i = 0; i < childMasks.Count; i += 2)
        {
            childMasks[i].SetColor(c);
            if(i+1 < childMasks.Count)
            childMasks[i+1].SetColor(c);
            //yield return new WaitForSeconds(waitOne);
            yield return new WaitForSeconds(waitOne);
        }


        // for (int i = childMasks.Count - 1; i >= 0; i--)
        // {
        //     childMasks[i].SetColor(c);
        //     yield return new WaitForSeconds(waitOne);
        // }
    }

    IEnumerator QueueAction3(){
        Color c = Color.black;
        float baseLoc = 752;

        for (int i = 0; i < childMasks.Count; i++)
        {
            childMasks[i].rectTransform.anchoredPosition = new Vector2(baseLoc, childMasks[i].rectTransform.anchoredPosition.y);
            while(childMasks[i].rectTransform.anchoredPosition.x > 0){
                childMasks[i].rectTransform.anchoredPosition += new Vector2(-translateAmount, 0);
                yield return new WaitForSecondsRealtime(waitOne);
            }
        }
        shaderSwitch.SwitchShader();
        yield return new WaitForSeconds(delayNext);

        for (int i = 0; i < childMasks.Count; i++)
        {
            while(childMasks[i].rectTransform.anchoredPosition.x > -baseLoc){
                childMasks[i].rectTransform.anchoredPosition += new Vector2(-translateAmount, 0);
                yield return new WaitForSecondsRealtime(waitOne);
            }
        }

    }

    IEnumerator GoMovie(){
        while(true){
            StartCoroutine(QueueAction3());
            yield return new WaitForSeconds(12);
        }
    }

    private void OnValidate() {
        //DoAction1();
        //DoAction2();
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BGMController : MonoBehaviour
{
    public AudioSource bgm;
    public List<AudioClip> clips;
    int index = 0;
    void Start()
    {
        
    }

    void Update(){
        if(Input.GetKeyDown(KeyCode.Space)){
            StartCoroutine(BGMPlayer());
        }
    }

    IEnumerator BGMPlayer(){
        yield return new WaitForSeconds(2.0f);
        bgm.Play();
        while(true){
            if(!bgm.isPlaying){
                index++;
                if(index >= clips.Count || clips[index] == null)
                    index = 0;
                
                bgm.clip = clips[index];
                bgm.Play();
            }
            yield return new WaitForSeconds(1.0f);
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Recorder;
#endif

public class BGMController : MonoBehaviour
{
    public AudioSource bgm;
    public List<AudioClip> clips;
    int index = 0;

    bool running = false;

    void Start()
    {
        
    }

    void Update(){
        // if(Input.GetKeyDown(KeyCode.Space)){
        //     StartCoroutine(BGMPlayer());
        // }
        if(Input.GetMouseButtonDown(0)){
            if(!running){
                StartCoroutine(BGMPlayer());
                running = true;
            }
        }
    }

    IEnumerator BGMPlayer(){
        yield return new WaitForSeconds(2.0f);
        bgm.Play();
        while(true){
            if(!bgm.isPlaying){
                index++;
                if(index == clips.Count){
                    Debug.Log("BGM Restart !");
                #if UNITY_EDITOR
                    RecorderWindow recorderWindow = (RecorderWindow)EditorWindow.GetWindow(typeof(RecorderWindow));
                    if (recorderWindow.IsRecording())
                        recorderWindow.StopRecording();
                #endif
                }
                if(index >= clips.Count || clips[index] == null)
                    index = 0;
                
                bgm.clip = clips[index];
                bgm.Play();
            }
            yield return new WaitForSeconds(1.0f);
        }
    }
}

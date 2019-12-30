using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using DG.Tweening;

public class CanvasGroupExtend : MonoBehaviour
{
    [Header("UI動畫設定")]
    protected const float FadeDuration = 0.5f;
    protected Tweener currentTween;
    protected CanvasGroup selfCanvas;

    //public Action OnPanelOpened;
    //public Action OnPanelClosed;

    public void ClosePanelImmediate(CanvasGroup panel){
        panel.alpha = 0;
        panel.interactable = false;
        panel.blocksRaycasts = false;
    }

    public void OpenPanelImmediate(CanvasGroup panel){
        panel.alpha = 1;
        panel.interactable = true;
        panel.blocksRaycasts = true;
    }

    public void ClosePanel(CanvasGroup panel, Action callback = null){
        if(currentTween != null){
            currentTween.Kill();
        }

        TweenCallback onComplete = () => {
            currentTween = null;
            callback?.Invoke();
        };
        panel.blocksRaycasts = false;
        currentTween = panel.DOFade(0, FadeDuration).OnComplete(onComplete);
    }

    public void OpenPanel(CanvasGroup panel, Action callback){
        if(currentTween != null){
            currentTween.Kill();
        }

        TweenCallback onComplete = () => {
            panel.alpha = 1;
            panel.interactable = true;
            panel.blocksRaycasts = true;
            currentTween = null;
            callback?.Invoke();
            //panel.GetComponent<CanvasGroupExtend>()?.OnPanelOpened?.Invoke();
        };
        currentTween = panel.DOFade(1,FadeDuration).OnComplete(onComplete);
    }

    public void OpenSelf(Action callback){
        if(selfCanvas == null)
            selfCanvas = GetComponent<CanvasGroup>();

        if(selfCanvas == null)
            return;
        
        OpenPanel(selfCanvas, callback);
    }

    public void CloseSelf(Action callback){
        if(selfCanvas == null)
            selfCanvas = GetComponent<CanvasGroup>();

        if(selfCanvas == null)
            return;
        
        ClosePanel(selfCanvas, callback);
    }

    public void OpenSelf(){
        OpenSelf(null);
    }

    public void CloseSelf(){
        CloseSelf(null);
    }

    public void OpenSelfImmediate(){
        if(selfCanvas == null)
            selfCanvas = GetComponent<CanvasGroup>();

        if(selfCanvas == null)
            return;
            
        if(currentTween != null)
            currentTween.Complete();

        OpenPanelImmediate(selfCanvas);
    }

    public void CloseSelfImmediate(){
        if(selfCanvas == null)
            selfCanvas = GetComponent<CanvasGroup>();

        if(selfCanvas == null)
            return;

        if(currentTween != null)
            currentTween.Complete();

        ClosePanelImmediate(selfCanvas);
    }
}

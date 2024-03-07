﻿#Requires AutoHotkey v1.1.1+  ; so that the editor would recognise this script as AHK V1
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include <lib>

SM := new SM()

#if (SM.IsEditingHTML())
^!l::
  ContLearn := SM.IsGrading() ? 1 : SM.IsLearning()
  Item := (ContLearn == 1) ? true : false
  CurrTimeDisplay := GetDetailedTime()
  CurrTimeFileName := RegExReplace(CurrTimeDisplay, ",? |:", "-")
  ClipSaved := ClipboardAll
  KeyWait Alt
  KeyWait Ctrl
  if (!data := Copy(false, true)) {
    Clipboard := ClipSaved
    return
  }
  SetToolTip("LaTeX converting...")
  if (!IfContains(data, "<IMG")) {  ; text
    Send {BS}^{f7}  ; set read point
    LatexFormula := Trim(ProcessLatexFormula(Clipboard), "$")
    ; After almost a year since I wrote this script, I finially figured out this f**ker website encodes the formula twice. Well, I suppose I don't use math that often in SM
    LatexFormula := EncodeDecodeURI(EncodeDecodeURI(LatexFormula))
    LatexLink := "https://latex.vimsky.com/test.image.latex.php?fmt=png&val=%255Cdpi%257B150%257D%2520%255Cbg_white%2520%255Chuge%2520" . LatexFormula . "&dl=1"
    LatexFolderPath := SM.GetCollPath(Text := WinGetText("ahk_class TElWind"))
                     . SM.GetCollName(Text) . "\elements\LaTeX"
    LatexPath := LatexFolderPath . "\" . CurrTimeFileName . ".png"
    InsideHTMLPath := "file:///[PrimaryStorage]LaTeX\" . CurrTimeFileName . ".png"
    SetTimer, DownloadLatex, -1
    FileCreateDir % LatexFolderPath
    LatexPlaceHolder := GetDetailedTime()
    Clip("<img alt=""" . LatexFormula . """ src=""" . InsideHTMLPath . """>" . LatexPlaceHolder,, false, true)
    if (ContLearn == 1) {  ; item and "Show answer"
      Send {Esc}
      SM.WaitTextExit()
    }
    SM.SaveHTML()
    SM.WaitHTMLFocus()
    HTML := FileRead(HTMLPath := SM.LoopForFilePath(false))
    HTML := StrReplace(HTML, LatexPlaceHolder)
    
    /*
      Recommended css setting for anti-merge class:
      .anti-merge {
        position: absolute;
        left: -9999px;
        top: -9999px;
      }
    */
    
    AntiMerge := "<SPAN class=anti-merge>Last LaTeX to image conversion at " . CurrTimeDisplay . "</SPAN>"
    HTML := RegExReplace(HTML, "<SPAN class=anti-merge>Last LaTeX to image conversion at .*?(<\/SPAN>|$)", AntiMerge, v)
    if (!v)
      HTML .= "`n" . AntiMerge
    SM.EmptyHTMLComp()
    WinWaitActive, ahk_class TElWind
    Send ^{Home}
    Clip(HTML,, false, "sm")
    if (ContLearn == 1) {  ; item and "Show answer"
      Send {Esc}
      SM.WaitTextExit()
    }
    SM.SaveHTML()
    if (Item) {
      WinWaitActive, ahk_class TElWind
      Send ^+{f7}  ; clear read point
    }
    Vim.State.SetMode("Vim_Normal")
  } else {  ; image
    Send {BS}  ; otherwise might contain unwanted format
    RegExMatch(data, "alt=""(.*?)""", v)
    if (!v)
      RegExMatch(data, "alt=(.*?) ", v)
    LatexFormula := EncodeDecodeURI(EncodeDecodeURI(v1, false), false)
    LatexFormula := ProcessLatexFormula(LatexFormula)
    RegExMatch(data, "src=""(.*?)""", v)
    if (!v)
      RegExMatch(data, "src=(.*?) ", v)
    LatexPath := StrReplace(v1, "file:///")
    LatexFormula := StrReplace(LatexFormula, "&amp;", "&")
    Clip(LatexFormula, true, false)
    FileDelete % LatexPath
    Vim.State.SetMode("Vim_Visual")
  }
  Clipboard := ClipSaved
return

ProcessLatexFormula(LatexFormula) {
  LatexFormula := RegExReplace(LatexFormula, "{\\(display|text)style |\\(display|text)style{ ?",, v)  ; from Wikipedia, Wikibooks, Better Explained, etc
  if (v)
    LatexFormula := RegExReplace(LatexFormula, "}$")
  LatexFormula := RegExReplace(LatexFormula, "\\\(\\(displaystyle)?",, v)  ; from LibreTexts
  if (v)
    LatexFormula := RegExReplace(LatexFormula, "\)$")
  LatexFormula := StrReplace(LatexFormula, "{\ce ",, v)  ; from Wikipedia's chemistry formulae
  if (v)
    LatexFormula := RegExReplace(LatexFormula, "}$")
  LatexFormula := RegExReplace(LatexFormula, "^\\\[|\\\]$")  ; removing start \[ and end ]\ (in Better Explained)
  LatexFormula := RegExReplace(LatexFormula, "^\\\(|\\\)$")  ; removing start \( and end )\ (in LibreTexts)
  return Trim(LatexFormula)
}

DownloadLatex:
  UrlDownloadToFile, % LatexLink, % LatexPath
return


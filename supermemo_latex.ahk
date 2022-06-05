#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
 
ReleaseKey(Key) {
	if (GetKeyState(Key))
		send {blind}{l%Key% up}{r%Key% up}
}

ClipboardGet_HTML( byref Data ) { ; www.autohotkey.com/forum/viewtopic.php?p=392624#392624
 If CBID := DllCall( "RegisterClipboardFormat", Str,"HTML Format", UInt )
	If DllCall( "IsClipboardFormatAvailable", UInt,CBID ) <> 0
	 If DllCall( "OpenClipboard", UInt,0 ) <> 0
		If hData := DllCall( "GetClipboardData", UInt,CBID, UInt )
			 DataL := DllCall( "GlobalSize", UInt,hData, UInt )
		 , pData := DllCall( "GlobalLock", UInt,hData, UInt )
		 , VarSetCapacity( data, dataL * ( A_IsUnicode ? 2 : 1 ) ), StrGet := "StrGet"
		 , A_IsUnicode ? Data := %StrGet%( pData, dataL, 0 )
									 : DllCall( "lstrcpyn", Str,Data, UInt,pData, UInt,DataL )
		 , DllCall( "GlobalUnlock", UInt,hData )
 DllCall( "CloseClipboard" )
 Return dataL ? dataL : 0
}

WaitTextSave(Timeout:=2000) {
	send {esc}  ; exit the field
	LoopTimeout := Timeout / 20
	loop {
		sleep 20
		if (!IsEditingText())
			Break
		if (A_Index > LoopTimeout) {
			ToolTip("Timed out.")
			Break
		}
	}
}

WaitTextFocus(Timeout:=2000) {
	LoopTimeout := Timeout / 20
	loop {
		if (IsEditingText())
			Break
		sleep 20
		if (A_Index > LoopTimeout)
			Break
	}
}

ToolTip(Text:="", Permanent:=false, Period:=-2000) {
	CoordMode, ToolTip, Screen
	ToolTip, % Text, % A_ScreenWidth / 2, % A_ScreenHeight / 3 * 2, 20
	if (!Permanent)
		SetTimer, RemoveToolTip, % Period
}

IsEditingText() {
	ControlGetFocus, CurrentFocus, ahk_class TElWind
	return (WinActive("ahk_class TElWind") && (InStr(CurrentFocus, "Internet Explorer_Server") || InStr(CurrentFocus, "TMemo")))
}

MoveAboveRef(NoRestore:=false) {
	Send ^{End}^+{up}  ; if there are references this would select (or deselect in visual mode) them all
	if (InStr(clip("",, NoRestore), "#SuperMemo Reference:")) {
		send {up 2}
	} else {
		send ^{end}
	}
}

; Clip() - Send and Retrieve Text Using the Clipboard
; by berban - updated February 18, 2019
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=62156
Clip(Text="", Reselect="", NoRestore:=false)
{
  Static BackUpClip, Stored, LastClip
  If (A_ThisLabel = A_ThisFunc) {
    If (Clipboard == LastClip)
      Clipboard := BackUpClip
    BackUpClip := LastClip := Stored := ""
  } Else {
    If !Stored {
      Stored := True
      BackUpClip := ClipboardAll  ; ClipboardAll must be on its own line
    } Else
      SetTimer, %A_ThisFunc%, Off
    LongCopy := A_TickCount, Clipboard := "", LongCopy -= A_TickCount  ; LongCopy gauges the amount of time it takes to empty the clipboard which can predict how long the subsequent clipwait will need
    If (Text = "") {
      SendInput, ^c
      ClipWait, LongCopy ? 0.6 : 0.2, True
    } Else {
      Clipboard := LastClip := Text
      ClipWait, 10
      SendInput, ^v
    }
    if (!NoRestore)  ; for scripts that restore clipboard at the end
      SetTimer, %A_ThisFunc%, -700
    Sleep 20  ; Short sleep in case Clip() is followed by more keystrokes such as {Enter}
    If (Text = "")
      Return LastClip := Clipboard
    Else If ReSelect and ((ReSelect = True) or (StrLen(Text) < 3000))
      SendInput, % "{Shift Down}{Left " StrLen(StrReplace(Text, "`r")) "}{Shift Up}"
  }
  Return
  Clip:
  Return Clip()
}

;uri encode/decode by Titan
;Thread: http://www.autohotkey.com/forum/topic18876.html
;About: http://en.wikipedia.org/wiki/Percent_encoding
;two functions by titan: (slightly modified by infogulch)
; https://www.autohotkey.com/board/topic/29866-encoding-and-decoding-functions-v11/
Enc_Uri(str) 
{
  f = %A_FormatInteger%
  SetFormat, Integer, Hex
  If RegExMatch(str, "^\w+:/{0,2}", pr)
    StringTrimLeft, str, str, StrLen(pr)
  StringReplace, str, str, `%, `%25, All
  Loop
    If RegExMatch(str, "i)[^\w\.~%/:]", char)
      StringReplace, str, str, %char%, % "%" . SubStr(Asc(char),3), All
    Else Break
  SetFormat, Integer, %f%
  Return, pr . str
}

html_decode(html) {  
   ; original name: ComUnHTML() by 'Guest' from
   ; https://autohotkey.com/board/topic/47356-unhtm-remove-html-formatting-from-a-string-updated/page-2 
   html := RegExReplace(html, "\r?\n|\r", "<br>")  ; added this because original strips line breaks
   oHTML := ComObjCreate("HtmlFile") 
   oHTML.write(html)
   return % oHTML.documentElement.innerText 
}

#If (WinActive("ahk_class TElWind"))
^!l::
  ReleaseKey("ctrl")
  KeyWait alt
  FormatTime, CurrentTimeDisplay,, yyyy-MM-dd HH:mm:ss:%A_msec%
  CurrentTimeFileName := RegExReplace(CurrentTimeDisplay, " |:", "-")
  ClipSaved := ClipboardAll
  Clipboard := ""
  send ^c
  ClipWait 0.6
  If (ClipboardGet_Html(Data)) {
    ; To do: detect selection contents
    ; if (RegExMatch(data, "<IMG[^>]*>\K[\s\S]+(?=<!--EndFragment-->)")) {  ; match end of first IMG tag until start of last EndFragment tag
      ; ToolTip("Please select text or image only.")
      ; Clipboard := ClipSaved
      ; Return
    ; } else
    if (!InStr(data, "<IMG")) {  ; text only
      send {bs}^{f7}  ; set read point
      WinGetText, VisibleText, ahk_class TElWind
      RegExMatch(VisibleText, "(?<=LearnBar\r\n)(.*?)(?= \(SuperMemo 18: )", CollectionName)
      RegExMatch(VisibleText, "(?<= \(SuperMemo 18: )(.*)(?=\)\r\n)", CollectionPath)
      LatexFormula := RegExReplace(Clipboard, "\\$", "\ ")  ; just in case someone would leave a \ at the end
      LatexFormula := Enc_Uri(LatexFormula)
      LatexLink := "https://latex.vimsky.com/test.image.latex.php?fmt=png&val=%255Cdpi%257B150%257D%2520%255Cnormalsize%2520%257B%255Ccolor%257Bwhite%257D%2520" . LatexFormula . "%257D&dl=1"
      LatexFolderPath := CollectionPath . CollectionName . "\LaTeX"
      LatexPath := LatexFolderPath . "\" . CurrentTimeFileName . ".png"
      SetTimer, DownloadLatex, -1
      FileCreateDir % LatexFolderPath
      ImgHtml = <img alt="%Clipboard%" src="%LatexPath%">
      clip(ImgHtml, true, true)
      send ^+1
      WaitTextSave()
      send ^t
      WaitTextFocus()
      Clipboard := ""
      send !{f12}fc  ; copy file path
      ClipWait
      HtmlPath := Clipboard
      FileRead, Html, % HtmlPath
      if (!Html)
        Html := ImgHtml  ; in case the Html is picture only and somehow not saved
      
      /*
        recommended css setting for fuck_lexicon class:
        .fuck_lexicon {
          position: absolute;
          left: -9999px;
          top: -9999px;
        }
      */
      
      fuck_lexicon = <SPAN class=fuck_lexicon>Last LaTeX to image conversion: %CurrentTimeDisplay%</SPAN>
      if (InStr(Html, "<SPAN class=fuck_lexicon>Last LaTeX to image conversion: ")) {  ; converted before
        WaitTextSave()
        NewHtml := RegExReplace(Html, "<SPAN class=fuck_lexicon>Last LaTeX to image conversion: (.*?)(<\/SPAN>|$)", fuck_lexicon)
        FileDelete % HtmlPath
        FileAppend, % NewHtml, % HtmlPath
        send !{home}!{left}  ; refresh so the conversion time would display correctly
      } else {  ; first time conversion
        NewHtml := Html . "`n" . fuck_lexicon
        MoveAboveRef(true)
        send ^+{home}{bs}{esc}  ; delete everything and save
        send ^+{f6}  ; opens notepad
        WinWaitNotActive, ahk_class TElWind,, 0
        send ^w
        WinWaitActive, ahk_class TElWind,, 0
        send ^{home}  ; put the caret on top
        clip(NewHtml,, true)
        send ^+{home}^+1
        WaitTextSave()
        ; no need for !home!left refreshing here
      }
      send !{f7}  ; go to read point
      sleep 250
      send {right}
    } else {  ; image only
      RegExMatch(data, "(alt=""|alt=)\K.+?(?=(""|\s+src=))", LatexFormula)  ; getting formula from alt=""
      RegExMatch(data, "src=""file:\/\/\/\K[^""]+", LatexPath)  ; getting path from src=""
      if (InStr(LatexFormula, "{\displaystyle")) {  ; from wikipedia, wikibooks, etc
        LatexFormula := StrReplace(LatexFormula, "{\displaystyle")
        LatexFormula := RegExReplace(LatexFormula, "}$")
      } else if (InStr(LatexFormula, "\displaystyle{")) {  ; from Better Explained
        LatexFormula := StrReplace(LatexFormula, "\displaystyle{")
        LatexFormula := RegExReplace(LatexFormula, "}$")
      }
      LatexFormula := RegExReplace(LatexFormula, "^\s+|\s+$")  ; removing start and end whitespaces
      LatexFormula := RegExReplace(LatexFormula, "^\\\[|\\\]$")  ; removing start \[ and end ]\ (in Better Explained)
      LatexFormula := Html_decode(LatexFormula)
      clip(LatexFormula, true, true)
      FileDelete % LatexPath
    }
  }
  Clipboard := ClipSaved
Return

DownloadLatex:
  UrlDownloadToFile, % LatexLink, % LatexPath
Return

RemoveToolTip:
  ToolTip,,,, 20
return

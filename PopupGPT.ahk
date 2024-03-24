﻿#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%

; Comment out the next line if compiling to EXE, instead use Ahk2Exe.exe GUI to add custom icon
;Menu, Tray, Icon, icon.ico

; Retrieve API key from Registry
RegRead, apiKey, HKEY_CURRENT_USER, Software\PopupGPT, APIKey

; If blank, set API via user prompt
if apiKey =
    Gosub, SetApi

Gui, Font, s10
Gui, Add, Edit, vInput w400 h200
Gui, Add, Button, gAnswer35, GPT 3.5 (CTRL+Enter)
Gui, Add, Button, gAnswer4, GPT 4 (SHIFT+ENTER)
Gui, Add, Button, gSetApi, Set API Key
Gui, Add, Edit, vOutput w400 h200 ReadOnly
Gui, Add, Button, gCopyOutput, Copy (ALT+C) 

Menu, Tray, Add, Show Popup, ShowGPTPopup
Return

ShowGPTPopup:
!`::  ; ALT+` Hotkey to show GUI
    GuiControl,, Input,  ; Clear the input field
    GuiControl,, Output,  ; Clear the output field
    Gui, Show, , PopupGPT  ; Show the GUI
    GuiControl, Focus, vInput  ; Focus on the input field
return

; Hotkeys for executing and copy should only exist if window is active
#IfWinActive, PopupGPT
    ^Enter::Gosub, Answer35
    +Enter::Gosub, Answer4
    !c::Gosub, CopyOutput
#IfWinActive

return

SetApi:
    InputBox, apiKey, API Key, Please enter your OpenAI API Key, ,,,,,,,%apiKey%
    RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\PopupGPT, APIKey, %apiKey%
return

Answer35:
    model := "gpt-3.5-turbo-0125"
    Gosub, Answer
return

Answer4:
    model := "gpt-4-0125-preview"
    Gosub, Answer
return

Answer:
Gui, Submit, NoHide

InputPrompt := Input
InputPrompt := StrReplace(InputPrompt, "`n", "\n")
If InputPrompt = ; Prompt is empty...
    {
        MsgBox Please type your prompt in the top, big white box
        Return
    }
GuiControl,, Output, Thinking...

curlCommand := "curl ""https://api.openai.com/v1/chat/completions"" -H ""Content-Type: application/json"" -H ""Authorization: Bearer " . apiKey . """ -d ""{\""model\"": \""" . model . "\"", \""messages\"": [{\""role\"": \""user\"", \""content\"": \""Answer this question brief and to the point, no intros: " . InputPrompt . "\""}]}"""
RunWait, %ComSpec% /c %curlCommand% > gptResponse.txt,, Hide UseErrorLevel
if ErrorLevel
    {
        MsgBox, There was an error running the cURL command: %ErrorLevel%
        return
    }

FileRead, OutputVar, gptResponse.txt
FileDelete, gptResponse.txt

if ErrorLevel
{
    MsgBox, There was an error with the response: %ErrorLevel%
    return
}

StartPosition := InStr(OutputVar, "content") + 11
EndPosition := InStr(OutputVar, "logprobs") - 18
gptOutput := SubStr(OutputVar, StartPosition, EndPosition - StartPosition)
gptOutput := StrReplace(gptOutput, "\n", "`n")
gptOutput := StrReplace(gptOutput, "\""", """")
gptOutput := StrReplace(gptOutput, "```", "")  ; Remove backticks around code.

GuiControl,, Output, %gptOutput%
return

CopyOutput:
GuiControlGet, CurrentOutput,, Output
Clipboard := CurrentOutput
return

GuiClose:
    Gui, Hide  ; Hide the GUI instead of exiting
return
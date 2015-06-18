#Region
;AutoIt3 settings
#AutoIt3Wrapper_UseX64=n
;Aut2Exe (compiler) settings
#AutoIt3Wrapper_icon=.\icon.ico
#AutoIt3Wrapper_outfile=.\PA_Object_Eraser.exe
#AutoIt3Wrapper_OutFile_X64=.\PA_Object_Eraser_x64.exe
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UPX_Parameters=--best --compress-resources=0
#AutoIt3Wrapper_Compile_both=N
;Resource Infos
#AutoIt3Wrapper_Res_Description=Prison Architect Object Eraser
#AutoIt3Wrapper_Res_Fileversion=0.5.3.0
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_LegalCopyright=Written by Reddit user Nevermind04
#EndRegion
#NoTrayIcon

#include <Array.au3>
#include <ComboConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>

Opt("MustDeclareVars",1)

_globalvars()
_main()

Func _globalvars()
	Global $ProgName="Prison Architect Object Eraser"
	Global $ProgVer="0.5.3"
	Global $PA_objectlist_array[1][3],$PA_saveread_array
EndFunc ;_globalvars

Func _main()
;Set local variables
	Local $PA_loaded_savefile,$PA_savedir_msgbox,$PA_savefile_array,$PA_savefile_combolist,$PA_savefilemod_array ;Null (for now) variables declared to be used later in the script
	Local $inifile=@AppDataDir&"\PA_Object_Eraser\settings.ini" ;Master .ini settings file, will be used if any settings need to be stored
	If Not FileExists(@AppDataDir&"\PA_Object_Eraser") Then DirCreate(@AppDataDir&"\PA_Object_Eraser") ;Writing settings to the .ini file will create the actual file, but not the directory structure - create dir under <UserProfile>\Appdata\Roaming\PA_Object_Eraser if it doesn't already exist
	Local $PA_defaultsavedir=@LocalAppDataDir&"\Introversion\Prison Architect\saves" ;Default savegame file directory
	Local $PA_saveext=".prison" ;Default savegame file extension
	Local $PA_savedir=IniRead($inifile,"Directories","SaveDir",$PA_defaultsavedir) ;Pull savegame file directory from ini, else use default
	Local $PA_savefile_changespending=0

;Create the GUI
	Local $GUI_main=GUICreate($ProgName&" v"&$ProgVer,640,480,IniRead($inifile,"Session","WindowPosX",-1),IniRead($inifile,"Session","WindowPosY",-1)) ;Create the main GUI. Will try to pull "remembered" window position from the ini. If the .ini doesn't exist or the values aren't there, the window will be centered on the main monitor
	;GUISetBkColor(0xFFFFFF) ;Background color: white
	;GUICtrlSetDefBkColor(0xFFFFFF) ;Default control background color: white
	;GUICtrlSetDefColor(0x000000) ;Default text color: black
	GUICtrlCreateLabel("Choose a save file and press the Load Save File button.",10,8,160,25,$SS_CENTER) ;Label in front of the combobox
	Local $GUI_combobox_savefilelist=GUICtrlCreateCombo("Loading...",180,10,315,20,$CBS_DROPDOWNLIST) ;Combobox which will contain a drop-down list of the user's save files
	Local $GUI_button_loadsavefile=GUICtrlCreateButton("Load Save File",505,8,130,25) ;Button to actually load the save file
	Local $GUI_button_opensavedir=GUICtrlCreateButton("Open Save Directory",505,35,130,25) ;Button that opens an Explorer window to the user's savegame directory
	Local $GUI_label_status=GUICtrlCreateLabel("(NO SAVE FILE LOADED)",10,45,490,25,$SS_CENTER) ;The status label, will be updated by functions to tell the user what is happening
	GUICtrlSetFont($GUI_label_status,12,700) ;Set font for status label to size 12 bold
	Local $GUI_list_objectlist=GUICtrlCreateList("",10,70,490,380) ;The main list which will contain all of the objects once a file is loaded
	GUICtrlCreateLabel("Select a group of objects from the list, then press Erase Objects to erase all of the selected objects.",505,70,130,55,$SS_CENTER) ;Label explaining what the Erase Object button does
	Local $GUI_button_eraseobjects=GUICtrlCreateButton("Erase Objects",505,125,130,25) ;Button to erase the object selected in the list
	Local $GUI_label_nevermind04=GUICtrlCreateLabel("This utility was written by Reddit user Nevermind04. Click here to send me a PM if you have any issues.",505,225,130,55,BitOR($SS_CENTER,$SS_NOTIFY,$SS_SUNKEN)) ;Label explaining what the Erase Object button does
	Local $GUI_button_savefile=GUICtrlCreateButton("Save File",505,355,130,25) ;Button to commit the changes to the user's save file
	GUICtrlCreateLabel("No changes will be saved until you press Save File. Your save file will be automatically backed up.",505,385,130,55,$SS_CENTER) ;Label explaining that the changes won't be committed until the Save File button is pressed
	Local $GUI_progress_loadbar=GUICtrlCreateProgress(10,450,620,20,$PBS_SMOOTH)
	GUISetState(@SW_SHOW)

;Determine directory where user's .prison savegame files are located
	If Not FileExists($PA_savedir) Then ;Save dir determined above does not exist
		If $PA_savedir==$PA_defaultsavedir Then ;Default save dir does not exist
			$PA_savedir_msgbox=MsgBox(4,$ProgName&" v"&$ProgVer,"It looks like your Prison Architect saves files are not in the default directory. Would you like to browse for a directory?")
			If $PA_savedir_msgbox==6 Then ;User pressed Yes button
				$PA_savedir=FileSelectFolder("Please select your Prison Architect save file directory.",@HomeDrive)
			Else ;User pressed No button
				Exit
			EndIf
		Else ;Directory from .ini file setting does not exist
			$PA_savedir_msgbox=MsgBox(3,$ProgName&" v"&$ProgVer,"Your previous Prison Architect save directory ("&$PA_savedir&") no longer exists. Would you like to reset it to the default directory? If you select "&Chr(34)&"No"&Chr(34)&", you will be asked to browse for a new save directory.")
			If $PA_savedir_msgbox==6 Then ;User pressed Yes button
				$PA_savedir=$PA_defaultsavedir
			ElseIf $PA_savedir_msgbox==7 Then ;User pressed No button
				$PA_savedir=FileSelectFolder("Please select your Prison Architect save file directory.",@HomeDrive)
			Else ;User pressed Cancel button
				Exit
			EndIf
		EndIf
	EndIf

;Make array from list of user's .prison savegame files
	$PA_savefile_array=_FileListToArray($PA_savedir,"*"&$PA_saveext,1)
	If IsArray($PA_savefile_array) Then ;The variable will be an array if files are found
		If $PA_savedir==$PA_defaultsavedir And IniRead($inifile,"Directories","SaveDir","")<>"" Then IniDelete($inifile,"Directories","SaveDir") ;If user had set an incorrect directory before, but then reverted to default, delete the bad record from .ini settings file
		If $PA_savedir<>$PA_defaultsavedir Then IniWrite($inifile,"Directories","SaveDir",$PA_savedir) ;If user selected a directory different than default save directory, write it to .ini settings file
	Else
		MsgBox(0,$ProgName&" v"&$ProgVer,"No "&$PA_saveext&" save files were found in your save directory: "&$PA_savedir)
		Exit
	EndIf
	;_ArrayDisplay($PA_savefile_array) ;View array for debugging purposes

;The $PA_savefile_array cannot be expanded to two columns (It's also possible that I just don't know how), so we will now build $PA_savefilemod_array
	Dim $PA_savefilemod_array[$PA_savefile_array[0]+1][2] ;Declare array same size as $PA_savefile_array, just with two columns
	$PA_savefilemod_array[0][0]=$PA_savefile_array[0] ;Index count should be the same
	For $x=1 To $PA_savefile_array[0] ;Copy the rest of the vars (which should be save file names in $PA_savedir)
		$PA_savefilemod_array[$x][0]=StringTrimRight($PA_savefile_array[$x],StringLen($PA_saveext)) ;Copy var into the first column, minus the extension for display purposes (since we know the extension, it will be trivial to recreate the actual file name)
	Next
	;_ArrayDisplay($PA_savefilemod_array) ;View array for debugging purposes

;Get file mod dates for sorting purposes
	For $x=1 To $PA_savefilemod_array[0][0]
		$PA_savefilemod_array[$x][1]=FileGetTime($PA_savedir&"\"&$PA_savefilemod_array[$x][0]&$PA_saveext,0,1) ;Get file date (YYYYMMDDHHMMSS format for numeric sorting) and put it in second column
	Next

;Sort the mod array
	_ArraySort($PA_savefilemod_array,1,1,"",1) ;Sort array by second column (YYYYMMDDHHMMSS timestamp) decending, so newest files are on the top
	;_ArrayDisplay($PA_savefilemod_array) ;View array for debugging purposes

;Update the savefile combobox
	$PA_savefile_combolist=""
	For $x=1 To $PA_savefilemod_array[0][0]
		;All items must be delimited by |   If the string starts with the delimiter, the previous string (which reads Loading...) will be wiped
		$PA_savefile_combolist&="|"&$PA_savefilemod_array[$x][0]
	Next
	GUICtrlSetData($GUI_combobox_savefilelist,$PA_savefile_combolist,IniRead($inifile,"Session","PA_SaveFile_LastLoaded",$PA_savefilemod_array[1][0])) ;Update the actual combobox with the savefile list - first (most recent file) as the default selection

;Wait for user to click something
	While 1
        Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE ; ;User clicks the X button
				If $PA_savefile_changespending==0 Then
					_exit($GUI_main,$inifile) ;Terminate the entire program
				Else
					If MsgBox(4+32+256,$ProgName,"You have made changes to your savegame, but you have not saved the changes to your file yet."&@LF&@LF&"(HINT: Press the [Save File] button at the bottom!)"&@LF&@LF&"Exit without saving changes?")==6 Then _exit($GUI_main,$inifile) ;If user presses yes, then exit without saving changes
				EndIf
			Case $GUI_label_nevermind04  ;User clicks the "Click here to PM Nevermind04" label
				ShellExecute("https://reddit.com/message/compose/?to=Nevermind04&subject=Problem%20with%20"&StringReplace($ProgName," ","%20")&"%20v"&$ProgVer)
			Case $GUI_button_loadsavefile ;User clicks the Load File button
				IniWrite($inifile,"Session","PA_SaveFile_LastLoaded",GUICtrlRead($GUI_combobox_savefilelist))
				$PA_loaded_savefile=$PA_savedir&"\"&GUICtrlRead($GUI_combobox_savefilelist)&$PA_saveext ;Read the selection in the combobox and form a full filepath to send to _loadsavefile
				_loadsavefile($GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile)
			Case $GUI_button_opensavedir ;User clicks the Open Save Directory button
				ShellExecute($PA_savedir) ;Opens a File Explorer window to the save directory
			Case $GUI_button_eraseobjects  ;User clicks the Erase Object button
				_eraseobject($GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile) ;Run the _eraseobject function
				Sleep(500) ;Give the user half a second to read the last status message
				_loadsavefile($GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile,1)
				$PA_savefile_changespending=1 ;Will be used to alert the user if they try to close the program or click save without changes
			Case $GUI_button_savefile  ;User clicks the Save File button
				_savefile($GUI_combobox_savefilelist,$GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile)
				$PA_savefile_changespending=0 ;No changes pending
        EndSwitch
    WEnd

EndFunc ;_main

Func _exit($GUI_main,$inifile)
	Local $winpos_array=WinGetPos($GUI_main) ;Pull the position of the GUI so that it can "remember" where it's at for the next session

;Make sure it's an array first - don't want to generate errors on exit :X
	If IsArray($winpos_array) Then
		If UBound($winpos_array)>=2 Then ;Should normally have 4 entries (starting at 0), but we only need two since our window isn't resizable
			IniWrite($inifile,"Session","WindowPosX",$winpos_array[0]) ;X Position
			IniWrite($inifile,"Session","WindowPosY",$winpos_array[1]) ;Y Position
		EndIf
	EndIf

	Exit ;Terminate the program
EndFunc ;_exit

Func _error($text,$exit=1)
	Local $errorcontact=@LF&@LF&"Please help improve this utility by reporting this error to Nevermind04 at Reddit.com"
	If $exit==0 Then
		MsgBox(48,"ERROR","ERROR: "&$text&$errorcontact) ;0 Has to be manually specified to allow script to continue in the event of an error
	Else
		MsgBox(48,"FATAL ERROR","FATAL ERROR: "&$text&$errorcontact) ;Otherwise, it's treated as a fatal error, which will terminate the script
		Exit
	EndIf
EndFunc ;_error

Func _loadsavefile($GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile,$LSF_refresh_saveread=0)
;Local vars
	Local $LSF_objectname,$LSF_searchpointer
	Local $LSF_savefilename=StringTrimLeft($PA_loaded_savefile,StringInStr($PA_loaded_savefile,"\",0,-1)) ;Var containing just the file name without the path, for display purposes
	Local $LSF_progresstimer=TimerInit() ;Timer to know when to update the progress bar
	Dim $PA_objectlist_array[1][3] ;Make sure $PA_objectlist_array is empty
	GUICtrlSetData($GUI_progress_loadbar,0) ;Make sure the progress bar starts at 0%

;Load file into var
	If $LSF_refresh_saveread==0 Then ;Load file from disk
		GUICtrlSetData($GUI_label_status,"Loading file: "&StringLeft($LSF_savefilename,36)) ;Update status text
		Local $filehandle=FileOpen($PA_loaded_savefile)
		$PA_saveread_array=FileReadToArray($filehandle) ;Read file into the array $PA_saveread_array
		FileClose($filehandle)
		If IsArray($PA_saveread_array) Then ;Quickest way to verify there weren't any errors reading the file
			$PA_saveread_array[0]=UBound($PA_saveread_array)-1 ;Set the [0] index to the number of entries starting at 1
		Else
			_error("There was a problem reading the save file: "&$LSF_savefilename) ;Display fatal error then exit
		EndIf
	EndIf

;Process the actual file. Data will be put into the $PA_objectlist_array array into two columns. First column will have the object name, second column will have the number of objects found in the save file
	If $LSF_refresh_saveread==0 Then ;Process file into $PA_saveread_array
		GUICtrlSetData($GUI_label_status,"Processing file: "&StringLeft($LSF_savefilename,33)) ;Update status text
	Else ;Refreshing $PA_saveread_array
		GUICtrlSetData($GUI_label_status,"Refreshing object list...")
	EndIf
	$PA_objectlist_array[0][0]=0 ;The array initially contains 0 entries, the index will need to be 0 instead of null for maths
	$PA_objectlist_array[0][1]=0 ;The index in the second column will contain the total number of objects found. Needs to be 0 also for maths
	For $x=1 To $PA_saveread_array[0]
		If StringLeft($PA_saveread_array[$x],9)=="    BEGIN" Then ;All object entries begin with this string
			$LSF_searchpointer=StringInStr($PA_saveread_array[$x],"  Type ",1,1) ;This string prefaces all object types, will return 0 if not found
			If $LSF_searchpointer>0 Then
				If StringInStr($PA_saveread_array[$x],"  SubType ",1,1) Then ;Objects have subtypes. This separates them from other entities like people
					$LSF_objectname=StringMid($PA_saveread_array[$x],$LSF_searchpointer+7,StringInStr($PA_saveread_array[$x],"  SubType",0,1,$LSF_searchpointer+8)-$LSF_searchpointer-7) ;Clever variable ninja wizard logic to extract just the object name from the string

					If $LSF_objectname=="Box" Or $LSF_objectname=="Stack" Then ;Boxes and Stacks are items with contents, which are what we're really concerned about
						$LSF_searchpointer=StringInStr($PA_saveread_array[$x],"  Contents ",1,1) ;This string prefaces the contents of stacks
						$LSF_objectname&=" - "&StringMid($PA_saveread_array[$x],$LSF_searchpointer+11,StringInStr($PA_saveread_array[$x],"  ",0,1,$LSF_searchpointer+12)-$LSF_searchpointer-11) ;More logic-fu craziness
					EndIf

					If $PA_objectlist_array[0][0]==0 Then ;The list is empty and this is the first object added to this list
						_ArrayAdd($PA_objectlist_array,$LSF_objectname&"|1|"&$x) ;Add the first object with quantity of 1
					Else
						For $y=1 To $PA_objectlist_array[0][0] ;Go through the objectlist to see if this object is already known
							If $PA_objectlist_array[$y][0]==$LSF_objectname Then ;If this objectname is found in the array of known objects
								$PA_objectlist_array[$y][1]+=1 ;Increase quantity in second column
								$PA_objectlist_array[$y][2]&=";"&$x ;Make a note of the line with this object
								ExitLoop ;Since the object was already found, no need to continue this For loop
							EndIf
							If $y==$PA_objectlist_array[0][0] Then ;If we've reached the end of the For loop without finding the object, then this is a currently unknown object
								_ArrayAdd($PA_objectlist_array,$LSF_objectname&"|1|"&$x) ;Add the new object with quantity of 1
							EndIf
						Next
					EndIf
				EndIf
				$PA_objectlist_array[0][0]=UBound($PA_objectlist_array,1)-1 ;Set the index to the number of entries starting at 1

			Else ;Sometimes object entries are spread out over many lines
				For $z=1 To 99 ;Search a maximum of 99 lines for the info we're looking for
					If $x+$z<$PA_saveread_array[0] Then ;Make sure we haven't reached the end of the array
						If StringLeft($PA_saveread_array[$x+$z],9)=="    BEGIN" Then ;This is not a multi-line object
							ExitLoop ;Exit the $z loop to return to the $x loop
						ElseIf StringLeft($PA_saveread_array[$x+$z],12)=="        Type" Then ;Multi-line objects entries begin with this string
							$LSF_searchpointer=StringInStr($PA_saveread_array[$x+$z],"Type                 ",1,1) ;Get pointer from the new line
							$LSF_objectname=StringMid($PA_saveread_array[$x+$z],$LSF_searchpointer+21,StringInStr($PA_saveread_array[$x+$z],"  ",0,1,$LSF_searchpointer+22)-$LSF_searchpointer-21) ;string search logic to get object name

							If $LSF_objectname=="Box" Or $LSF_objectname=="Stack" Then ;Get contents of Box/Stack
								For $y=1 To 99 ;Search up to 99 lines inside the stack object entry for the contents
									If StringLeft($PA_saveread_array[$x+$z+$y],16)=="        Contents" Then
										$LSF_searchpointer=StringInStr($PA_saveread_array[$x+$z+$y],"Contents             ",1,1) ;This string prefaces the contents of stacks
										$LSF_objectname&=" - "&StringMid($PA_saveread_array[$x+$z+$y],$LSF_searchpointer+21,StringInStr($PA_saveread_array[$x+$z+$y],"  ",0,1,$LSF_searchpointer+22)-$LSF_searchpointer-21) ;string search logic to find contents
										ExitLoop ;Exit the for loop; object name assigned
									ElseIf StringLeft($PA_saveread_array[$x+$z+$y],7)=="    END" Then ;Reached the end of the object entry without finding useful data
										$x+=$z+$y ;Increase the $x pointer to prevent wasting time on lines we've already examined
										ExitLoop 2 ;Exit the $y loop and $z loop so the $x loop can cycle again
									EndIf
								Next
							EndIf

							If $PA_objectlist_array[0][0]==0 Then ;First object added to this list
								_ArrayAdd($PA_objectlist_array,$LSF_objectname&"|1|"&$x+$z) ;Add the first object with quantity of 1
							Else
								For $y=1 To $PA_objectlist_array[0][0] ;Go through the objectlist to see if this object is already known
									If $PA_objectlist_array[$y][0]==$LSF_objectname Then ;If this objectname is found in the array of known objects
										$PA_objectlist_array[$y][1]+=1 ;Increase quantity in second column
										For $w=0 To 99 ;Since this is a multi-line object, we need to note all lines of object info, starting at BEGIN ($x) and ending at END
											$PA_objectlist_array[$y][2]&=";"&$x+$w ;Make a note of the line with this object
											If StringLeft($PA_saveread_array[$x+$w],7)=="    END" Then ExitLoop ;Reached the end of the object entry, exit the $y loop
										Next
										ExitLoop ;Since the object was already found, no need to continue this For loop
									EndIf
									If $y==$PA_objectlist_array[0][0] Then ;If we've reached the end of the For loop without finding the object, then this is a currently unknown object
										_ArrayAdd($PA_objectlist_array,$LSF_objectname&"|1") ;Add the new object with quantity of 1, leaving the "found at lines X" column blank
										$PA_objectlist_array[UBound($PA_objectlist_array)-1][2]=$x ;Make a note of the line with this object at the newest row - this is the first time this object has been found, needs to not have a ; in front of it
										For $w=1 To 99 ;Since this is a multi-line object, we need to note all lines of object info, starting at BEGIN ($x) and ending at END
											$PA_objectlist_array[UBound($PA_objectlist_array)-1][2]&=";"&$x+$w ;Make a note of the line with this object at the newest row
											If StringLeft($PA_saveread_array[$x+$w],7)=="    END" Then ExitLoop ;Reached the end of the object entry, exit the $y loop
										Next
									EndIf
								Next
							EndIf

						ElseIf StringLeft($PA_saveread_array[$x+$z],7)=="    END" Then ;Reached the end of the object entry without finding useful data
							$x+=$z ;No need to go over these lines again
							ExitLoop ;Exit the $z loop so the $x loop can cycle again
						EndIf
						$PA_objectlist_array[0][0]=UBound($PA_objectlist_array,1)-1 ;Set the index to the number of entries starting at 1

					EndIf
				Next
			EndIf
		EndIf

		If TimerDiff($LSF_progresstimer)>500 Then ;500ms (half a second) has passed, time to update the progress bar/list controls
			GUICtrlSetData($GUI_progress_loadbar,Floor($x/$PA_saveread_array[0]*100)) ;Calculate progress over total, then multiply by 100 and floor it to give an even %, then push to the progress bar
			_updatelist($GUI_list_objectlist,$PA_objectlist_array) ;Push updated data to the list control
			$LSF_progresstimer=TimerInit() ;Reset timer
		EndIf
	Next
	For $x=1 To $PA_objectlist_array[0][0]
		$PA_objectlist_array[0][1]+=$PA_objectlist_array[$x][1]
	Next
	_updatelist($GUI_list_objectlist,$PA_objectlist_array) ;Push final update
	GUICtrlSetData($GUI_progress_loadbar,100) ;Sometimes the progress bar never makes it to 100%, so we have to hard set it to 100
	If $LSF_refresh_saveread==0 Then ;Loading file message
		GUICtrlSetData($GUI_label_status,"Save file loaded. Total objects: "&$PA_objectlist_array[0][1])
	Else ;Refreshing list message
		GUICtrlSetData($GUI_label_status,"List Refreshed. Total objects: "&$PA_objectlist_array[0][1])
	EndIf
	_ArraySort($PA_objectlist_array,0,1)
	;_ArrayDisplay($PA_objectlist_array) ;Debug

	Return("") ;Return to _main
EndFunc ;_loadsavefile

Func _updatelist($GUI_list_objectlist,$PA_objectlist_array)
;Local vars
	Local $UL_updatestring
	_ArraySort($PA_objectlist_array,0,1,"",0) ;Sort array for readability

;Build delimited string because for some reason the damn list control doesn't accept arrays >_<
	For $x=1 To $PA_objectlist_array[0][0]
		$UL_updatestring&="|"&$PA_objectlist_array[$x][0]&" - "&$PA_objectlist_array[$x][1]
	Next

	GUICtrlSetData($GUI_list_objectlist,$UL_updatestring) ;Push the string to the control
EndFunc ;_updatelist

Func _eraseobject($GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile)
;Local vars
	Local $EO_array_copy_offset,$EO_eraseline_array,$EO_object_begin,$EO_object_contents,$EO_object_count,$EO_object_end,$EO_object_listpos,$EO_object_name,$EO_progresstimer
	GUICtrlSetData($GUI_progress_loadbar,0) ;Reset progress bar to 0%

;Error anticipation
	If Not IsArray($PA_saveread_array) Then ;Throw error if this is not an array
		_error("No objects have loaded. Please load a save file.",0) ;Throw error, but don't force exit
		Return($PA_saveread_array) ;Escape subroutine
	EndIf
	If GUICtrlRead($GUI_list_objectlist)=="" Then
		_error("No objects have been selected. Please select an object in the list.",0) ;Display error, no exit
		Return($PA_saveread_array) ;Escape subroutine
	EndIf

;Get object name, number of objects, and box/stack contents
	$EO_object_name=StringMid(GUICtrlRead($GUI_list_objectlist),1,StringInStr(GUICtrlRead($GUI_list_objectlist)," - ",0,1)-1) ;Use the dash to delimit the first part of the list string to get the actual object name
	If $EO_object_name=="Box" Or $EO_object_name=="Stack" Then ;Boxes/Stacks have two dashes
		$EO_object_contents=StringMid(GUICtrlRead($GUI_list_objectlist),StringInStr(GUICtrlRead($GUI_list_objectlist)," - ",0,1)+3,StringInStr(GUICtrlRead($GUI_list_objectlist)," - ",0,2)-(StringInStr(GUICtrlRead($GUI_list_objectlist)," - ",0,1)+3)) ;String magic to grab string between both sets of dashes
		$EO_object_count=StringMid(GUICtrlRead($GUI_list_objectlist),StringInStr(GUICtrlRead($GUI_list_objectlist)," - ",0,2)+3) ;Grab string after the second dash
	Else
		$EO_object_count=StringMid(GUICtrlRead($GUI_list_objectlist),StringInStr(GUICtrlRead($GUI_list_objectlist)," - ",0,1)+3) ;If not a stack, there will be only one dash so grab the string after the first dash
	EndIf
	;MsgBox(0,"debug","$EO_object_name=="&Chr(34)&$EO_object_name&Chr(34)&@LF&"$EO_object_contents=="&Chr(34)&$EO_object_contents&Chr(34)&@LF&"$EO_object_count=="&Chr(34)&$EO_object_count&Chr(34)) ;Used for debugging

;Update status text
	If $EO_object_contents=="" Then ;Not an object with contents
		GUICtrlSetData($GUI_label_status,"Erasing Objects: "&$EO_object_name) ;Send the status string to the control
	Else ;Object has contents
		GUICtrlSetData($GUI_label_status,"Erasing Objects: "&$EO_object_name&" containing "&$EO_object_contents)
	EndIf
	GUICtrlSetData($GUI_progress_loadbar,0) ;Progress bar to 0%

;Find the object in the object array
	For $x=1 To $PA_objectlist_array[0][0]
		If $EO_object_contents=="" Then ;Object is not a box/stack because it has no contents
			If $PA_objectlist_array[$x][0]==$EO_object_name Then
				$EO_object_listpos=$x ;Record which row in the array this entry is on so we can later get the [$EO_object_listpos][2] column entry, which contains all of the lines this object is on in $PA_saveread_array
				ExitLoop ;Found what we're looking for, terminate $x For loop
			EndIf
		Else ;Object has contents
			If $PA_objectlist_array[$x][0]==$EO_object_name&" - "&$EO_object_contents Then ;Match object AND contents
				$EO_object_listpos=$x ;Record row
				ExitLoop ;Terminate $x For loop
			EndIf
		EndIf
	Next
	GUICtrlSetData($GUI_progress_loadbar,5) ;Progress bar to 5%

;Make an array of the lines in which this object is found
	$EO_eraseline_array=StringSplit($PA_objectlist_array[$EO_object_listpos][2],";")
	For $x=1 To $EO_eraseline_array[0]
		$EO_eraseline_array[$x]=Number($EO_eraseline_array[$x]) ;Convert these entries from strings to numbers
	Next
	GUICtrlSetData($GUI_progress_loadbar,10) ;Progress bar to 10%

;Debug display actual lines that are not being copied
	;Local $debugarray[$EO_eraseline_array[0]+1]
	;For $x=1 To $EO_eraseline_array[0]
	;	$debugarray[$x]=$PA_saveread_array[$EO_eraseline_array[$x]]
	;Next
	;_ArrayDisplay($debugarray)

;Reduce the size of $PA_saveread_array by copying over itself without the lines in $EO_eraseline_array
;This is a *MUCH* faster method than deleting the lines one-by-one using _ArrayDelete() on $PA_saveread_array for an object with ~100 entries took 30+ seconds on my i7 - too slow
;We will start at the first $EO_eraseline_array line (which will correspond 1-to-1 with $PA_saveread_array) and start writing values back to $PA_saveread_array offset to compensate for the "erased" value
;After that, we will resize $PA_saveread_array which will drop the values off of the end. This should give us a complete save file minus the objects the user specified to erase
	$EO_progresstimer=TimerInit() ;Timer to know when to update the progress bar
	$EO_array_copy_offset=0 ;This will be used to compensate for the skipped rows in $PA_saveread_array. It will directly correspond to where we are in $EO_eraseline_array, so we can use it as a pointer
	For $x=$EO_eraseline_array[1] To $PA_saveread_array[0] ;Start at the first line of $EO_eraseline_array since we haven't skipped any lines yet
		If $EO_array_copy_offset<$EO_eraseline_array[0] Then
			For $y=1 To 9999 ;Since there are consecutive rows with matches, we need to use a loop until we don't find matches
				If $x+$EO_array_copy_offset==$EO_eraseline_array[$EO_array_copy_offset+1] Then ;Look for the next offset
					$EO_array_copy_offset+=1 ;Increase the offset/pointer by 1
				Else
					ExitLoop ;Exit $y For loop
				EndIf
				If $EO_array_copy_offset==$EO_eraseline_array[0] Then ExitLoop ;Prevent out of array range error, exit $y For loop
			Next
		EndIf

		$PA_saveread_array[$x]=$PA_saveread_array[$x+$EO_array_copy_offset] ;Copy lines of $PA_saveread_array while "skipping" the lines in $EO_eraseline_array by offsetting the pointer
		If $x+$EO_array_copy_offset==$PA_saveread_array[0] Then	ExitLoop ;Reached the end of the array, terminate $x For loop

		If TimerDiff($EO_progresstimer)>500 Then ;500ms (half a second) has passed, time to update the progress bar/list controls
			GUICtrlSetData($GUI_progress_loadbar,Floor($x/$PA_saveread_array[0]*90)+10) ;Calculate progress in percentage for the remaining 90% of the progress bar
			_updatelist($GUI_list_objectlist,$PA_objectlist_array) ;Push updated data to the list control
			$EO_progresstimer=TimerInit() ;Reset timer
		EndIf
	Next

	ReDim $PA_saveread_array[$PA_saveread_array[0]-$EO_eraseline_array[0]+1] ;Resize array
	$PA_saveread_array[0]=UBound($PA_saveread_array)-1
	GUICtrlSetData($GUI_progress_loadbar,100) ;Progress bar to 100%
	GUICtrlSetData($GUI_label_status,$EO_object_count&" Objects Erased.")

	Return("") ;return to _main
EndFunc ;_eraseobject

Func _savefile($GUI_combobox_savefilelist,$GUI_label_status,$GUI_list_objectlist,$GUI_progress_loadbar,$PA_loaded_savefile)
	GUICtrlSetData($GUI_label_status,"Backing up savegame: "&StringLeft(GUICtrlRead($GUI_combobox_savefilelist),27))
	If FileMove($PA_loaded_savefile,$PA_loaded_savefile&"-BACKUP-"&@YEAR&@MON&@MDAY&"-"&@HOUR&@MIN&@SEC)==0 Then _error($PA_loaded_savefile&" could not be backed up to "&$PA_loaded_savefile&"-BACKUP-"&@YEAR&@MON&@MDAY&"-"&@HOUR&@MIN&@SEC) ;FileMove effectively renames a file when used this way
	GUICtrlSetData($GUI_progress_loadbar,20) ;Progress bar to 20%
	If _FileWriteFromArray($PA_loaded_savefile,$PA_saveread_array,1)==0 Then  _error($PA_loaded_savefile&" could not be written to disk") ;Dump the array into the file - should be very quick, even with 100,000+ lines
	GUICtrlSetData($GUI_progress_loadbar,100) ;Progress bar to 100%
	GUICtrlSetData($GUI_label_status,StringLeft(GUICtrlRead($GUI_combobox_savefilelist),17)&" was successfully backed up and saved.")
	Return("") ;return to _main
EndFunc ;_savefile

Func _arrayerase($AE_begin,$AE_end=0) ;_ArrayDelete() is stupidly slow, so we have to build our own function
;Declare local vars
	Local $AE_arrayoffset=0
	If $AE_end==0 Then
		Local $AE_temparray[$PA_saveread_array[0]] ;The deletion of the BEGIN line will remove 1 line from the array, but entry 0 will be used for the index count anyway, so the nullify eachother
	Else
		Local $AE_temparray[$PA_saveread_array[0]-($AE_end-$AE_begin)]
	EndIf
	$AE_temparray[0]=UBound($AE_temparray)-1 ;Set index count
	;If $AE_end<>0 Then MsgBox(0,"debug _arrayerase","$AE_begin=="&$AE_begin&@LF&"$AE_end=="&$AE_end&@LF&"$PA_saveread_array[0]=="&$PA_saveread_array[0]&@LF&"$AE_temparray[0]=="&$AE_temparray[0])

	For $x=1 To $AE_temparray[0]
		If $x==$AE_begin Then
			If $AE_end==0 Then
				$AE_arrayoffset=1
			Else
				$AE_arrayoffset=1+$AE_end-$AE_begin
			EndIf
			;If $AE_end<>0 Then MsgBox(0,"debug _arrayerase",$x&": "&$PA_saveread_array[$x]&@LF&"-> "&$AE_arrayoffset&@LF&$x+$AE_arrayoffset&": "&$PA_saveread_array[$x+$AE_arrayoffset])
		EndIf
		$AE_temparray[$x]=$PA_saveread_array[$x+$AE_arrayoffset]
	Next

	$PA_saveread_array=$AE_temparray
EndFunc ;_arrayerase
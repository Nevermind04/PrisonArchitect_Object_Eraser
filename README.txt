--PRISONARCHITECT OBJECT ERASER README--
	Prison Architect Object Eraser has been designed to be a small, simple utility to assist in bulk erasing specific objects from Prison Architect save
	games. If you have a problem with the operation of this utility, please message me at Reddit: https://reddit.com/message/compose/?to=Nevermind04

	Prison Architect is an excellent game, but it is currently at the alpha stage of its development cycle (at the time of writing this README). Every
	once in a while, there are new objects added to the Prison Architect game that do not quite behave like you would expect them to behave. From dirty
	prison uniforms being left all over prisons to food trays piling up to cooked food being dumped forever into storage rooms to mail courier bags being
	delivered until your prison is full, these little bugs only have one thing in common: hundreds of objects littering the rooms of your prisons.

	Objects can be manually deleted line by line in your save files, but that is an extremely tedious and time-consuming task. This utility is NOT
	designed to fix the bugs that cause the objects to pile up, but rather to fully automate the process of removing these annoying objects from your
	prison's savegame files.

	This utility should be able to recognize new objects as the Prison Architect developers add things to the game. If a new object is added and this
	utility fails to find it, please message me at Reddit (see the link on the 3rd line of this README) and I will issue an update via GitHub as soon as
	time permits. This utility works for the PC version of Prison Architect ONLY. I have absolutely no intentions of supporting other platforms, ever.

--USAGE--
	01) Close Prison Architect
	02) Open PA_Object_Eraser.exe
	03) Select your savegame file from the drop-down list at the top
	04) Press the "Load Save File" button
	05) Wait for your file to load (it should not take more than a few seconds)
	06) All of the objects in your prison will be listed with their quantities in the big box in the center of the utility
	07) Click the list to select the objects you would like to erase
	08) Press the "Erase Objects" button to erase these objects
	09) When you are finished erasing objects, click the "Save File" button to save the changes into your savegame
	10) A backup of your savegame will automatically be created in your savegame directory (this utility will not display your backups to reduce clutter)
	11) Start Prison Architect, load your savegame, and enjoy your (hopefully) less cluttered prison!

--SAVEGAME BACKUPS--
	If you use this utility frequently, old backups of your savegames will pile up in your savegame folder. To access this folder, simply click the
	"Open Save Directory" button, or paste the following into a File Explorer address bar: %localappdata%\Introversion\Prison Architect\saves

--(MAYBE) PLANNED FEATURES--
	These are things I have in mind for the future. None of these features will be released on any sort of schedule, but rather whenever I get around to
	it. I work full-time and I will maintain this utility in my space time, so these features may be done tomorrow, next week, next month, or never.
	   - Erase prisoners by security level (Min Sec, Normal Sec, Max Sec, Supermax, Protected, etc.)
	   - Erase rooms of one type (Cell, Shower, Canteen, etc.)
	   - A limit on the number of savegame backups in your savegame directory before automatically removing old backups (to prevent clutter)
	   - Improving the aesthetics of this utility - it is currently bare-bones and ugly

--CHANGELOG--
	0.5.2 - 2015-06-18
	   - Initial Stable Release
	   - Object list is dynamically populated from savegame file; should work on future versions of Prison Architect
	   - Automatic backups when saving changes to file

--SOFTWARE LICENSE--
	Copyright (c) 2015 Nevermind04

	The MIT License (MIT)

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
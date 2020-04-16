#SingleInstance,Force
global settings:=new xml("settings")
if(FileExist("workspaces.ico"))
	Menu,Tray,Icon,Workspaces.ico
Gui()
return
show:
WinShow,% hwnd([1])
return
capture(){
	static node
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	node:=settings.ssn("//*[@tv='" TV_GetSelection() "']"),node:=ssn(node,"ancestor-or-self::workspace")
	if !node
		return m("Please select or create a workspace to add windows to")
	Gui,2:Destroy
	Gui,2:Default
	Gui,Add,ListView,w600 h200,Window|hwnd
	Gui,Add,Button,gchoose Default,Add Selected
	WinGet,list,list
	Loop,%list%{
		WinGetTitle,title,% "ahk_id" list%A_Index%
		WinGet,max,MinMax,% "ahk_id" list%A_Index%
		if(max!=0||title="")
			continue
		if(title="program manager")
			Continue
		WinGetPos,x,y,w,h,% "ahk_id" list%A_Index%
		if title
			LV_Add("",title,list%A_Index%)
	}
	windows:=settings.sn("//window")
	while,ww:=windows.item[A_Index-1],ea:=xml.ea(ww)
		LV_Add("",ea.title)
	Loop,3
		LV_ModifyCol(A_Index,"AutoHDR")
	Gui,Show,,% "Select Windows To Add To : " ssn(node,"@title").text
	return
	choose:
	WorkSpaceState(),next:=0
	Gui,2:Default
	Gui,2:ListView,SysListView321
	while,next:=LV_GetNext(next){
		LV_GetText(win,next,2)
		if(win=""){
			LV_GetText(title,next,1)
			if(ssn(node,"window[@title='" title "']"))
				Continue
			copy:=settings.ssn("//window[@title='" title "']")
			clone:=copy.clonenode(1)
			node.AppendChild(clone),node.SetAttribute("expand",1)
			Continue
		}
		for Item in ComObjCreate("Shell.Application").Windows
			if(item.hwnd=win)
				run:=RegExReplace(SubStr(uridecode(item.locationurl),9),"\/","\")
		aid:="ahk_id" win
		WinGetTitle,title,%aid%
		WinGetClass,class,%aid%
		WinGetPos,x,y,w,h,%aid%
		Position:="x" x " y" y " w" w " h" h
		WinGet,list,list
		if(run=""){
			Loop,%list%{
				hwnd:=list%A_Index%
				WinGetTitle,wintitle,% "ahk_id" hwnd
				if (wintitle==title){
					WinGet,Run,processpath,ahk_id%hwnd%
					Break
				}
			}
		}
		WinGet,maximize,MinMax,%title%
		SysGet,count,MonitorCount
		WinRestore,% hwnd([1])
		WinActivate,% hwnd([1])
		if !ssn(node,"window[@title='" title "']"){
			top:=settings.under({under:node,node:"window",att:{title:title}})
			for a,b in {Class:class,Maximize:0,Run:Run,"Auto Close":0,"Auto Open":0}
				settings.under({under:top,node:"item",att:{title:a,value:b}})
			mc:=settings.under({under:top,node:"monitor",att:{title:"Monitor Count",value:count}})
			settings.under({under:mc,node:"position",att:{title:"Position",value:position}})
			node.SetAttribute("expand",1)
		}
		run:=""
	}
	Gui,2:Destroy
	PopulateGroups()
	return
}
Create_Workspace(){
	createworkspace:
	InputBox,workspace,Workspace Name,Enter the name for the new workspace
	if(ErrorLevel||workspace="")
		return
	if settings.ssn("//workspaces/workspace[@title='" workspace "']")
		return m("Workspace exists.")
	select:=settings.sn("//*[@select]")
	while,ss:=select.item[A_Index-1]
		ss.RemoveAttribute("select")
	ws:=settings.Add({path:"workspaces/workspace",att:{title:workspace,select:1},dup:1})
	Populategroups()
	return
}
delete(){
	delete:
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	ControlGetFocus,Focus,% hwnd([1])
	if(Focus="SysTreeView321"){
		sel:=TV_GetSelection(),node:=settings.ssn("//*[@tv='" sel "']"),ea:=xml.ea(node)
		if(node.nodename="workspaces")
			return m("Can not delete the main workspaces")
		if(node.nodename="window"){
			tv:=TV_GetNext(sel)?TV_GetNext(sel):TV_GetPrev(sel)?TV_GetPrev(sel):TV_GetParent(sel)
			TV_Modify(tv,"Select Vis Focus"),node.ParentNode.RemoveChild(node)
			return PopulateGroups(1)
		}
		if(node.nodename="workspace"){
			MsgBox,308,Are you sure?,This action can not be undone.
			IfMsgBox,No
				return
			node.ParentNode.RemoveChild(node),PopulateGroups(1)
		}if(ea.title="run")
			node.SetAttribute("value",""),TV_Modify(sel,"","Run")
		return
		Gui,1:Default
		Gui,1:TreeView,SysTreeView321
		return
		rem:=settings.ssn("//*[@tv='" TV_GetSelection() "']"),rem.ParentNode.RemoveChild(rem)
		PopulateGroups(1)
	}
	return
}
exit(){
	keyexit:
	ExitApp
	return
	Exit:
	WorkSpaceState()
	tv:=settings.sn("//*[@tv]")
	while,tt:=tv.item[A_Index-1]
		tt.RemoveAttribute("tv")
	settings.save(1)
	ExitApp
	return
}
Find(doc,node,find){
	if InStr(find,"'")
		return doc.SelectSingleNode(node "[contains(.,concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "'))]/..")
	else
		return doc.SelectSingleNode(node "[.='" find "']/..")
}
Gui(){
	static
	SetTitleMatchMode,2
	Gui,+hwndhwnd
	hwnd(1,hwnd)
	Hotkey,IfWinActive,% hwnd([1])
	Hotkey,Delete,Delete,On
	Hotkey,^down,movedown,On
	Hotkey,^up,moveup,On
	Hotkey,~Enter,Enter,On
	Hotkey,+Escape,keyExit,On
	Gui,Add,TreeView,w500 h400 AltSubmit gtv hwndtv
	Gui,Add,Button,gcreateworkspace,&Create Workspace
	Gui,Add,Button,gcapture,&Add Windows To Selected Workspace
	Gui,Add,Button,gupdatepos,&Update Open Windows Positions
	Gui,Add,Button,gcontract,Con&tract All Workspaces
	Gui,Add,Button,gupdate,Update Program
	Gui,Add,Button,ghelp,&Help
	hwnd("addtoworkspace",atw),hwnd("tv",tv)
	Version=0.001.6
	Gui,Show,,Workspace %version%
	PopulateGroups(),tv()
	OnExit,Exit
	Menu,Tray,NoStandard
	Menu,Tray,Add,Show Workspaces,show
	Menu,Tray,Default,Show Workspaces
	Menu,Tray,Standard
	if win:=settings.ssn("//windows")
		win.ParentNode.RemoveChild(win)
	return
	contract:
	WorkSpaceState(),contract:=settings.sn("//*[@expand]")
	GuiControl,-Redraw,SysTreeView321
	while,cc:=contract.item[A_Index-1]
		if(cc.nodename!="workspaces")
			TV_Modify(ssn(cc,"@tv").text,"-Expand")
	GuiControl,+Redraw,SysTreeView321
	return
	toggle:
	Gui,1:TreeView,SysTreeView321
	Gui,1:Default
	tv:=settings.ssn("//*[@tv='" TV_GetSelection() "']")
	if (tv.nodename!="Workspace")
		return m("Select a Workspace to add windows to")
	Gui,3:Destroy
	Gui,3:Default
	Gui,Add,ListView,w400 h300,Window
	Gui,Add,Button,gaddto Default,% "Add Selected to " ssn(tv,"@title").text
	win:=settings.sn("//windows/*")
	while,ww:=win.item[A_Index-1],ea:=xml.ea(ww)
		LV_Add("",ea.title)
	Gui,Show,,% "Add To " ssn(tv,"@title").text
	return
	addto:
	Gui,3:Default
	Gui,3:ListView,SysListView321
	next:=0
	while,next:=LV_GetNext(next),LV_GetText(name,next)
		if !ssn(tv,"window[@title='" name "']")
			node:=settings.find("//windows/window/@title",name),clone:=node.clonenode(1),tv.AppendChild(clone)
	tv.SetAttribute("expand",1),PopulateGroups()
	return
	3GuiEscape:
	Gui,3:Destroy
	return
}
hwnd(win,hwnd=""){
	static window:=[]
	if win=get
		return window
	if (win.rem){
		Gui,1:-Disabled
		Gui,1:Default
		WindowTracker.Exit(win.rem)
		if !window[win.rem]
			Gui,% win.rem ":Destroy"
		Else
			DllCall("DestroyWindow",uptr,window[win.rem])
		window[win.rem]:=""
	}
	if IsObject(win)
		return "ahk_id" window[win.1]
	if !hwnd
		return window[win]
	window[win]:=hwnd
}
m(x*){
	for a,b in x
		list.=b "`n"
	MsgBox,,AHK Studio,% list
}
t(x*){
	for a,b in x
		list.=b "`n"
	ToolTip,% list
}
PopulateGroups(save:=0){
	static lastkeys:=[]
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	if save
		WorkSpaceState()
	GuiControl,1:-Redraw,SysTreeView321
	TV_Delete(),TreeView:=[],lastkeys:=[]
	for a in lastkeys{
		Hotkey,IfWinActive
		Hotkey,%a%,Hotkey,Off
	}
	for a,b in {workspaces:"Workspaces"}{
		info:=settings.sn("//" a "/descendant-or-self::*")
		while,ii:=info.item[A_Index-1],ea:=xml.ea(ii){
			value:=ea.hotkey?" = " ea.hotkey:ea.value!=""?" = " ea.value:"",title:=ea.title?ea.title:b
			ii.SetAttribute("tv",TV_Add(title value,ssn(ii.ParentNode,"@tv").text))
			if(ea.hotkey){
				Hotkey,IfWinActive
				Hotkey,% ea.Hotkey,hotkey,On
				lastkeys[ea.hotkey]:=1
			}
		}
	}
	set:=settings.sn("//Settings/descendant-or-self::*")
	if (set.length!=3){
		top:=settings.Add({path:"Settings",att:{name:"Settings"}})
		for a,b in ["Hide/Show GUI","Toggle Current Workspace"]
			if !ssn(top,"setting[@name='" b "']")
				settings.under({under:top,node:"setting",att:{name:b}})
		set:=settings.sn("//Settings/descendant-or-self::*")
	}
	while,ss:=set.item[A_Index-1],ea:=xml.ea(ss){
		hotkey:=ea.hotkey?" = " ea.hotkey:""
		tv:=TV_Add(ea.name hotkey,ssn(ss.ParentNode,"@tv").text),ss.SetAttribute("tv",tv)
		if(hotkey){
			Hotkey,IfWinActive
			Hotkey,% ea.Hotkey,hotkey,On
			lastkeys[ea.hotkey]:=1
		}
	}
	select:=settings.sn("//*[@select]"),tv:=ssn(Select.item[0],"@tv").text,expand:=settings.sn("//*[@expand]"),VisFirst:=settings.ssn("//*[@VisFirst]/@tv").text
	while,ss:=select.item[A_Index-1]
		ss.RemoveAttribute("select")
	while,ee:=expand.item[A_Index-1],ea:=xml.ea(ee)
		TV_Modify(ea.tv,"Expand")
	select:=settings.sn("//*[@select]"),TV_Modify(tv,"Select Vis Focus")
	TV_Modify(VisFirst,"VisFirst")
	GuiControl,1:+Redraw,SysTreeView321
	return
}
class xml{
	keep:=[]
	__New(param*){
		if !FileExist(A_ScriptDir "\lib")
			FileCreateDir,%A_ScriptDir%\lib
		root:=param.1,file:=param.2
		file:=file?file:root ".xml"
		temp:=ComObjCreate("MSXML2.DOMDocument"),temp.setProperty("SelectionLanguage","XPath")
		this.xml:=temp
		if FileExist(file){
			ff:=FileOpen(file,"r","utf-16"),info:=ff.Read(ff.length)
			if(info=""){
				this.xml:=this.CreateElement(temp,root)
				FileDelete,%file%
			}else
				temp.loadxml(info),this.xml:=temp
		}else
			this.xml:=this.CreateElement(temp,root)
		this.file:=file
		xml.keep[root]:=this
	}
	CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}
	lang(info){
		info:=info=""?"XPath":"XSLPattern"
		this.xml.setProperty("SelectionLanguage",info)
	}
	unique(info){
		if (info.check&&info.text)
			return
		if info.under{
			if info.check
				find:=info.under.SelectSingleNode("*[@" info.check "='" info.att[info.check] "']")
			if info.Text
				find:=this.cssn(info.under,"*[text()='" info.text "']")
			if !find
				find:=this.under({under:info.under,att:info.att,node:info.path})
			for a,b in info.att
				find.SetAttribute(a,b)
		}
		else
		{
			if info.check
				find:=this.ssn("//" info.path "[@" info.check "='" info.att[info.check] "']")
			else if info.text
				find:=this.ssn("//" info.path "[text()='" info.text "']")
			if !find
				find:=this.add({path:info.path,att:info.att,dup:1})
			for a,b in info.att
				find.SetAttribute(a,b)
		}
		if info.text
			find.text:=info.text
		return find
	}
	Add(info){
		path:=info.path,p:="/",dup:=this.ssn("//" path)?1:0
		if next:=this.ssn("//" path)?this.ssn("//" path):this.ssn("//*")
			Loop,Parse,path,/
				last:=A_LoopField,p.="/" last,next:=this.ssn(p)?this.ssn(p):next.appendchild(this.xml.CreateElement(last))
		if (info.dup&&dup)
			next:=next.parentnode.appendchild(this.xml.CreateElement(last))
		for a,b in info.att
			next.SetAttribute(a,b)
		for a,b in StrSplit(info.list,",")
			next.SetAttribute(b,info.att[b])
		if info.text!=""
			next.text:=info.text
		return next
	}
	under(info){
		new:=info.under.appendchild(this.xml.createelement(info.node))
		for a,b in info.att
			new.SetAttribute(a,b)
		for a,b in StrSplit(info.list,",")
			new.SetAttribute(b,info.att[b])
		if info.text
			new.text:=info.text
		return new
	}
	findsn(node,find){
		if InStr(find,"'")
			return this.xml.SelectNodes(node "[contains(.,concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "'))]/..")
		else
			return this.xml.SelectNodes(node "[.='" find "']/..")
	}
	find(node,find){
		if InStr(find,"'")
			return this.xml.SelectSingleNode(node "[contains(.,concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "'))]/..")
		else
			return this.xml.SelectSingleNode(node "[.='" find "']/..")
	}
	ssn(node){
		return this.xml.SelectSingleNode(node)
	}
	sn(node){
		return this.xml.SelectNodes(node)
	}
	__Get(x=""){
		return this.xml.xml
	}
	Get(path,Default){
		return value:=this.ssn(path).text!=""?this.ssn(path).text:Default
	}
	transform(){
		static
		if !IsObject(xsl){
			xsl:=ComObjCreate("MSXML2.DOMDocument")
			style=
			(
			<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
			<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
			<xsl:template match="@*|node()">
			<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
			<xsl:for-each select="@*">
			<xsl:text></xsl:text>		
			</xsl:for-each>
			</xsl:copy>
			</xsl:template>
			</xsl:stylesheet>
			)
			xsl.loadXML(style),style:=null
		}
		this.xml.transformNodeToObject(xsl,this.xml)
	}
	save(x*){
		if x.1=1
			this.Transform()
		filename:=this.file?this.file:x.1.1,file:=fileopen(filename,"rw","Utf-16")
		if(this.xml.xml==file.read(file.length))
			return
		file.seek(0),file.write(this[]),file.length(file.position)
	}
	remove(rem){
		if !IsObject(rem)
			rem:=this.ssn(rem)
		rem.ParentNode.RemoveChild(rem)
	}
	ea(path){
		list:=[]
		if nodes:=path.nodename
			nodes:=path.SelectNodes("@*")
		else if path.text
			nodes:=this.sn("//*[text()='" path.text "']/@*")
		else if !IsObject(path)
			nodes:=this.sn(path "/@*")
		else
			for a,b in path
				nodes:=this.sn("//*[@" a "='" b "']/@*")
		while,n:=nodes.item(A_Index-1)
			list[n.nodename]:=n.text
		return list
	}
}
ssn(node,path){
	return node.SelectSingleNode(path)
}
sn(node,path){
	return node.SelectNodes(path)
}
AddHotkey(){
	static
	KeyWait,Enter,U
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	workspace:=settings.ssn("//*[@tv='" TV_GetSelection() "']")
	if !(InStr(workspace.nodename,"workspace")||workspace.nodename="setting")
		return m("Please select a workspace to add a hotkey to")
	Gui,2:Destroy
	Gui,2:Default
	Gui,Add,Hotkey,w200 vhotkey hwndhotkeyhwnd,% ssn(workspace,"@hotkey").text
	Gui,Add,Edit,w200 vedit gedithotkey
	Gui,Add,Button,gsavehotkey Default,Save Hotkey
	Gui,Show,,Edit Hotkey
	return
	2GuiEscape:
	2GuiClose:
	Gui,2:Destroy
	return
	edithotkey:
	Gui,2:Submit,Nohide
	GuiControl,2:,%hotkeyhwnd%,%edit%
	return
	savehotkey:
	Gui,Submit,Nohide
	if(Hotkey=""&&edit){
		MsgBox,36,Non-Standard Hotkey,This is a non-standard hotkey. Use it?
		IfMsgBox,No
			return
		hotkey:=edit
	}
	workspace.SetAttribute("hotkey",hotkey),PopulateGroups(1)
	Gui,2:Destroy
	return
}
WorkSpaceState(select:=1){
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	if TV_GetChild(0){
		for a,b in ["VisFirst","expand","select"]{
			rem:=settings.sn("//*[@" b "='1']")
			while,rr:=rem.Item[A_Index-1]
				rr.RemoveAttribute(b)
		}tv:=0
		while,tv:=TV_GetNext(tv,"F")
			if TV_Get(tv,"E")
				(flan:=settings.ssn("//*[@tv='" tv "']")).SetAttribute("expand",1)
		SendMessage,0x1100+10,5,,,% hwnd(["tv"])
		if ErrorLevel
			settings.ssn("//*[@tv='" ErrorLevel "']").SetAttribute("VisFirst","1")
		settings.ssn("//*[@tv='" TV_GetSelection() "']").SetAttribute("select",1)
	}
}
Move_Windows(){
	movedown:
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	current:=settings.ssn("//*[@tv='" TV_GetSelection() "']")
	if(current.nodename!="window"||current.nextsibling.xml="")
		return
	WorkSpaceState(),root:=current.ParentNode
	if next:=current.nextsibling.nextsibling
		root.insertbefore(current,next)
	else
		root.AppendChild(current)
	PopulateGroups(1)
	return
	moveup:
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	current:=settings.ssn("//*[@tv='" TV_GetSelection() "']")
	if(current.nodename!="window"||(prev:=current.previoussibling).xml="")
		return
	WorkSpaceState(),root:=current.ParentNode,root.InsertBefore(current,prev),PopulateGroups(1)
	return
}
enter(){
	enter:
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	ControlGetFocus,Focus,% hwnd([1])
	if(focus="SysTreeView321"){
		sel:=TV_GetSelection(),current:=settings.ssn("//*[@tv='" sel "']"),ea:=xml.ea(current)
		if InStr(current.nodename,"workspace")
			AddHotkey()
		else if(ea.title~="(Auto Close|Auto Open|Maximize)"){
			current.SetAttribute("value",ea.value?0:1)
		}else if(ea.title="run"){
			file:=ea.run
			SplitPath,file,,dir
			FileSelectFile,newinfo,,%dir%,Please select the program to run: Escape for Folder Select
			if(FileExist(newinfo)=""||newinfo="")
				return
			current.SetAttribute("value",newinfo)
		}else if(ea.title="position")
			return updatepos(current),PopulateGroups()
		else if(current.nodename="window"){
			InputBox,newinfo,New Title,Enter a new title,,,,,,,,% ssn(current,"@title").text
			if(ErrorLevel||newinfo="")
				return
			current.SetAttribute("title",newinfo)
		}else if(current.nodename="setting"){
			AddHotkey()
		}
		PopulateGroups(1)
	}
	return
}
tv(check:=0){
	tv:
	Gui,1:TreeView,SysTreeView321
	Gui,1:Default
	if(A_GuiEvent="doubleclick"){
		node:=settings.ssn("//*[@tv='" A_EventInfo "']"),ea:=xml.ea(node)
		if(ea.title="Run"){
			InputBox,run,New Run Value,Enter a file path/folder to run,,,,,,,,% ea.value
			if(ErrorLevel||run="")
				return
			return node.SetAttribute("value",run),PopulateGroups(1)
		}if(ea.title="position"){
			InputBox,newpos,New Position,Edit the windows position,,,,,,,,% ea.value
			if(ErrorLevel||newpos="")
				return
			return node.SetAttribute("value",newpos),PopulateGroups(1)
		}
	}
	else if(A_GuiEvent="RightClick"){
		node:=settings.ssn("//*[@tv='" A_EventInfo "']"),ea:=xml.ea(node)
		if(node.nodename="window"){
			pos:=[]
			if !WinExist(ea.title){
				run:=ssn(node,"item[@title='Run']/@value").text
				SplitPath,run,file,dir
				if !file
					Run,%dir%
				else
					Run,%file%,%dir%
			}
			WinGet,max,MinMax,% ea.title
			if(max=-1)
				WinRestore,% ea.title
			WinActivate,% ea.title
			SysGet,count,MonitorCount
			position:=(ssn(node,"*[@title='Monitor Count'][@value='" count "']/position/@value").text)
			position:=position?position:ssn(node,"descendant::position/@value").text
			for a,b in StrSplit(position," ")
				pos[SubStr(b,1,1)]:=SubStr(b,2)
			if(getvalue(node,"Maximize")){
				WinRestore,% ea.title
				WinMaximize,% ea.title
			}else
				WinMove,% ea.title,,% pos.x,% pos.y,% pos.w,% pos.h
			WinActivate,% hwnd([1])
		}if(ea.title="run"){
			FileSelectFolder,dir,,,Select a folder to open
			if ErrorLevel
				return
			node.SetAttribute("value",dir),PopulateGroups(1)
		}
	}
	return
}
update(){
	update:
	if FileExist("gui.ahk")
		return
	URLDownloadToFile,http://files.maestrith.com/Workspace/Workspace.ahk,temp.ahk
	FileRead,temp,temp.ahk
	if InStr(temp,"Find This"){
		settings.save(1)
		SplitPath,A_ScriptFullPath,file,dir,,name
		FileMove,%A_ScriptName%,%dir%\%name% %A_Now%.ahk,1
		FileMove,temp.ahk,%A_ScriptName%,1
		Reload
		ExitApp
	}
	return
}
Hotkey(){
	static
	hotkey:
	current:=settings.ssn("//*[@hotkey='" A_ThisHotkey "']")
	if(current.nodename="workspaces"){
		if Visible
			return t(),visible:=0
		list:=settings.sn("//workspace[@hotkey]"),keylist:=""
		while,ll:=list.item[A_Index-1],ea:=xml.ea(ll)
			keylist.=ea.title " = " ea.hotkey "`n"
		Visible:=1
		return t(keylist)
	}else if(current.nodename="setting"),ea:=xml.ea(current){
		if(ea.name="Hide/Show GUI"){
			GuiClose:
			WinGet,max,minmax,% hwnd([1])
			if max=0
				WinHide,% hwnd([1])
			if (max=""){
				WinShow,% hwnd([1])
				WinActivate,% hwnd([1])
			}
			return
		}else if(ea.name="Toggle Current Workspace"){
			current:=settings.ssn("//workspace[@current]")
			if !current
				settings.ssn("//workspace").SetAttribute("current",1)
			else{
				if(next:=current.nextsibling){
					current.RemoveAttribute("current")
					next.SetAttribute("current",1)
				}else{
					current.RemoveAttribute("current")
					settings.ssn("//workspace").SetAttribute("current",1)
				}
			}
			current:=settings.ssn("//workspace[@current]")
			Restore(sn(current,"descendant::window"),1,1)
		}
	}
	windows:=settings.sn("//*[@hotkey='" A_ThisHotkey "']/descendant::window"),minimized:=""
	Gui,1:Default
	Gui,1:TreeView,SysTreeView321
	TV_GetText(workspace,TV_GetSelection())
	while,ww:=windows.item[A_Index-1],ea:=xml.ea(ww){
		if(WinActive(ea.title " ahk_class " getvalue(ww,"Class"))){
			position:=(ssn(ww,"*[@title='Monitor Count'][@value='" count "']/position/@value").text),position:=position?position:ssn(ww,"descendant::position/@value").text
			WinGetPos,x,y,w,h,% ea.title " ahk_class " getvalue(ww,"Class")
			for a,b in {x:x,y:y,w:w,h:h}{
				RegExMatch(position,"Oi)" a "(\d+)",found)
				if(found.1!=b){
					minimized:=1
					Goto,hkbottom
				}
			}
			minimized:=0
			goto,hkbottom
		}
	}Minimized:=1
	hkbottom:
	Restore(windows,minimized)
	return
}
UriDecode(Uri) {
	Pos := 1
	While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos)
	{
		VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code,2)
		Loop, Parse, Code, `%
			NumPut("0x" A_LoopField, Var, A_Index-1, "UChar")
		Decoded := StrGet(&Var, "UTF-8")
		Uri := SubStr(Uri, 1, Pos-1) . Decoded . SubStr(Uri, Pos+StrLen(Code)+1)
		Pos += StrLen(Decoded)+1
	}
	Return, Uri
}
getvalue(node,value){
	return ssn(node,"descendant::*[@title='" value "']/@value").text
}
Restore(windows,minimized,skipwait:=0){
	while,ww:=windows.item[windows.length-(A_Index)],ea:=xml.ea(ww){
		if(minimized){
			if (WinExist(ea.title)=0){
				if !getvalue(ww,"Auto Open")
					Continue
				file:=getvalue(ww,"Run")
				SplitPath,file,filename,dir
				if !filename
					Run,%dir%
				else
					Run,%filename%,%dir%
				WinWait,% ea.title,,1
			}
			WinActivate,% ea.title " ahk_class " class:=getvalue(ww,"Class")
			pos:=[]
			SysGet,count,MonitorCount
			position:=(ssn(ww,"*[@title='Monitor Count'][@value='" count "']/position/@value").text),position:=position?position:ssn(ww,"descendant::position/@value").text
			for a,b in StrSplit(position," ")
				pos[SubStr(b,1,1)]:=SubStr(b,2)
			if(getvalue(ww,"Maximize")){
				WinWaitActive,% ea.title
				WinMaximize,% ea.title
			}else
				WinMove,% ea.title,,% pos.x,% pos.y,% pos.w,% pos.h
		}else{
			WinGet,list,list,% "ahk_class" ssn(ww,"*[@title='Class']/@value").text
			match:=[]
			Loop,%list%
			{
				WinGetTitle,title,% "ahk_id" list%A_Index%
				if InStr(title,ea.title)
					match[title]:=list%A_Index%
			}
			for a,b in match{
				if(getvalue(ww,"Auto Close"))
					WinClose,ahk_id %b%
				else
					WinMinimize,ahk_id %b%
			}
		}
	}t()
}
Update_Positions(){
	updatepos:
	wl:=settings.sn("//window")
	while,ww:=wl.item[A_Index-1]{
		win:=ssn(ww,"@title").text
		WinGet,max,MinMax,%win%
		if (max=0)
			updatepos(ww)
	}PopulateGroups(1)
	return
}
updatepos(current){
	SysGet,count,MonitorCount
	parent:=ssn(current,"ancestor-or-self::window")
	WinGetPos,x,y,w,h,% ssn(parent,"@title").text
	if !position:=ssn(parent,"*[@title='Monitor Count'][@value='" count "']")
		position:=settings.under({under:parent,node:"monitor",att:{title:"Monitor Count",value:count}})
	if !pos:=ssn(position,"position")
		pos:=settings.under({under:position,node:"position",att:{title:"Position"}})
	if(x!=""&&y!=""&&w!=""&&h!=""){
		pos.SetAttribute("value","x" x " y" y " w" w " h" h)
	}else{
		InputBox,newinfo,New Position,Enter a new position for this window,,,,,,,,% ea.position
		if(ErrorLevel||newinfo="")
			return m("Please enter a value for this window")
		pos.SetAttribute("value",newinfo)
	}
	WorkSpaceState(1),pos.SetAttribute("select",1)
}
Help(){
	help=
(
Adding Workspaces: Alt+C

	Click Create Workspace

Adding Windows To A Workspace: Alt+A

	Highlight a workspace, then Click Add Windows To Selected Workspace

Update Open Windows Positions: Alt+U

	This will update the positions to all of the visible windows

Contract All Workspaces: Alt+T

	Contracts everything in the treeview except for the Workspaces


Adding Hotkeys:

	You can add hotkeys to the following by selecting the node and pressing Enter

	The main Workspaces node:
		This hotkey will display/hide the main hotkeys for your workspaces

	Any Workspace node:
		This will associate that workspace with a hotkey so when you press
			that hotkey it will hide/show those windows

	Settings:

		Hide/Show GUI:
			This will hide/show the main gui
	
		Toggle Current Workspace:
			This will bring the next workspace in the list to the forground

	Updating Individual Window Positions:

		Select the position attribute for the window and press enter
)
	Gui,2:Destroy
	Gui,2:Add,Text,w500 -Wrap,%help%
	Gui,2:Show,,Help
}
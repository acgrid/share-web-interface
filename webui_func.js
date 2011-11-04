function get_DL_Links(frm){
	var Table = document.getElementById("DLL");
	var DL_Box = document.getElementById("DL_LINKS");
	var DLItems = Table.getElementsByTagName("INPUT");
	DL_Box.style.display = "block";
	DL_Box.value = "";
	for(var i=0;i<DLItems.length;i++){
		if(DLItems.item(i).checked){
			var auth = (frm.elements['DLL_WithAuth'].checked) ? frm.elements['DLL_Auth'].value : "";
			DL_Box.value = DL_Box.value + DLItems.item(i).value + "\r\n" + location.protocol + "//" + auth + location.host + "/?extop=DL&FN=" + encodeURI(DLItems.item(i).value) + "\r\n";
		}
	}
	DL_Box.focus();
}

function encode_DL_Links(frm){
	var Table = document.getElementById("DLL");
	var DLItems = Table.getElementsByTagName("A");
	for(var i=0;i<DLItems.length;i++){
		DLItems.item(i).href = encodeURI(DLItems.item(i).href);
	}
}

function BatchSelect(sender, table){
	var mode = sender.checked;
	var table = document.getElementById(table);
	var Boxes = table.getElementsByTagName("INPUT");

	for(var i=1;i<Boxes.length;i++){
		if(Boxes.item(i).type == "checkbox"){
			Boxes.item(i).checked = (mode) ? true : false;
		}
	}
}

function SmileIT(smile,form,text){
   document.forms[form].elements[text].value = document.forms[form].elements[text].value+" "+smile+" ";
   document.forms[form].elements[text].focus();
}

function checkhash(){
	var hashinput = document.getElementById("hashbox");
	if ((hashinput.value.length != 40) && (hashinput.value.length != 0)){
		alert("Invaild Hash: Less than 40 digits.");
		return false;
	}
/*	if (hashinput.value.toUpperCase().replace("/[A-F]/g", "").length){
		alert("Invaild Hash: Unexpected character(s).");
		return false;
	}else{
		return true;
	}*/
}

function change(o,a,b,c){
var t=document.getElementById(o).getElementsByTagName("tr");
for(var i=0;i<t.length;i++){
   t[i].style.backgroundColor=(t[i].sectionRowIndex%2==0)?a:b;
   t[i].onmouseover=function(){
    if(this.x!="1")this.style.backgroundColor=c;
   }
   t[i].onmouseout=function(){
    if(this.x!="1")this.style.backgroundColor=(this.sectionRowIndex%2==0)?a:b;
   }
}
}

function getxmlhttp(){
	var xmlhttp=false;
	try {
		xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
	} catch(e) {
		try {
			xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		} catch(e) {
			xmlhttp = false;
		}
	}
	if (!xmlhttp && typeof XMLHttpRequest != 'undefined') {
		xmlhttp = new XMLHttpRequest();
	}
	return xmlhttp;
}

function do_ajax(section){
	var info = document.getElementById(section+'_Content');
	xmlhttp = getxmlhttp();
	xmlhttp.open("GET","/?ajax="+section);
	xmlhttp.onreadystatechange = function(){
		if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
			if (xmlhttp.responseText != 'NULL') {
				info.innerHTML = xmlhttp.responseText;
				change(section,"#c8e1fb","#eaf4fe","#d1eb88");
			}
		}
	}
	xmlhttp.send(null);
}

function dis_alpha(){
	var Items = document.getElementsByTagName("TABLE");
	for(var i=0;i<Items.length;i++){
		Items.item(i).style.opacity=1;
		Items.item(i).filters.alpha.opacity=100;
	}
	Items = document.getElementsByTagName("INPUT");
	for(var i=0;i<Items.length;i++){
		Items.item(i).style.opacity=1;
		Items.item(i).filters.alpha.opacity=100;
	}
	Items = document.getElementsByTagName("TEXTAREA");
	for(var i=0;i<Items.length;i++){
		Items.item(i).style.opacity=1;
		Items.item(i).filters.alpha.opacity=100;		
	}	
}

function prase_trigger_params(frm){
	var params = new String(frm.elements["TR_Params"].value);
	frm.reset();
	Pos_Hash = params.lastIndexOf(" ");
	frm.elements["TR_Hash"].value = params.substr(Pos_Hash+1,40);
	Pos_Size = params.lastIndexOf(" ",Pos_Hash-1);
	frm.elements["TR_MinSize"].value = params.substr(Pos_Size+1,Pos_Hash-Pos_Size-1).replace(/,/g,"");
	frm.elements["TR_MaxSize"].value = params.substr(Pos_Size+1,Pos_Hash-Pos_Size-1).replace(/,/g,"");
	Pos_ID = params.lastIndexOf(" ",Pos_Size-1);
	frm.elements["TR_ID"].value = params.substr(Pos_ID+1,Pos_Size-Pos_ID-1);
	frm.elements["TR_Keyword"].value = params.substr(0,Pos_ID);	
}

function BlockSelect(mode,box){
	if(mode){
		var boxes = document.getElementsByTagName("INPUT");
		for(var i=0;i<boxes.length;i++){
			if(boxes.item(i) == last_box) first = i;
			if(boxes.item(i) == box) second = i;
		}
		s = first < second ? first : second;
		e = first > second ? first : second;
		for(var j=s;j<e;j++) boxes.item(j).checked = true;
	}else{
		last_box = box;
	}
}

function PickCluster(cluster){
	position = prompt("Which cluster do you want to be changed?","5");
	if(position > 0 && position < 6) document.getElementById("Cluster_"+position).value = cluster;
}
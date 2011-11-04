function countdown(time)
{
	var status = document.getElementById("FL_AUTOREF_STATUS").value;
	if (status == "OFF") { return; }
	if (status == "RST") { 
	document.getElementById('FL_COUNTDOWN').innerHTML="0";
	init();
	}else{
		if (time <= 0){
		document.getElementById('FL_COUNTDOWN').innerHTML="0";
		do_ajax('MEMO');
		init();
		}
		else {
		document.getElementById('FL_COUNTDOWN').innerHTML=time;
		time=time-1;
		setTimeout("countdown("+time+")", 1000); 
		}
	}
}
function init(){
var time;
time = document.getElementById("FL_AUTOREF_START").value;
document.getElementById("FL_AUTOREF_STATUS").value = "ON";
document.getElementById('FL_COUNTDOWN').innerHTML=time;
countdown(time);
}
function reset(){
document.getElementById("FL_AUTOREF_STATUS").value = "RST";
}
function sw(){
if (document.getElementById("FL_AUTOREF_STATUS").value == "ON") {
	document.getElementById("FL_AUTOREF_STATUS").value = "OFF";
	document.getElementById('FL_COUNTDOWN').innerHTML = "Inf.";
}else{
	document.getElementById("FL_AUTOREF_STATUS").value = "ON";
	init();
}
}

//
// When the document has finished loading, the browser
// will invoke the function supplied here.  This
// is an anonymous function that simply requests that the 
// brower determine the current position, and when it's
// done, call the "Start" function  (which is at the end
// of this file)

$(document).ready(function() {
	Start();
});


//
// NewData is called by the browser after any request
// for data we have initiated completes
//
returnFunction = function(data) {

//	$("#data").html(data);
	console.log("returned function");
},


//
// The start function is called back once the document has 
// been loaded and the browser has determined the current location
//
Start = function(location) {
	$.get("portfolio.pl",
		{
			act:	"interactionWithPerl",
		}, returnFunction);
};

function displayGraph(){
	var stockname = document.getElementById('stockname').innerHTML;

	$.get("portfolio.pl",
		{
			act:	"viewStock",
			run: 1,
			stockID: stockname,
		}, callBackAfterGettingStockData);

};

function callBackAfterGettingStockData(data){
	var el = document.createElement( 'html' );
	el.innerHTML = data;
	//var tableData = el.getElementById("symbolDataDiv").innerHTML;
	var tableData2 = el.getElementsByTagName( 'pre' );
	$("#chartdata").html(data);
	console.log(tableData2);
	console.log("callback entered");
};



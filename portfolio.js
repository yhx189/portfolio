
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
	var stockname = document.getElementsByName('symbolForGraph')[0].value;
	var radios = document.getElementsByName('interval');
	var interval = "";
	for (var i = 0; i < radios.length; i++) {
	    if (radios[i].checked) {
	        // do whatever you want with the checked radio
	        interval = radios[i].value;
	        break;
	    }
	}

	var historical = 0;
	var current = 0;
	var predicted = 0;
	var symbolDataSelection = document.getElementById('symbolDataSelection');
    var dataSelected = symbolDataSelection.getElementsByTagName('input');
    for (var i = 0; i < dataSelected.length; i++) {
    	if(dataSelected[i].checked){
    		switch(dataSelected[i].value){
    			case "Historical":
    			historical = 1;
    			break;
    			case "Current":
    			current = 1;
    			break;
    			case "Predicted":
    			predicted = 1;
    			break;
    		}
    	}
	}

	console.log("historical" + historical);
	console.log("current" + current);
	console.log("predicted" + predicted);
	console.log(stockname);
	console.log(interval);
	console.log("display graph called");

	var htmlDate =  document.getElementById('stockStartDate').value;
	var startDate = new Date(htmlDate);
	if ( isNaN(startDate.valueOf()) ) { // Valid date
	    startDate = new Date();
	}else{
		startDate.setDate(startDate.getDate()+1);
	}
	
	var startDay = startDate.getDate();
	var startMonth = startDate.getMonth()+1;
	var startYear = startDate.getFullYear();
	var startDateString = startMonth + "/" + startDay + "/" + startYear;

	var endDate = startDate;

	switch(interval){
		case "week":
		endDate.setDate(endDate.getDate() + 7);
		break;
		case "month":
		endDate.setMonth(endDate.getMonth() + 1);
		break;
		case "quarter":
		endDate.setMonth(endDate.getMonth() + 3);
		break;
		case "year":
		endDate.setFullYear(endDate.getFullYear() + 1);
		break;
		case "fiveyears":
		endDate.setFullYear(endDate.getFullYear() + 5);
		break;
	}

	var endDay = endDate.getDate();
	var endMonth = endDate.getMonth()+1;
	var endYear = endDate.getFullYear();
	var endDateString = endMonth + "/" + endDay + "/" + endYear;

	var daysToPredict =  document.getElementById('daysToPredict').value;

	$.get("portfolio.pl",
		{
			act:	"viewStock",
			run: 1,
			stockSymbol: stockname,
			historical : historical,
			current : current,
			predicted : predicted,
			startDate : startDateString,
			endDate : endDateString,
			daysToPredict : daysToPredict
		}, callBackAfterGettingStockData);

};

function callBackAfterGettingStockData(data){
	var el = document.createElement( 'html' );
	el.innerHTML = data;
	//var tableData = el.getElementById("symbolDataDiv").innerHTML;
	var tableData2 = el.getElementsByTagName( 'pre' );
	$("#chartdata").html(data);
	console.log(data);
	console.log("callback entered");
};



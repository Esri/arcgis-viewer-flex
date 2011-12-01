// convert all characters to lowercase to simplify testing
    var agt=navigator.userAgent.toLowerCase();

    // *** BROWSER VERSION ***
    // Note: On IE5, these return 4, so use is_ie5up to detect IE5.
    var is_major = parseInt(navigator.appVersion);
    var is_minor = parseFloat(navigator.appVersion);

/*-----------------------------------
Determines browser
-----------------------------------*/
 // If you want to allow spoofing, take out the tests for opera and webtv.
    var is_nav  = ((agt.indexOf('mozilla')!=-1) && (agt.indexOf('spoofer')==-1)
                && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera')==-1));
                //&& (agt.indexOf('webtv')==-1) && (agt.indexOf('hotjava')==-1));

    var is_nav4 = (is_nav && (is_major == 4));
    var is_nav4up = (is_nav && (is_major >= 4));
    var is_navonly      = (is_nav && ((agt.indexOf(";nav") != -1) ||
                          (agt.indexOf("; nav") != -1)) );
    var is_nav6 = (is_nav && (is_major == 5));
    var is_nav6up = (is_nav && (is_major >= 5));

    var is_ie     = ((agt.indexOf("msie") != -1) && (agt.indexOf("opera") == -1));
    var is_ie3    = (is_ie && (is_major < 4));
    var is_ie4    = (is_ie && (is_major == 4) && (agt.indexOf("msie 4")!=-1) );
    var is_ie5    = (is_ie && (is_major == 4) && (agt.indexOf("msie 5.0")!=-1) );
    var is_ie5_5  = (is_ie && (is_major == 4) && (agt.indexOf("msie 5.5") !=-1));
    var is_ie5up  = (is_ie && !is_ie3 && !is_ie4);
    var is_ie5_5up =(is_ie && !is_ie3 && !is_ie4 && !is_ie5);
    var is_ie6    = (is_ie && (is_major == 4) && (agt.indexOf("msie 6.")!=-1) );
    var is_ie6up  = (is_ie && !is_ie3 && !is_ie4 && !is_ie5 && !is_ie5_5);

    var is_opera = (agt.indexOf("opera") != -1);
    var is_opera2 = (agt.indexOf("opera 2") != -1 || agt.indexOf("opera/2") != -1);
    var is_opera3 = (agt.indexOf("opera 3") != -1 || agt.indexOf("opera/3") != -1);
    var is_opera4 = (agt.indexOf("opera 4") != -1 || agt.indexOf("opera/4") != -1);
    var is_opera5 = (agt.indexOf("opera 5") != -1 || agt.indexOf("opera/5") != -1);
    var is_opera6 = (agt.indexOf("opera 6") != -1 || agt.indexOf("opera/6") != -1);
    var is_opera7up = (is_opera && !is_opera2 && !is_opera3 && !is_opera4 && !is_opera5 && !is_opera6);
    /*var is_safari   = ((agt.indexOf("safari") != -1);*/

    // *** PLATFORM ***
    var is_win   = ( (agt.indexOf("win")!=-1) || (agt.indexOf("16bit")!=-1) );
    // NOTE: On Opera 3.0, the userAgent string includes "Windows 95/NT4" on all
    //        Win32, so you can't distinguish between Win95 and WinNT.
    var is_win95 = ((agt.indexOf("win95")!=-1) || (agt.indexOf("windows 95")!=-1));

    var is_mac    = (agt.indexOf("mac")!=-1);

/*-----------------------------------
global variable initialization
-----------------------------------*/
//var is = new Is();

var swapArray = new Array();  //global that holds swap images info
var selectedImage = "getdirections";
var bWindow = null;
var layer;
var navHeight;

var layerArray = new Array();

/*Function to reload a page in NN4.7 when it is resized*/

 function handleResize() {
    if (is_nav4) {
        location.reload();
        return false;
    }
}

if (is_nav4) {
    window.captureEvents(Event.RESIZE);
    window.onresize = handleResize;
}

/*------------------------------------------------
Pop up window function for the links to mapmuseum
------------------------------------------------*/

function pop(URL, name) {
  bWindow = window.open(URL, name,"status=0,menubar=0,width=620,height=542");

}

function popCustom(URL,name,options) {
  bWindow = window.open(URL,name,options);
}

/*-----------------------------------
Called from the onLoad() inside the body tag
Creates arrays for all images and references
to the layers involved in the navigation
-----------------------------------*/
function initialize() {
    parseLayers(document);

}
function mapLayers() {
    subMapArray = new Array(getLayerRef('clientserver'),getLayerRef('crossplatform'),getLayerRef('richmapping'));
    subArrowArray = new Array('maparrow1', 'maparrow2', 'maparrow3');
    alert(subMapArray);
}
function loadGetDirectionsLayers() {
    subTextArray = new Array(getLayerRef('direto'),getLayerRef('nearby'));
}

function loadMapLayers() {
    subTextArray = new Array(getLayerRef('maptext1'), getLayerRef('maptext2'), getLayerRef('maptext3'));
    subMapArray = new Array(getLayerRef('largemap1'), getLayerRef('largemap2'), getLayerRef('largemap3'));
    subArrowArray = new Array('maparrow1', 'maparrow2', 'maparrow3');
}

function loadGateways() {
    subTextArray = new Array(getLayerRef('maptext1'), getLayerRef('maptext2'), getLayerRef('maptext3'), getLayerRef('maptext4'), getLayerRef('maptext5'));
    subMapArray = new Array(getLayerRef('largemap1'), getLayerRef('largemap2'), getLayerRef('largemap3'), getLayerRef('largemap4'), getLayerRef('largemap5'));
    subArrowArray = new Array('maparrow1', 'maparrow2', 'maparrow3', 'maparrow4', 'maparrow5');
}


//= Determines layer ID depending on the browser

function getLayerRef(layerID) {
    if (is_nav && is_nav6up) {
        return document.getElementById(layerID);
    } else if (is_nav) {
        return document.layers[layerID];
    } else {
        return document.all[layerID];
    }
}
/*---------------------------------------
Called from initialize()
Automatically parse every layer in document,
determining which have swappable images,
and (NS only) create references to every
layer in the document
---------------------------------------*/
function parseLayers(str) {


    for (var i=0; i < str.images.length; i++) {
        if (str.images[i].name != "") {
            createImageObjects(str.images[i]);
        }
    }

    if (is_nav && !is_nav6up) {
        for (var i=0; i < str.layers.length; i++) {
            var layRef = str.layers[i].name;
            layerArray[layRef] = new Object();
            layerArray[layRef].layerRef = str.layers[layRef];
            parseLayers(str.layers[i].document);
        }
    }

}

/*----------------- NEW -----------------
Called from parseLayers()
Preloads and creates object references for swappable images
including _on state, _off state, and DOM image object path
---------------------------------------*/
function createImageObjects(imgObj) {

    var ftypeExp = /(_on|_off|_down)\.[^\.]*$/i;   // regular expression used to split the filename string
    var extExp = /\.[^\.]*$/;
    var srcString = imgObj.src;
    var extString = srcString.match(extExp)[0]; // grab the extension
    var imgRef = imgObj.name;
    var fnameString = srcString.replace(ftypeExp, "");

    swapArray[imgRef] = new Object();
    swapArray[imgRef].on = new Image();
    swapArray[imgRef].on.src = fnameString + "_on" + extString;
    swapArray[imgRef].off = new Image();
    swapArray[imgRef].off.src = fnameString + "_off" + extString;
    swapArray[imgRef].layerRef = imgObj;
    swapArray[imgRef].on2 = new Image();
    swapArray[imgRef].on2.src = fnameString + "_on2" + extString;
    swapArray[imgRef].layerRef = imgObj;

}

/*---------------------------------------
Called from the <a href> tag
Swap image function for rollovers
---------------------------------------*/
function swap(imgName, onoffon2) {
    if (swapArray[imgName] != null) {
        swapArray[imgName].layerRef.src = swapArray[imgName][onoffon2].src;
    }
}

function onClickSwap(imgName) {
    if(selectedImage != imgName) {
        swap(imgName, 'on');
        if(selectedImage != '') {
            swap(selectedImage, 'off');
        }
        selectedImage = imgName;
        return true;
    } else {
        swap(imgName, 'on');
        return false;
    }
}
// called from onMouseOver and onMouseOut
function mouseSwap(imgName, onoff) {
    if(selectedImage != imgName) {
        swap(imgName, onoff);
    }
}


// called from onclick, can handle multiple groups of buttons; each group must be defined in the individual page, normally "whichTOOL".
function swapGroup(imgName, group) {
    for (prop in swapArray) {
        if (prop.indexOf(group) != -1) {
            swap(prop, 'off');
        }
    }
  swap(imgName, 'on');
}


/*---------------------------------------
Controls the visibility of the menu layers
---------------------------------------*/
function dropSub(layer) {
    for (i=0; i < subTextArray.length; i++) {
        (is_nav && !is_nav6up) ? subTextArray[i].visibility = "hide" : subTextArray[i].style.visibility = "hidden";
        if (subTextArray[i].id.indexOf(layer) != -1) {
            (is_nav && !is_nav6up) ? subTextArray[i].visibility = "show" : subTextArray[i].style.visibility = "visible";
        }
    }
}

function dropMap(layer) {
    for (i=0; i < subMapArray.length; i++) {
        (is_nav && !is_nav6up) ? subMapArray[i].visibility = "hide" : subMapArray[i].style.visibility = "hidden";
        if (subMapArray[i].id.indexOf(layer) != -1) {
            (is_nav && !is_nav6up) ? subMapArray[i].visibility = "show" : subMapArray[i].style.visibility = "visible";
            swap(subArrowArray[i], 'on');
        } else {
            swap(subArrowArray[i], 'off');
        }


    }
}
function changeMap(imgPath){
    //if (is.NNOLD){
        //imgPath = "../" + imgPath;
    //}
    document.largemap.src = imgPath;

}

/*---------------------------------------
FAQ TOGGLE SCRIPT
---------------------------------------*/

//use this to collapse/expand lists
function toggle(thisList){
    if (document.getElementById(thisList).style.display =="") {
        document.getElementById(thisList).style.display = "block";
        document.getElementById(thisList + "arrow").className = "selectedCategory";
    } else {
        document.getElementById(thisList).style.display ="";
        document.getElementById(thisList + "arrow").className = "arrow";
    }
}

//use this to "show" or "hide" all the things on a collapsable list, at the same time, currently used by the FAQ
function toggleAllTag(tagname) {
    tagArray = document.getElementsByTagName(tagname); // produces an array of all objects in the page that are the tag you requested
    for (i = 0; i < tagArray.length; i ++) {
        if (tagState == "hidden") {
            document.getElementById(tagArray[i].id).style.display = "block";
            document.getElementById(tagArray[i].id + "arrow").className = "selectedCategory";
        } else {
            document.getElementById(tagArray[i].id).style.display ="";
            document.getElementById(tagArray[i].id + "arrow").className = "arrow";
        }
    }
    tagState = (tagState == "hidden") ? "visible" : "hidden";
}

//tagState must be defined
tagState = "hidden";





/*---------------------------------------
TESTING FAQ TOGGLE SCRIPT
---------------------------------------*/

//use this to collapse/expand lists
function toggleOpen(thisList){
    if (document.getElementById(thisList).style.display =="") {
        document.getElementById(thisList).style.display = "block";
        document.getElementById(thisList + "arrow").className = "selectedCategory";
    } else {
        document.getElementById(thisList).style.display ="";
        document.getElementById(thisList + "arrow").className = "arrow";
    }
}

//use this to "show" or "hide" all the things on a collapsable list, at the same time, currently used by the FAQ
function toggleAllTagOpen(tagname) {
    tagArray = document.getElementsByTagName(tagname); // produces an array of all objects in the page that are the tag you requested
    for (i = 0; i < tagArray.length; i ++) {
        if (tagState == "hidden") {
            document.getElementById(tagArray[i].id).style.display = "block";
            document.getElementById(tagArray[i].id + "arrow").className = "selectedCategory";
        } else {
            document.getElementById(tagArray[i].id).style.display ="";
            document.getElementById(tagArray[i].id + "arrow").className = "arrow";
        }
    }
    tagState = (tagState == "hidden") ? "visible" : "hidden";
}

//initialize a multi-collapsible list
function collapsibleList(listname){
    this.tagState = "hidden";
    this.listName = listname;
}

//use this to "show" or "hide" all the things on a collapsable list without affecting another collapsible list on the page
function toggleAllTagMulti(tagname, baseName) {
    tagArray = document.getElementById(baseName.listName).getElementsByTagName(tagname); // produces an array of all objects in the page that are the tag you requested
    for (i = 0; i < tagArray.length; i ++) {
        if (baseName.tagState == "hidden") {
            document.getElementById(tagArray[i].id).style.display = "block";
            document.getElementById(tagArray[i].id + "arrow").className = "selectedCategory";
        } else {
            document.getElementById(tagArray[i].id).style.display ="";
            document.getElementById(tagArray[i].id + "arrow").className = "arrow";
        }
    }
    baseName.tagState = (baseName.tagState == "hidden") ? "visible" : "hidden";
}

/*---------------------------------------
SOFTWARE PAGES NEW WINDOW POPUP
---------------------------------------*/

//used for demos on software pages to popup a new window

function NewWindow(mypage, myname, w, h, scroll) {
var winl = (screen.width - w) / 2;
var wint = (screen.height - h) / 2;
winprops = 'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable'
win = window.open(mypage, myname, winprops)
if (parseInt(navigator.appVersion) >=4) { win.window.focus(); }
}

/*---------------------------------------
BOX WITH DYANMIC CONTENT AND TABS ON TOP
---------------------------------------*/

function getTabStructure() {
    //get an array of all boxTabs on the page
    for (a = 0; a < document.getElementsByTagName("a").length; a++){
        if (document.getElementsByTagName("a")[a].className.indexOf("boxtab") != -1){
            document.getElementsByTagName("a")[a].onclick = function(){
                //get a an array of the parentNode's A tags
                for (t = 0; t < this.parentNode.getElementsByTagName("a").length; t++){
                    this.parentNode.getElementsByTagName("a")[t].className = this.parentNode.getElementsByTagName("a")[t].className.replace(/\s*selected/g,"");
                }
                //mark the clicked tab as selected
                this.className += " selected";
                //get a an array of the grandparentNode's divs tags
                for (t = 0; t < this.parentNode.parentNode.getElementsByTagName("div").length; t++){
                    if (this.parentNode.parentNode.getElementsByTagName("div")[t].id.indexOf("Content") != -1){
                        this.parentNode.parentNode.getElementsByTagName("div")[t].className = this.parentNode.parentNode.getElementsByTagName("div")[t].className.replace(/\s*selected/g,"");
                    }
                }
                //show the clicked tab's content section
                document.getElementById(this.id + "Content").className += " selected";
                this.blur();
            }
        }
    }
}


//for persistent lists, which will uncollapse a single section when a cookie is set (requires rotatingmap.js to be included)
//This is only for collapsible lists.
persistentList = function(listName){
    this.listName = listName;
}
makePersistentLinks = function(){ //a function that can take any number of arguments, each of which is a persistentList object
    for (i=0; i < arguments.length; i++){ //loop through the arguments
        aArray = document.getElementById(arguments[i].listName).getElementsByTagName("a"); //get an array of the persistentList's <a> tags
        for (a = 0; a < aArray.length; a++){
            aArray[a].onclick = function(){
                if (this.href.indexOf("#") != -1) { //if the href contains a #
                    hrefArray = this.href.split("#"); //split up the href at the #
                    listSectionValue = hrefArray[1].replace(/arrow/,""); //grab whatever comes after the # and remove "arrow" from it;
                    setCookie("listSection", listSectionValue);
                }
            }
        }
    }
}
getPersistentLinks = function(){
    if(getCookie("listSection")){
        theListSection = getCookie("listSection");
        document.getElementById(theListSection).style.display = "block";
        document.getElementById(theListSection + "arrow").className = "selectedCategory";
        window.location.hash = theListSection + "arrow";
        //setCookie("listSection", "");
    }
}

/*------------EBIS functions for the Subscriber Login-----------------*/
/*function login() {

    document.forms.testForm.username.value = document.forms.testForm.uname.value;
    document.forms.testForm.password.value = document.forms.testForm.pword.value;
    document.forms.testForm.uname.value = "";
    document.forms.testForm.pword.value = "";
    document.forms.testForm.action="https://webaccounts.esri.com/CAS/index.cfm";
    document.forms.testForm.submit();
   } */
/*------------EBIS functions for the Subscriber Login-----------------*/

/*----------This function is to used for the E-recruitment links so that they open in a new window with no browser tool bar-----*/

/*function pop_er(url)
  {
   var er_win;

   er_win = window.open(url, 'e_rec', 'directories=0, scrollbars=1,resizable=1');
   er_win.focus();
  }

function popCareersMovie(URL, name) {
  bWindow = window.open(URL, name,"status=0,menubar=0,width=1000,height=744,resizable,scrollbars=yes");
}*/


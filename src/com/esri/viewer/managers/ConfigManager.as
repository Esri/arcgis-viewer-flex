///////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010-2011 Esri. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////
package com.esri.viewer.managers
{

import com.esri.ags.clusterers.ESRIClusterer;
import com.esri.ags.clusterers.WeightedClusterer;
import com.esri.ags.clusterers.supportClasses.FlareSymbol;
import com.esri.ags.clusterers.supportClasses.SimpleClusterSymbol;
import com.esri.ags.events.WebMapEvent;
import com.esri.ags.geometry.Extent;
import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
import com.esri.ags.layers.ArcGISImageServiceLayer;
import com.esri.ags.layers.ArcGISTiledMapServiceLayer;
import com.esri.ags.layers.FeatureLayer;
import com.esri.ags.layers.KMLLayer;
import com.esri.ags.layers.Layer;
import com.esri.ags.layers.OpenStreetMapLayer;
import com.esri.ags.layers.WMSLayer;
import com.esri.ags.layers.supportClasses.LOD;
import com.esri.ags.symbols.Symbol;
import com.esri.ags.tasks.GeometryServiceSingleton;
import com.esri.ags.virtualearth.VETiledLayer;
import com.esri.ags.webmap.WebMapUtil;
import com.esri.viewer.AppEvent;
import com.esri.viewer.ConfigData;
import com.esri.viewer.ViewerContainer;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.text.TextFormat;

import mx.collections.ArrayCollection;
import mx.resources.ResourceManager;
import mx.rpc.Fault;
import mx.rpc.Responder;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;
import mx.utils.StringUtil;

[Event(name="configLoaded", type="com.esri.viewer.AppEvent")]

/**
 * ConfigManager is used to parse the configuration file and store the information in ConfigData.
 * The default configuration file is config.xml, but you can specify an alternative configuration file,
 * e.g. http://myserver/flexviewer/index.html?config=myconfig.xml
 *
 * The name of the default configuration file is specified in ViewerContainer.mxml.
 */
public class ConfigManager extends EventDispatcher
{
    private const CONFIG_MANAGER:String = "ConfigManager";

    public function ConfigManager()
    {
        //make sure the container is properly initialized and then
        //proceed with configuration initialization.
        AppEvent.addListener(ViewerContainer.CONTAINER_INITIALIZED, containerInitializedHandler);
    }

    private function containerInitializedHandler(event:Event):void
    {
        loadConfig();
    }

    private function loadConfig():void
    {
        var configService:HTTPService = new HTTPService();
        configService.url = ViewerContainer.configFile;
        configService.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
        configService.addEventListener(ResultEvent.RESULT, configService_resultHandler);
        configService.addEventListener(FaultEvent.FAULT, configService_faultHandler);
        configService.send();
    }

    private function configService_faultHandler(event:mx.rpc.events.FaultEvent):void
    {
        // happens if for example the main config file is missing or have crossdomain problem

        var sInfo:String = "";

        // Missing config file
        if (event.fault.rootCause is IOErrorEvent)
        {
            var ioe:IOErrorEvent = event.fault.rootCause as IOErrorEvent;
            if (ioe.text.indexOf("2032: Stream Error. URL:") > -1)
            {
                sInfo += StringUtil.substitute(getDefaultString('missingConfigFileText'), ioe.text.substring(32)) + "\n\n";
            }
            else
            {
                // some other IOError
                sInfo += event.fault.rootCause + "\n\n";
            }
        }

        // config file with crossdomain issue
        if (event.fault.rootCause is SecurityErrorEvent)
        {
            var sec:SecurityErrorEvent = event.fault.rootCause as SecurityErrorEvent;
            if (sec.text.indexOf("Error #2048: ") > -1) // debug player
            {
                sInfo += StringUtil.substitute(getDefaultString('configFileCrossDomain'), "\n", sec.text) + "\n\n";
            }
            else if (sec.text.indexOf("Error #2048") > -1) // non-debug player
            {
                sInfo += StringUtil.substitute(getDefaultString('configFileCrossDomain'), "\n", sec.toString()) + "\n\n";
            }
            else
            {
                // some other Security error
                sInfo += event.fault.rootCause + "\n\n";
            }
        }

        if (event.statusCode) // e.g. 404 - Not Found - http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
        {
            sInfo += StringUtil.substitute(getDefaultString('httpResponseStatus'), event.statusCode) + "\n\n";
        }

        sInfo += StringUtil.substitute(getDefaultString('faultCode'), event.fault.faultCode) + "\n\n";
        sInfo += StringUtil.substitute(getDefaultString('faultInfo'), event.fault.faultString) + "\n\n";
        sInfo += StringUtil.substitute(getDefaultString('faultDetail'), event.fault.faultDetail);

        AppEvent.showError(sInfo, CONFIG_MANAGER);
    }

    private function configService_resultHandler(event:ResultEvent):void
    {
        try
        {
            //parse main configuration file to create config data object
            var configData:ConfigData = new ConfigData();
            var configXML:XML = XML(event.result);
            configData.configXML = configXML;

            var i:int;
            var j:int;

            //================================================
            //Proxy configuration
            //================================================
            var proxyUrl:String = configXML.httpproxy;
            if (proxyUrl)
            {
                configData.proxyUrl = proxyUrl;
            }

            //================================================
            //BingKey configuration
            //================================================
            var bingKey:String = configXML.bing.@key;
            if (bingKey)
            {
                configData.bingKey = bingKey;
            }

            //================================================
            //GeometryService configuration
            //================================================
            var geometryService:XML = configXML.geometryservice[0];
            if (geometryService)
            {
                configData.geometryService.url = geometryService.@url[0] ? String(geometryService.@url[0]) : "";
                configData.geometryService.token = geometryService.@token[0] ? String(geometryService.@token[0]) : "";
                configData.geometryService.useproxy = geometryService.@useproxy[0] == "true";

                if (configData.geometryService.url)
                {
                    GeometryServiceSingleton.instance.url = configData.geometryService.url;
                    GeometryServiceSingleton.instance.token = configData.geometryService.token;
                    if (configData.geometryService.useproxy)
                    {
                        GeometryServiceSingleton.instance.proxyURL = configData.proxyUrl;
                    }
                }
            }

            //================================================
            //Style configuration
            //================================================
            var styleAlpha:String = (XMLList(configXML.style.alpha).length() > 0) ? configXML.style.alpha : configXML.stylealpha;
            if (styleAlpha)
            {
                configData.styleAlpha = Number(styleAlpha);
            }

            var styleColors:Array = String(configXML.style.colors).split(",");
            if (styleColors.length == 1) // if style.colors are not specified, then check for stylecolors for backwards compatibility with version 2.1
            {
                styleColors = String(configXML.stylecolors).split(",");
            }

            var colorStr:String = "";
            for each (colorStr in styleColors)
            {
                configData.styleColors.push(uint(colorStr));
            }

            var styleFontName:String = configXML.style.font.@name;
            var styleFontSize:String = configXML.style.font.@size;
            var font:Object =
                {
                    id: "font",
                    name: styleFontName,
                    size: int(styleFontSize)
                };
            configData.font = font;

            var styleTitleFontName:String = configXML.style.titlefont.@name;
            var styleTitleFontSize:String = configXML.style.titlefont.@size;
            var titleFont:Object =
                {
                    id: "titleFont",
                    name: styleTitleFontName,
                    size: int(styleTitleFontSize)
                };
            configData.titleFont = titleFont;

            var styleSubTitleFontName:String = configXML.style.subtitlefont.@name;
            var styleSubTitleFontSize:String = configXML.style.subtitlefont.@size;
            var subTitleFont:Object =
                {
                    id: "subTitleFont",
                    name: styleSubTitleFontName,
                    size: int(styleSubTitleFontSize)
                };
            configData.subTitleFont = subTitleFont;
            
            //================================================
            //layoutDirection configuration
            //================================================
            var layoutDirection:String = configXML.layoutdirection;
            if (layoutDirection)
            {
                configData.layoutDirection = layoutDirection;
            }
            
            //================================================
            //user interface
            //================================================
            var configUI:Array = [];
            var value:String = configXML.title[0];
            var title:Object =
                {
                    id: "title",
                    value: value
                };
            configUI.push(title);

            value = configXML.subtitle[0];
            var subtitle:Object =
                {
                    id: "subtitle",
                    value: value
                };
            configUI.push(subtitle);

            value = configXML.logo[0];
            var logo:Object =
                {
                    id: "logo",
                    value: value
                };
            configUI.push(logo);

            value = configXML.splashpage.@url;
            if (value)
            {
                var splashConfig:String = configXML.splashpage.@config;
                var spashConfigXML:XML = null;
                if (splashConfig.charAt(0) === "#")
                {
                    spashConfigXML = configXML.configuration.(@id == splashConfig.substr(1))[0];
                }
                var splashTitle:String = configXML.splashpage.@label;
                var splashPage:Object =
                    {
                        id: "splashpage",
                        value: value,
                        config: splashConfig,
                        configXML: spashConfigXML,
                        title: splashTitle
                    };
                configUI.push(splashPage);
            }

            var wleft:String = configXML.widgetcontainer.@left;
            var wright:String = configXML.widgetcontainer.@right;
            var wtop:String = configXML.widgetcontainer.@top;
            var wbottom:String = configXML.widgetcontainer.@bottom;
            var wlayout:String = configXML.widgetcontainer.@layout;
            if (!wlayout)
            {
                wlayout = "horizontal";
            }

            if (wleft || wright || wtop || wbottom || wlayout)
            {
                var widgetContainer:Object =
                    {
                        id: "widgetcontainer",
                        left: wleft,
                        right: wright,
                        top: wtop,
                        bottom: wbottom,
                        layout: wlayout
                    };
                configUI.push(widgetContainer);
            }

            configData.viewerUI = configUI;

            //================================================
            //controls
            //================================================
            var configControls:Array = [];
            var controlList:XMLList = configXML.widget;
            var controlIdWeight:Number = 1000;
            for (i = 0; i < controlList.length(); i++)
            {
                var controlIcon:String = controlList[i].@icon;
                var controlLabel:String = controlList[i].@label;
                var controlLeft:String = controlList[i].@left;
                var controlRight:String = controlList[i].@right;
                var controlTop:String = controlList[i].@top;
                var controlBottom:String = controlList[i].@bottom;
                var controlHorizontalCenter:String = controlList[i].@horizontalcenter;
                var controlVerticalCenter:String = controlList[i].@verticalcenter;
                var controlVisible:String = controlList[i].@visible;
                var controlConfig:String = controlList[i].@config;
                var controlUrl:String = controlList[i].@url;

                var controlConfigXML:XML = null;
                if (controlConfig.charAt(0) === "#")
                {
                    controlConfigXML = configXML.configuration.(@id == controlConfig.substr(1))[0];
                }

                var control:Object =
                    {
                        id: controlIdWeight + i,
                        icon: controlIcon,
                        label: controlLabel,
                        left: controlLeft,
                        right: controlRight,
                        top: controlTop,
                        bottom: controlBottom,
                        horizontalCenter: controlHorizontalCenter,
                        verticalCenter: controlVerticalCenter,
                        visible: controlVisible,
                        config: controlConfig,
                        configXML: controlConfigXML,
                        url: controlUrl
                    };
                configControls.push(control);
            }
            configData.controls = configControls;

            //=================================================
            //map
            //================================================
            var mapAttrs:Array = [];
            var initialExtent:String = configXML.map.@initialextent;
            if (ViewerContainer.urlConfigParams.extent != null)
            {
                var extentParam:String = ViewerContainer.urlConfigParams.extent;
                initialExtent = extentParam.replace(/,/g, " ");
            }
            if (initialExtent)
            {
                var iExt:Object =
                    {
                        id: "initial",
                        extent: initialExtent
                    };
                mapAttrs.push(iExt);
            }
            var fullExtent:String = configXML.map.@fullextent;
            if (fullExtent)
            {
                var fExt:Object =
                    {
                        id: "full",
                        extent: fullExtent
                    };
                mapAttrs.push(fExt);
            }
            var mapCenter:String = configXML.map.@center;
            if (ViewerContainer.urlConfigParams.center != null)
            {
                var centerParam:String = ViewerContainer.urlConfigParams.center;
                mapCenter = centerParam.replace(/,/g, " ");
            }
            if (mapCenter)
            {
                var centerObj:Object =
                    {
                        id: "center",
                        center: mapCenter
                    };
                mapAttrs.push(centerObj);
            }
            var mapLevel:String = configXML.map.@level;
            if (ViewerContainer.urlConfigParams.level != null)
            {
                mapLevel = ViewerContainer.urlConfigParams.level;
            }
            if (mapLevel)
            {
                var levelObj:Object =
                    {
                        id: "level",
                        level: mapLevel
                    };
                mapAttrs.push(levelObj);
            }
            var mapScale:String = configXML.map.@scale;
            if (ViewerContainer.urlConfigParams.scale != null)
            {
                mapScale = ViewerContainer.urlConfigParams.scale;
            }
            if (mapScale)
            {
                var scaleObj:Object =
                    {
                        id: "scale",
                        scale: mapScale
                    };
                mapAttrs.push(scaleObj);
            }

            var mapLeft:Number;
            var mapRight:Number;
            var mapTop:Number;
            var mapBottom:Number;
            if (configXML.map.@left)
            {
                mapLeft = Number(configXML.map.@left);
            }
            if (configXML.map.@right)
            {
                mapRight = Number(configXML.map.@right);
            }
            if (configXML.map.@top)
            {
                mapTop = Number(configXML.map.@top);
            }
            if (configXML.map.@bottom)
            {
                mapBottom = Number(configXML.map.@bottom);
            }

            var size:Object =
                {
                    id: "map",
                    left: mapLeft,
                    right: mapRight,
                    top: mapTop,
                    bottom: mapBottom
                };
            mapAttrs.push(size);

            var wkid:Number;
            var wkt:String
            if (configXML.map.@wkid)
            {
                wkid = Number(configXML.map.@wkid);
            }
            if (configXML.map.@wkt)
            {
                wkt = configXML.map.@wkt;
            }
            var ref:Object =
                {
                    id: "spatialref",
                    wkid: wkid,
                    wkt: wkt
                };
            mapAttrs.push(ref);

            var zoomSliderVisible:Boolean = configXML.map.@zoomslidervisible == "true";
            var zoomSliderVisibility:Object =
                {
                    id: "zoomSlider",
                    zoomSliderVisible: zoomSliderVisible
                };
            mapAttrs.push(zoomSliderVisibility);

            var scaleBarVisible:Boolean = configXML.map.@scalebarvisible[0] ? configXML.map.@scalebarvisible == "true" : true;
            var scaleBarVisibility:Object =
                {
                    id: "scaleBar",
                    scaleBarVisible: scaleBarVisible
                };
            mapAttrs.push(scaleBarVisibility);

            var esriLogoVisible:Boolean = configXML.map.@esrilogovisible[0] ? configXML.map.@esrilogovisible == "true" : true;
            var esriLogoVisibility:Object =
                {
                    id: "esriLogo",
                    esriLogoVisible: esriLogoVisible
                };
            mapAttrs.push(esriLogoVisibility);

            var openHandCursorVisible:Boolean = configXML.map.@openhandcursorvisible[0] ? configXML.map.@openhandcursorvisible == "true" : false;
            var openHandCursorVisiblility:Object =
                {
                    id: "openHandCursor",
                    openHandCursorVisible: openHandCursorVisible
                };
            mapAttrs.push(openHandCursorVisiblility);

            var wrapAround180:Boolean = configXML.map.@wraparound180[0] ? configXML.map.@wraparound180 == "true" : false;
            var wrapAround180Attr:Object =
                {
                    id: "wrapAround180",
                    wrapAround180: wrapAround180
                };
            mapAttrs.push(wrapAround180Attr);

            var panEasingFactor:Number = parseFloat(configXML.map.@paneasingfactor[0]);
            if (!isNaN(panEasingFactor))
            {
                var panEasingFactorAttr:Object =
                    {
                        id: "panEasingFactor",
                        panEasingFactor: panEasingFactor
                    };
                mapAttrs.push(panEasingFactorAttr);
            }

            var units:String = configXML.map.@units[0];
            if (units)
            {
                var unitsAttr:Object =
                    {
                        id: "units",
                        units: units
                    };
                mapAttrs.push(unitsAttr);
            }

            var lodsList:XMLList = configXML.map.lods.lod;
            if (lodsList.length() > 0)
            {
                var lods:Array = [];
                for each (var lod:XML in lodsList)
                {
                    var resolution:Number = lod.@resolution;
                    var scale:Number = lod.@scale;
                    lods.push(new LOD(NaN, resolution, scale));
                }
                mapAttrs.push({ id: "lods", lods: lods });
            }

            configData.mapAttrs = mapAttrs;

            var arcGISWebMapItemID:String = configXML.map.@itemid[0];
            if (ViewerContainer.urlConfigParams.itemid)
            {
                arcGISWebMapItemID = ViewerContainer.urlConfigParams.itemid;
            }

            if (arcGISWebMapItemID)
            {
                var webMapUtil:WebMapUtil = new WebMapUtil();
                webMapUtil.bingMapsKey = configData.bingKey;
                webMapUtil.proxyURL = configData.proxyUrl;
                if (GeometryServiceSingleton.instance.url)
                {
                    webMapUtil.geometryService = GeometryServiceSingleton.instance;
                }
                var arcgisSharingURL:String = configXML.map.@arcgissharingurl[0];
                if (arcgisSharingURL)
                {
                    webMapUtil.arcgisSharingURL = arcgisSharingURL;
                }
                webMapUtil.createMapById(arcGISWebMapItemID, new Responder(webMapUtil_createMapByIdResultHandler, webMapUtil_createMapByIdFaultHandler));
                function webMapUtil_createMapByIdResultHandler(result:WebMapEvent):void
                {
                    if (!title.value)
                    {
                        title.value = result.item.title;
                    }

                    var baseMapTitle:String;
                    if (result.itemData.baseMap)
                    {
                        baseMapTitle = result.itemData.baseMap.title;
                    }

                    var layers:ArrayCollection = result.map.layers as ArrayCollection;
                    configData.webMapLayers = layers;
                    for (i = 0; i < layers.length; i++)
                    {
                        var layer:Layer = layers[i];
                        var isOpLayer:Boolean = layer.id.indexOf("base") != 0;

                        if (!isOpLayer && !baseMapTitle && i == 0)
                        {
                            baseMapTitle = layer.name;
                        }

                        var label:String = baseMapTitle;
                        if (isOpLayer)
                        {
                            label = layer.name;
                        }
                        layer.id = label;

                        var lyrXML:XML = null;
                        if (layer is ArcGISDynamicMapServiceLayer)
                        {
                            var dynLyr:ArcGISDynamicMapServiceLayer = layer as ArcGISDynamicMapServiceLayer;
                            lyrXML = <layer label={label}
                                    type="dynamic"
                                    visible={dynLyr.visible}
                                    alpha={dynLyr.alpha}
                                    useproxy={dynLyr.proxyURL != null}
                                    url={dynLyr.url}/>;
                            if (dynLyr.visibleLayers)
                            {
                                lyrXML.@visiblelayers = dynLyr.visibleLayers.toArray().join();
                            }
                        }
                        else if (layer is ArcGISImageServiceLayer)
                        {
                            var imgLyr:ArcGISImageServiceLayer = layer as ArcGISImageServiceLayer;
                            lyrXML = <layer label={label}
                                    type="image"
                                    visible={imgLyr.visible}
                                    alpha={imgLyr.alpha}
                                    useproxy={imgLyr.proxyURL != null}
                                    url={imgLyr.url}/>;
                            if (imgLyr.bandIds)
                            {
                                lyrXML.@bandids = imgLyr.bandIds.join();
                            }
                        }
                        else if (layer is ArcGISTiledMapServiceLayer)
                        {
                            var tiledLyr:ArcGISTiledMapServiceLayer = layer as ArcGISTiledMapServiceLayer;
                            lyrXML = <layer label={label}
                                    type="tiled"
                                    visible={tiledLyr.visible}
                                    alpha={tiledLyr.alpha}
                                    useproxy={tiledLyr.proxyURL != null}
                                    url={tiledLyr.url}/>;
                            if (tiledLyr.displayLevels)
                            {
                                lyrXML.@displaylevels = tiledLyr.displayLevels.join();
                            }
                        }
                        else if (layer is FeatureLayer)
                        {
                            var feaLyr:FeatureLayer = layer as FeatureLayer;
                            if (feaLyr.featureCollection)
                            {
                                lyrXML = <layer label={label}
                                        type="feature"
                                        visible={feaLyr.visible}
                                        alpha={feaLyr.alpha}/>
                            }
                            else
                            {
                                lyrXML = <layer label={label}
                                        type="feature"
                                        visible={feaLyr.visible}
                                        alpha={feaLyr.alpha}
                                        mode={feaLyr.mode}
                                        useproxy={feaLyr.proxyURL != null}
                                        url={feaLyr.url}/>;
                            }
                        }
                        else if (layer is OpenStreetMapLayer)
                        {
                            var osmLyr:OpenStreetMapLayer = layer as OpenStreetMapLayer;
                            lyrXML = <layer label={label}
                                    type="osm"
                                    visible={osmLyr.visible}
                                    alpha={osmLyr.alpha}/>;
                        }
                        else if (layer is VETiledLayer)
                        {
                            var veLyr:VETiledLayer = layer as VETiledLayer;
                            lyrXML = <layer label={label}
                                    type="bing"
                                    visible={veLyr.visible}
                                    alpha={veLyr.alpha}
                                    style={veLyr.mapStyle}/>;
                            if (veLyr.displayLevels)
                            {
                                lyrXML.@displaylevels = veLyr.displayLevels.join();
                            }
                        }
                        else if (layer is KMLLayer)
                        {
                            var kmlLayer:KMLLayer = layer as KMLLayer;
                            lyrXML = <layer label={label}
                                    type="kml"
                                    visible={kmlLayer.visible}
                                    alpha={kmlLayer.alpha}
                                    url={kmlLayer.url}/>;
                        }
                        else if (layer is WMSLayer)
                        {
                            var wmsLayer:WMSLayer = layer as WMSLayer;
                            lyrXML = <layer label={label}
                                    type="wms"
                                    visible={wmsLayer.visible}
                                    alpha={wmsLayer.alpha}
                                    version={wmsLayer.version}
                                    skipgetcapabilities={wmsLayer.skipGetCapabilities}
                                    imageformat={wmsLayer.imageFormat}
                                    url={wmsLayer.url}/>;
                            if (wmsLayer.visibleLayers)
                            {
                                lyrXML.@visiblelayers = wmsLayer.visibleLayers.toArray().join();
                            }
                        }
                        if (lyrXML)
                        {
                            if (isOpLayer)
                            {
                                configData.opLayers.push(getLayerObject(lyrXML, i, true, bingKey, layer));
                            }
                            else
                            {
                                if (configData.opLayers.length > 0)
                                {
                                    lyrXML.@reference = true;
                                }
                                configData.basemaps.push(getLayerObject(lyrXML, i, false, bingKey, layer));
                            }
                        }
                    }
                    if (!initialExtent)
                    {
                        var extent:Extent = result.map.extent;
                        if (extent)
                        {
                            var extentArr:Array = [ extent.xmin, extent.ymin, extent.xmax, extent.ymax ];
                            var iExt:Object =
                                {
                                    id: "initial",
                                    extent: extentArr.join(" ")
                                };
                            mapAttrs.push(iExt);
                        }
                    }
                    AppEvent.dispatch(AppEvent.CONFIG_LOADED, configData);
                }
                function webMapUtil_createMapByIdFaultHandler(error:Fault):void
                {
                    AppEvent.showError(error.faultString, CONFIG_MANAGER);
                }
            }
            else
            {
                //================================================
                //map:basemaps
                //================================================
                var configBasemaps:Array = [];
                var maplayerList:XMLList = configXML.map.basemaps.mapservice; // TODO - is this still in use ???

                if (maplayerList.length() < 1)
                {
                    maplayerList = configXML.map.basemaps.layer;
                }

                for (i = 0; i < maplayerList.length(); i++)
                {
                    configBasemaps.push(getLayerObject(maplayerList[i], i, false, bingKey));
                }
                configData.basemaps = configBasemaps;

                //================================================
                //map:operationalLayers
                //================================================
                var configOpLayers:Array = [];
                var opLayerList:XMLList = configXML.map.operationallayers.layer;
                for (i = 0; i < opLayerList.length(); i++)
                {
                    configOpLayers.push(getLayerObject(opLayerList[i], i, true, bingKey));
                }
                configData.opLayers = configOpLayers;
            }

            //=================================================
            //widgets
            //================================================
            var configWidgets:Array = [];
            var widgetContainerList:XMLList = configXML.widgetcontainer;
            var widgetId:Number = 0;
            for (i = 0; i < widgetContainerList.children().length(); i++)
            {
                var xmlObject:XML = widgetContainerList.children()[i];
                if (xmlObject.name() == "widgetgroup")
                {
                    var widgetGroupList:XMLList = XMLList(xmlObject);
                    createWidgets(widgetGroupList.widget, true, widgetGroupList.widget.length(), widgetGroupList.@label, widgetGroupList.@icon);
                }
                else
                {
                    var widgetList:XMLList = XMLList(xmlObject);
                    createWidgets(widgetList, false);
                }
            }

            function createWidgets(widgetList:XMLList, grouped:Boolean, groupLength:Number = 0, groupLabel:String = null, groupIcon:String = null):void
            {
                var widgetListLength:int = widgetList.length();
                for (var p:int = 0; p < widgetListLength; p++)
                {
                    // if grouped
                    var wGrouped:Boolean = grouped;
                    var wGroupLength:Number = groupLength;
                    var wGroupIcon:String = groupIcon;
                    var wGroupLabel:String = groupLabel;

                    var wLabel:String = widgetList[p].@label;
                    var wIcon:String = widgetList[p].@icon;
                    var wConfig:String = widgetList[p].@config;
                    var wPreload:String = widgetList[p].@preload;
                    var wWidth:String = widgetList[p].@width;
                    var wHeight:String = widgetList[p].@height;
                    var wUrl:String = widgetList[p].@url;
                    var wx:String = widgetList[p].@x;
                    var wy:String = widgetList[p].@y;
                    var wLeft:String = widgetList[p].@left;
                    var wTop:String = widgetList[p].@top;
                    var wRight:String = widgetList[p].@right;
                    var wBottom:String = widgetList[p].@bottom;

                    // Look for embedded configuration
                    var wConfigXML:XML = null;
                    if (wConfig.charAt(0) === "#")
                    {
                        wConfigXML = configXML.configuration.(@id == wConfig.substr(1))[0];
                    }
                    if (!wGroupIcon)
                    {
                        wGroupIcon = ViewerContainer.DEFAULT_WIDGET_GROUP_ICON;
                    }
                    if (!wIcon)
                    {
                        wIcon = ViewerContainer.DEFAULT_WIDGET_ICON;
                    }

                    var widget:Object =
                        {
                            id: widgetId,
                            grouped: wGrouped,
                            groupLength: wGroupLength,
                            groupIcon: wGroupIcon,
                            groupLabel: wGroupLabel,
                            label: wLabel,
                            icon: wIcon,
                            config: wConfig,
                            configXML: wConfigXML, // reference to emdedded XML configuration (if any)
                            preload: wPreload,
                            width: wWidth,
                            height: wHeight,
                            x: wx,
                            y: wy,
                            left: wLeft,
                            top: wTop,
                            right: wRight,
                            bottom: wBottom,
                            url: wUrl
                        };
                    configWidgets.push(widget);
                    widgetId++;
                }
            }
            configData.widgets = configWidgets;

            //=================================================
            //widgetContainers
            //   [] ={container, widgets}
            //================================================

            var wContainers:XMLList = configXML.widgetcontainer;
            var configWContainers:Array = [];
            for (i = 0; i < wContainers.length(); i++)
            {
                //get container parameters
                var wcLeft:String = wContainers[i].@left;
                var wcRight:String = wContainers[i].@right;
                var wcTop:String = wContainers[i].@top;
                var wcBottom:String = wContainers[i].@bottom;
                var wcLayout:String = wContainers[i].@layout;
                var wcUrl:String = wContainers[i].@url;

                if (!wcLayout)
                {
                    wcLayout = ViewerContainer.DEFAULT_WIDGET_LAYOUT;
                }

                if (!wcUrl)
                {
                    wcUrl = ViewerContainer.DEFAULT_WIDGET_CONTAINER_WIDGET;
                }

                var wgContainer:Object =
                    {
                        id: i,
                        left: wcLeft,
                        right: wcRight,
                        top: wcTop,
                        bottom: wcBottom,
                        layout: wcLayout,
                        url: wcUrl,
                        obj: null
                    };

                //get widgets for this container
                var contWidgets:Array = [];
                var wid:uint = 0;
                for (var n:int = 0; n < wContainers[i].children().length(); n++)
                {
                    var xmlObj:XML = wContainers[i].children()[n];
                    if (xmlObj.name() == "widgetgroup")
                    {
                        var widgetGrpList:XMLList = XMLList(xmlObj);
                        getWidgetList(widgetGrpList.widget, true, widgetGrpList.widget.length(), widgetGrpList.@label, widgetGrpList.@icon);
                    }
                    else
                    {
                        var wdgtList:XMLList = XMLList(xmlObj);
                        getWidgetList(wdgtList, false);
                    }
                }

                function getWidgetList(wgList:XMLList, grouped:Boolean, groupLength:Number = 0, groupLabel:String = null, groupIcon:String = null):void
                {
                    for (j = 0; j < wgList.length(); j++)
                    {
                        // if grouped
                        var wgGrouped:Boolean = grouped;
                        var wgGroupLength:Number = groupLength;
                        var wgGroupIcon:String = groupIcon;
                        var wgGroupLabel:String = groupLabel;

                        var wgLabel:String = wgList[j].@label;
                        var wgIcon:String = wgList[j].@icon;
                        var wgConfig:String = wgList[j].@config;
                        var wgPreload:String = wgList[j].@preload;
                        var wgWidth:String = wgList[j].@width;
                        var wgHeight:String = wgList[j].@height;
                        var wgUrl:String = wgList[j].@url;
                        var wgx:String = wgList[j].@x;
                        var wgy:String = wgList[j].@y;
                        var wgLeft:String = wgList[j].@left;
                        var wgTop:String = wgList[j].@top;
                        var wgRight:String = wgList[j].@right;
                        var wgBottom:String = wgList[j].@bottom;
                        var wHorizontalCenter:String = wgList[j].@horizontalcenter;
                        var wVerticalCenter:String = wgList[j].@verticalcenter;

                        var wgConfigXML:XML = null;
                        if (wgConfig.charAt(0) === "#")
                        {
                            wgConfigXML = configXML.configuration.(@id == wgConfig.substr(1))[0];
                        }
                        if (!wgGroupIcon)
                        {
                            wgGroupIcon = ViewerContainer.DEFAULT_WIDGET_GROUP_ICON;
                        }
                        if (!wgIcon)
                        {
                            wgIcon = ViewerContainer.DEFAULT_WIDGET_ICON;
                        }

                        var wg:Object =
                            {
                                id: wid,
                                grouped: wgGrouped,
                                groupLength: wgGroupLength,
                                groupIcon: wgGroupIcon,
                                groupLabel: wgGroupLabel,
                                label: wgLabel,
                                icon: wgIcon,
                                config: wgConfig,
                                configXML: wgConfigXML, // reference to enbedded XML configuration (if any)
                                preload: wgPreload,
                                width: wgWidth,
                                height: wgHeight,
                                x: wgx,
                                y: wgy,
                                left: wgLeft,
                                right: wgRight,
                                top: wgTop,
                                bottom: wgBottom,
                                horizontalCenter: wHorizontalCenter,
                                verticalCenter: wVerticalCenter,
                                url: wgUrl
                            };
                        contWidgets.push(wg);

                        //indexing
                        var windex:Object = { container: i, widget: wid };
                        configData.widgetIndex.push(windex);
                        wid++;
                    }
                }

                var container:Object = { container: wgContainer, widgets: contWidgets };
                configWContainers.push(container);
            }
            configData.widgetContainers = configWContainers;

            if (!arcGISWebMapItemID)
            {
                //================================================
                //announce configuration is complete
                //================================================
                AppEvent.dispatch(AppEvent.CONFIG_LOADED, configData);
            }
        }
        catch (error:Error)
        {
            AppEvent.showError(StringUtil.substitute(getDefaultString("parseConfigErrorText"), ViewerContainer.configFile + "\n" + error.message), CONFIG_MANAGER);
        }
    }

    private function getLayerObject(obj:XML, num:Number, isOpLayer:Boolean, bingKey:String, layer:Layer = null):Object
    {
        var label:String = isOpLayer ? 'OpLayer ' + num : 'Map ' + num; // default label
        if (obj.@label[0]) // check that label attribute exist
        {
            label = obj.@label; // set basemap label if specified in configuration file
        }

        var type:String;
        if (!isOpLayer)
        {
            type = "tiled"; // default basemap type
        }
        if (obj.@type[0]) // check that type attribute exist
        {
            type = obj.@type; // set basemap type if specified in configuration file
        }

        // wms
        var wkid:String;
        if (obj.@wkid[0])
        {
            wkid = obj.@wkid;
        }

        var visible:Boolean = obj.@visible == "true";

        var alpha:Number = 1.0;
        if (obj.@alpha[0])
        {
            if (!isNaN(parseFloat(obj.@alpha)))
            {
                alpha = parseFloat(obj.@alpha);
            }
        }

        var maxAllowableOffset:Number;
        if (obj.@maxallowableoffset[0])
        {
            if (!isNaN(parseFloat(obj.@maxallowableoffset)))
            {
                maxAllowableOffset = parseFloat(obj.@maxallowableoffset);
            }
        }

        var noData:Number;
        if (obj.@nodata[0])
        {
            if (!isNaN(parseFloat(obj.@nodata)))
            {
                noData = parseFloat(obj.@nodata);
            }
        }

        var autoRefresh:Number = 0;
        if (obj.@autorefresh[0])
        {
            if (!isNaN(parseInt(obj.@autorefresh)))
            {
                autoRefresh = parseInt(obj.@autorefresh);
            }
        }

        var clusterer:ESRIClusterer = parseClusterer(obj.clustering[0]);
        var useProxy:Boolean = obj.@useproxy[0] && obj.@useproxy == "true"; // default false
        var useMapTime:Boolean = obj.@usemaptime[0] ? obj.@usemaptime == "true" : true; // default true
        var useAMF:String = obj.@useamf[0] ? obj.@useamf : "";
        var token:String = obj.@token[0] ? obj.@token : "";
        var mode:String = obj.@mode[0] ? obj.@mode : "";
        var icon:String = obj.@icon[0] ? obj.@icon : "";
        var imageFormat:String = obj.@imageformat;
        var visibleLayers:String = obj.@visiblelayers;
        var displayLevels:String = obj.@displaylevels;
        var bandIds:String = obj.@bandids;
        var skipGetCapabilities:String = obj.@skipgetcapabilities[0];
        var version:String = obj.@version[0];
        var url:String = obj.@url;
        var serviceURL:String = obj.@serviceurl[0];
        var username:String = obj.@username;
        var password:String = obj.@password;

        // ve tiled layer
        var style:String = obj.@style[0] ? obj.@style : "";
        var key:String;
        if (bingKey)
        {
            key = bingKey;
        }
        else
        {
            key = obj.@key[0] ? obj.@key : "";
        }
        var culture:String = obj.@culture[0] ? obj.@culture : "";

        // arcims layer
        var serviceHost:String = obj.@servicehost[0] ? obj.@servicehost : "";
        var serviceName:String = obj.@servicename[0] ? obj.@servicename : "";

        // definitionExpression for featurelayer
        var definitionExpression:String = obj.@definitionexpression[0] ? obj.@definitionexpression : "";

        //sublayers
        var subLayers:Array = [];
        if (type == "tiled" || type == "dynamic")
        {
            var subLayersList:XMLList = obj.sublayer;
            for (var i:int = 0; i < subLayersList.length(); i++)
            {
                subLayers.push({ id: String(subLayersList[i].@id), info: subLayersList[i].@info, infoConfig: subLayersList[i].@infoconfig, popUpConfig: subLayersList[i].@popupconfig, definitionExpression: String(subLayersList[i].@definitionexpression)});
            }
        }

        var resultObject:Object =
            {
                id: String(num),
                alpha: alpha,
                bandIds: bandIds,
                autoRefresh: autoRefresh,
                culture: culture,
                clusterer: clusterer,
                definitionExpression: definitionExpression,
                displayLevels: displayLevels,
                icon: icon,
                imageFormat: imageFormat,
                key: key,
                label: label,
                maxAllowableOffset: maxAllowableOffset,
                mode: mode,
                noData: noData,
                password: password,
                serviceHost: serviceHost,
                serviceName: serviceName,
                serviceURL: serviceURL,
                skipGetCapabilities: skipGetCapabilities,
                style: style,
                subLayers: subLayers,
                token: token,
                type: type,
                url: url,
                useAMF: useAMF,
                useMapTime: useMapTime,
                useProxy: useProxy,
                username: username,
                version: version,
                visible: visible,
                visibleLayers: visibleLayers,
                wkid: wkid
            };

        // look for info, infoconfig and popupconfig on basemaps and operational layers
        var opLayerInfo:String = obj.@info;
        var opLayerInfoConfig:String = obj.@infoconfig;
        var opLayerPopUpConfig:String = obj.@popupconfig;
        resultObject.popUpConfig = opLayerPopUpConfig;
        resultObject.infoConfig = opLayerInfoConfig;
        resultObject.infoUrl = opLayerInfo;
        resultObject.layer = layer;
        if (!isOpLayer)
        {
            var reference:Boolean = obj.@reference[0] && obj.@reference == "true";
            resultObject.reference = reference;
        }

        return resultObject;
    }

    private function getDefaultString(token:String):String
    {
        return ResourceManager.getInstance().getString("ViewerStrings", token);
    }

    private function parseClusterer(clusteringXML:XML):ESRIClusterer
    {
        var clusterer:ESRIClusterer;

        if (clusteringXML)
        {
            var clusterSymbol:Symbol;
            if (clusteringXML.clustersymbol[0])
            {
                clusterSymbol = parseClusterSymbol(clusteringXML.clustersymbol[0]);
            }

            if (clusterSymbol)
            {
                clusterer = new WeightedClusterer();
                if (clusteringXML.@mingraphiccount[0])
                {
                    clusterer.minGraphicCount = parseInt(clusteringXML.@mingraphiccount[0]);
                }
                if (clusteringXML.@sizeinpixels[0])
                {
                    clusterer.sizeInPixels = parseFloat(clusteringXML.@sizeinpixels[0]);
                }
                clusterer.symbol = clusterSymbol;
            }
        }

        return clusterer;
    }

    private function parseClusterSymbol(clusterSymbolXML:XML):Symbol
    {
        var clusterSymbol:Symbol;

        var type:String = clusterSymbolXML.@type;

        if (type == "simple")
        {
            clusterSymbol = parseSimpleClusterSymbol(clusterSymbolXML);
        }
        else if (type == "flare")
        {
            clusterSymbol = parseFlareSymbol(clusterSymbolXML);
        }

        return clusterSymbol;
    }

    private function parseSimpleClusterSymbol(clusterSymbolXML:XML):Symbol
    {
        var simpleClusterSymbol:SimpleClusterSymbol = new SimpleClusterSymbol();

        if (clusterSymbolXML.@alpha[0])
        {
            simpleClusterSymbol.alpha = parseFloat(clusterSymbolXML.@alpha[0]);
        }
        if (clusterSymbolXML.@color[0])
        {
            simpleClusterSymbol.color = parseInt(clusterSymbolXML.@color[0]);
        }
        if (clusterSymbolXML.@size[0])
        {
            simpleClusterSymbol.size = parseFloat(clusterSymbolXML.@size[0]);
        }
        if (clusterSymbolXML.@alphas[0])
        {
            simpleClusterSymbol.alphas = parseAlphas(clusterSymbolXML.@alphas[0]);
        }
        if (clusterSymbolXML.@sizes[0])
        {
            simpleClusterSymbol.sizes = parseSizes(clusterSymbolXML.@sizes[0]);
        }
        if (clusterSymbolXML.@weights[0])
        {
            simpleClusterSymbol.weights = parseWeights(clusterSymbolXML.@weights[0]);
        }
        if (clusterSymbolXML.@colors[0])
        {
            simpleClusterSymbol.colors = parseColors(clusterSymbolXML.@colors[0]);
        }
        var textFormat:TextFormat = parseTextFormat(clusterSymbolXML);

        simpleClusterSymbol.textFormat = textFormat;

        return simpleClusterSymbol;
    }

    private function parseAlphas(delimitedAlphas:String):Array
    {
        var alphas:Array = [];
        var alphasToParse:Array = delimitedAlphas.split(',');
        for each (var alpha:String in alphasToParse)
        {
            alphas.push(parseFloat(alpha));
        }

        return alphas;
    }

    private function parseSizes(delimitedSizes:String):Array
    {
        var sizes:Array = [];
        var sizesToParse:Array = delimitedSizes.split(',');
        for each (var size:String in sizesToParse)
        {
            sizes.push(parseFloat(size));
        }

        return sizes;
    }

    private function parseWeights(delimitedWeights:String):Array
    {
        var weights:Array = [];
        var weightsToParse:Array = delimitedWeights.split(',');
        for each (var weight:String in weightsToParse)
        {
            weights.push(parseFloat(weight));
        }

        return weights;
    }

    private function parseColors(delimitedColors:String):Array
    {
        var colors:Array = [];
        var colorsToParse:Array = delimitedColors.split(',');
        for each (var color:String in colorsToParse)
        {
            colors.push(parseInt(color));
        }
        return colors;
    }

    private function parseTextFormat(clusterSymbolXML:XML):TextFormat
    {
        var textFormat:TextFormat = new TextFormat();

        if (clusterSymbolXML.@textcolor[0])
        {
            textFormat.color = parseInt(clusterSymbolXML.@textcolor);
        }
        if (clusterSymbolXML.@textsize[0])
        {
            textFormat.size = parseInt(clusterSymbolXML.@textsize);
        }

        return textFormat;
    }

    private function parseFlareSymbol(flareSymbolXML:XML):Symbol
    {
        var flareSymbol:FlareSymbol = new FlareSymbol();

        if (flareSymbolXML)
        {
            if (flareSymbolXML.@alpha[0])
            {
                flareSymbol.backgroundAlpha = parseFloat(flareSymbolXML.@alpha[0]);
            }
            if (flareSymbolXML.@color[0])
            {
                flareSymbol.backgroundColor = parseInt(flareSymbolXML.@color[0])
            }
            if (flareSymbolXML.@bordercolor[0])
            {
                flareSymbol.borderColor = parseInt(flareSymbolXML.@bordercolor[0]);
            }
            if (flareSymbolXML.@flaremaxcount[0])
            {
                flareSymbol.flareMaxCount = parseInt(flareSymbolXML.@flaremaxcount[0])
            }
            if (flareSymbolXML.@size[0])
            {
                flareSymbol.size = parseFloat(flareSymbolXML.@size[0]);
            }
            if (flareSymbolXML.@alphas[0])
            {
                flareSymbol.backgroundAlphas = parseAlphas(flareSymbolXML.@alphas[0]);
            }
            if (flareSymbolXML.@sizes[0])
            {
                flareSymbol.sizes = parseSizes(flareSymbolXML.@sizes[0]);
            }
            if (flareSymbolXML.@weights[0])
            {
                flareSymbol.weights = parseWeights(flareSymbolXML.@weights[0]);
            }
            if (flareSymbolXML.@colors[0])
            {
                flareSymbol.backgroundColors = parseColors(flareSymbolXML.@colors[0]);
            }

            flareSymbol.textFormat = parseTextFormat(flareSymbolXML);
        }

        return flareSymbol;
    }
}

}

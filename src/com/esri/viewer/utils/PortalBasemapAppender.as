package com.esri.viewer.utils
{

import com.esri.ags.events.PortalEvent;
import com.esri.ags.portal.Portal;
import com.esri.ags.portal.supportClasses.PortalGroup;
import com.esri.ags.portal.supportClasses.PortalItem;
import com.esri.ags.portal.supportClasses.PortalQueryParameters;
import com.esri.ags.portal.supportClasses.PortalQueryResult;
import com.esri.viewer.AppEvent;
import com.esri.viewer.ConfigData;

import flash.events.Event;
import flash.events.EventDispatcher;

import mx.resources.ResourceManager;
import mx.rpc.AsyncResponder;
import mx.rpc.Fault;
import mx.rpc.events.FaultEvent;
import mx.utils.ObjectUtil;

public class PortalBasemapAppender extends EventDispatcher
{
    private const PORTAL_BASEMAP_APPENDER:String = "PortalBasemapAppender";

    private var configData:ConfigData;
    private var portalURL:String;

    private var itemTitleOrder:Array;
    private var processedArcGISBasemaps:Array;
    private var totalBasemaps:int;
    private var totalPossibleArcGISBasemaps:int;

    private var comparableDefaultBasemapObjects:Array;
    private var defaultBasemapTitle:String;

    public function PortalBasemapAppender(portalURL:String, configData:ConfigData)
    {
        this.portalURL = portalURL;
        this.configData = configData;
    }

    public function fetchAndAppendPortalBasemaps():void
    {
        var portal:Portal = new Portal();
        portal.addEventListener(PortalEvent.LOAD, portal_loadedHandler);
        portal.addEventListener(FaultEvent.FAULT, portal_faultHandler);

        var locale:String = ResourceManager.getInstance().localeChain[0];
        portal.load(portalURL, toCultureCode(locale));
    }

    protected function portal_loadedHandler(event:PortalEvent):void
    {
        var portal:Portal = event.target as Portal;
        comparableDefaultBasemapObjects = getComparableBasemapObjects(portal.info.defaultBasemap);
        var queryParams:PortalQueryParameters = PortalQueryParameters.forQuery(portal.info.basemapGalleryGroupQuery);
        portal.queryGroups(queryParams, new AsyncResponder(portal_queryGroupsResultHandler, portal_queryGroupsFaultHandler, portal));
    }

    protected function portal_queryGroupsResultHandler(queryResult:PortalQueryResult, portal:Portal):void
    {
        if (queryResult.results.length > 0)
        {
            var portalGroup:PortalGroup = queryResult.results[0];
            var queryParams:PortalQueryParameters = PortalQueryParameters.forItemsInGroup(portalGroup.id).withLimit(50).withSortField("name");
            portal.queryItems(queryParams, new AsyncResponder(portal_queryItemsResultHandler, portal_queryItemsFaultHandler));
        }
        else
        {
            dispatchComplete();
        }
    }

    private function portal_queryItemsResultHandler(queryResult:PortalQueryResult, token:Object = null):void
    {
        var resultItems:Array = queryResult.results;
        totalPossibleArcGISBasemaps = resultItems.length;
        itemTitleOrder = [];
        processedArcGISBasemaps = [];
        totalBasemaps = configData.basemaps.length;
        var portalItem:PortalItem;
        for (var i:uint = 0; i < totalPossibleArcGISBasemaps; i++)
        {
            portalItem = resultItems[i];
            itemTitleOrder.push(portalItem.title);
            portalItem.getJSONData(new AsyncResponder(portalItem_getJSONDataResultHandler,
                                                      portalItem_getJSONDataFaultHandler,
                                                      portalItem));
        }
    }

    private function portalItem_getJSONDataResultHandler(itemData:Object, item:PortalItem):void
    {
        createBasemapLayerObject(itemData, item);
        if (isDefaultBasemap(itemData.baseMap))
        {
            defaultBasemapTitle = itemData.baseMap.title;
        }
        updateTotalArcGISBasemaps();
    }

    private function createBasemapLayerObject(itemData:Object, item:PortalItem):void
    {
        if (!itemData)
        {
            return;
        }

        var basemapObject:Object = itemData.baseMap;
        var basemapLayerObjects:Array = basemapObject.baseMapLayers;
        if (!(basemapObject && basemapLayerObjects))
        {
            return;
        }

        var title:String = basemapObject.title;
        var iconURL:String = item.thumbnailURL;
        var existingBasemapLayerObject:Object = findBasemapLayerObjectById(title);
        if (existingBasemapLayerObject)
        {
            existingBasemapLayerObject.icon = iconURL;
            return;
        }

        var basemapLayerObject:Object = basemapLayerObjects[0];
        addBasemapLayerObject(baseMapLayerObjectToLayerXML(title,
                                                           basemapLayerObject,
                                                           iconURL));

        var totalBaseMapLayers:int = basemapLayerObjects.length;
        if (totalBaseMapLayers > 1)
        {
            basemapLayerObject = basemapLayerObjects[1];
            addBasemapLayerObject(baseMapLayerObjectToLayerXML(title,
                                                               basemapLayerObject,
                                                               iconURL));
        }
    }

    private function isDefaultBasemap(basemapObject:Object):Boolean
    {
        var comparableBasemapObjects:Array = getComparableBasemapObjects(basemapObject);

        return (ObjectUtil.compare(comparableBasemapObjects, comparableDefaultBasemapObjects) == 0);
    }

    private function getComparableBasemapObjects(basemapObject:Object):Array
    {
        var basemapLayerObjects:Array = basemapObject.baseMapLayers;
        var comparableBasemapObjects:Array = [];
        var comparableBasemapLayerObject:Object;

        for each (var basemapLayerObject:Object in basemapLayerObjects)
        {
            comparableBasemapLayerObject = {};

            if (basemapLayerObject.url)
            {
                comparableBasemapLayerObject.url = basemapLayerObject.url;
            }
            if (basemapLayerObject.type)
            {
                comparableBasemapLayerObject.type = basemapLayerObject.type;
            }

            comparableBasemapObjects.push(comparableBasemapLayerObject);
        }

        return comparableBasemapObjects;
    }

    private function findBasemapLayerObjectById(id:String):Object
    {
        var layerObjectResult:Object;

        var basemapLayerObjects:Array = configData.basemaps;
        for each (var layerObject:Object in basemapLayerObjects)
        {
            if (layerObject.layer && (layerObject.layer.id == id))
            {
                layerObjectResult = layerObject;
                break;
            }
        }

        return layerObjectResult;
    }

    private function updateTotalArcGISBasemaps():void
    {
        totalPossibleArcGISBasemaps--;
        if (totalPossibleArcGISBasemaps == 0)
        {
            addArcGISBasemapsToConfig();
            dispatchComplete();
        }
    }

    private function dispatchComplete():void
    {
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function addArcGISBasemapsToConfig():void
    {
        var hasBasemaps:Boolean = (configData.basemaps.length > 0);

        if (!hasBasemaps)
        {
            if (defaultBasemapTitle)
            {
                setDefaultBasemapVisible();
            }
            else
            {
                setFirstBasemapVisible();
            }
        }

        addBasemapsInOrder();
    }

    private function setDefaultBasemapVisible():void
    {
        for each (var layerObject:Object in processedArcGISBasemaps)
        {
            if (defaultBasemapTitle == layerObject.label)
            {
                layerObject.visible = true;
            }
        }
    }

    private function setFirstBasemapVisible():void
    {
        if (!itemTitleOrder)
        {
            return;
        }

        var firstBasemapLabel:String = itemTitleOrder[0];
        for each (var layerObject:Object in processedArcGISBasemaps)
        {
            if (layerObject.label == firstBasemapLabel)
            {
                layerObject.visible = true;
            }
        }
    }

    private function addBasemapsInOrder():void
    {
        for each (var itemLabel:String in itemTitleOrder)
        {
            for each (var layerObject:Object in processedArcGISBasemaps)
            {
                if (layerObject.label == itemLabel)
                {
                    configData.basemaps.push(layerObject);
                }
            }
        }
    }

    private function addBasemapLayerObject(layerXML:XML):void
    {
        if (layerXML)
        {
            processedArcGISBasemaps.push(LayerObjectUtil.getLayerObject(layerXML,
                                                                        totalBasemaps++,
                                                                        false,
                                                                        configData.bingKey));
        }
    }

    private function baseMapLayerObjectToLayerXML(title:String, basemapLayerObject:Object, iconURL:String = null):XML
    {
        var layerXML:XML;
        const url:String = basemapLayerObject.url;
        const type:String = basemapLayerObject.type;

        if (url)
        {
            layerXML = createTiledLayerXML(title, iconURL, url, basemapLayerObject, false);
        }
        else if (isAllowedType(type))
        {
            layerXML = createNonEsriLayerXML(title, iconURL, basemapLayerObject, false, type);
        }

        return layerXML;
    }

    private function createTiledLayerXML(title:String, iconURL:String, url:String, basemapLayerObject:Object, visible:Boolean):XML
    {
        var layerXML:XML = <layer label={title}
                type="tiled"
                icon={iconURL}
                url={url}
                alpha={basemapLayerObject.opacity}
                visible={visible}/>;

        return layerXML;
    }

    private function isAllowedType(type:String):Boolean
    {
        return type == "OpenStreetMap" ||
            (isBingBasemap(type) && hasBingKey());
    }

    private function createNonEsriLayerXML(title:String, iconURL:String, basemapLayerObject:Object, visible:Boolean, type:String):XML
    {
        var layerXML:XML = <layer label={title}
                icon={iconURL}
                type={toViewerNonEsriLayerType(basemapLayerObject.type)}
                alpha={basemapLayerObject.opacity}
                visible={visible}/>;

        if (isBingBasemap(type))
        {
            layerXML.@style = mapBingStyleFromBasemapType(type);
        }

        return layerXML;
    }

    private function toViewerNonEsriLayerType(type:String):String
    {
        var viewerType:String;
        if (type == "OpenStreetMap")
        {
            viewerType = "osm";
        }
        else if (isBingBasemap(type))
        {
            viewerType = "bing";
        }

        return viewerType;
    }

    private function isBingBasemap(type:String):Boolean
    {
        return type && type.indexOf('BingMaps') > -1;
    }

    private function hasBingKey():Boolean
    {
        var bingKey:String = configData.bingKey;
        return (bingKey != null && bingKey.length > 0);
    }

    private function mapBingStyleFromBasemapType(type:String):String
    {
        if (type == 'BingMapsAerial')
        {
            return 'aerial';
        }
        else if (type == 'BingMapsHybrid')
        {
            return 'aerialWithLabels';
        }
        else
        {
            //default - BingMapsRoad
            return 'road';
        }
    }

    private function portalItem_getJSONDataFaultHandler(fault:Fault, token:Object = null):void
    {
        var errorMessage:String = 'Could not fetch basemap data\n' + fault.faultString;
        AppEvent.dispatch(AppEvent.APP_ERROR, errorMessage);
        updateTotalArcGISBasemaps();
    }

    private function portal_queryGroupsFaultHandler(fault:Fault, token:Object = null):void
    {
        AppEvent.showError("Could not query portal.", PORTAL_BASEMAP_APPENDER);
        dispatchComplete();
    }

    private function portal_queryItemsFaultHandler(fault:Fault, token:Object = null):void
    {
        AppEvent.showError("Could not query portal items.", PORTAL_BASEMAP_APPENDER);
        dispatchComplete();
    }

    private function portal_faultHandler(event:FaultEvent):void
    {
        AppEvent.showError("Could not connect to Portal.", PORTAL_BASEMAP_APPENDER);
        dispatchComplete();
    }

    private function toCultureCode(locale:String):String
    {
        return locale.replace('_', '-');
    }
}
}

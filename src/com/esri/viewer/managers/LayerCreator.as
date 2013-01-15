///////////////////////////////////////////////////////////////////////////
// Copyright (c) 2012 Esri. All Rights Reserved.
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

import com.esri.ags.SpatialReference;
import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
import com.esri.ags.layers.ArcGISImageServiceLayer;
import com.esri.ags.layers.ArcGISTiledMapServiceLayer;
import com.esri.ags.layers.ArcIMSMapServiceLayer;
import com.esri.ags.layers.CSVLayer;
import com.esri.ags.layers.FeatureLayer;
import com.esri.ags.layers.GeoRSSLayer;
import com.esri.ags.layers.KMLLayer;
import com.esri.ags.layers.Layer;
import com.esri.ags.layers.OpenStreetMapLayer;
import com.esri.ags.layers.WMSLayer;
import com.esri.ags.layers.WMTSLayer;
import com.esri.ags.layers.supportClasses.Field;
import com.esri.ags.virtualearth.VETiledLayer;

import flash.utils.setInterval;

import mx.collections.ArrayCollection;
import mx.collections.ArrayList;

public class LayerCreator
{
    public static function createLayerFromLayerObject(layerObject:Object):Layer
    {
        return createLayer(LayerCreationProperties.fromLayerObject(layerObject));
    }

    private static function createLayer(layerCreationProperties:LayerCreationProperties):Layer
    {
        var layerType:String = layerCreationProperties.type.toLowerCase();

        if (layerType == "tiled")
        {
            return createTiledLayer(layerCreationProperties);
        }
        else if (layerType == "dynamic")
        {
            return createDynamicLayer(layerCreationProperties);
        }
        else if (layerType == "feature")
        {
            return createFeatureLayer(layerCreationProperties);
        }
        else if (layerType == "bing")
        {
            return createBingLayer(layerCreationProperties);
        }
        else if (layerType == "image")
        {
            return createImageLayer(layerCreationProperties);
        }
        else if (layerType == "arcims")
        {
            return createArcIMSLayer(layerCreationProperties);
        }
        else if (layerType == "wms")
        {
            return createWMSLayer(layerCreationProperties);
        }
        else if (layerType == "wmts")
        {
            return createWMTSLayer(layerCreationProperties);
        }
        else if (layerType == "osm")
        {
            return createOSMLayer(layerCreationProperties);
        }
        else if (layerType == "kml")
        {
            return createKMLLayer(layerCreationProperties);
        }
        else if (layerType == "csv")
        {
            return createCSVLayer(layerCreationProperties);
        }
        else if (layerType == "georss")
        {
            return createGeoRSSLayer(layerCreationProperties);
        }
        else
        {
            //TODO: throw meaningful error instead.
            return null;
        }
    }

    private static function createTiledLayer(layerCreationProperties:LayerCreationProperties):ArcGISTiledMapServiceLayer
    {
        var tiledLayer:ArcGISTiledMapServiceLayer = new ArcGISTiledMapServiceLayer(layerCreationProperties.url);
        tiledLayer.alpha = layerCreationProperties.alpha;
        tiledLayer.id = layerCreationProperties.label;
        tiledLayer.name = layerCreationProperties.label;
        tiledLayer.token = layerCreationProperties.token;
        tiledLayer.visible = layerCreationProperties.visible;
        if (layerCreationProperties.displayLevels)
        {
            tiledLayer.displayLevels = layerCreationProperties.displayLevels.split(",");
            for (var i:int = 0; i < tiledLayer.displayLevels.length; i++)
            {
                tiledLayer.displayLevels[i] = Number(tiledLayer.displayLevels[i]); // convert to Numbers
            }
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            tiledLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            tiledLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            tiledLayer.maxScale = layerCreationProperties.maxScale;
        }
        return tiledLayer;
    }

    private static function createDynamicLayer(layerCreationProperties:LayerCreationProperties):ArcGISDynamicMapServiceLayer
    {
        var dynLayer:ArcGISDynamicMapServiceLayer = new ArcGISDynamicMapServiceLayer(layerCreationProperties.url);
        dynLayer.alpha = layerCreationProperties.alpha;
        dynLayer.id = layerCreationProperties.label;
        dynLayer.gdbVersion = layerCreationProperties.gdbVersion;
        dynLayer.name = layerCreationProperties.label;
        dynLayer.token = layerCreationProperties.token;
        dynLayer.visible = layerCreationProperties.visible;
        dynLayer.useMapTime = layerCreationProperties.useMapTime;
        dynLayer.disableClientCaching = layerCreationProperties.disableClientCaching;
        if (layerCreationProperties.autoRefresh > 0)
        {
            setInterval(dynLayer.refresh, layerCreationProperties.autoRefresh * 1000);
        }
        if (layerCreationProperties.imageFormat)
        {
            dynLayer.imageFormat = layerCreationProperties.imageFormat;
        }
        if (layerCreationProperties.visibleLayers)
        {
            var vizLayers:Array = layerCreationProperties.visibleLayers.split(",");
            for (var i:int = 0; i < vizLayers.length; i++)
            {
                vizLayers[i] = Number(vizLayers[i]); // convert to Numbers
            }
            dynLayer.visibleLayers = new ArrayCollection(vizLayers);
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            dynLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            dynLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            dynLayer.maxScale = layerCreationProperties.maxScale;
        }
        if (layerCreationProperties.maxImageHeight > 0)
        {
            dynLayer.maxImageHeight = layerCreationProperties.maxImageHeight;
        }
        if (layerCreationProperties.maxImageWidth > 0)
        {
            dynLayer.maxImageWidth = layerCreationProperties.maxImageWidth;
        }
        return dynLayer;
    }

    private static function createFeatureLayer(layerCreationProperties:LayerCreationProperties):FeatureLayer
    {
        var featureLayer:FeatureLayer = new FeatureLayer(layerCreationProperties.url);

        featureLayer.alpha = layerCreationProperties.alpha;
        featureLayer.id = layerCreationProperties.label;
        featureLayer.gdbVersion = layerCreationProperties.gdbVersion;
        featureLayer.name = layerCreationProperties.label;
        featureLayer.maxAllowableOffset = layerCreationProperties.maxAllowableOffset;
        featureLayer.outFields = [ '*' ]; // TODO: be smarter
        featureLayer.token = layerCreationProperties.token;
        featureLayer.visible = layerCreationProperties.visible;
        featureLayer.useMapTime = layerCreationProperties.useMapTime;
        featureLayer.clusterer = layerCreationProperties.clusterer;
        featureLayer.disableClientCaching = layerCreationProperties.disableClientCaching;
        if (layerCreationProperties.renderer)
        {
            featureLayer.renderer = layerCreationProperties.renderer;
        }
        if (layerCreationProperties.autoRefresh > 0)
        {
            setInterval(featureLayer.refresh, layerCreationProperties.autoRefresh * 1000);
        }
        if (layerCreationProperties.useAMF)
        {
            featureLayer.useAMF = (layerCreationProperties.useAMF == "true");
        }
        if (layerCreationProperties.mode)
        {
            featureLayer.mode = layerCreationProperties.mode;
        }
        if (layerCreationProperties.definitionExpression)
        {
            featureLayer.definitionExpression = layerCreationProperties.definitionExpression;
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            featureLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            featureLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            featureLayer.maxScale = layerCreationProperties.maxScale;
        }
        if (!layerCreationProperties.isEditable)
        {
            featureLayer.isEditable = false; // only set it if it is 'false'
        }
        // example for hard-coding layer symbology, e.g. for pre-10.0 ArcGIS Servers
        /* if (layerCreationProperties.label == "Traffic Cameras") // the layer label in main configuration file
        {
        var picSymbol:PictureMarkerSymbol = new PictureMarkerSymbol("assets/images/i_camera.png",30,30,0,0,0);
        var rend:Renderer = new SimpleRenderer(picSymbol);
        featureLayer.renderer = rend;
        } */
        return featureLayer;
    }

    private static function createBingLayer(layerCreationProperties:LayerCreationProperties):VETiledLayer
    {
        var veTiledLayer:VETiledLayer = new VETiledLayer();
        veTiledLayer.id = layerCreationProperties.label;
        veTiledLayer.name = layerCreationProperties.label;
        veTiledLayer.key = layerCreationProperties.bingMapKey;
        veTiledLayer.visible = layerCreationProperties.visible;
        veTiledLayer.alpha = layerCreationProperties.alpha;
        if (layerCreationProperties.style)
        {
            veTiledLayer.mapStyle = layerCreationProperties.style;
        }
        if (layerCreationProperties.culture)
        {
            veTiledLayer.culture = layerCreationProperties.culture;
        }
        if (layerCreationProperties.displayLevels)
        {
            veTiledLayer.displayLevels = layerCreationProperties.displayLevels.split(",");
            for (var i:int = 0; i < veTiledLayer.displayLevels.length; i++)
            {
                veTiledLayer.displayLevels[i] = Number(veTiledLayer.displayLevels[i]); // convert to Numbers
            }
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            veTiledLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            veTiledLayer.maxScale = layerCreationProperties.maxScale;
        }
        return veTiledLayer;
    }

    private static function createImageLayer(layerCreationProperties:LayerCreationProperties):ArcGISImageServiceLayer
    {
        var imgLayer:ArcGISImageServiceLayer = new ArcGISImageServiceLayer(layerCreationProperties.url);
        imgLayer.id = layerCreationProperties.label;
        imgLayer.name = layerCreationProperties.label;
        imgLayer.alpha = layerCreationProperties.alpha;
        imgLayer.token = layerCreationProperties.token;
        imgLayer.visible = layerCreationProperties.visible;
        imgLayer.noData = layerCreationProperties.noData;
        imgLayer.useMapTime = layerCreationProperties.useMapTime;
        imgLayer.disableClientCaching = layerCreationProperties.disableClientCaching;
        if (layerCreationProperties.imageFormat)
        {
            imgLayer.imageFormat = layerCreationProperties.imageFormat;
        }
        if (layerCreationProperties.bandIds)
        {
            imgLayer.bandIds = layerCreationProperties.bandIds.split(",");
            for (var i:int = 0; i < imgLayer.bandIds.length; i++)
            {
                imgLayer.bandIds[i] = Number(imgLayer.bandIds[i]); // convert to Numbers
            }
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            imgLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            imgLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            imgLayer.maxScale = layerCreationProperties.maxScale;
        }
        return imgLayer;
    }

    private static function createArcIMSLayer(layerCreationProperties:LayerCreationProperties):ArcIMSMapServiceLayer
    {
        var arcimsLayer:ArcIMSMapServiceLayer = new ArcIMSMapServiceLayer();
        arcimsLayer.alpha = layerCreationProperties.alpha;
        arcimsLayer.id = layerCreationProperties.label;
        arcimsLayer.name = layerCreationProperties.label;
        arcimsLayer.visible = layerCreationProperties.visible;
        arcimsLayer.serviceHost = layerCreationProperties.serviceHost;
        arcimsLayer.serviceName = layerCreationProperties.serviceName;
        if (layerCreationProperties.autoRefresh > 0)
        {
            setInterval(arcimsLayer.refresh, layerCreationProperties.autoRefresh * 1000);
        }
        if (layerCreationProperties.imageFormat)
        {
            arcimsLayer.imageFormat = layerCreationProperties.imageFormat;
        }
        if (layerCreationProperties.visibleLayers)
        {
            var visLayers:Array = layerCreationProperties.visibleLayers.split(",");
            arcimsLayer.visibleLayers = new ArrayCollection(visLayers);
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            arcimsLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (layerCreationProperties.username && layerCreationProperties.password)
        {
            arcimsLayer.username = layerCreationProperties.username;
            arcimsLayer.password = layerCreationProperties.password;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            arcimsLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            arcimsLayer.maxScale = layerCreationProperties.maxScale;
        }
        return arcimsLayer;
    }

    private static function createWMSLayer(layerCreationProperties:LayerCreationProperties):WMSLayer
    {
        var wmsLayer:WMSLayer = new WMSLayer(layerCreationProperties.url);
        wmsLayer.alpha = layerCreationProperties.alpha;
        wmsLayer.id = layerCreationProperties.label;
        wmsLayer.name = layerCreationProperties.label;
        wmsLayer.visible = layerCreationProperties.visible;
        wmsLayer.disableClientCaching = layerCreationProperties.disableClientCaching;
        if (layerCreationProperties.wkid)
        {
            wmsLayer.spatialReference = new SpatialReference(layerCreationProperties.wkid);
        }
        if (layerCreationProperties.autoRefresh > 0)
        {
            setInterval(wmsLayer.refresh, layerCreationProperties.autoRefresh * 1000);
        }
        if (layerCreationProperties.imageFormat)
        {
            wmsLayer.imageFormat = layerCreationProperties.imageFormat;
        }
        if (layerCreationProperties.visibleLayers)
        {
            var wmsVisLayers:Array = layerCreationProperties.visibleLayers.split(",");
            wmsLayer.visibleLayers = new ArrayList(wmsVisLayers);
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            wmsLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (layerCreationProperties.skipGetCapabilities)
        {
            wmsLayer.skipGetCapabilities = layerCreationProperties.skipGetCapabilities == "true";
        }
        if (layerCreationProperties.username && layerCreationProperties.password)
        {
            wmsLayer.username = layerCreationProperties.username;
            wmsLayer.password = layerCreationProperties.password;
        }
        if (layerCreationProperties.version)
        {
            wmsLayer.version = layerCreationProperties.version;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            wmsLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            wmsLayer.maxScale = layerCreationProperties.maxScale;
        }
        if (layerCreationProperties.maxImageHeight > 0)
        {
            wmsLayer.maxImageHeight = layerCreationProperties.maxImageHeight;
        }
        if (layerCreationProperties.maxImageWidth > 0)
        {
            wmsLayer.maxImageWidth = layerCreationProperties.maxImageWidth;
        }
        return wmsLayer;
    }

    private static function createWMTSLayer(layerCreationProperties:LayerCreationProperties):WMTSLayer
    {
        var wmtsLayer:WMTSLayer = new WMTSLayer(layerCreationProperties.url);
        wmtsLayer.alpha = layerCreationProperties.alpha;
        wmtsLayer.id = layerCreationProperties.label;
        wmtsLayer.name = layerCreationProperties.label;
        wmtsLayer.visible = layerCreationProperties.visible;
        if (layerCreationProperties.imageFormat)
        {
            wmtsLayer.imageFormat = layerCreationProperties.imageFormat;
        }
        if (layerCreationProperties.proxyUrl && layerCreationProperties.useProxy)
        {
            wmtsLayer.proxyURL = layerCreationProperties.proxyUrl;
        }
        if (layerCreationProperties.serviceMode)
        {
            wmtsLayer.serviceMode = layerCreationProperties.serviceMode;
        }
        if (layerCreationProperties.layerId)
        {
            wmtsLayer.layerId = layerCreationProperties.layerId;
        }
        if (layerCreationProperties.tileMatrixSetId)
        {
            wmtsLayer.tileMatrixSetId = layerCreationProperties.tileMatrixSetId;
        }
        if (layerCreationProperties.style)
        {
            wmtsLayer.style = layerCreationProperties.style;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            wmtsLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            wmtsLayer.maxScale = layerCreationProperties.maxScale;
        }
        return wmtsLayer;
    }

    private static function createOSMLayer(layerCreationProperties:LayerCreationProperties):OpenStreetMapLayer
    {
        var osmLayer:OpenStreetMapLayer = new OpenStreetMapLayer();
        osmLayer.alpha = layerCreationProperties.alpha;
        osmLayer.id = layerCreationProperties.label;
        osmLayer.name = layerCreationProperties.label;
        osmLayer.visible = layerCreationProperties.visible;
        if (!isNaN(layerCreationProperties.minScale))
        {
            osmLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            osmLayer.maxScale = layerCreationProperties.maxScale;
        }
        return osmLayer;
    }

    private static function createKMLLayer(layerCreationProperties:LayerCreationProperties):KMLLayer
    {
        var kmlLayer:KMLLayer = new KMLLayer(layerCreationProperties.url);

        kmlLayer.alpha = layerCreationProperties.alpha;
        kmlLayer.id = layerCreationProperties.label;
        kmlLayer.name = layerCreationProperties.label;
        kmlLayer.disableClientCaching = layerCreationProperties.disableClientCaching;
        if (layerCreationProperties.serviceURL)
        {
            kmlLayer.serviceURL = layerCreationProperties.serviceURL;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            kmlLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            kmlLayer.maxScale = layerCreationProperties.maxScale;
        }
        kmlLayer.visible = layerCreationProperties.visible;
        return kmlLayer;
    }

    private static function createCSVLayer(layerCreationProperties:LayerCreationProperties):CSVLayer
    {
        var csvLayer:CSVLayer = new CSVLayer(layerCreationProperties.url);

        csvLayer.alpha = layerCreationProperties.alpha;
        csvLayer.id = layerCreationProperties.label;
        csvLayer.name = layerCreationProperties.label;
        csvLayer.latitudeFieldName = layerCreationProperties.latitudeFieldName;
        csvLayer.longitudeFieldName = layerCreationProperties.longitudeFieldName;
        if (layerCreationProperties.renderer)
        {
            csvLayer.renderer = layerCreationProperties.renderer;
        }
        if (layerCreationProperties.columnDelimiter)
        {
            csvLayer.columnDelimiter = layerCreationProperties.columnDelimiter;
        }
        if (layerCreationProperties.sourceFields)
        {
            var sFields:Array = layerCreationProperties.sourceFields.split(",");
            var fields:Array = [];
            for (var i:int = 0; i < sFields.length; i++)
            {
                var field:Field = new Field;
                var fieldProps:Array = String(sFields[i]).split("|");
                if (fieldProps.length == 1) // field name only     
                {
                    field.name = fieldProps[0];
                }
                else if (fieldProps.length == 2) // field name and alias
                {
                    field.name = fieldProps[0];
                    field.alias = fieldProps[1];
                }
                else if (fieldProps.length == 3) // field name, alias and type
                {
                    field.name = fieldProps[0];
                    field.alias = fieldProps[1];
                    field.type = fieldProps[2];
                }
                fields.push(field);
            }
            csvLayer.sourceFields = fields;
        }
        return csvLayer;
    }

    private static function createGeoRSSLayer(layerCreationProperties:LayerCreationProperties):GeoRSSLayer
    {
        var geoRSSLayer:GeoRSSLayer = new GeoRSSLayer(layerCreationProperties.url);

        geoRSSLayer.alpha = layerCreationProperties.alpha;
        geoRSSLayer.id = layerCreationProperties.label;
        geoRSSLayer.name = layerCreationProperties.label;
        geoRSSLayer.disableClientCaching = layerCreationProperties.disableClientCaching;
        if (layerCreationProperties.serviceURL)
        {
            geoRSSLayer.serviceURL = layerCreationProperties.serviceURL;
        }
        if (!isNaN(layerCreationProperties.minScale))
        {
            geoRSSLayer.minScale = layerCreationProperties.minScale;
        }
        if (!isNaN(layerCreationProperties.maxScale))
        {
            geoRSSLayer.maxScale = layerCreationProperties.maxScale;
        }
        geoRSSLayer.visible = layerCreationProperties.visible;
        return geoRSSLayer;
    }
}

}

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
package com.esri.viewer.components.toc.tocClasses
{

import com.esri.ags.events.LayerEvent;
import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
import com.esri.ags.layers.ArcGISTiledMapServiceLayer;
import com.esri.ags.layers.ArcIMSMapServiceLayer;
import com.esri.ags.layers.KMLLayer;
import com.esri.ags.layers.Layer;
import com.esri.ags.layers.supportClasses.KMLFeatureInfo;
import com.esri.ags.layers.supportClasses.KMLFolder;
import com.esri.ags.layers.supportClasses.LayerInfo;
import com.esri.viewer.ViewerContainer;
import com.esri.viewer.components.toc.utils.MapUtil;

import mx.collections.ArrayCollection;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;

/**
 * A TOC item representing a map service or graphics layer.
 *
 * @private
 */
public class TocMapLayerItem extends TocItem
{
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------    

    private var _isMSOnly:Boolean = false;
    private var _isVisibleLayersSet:Boolean = false;
    private var _layer:Layer;
    private var _labelFunction:Function;

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new TocMapLayerItem
     */
    public function TocMapLayerItem(layer:Layer, labelFunction:Function = null, isMapServiceOnly:Boolean = false)
    {
        super();

        _layer = layer;
        _isMSOnly = isMapServiceOnly;
        // Set the initial visibility without causing a layer refresh
        setVisible(layer.visible, false);

        // check if the visiblelayers was set on the dynamic map servicelayer
        var opLayers:Array = ViewerContainer.getInstance().configData.opLayers;
        for (var i:int = 0; i < opLayers.length; )
        {
            if (layer is ArcGISDynamicMapServiceLayer && (layer.id == opLayers[i].label) && opLayers[i].visibleLayers)
            {
                _isVisibleLayersSet = true;
                break;
            }
            else
            {
                i++;
            }
        }

        if (labelFunction == null)
        {
            // Default label function
            labelFunction = MapUtil.labelLayer;
        }
        _labelFunction = labelFunction;
        label = labelFunction(layer);

        if (!isMapServiceOnly)
        {
            if (layer.loaded)
            {
                // Process the layer info immediately
                createChildren();
            }
        }

        // Listen for future layer load events
        layer.addEventListener(LayerEvent.LOAD, onLayerLoad, false, 0, true);

        // Listen for changes in layer visibility
        layer.addEventListener(FlexEvent.SHOW, onLayerShow, false, 0, true);
        layer.addEventListener(FlexEvent.HIDE, onLayerHide, false, 0, true);
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    //  layer
    //--------------------------------------------------------------------------

    /**
     * The map layer to which this TOC item is attached.
     */
    public function get layer():Layer
    {
        return _layer;
    }

    //--------------------------------------------------------------------------
    //
    //  Overriden Methods
    //
    //--------------------------------------------------------------------------    

    /**
     * @private
     */
    override internal function updateIndeterminateState(calledFromChild:Boolean = false):void
    {
        indeterminate = DEFAULT_INDETERMINATE;

        // Recurse up the tree
        if (parent)
        {
            parent.updateIndeterminateState(true);
        }
    }

    /**
     * @private
     */
    override internal function refreshLayer():void
    {
        layer.visible = visible;

        // ArcIMS requires layer names, whereas ArcGIS Server requires layer IDs
        var useLayerInfoName:Boolean = (layer is ArcIMSMapServiceLayer);

        var visLayers:Array = [];
        for each (var child:TocItem in children)
        {
            accumVisibleLayers(child, visLayers, useLayerInfoName);
        }

        if (layer is ArcGISDynamicMapServiceLayer)
        {
            ArcGISDynamicMapServiceLayer(layer).visibleLayers = new ArrayCollection(visLayers);
            ArcGISDynamicMapServiceLayer(layer).visibleLayers.removeEventListener(CollectionEvent.COLLECTION_CHANGE, visibleLayersChangeHandler);
            ArcGISDynamicMapServiceLayer(layer).visibleLayers.addEventListener(CollectionEvent.COLLECTION_CHANGE, visibleLayersChangeHandler);              
        }
        else if (layer is ArcIMSMapServiceLayer)
        {
            ArcIMSMapServiceLayer(layer).visibleLayers = new ArrayCollection(visLayers);
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    private function visibleLayersChangeHandler(event:CollectionEvent):void
    {   
        if (layer.visible)
        {   
            var layerInfos:Array=[];           
            // get the actual visible layers           
            var actualVisibleLayers:Array = getActualVisibleLayers(ArcGISDynamicMapServiceLayer(layer).visibleLayers.toArray(), ArcGISDynamicMapServiceLayer(layer).layerInfos.slice());
            for each (var child:TocLayerInfoItem in children)
            {   
                updateTOCItemVisibility(child, actualVisibleLayers);                              
            }            
        }
    }
    
    private function updateTOCItemVisibility(item:TocLayerInfoItem, actualVisibleLayers:Array):void
    {
        if (item.isGroupLayer())
        {   
            item.visible = actualVisibleLayers.indexOf(item.layerInfo.id) != -1;
            for each (var child:TocLayerInfoItem in item.children)
            {
                updateTOCItemVisibility(child, actualVisibleLayers);
            }
        }
        else
        {
            item.visible = actualVisibleLayers.indexOf(item.layerInfo.id) != -1;
        }
    } 
    
    private function accumVisibleLayers(item:TocItem, accum:Array, useLayerInfoName:Boolean = false):void
    {
        if (item.isGroupLayer())
        {
            // Don't include group layer IDs/names in the visible layer list, since the ArcGIS REST API
            // implicitly turns on all child layers when the group layer is visible. This goes
            // counter to what most users have come to expect from apps, e.g. ArcMap.

            if (item.visible) // only accumulate for a visible group layers
            {
                for each (var child:TocItem in item.children)
                {
                    accumVisibleLayers(child, accum, useLayerInfoName);
                }
            }
        }
        else
        { // Leaf layer
            if (item.visible)
            {
                if (item is TocLayerInfoItem)
                {
                    var layer:TocLayerInfoItem = TocLayerInfoItem(item);
                    accum.push(useLayerInfoName ? layer.layerInfo.name : layer.layerInfo.id);
                }
            }
        }
    }

    private function onLayerLoad(event:LayerEvent):void
    {
        // Relabel this item, since map layer URL or service name might have changed.
        label = _labelFunction(layer);
        if (!_isMSOnly)
        {
            createChildren();
        }
    }

    private function onLayerShow(event:FlexEvent):void
    {
        setVisible(layer.visible, true);
    }

    private function onLayerHide(event:FlexEvent):void
    {
        setVisible(layer.visible, true);
    }

    /**
     * Populates this item's children collection based on any layer info
     * of the map service.
     */
    private function createChildren():void
    {
        children = null;
        var layerInfos:Array; // of LayerInfo

        if (layer is ArcGISTiledMapServiceLayer)
        {
            layerInfos = ArcGISTiledMapServiceLayer(layer).layerInfos;
        }
        else if (layer is ArcGISDynamicMapServiceLayer)
        {
            var arcGISDynamicMapServiceLayer:ArcGISDynamicMapServiceLayer = ArcGISDynamicMapServiceLayer(layer);
            // TODO - watch for visibleLayers property change
            if (_isVisibleLayersSet)
            {
                layerInfos = [];
                // get the actual visible layers
                var actualVisibleLayers:Array = getActualVisibleLayers(arcGISDynamicMapServiceLayer.visibleLayers.toArray(), arcGISDynamicMapServiceLayer.layerInfos);
                for each (var layerInfo:LayerInfo in arcGISDynamicMapServiceLayer.layerInfos.slice())
                {
                    if (actualVisibleLayers.indexOf(layerInfo.id) != -1)
                    {
                        layerInfo.defaultVisibility = true;
                    }
                    else
                    {
                        layerInfo.defaultVisibility = false;
                    }
                    layerInfos.push(layerInfo);
                }
            }
            else
            {
                layerInfos = arcGISDynamicMapServiceLayer.layerInfos;
            }
        }
        else if (layer is ArcIMSMapServiceLayer)
        {
            layerInfos = ArcIMSMapServiceLayer(layer).layerInfos;
        }
        else if (layer is KMLLayer)
        {
            createKMLLayerTocItems(this, KMLLayer(layer));
        }

        if (layerInfos)
        {
            var rootLayers:Array = findRootLayers(layerInfos);
            for each (var layerInfo1:LayerInfo in rootLayers)
            {
                addChild(createTocLayer(this, layerInfo1, layerInfos, layerInfo1.defaultVisibility));
            }
        }
    }

    private function getActualVisibleLayers(layerIds:Array, layerInfos:Array):Array
    {
        var result:Array = [];

        layerIds = layerIds ? layerIds.concat() : null;
        var layerInfo:LayerInfo;
        var layerIdIndex:int;

        if (layerIds)
        {
            // replace group layers with their sub layers
            for each (layerInfo in layerInfos)
            {
                layerIdIndex = layerIds.indexOf(layerInfo.id);
                if (layerInfo.subLayerIds && layerIdIndex != -1)
                {
                    layerIds.splice(layerIdIndex, 1); // remove the group layer id
                    for each (var subLayerId:Number in layerInfo.subLayerIds)
                    {
                        layerIds.push(subLayerId); // add subLayerId
                    }
                }
            }

            for each (layerInfo in layerInfos.reverse())
            {
                if (layerIds.indexOf(layerInfo.id) != -1 && layerIds.indexOf(layerInfo.parentLayerId) == -1 && layerInfo.parentLayerId != -1)
                {
                    layerIds.push(layerInfo.parentLayerId);
                }
            }

            result = layerIds;
        }

        return result;
    }

    private static function createKMLLayerTocItems(parentItem:TocItem, layer:KMLLayer):void
    {
        for each (var folder:KMLFolder in layer.folders)
        {
            if (folder.parentFolderId == -1)
            {
                parentItem.addChild(createKmlFolderTocItem(parentItem, folder, layer.folders, layer));
            }
        }

        for each (var networkLink:KMLLayer in layer.networkLinks)
        {
            // If the parent folder exists , do not create NetworkLinkItem as it is already created
            if (!(hasParentFolder(Number(networkLink.id), layer.folders)))
            {
                // check if it is loaded
                if (networkLink.loaded)
                {
                    parentItem.addChild(createKmlNetworkLinkTocItem(parentItem, networkLink, layer));
                }
                else
                {
                    networkLink.addEventListener(LayerEvent.LOAD, networkLinkLoadHandler);
                }

                function networkLinkLoadHandler(event:LayerEvent):void
                {
                    parentItem.addChild(createKmlNetworkLinkTocItem(parentItem, networkLink, layer));
                }
            }
        }
    }

    private static function hasParentFolder(id:Number, folders:Array):Boolean
    {
        // find the immediate parent folder
        var parentFolderFound:Boolean;

        for (var i:int = 0; i < folders.length; )
        {
            for (var j:int = 0; j < KMLFolder(folders[i]).featureInfos.length; )
            {
                if (id == KMLFolder(folders[i]).featureInfos[j].id)
                {
                    parentFolderFound = true;
                    break;
                }
                else
                {
                    j++
                }
            }
            if (parentFolderFound)
            {
                break;
            }
            else
            {
                i++;
            }
        }

        return parentFolderFound;
    }

    private static function findRootLayers(layerInfos:Array):Array // of LayerInfo
    {
        var roots:Array = [];
        for each (var layerInfo:LayerInfo in layerInfos)
        {
            // ArcGIS: parentLayerId is -1
            // ArcIMS: parentLayerId is NaN
            if (isNaN(layerInfo.parentLayerId) || layerInfo.parentLayerId == -1)
            {
                roots.push(layerInfo);
            }
        }
        return roots;
    }

    private static function findLayerById(id:Number, layerInfos:Array):LayerInfo
    {
        for each (var layerInfo:LayerInfo in layerInfos)
        {
            if (id == layerInfo.id)
            {
                return layerInfo;
            }
        }
        return null;
    }

    private static function createTocLayer(parentItem:TocItem, layerInfo:LayerInfo, layerInfos:Array, isVisible:Boolean):TocLayerInfoItem
    {
        var item:TocLayerInfoItem = new TocLayerInfoItem(parentItem, layerInfo, isVisible);

        // Handle any sublayers of a group layer
        if (layerInfo.subLayerIds)
        {
            for each (var childId:Number in layerInfo.subLayerIds)
            {
                var childLayer:LayerInfo = findLayerById(childId, layerInfos);
                if (childLayer)
                {
                    item.addChild(createTocLayer(item, childLayer, layerInfos, childLayer.defaultVisibility));
                }
            }
        }
        return item;
    }

    private static function createKmlFolderTocItem(parentItem:TocItem, folder:KMLFolder, folders:Array, layer:KMLLayer):TocKmlFolderItem
    {
        var item:TocKmlFolderItem = new TocKmlFolderItem(parentItem, folder, layer);

        // Handle any sublayers of a group layer
        if (folder.subFolderIds && folder.subFolderIds.length > 0)
        {
            var lookInFeatureInfos:Boolean = true;
            for each (var childId:Number in folder.subFolderIds)
            {
                var childFolder:KMLFolder = findFolderById(childId, folders);
                if (childFolder)
                {
                    item.addChild(createKmlFolderTocItem(item, childFolder, folders, layer));
                }
            }
        }
        else if (folder.featureInfos && folder.featureInfos.length > 0)
        {
            for each (var featureInfo:KMLFeatureInfo in folder.featureInfos)
            {
                if (featureInfo.type == KMLFeatureInfo.NETWORK_LINK)
                {
                    var networkLink:KMLLayer = layer.getFeature(featureInfo) as KMLLayer;
                    item.addChild(createKmlNetworkLinkTocItem(item, networkLink, layer));
                }
            }
        }
        return item;
    }

    private static function createKmlNetworkLinkTocItem(item:TocItem, networkLink:KMLLayer, layer:KMLLayer):TocKmlNetworkLinkItem
    {
        var tocKmlNetworkLinkItem:TocKmlNetworkLinkItem = new TocKmlNetworkLinkItem(item, networkLink, layer);
        if (networkLink.loaded)
        {
            createKMLLayerTocItems(tocKmlNetworkLinkItem, networkLink); // as network link is also a type of KMLLayer
        }
        else
        {
            networkLink.addEventListener(LayerEvent.LOAD, layerLoadHandler);
        }

        function layerLoadHandler(event:LayerEvent):void
        {
            createKMLLayerTocItems(tocKmlNetworkLinkItem, networkLink);
        }

        return tocKmlNetworkLinkItem;
    }

    private static function findFolderById(id:Number, allFolders:Array):KMLFolder
    {
        var match:KMLFolder;

        for (var i:int = 0; i < allFolders.length; )
        {
            if (allFolders[i].id == id)
            {
                match = allFolders[i] as KMLFolder;
                break;
            }
            else
            {
                i++;
            }
        }

        return match;
    }
}

}

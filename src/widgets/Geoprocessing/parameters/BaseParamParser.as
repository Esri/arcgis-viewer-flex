///////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011 Esri. All Rights Reserved.
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
package widgets.Geoprocessing.parameters
{

import com.esri.ags.renderers.ClassBreaksRenderer;
import com.esri.ags.renderers.IRenderer;
import com.esri.ags.renderers.SimpleRenderer;
import com.esri.ags.renderers.UniqueValueRenderer;
import com.esri.ags.renderers.supportClasses.ClassBreakInfo;
import com.esri.ags.renderers.supportClasses.UniqueValueInfo;
import com.esri.ags.symbols.PictureMarkerSymbol;
import com.esri.ags.symbols.SimpleFillSymbol;
import com.esri.ags.symbols.SimpleLineSymbol;
import com.esri.ags.symbols.SimpleMarkerSymbol;
import com.esri.ags.symbols.Symbol;

public class BaseParamParser
{
    public function parseParameters(paramsXML:XMLList):Array
    {
        throw new Error("Abstract class - must be implemented by subclasses.");
    }

    protected function parseRenderer(rendererXML:XML, geometryType:String):IRenderer
    {
        var renderer:IRenderer

        if (rendererXML)
        {
            var rendererSymbol:Symbol;
            var rendererInfos:Array;

            if (rendererXML.defaultsymbol[0])
            {
                rendererSymbol = parseSymbol(rendererXML.defaultsymbol[0], geometryType);
            }

            if (!rendererSymbol)
            {
                rendererSymbol = createDefaultSymbolFromGeometry(geometryType);
            }

            if (rendererXML.@type == FeatureLayerParameter.SIMPLE_RENDERER)
            {
                renderer = new SimpleRenderer(rendererSymbol);
            }
            else if (rendererXML.@type == FeatureLayerParameter.CLASS_BREAKS_RENDERER)
            {
                rendererInfos = parseClassBreakInfos(rendererXML.infos.symbol, geometryType);
                renderer = new ClassBreaksRenderer(rendererXML.@attribute, rendererSymbol, rendererInfos);
            }
            else if (rendererXML.@type == FeatureLayerParameter.UNIQUE_VALUE_RENDERER)
            {
                rendererInfos = parseUniqueValueInfos(rendererXML.infos.symbol, geometryType);
                renderer = new UniqueValueRenderer(rendererXML.@attribute, rendererSymbol, rendererInfos);
            }
            else
            {
                renderer = new SimpleRenderer(rendererSymbol);
            }
        }

        if (!renderer)
        {
            renderer = new SimpleRenderer(createDefaultSymbolFromGeometry(geometryType));
        }

        return renderer;
    }

    private function parseSymbol(symbolXML:XML, geometryType:String):Symbol
    {
        var symbol:Symbol;
        var symbolType:String = symbolXML.@type;

        switch (geometryType)
        {
            case FeatureLayerParameter.POINT:
            {
                if (symbolType == FeatureLayerParameter.SIMPLE_MARKER || symbolType == FeatureLayerParameter.PICTURE_MARKER)
                {
                    symbol = symbolType == FeatureLayerParameter.SIMPLE_MARKER ? parseSimpleMarkerSymbol(symbolXML) : parsePictureMarkerSymbol(symbolXML);
                }
                else
                {
                    symbol = createDefaultSymbolFromGeometry(geometryType);
                }
                break;
            }
            case FeatureLayerParameter.POLYLINE:
            {
                symbol = symbolType == FeatureLayerParameter.SIMPLE_LINE ? parseSimpleLineSymbol(symbolXML) : createDefaultSymbolFromGeometry(geometryType);
                break;
            }
            case FeatureLayerParameter.POLYGON:
            {
                symbol = symbolType == FeatureLayerParameter.SIMPLE_FILL ? parseSimpleFillSymbol(symbolXML) : createDefaultSymbolFromGeometry(geometryType);
                break;
            }
        }

        return symbol;
    }

    private function parseSimpleMarkerSymbol(symbolXML:XML):SimpleMarkerSymbol
    {
        var simpleMarkerSymbol:SimpleMarkerSymbol = createDefaultPointSymbol();

        if (symbolXML.@alpha[0])
        {
            simpleMarkerSymbol.alpha = symbolXML.@alpha;
        }
        if (symbolXML.@color[0])
        {
            simpleMarkerSymbol.color = symbolXML.@color;
        }
        if (symbolXML.@size[0])
        {
            simpleMarkerSymbol.size = symbolXML.@size;
        }

        var outlineSymbol:SimpleLineSymbol = createDefaultOutlineSymbol();
        if (symbolXML.outline.@color[0])
        {
            outlineSymbol.color = symbolXML.outline.@color;
        }
        if (symbolXML.outline.@width[0])
        {
            outlineSymbol.width = symbolXML.outline.@width;
        }

        simpleMarkerSymbol.outline = outlineSymbol;

        return simpleMarkerSymbol;
    }

    private function parseSimpleFillSymbol(symbolXML:XML):SimpleFillSymbol
    {
        var simpleFillSymbol:SimpleFillSymbol = createDefaultPolygonSymbol();

        if (symbolXML.@alpha[0])
        {
            simpleFillSymbol.alpha = symbolXML.@alpha;
        }
        if (symbolXML.@color[0])
        {
            simpleFillSymbol.color = symbolXML.@color;
        }

        var outlineSymbol:SimpleLineSymbol = createDefaultOutlineSymbol();
        if (symbolXML.outline.@color[0])
        {
            outlineSymbol.color = symbolXML.outline.@color;
        }
        if (symbolXML.outline.@width[0])
        {
            outlineSymbol.width = symbolXML.outline.@width;
        }

        simpleFillSymbol.outline = outlineSymbol;

        return simpleFillSymbol;
    }

    private function parseSimpleLineSymbol(symbolXML:XML):SimpleLineSymbol
    {
        var simpleLineSymbol:SimpleLineSymbol = createDefaultPolylineSymbol();

        if (symbolXML.@alpha[0])
        {
            simpleLineSymbol.alpha = symbolXML.@alpha;
        }
        if (symbolXML.outline.@color[0])
        {
            simpleLineSymbol.color = symbolXML.outline.@color;
        }
        if (symbolXML.outline.@width[0])
        {
            simpleLineSymbol.width = symbolXML.outline.@width;
        }

        return simpleLineSymbol;
    }

    private function parsePictureMarkerSymbol(symbolXML:XML):PictureMarkerSymbol
    {
        var url:String = symbolXML.@url;
        var height:Number = symbolXML.@height || 0;
        var width:Number = symbolXML.@width || 0;
        var xOffset:Number = symbolXML.@xoffset || 0;
        var yOffset:Number = symbolXML.@yoffset || 0;
        var angle:Number = symbolXML.@angle || 0;

        return new PictureMarkerSymbol(url, width, height, xOffset, yOffset, angle);
    }

    private function createDefaultSymbolFromGeometry(geometryType:String):Symbol
    {
        var defaultSymbol:Symbol;

        if (geometryType == FeatureLayerParameter.POINT)
        {
            defaultSymbol = createDefaultPointSymbol();
        }
        else if (geometryType == FeatureLayerParameter.POLYGON)
        {
            defaultSymbol = createDefaultPolygonSymbol();
        }
        else if (geometryType == FeatureLayerParameter.POLYLINE)
        {
            defaultSymbol = createDefaultPolylineSymbol();
        }

        return defaultSymbol;
    }

    protected function createDefaultPointSymbol():SimpleMarkerSymbol
    {
        return new SimpleMarkerSymbol();
    }

    protected function createDefaultPolygonSymbol():SimpleFillSymbol
    {
        return new SimpleFillSymbol();
    }

    protected function createDefaultPolylineSymbol():SimpleLineSymbol
    {
        return new SimpleLineSymbol();
    }

    protected function createDefaultOutlineSymbol():SimpleLineSymbol
    {
        return new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, 0, 1, 1);
    }

    private function parseClassBreakInfos(classBreaksInfosXMLList:XMLList, geometryType:String):Array
    {
        var classBreakInfos:Array = [];

        for each (var classBreaksInfoXML:XML in classBreaksInfosXMLList)
        {
            classBreakInfos.push(
                new ClassBreakInfo(parseSymbol(classBreaksInfoXML[0], geometryType), classBreaksInfoXML.@min, classBreaksInfoXML.@max));
        }

        return classBreakInfos;
    }

    private function parseUniqueValueInfos(uniqueValueInfosXMLList:XMLList, geometryType:String):Array
    {
        var uniqueValueInfos:Array = [];

        for each (var uniqueValueInfoXML:XML in uniqueValueInfosXMLList)
        {
            uniqueValueInfos.push(
                new UniqueValueInfo(parseSymbol(uniqueValueInfoXML[0], geometryType), uniqueValueInfoXML.@value));
        }

        return uniqueValueInfos;
    }
}

}

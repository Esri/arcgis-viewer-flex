package com.esri.viewer.utils
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

public class RendererParser
{
    public function parseRenderer(rendererXML:XML):IRenderer
    {
        var renderer:IRenderer;

        if (rendererXML)
        {
            if (rendererXML.simplerenderer[0])
            {
                renderer = new SimpleRenderer(parseSymbol(rendererXML.simplerenderer[0]));
            }
            else if (rendererXML.classbreaksrenderer[0])
            {
                renderer = parseClassBreaksRenderer(rendererXML.classbreaksrenderer[0]);
            }
            else if (rendererXML.uniquevaluerenderer[0])
            {
                renderer = parseUniqueValueRenderer(rendererXML.uniquevaluerenderer[0]);
            }
        }

        return renderer;
    }

    private function parseClassBreaksRenderer(rendererXML:XML):IRenderer
    {
        var cbRenderer:ClassBreaksRenderer = new ClassBreaksRenderer(rendererXML.@field[0],
                                                                     parseSymbol(rendererXML),
                                                                     parseClassBreakInfos(rendererXML.classbreakinfo));
        if (rendererXML.defaultlabel[0])
        {
            cbRenderer.defaultLabel = rendererXML.defaultlabel;
        }

        return cbRenderer;
    }

    private function parseSymbol(symbolXML:XML):Symbol
    {
        var symbol:Symbol;

        if (symbolXML.simplemarkersymbol[0])
        {
            symbol = parseSimpleMarkerSymbol(symbolXML.simplemarkersymbol[0]);
        }
        else if (symbolXML.picturemarkersymbol[0])
        {
            symbol = parsePictureMarkerSymbol(symbolXML.picturemarkersymbol[0]);
        }
        else if (symbolXML.simplelinesymbol[0])
        {
            symbol = parseSimpleLineSymbol(symbolXML.simplelinesymbol[0]);
        }
        else if (symbolXML.simplefillsymbol[0])
        {
            symbol = parseSimpleFillSymbol(symbolXML.simplefillsymbol[0]);
        }

        return symbol;
    }

    private function parseSimpleMarkerSymbol(smsXML:XML):SimpleMarkerSymbol
    {
        const simpleMarkerSymbol:SimpleMarkerSymbol = createDefaultPointSymbol();

        const parsedColor:Number = parseInt(smsXML.@color[0]);
        const parsedAlpha:Number = parseFloat(smsXML.@alpha[0]);
        const parsedSize:Number = parseFloat(smsXML.@size[0]);

        if (smsXML.@style[0])
        {
            simpleMarkerSymbol.style = smsXML.@style;
        }
        if (!isNaN(parsedAlpha))
        {
            simpleMarkerSymbol.alpha = parsedAlpha;
        }
        if (!isNaN(parsedColor))
        {
            simpleMarkerSymbol.color = parsedColor;
        }
        if (!isNaN(parsedSize))
        {
            simpleMarkerSymbol.size = parsedSize;
        }

        const outlineSymbol:SimpleLineSymbol = createDefaultOutlineSymbol();

        const parsedOutlineColor:uint = parseInt(smsXML.outline.@color[0]);
        const parsedOutlineWidth:Number = parseFloat(smsXML.outline.@width[0]);

        if (smsXML.outline.@style[0])
        {
            outlineSymbol.style = smsXML.outline.@style
        }
        if (!isNaN(parsedOutlineColor))
        {
            outlineSymbol.color = parsedOutlineColor;
        }
        if (!isNaN(parsedOutlineWidth))
        {
            outlineSymbol.width = parsedOutlineWidth;
        }

        simpleMarkerSymbol.outline = outlineSymbol;

        return simpleMarkerSymbol;
    }

    protected function createDefaultPointSymbol():SimpleMarkerSymbol
    {
        return new SimpleMarkerSymbol();
    }

    protected function createDefaultOutlineSymbol():SimpleLineSymbol
    {
        return new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, 0, 1, 1);
    }

    private function parsePictureMarkerSymbol(pmsXML:XML):PictureMarkerSymbol
    {
        const url:String = pmsXML.@url;

        const parsedHeight:Number = parseFloat(pmsXML.@height[0]);
        const parsedWidth:Number = parseFloat(pmsXML.@width[0]);
        const parsedXOffset:Number = parseFloat(pmsXML.@xoffset[0]);
        const parsedYOffset:Number = parseFloat(pmsXML.@yoffset[0]);
        const parsedAngle:Number = parseFloat(pmsXML.@angle[0]);

        const height:Number = !isNaN(parsedHeight) ? parsedHeight : 0;
        const width:Number = !isNaN(parsedWidth) ? parsedWidth : 0;
        const xOffset:Number = !isNaN(parsedXOffset) ? parsedXOffset : 0;
        const yOffset:Number = !isNaN(parsedYOffset) ? parsedYOffset : 0;
        const angle:Number = !isNaN(parsedAngle) ? parsedAngle : 0;

        return new PictureMarkerSymbol(url, width, height, xOffset, yOffset, angle);
    }

    private function parseSimpleLineSymbol(slsXML:XML):SimpleLineSymbol
    {
        const simpleLineSymbol:SimpleLineSymbol = createDefaultPolylineSymbol();

        const parsedAlpha:Number = parseFloat(slsXML.@alpha[0]);
        const parsedOutlineColor:uint = parseInt(slsXML.@color[0]);
        const parsedOutlineWidth:Number = parseFloat(slsXML.@width[0]);

        if (slsXML.@style[0])
        {
            simpleLineSymbol.style = slsXML.@style;
        }
        if (!isNaN(parsedAlpha))
        {
            simpleLineSymbol.alpha = parsedAlpha;
        }
        if (!isNaN(parsedOutlineColor))
        {
            simpleLineSymbol.color = parsedOutlineColor;
        }
        if (!isNaN(parsedOutlineWidth))
        {
            simpleLineSymbol.width = parsedOutlineWidth;
        }

        return simpleLineSymbol;
    }

    protected function createDefaultPolylineSymbol():SimpleLineSymbol
    {
        return new SimpleLineSymbol();
    }

    private function parseSimpleFillSymbol(sfsXML:XML):SimpleFillSymbol
    {
        const simpleFillSymbol:SimpleFillSymbol = createDefaultPolygonSymbol();

        const parsedColor:Number = parseInt(sfsXML.@color[0]);
        const parsedAlpha:Number = parseFloat(sfsXML.@alpha[0]);

        if (sfsXML.@style[0])
        {
            simpleFillSymbol.style = sfsXML.@style;
        }
        if (!isNaN(parsedAlpha))
        {
            simpleFillSymbol.alpha = parsedAlpha;
        }
        if (!isNaN(parsedColor))
        {
            simpleFillSymbol.color = parsedColor;
        }

        const outlineSymbol:SimpleLineSymbol = createDefaultOutlineSymbol();

        const parsedOutlineColor:uint = parseInt(sfsXML.outline.@color[0]);
        const parsedOutlineWidth:Number = parseFloat(sfsXML.outline.@width[0]);

        if (sfsXML.outline.@style[0])
        {
            outlineSymbol.style = sfsXML.outline.@style;
        }
        if (!isNaN(parsedOutlineColor))
        {
            outlineSymbol.color = parsedOutlineColor;
        }
        if (!isNaN(parsedOutlineWidth))
        {
            outlineSymbol.width = parsedOutlineWidth;
        }

        simpleFillSymbol.outline = outlineSymbol;

        return simpleFillSymbol;
    }

    protected function createDefaultPolygonSymbol():SimpleFillSymbol
    {
        return new SimpleFillSymbol();
    }

    private function parseClassBreakInfos(classBreaksInfosXMLList:XMLList):Array
    {
        var classBreakInfos:Array = [];

        for each (var classBreaksInfoXML:XML in classBreaksInfosXMLList)
        {
            const classBreakInfo:ClassBreakInfo = new ClassBreakInfo(parseSymbol(classBreaksInfoXML),
                                                                     classBreaksInfoXML.@min,
                                                                     classBreaksInfoXML.@max);
            classBreakInfo.label = classBreaksInfoXML.@label;
            classBreakInfos.push(classBreakInfo);
        }

        return classBreakInfos;
    }

    private function parseUniqueValueRenderer(rendererXML:XML):IRenderer
    {
        var uvRenderer:UniqueValueRenderer = new UniqueValueRenderer(rendererXML.@field,
                                                                     parseSymbol(rendererXML),
                                                                     parseUniqueValueInfos(rendererXML.uniquevalueinfo));
        if (rendererXML.@field2[0])
        {
            uvRenderer.field2 = rendererXML.@field2;
        }
        if (rendererXML.@field3[0])
        {
            uvRenderer.field3 = rendererXML.@field3;
        }
        if (rendererXML.@fielddelimiter[0])
        {
            uvRenderer.fieldDelimiter = rendererXML.@fielddelimiter;
        }
        if (rendererXML.defaultlabel[0])
        {
            uvRenderer.defaultLabel = rendererXML.defaultlabel;
        }

        return uvRenderer;
    }

    private function parseUniqueValueInfos(uniqueValueInfosXMLList:XMLList):Array
    {
        var uniqueValueInfos:Array = [];

        for each (var uniqueValueInfoXML:XML in uniqueValueInfosXMLList)
        {
            const uniqueValueInfo:UniqueValueInfo = new UniqueValueInfo(parseSymbol(uniqueValueInfoXML),
                                                                        uniqueValueInfoXML.@value);
            uniqueValueInfo.label = uniqueValueInfoXML.@label;
            uniqueValueInfos.push(uniqueValueInfo);
        }

        return uniqueValueInfos;
    }
}
}

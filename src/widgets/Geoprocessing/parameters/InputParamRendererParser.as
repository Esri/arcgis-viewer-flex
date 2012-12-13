package widgets.Geoprocessing.parameters
{

import com.esri.ags.symbols.SimpleFillSymbol;
import com.esri.ags.symbols.SimpleLineSymbol;
import com.esri.ags.symbols.SimpleMarkerSymbol;
import com.esri.viewer.utils.RendererParser;

public class InputParamRendererParser extends RendererParser
{
    //override default symbols to match draw widget defaults

    override protected function createDefaultPointSymbol():SimpleMarkerSymbol
    {
        return new SimpleMarkerSymbol(SimpleMarkerSymbol.STYLE_CIRCLE, 15, 0x3FAFDC, 1, 0, 0, 0, new SimpleLineSymbol());
    }

    override protected function createDefaultPolygonSymbol():SimpleFillSymbol
    {
        return new SimpleFillSymbol(SimpleFillSymbol.STYLE_SOLID, 0x3FAFDC, 1, new SimpleLineSymbol());
    }

    override protected function createDefaultPolylineSymbol():SimpleLineSymbol
    {
        return new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, 0x3FAFDC, 1, 5);
    }
}
}

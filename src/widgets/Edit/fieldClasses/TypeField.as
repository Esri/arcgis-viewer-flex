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
package widgets.Edit.fieldClasses
{

import com.esri.ags.components.supportClasses.ITypeField;
import com.esri.ags.layers.supportClasses.FeatureType;

import mx.collections.ArrayList;
import mx.collections.IList;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

import spark.components.DropDownList;
import spark.components.supportClasses.TextBase;
import spark.events.DropDownEvent;

/**
 * @private
 * 
 * Drop down list component used in the AttributeInspector to handle feature types attribute values.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class TypeField extends DropDownList implements ITypeField
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new TypeField.
     */
    public function TypeField()
    {
        minWidth = 128;
        requireSelection = true;
        labelField = "name";
        setStyle('contentBackgroundAlpha', 1);
        addEventListener(DropDownEvent.CLOSE, closeHandler);
    }


    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var m_featureTypeNotInDomain:FeatureType;


    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  editable
    //----------------------------------
    
    [Bindable("enabledChanged")]
    [Inspectable(category="General", enumeration="true,false", defaultValue="true")]
    
    /**
     * @inheritDoc
     */
    public function get editable():Boolean
    {
        return enabled;
    }
    
    /**
     * @private
     */
    public function set editable(value:Boolean):void
    {
        enabled = value;
    }

    //----------------------------------
    //  featureTypes
    //----------------------------------

    private var m_featureTypes:Array;
    private var m_featureTypesChanged:Boolean = false;

    /**
     * @inheritDoc
     */
    public function get featureTypes():Array
    {
        return m_featureTypes;
    }

    /**
     * @private
     */
    public function set featureTypes(value:Array):void
    {
        if (m_featureTypes !== value)
        {
            m_featureTypes = value;
            m_featureTypesChanged = true;
            invalidateProperties();
        }
    }

    //----------------------------------
    //  data
    //----------------------------------

    private var m_data:Object;
    private var m_oldFeatureType:Object;
    private var m_dataChanged:Boolean = false;

    /**
     * @inheritDoc
     */
    public function get data():Object
    {
        return m_data;
    }

    /**
     * @private
     */
    public function set data(value:Object):void
    {
        if (m_data != value)
        {
            m_data = value;
            m_dataChanged = true;
            invalidateProperties();
        }
    }
    
    //----------------------------------
    //  fieldLabel
    //----------------------------------
    
    private var m_fieldLabel:String;
    
    /**
     * @inheritDoc
     */
    public function get fieldLabel():String
    {
        return m_fieldLabel;
    }
    
    /**
     * @private
     */
    public function set fieldLabel(value:String):void
    {
        m_fieldLabel = value;
    }

    //----------------------------------
    //  dataProvider
    //----------------------------------

    /**
     * @private
     */
    override public function set dataProvider(value:IList):void
    {
        super.dataProvider = value;
        const list:IList = dataProvider;

        if (!list || list.length == 0)
        {
            return;
        }

        var longestNameItemIndex:int = 0;
        var i:int;
        for (i = 1; i < list.length; i++)
        {
            if (list.getItemAt(i).name.length > list.getItemAt(longestNameItemIndex).name.length)
            {
                longestNameItemIndex = i;
            }
        }
        typicalItem = list.getItemAt(longestNameItemIndex); // make the list wider, forcing it to not show scroller
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    override protected function commitProperties():void
    {
        if (skin)
        {
            super.commitProperties();
        }

        if (m_featureTypesChanged || m_dataChanged)
        {
            m_featureTypesChanged = m_dataChanged = false;

            if (m_featureTypes)
            {
                dataProvider = new ArrayList(m_featureTypes.concat());
            }
            else
            {
                dataProvider = null;
                return;
            }

            var featureType:FeatureType;
            var featureTypeIndex:int = -1;

            // Try to find the current data in the coded values of the domain
            for (var i:int = 0, n:int = dataProvider.length; i < n; i++)
            {
                featureType = dataProvider.getItemAt(i) as FeatureType;
                if (featureType.id == m_data)
                {
                    m_oldFeatureType = featureType;
                    featureTypeIndex = i;
                    break;
                }
            }

            // If the data isn't found, display the data with the lineThrough.
            if (!featureTypeIndex == -1 && m_data)
            {
                const id:String = m_data.toString();
                m_featureTypeNotInDomain = new FeatureType();
                m_featureTypeNotInDomain.id = id;
                m_featureTypeNotInDomain.name = id;
                dataProvider.addItemAt(m_featureTypeNotInDomain, 0);
                if (!initialized)
                {
                    addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
                }
                else
                {
                    updateFeatureTypeNotInDomainRenderer();
                }
            }
            else if (featureTypeIndex != -1)
            {
                selectedIndex = featureTypeIndex;
            }
        }
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  Public Methods: IFieldRenderer
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function formatToString(value:Object):String
    {
        // TODO return the name
        this.data = value;
        validateProperties();
        return selectedItem ? (selectedItem as FeatureType).name : null;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    private function updateFeatureTypeNotInDomainRenderer():void
    {
        const list:IList = dataProvider as IList;
        if (list && list.length && m_featureTypeNotInDomain === list.getItemAt(0) && labelDisplay)
        {
            if (labelDisplay is TextBase)
            {
                (labelDisplay as TextBase).setStyle('lineThrough', true);
            }
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Event Handlers
    //
    //--------------------------------------------------------------------------

    private function creationCompleteHandler(event:FlexEvent):void
    {
        removeEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
        updateFeatureTypeNotInDomainRenderer();
    }

    private function closeHandler(event:DropDownEvent):void
    {
        const featureType:FeatureType = selectedItem as FeatureType;
        if (m_data != featureType.id)
        {
            var pce:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "data", data, featureType.id, this);
            dispatchEvent(pce);
            pce = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "featureType", m_oldFeatureType, featureType, this);
            dispatchEvent(pce);
            m_data = featureType.id;
        }
        if (labelDisplay is TextBase)
        {
            (labelDisplay as TextBase).setStyle('lineThrough', m_featureTypeNotInDomain === selectedItem);
        }
    }
}

}

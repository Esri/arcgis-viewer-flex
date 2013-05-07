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

import com.esri.ags.components.supportClasses.IFieldRenderer;

import flash.events.Event;
import flash.events.MouseEvent;

import mx.collections.IList;
import mx.core.IDataRenderer;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

import spark.components.ButtonBar;

/**
 * @private
 * 
 * Button bar component that could be used in a FieldInspector.
 *
 * @since ArcGIS API for Flex 3.4
 *
 * @see http://resources.arcgis.com/en/help/flex-api/samples/#/Attribute_Inspector__edit_/01nq0000005z000000 Live sample - FieldInspector to customize fields in AttributeInspector
 */
public class ButtonBarField extends ButtonBar implements IFieldRenderer
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new ButtonBarField.
     */
    public function ButtonBarField()
    {
        requireSelection = true;
        addEventListener(MouseEvent.CLICK, clickHandler);
    }
    

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  valueField
    //----------------------------------

    private var m_valueField:String = "value";

    [Bindable("valueFieldChanged")]

    /**
     * The name of the value field.
     *
     * @default value
     */
    public function get valueField():String
    {
        return m_valueField;
    }

    /**
     * @private
     */
    public function set valueField(value:String):void
    {
        if (m_valueField != value)
        {
            m_valueField = value;
            // set m_dataChanged to true to force refresh the selectedItem.
            m_dataChanged = true;
            invalidateProperties();
            dispatchEvent(new Event("valueFieldChanged"));
        }
    }

    //----------------------------------
    //  data
    //----------------------------------

    private var m_data:Object;
    private var m_dataChanged:Boolean = false;

    [Bindable("dataChange")]
    
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

            dispatchEvent(new FlexEvent(FlexEvent.DATA_CHANGE));
        }
    }
        
    //----------------------------------
    //  editable
    //----------------------------------
    
    [Bindable("enabledChanged")]
    [Inspectable(category="General", enumeration="true,false", defaultValue="true")]

    public function get editable():Boolean
    {
        return enabled;
    }

    public function set editable(value:Boolean):void
    {
        enabled = value;
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
    
    //--------------------------------------------------------------------------
    //
    //  Overridden Methods
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    override protected function commitProperties():void
    {
        super.commitProperties();
        if (m_dataChanged)
        {
            m_dataChanged = false;
            const list:IList = dataProvider;
            if (list)
            {
                for (var i:int = 0; i < list.length; i++)
                {
                    const item:Object = list.getItemAt(i);
                    if (item == m_data)
                    {
                        selectedIndex = i;
                        break;
                    }
                    if (item.hasOwnProperty(valueField) && item[valueField] === m_data)
                    {
                        selectedIndex = i;
                        break;
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  Public Functions: IFieldRenderer
    //
    //--------------------------------------------------------------------------
    
    public function formatToString(value:Object):String
    {
        if (!value)
        {
            return null;
        }

        if (value.hasOwnProperty(valueField))
        {
            return value[valueField];
        }
        
        return value.toString();
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     * Dispatch a PropertyChangeEvent if data has changed.
     */
    private function commitNewDataValue(newValue:Object):void
    {
        if (data != newValue)
        {
            var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "data", data, newValue, this);
            dispatchEvent(event);
            m_data = newValue;
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Event Handler
    //
    //--------------------------------------------------------------------------

    private function clickHandler(event:Event):void
    {
        var newValue:Object;
        if (selectedItem is String)
        {
            newValue = selectedItem;
        }
        else if (selectedItem)
        {
            newValue = selectedItem[valueField];
        }
        else
        {
            newValue = null;
        }
        commitNewDataValue(newValue);
    }

}
}

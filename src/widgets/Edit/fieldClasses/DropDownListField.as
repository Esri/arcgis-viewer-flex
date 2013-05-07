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

import mx.collections.IList;
import mx.core.IDataRenderer;
import mx.events.DropdownEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

import spark.components.DropDownList;

/**
 * @private
 * 
 * Drop down list component that could be used in in FieldInspector.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class DropDownListField extends DropDownList implements IFieldRenderer, IDataRenderer
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new DropDownListField.
     */
    public function DropDownListField()
    {
        // percentWidth = 100; CR 227,288
        minWidth = 128;
        requireSelection = true;
        addEventListener(DropdownEvent.CLOSE, closeHandler);
    }

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

    //----------------------------------
    //  valueField
    //----------------------------------

    private var m_valueField:String = "value";

    /**
     * The name of the value field.
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
            refreshSelectedItem();
        }
    }


    //----------------------------------
    //  data
    //----------------------------------

    private var m_data:Object;

    /**
     * Data associated with this drop down list field.
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
            refreshSelectedItem();
        }
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  Public Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function formatToString(value:Object):String
    {
        if (!value)
        {
            return null;
        }
        var result:String;
        const list:IList = dataProvider;
        if (list)
        {
            for (var i:int = 0; i < list.length; i++)
            {
                const item:Object = list.getItemAt(i);
                if (item == value)
                {
                    result = itemToLabel(item);
                    break;
                }
                if (item.hasOwnProperty(valueField) && item[valueField] === m_data)
                {
                    result = itemToLabel(item);
                    break;
                }
            }
        }
        return result;
    }

    //--------------------------------------------------------------------------
    //
    //  Private Methods
    //
    //--------------------------------------------------------------------------

    private function refreshSelectedItem():void
    {
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

    //--------------------------------------------------------------------------
    //
    //  Event Handlers
    //
    //--------------------------------------------------------------------------

    private function closeHandler(event:Event):void
    {
        var newData:Object = null;
        if (selectedItem is String)
        {
            newData = selectedItem;
        }
        else
        {
            newData = selectedItem[valueField];
        }
        if (m_data != newData)
        {
            var pce:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "data", m_data, newData, this);
            dispatchEvent(pce);
            m_data = newData;
        }
    }

}
}

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

import com.esri.ags.components.supportClasses.ICodedValueDomainField;
import com.esri.ags.layers.supportClasses.CodedValue;
import com.esri.ags.layers.supportClasses.CodedValueDomain;

import mx.collections.ArrayList;
import mx.collections.IList;
import mx.core.IDataRenderer;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

import spark.components.DropDownList;
import spark.components.supportClasses.TextBase;
import spark.events.DropDownEvent;

/**
 * @private
 * 
 * Drop down list component used in the AttributeInspector to handle coded value attribute values.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class CodedValueDomainField extends DropDownList implements ICodedValueDomainField, IDataRenderer
{


    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new CodedValueDomainField
     */
    public function CodedValueDomainField()
    {
        //percentWidth = 100; CR 227,288
        minWidth = 128;
        labelField = "name";
        addEventListener(DropDownEvent.CLOSE, closeHandler);
    }


    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var m_codedValueNotInDomain:CodedValue;


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
    //  domain
    //----------------------------------

    private var m_domain:CodedValueDomain;
    private var m_domainChanged:Boolean = false;

    /**
     * @inheritDoc
     */
    public function get domain():CodedValueDomain
    {
        return m_domain;
    }

    /**
     * @private
     */
    public function set domain(value:CodedValueDomain):void
    {
        if (m_domain !== value)
        {
            m_domain = value;
            m_domainChanged = true;
            invalidateProperties();
        }
    }

    //----------------------------------
    //  data
    //----------------------------------

    private var m_data:Object;
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
        // TODO return the value directly without setting the data property
        this.data = value;
        validateProperties();
        return (selectedItem as CodedValue).name;
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
        if (skin)
        {
            super.commitProperties();
        }
        if (m_domainChanged || m_dataChanged)
        {
            m_domainChanged = m_dataChanged = false;

            if (m_domain && m_domain.codedValues)
            {
                dataProvider = new ArrayList(m_domain.codedValues.concat());
            }
            else
            {
                dataProvider = null;
                return;
            }

            var codedValueIndex:int = -1;
            var codedValue:CodedValue;

            // Try to find the current data in the coded values of the domain
            for (var i:int = 0, n:int = dataProvider.length; i < n; i++)
            {
                codedValue = dataProvider.getItemAt(i) as CodedValue;
                if (codedValue.code == m_data)
                {
                    codedValueIndex = i;
                    break;
                }
            }

            // If the data isn't found, display the data with the lineThrough.
            if (!codedValueIndex == -1 && m_data)
            {
                const code:String = m_data.toString();
                m_codedValueNotInDomain = new CodedValue();
                m_codedValueNotInDomain.code = code;
                m_codedValueNotInDomain.name = code;
                dataProvider.addItemAt(m_codedValueNotInDomain, 0);
                if (!initialized)
                {
                    addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
                }
                else
                {
                    updateCodedValueNotInDomainRenderer();
                }
            }
            else if (codedValueIndex != -1)
            {
                selectedIndex = codedValueIndex;
            }
        }
    }


    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     * Dispatch a PropertyChangeEvent if data has changed.
     */
    private function commitDataChange(codedValue:CodedValue):void
    {
        var newDataValue:Object;
        if (codedValue && m_data != codedValue.code)
        {
            newDataValue = codedValue.code;
        }
        else if (m_data)
        {
            newDataValue = m_data;
        }
        if (m_data != newDataValue)
        {
            var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "data", m_data, newDataValue, this);
            dispatchEvent(event);
            m_data = newDataValue;
        }
    }

    private function updateCodedValueNotInDomainRenderer():void
    {
        const list:IList = dataProvider as IList;
        if (list && list.length && m_codedValueNotInDomain === list.getItemAt(0) && labelDisplay)
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
        updateCodedValueNotInDomainRenderer();
    }

    private function closeHandler(event:DropDownEvent):void
    {
        const codedValue:CodedValue = selectedItem as CodedValue;
        commitDataChange(codedValue);
        if (labelDisplay is TextBase)
        {
            (labelDisplay as TextBase).setStyle("lineThrough", selectedItem === m_codedValueNotInDomain);
        }
    }
}

}

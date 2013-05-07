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

import com.esri.ags.components.supportClasses.ILabelField;

import spark.components.Label;

/**
 * @private
 * 
 * Label component to render non editable attribute values.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class LabelField extends Label implements ILabelField
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new LabelField.
     */
    public function LabelField(value:Object = null)
    {
        data = value;
        width = 150;
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
    //  labelFunction
    //----------------------------------

    private var m_labelFunction:Function;
    
    /**
     * @inheritDoc
     */
    public function get labelFunction():Function
    {
        return m_labelFunction;
    }
    
    /**
     * @private
     */
    public function set labelFunction(value:Function):void
    {
        if (m_labelFunction != value)
        {
            m_labelFunction = value;
            text = formatToString(m_data);
        }
    }

    //----------------------------------
    //  data
    //----------------------------------

    private var m_data:Object = null;

    /**
     * Associated data in the form of a String.
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
            text = formatToString(m_data);
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
        if (m_labelFunction != null)
        {
            return m_labelFunction(m_data);
        }
        else if (m_data)
        {
            return m_data.toString();
        }
        else
        {
            return null;
        }
    }
}

}

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

import com.esri.ags.components.supportClasses.IDoubleField;

import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.MouseEvent;

import mx.core.FlexGlobals;
import mx.core.IDataRenderer;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;
import mx.events.ValidationResultEvent;

import spark.components.Application;
import spark.components.TextInput;
import spark.formatters.NumberFormatter;
import spark.validators.NumberValidator;

/**
 * @private
 *
 * Text input component used in the AttributeInspector to handle double precision attribute values.
 * This class includes a number validator that gets triggered when the user hits the enter key.
 * Upon successful validation, an update event is bubbled to the attribute inspector to apply as edits
 * on the associated feature layer.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class DoubleField extends TextInput implements IDoubleField, IDataRenderer
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new DoubleField.
     */
    public function DoubleField()
    {
        m_decimalSeparator = resourceManager.getString("validators", "decimalSeparator");

        restrict = "0-9\\-\\" + m_decimalSeparator;
        // Don't reference the SoftKeyboardType.NUMBER constant since SoftKeyboardType doesn't exist in web context
        softKeyboardType = "number";

        numberFormatter = new NumberFormatter();
        numberFormatter.useGrouping = false;
        numberFormatter.fractionalDigits = 16;
        numberFormatter.trailingZeros = false;
        numberFormatter.leadingZero = true;

        numberValidator = new NumberValidator();
        numberValidator.minValue = -Number.MAX_VALUE;
        numberValidator.maxValue = Number.MAX_VALUE;
        numberValidator.required = false; // CR 172,584
        numberValidator.source = this;
        numberValidator.property = "text";
        numberValidator.trigger = this;
        numberValidator.fractionalDigits = 16;
        numberValidator.triggerEvent = Event.CHANGE;
        numberValidator.addEventListener(ValidationResultEvent.INVALID, invalidHandler);
        numberValidator.addEventListener(ValidationResultEvent.VALID, validHandler);

        var app:Application = FlexGlobals.topLevelApplication as Application;
        if (app.stage)
        {
            maxWidth = maxHeight = Math.min(app.stage.stageWidth, app.stage.stageHeight);
        }

        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
        addEventListener(FlexEvent.ENTER, enterHandler);
    }


    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var m_decimalSeparator:String;

    private var m_listenerAdded:Boolean = false;

    /**
     * @private
     */
    protected var valid:Boolean = true;

    /**
     * @private
     */
    protected var numberValidator:NumberValidator;

    /**
     * @private
     */
    protected var numberFormatter:NumberFormatter;


    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  data
    //----------------------------------

    private var m_oldDataValue:Object;

    /**
     * The associated data in the form of a Number.
     */
    public function get data():Object
    {
        return text === "" ? null : numberFormatter.parse(text).value;
    }

    /**
     * @private
     */
    public function set data(value:Object):void
    {
        m_oldDataValue = value;
        text = value === null ? "" : formatToString(value);
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
    //  minValue
    //----------------------------------

    [Bindable("minValueChanged")]

    /**
     * The validator minimum value.
     * 
     * @default Number.MIN_VALUE
     *
     * @since ArcGIS API for Flex 2.1
     */
    public function get minValue():Number
    {
        return numberValidator.minValue as Number;
    }

    /**
     * @private
     */
    public function set minValue(value:Number):void
    {
        if (!numberValidator.minValue != value)
        {
            numberValidator.minValue = Math.max(value, -Number.MAX_VALUE);
            dispatchEvent(new Event("minValueChanged"));
        }
    }


    //----------------------------------
    //  maxValue
    //----------------------------------

    [Bindable("maxValueChanged")]

    /**
     * The validator maximum value.
     * 
     * @default Number.MAX_VALUE
     *
     * @since ArcGIS API for Flex 2.1
     */
    public function get maxValue():Number
    {
        return numberValidator.maxValue as Number;
    }

    /**
     * @private
     */
    public function set maxValue(value:Number):void
    {
        if (numberValidator.maxValue != value)
        {
            numberValidator.maxValue = Math.min(value, Number.MAX_VALUE);
            dispatchEvent(new Event("minValueChanged"));
        }
    }


    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    override protected function focusInHandler(event:FocusEvent):void
    {
        super.focusInHandler(event);
        if (!m_listenerAdded)
        {
            FlexGlobals.topLevelApplication.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true, 1, true);
            m_listenerAdded = true;
        }
    }

    /**
     * @private
     */
    override protected function focusOutHandler(event:FocusEvent):void
    {
        super.focusOutHandler(event);
        if (m_listenerAdded)
        {
            FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
            m_listenerAdded = false;
        }
        commitDataChange();
    }

    //--------------------------------------------------------------------------
    //
    //  Public Methods: IFieldRenderer
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     * 
     * Format number using the spark formatter and remove trailing zeros.
     */
    public function formatToString(value:Object):String
    {
        if (!value)
        {
            return null;
        }
        
        var formatted:String = numberFormatter.format(value);
		
        // Remove the trailing zeros
        if (formatted.lastIndexOf(m_decimalSeparator) != -1)
        {
            formatted = formatted.replace(/0*$/g, "");
        }
		else
		{
			formatted += m_decimalSeparator;
		}
		
        // Remove the decimal separator if it's the last char
        while (formatted.lastIndexOf(m_decimalSeparator) == -1 || formatted.lastIndexOf(m_decimalSeparator) >= formatted.length - 2)
        {
            formatted = formatted += 0;
        }
		
        return formatted;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    private function getTargetAsDoubleField(target:Object):DoubleField
    {
        const doubleField:DoubleField = target as DoubleField;
        if (doubleField)
        {
            return doubleField;
        }
        if (target.parent)
        {
            return getTargetAsDoubleField(target.parent);
        }
        return null;
    }

    /**
     * Dispatch a PropertyChangeEvent if data has changed.
     */
    private function commitDataChange():void
    {
        if (valid && m_oldDataValue != data)
        {
            var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "data", m_oldDataValue, data, this);
            dispatchEvent(event);
            m_oldDataValue = data;
        }
		text = formatToString(data);
    }

    //--------------------------------------------------------------------------
    //
    //  Event Handlers
    //
    //--------------------------------------------------------------------------

    private function enterHandler(event:FlexEvent):void
    {
        commitDataChange();
    }

    private function removedFromStageHandler(event:Event):void
    {
        FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
    }

    private function invalidHandler(event:ValidationResultEvent):void
    {
        valid = false;
        dispatchEvent(new ValidationResultEvent(event.type, true, false, event.field, event.results));
    }

    private function validHandler(event:ValidationResultEvent):void
    {
        valid = true;
        dispatchEvent(new ValidationResultEvent(event.type, true, false, event.field, event.results));
    }

    private function mouseDownHandler(event:MouseEvent):void
    {
        if (getTargetAsDoubleField(event.target) !== this && valid)
        {
            stage.focus = null; // removes the focus
            commitDataChange();
            FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
            m_listenerAdded = false;
        }
    }
}

}

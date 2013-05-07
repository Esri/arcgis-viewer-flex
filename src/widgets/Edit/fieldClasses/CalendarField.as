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

import com.esri.ags.components.supportClasses.IDateField;
import com.esri.ags.utils.ESRIMessageCodes;

import flash.events.Event;

import mx.controls.DateField;
import mx.core.mx_internal;
import mx.events.CalendarLayoutChangeEvent;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;
import mx.events.ValidationResultEvent;
import mx.formatters.DateFormatter;
import mx.validators.DateValidator;

/**
 * @private
 * 
 * A calendar component used in the AttributeInspector to handle date attribute values.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class CalendarField extends DateField implements IDateField
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Creates a new CalendarField.
     */
    public function CalendarField()
    {
        super();
        yearNavigationEnabled = true;
        editable = false;
        addEventListener(CalendarLayoutChangeEvent.CHANGE, changeHandler);
        addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);

        labelFunction = formatDate;
    }


    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var m_isDateValid:Boolean = true;
    private var m_dateValidator:DateValidator;
    private var m_dateFormatter:DateFormatter;


    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
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
    //  data
    //----------------------------------

    private var m_oldDataValue:Object;
    
    /**
     * @inheritDoc
     */
    override public function get data():Object
    {
        return selectedDate ? selectedDate.time : null;
    }

    /**
     * @private
     */
    override public function set data(value:Object):void
    {
        if (value is Number)
        {
            const date:Date = new Date();
            date.time = Number(value);
            selectedDate = date;
            m_oldDataValue = value;
        }
    }

    //----------------------------------
    //  dateFormat
    //----------------------------------

    private var m_dateFormat:String;
    private var m_dateFormatOverridden:Boolean = false;

    /**
     * Specify the date format in the text input.
     * 
     * @see mx.formatters.DateFormatter#formatString
     */
    public function get dateFormat():String
    {
        return m_dateFormat;
    }

    /**
     * @private
     */
    public function set dateFormat(value:String):void
    {
        if (m_dateFormat !== value)
        {
            m_dateFormat = value;
            if (m_dateFormatter)
            {
                m_dateFormatter.formatString = m_dateFormat;
            }
            if (m_dateValidator)
            {
                m_dateValidator.inputFormat = m_dateFormat;
            }
            m_dateFormatOverridden = true;
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     *
     *  measure() override to patch the bigDate value.
     *  in SDK : var bigDate:Date = new Date(2004, 12, 31); => Jan 31 2005
     */
    override protected function measure():void
    {
        // skip base class, we do our own calculation here
        // super.measure();

        var buttonWidth:Number = mx_internal::downArrowButton.getExplicitOrMeasuredWidth();
        var buttonHeight:Number = mx_internal::downArrowButton.getExplicitOrMeasuredHeight();

        var bigDate:Date = new Date(2004, 11, 31);
        var txt:String = formatDate(bigDate);

        measuredMinWidth = measuredWidth = measureText(txt).width + 8 + 2 + buttonWidth;
        measuredMinWidth = measuredWidth += getStyle("paddingLeft") + getStyle("paddingRight");
        measuredMinHeight = measuredHeight = textInput.getExplicitOrMeasuredHeight();
    }

    /**
     * @private
     */
    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
        if (mx_internal::downArrowButton)
        {
            mx_internal::downArrowButton.visible = enabled;
        }
        super.updateDisplayList(unscaledWidth, unscaledHeight);
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
        return formatDate(new Date(value as Number));
    }


    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    private function formatDate(value:Date):String
    {
        if (!m_dateFormatter)
        {
            if (!m_dateFormat && !m_dateFormatOverridden)
            {
                m_dateFormat = resourceManager.getString(ESRIMessageCodes.ESRI_MESSAGES, "popUpFormat_shortDate");
            }
            m_dateFormatter = new DateFormatter();
            m_dateFormatter.formatString = m_dateFormat;
        }
        return m_dateFormatter.format(value);
    }

    /**
     * Dispatch a PropertyChangeEvent if data has changed.
     */
    private function commitDataChange():void
    {
        if (m_oldDataValue != data)
        {
            var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, true, false, PropertyChangeEventKind.UPDATE, "data", m_oldDataValue, data, this);
            dispatchEvent(event);
            m_oldDataValue = data;
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

        if (!m_dateFormatOverridden)
        {
            m_dateFormat = resourceManager.getString(ESRIMessageCodes.ESRI_MESSAGES, "popUpFormat_shortDate");
        }

        m_dateValidator = new DateValidator();
        m_dateValidator.required = false;
        m_dateValidator.source = this;
        m_dateValidator.property = "text";
        m_dateValidator.trigger = this.textInput;
        m_dateValidator.triggerEvent = Event.CHANGE;
        m_dateValidator.inputFormat = m_dateFormat;
        m_dateValidator.addEventListener(ValidationResultEvent.VALID, dateValidator_validHandler);
        m_dateValidator.addEventListener(ValidationResultEvent.INVALID, dateValidator_invalidHandler);
    }

    private function dateValidator_invalidHandler(event:ValidationResultEvent):void
    {
        m_isDateValid = false;
    }

    private function dateValidator_validHandler(event:ValidationResultEvent):void
    {
        m_isDateValid = true;
    }

    private function changeHandler(event:CalendarLayoutChangeEvent):void
    {
        if (m_isDateValid)
        {
            // Update the Feature
            commitDataChange();
        }
    }
}

}

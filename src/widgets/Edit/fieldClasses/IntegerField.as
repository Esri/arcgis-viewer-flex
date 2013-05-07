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
import flash.events.FocusEvent;
import flash.events.MouseEvent;
import flash.globalization.NationalDigitsType;

import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;
import mx.events.ValidationResultEvent;
import mx.validators.NumberValidatorDomainType;

import spark.components.Application;
import spark.components.TextInput;
import spark.formatters.NumberFormatter;
import spark.validators.NumberValidator;

/**
 * @private
 *
 * Text input component used in the AttributeInspector to handle integer attribute values.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class IntegerField extends TextInput implements IFieldRenderer
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new IntegerField.
     */
    public function IntegerField()
    {
        restrict = "0-9\\-";
        // Don't reference the SoftKeyboardType.NUMBER constant since SoftKeyboardType doesn't exist in web context
        softKeyboardType = "number";
        
        numberValidator = new NumberValidator();
        numberValidator.required = false; // CR - 172,584
        numberValidator.domain = NumberValidatorDomainType.INT;
        numberValidator.minValue = int.MIN_VALUE;
        numberValidator.maxValue = int.MAX_VALUE;
        numberValidator.source = this;
        numberValidator.property = "text";
        numberValidator.trigger = this;
        numberValidator.triggerEvent = Event.CHANGE;
        numberValidator.addEventListener(ValidationResultEvent.INVALID, invalidHandler);
        numberValidator.addEventListener(ValidationResultEvent.VALID, validHandler);

        addEventListener(FlexEvent.ENTER, enterHandler);
        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);

        var app:Application = FlexGlobals.topLevelApplication as Application;
        if (app.stage)
        {
            maxWidth = maxHeight = Math.min(app.stage.stageWidth, app.stage.stageHeight);
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var m_listenerAdded:Boolean = false;

    protected var valid:Boolean = true;
    
    protected var numberValidator:NumberValidator;

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
     * The associated data in the form of a Number.
     */
    public function get data():Object
    {
        return text === "" ? null : parseInt(text);
    }

    /**
     * @private
     */
    public function set data(value:Object):void
    {
        m_oldDataValue = value;
        text = value === null ? "" : parseInt(value.toString()).toString();
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
     */
    public function formatToString(value:Object):String
    {
        // TODO return the name
        if (!value)
        {
            return null;
        }
        return parseInt(value.toString()).toString();
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    private function getTargetAsIntegerField(target:Object):IntegerField
    {
        const integerField:IntegerField = target as IntegerField;
        if (integerField)
        {
            return integerField;
        }
        if (target.parent)
        {
            return getTargetAsIntegerField(target.parent);
        }
        return null;
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

    private function enterHandler(event:FlexEvent):void
    {
        commitDataChange();
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

    private function removedFromStageHandler(event:Event):void
    {
        FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
    }

    private function mouseDownHandler(event:MouseEvent):void
    {
        if (getTargetAsIntegerField(event.target) !== this && valid)
        {
            stage.focus = null; // removes the focus
            commitDataChange();
            FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
            m_listenerAdded = false;
        }
    }
}

}

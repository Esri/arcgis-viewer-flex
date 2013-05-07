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

import mx.core.FlexGlobals;
import mx.core.IDataRenderer;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

import spark.components.Application;
import spark.components.TextInput;

/**
 * @private
 *
 * Text input component used in the AttributeInspector to handle short string attribute values.
 * For longer strings, the multi-line TextField component is used.
 * By default, "longer" is defined as strings fields with more than 40 characters, but you can change this threshold using the singleToMultilineThreshold property on the AttributeInspector.
 *
 * @since ArcGIS API for Flex 3.4
 *
 * @see TextField
 * @see com.esri.ags.components.AttributeInspector#singleToMultilineThreshold
 */
public class StringField extends TextInput implements IFieldRenderer
{
    //--------------------------------------------------------------------------
    //
    //  Contructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new StringField.
     */
    public function StringField(value:Object = null)
    {
        data = value;
        addEventListener(FlexEvent.ENTER, enterHandler);

        var app:Application = FlexGlobals.topLevelApplication as Application;
        if (app.stage)
        {
            maxWidth = maxHeight = Math.min(app.stage.stageWidth, app.stage.stageHeight);
        }

        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var m_listenerAdded:Boolean = false;
    

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
     * The associated data in the form of a String.
     */
    public function get data():Object
    {
        return text;
    }

    /**
     * @private
     */
    public function set data(value:Object):void
    {
        m_oldDataValue = value;
        text = formatToString(value);
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

    public function formatToString(value:Object):String
    {
        return value ? value.toString() : null;
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

    private function mouseDownHandler(event:MouseEvent):void
    {
        if (getTargetAsStringField(event.target) !== this)
        {
            stage.focus = null; // removes the focus
            commitDataChange();
            FlexGlobals.topLevelApplication.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
            m_listenerAdded = false;
        }
    }

    private function getTargetAsStringField(target:Object):StringField
    {
        const textField:StringField = target as StringField;
        if (textField)
        {
            return textField;
        }
        if (target.parent)
        {
            return getTargetAsStringField(target.parent);
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
}

}

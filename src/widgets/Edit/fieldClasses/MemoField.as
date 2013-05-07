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
import com.esri.ags.skins.supportClasses.MemoWindow;

import flash.events.Event;
import flash.events.MouseEvent;

import flashx.textLayout.conversion.ConversionType;
import flashx.textLayout.conversion.TextConverter;
import flashx.textLayout.elements.LinkElement;
import flashx.textLayout.elements.TextFlow;
import flashx.textLayout.events.FlowElementMouseEvent;

import mx.core.FlexGlobals;
import mx.events.CloseEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;
import mx.managers.PopUpManager;

import spark.components.Application;
import spark.components.Button;
import spark.components.HGroup;
import spark.components.RichEditableText;
import spark.components.RichText;
import spark.components.TextArea;
import spark.events.TextOperationEvent;


/**
 * @private
 * 
 * Text component used in the AttributeInspector to handle string attribute values displayed with HTML.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class MemoField extends HGroup implements IFieldRenderer
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     *
     */
    public function MemoField()
    {
        super();
        var app:Application = FlexGlobals.topLevelApplication as Application;
        if (app.stage)
        {
            maxWidth = maxHeight = Math.min(app.stage.stageWidth, app.stage.stageHeight);
        }
    }


    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    public var memoButton:Button;

    public var memoArea:TextArea;

    public var memoRichText:RichEditableText;

    private var m_memoWindow:MemoWindow;

    //----------------------------------
    //  data
    //----------------------------------

    private var m_data:String;

    public function get data():Object
    {
        return m_data;
    }

    public function set data(value:Object):void
    {
        if (m_data != value)
        {
            m_data = value as String;
            if (memoArea)
            {
                // /!\ Don't share the textflow between the TextArea and the richText
                memoArea.textFlow = TextConverter.importToFlow(m_data, TextConverter.TEXT_FIELD_HTML_FORMAT);
            }
            if (memoRichText)
            {
                memoRichText.textFlow = TextConverter.importToFlow(m_data, TextConverter.TEXT_FIELD_HTML_FORMAT);
            }
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
    //  maxChars
    //----------------------------------

    private var m_maxChars:int = 0;

    /**
     * @private
     */
    public function get maxChars():int
    {
        return m_maxChars;
    }

    /**
     * @private
     */
    public function set maxChars(value:int):void
    {
        if (m_maxChars !== value)
        {
            m_maxChars = value;
            if (memoArea)
            {
                memoArea.maxChars = value;
            }
        }
    }

    //----------------------------------
    //  memoWindowTitle
    //----------------------------------

    private var m_toolTip:String;

    /**
     * @private
     */
    override public function get toolTip():String
    {
        return m_toolTip;
    }

    /**
     * @private
     */
    override public function set toolTip(value:String):void
    {
        m_toolTip = value;
        if (memoArea)
        {
            memoArea.toolTip = m_toolTip;
        }
    }

    //----------------------------------
    //  editable
    //----------------------------------

    private var m_editable:Boolean = true;
    private var m_editableChanged:Boolean = true;

    [Bindable("editableChanged")]
    [Inspectable(category="General", enumeration="true,false", defaultValue="true")]

    /**
     * @inheritDoc
     */
    public function get editable():Boolean
    {
        return m_editable;
    }

    /**
     * @private
     */
    public function set editable(value:Boolean):void
    {
        if (m_editable != value)
        {
            m_editable = value;
            m_editableChanged = true;
            invalidateSize();
            invalidateDisplayList();
            if (hasEventListener("editableChanged"))
            {
                dispatchEvent(new Event("editableChanged"));
            }
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden Methods
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    override protected function createChildren():void
    {
        super.createChildren();

        if (!memoArea)
        {
            memoArea = new TextArea();
            memoArea.textFlow = TextConverter.importToFlow(m_data, TextConverter.TEXT_FIELD_HTML_FORMAT);
            memoArea.percentWidth = 100;
            memoArea.maxChars = m_maxChars;
            memoArea.minWidth = minWidth;
            memoArea.toolTip = toolTip;
            memoArea.includeInLayout = memoArea.visible = memoArea.editable = m_editable;
            memoArea.addEventListener(TextOperationEvent.CHANGE, memoAreaChangeHandler);
            addElement(memoArea);
        }

        if (!memoRichText)
        {
            memoRichText = new RichEditableText();
            memoRichText.editable = false;
            memoRichText.includeInLayout = memoRichText.visible = !m_editable;
            memoRichText.textFlow = TextConverter.importToFlow(m_data, TextConverter.TEXT_FIELD_HTML_FORMAT);
            addElement(memoRichText);
        }

        if (!memoButton)
        {
            memoButton = new Button();
            memoButton.label = resourceManager.getString("ESRIMessages", "memoButtonEdit") + "...";
            memoButton.includeInLayout = memoButton.visible = m_editable;
            memoButton.addEventListener(MouseEvent.CLICK, memoButtonClickHandler);
            addElement(memoButton);
        }
    }

    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);
        if (m_editableChanged)
        {
            m_editableChanged = false;
            if (memoArea)
            {
                memoArea.includeInLayout = memoArea.visible = memoArea.editable = m_editable;
            }
            if (memoRichText)
            {
                memoRichText.includeInLayout = memoRichText.visible = !m_editable;
                memoRichText.width = memoArea.getExplicitOrMeasuredWidth() + memoButton.getExplicitOrMeasuredWidth() + gap;
            }
            if (memoButton)
            {
                memoButton.includeInLayout = memoButton.visible = m_editable;
            }
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
        return value ? value.toString() : null;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     * Dispatch a PropertyChangeEvent if data has changed.
     */
    private function commitDataChange(newValue:String):void
    {
        if (m_data != newValue)
        {
            var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE,
                                                                    true,
                                                                    false,
                                                                    PropertyChangeEventKind.UPDATE,
                                                                    "data",
                                                                    m_data,
                                                                    newValue,
                                                                    this);
            m_data = newValue;
            dispatchEvent(event);
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Event Handlers
    //
    //--------------------------------------------------------------------------

    private function memoAreaChangeHandler(event:TextOperationEvent):void
    {
        var newValue:String = TextConverter.export(memoArea.textFlow,
                                                   TextConverter.TEXT_FIELD_HTML_FORMAT,
                                                   ConversionType.STRING_TYPE) as String;
        if (memoRichText)
        {
            var textFlow:TextFlow = TextConverter.importToFlow(newValue, TextConverter.TEXT_FIELD_HTML_FORMAT);
            if (textFlow)
            {
                textFlow.addEventListener(FlowElementMouseEvent.CLICK, textFlowLinkClickHandler, false, 0, true);
            }
            // /!\ Don't share the textflow between the TextArea and the richText
            memoRichText.textFlow = textFlow;
        }
        commitDataChange(newValue);
    }

    private function memoButtonClickHandler(event:MouseEvent):void
    {
        m_memoWindow = PopUpManager.createPopUp(FlexGlobals.topLevelApplication as Application, MemoWindow, true) as MemoWindow;
        m_memoWindow.title = fieldLabel;
        m_memoWindow.richTextEditor.htmlText = m_data;
        PopUpManager.centerPopUp(m_memoWindow);
        m_memoWindow.addEventListener(Event.COMPLETE, memoWindowCompleteHandler);
        m_memoWindow.addEventListener(CloseEvent.CLOSE, memoWindowcloseHandler);
    }

    private function memoWindowCompleteHandler(event:Event):void
    {
        var oldValue:String = m_data
        var newValue:String = m_memoWindow.richTextEditor.htmlText;
        var textFlow:TextFlow;
        textFlow = TextConverter.importToFlow(newValue, TextConverter.TEXT_FIELD_HTML_FORMAT);
        newValue = TextConverter.export(textFlow,
                                        TextConverter.TEXT_FIELD_HTML_FORMAT,
                                        ConversionType.STRING_TYPE) as String;
        commitDataChange(newValue);
        memoArea.textFlow = textFlow;
        if (memoRichText)
        {
            textFlow = TextConverter.importToFlow(newValue, TextConverter.TEXT_FIELD_HTML_FORMAT);
            if (textFlow)
            {
                textFlow.addEventListener(FlowElementMouseEvent.CLICK, textFlowLinkClickHandler, false, 0, true);
            }
            // /!\ Don't share the textflow between the TextArea and the richText
            memoRichText.textFlow = textFlow;
        }
        memoWindowcloseHandler(event);
    }

    private function textFlowLinkClickHandler(event:FlowElementMouseEvent):void
    {
        var linkElement:LinkElement = event.flowElement as LinkElement;
        if (linkElement && linkElement.target != "_blank")
        {
            linkElement.target = "_blank";
        }
    }

    private function memoWindowcloseHandler(event:Event):void
    {
        m_memoWindow.removeEventListener(Event.COMPLETE, memoWindowCompleteHandler);
        m_memoWindow.removeEventListener(CloseEvent.CLOSE, memoWindowcloseHandler);

        PopUpManager.removePopUp(m_memoWindow);
        m_memoWindow = null;
    }
}
}

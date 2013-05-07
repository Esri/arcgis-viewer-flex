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

import mx.utils.StringUtil;

/**
 * @private
 * 
 * Text input component used in the AttributeInspector to handle numbers attibute values contained into a range.
 *
 * @since ArcGIS API for Flex 3.4
 */
public class RangeDomainField extends DoubleField
{
    
    //--------------------------------------------------------------------------
    //
    //  Constructor.
    //
    //--------------------------------------------------------------------------
    
    /**
     * Creates a new RangeDomainField component.
     */
    public function RangeDomainField()
    {
        super();
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  minValue
    //----------------------------------
    
    /**
     * @private
     */
    override public function set minValue(value:Number):void
    {
        if (this.minValue != value)
        {
            super.minValue = value;
            updateValidationErrorString();
        }
    }
    
    //----------------------------------
    //  maxValue
    //----------------------------------
    
    /**
     * @private
     */
    override public function set maxValue(value:Number):void
    {
        if (this.maxValue != value)
        {
            super.maxValue = value;
            updateValidationErrorString();
        }
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    private function updateValidationErrorString():void
    {
        const validationError:String = StringUtil.substitute(resourceManager.getString("ESRIMessages", "attributeInspectorFieldRangeValidationError"), minValue, maxValue);
        numberValidator.lessThanMinError = numberValidator.greaterThanMaxError = validationError;
    }
    
}
}

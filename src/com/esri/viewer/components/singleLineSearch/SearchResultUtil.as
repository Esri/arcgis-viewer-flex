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
package com.esri.viewer.components.singleLineSearch
{

import com.esri.ags.tasks.supportClasses.AddressCandidate;
import com.esri.ags.tasks.supportClasses.FindResult;

import mx.utils.StringUtil;

public class SearchResultUtil
{
    public static function searchResultToLabel(searchResult:Object):String
    {
        if (searchResult is FindResult)
        {
            return findResultToLabel(searchResult as FindResult);
        }
        else if (searchResult is AddressCandidate)
        {
            return (searchResult as AddressCandidate).address as String;
        }
        else
        {
            return searchResult as String;
        }
    }

    private static function findResultToLabel(findResult:FindResult):String
    {
        return StringUtil.substitute('{0} - {1} - {2} ({3})',
                                     findResult.value,
                                     findResult.foundFieldName,
                                     findResult.layerName,
                                     findResult.layerId);
    }
}
}

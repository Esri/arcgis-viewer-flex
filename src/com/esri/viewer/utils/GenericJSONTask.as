///////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011 Esri. All Rights Reserved.
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
package com.esri.viewer.utils
{

import com.esri.ags.tasks.BaseTask;

import flash.net.URLVariables;

import mx.rpc.AsyncToken;
import mx.rpc.IResponder;

/**
 * Sends a HTTP request to the url with any additional query parameters specified in the urlVariables.
 * The response is expected to be JSON that is decoded and passed back to the responder's result handler.
 */
public class GenericJSONTask extends BaseTask
{
    public function execute(urlVariables:URLVariables, responder:IResponder):AsyncToken
    {
        return sendURLVariables("", urlVariables, responder, handleDecodedObject);
    }

    private function handleDecodedObject(decodedObject:Object, asyncToken:AsyncToken):void
    {
        for each (var responder:IResponder in asyncToken.responders)
        {
            responder.result(decodedObject);
        }
    }
}

}

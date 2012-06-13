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

/**
 * Utility class for mapping error codes with application error messages.
 */
public class ErrorMessageUtil
{
    public static function getKnownErrorCauseMessage(faultCode:String):String
    {
        var message:String;

        switch (faultCode)
        {
            case "Channel.Security.Error":
            {
                message = "GIS Server is missing a crossdomain file.";
                break;
            }
            case "Server.Error.Request":
            case "400":
            case "404":
            {
                message = "Service does not exist or is inaccessible.";
                break;
            }
            case "499":
            {
                message = "You don't have permissions to access this service.";
                break;
            }
            default:
            {
                message = "Unknown error cause.";
            }
        }

        return message;
    }

    public static function makeHTMLSafe(content:String):String
    {
        content = content.replace(/>/g, "&gt;");
        content = content.replace(/</g, "&lt;");
        return content;
    }
}

}

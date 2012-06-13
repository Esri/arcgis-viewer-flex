==========================
ArcGIS Viewer for Flex 3.0
build date 2012-06-06
==========================

This file contains the complete source code for the ArcGIS Viewer for Flex 3.0.

============================
Getting Started - Developers
============================

See http://links.esri.com/flexviewer-gettingstarted-developers

1. In Adobe Flash Builder 4.6, go to "File" -> "Import Flash Builder project..."

2. Keeping "File" option selected, click "Browse..." button.

3. Select flexviewer-3.0-src.zip downloaded in step 1, e.g. "C:\Documents and Settings\jack\My Documents\flexviewer-3.0-src.zip".

4. "Extract new project to:" textbox will be automatically set to location where the project source will reside,
    e.g. "C:\Documents and Settings\jack\Adobe Flash Builder 4.6\FlexViewer.
    Do not put it onto your web server - you should separate your code location from your output.

5. Click "Finish" button. Project will be created and displayed in the Package Explorer window of Flash Builder 4.6, e.g. in this case FlexViewer.

6. If prompted to upgrade the project (because it was created with a previous version of Flash Builder), click "OK"

7. If prompted to choose Flex SDK version, select "Flex 4.6.0"

8. If needed, download API Library from http://links.esri.com/flex-api/latest-download.
   Go to "Project" -> "Properties" -> "Flex Build Path". 
   Click "Add SWC" and navigate to the agslib-3.0-2012-06-06.swc file.
      

Optionally:

1. Right click on this project (FlexViewer) -> Click "Properties" -> Click "Flex Build Path".

2. In the "Output folder" textbox at bottom, specify the location of your web server where your
    Flex Viewer should be deployed, e.g. in case of IIS web server, C:\Inetpub\wwwroot\flexviewerdebug.

3. In "Output folder URL" text box , specify the URL that matches with your output folder specified
    in last step, e.g. http://localhost/flexviewerdebug/

4. Click OK

5. Rebuild the project.

6. Select the project. Now let's run it - there are multiple ways of doing this.
    One way is to click green triangle button on top.
    Another way is click Ctrl-F11.
    A third way is to click "Run" menu, then select "Run Index".

7. Browser will open and Flex Viewer application will be displayed.


================
More Information
================

Flex Viewer: http://resources.arcgis.com/en/communities/flex-viewer/
Flex API http://resources.arcgis.com/en/communities/flex-api/

Flex Viewer License agreement at http://www.apache.org/licenses/LICENSE-2.0.html
Flex API License agreement at http://www.esri.com/legal/pdfs/mla_e204_e300/english.pdf


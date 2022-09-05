# Sepia Configuration
A guide to the Sepia configuration file

## Introduction

Mobile applications written to interact with the Ayla service and devices all have very similar requirements: User account management, device management, scheduling, notifications, and most importantly device control by the user. The Sepia platform provides not only the infrastructure needed to manage these requirements, but also a set of user interface screens and controls that can be used or customized to build a working application with very little effort.

The Sepia platform allows developers to define the overall structure of their application in a configuration file that is shared between iOS and Android. The Sepia platform uses the configuration file to build the application, configure app navigation, build menus and render screens appropriate to the application.

Because both iOS and Android use the same configuration file, both applications can be modified in the same way by changing a single configuration file. This allows for rapid prototyping of the user interface as well as the easy addition or removal of application features.

This document describes the Sepia configuration file and provides examples of how it might be used to configure different types of applications.

## Config File Format

The Sepia configuration file is a JSON document containing information about the application configuration. The top-level of the document contains the following fields:

<style>
table {
    font-family: monospace;
    border-collapse: collapse;
    width: 100%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #eeeeee;
}
</style>

<table>
  <tr>
    <td>version</td>
    <td>Version of the configuration. This may be used by the application to ensure the version of the configuration matches an expected version, but is unused internally by the Sepia platform</td>
  </tr>
  <tr>
    <td>name</td>
    <td>Name for the configuration. Also not used internally by the Sepia platform, this field provides a way for the application to identify the configuration it was built with.</td>
  </tr>
  <tr>
    <td>applicationIdentifier</td>
    <td>Identifier used for the application. On Android, this is used as the application ID; on iOS, this is the bundle identifier.</td>
  </tr>
  <tr>
    <td>packages</td>
    <td>(Android-specific) array of package names used by classes within the configuration. These packages are pre-pended to class names to find them within the application.</td>
  </tr>
  <tr>
    <td>devices</td>
    <td>Array of Device objects with details about the types of devices the application supports, detailed later in this document</td>
  </tr>
  <tr>
    <td>sdkConfig</td>
    <td>Configuration parameters used to initialize the Ayla Mobile SDK. Details can be found later in this document.</td>
  </tr>
  <tr>
    <td>userExperience</td>
    <td>Configuration parameters used to construct the user interface for the application. This includes screen definitions, controls, colors, menus, etc. More details can be found later in this document.</td>
  </tr>
</table>

### Devices

The devices array is used to provide the platform with information about the specific devices that are to be supported by the application. Each device object in the array contains the following fields:

<table>
  <tr>
    <td>class</td>
    <td>Name of the class that should be instantiated within Ayla Device Manager. This class must exist in the project, and must derive from AylaDevice (Android) or ALDevice (iOS). This allows user-defined device objects to be created and managed by Ayla Device Manager</td>
  </tr>
  <tr>
    <td>ssidRegex</td>
    <td>Regular expression used to filter SSIDs when scanning for WiFi access points. This value should be set to a regular expression that will pass through SSIDs matching the expected format for the device access point.</td>
  </tr>
  <tr>
    <td>detailScreen</td>
    <td>Name of the screen to be presented if the user wishes to view details about this device</td>
  </tr>
  <tr>
    <td>managedProperties</td>
    <td>Array of property details for this device, described in more detail below</td>
  </tr>
  <tr>
    <td>model</td>
    <td>The model (string) of the device, used to identify devices of this type</td>
  </tr>
  <tr>
    <td>oemModel</td>
    <td>The OEM model (string) of the device, used to identify devices of this type</td>
  </tr>
  <tr>
    <td>scheduleScreen</td>
    <td>Screen shown for this device when the user wishes to set a schedule on the device</td>
  </tr>
</table>


#### Managed Properties

Each device should provide a set of Property details that describe the various properties of the device that should be managed by the Ayla SDK, as well as additional hints to the Sepia platform that allow it to display an intelligent user interface to manipulate or display the property.

<table>
  <tr>
    <td>control</td>
    <td>Optionally references the control object that should be used to allow display or
    interaction with this property. For example, the current temperature property for a
    thermostat may reference a "thermometer" control that graphically displays the property
    value as a reading on a thermometer.</td>
  </tr>
  <tr>
    <td>name</td>
    <td>Name of the property</td>
  </tr>
  <tr>
    <td>notify</td>
    <td>True if the property can be used for notifications, false otherwise</td>
  </tr>
  <tr>
    <td>schedule</td>
    <td>True if the property can be scheduled, false otherwise</td>
  </tr>
  <tr>
  <td>actions</td>
  <td>Array of Actions supported by this property. Actions are mappings of string references 
  (names presented to the user) and property values. For example, a switch might map the string 
  "Turn On" to the value 1, and the string "Turn Off" to the value 0 as actions on the property 
  that controls the on / off state of the switch.
</table>

    {
          "name": "on_off",			// Property name
          "notify": false,			// Do not enable notifications
          "schedule": true			// Enable schedules
          "actions": [
            {
              "name": "turn_off",
              "value": 0
            },
            {
              "name": "turn_on",
              "value": 1
            }
            ...
    

### sdkConfig

The sdkConfig field contains information required by the Ayla Mobile SDK to be initialized:

<table>
  <tr>
    <td>appId</td>
    <td>Application ID, provided by Ayla Networks</td>
  </tr>
  <tr>
    <td>appSecret</td>
    <td>Application secret, provided by Ayla Networks</td>
  </tr>
  <tr>
    <td>allowMobileDSS</td>
    <td>True to allow mobile DSS, false otherwise</td>
  </tr>
  <tr>
    <td>allowOfflineUse</td>
    <td>True to allow the user to sign in without an Internet connection, false otherwise</td>
  </tr>
  <tr>
    <td>serviceType</td>
    <td>Dynamic | Field | Development | Staging | Demo</td>
  </tr>
  <tr>
    <td>serviceLocation</td>
    <td>USA | China | Europe</td>
  </tr>
  <tr>
    <td>consoleLogLevel</td>
    <td>Verbose | Debug | Info | Warning | Error | None</td>
  </tr>
  <tr>
    <td>fileLogLevel</td>
    <td>Verbose | Debug | Info | Warning | Error | None</td>
  </tr>
  <tr>
    <td>xPlatformId</td>
    <td>Unique string shared between applications to share data. Used as a prefix for datum keys by the platform.</td>
  </tr>
  <tr>
    <td>defaultNetworkTimeoutMs</td>
    <td>Default timeout for network operations. Defaults to 5000 ms.</td>
  </tr>
</table>


### User Experience

The userExperience field contains the information needed to structure the application’s flow, menu, navigation, etc.

#### Screens

Sepia uses a concept of a "Screen" to represent a view within the application. On iOS, these are akin to “View Controllers”; on Android these are akin to “Fragments”. 

Each screen defined within the Sepia configuration file has a name, which may be used as a reference to that screen elsewhere in the configuration file as well as within application code. The Screen objects contain the following elements:

<table>
  <tr>
    <td>class</td>
    <td>Name of the screen class to be instantiated in code. This class must derive from the SepiaScreen base class. On iOS, SepiaScreen is a subclass of UIViewController. On Android, SepiaScreen is a subclass of Fragment.</td>
  </tr>
  <tr>
    <td>name</td>
    <td>Name of the screen. This is used within the configuration file to refer to a screen (e.g. "homeScreeen": “my_screen_name”) as well as within application code.</td>
  </tr>
  <tr>
    <td>title</td>
    <td>String identifier for the title this screen should present. The identifier is mapped to an entry in the string table on each platform, e.g. NSLocalizedString on iOS and the R.string enumeration on Android. This title is also used to represent a screen when shown in a menu or other navigation utility.</td>
  </tr>
  <tr>
    <td>icon</td>
    <td>Icon identifier for the screen. If the screen is referenced in a menu or other location within the application, an icon may be displayed next to the screen’s title.</td>
  </tr>
  <tr>
    <td>extras</td>
    <td>Dictionary of name / value pairs passed to the screen. This field can be used to pass additional information to the screen from the configuration if desired.</td>
  </tr>
</table>




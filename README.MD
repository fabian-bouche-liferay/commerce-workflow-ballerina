# Commerce workflow with ballerina client extension

This project simulates a situation where Liferay is integrated with a third party commerce order
management system which has to receive Commerce Orders when they are submitted by customers.

It will simulate successful and failed transmissions with manual retransmission by commerce admins.

The solution is built using Liferay Workflows and relies on a workflow action client extension
to make the transmission.

## Pre-requisites

This client extension uses ballerina.
Please setup ballerina (download from https://ballerina.io).
And adjust the client extension's build.gradle to your environment

```
build.doFirst {
    println("Building Ballerina")
    if (System.getProperty('os.name').toLowerCase(Locale.ROOT).contains('windows')) {
        exec { 
        	commandLine 'C:\\Program Files\\Ballerina\\bin\\bal.bat', 'build'
        }
    } else {
        exec { 
        	commandLine 'bal', 'build'
        }
    }
}
```

## Create a Commerce Admin Role

Create a role with the key `Commerce admin` and assign a user.
This role will receive workflow assignments to resubmit commerce orders which have not been successfully transmitted
to a simulated external system.

## The workflow

Here's a workflow definition:
https://github.com/fabian-bouche-liferay/commerce-workflow-ballerina/blob/master/workflows/sample-commerce-buyer-process.xml

In your Liferay Commerce Channel configuration, you have to assign it to "Seller Order Acceptance Workflow".

## The workflow client extension action

The workflow calls `function#liferay-ballerina-commerce-transmission-workflow-action` when the commerce order is submitted.
The call is handled by https://github.com/fabian-bouche-liferay/commerce-workflow-ballerina/blob/master/client-extensions/commerce-transmission-action/main.bal

The workflow action will be successful 3 times out of 4 and will simulate failure 1 time out of 4.

Success or failure will trigger a different transition in the workflow.
In case the transition is a failure, the commerce admin will receive a notification and will be able to attempt a
retransmission of the commerce order.
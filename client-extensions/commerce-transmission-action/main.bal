import ballerina/http;
import ballerina/log;
import ballerina/random;

type CommerceOrder record {
    int id;
    decimal total;
    CommerceOrderItem[] orderItems;
};

type CommerceOrderItem record {
    string sku;
    int quantity;
    decimal unitPrice;
};

type WorkflowInstance record {
    string transitionURL;
    string workflowTaskId;
    CommerceOrder entryDTO;
};

type TaskTransition record {
    string comment;
    string transitionName;
    int workflowTaskId;
};

type TaskTransitionResponse record {
    boolean completed;
};

http:Client liferayAPI = check new ("http://localhost:8080");
service / on new http:Listener(9090) {
    resource function post commerceorder/transmit(http:Request request) returns error? {
        json payload = check request.getJsonPayload();
        log:printInfo("Received " + payload.toJsonString());
        WorkflowInstance workflowInstance = check payload.cloneWithType();
        string authorization = check request.getHeader("Authorization");

        string transmissionStatus = transmit(workflowInstance.entryDTO);
        
        TaskTransition taskTransition = {
            comment: string `Transmission result ${transmissionStatus}`,
            transitionName: transmissionStatus,
            workflowTaskId: check int:fromString(workflowInstance.workflowTaskId)
        };

        future<()> futureResult = start updateWorkflowTask(workflowInstance, taskTransition,authorization );
    }

};

function updateWorkflowTask(WorkflowInstance workflowInstance, TaskTransition taskTransition, string authorization) {
    map<string|string[]> headers = { "Authorization": authorization};
    log:printInfo(string `Making a request to Liferay workflow api with ${headers.toJsonString()} and path ${workflowInstance.transitionURL} with message ${taskTransition.toJsonString()}`);

    do {
        http:Response post = check liferayAPI->post(headers = headers, path = workflowInstance.transitionURL, message = taskTransition);
        TaskTransitionResponse taskTransitionResponse = check (check post.getJsonPayload()).cloneWithType();
        log:printInfo(string `Workflow update status ${taskTransitionResponse.completed}`);
    } on fail var e {
        log:printError(string `Failed to update Workflow ${e.message()}`);
    }
} 

function transmit(CommerceOrder commerceOrder) returns string {
    do {
        int randomInt = check random:createIntInRange(0, 100);
        if(randomInt < 75) {
            log:printInfo(string `Adding a new commerce order with ID ${commerceOrder.id} and total price ${commerceOrder.total}`);
            return "transmission_success";            
        }
    } on fail var e {
        log:printError(string `Failed to generate random int ${e.message()}`);
    }
    log:printError(string `Failed to add a new commerce order with ID ${commerceOrder.id} and total price ${commerceOrder.total}`);
    return "transmission_failure";            
}

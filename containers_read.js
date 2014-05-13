var azure = require('azure');
 
function read(query, user, request) {
    
    var accountName = 'ACCOUNT NAME';
    var accountKey = 'ACCOUNT KEY';
    var host = accountName + '.blob.core.windows.net';
    var blobService = azure.createBlobService(accountName, accountKey, host);
    
    blobService.listContainers(function (error, containers) {
        if (error) {
            request.respond(500, error);
        } else {
            request.respond(200, containers);
        }
    });
}
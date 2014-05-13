var azure = require('azure');
 
function del(id, user, request) {
    
    var accountName = 'ACCOUNT NAME';
    var accountKey = 'ACCOUNT KEY';
    var host = accountName + '.blob.core.windows.net';
    var blobService = azure.createBlobService(accountName, accountKey, host);
    
    blobService.deleteContainer(request.parameters.containerName, function (error) {
        if (!error) {
            request.respond(200);
        } else {
            request.respond(500);
        }
    });
}
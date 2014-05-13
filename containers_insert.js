var azure = require('azure');
 
function insert(item, user, request) {
    
    var accountName = 'ACCOUNT NAME';
    var accountKey = 'ACCOUNT KEY';
    var host = accountName + '.blob.core.windows.net';
    var blobService = azure.createBlobService(accountName, accountKey, host);
    
    if (request.parameters.isPublic == 1) {
        blobService.createContainerIfNotExists(item.containerName
            ,{publicAccessLevel : 'blob'}
            , function (error) {
                if (!error) {
                    request.respond(200, item);
                } else {
                    console.log(error);
                    request.respond(500);
                }
            });
    } else {    
        blobService.createContainerIfNotExists(item.containerName, function (error) {
            if (!error) {
                request.respond(200, item);
            } else {
                console.log(error);
                request.respond(500);
            }
        });
    }
}
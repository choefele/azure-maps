var azure = require('azure');
var qs = require('querystring');
 
function insert(item, user, request) {
   
    var accountName = 'ACCOUNT NAME';
    var accountKey = 'ACCOUNT KEY';
    var host = accountName + '.blob.core.windows.net';
    var blobService = azure.createBlobService(accountName, accountKey, host);
    
    var sharedAccessPolicy = { 
        AccessPolicy: {
            Permissions: 'rw', //Read and Write permissions
            Expiry: minutesFromNow(5) 
        }
    };
    
    var sasUrl = blobService.generateSharedAccessSignature(request.parameters.containerName,
                    request.parameters.blobName, sharedAccessPolicy);
 
    var sasQueryString = { 'sasUrl' : sasUrl.baseUrl + sasUrl.path + '?' + qs.stringify(sasUrl.queryString) };                    
 
    request.respond(200, sasQueryString);
}
 
function minutesFromNow(minutes) {
    var date = new Date()
  date.setMinutes(date.getMinutes() + minutes);
  return date;
}
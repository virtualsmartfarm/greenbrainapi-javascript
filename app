var timeStamp = new Date().toISOString();
let api = 'https://api.greenbrain.net.au/v3';
let request = require('request');
let containerName = 'mea'
let storageKey = process.env.STORAGE_KEY;
let storageName = process.env.STORAGE_NAME;
//   let greenbrainUsername = process.env.GREENBRAIN_USERNAME;
//   let greenbrainPassword = process.env.GREENBRAIN_PASSWORD;
let storageURL = 'https://avrclimate.blob.core.windows.net';

const {Aborter, BlobURL, BlockBlobURL, ContainerURL, ServiceURL, StorageURL, SharedKeyCredential, AnonymousCredential, TokenCredential} = require("@azure/storage-blob");
if (myTimer.IsPastDue) {
    context.log('JavaScript is running late!');
}

context.log('JavaScript timer trigger function ran!', timeStamp); 
//    context.log(`stroageKey ${storageKey}`);
//    context.log(`password '${greenbrainPassword}'`);
//    context.log(req.query.JSON.stringify);
context.log(`API=${api}, timestamp=${timeStamp}`);
let options = {
    url: `${api}/auth/login`,
    headers: {
        'Content-type': 'application/json'
    },
    body: JSON.stringify({ email: process.env.GREENBRAIN_USERNAME, password: process.env.GREENBRAIN_PASSWORD })
}

let authPromise = new Promise((resolve, reject) => {
    request.post(options, function(error, response, body) {

        if (error) {
            context.log('Error');
            reject(error);
            return;
        }

        resolve(JSON.parse(response.body).token);

    });


});

let token = await authPromise;

context.log(`Token: ${token}`);

options = {
    url: `${api}/bootstrap`,
    headers: {
        "Authorization": `Bearer ${token}`
    }
}

let boostrapPromise = new Promise((resolve, reject) => {
  request.get(options, function(error, response, body) {

        if (error) {
            context.log('Error');
            reject(error);
            return;
        }

 //       context.log(JSON.stringify(response));    

        resolve(response);

    });

});

let result = await boostrapPromise;

let d = new Date();
let obsTime = `${d.getFullYear()}-${('0' + (d.getMonth()+1)).slice(-2)}-${('0' + d.getDate()).slice(-2)}`;

options = {

    url: `${api}/sensor-groups/6845/readings?date=${obsTime}`,
    headers: {
        "Authorization": `Bearer ${token}`
    }
}

let readingPromise = new Promise((resolve, reject) => {
  request.get(options, function(error, response, body) {

        context.log(JSON.stringify(body));    

        resolve(body);

    });
});

let reading = await readingPromise;

const sharedKeyCredential = new SharedKeyCredential(storageName, storageKey);
const pipeline = StorageURL.newPipeline(sharedKeyCredential);
const serviceURL = new ServiceURL(storageURL, pipeline);
const containerURL = ContainerURL.fromServiceURL(serviceURL, containerName);

const readingLength = reading.length;

const blobName = `${new Date().getTime()}-mea-sensor-6845.json`;
const blobURL = BlobURL.fromContainerURL(containerURL, blobName);
const blockBlobURL = BlockBlobURL.fromBlobURL(blobURL);

const uploadBlobResponse = await blockBlobURL.upload(
    Aborter.none,
    reading,
    reading.length
);

context.log(`Upload - ${blobName} successfully`);

context.log(`Completed - ${timeStamp} - [${obsTime}] - ${reading.length}`);


const WebSocket = require('ws');

const ws = new WebSocket('wss://wsprc.royalassetindo.co.id');

ws.on('open', () => {
    console.log('WEBSOCKET CONNECTED');
});

ws.on('message', (data) => {
    console.log('DATA DITERIMA:');
    console.log(data.toString());
});

ws.on('error', (error) => {
    console.log('WEBSOCKET ERROR:', error.message);
});

ws.on('close', (code, reason) => {
    console.log('WEBSOCKET CLOSED:', code, reason.toString());
});

setTimeout(() => {
    ws.close();
    process.exit(0);
}, 15000);

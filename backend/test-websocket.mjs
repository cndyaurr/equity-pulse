import WebSocket from 'ws';

const ws = new WebSocket('wss://wsprc.royalassetindo.co.id');

ws.on('open', () => {
    console.log('WEBSOCKET CONNECTED');
    console.log('Menunggu data selama 60 detik...');
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
    clearTimeout(timer);
});

const timer = setTimeout(() => {
    console.log('Pengujian selesai, menutup koneksi...');
    ws.close(1000, 'Test selesai');
}, 60000);

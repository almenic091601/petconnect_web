const express = require('express');
const cors = require('cors');
const fs = require('fs');

const app = express();

// Load CORS options from cors.json
const corsOptions = JSON.parse(fs.readFileSync('cors.json', 'utf8'));
app.use(cors(corsOptions));

app.get('/', (req, res) => {
  res.send('CORS-enabled server is running!');
});

app.listen(3001, () => {
  console.log('Server running on http://localhost:3001');
});

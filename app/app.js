const http = require("node:http");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8"
  });

  res.end(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Powernet IT Service Dashboard</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 50px auto;
          padding: 20px;
          background: #f4f7fb;
          color: #20304a;
        }
        .card {
          background: white;
          padding: 24px;
          border-radius: 12px;
          box-shadow: 0 2px 8px #00000012;
        }
        .status { color: #16794b; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Powernet IT Service Dashboard</h1>
        <p>DevOps deployment demonstration application</p>
        <p class="status">Application Status: Running</p>
        <p>Service: IT and Network Support</p>
        <p>Environment: ${process.env.APP_ENV || "Development"}</p>
      </div>
    </body>
    </html>
  `);
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Powernet dashboard running on port ${PORT}`);
});

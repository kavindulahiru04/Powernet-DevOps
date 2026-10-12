const http = require("node:http");
const assert = require("node:assert/strict");

const req = http.get("http://localhost:3000", (res) => {
  let body = "";

  res.setEncoding("utf8");
  res.on("data", (chunk) => body += chunk);

  res.on("end", () => {
    try {
      assert.equal(res.statusCode, 200);
      assert.ok(body.includes("Powernet IT Service Dashboard"));
      assert.ok(body.includes("Application Status: Running"));

      console.log("PASS: HTTP status is 200");
      console.log("PASS: Dashboard title is present");
      console.log("PASS: Application status is present");
      console.log("ALL TESTS PASSED");

      process.exitCode = 0;
    } catch (error) {
      console.error("TEST FAILED:", error.message);
      process.exitCode = 1;
    }
  });
});

req.on("error", (error) => {
  console.error("Could not reach application:", error.message);
  process.exitCode = 1;
});

req.setTimeout(5000, () => {
  console.error("TEST FAILED: Request timed out");
  req.destroy();
  process.exitCode = 1;
});

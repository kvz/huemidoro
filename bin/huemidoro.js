#!/usr/bin/env node
// No coffee needed as this sources ./lib, not ./src:
// var coffee  = require("coffee-script/register");
require("source-map-support").install();
var Huemidoro = require("../");

var config   = {};
// var required = [ "username", "password", "account_id", "project_id" ];
// for (var i in required) {
//   var cfgKey = required[i];
//   var envKey = "HUEMIDORO_" + cfgKey.toUpperCase();

//   if (!(envKey in process.env)) {
//     console.error("Please first set the following environment key: " + envKey);
//     if (cfgKey == "project_id") {
//       console.error("Warning, first use a new/empty project before trying this on the real thing!");
//     }
//     process.exit(1);
//   }
//   config[cfgKey] = process.env[envKey];
// }

var huemidoro = new Huemidoro(config);
var action  = process.argv[2];
var file    = process.argv[3];

if (!(action in huemidoro)) {
  action = "help";
}

huemidoro[action](file, function(err, stdout, stderr) {
  if (err) {
    throw err;
  }

  if (stderr) {
    console.error(stderr);
  }
  if (stdout) {
    console.log(stdout);
  }
});

"use strict";

module.exports = {
  public: true,
  host: "0.0.0.0",
  port: 9000,
  reverseProxy: false,
  maxHistory: 10000,
  https: {
    enable: false,
  },
  theme: "default",
  defaults: {
    name: "Wetfish Local",
    host: "hub",
    port: 6667,
    password: "",
    tls: false,
    rejectUnauthorized: false,
    nick: "user",
    username: "user",
    realname: "The Lounge User",
    join: "#wetfish",
  },
};

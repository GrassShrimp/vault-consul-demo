const {vault: config} = require('../config')
const fs = require('fs')

let content = fs.readFileSync("/vault/secrets/database-config.txt", "utf-8")

class Vault {
  constructor(content){
    this.content = content
  }

  async get_secret(ctx, next) {
    ctx.body = this.content
  }
}

module.exports = new Vault(content)
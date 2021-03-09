const {vault: config} = require('../config')
const fs = require('fs')

var options = {
  apiVersion: 'v1',
  endpoint: config.addr,
  token: fs.readFileSync(config.jwt_path, "utf-8")
}

const vaultLib = require("node-vault")(options);

class Vault {
  constructor(vault_lib){
    this.vault_lib = vault_lib
  }

  async get_secret(ctx, next) {
    ctx.body = await this.vault_lib.read('secret/webapp/config')
  }
}

module.exports = new Vault(vaultLib)
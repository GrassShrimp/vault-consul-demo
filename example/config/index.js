module.exports = {
  port: 3000,
  vault: {
    addr: process.env.VAULT_ADDR,
    jwt_path: process.env.JWT_PATH,
  }
}

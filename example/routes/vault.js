const controller = require('../controller/vault')
const router = new require('koa-router')()

const routers = router.get('koa-secret', controller.get_secret.bind(controller))

module.exports = routers
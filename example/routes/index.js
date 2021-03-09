const router = require('koa-router')()
const vault = require('./vault')

router.use('/', vault.routes(), vault.allowedMethods())
router.get('/', async (ctx, next) => {
  // ctx.body = 'Hello World'
  ctx.state = {
    title: 'Koa2'
  }
  await ctx.render('index', ctx.state)
})

module.exports = router

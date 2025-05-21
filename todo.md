add a webhook handler for github to restart on push to main for CI/CD


----------------------
✅ DONE: Enhanced auth caching system
- Implemented efficient LRU caching for auth data
- Added thread safety and eviction events
- Created proper resource management
- Improved performance with queue-based approach
----------------------


create an auth router like the crud one , and make it customizable to allow or disallow different functions like the login/register, etc...

create a dispacher router, or Dispatcher, that takes a list of routers and runs them at order, and it can be passed to the server directly


how to add cron jobs in dart

create AuthMiddlewares with multiple middlewares like the .loggedin, etc..., and the authMiddleware is an object which will take a flux authenticator object

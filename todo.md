

create an auth router like the crud one , and make it customizable to allow or disallow different functions like the login/register, etc...

create a dispacher router, or Dispatcher, that takes a list of routers and runs them at order, and it can be passed to the server directly


how to add cron jobs in dart

create AuthMiddlewares with multiple middlewares like the .loggedin, etc..., and the authMiddleware is an object which will take a flux authenticator object

make a storage micro service for upload/downloading files, should be integrated with storage buckets

test cors protection
test webhooks on different systems
add hmac algorithm for protecting APIs to a specific secret




---------
add a dashboard with turn on and off from the app class
and settable endpoint , dashboard runs on the same server or seperate server from the main app
dashboard initianlly has users management/routes and endpoints brnches like a tree but with no editing to them


----------
auto db connection retry if closed or dropped
add a webhook handler for github to restart on push to main for CI/CD


----------------------
cache user data to prevent loading from db with every request 
and make that user cache to be in the auth service 
update the user when update
and delete when deleted from db

use a map in cache for easy accessing
----------------------


create an auth router like the crud one , and make it customizable to allow or disallow different functions like the login/register, etc...

create a dispater router, or Dispatcher, that takes a list of routers and runs them at order, and it can be passed to the server directly
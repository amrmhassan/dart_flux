serve static files with send response

make the response have access to all SendResponse methods

add a webhook handler for github to restart on push to main for CI/CD


----------------------
cache user data to prevent loading from db with every request 
and make that user cache to be in the auth service 
update the user when update
and delete when deleted from db

use a map in cache for easy accessing
----------------------

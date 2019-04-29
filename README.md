# Bookshelf (Task Queueing example)

This is an updated version of the ["Task Queueing Demo App"](https://github.com/GoogleCloudPlatform/getting-started-ruby/tree/master/6-task-queueing) example from Google Cloud Platform, which uses the
Google Cloud PubSub service.

## Run the app locally

This project uses Docker :) But first, make sure you set up the required
credentials by copying the `example.env` file into `.env`, and replace the
values with your own.

Then, start the app using `docker-compose`:

```
docker-compose up web worker
```

The app will launch at http://localhost:3000, and for every book you add, the
worker will try to match the info with what's available at Google Books API, and
bring up a book cover.

Notice how we're using the Google Cloud PubSub Emulator image from [vovimayhem/google-pubsub-emulator](https://hub.docker.com/r/vovimayhem/google-pubsub-emulator).

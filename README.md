# rust-crud

## Overview

This is an experimental project for CRUD application with Elm and Rust. This project consists of simple three layers.

The following table shows that the relation between abstract layers and thier concrete components:

| Layer | Component |
----|----|
| UI/Frontend | [Elm](https://elm-lang.org/) |
| API/Backend | [Actix](https://actix.rs/) |
| DB | [bayard](https://github.com/bayard-search/bayard) |

## Other Components

In addtion to the above components, the project uses extra components to make the development process easier.

### Docker

All layers are comtainerized with [Docker](https://www.docker.com/). For rust application, it is used only for the build process because Rust doesn't require any runtime system.

### nginx

For serving the elm application, [Nginx](https://www.nginx.com/) is used as HTTP server. This makes the Elm UI less depend on the backend.

## Commands

### Run The Server in Watch Mode

To run a actix-web server in watch mode, need some trick below.

```bash
systemfd --no-pid -s http::3000 -- cargo watch -x run
```

If You would like to know waht is each part of the command, please consult following link.

[Auto-Reloading Development Server](https://actix.rs/docs/autoreload/)

### Build Elm with elm-live

To build the elm application, using [elm-live](https://www.elm-live.com/).

```bash
elm-live src/Main.elm --open --pushstate --port=5050 --host=localhost --dir=./dist -- --output=./dist/index.html
```
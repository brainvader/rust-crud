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

## Reference

### actix-web

* [actix](https://actix.rs/)
* [actix_rt](https://docs.rs/actix-rt/1.0.0/actix_rt/index.html)
* [actix_cors](https://docs.rs/actix-cors/0.3.0-alpha.1/actix_cors/)
* [actix/examples](https://github.com/actix/examples)
* [Active-web Archives - TURRETA](https://turreta.com/tag/active-web/)
* [Overview · Serde](https://serde.rs/)
* [Error Handling - A Gentle Introduction to Rust](https://stevedonovan.github.io/rust-gentle-intro/6-error-handling.html)
* [rustbook-1/ch11](https://github.com/KeenS/rustbook-1/tree/actix-web-2.0.0/ch11)

### Elm

* [package.elm-lang.org](https://github.com/elm/package.elm-lang.org)
* [Routing in Elm](https://elm.christmas/2018/15)
* [Learning Elm, part 2](http://lucasmreis.github.io/blog/learning-elm-part-2/)
* [elm-ui: Forget CSS and enjoy creating UIs in pure Elm](https://korban.net/posts/elm/2019-11-17-elm-ui-introduction/)
* [elm-json-decode-pipeline](https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/)
* [remotedata](https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/)

### bayard

* [bayard-search/bayard](https://github.com/bayard-search/bayard)
* [Bayard documentation](https://bayard-search.github.io/bayard/overview.html)
* [Rust製全文検索エンジンのbayardを入れてみた](https://qiita.com/gosarami/items/d198c15e960f856f63b1)

### Nginx

* [Beginner’s Guide](http://nginx.org/en/docs/beginners_guide.html)
* [Nginx Documentation - Web Server](https://docs.nginx.com/nginx/admin-guide/web-server/)
* [Nginx Tutorial](https://www.netguru.com/codestories/nginx-tutorial-basics-concepts)
* [Nginx Tutorial Step by Step with Examples](https://knockdata.github.io/Nginx-Tutorial-Step-by-Step-with-Examples/   )
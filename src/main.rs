use actix_files as fs;
use actix_web::http::StatusCode;
use actix_web::{middleware, web, App, HttpResponse, HttpServer};
use listenfd::ListenFd;
use std::io::Result;

mod example;
// implicit root module
use crate::example::db;
use crate::example::hello;

async fn page_404() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/404.html")?.set_status_code(StatusCode::NOT_FOUND))
}

#[actix_rt::main]
async fn main() -> Result<()> {
    let url = "127.0.0.1:8088";
    let mut listenfd = ListenFd::from_env();
    let mut server = HttpServer::new(|| {
        App::new()
            .wrap(middleware::DefaultHeaders::new().header("Access-Control-Allow-Origin", "*"))
            .service(
                web::scope("/example")
                    .configure(hello::config)
                    .configure(db::config),
            )
            .service(fs::Files::new("/static", ".").show_files_listing())
            .default_service(web::to(page_404))
    });

    server = if let Some(l) = listenfd.take_tcp_listener(0).unwrap() {
        server.listen(l)?
    } else {
        server.bind(url)?
    };

    server.run().await
}

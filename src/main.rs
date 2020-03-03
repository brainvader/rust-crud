use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use listenfd::ListenFd;
use std::io::Result;

async fn index() -> impl Responder {
    HttpResponse::Ok().body("Hello World!")
}

#[actix_rt::main]
async fn main() -> Result<()> {
    let url = "127.0.0.1:8088";
    let mut listenfd = ListenFd::from_env();
    let mut server = HttpServer::new(|| App::new().route("/", web::get().to(index)));

    server = if let Some(l) = listenfd.take_tcp_listener(0).unwrap() {
        server.listen(l)?
    } else {
        server.bind(url)?
    };

    server.run().await
}

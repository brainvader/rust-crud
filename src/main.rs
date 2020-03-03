use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use std::io::Result;

async fn index() -> impl Responder {
    HttpResponse::Ok().body("Hello World!")
}

#[actix_rt::main]
async fn main() -> Result<()> {
    let url = "127.0.0.1:8088";
    HttpServer::new(|| App::new().route("/", web::get().to(index)))
        .bind(url)?
        .run()
        .await
}

use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use listenfd::ListenFd;
use std::io::Result;

mod hello {
    use actix_web::{get, web, HttpResponse, Responder};

    #[get("/hello")]
    async fn hello_world() -> impl Responder {
        HttpResponse::Ok().body("Hello World!")
    }

    pub fn config(cfg: &mut web::ServiceConfig) {
        cfg.service(hello_world);
    }
}

#[actix_rt::main]
async fn main() -> Result<()> {
    let url = "127.0.0.1:8088";
    let mut listenfd = ListenFd::from_env();
    let mut server = HttpServer::new(|| {
        App::new()
            .configure(hello::config)
            .default_service(web::to(|| HttpResponse::NotFound()))
    });

    server = if let Some(l) = listenfd.take_tcp_listener(0).unwrap() {
        server.listen(l)?
    } else {
        server.bind(url)?
    };

    server.run().await
}

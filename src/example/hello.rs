use actix_web::{get, web, HttpResponse, Responder};

#[get("/hello")]
async fn hello_world() -> impl Responder {
    HttpResponse::Ok().body("Hello World!")
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(hello_world);
}

use actix_web::{get, web, Error, HttpRequest, HttpResponse, Responder};
use futures::future::{ready, Ready};
use serde::Serialize;

#[get("/hello")]
async fn hello_world() -> impl Responder {
    HttpResponse::Ok().body("Hello World!")
}

#[derive(Serialize)]
struct MyObj {
    name: &'static str,
}

impl Responder for MyObj {
    type Error = Error;
    type Future = Ready<Result<HttpResponse, Error>>;

    fn respond_to(self, _req: &HttpRequest) -> Self::Future {
        let mime_type = "application/json";
        let body = serde_json::to_string(&self).unwrap();
        let response = HttpResponse::Ok().content_type(mime_type).body(body);
        ready(Ok(response))
    }
}

#[get("/my-obj")]
async fn my_obj() -> impl Responder {
    MyObj { name: "user" }
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(my_obj).service(hello_world);
}

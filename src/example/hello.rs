use actix_web::{get, web, Error, HttpRequest, HttpResponse, Responder};
use futures::future::{ready, Ready};
use serde::Serialize;

#[get("/hello")]
async fn hello_world() -> impl Responder {
    let mut response_builder = HttpResponse::Ok();
    let body = "Hello World!";
    response_builder.body(body)
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
        let mut response_builder = HttpResponse::Ok();
        let response = response_builder.content_type(mime_type).body(body);
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

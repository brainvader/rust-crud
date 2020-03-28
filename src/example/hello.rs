use actix_files as fs;
use actix_web::{get, web, Error, HttpRequest, HttpResponse, Responder, Result};
use futures::future::{ready, Ready};
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::BufReader;
use std::path::Path;

#[get("/hello")]
async fn hello_world() -> impl Responder {
    let mut response_builder = HttpResponse::Ok();
    let body = "Hello World!";
    response_builder.body(body)
}

#[get("/svg/test")]
async fn test_svg() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("./static/image/test.svg")?)
}

type QuizId = u8;

#[derive(Serialize, Deserialize)]
struct Cell {
    kind: String,
    content: String,
}

#[derive(Serialize, Deserialize)]
struct Quiz {
    id: QuizId,
    question: Vec<Cell>,
    answer: Vec<Cell>,
}

#[get("what-is-minq")]
async fn what_is_minq() -> Result<HttpResponse> {
    let mut response_builder = HttpResponse::Ok();
    let path_to_file = Path::new("./quiz/what-is-minq.json");
    let file = File::open(path_to_file)?;
    let reader = BufReader::new(file);
    let quiz: Quiz = serde_json::from_reader(reader)?;
    let mime_type = "application/json";
    let response = response_builder.content_type(mime_type).json(quiz);
    Ok(response)
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
    cfg.service(my_obj)
        .service(hello_world)
        .service(what_is_minq)
        .service(test_svg);
}

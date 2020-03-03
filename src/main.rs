use actix_web::{HttpResponse, Responder};

async fn index() -> impl Responder {
    "Hello World!"
}

#[actix_rt::main]
async fn main() {
    println!("Hello, world!");
}

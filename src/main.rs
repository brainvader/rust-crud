use actix_web::{HttpResponse, Responder};

async fn index() -> impl Responder {
    "Hello World!"
}

fn main() {
    println!("Hello, world!");
}

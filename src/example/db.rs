use actix_web::{get, web, HttpResponse, Result};
use serde::{de, Deserialize, Serialize};
use std::fs::File;
use std::io::BufReader;
use std::path::Path;

type PostId = u8;

#[derive(Serialize, Deserialize)]
struct Post {
    id: PostId,
    title: String,
    author: String,
}

#[allow(non_snake_case)]
#[derive(Serialize, Deserialize)]
struct Comment {
    id: u8,
    body: String,
    postId: PostId,
}

#[derive(Serialize, Deserialize)]
struct Profile {
    name: String,
}

#[derive(Serialize, Deserialize)]
struct DB {
    posts: Vec<Post>,
    comments: Vec<Comment>,
    profile: Profile,
}

fn read_from_json<T>(file_str: &str) -> Result<T>
where
    T: de::DeserializeOwned,
{
    let path_to_file = Path::new(file_str);
    let file = File::open(path_to_file)?;
    let reader = BufReader::new(file);
    let data: T = serde_json::from_reader(reader)?;
    Ok(data)
}

#[get("posts")]
async fn get_posts() -> Result<HttpResponse> {
    let mut response_builder = HttpResponse::Ok();
    let data = read_from_json::<DB>("./quiz/db.json")?;
    let posts: Vec<Post> = data.posts;
    let mime_type = "application/json";
    let response = response_builder.content_type(mime_type).json(posts);
    Ok(response)
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(get_posts);
}

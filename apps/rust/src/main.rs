use serde_json::Value;
use std::io;

fn main() -> io::Result<()> {
    let credentials_raw = io::stdin()
        .lines()
        .map(|l| l.unwrap())
        .find(|l| l.contains("access_token"))
        .unwrap();
    let credentials: Value = serde_json::from_str(&credentials_raw)?;
    let access_token = &credentials["access_token"].as_str().unwrap();

    // let mut credentials: Value;

    // for line in lines {
    //     let input = String::from(line.unwrap());
    //     if input.as_str().contains("access_token") {
    //         break serde_json::from_str(s)?;
    //     }
    // }

    Ok(())
}

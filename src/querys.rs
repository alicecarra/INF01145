use std::collections::HashMap;

use anyhow::anyhow;
use inf01145::Service;
use postgres::Row;
use repl_rs::{Convert, Value};

pub fn query(
    args: HashMap<String, Value>,
    service: &mut Service,
) -> Result<Option<String>, anyhow::Error> {
    let query_idx: usize = args["query"].convert()?;
    let query = service.querys.get(query_idx).clone().unwrap();

    if query.contains('$') {
        let arg: f64 = match args.get("arg") {
            Some(arg) => arg.convert().unwrap(),
            None => {
                return Ok(Some(
                    "Você precisa fornecer um parametro para essa consulta!".into(),
                ));
            }
        };

        match service.client.query(query, &[&arg]) {
            Ok(result) => {
                let mut response = String::new();

                for row in result {
                    let col_size = row.columns().len();
                    for col in 0..col_size {
                        response.push_str(
                            format!(
                                "{}: {} ",
                                row.columns()[col].name(),
                                format_row(&row, col).unwrap()
                            )
                            .as_str(),
                        );
                    }

                    response.push_str("\n");
                }

                Ok(Some(response))
            }
            Err(error) => Err(anyhow!("Error creating instances: {error}")),
        }
    } else {
        match service.client.simple_query(query) {
            Ok(result) => {
                let mut response = String::new();

                for row in result {
                    let row = match row {
                        postgres::SimpleQueryMessage::Row(row) => row,
                        _ => continue,
                    };

                    let col_size = row.columns().len();
                    for col in 0..col_size {
                        response.push_str(
                            format!("{}: {} ", row.columns()[col].name(), row.get(col).unwrap())
                                .as_str(),
                        );
                    }

                    response.push_str("\n");
                }

                Ok(Some(response))
            }
            Err(error) => return Err(anyhow!("Error creating instances: {error}")),
        }
    }
}

pub fn list(
    _args: HashMap<String, Value>,
    service: &mut Service,
) -> Result<Option<String>, anyhow::Error> {
    let mut help = String::new();

    for (index, query) in service.querys.clone().into_iter().enumerate() {
        // number of elements = len() - 1
        if index == service.querys.len() {
            break;
        }

        let comment = query.split('|').nth(1).unwrap();
        help.push_str(format!("{index}:{comment}\n").as_str());
    }

    Ok(Some(help))
}

fn format_row(row: &Row, idx: usize) -> Option<String> {
    if let Ok(number) = row.try_get(idx) {
        let number: i64 = number;
        return Some(number.to_string());
    }
    if let Ok(number) = row.try_get(idx) {
        let number: i32 = number;
        return Some(number.to_string());
    }
    if let Ok(number) = row.try_get(idx) {
        let number: i16 = number;
        return Some(number.to_string());
    }
    if let Ok(number) = row.try_get(idx) {
        let number: i8 = number;
        return Some(number.to_string());
    }
    if let Ok(number) = row.try_get(idx) {
        let number: u32 = number;
        return Some(number.to_string());
    }

    if let Ok(number) = row.try_get(idx) {
        let number: f64 = number;
        return Some(number.to_string());
    }
    if let Ok(number) = row.try_get(idx) {
        let number: f32 = number;
        return Some(number.to_string());
    }

    if let Ok(text) = row.try_get(idx) {
        let text: &str = text;
        return Some(text.to_string());
    }

    return None;
}

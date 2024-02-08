use std::collections::HashMap;

use anyhow::anyhow;
use postgres::Client;
use repl_rs::Value;

pub fn create_instances(
    args: HashMap<String, Value>,
    client: &mut Client,
) -> Result<Option<String>, anyhow::Error> {
    let query = include_str!("instances.sql");

    match client.batch_execute(query) {
        Ok(_) => Ok(Some("Instâncias Criadas".into())),
        Err(error) => Err(anyhow!("Error creating: {error}")),
    }
}

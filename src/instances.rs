use std::collections::HashMap;

use anyhow::anyhow;
use inf01145::Service;
use repl_rs::Value;

pub fn create_instances(
    args: HashMap<String, Value>,
    service: &mut Service,
) -> Result<Option<String>, anyhow::Error> {
    let query = include_str!("instances.sql");

    match service.client.batch_execute(query) {
        Ok(_) => Ok(Some("Instances Created".into())),
        Err(error) => Err(anyhow!("Error creating instances: {error}")),
    }
}

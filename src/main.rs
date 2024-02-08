pub mod instances;

use repl_rs::{Command, Error, Parameter, Result, Value};
use repl_rs::{Convert, Repl};

use instances::create_instances;
use postgres::Client;

fn main() -> anyhow::Result<()> {
    let mut client = match Client::connect(
        "host=localhost user=postgres password=1234",
        postgres::NoTls,
    ) {
        Ok(client) => client,
        Err(error) => panic!("Error creating database connection: {error}"),
    };

    let mut repl = Repl::new(client)
        .add_command(Command::new("create", create_instances).with_help("create instances"));

    repl.run();

    Ok(())
}

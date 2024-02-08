pub mod instances;
pub mod querys;

use anyhow::anyhow;
use inf01145::Service;
use querys::{list, query};
use repl_rs::{Command, Error, Parameter, Result, Value};
use repl_rs::{Convert, Repl};

use instances::create_instances;

fn main() -> anyhow::Result<()> {
    let mut repl = Repl::new(Service::default())
        .add_command(Command::new("create", create_instances).with_help("create instances"))
        .add_command(Command::new("list", list).with_help("create instances"))
        .add_command(
            Command::new("query", query)
                .with_parameter(Parameter::new("query").set_required(true)?)?
                .with_parameter(Parameter::new("arg").set_required(false)?)?
                .with_help("create instances"),
        );

    repl.run().map_err(|error| anyhow!("repl error: {error}"))
}

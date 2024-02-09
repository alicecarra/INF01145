pub mod instances;
pub mod querys;

use anyhow::anyhow;
use inf01145::Service;
use querys::{list, query};
use repl_rs::Repl;
use repl_rs::{Command, Parameter};

use instances::create_instances;

fn main() -> anyhow::Result<()> {
    let mut repl = Repl::new(Service::default())
        .with_name("Consultor MegaBit Shop")
        .add_command(Command::new("create", create_instances).with_help("Cria instâncias"))
        .add_command(Command::new("list", list).with_help("Lista consultas disponíveis"))
        .add_command(
            Command::new("query", query)
                .with_parameter(Parameter::new("query").set_required(true)?)?
                .with_parameter(Parameter::new("arg").set_required(false)?)?
                .with_help("Realiza consultas. Uso: query [index] [parametro(opcional)]"),
        );

    repl.run().map_err(|error| anyhow!("repl error: {error}"))
}

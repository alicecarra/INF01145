pub mod instances;

use instances::create_instances;
use postgres::Client;

fn main() {
    let mut client = match Client::connect(
        "host=localhost user=postgres password=1234",
        postgres::NoTls,
    ) {
        Ok(client) => client,
        Err(error) => panic!("Error creating database connection: {error}"),
    };

    create_instances(&mut client);
}

use postgres::Client;

pub fn create_instances(client: &mut Client) {
    let query = include_str!("instances.sql");

    match client.batch_execute(query) {
        Ok(_) => println!("Instâncias Criadas"),
        Err(error) => eprintln!("Erro criando instâncias: {error}"),
    };
}

use postgres::Client;

pub struct Service {
    pub querys: Vec<String>,
    pub client: Client,
}

impl Default for Service {
    fn default() -> Self {
        let client = Client::connect(
            "host=localhost user=postgres password=1234",
            postgres::NoTls,
        )
        .unwrap();

        let querys = include_str!("querys.sql")
            .split_inclusive(';')
            .into_iter()
            .filter_map(|query| {
                if query.is_empty() {
                    None
                } else {
                    Some(query.to_string())
                }
            })
            .collect::<Vec<String>>();

        Self { querys, client }
    }
}

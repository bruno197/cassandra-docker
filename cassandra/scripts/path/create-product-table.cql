CREATE TABLE IF NOT EXISTS store.product (
    id timeuuid,
    name text,
    description text,
    quantity int,
    price bigint,
    creation_date timestamp,
    PRIMARY KEY (id)
);
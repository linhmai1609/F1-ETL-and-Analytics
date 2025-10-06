create table dim_driver(
    driver_key serial primary key,
    driver_id varchar(50) not null,
    driver_broadcast_name varchar(100) not null,
    driver_country_code varchar(10),
    driver_number int not null,
    driver_full_name varchar(100) not null,
    driver_first_name varchar(50) not null,
    driver_last_name varchar(50) not null,
    driver_name_acronym varchar(10) not null,
    driver_headshot_url varchar(255),
    driver_meeting_key int not null,
    driver_team_colour varchar(20),
    driver_team_name varchar(100),
    effective_from_session int,
    effective_to_session int,
    is_latest boolean not null,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP
)
;

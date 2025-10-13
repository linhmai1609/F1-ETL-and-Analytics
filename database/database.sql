create table dim_driver(
    driver_key serial primary key,
    driver_id varchar(50) not null,
    broadcast_name varchar(100) not null,
    country_code varchar(10),
    driver_number int not null,
    full_name varchar(100) not null,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    name_acronym varchar(10) not null,
    headshot_url varchar(255),
--    meeting_key int not null,
    team_colour varchar(20),
    team_name varchar(100),
    effective_from_meeting int,
    effective_to_meeting int,
    is_latest boolean not null,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP
)
;
create index idx_dim_driver_number on dim_driver(driver_number)
;
create index idx_dim_driver_effective_meeting on dim_driver(effective_from_meeting, effective_to_meeting)
;
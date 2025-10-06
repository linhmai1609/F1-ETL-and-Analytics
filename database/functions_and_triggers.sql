create or replace function func_update_record_timestamp() 
returns trigger as $$
DECLARE
    existing_record dim_driver;
begin
	
	SELECT * INTO existing_record
    FROM dim_driver
    WHERE driver_full_name = NEW.driver_full_name
    ORDER BY effective_to_session DESC
    LIMIT 1;
	
	if found then 
		
		if existing_record.effective_to_session < new.effective_from_session then
			update dim_driver
			set updated_at = CURRENT_TIMESTAMP, effective_to_session = new.effective_to_session, is_latest = false
			where 1=1
				and driver_full_name = new.driver_full_name;
		end if;is_active
			
		IF (
		    existing_record.driver_broadcast_name IS DISTINCT FROM NEW.driver_broadcast_name AND
		    existing_record.driver_country_code IS DISTINCT FROM NEW.driver_country_code AND
		    existing_record.driver_number IS DISTINCT FROM NEW.driver_number AND
		    existing_record.driver_full_name IS DISTINCT FROM NEW.driver_full_name AND
		    existing_record.driver_first_name IS DISTINCT FROM NEW.driver_first_name AND
		    existing_record.driver_last_name IS DISTINCT FROM NEW.driver_last_name AND
		    existing_record.driver_name_acronym IS DISTINCT FROM NEW.driver_name_acronym AND
		    existing_record.driver_headshot_url IS DISTINCT FROM NEW.driver_headshot_url AND
		    existing_record.driver_meeting_key IS DISTINCT FROM NEW.driver_meeting_key AND
		    existing_record.driver_team_colour IS DISTINCT FROM NEW.driver_team_colour AND
		    existing_record.driver_team_name IS DISTINCT FROM NEW.driver_team_name AND
			existing_record.effective_from_session IS DISTINCT FROM NEW.effective_from_session AND
		    existing_record.is_active IS DISTINCT FROM NEW.is_active
		) THEN
       		return null;
		end if;
		
	end if;
	return new;
end;
$$ LANGUAGE plpgsql;

create or replace TRIGGER trg_before_insert_driver
BEFORE INSERT ON dim_driver
FOR EACH ROW
EXECUTE FUNCTION func_update_record_timestamp();
	
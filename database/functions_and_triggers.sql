create or replace function func_update_record_timestamp() 
returns trigger as $$
DECLARE
    existing_record dim_driver;
begin
	
	SELECT * INTO existing_record
    FROM dim_driver
    WHERE 1=1
		and full_name = NEW.full_name
		and is_latest = true
    ORDER BY effective_to_meeting DESC
    LIMIT 1;
	
	if found then 
		
		if existing_record.effective_to_meeting < new.effective_from_meeting then
			update dim_driver
			set updated_at = CURRENT_TIMESTAMP, effective_to_meeting = new.effective_to_meeting
			where 1=1
				and is_latest = true
				and full_name = new.full_name;
		end if;
			
		IF (
		    existing_record.broadcast_name IS DISTINCT FROM NEW.broadcast_name OR
		    existing_record.country_code IS DISTINCT FROM NEW.country_code OR
		    existing_record.driver_number IS DISTINCT FROM NEW.driver_number OR
		    existing_record.full_name IS DISTINCT FROM NEW.full_name OR
		    existing_record.first_name IS DISTINCT FROM NEW.first_name OR
		    existing_record.last_name IS DISTINCT FROM NEW.last_name OR
		    existing_record.name_acronym IS DISTINCT FROM NEW.name_acronym OR
		    existing_record.headshot_url IS DISTINCT FROM NEW.headshot_url OR
--		    existing_record.meeting_key IS DISTINCT FROM NEW.meeting_key OR
		    existing_record.team_colour IS DISTINCT FROM NEW.team_colour OR
		    existing_record.team_name IS DISTINCT FROM NEW.team_name
		) THEN
			update dim_driver
			set is_latest = false
			where 1=1
				and is_latest = true
				and full_name = new.full_name
			;

       		return new;
		else
			return null;
		end if;
	else
		return new;
	end if;
--	return null;
end;
$$ LANGUAGE plpgsql;

create or replace TRIGGER trg_before_insert_driver
BEFORE INSERT ON dim_driver
FOR EACH ROW
EXECUTE FUNCTION func_update_record_timestamp();
	